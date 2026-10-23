extends Node
class_name BeldeLocalBridge

## A loopback-only Native Messaging endpoint. The PC remains authoritative.
## This enforces one PC/editor pair on this machine, not across unconnected devices.
signal connection_changed(connected: bool)
signal command_received(kind: String)

const MAX_BODY_BYTES: int = 65536
const MAX_HEADER_BYTES: int = 8192
const MAX_RESPONSE_BYTES: int = 1048576
const MAX_CLIENTS: int = 16
const REQUEST_TIMEOUT_SECONDS: float = 4.0
const INSTANCE_TITLE: String = "Multiple Game Instances Detected"
const INSTANCE_MESSAGE: String = "Your game is currently active on another device or platform. Only one active PC gameplay session and one connected editor session are permitted."
const INSTANCE_ACTION: String = "Disconnect other session to continue"

var pairing_code: String = ""
var editor_connected: bool = false
var lease_ttl_seconds: float = 15.0
var last_error_message: String = ""
var port: int = 43127
var _server: TCPServer = TCPServer.new()
var _clients: Array = []
var _state_provider: Callable
var _command_handler: Callable
var _lease_token: String = ""
var _lease_client_id: String = ""
var _lease_deadline: float = 0.0
var _pair_attempts: Array = []
var _crypto: Crypto = Crypto.new()
var _running: bool = false

func configure(state_provider: Callable, command_handler: Callable, requested_port: int = 43127) -> Error:
	if not state_provider.is_valid() or not command_handler.is_valid():
		last_error_message = "The editor bridge requires game-state and command callbacks."
		return ERR_INVALID_PARAMETER
	if _running:
		return ERR_ALREADY_IN_USE
	port = requested_port
	var configured_port: String = OS.get_environment("BELDE_BRIDGE_PORT")
	if requested_port == 43127 and not configured_port.is_empty():
		if not configured_port.is_valid_int():
			last_error_message = "BELDE_BRIDGE_PORT must be an integer between 1024 and 65535."
			return ERR_INVALID_PARAMETER
		port = configured_port.to_int()
	if port < 1024 or port > 65535:
		last_error_message = "The editor bridge port must be between 1024 and 65535."
		return ERR_INVALID_PARAMETER
	_state_provider = state_provider
	_command_handler = command_handler
	var error: Error = _server.listen(port, "127.0.0.1")
	if error != OK:
		last_error_message = INSTANCE_TITLE + "\n" + INSTANCE_MESSAGE
		return error
	pairing_code = _new_pairing_code()
	_running = true
	set_process(true)
	return OK

func shutdown() -> void:
	_running = false
	_server.stop()
	for client in _clients:
		client["peer"].disconnect_from_host()
	_clients.clear()
	_clear_lease()
	set_process(false)

func disconnect_editor() -> void:
	_clear_lease()
	pairing_code = _new_pairing_code()

func connection_info() -> Dictionary:
	_expire_lease()
	return {
		"connected": editor_connected,
		"lease_seconds_remaining": maxf(0.0, _lease_deadline - _now()),
		"scope": "this PC and its paired editor",
		"protocol_version": 1
	}

func _exit_tree() -> void:
	shutdown()

func _process(_delta: float) -> void:
	if not _running:
		return
	_expire_lease()
	while _server.is_connection_available():
		var peer: StreamPeerTCP = _server.take_connection()
		if _clients.size() >= MAX_CLIENTS:
			peer.disconnect_from_host()
		else:
			peer.set_no_delay(true)
			_clients.append({"peer": peer, "buffer": PackedByteArray(), "created": _now()})
	for index in range(_clients.size() - 1, -1, -1):
		var client: Dictionary = _clients[index]
		var peer: StreamPeerTCP = client["peer"]
		peer.poll()
		if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			_clients.remove_at(index)
			continue
		if _now() - float(client["created"]) > REQUEST_TIMEOUT_SECONDS:
			_respond(peer, 408, _error("The editor request timed out.", "timeout"))
			_clients.remove_at(index)
			continue
		var available: int = peer.get_available_bytes()
		if available > 0:
			var read_result: Array = peer.get_data(mini(available, MAX_BODY_BYTES + MAX_HEADER_BYTES + 1))
			if int(read_result[0]) != OK:
				peer.disconnect_from_host()
				_clients.remove_at(index)
				continue
			var buffer: PackedByteArray = client["buffer"]
			buffer.append_array(read_result[1])
			client["buffer"] = buffer
			_clients[index] = client
		if _consume_request(client):
			_clients.remove_at(index)

func _consume_request(client: Dictionary) -> bool:
	var peer: StreamPeerTCP = client["peer"]
	var buffer: PackedByteArray = client["buffer"]
	if buffer.size() > MAX_BODY_BYTES + MAX_HEADER_BYTES:
		_respond(peer, 413, _error("The editor request is too large.", "too_large"))
		return true
	var header_end: int = _find_header_end(buffer)
	if header_end < 0:
		if buffer.size() > MAX_HEADER_BYTES:
			_respond(peer, 431, _error("The editor request headers are too large.", "too_large"))
			return true
		return false
	# HTTP headers must be ASCII, so string and byte offsets agree here.
	if header_end > MAX_HEADER_BYTES:
		_respond(peer, 431, _error("The editor request headers are too large.", "too_large"))
		return true
	var header_bytes: PackedByteArray = buffer.slice(0, header_end)
	for byte in header_bytes:
		if byte > 127:
			_respond(peer, 400, _error("HTTP headers must be ASCII.", "invalid_request"))
			return true
	var header_text: String = header_bytes.get_string_from_ascii()
	for character_index in range(header_text.length()):
		if header_text.unicode_at(character_index) > 127:
			_respond(peer, 400, _error("HTTP headers must be ASCII.", "invalid_request"))
			return true
	var lines: PackedStringArray = header_text.split("\r\n")
	var first: PackedStringArray = lines[0].split(" ", false)
	if first.size() != 3 or not first[2].begins_with("HTTP/1."):
		_respond(peer, 400, _error("Malformed HTTP request.", "invalid_request"))
		return true
	var headers: Dictionary = {}
	for line_index in range(1, lines.size()):
		var line: String = lines[line_index]
		var separator: int = line.find(":")
		if separator < 1:
			_respond(peer, 400, _error("Malformed HTTP header.", "invalid_request"))
			return true
		var key: String = line.substr(0, separator).strip_edges().to_lower()
		if headers.has(key):
			_respond(peer, 400, _error("Repeated HTTP headers are not accepted.", "invalid_request"))
			return true
		headers[key] = line.substr(separator + 1).strip_edges()
	if headers.has("origin") or headers.has("transfer-encoding"):
		_respond(peer, 403, _error("Use the authorized Belde Native Messaging editor.", "forbidden"))
		return true
	var expected_host: String = "127.0.0.1:" + str(port)
	if str(headers.get("host", "")) != expected_host:
		_respond(peer, 403, _error("Only the local Belde host is accepted.", "forbidden"))
		return true
	var method: String = first[0]
	var route: String = first[1]
	if method == "GET" and route == "/health":
		_respond(peer, 200, {"ok": true, "application": "Belde", "protocol_version": 1})
		return true
	if method != "POST" or route != "/native":
		_respond(peer, 404, _error("Unknown editor endpoint.", "not_found"))
		return true
	if not str(headers.get("content-type", "")).to_lower().begins_with("application/json"):
		_respond(peer, 415, _error("The native host must send JSON.", "invalid_request"))
		return true
	var length_text: String = str(headers.get("content-length", ""))
	if not length_text.is_valid_int():
		_respond(peer, 411, _error("Content-Length is required.", "invalid_request"))
		return true
	var length: int = length_text.to_int()
	if length < 2 or length > MAX_BODY_BYTES:
		_respond(peer, 413, _error("The editor request body is too large or empty.", "too_large"))
		return true
	var body_start: int = header_end + 4
	if buffer.size() < body_start + length:
		return false
	if buffer.size() > body_start + length:
		_respond(peer, 400, _error("Pipelined editor requests are not accepted.", "invalid_request"))
		return true
	var parser: JSON = JSON.new()
	var parse_error: Error = parser.parse(buffer.slice(body_start, body_start + length).get_string_from_utf8())
	if parse_error != OK or not parser.data is Dictionary:
		_respond(peer, 400, _error("The editor request must be a JSON object.", "invalid_request"))
		return true
	var result: Dictionary = _route_native(parser.data)
	if parser.data.has("request_id"):
		result["request_id"] = parser.data["request_id"]
	var status: int = int(result.get("http_status", 200 if bool(result.get("ok", false)) else 400))
	result.erase("http_status")
	_respond(peer, status, result)
	return true

func _find_header_end(bytes: PackedByteArray) -> int:
	for index in range(maxi(0, bytes.size() - 3)):
		if bytes[index] == 13 and bytes[index + 1] == 10 and bytes[index + 2] == 13 and bytes[index + 3] == 10:
			return index
	return -1

func _route_native(request: Dictionary) -> Dictionary:
	_expire_lease()
	var operation: String = str(request.get("op", ""))
	if operation == "pair":
		return _pair(request)
	var token: String = str(request.get("token", ""))
	var client_id: String = str(request.get("client_id", ""))
	if not _authenticated(token, client_id):
		return {"ok": false, "http_status": 401, "status": "disconnected", "message": "The editor pairing expired. Enter the code shown in Belde to reconnect."}
	_lease_deadline = _now() + lease_ttl_seconds
	match operation:
		"heartbeat":
			return {"ok": true, "status": "synced", "lease_seconds": lease_ttl_seconds}
		"state":
			var state: Variant = _state_provider.call()
			if not state is Dictionary:
				return {"ok": false, "http_status": 503, "status": "disconnected", "message": "The game is not ready to share its state."}
			return {"ok": true, "status": "synced", "state": state, "connection": connection_info()}
		"command":
			var command: Variant = request.get("command", null)
			if not command is Dictionary or str(command.get("kind", "")).is_empty():
				return _error("Choose a valid editor command.", "invalid_request")
			var enriched: Dictionary = command.duplicate(true)
			if request.has("expected_revision"):
				var expected: Variant = request["expected_revision"]
				if not (expected is int or expected is float) or not is_finite(float(expected)) or float(expected) != floorf(float(expected)) or float(expected) < 0:
					return _error("The editor layout revision is invalid.", "invalid_request")
				enriched["expected_revision"] = int(expected)
			var response: Variant = _command_handler.call(enriched)
			if not response is Dictionary:
				return {"ok": false, "http_status": 500, "message": "The game could not process this edit.", "status": "error"}
			var output: Dictionary = response.duplicate(true)
			if not bool(output.get("ok", false)):
				output["http_status"] = 409 if bool(output.get("conflict", false)) else 400
			command_received.emit(str(enriched.get("kind", "")))
			return output
		"disconnect":
			_clear_lease()
			return {"ok": true, "status": "disconnected", "message": "Editor disconnected. The PC game can continue."}
		_:
			return _error("Unknown editor operation.", "invalid_request")

func _pair(request: Dictionary) -> Dictionary:
	var now: float = _now()
	_pair_attempts = _pair_attempts.filter(func(attempt: Variant) -> bool: return now - float(attempt) < 30.0)
	if _pair_attempts.size() >= 5:
		return {"ok": false, "http_status": 429, "status": "disconnected", "message": "Too many pairing attempts. Wait 30 seconds and use the code shown in Belde."}
	var client_id: String = str(request.get("client_id", ""))
	if not _valid_client_id(client_id) or str(request.get("code", "")) != pairing_code:
		_pair_attempts.append(now)
		return {"ok": false, "http_status": 401, "status": "disconnected", "message": "That pairing code is not current. Use the six digits shown in the PC game."}
	if editor_connected and not bool(request.get("force", false)):
		return {"ok": false, "http_status": 409, "status": "session_conflict", "title": INSTANCE_TITLE, "message": INSTANCE_MESSAGE, "action": INSTANCE_ACTION}
	if editor_connected:
		_clear_lease()
	_lease_token = _crypto.generate_random_bytes(32).hex_encode()
	_lease_client_id = client_id
	_lease_deadline = now + lease_ttl_seconds
	editor_connected = true
	_pair_attempts.clear()
	connection_changed.emit(true)
	return {"ok": true, "status": "synced", "token": _lease_token, "client_id": client_id, "lease_seconds": lease_ttl_seconds, "message": "Belde and this editor are now one connected pair."}

func _authenticated(token: String, client_id: String) -> bool:
	if not editor_connected or client_id != _lease_client_id or token.length() != 64:
		return false
	return _crypto.constant_time_compare(token.to_utf8_buffer(), _lease_token.to_utf8_buffer())

func _valid_client_id(client_id: String) -> bool:
	if client_id.length() < 8 or client_id.length() > 80:
		return false
	for character in client_id:
		if not character in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-":
			return false
	return true

func _expire_lease() -> void:
	if editor_connected and _now() >= _lease_deadline:
		_clear_lease()

func _clear_lease() -> void:
	var was_connected: bool = editor_connected
	editor_connected = false
	_lease_token = ""
	_lease_client_id = ""
	_lease_deadline = 0.0
	if was_connected:
		connection_changed.emit(false)

func _new_pairing_code() -> String:
	var random: PackedByteArray = _crypto.generate_random_bytes(4)
	var number: int = int(random[0]) | (int(random[1]) << 8) | (int(random[2]) << 16) | (int(random[3]) << 24)
	return str(100000 + number % 900000)

func _now() -> float:
	return float(Time.get_ticks_msec()) / 1000.0

func _error(message: String, status: String) -> Dictionary:
	return {"ok": false, "message": message, "status": status}

func _respond(peer: StreamPeerTCP, status: int, result: Dictionary) -> void:
	var body: PackedByteArray = JSON.stringify(result).to_utf8_buffer()
	if body.size() > MAX_RESPONSE_BYTES:
		status = 500
		body = JSON.stringify(_error("The game state is too large to share.", "too_large")).to_utf8_buffer()
	var reasons: Dictionary = {200: "OK", 400: "Bad Request", 401: "Unauthorized", 403: "Forbidden", 404: "Not Found", 408: "Request Timeout", 409: "Conflict", 411: "Length Required", 413: "Content Too Large", 415: "Unsupported Media Type", 429: "Too Many Requests", 431: "Request Header Fields Too Large", 500: "Internal Server Error", 503: "Service Unavailable"}
	var header: String = "HTTP/1.1 %d %s\r\nContent-Type: application/json; charset=utf-8\r\nContent-Length: %d\r\nConnection: close\r\nCache-Control: no-store\r\nX-Content-Type-Options: nosniff\r\n\r\n" % [status, reasons.get(status, "Error"), body.size()]
	var bytes: PackedByteArray = header.to_utf8_buffer()
	bytes.append_array(body)
	peer.put_data(bytes)
	peer.disconnect_from_host()
