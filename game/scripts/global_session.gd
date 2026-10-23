extends Node
class_name BeldeGlobalSession

## Optional profile lease. Local-only play stays available when no URL is configured.
## HTTPS certificate verification uses HTTPRequest's verified default TLS behavior.
signal status_changed(status: String)

const HEARTBEAT_MS = 5000
const DEFAULT_TTL_MS = 20000
const WARNING_TITLE = "Multiple Game Instances Detected"
const WARNING_BODY = "Your game is currently active on another device or platform. Only one active PC gameplay session and one connected editor session are permitted."
const WARNING_ACTION = "Disconnect other session to continue"

var enabled: bool = false
var session_ready: bool = true
var status: String = "local"
var message: String = "Local gameplay and editor pairing."
var conflict_title: String = WARNING_TITLE
var conflict_action: String = WARNING_ACTION
var _url: String = ""
var _profile_id: String = ""
var _profile_token: String = ""
var _instance_id: String = ""
var _lease_token: String = ""
var _lease_deadline_ms: int = 0
var _last_heartbeat_ms: int = 0
var _pending: bool = false
var _pending_op: String = ""
var _closing: bool = false
var _http: HTTPRequest

func configure_from_environment() -> Error:
	_cancel_pending()
	_closing = false
	_url = OS.get_environment("BELDE_SESSION_URL").strip_edges().trim_suffix("/")
	_profile_id = OS.get_environment("BELDE_PROFILE_ID")
	_profile_token = OS.get_environment("BELDE_PROFILE_TOKEN")
	_lease_token = ""
	_lease_deadline_ms = 0
	enabled = not _url.is_empty()
	if not enabled:
		_set_status("local", "Local gameplay and editor pairing.", true)
		return OK
	if not _valid_url(_url):
		_set_status("configuration_error", "Use an HTTPS session service, or HTTP on localhost for local testing.", false)
		return ERR_INVALID_PARAMETER
	if not _valid_credentials():
		_set_status("configuration_error", "Set BELDE_PROFILE_ID and BELDE_PROFILE_TOKEN for this profile.", false)
		return ERR_UNCONFIGURED
	if _instance_id.is_empty():
		_instance_id = Crypto.new().generate_random_bytes(32).hex_encode()
	_ensure_http()
	_set_status("disconnected", "Connect to the profile session service to continue.", false)
	return OK

func _valid_credentials() -> bool:
	var valid_id: RegEx = RegEx.create_from_string("^[A-Za-z0-9_-]{1,64}$")
	return valid_id.search(_profile_id) != null and _profile_token.length() >= 32 and _profile_token.length() <= 512 and not _profile_token.contains("\r") and not _profile_token.contains("\n")

func _valid_url(url: String) -> bool:
	if url.contains("@") or url.contains("?") or url.contains("#") or url.contains("\\"):
		return false
	var authority: String = ""
	if url.begins_with("https://"):
		authority = url.substr(8).get_slice("/", 0)
		return not authority.is_empty()
	if not url.begins_with("http://"):
		return false
	authority = url.substr(7).get_slice("/", 0)
	var host: String = authority.get_slice(":", 0).to_lower()
	if authority.begins_with("[::1]"):
		var tail: String = authority.substr(5)
		return tail.is_empty() or (tail.begins_with(":") and tail.substr(1).is_valid_int())
	return host == "127.0.0.1" or host == "localhost"

func _ensure_http() -> void:
	if is_instance_valid(_http):
		return
	_http = HTTPRequest.new()
	_http.timeout = 4.0
	_http.body_size_limit = 65536
	_http.max_redirects = 0
	add_child(_http)
	_http.request_completed.connect(_request_finished)

func start() -> void:
	if not enabled:
		_set_status("local", "Local gameplay and editor pairing.", true)
		return
	if _url.is_empty() or not _valid_credentials() or not _valid_url(_url):
		_set_status("configuration_error", "Profile session settings are incomplete or invalid.", false)
		return
	_closing = false
	_cancel_pending()
	_lease_token = ""
	_send("acquire", false)

func force_takeover() -> void:
	if not enabled or not _valid_credentials() or not _valid_url(_url):
		return
	_closing = false
	_cancel_pending()
	_lease_token = ""
	_send("acquire", true)

func _send(operation: String, force: bool = false) -> void:
	_ensure_http()
	var payload: Dictionary = {"profile_id": _profile_id, "instance_id": _instance_id}
	if operation == "acquire":
		payload["force"] = force
	else:
		payload["lease_token"] = _lease_token
	_pending = true
	_pending_op = operation
	if operation == "acquire":
		_set_status("connecting", "Connecting to the profile session service…", false)
	var headers: PackedStringArray = ["Content-Type: application/json", "Authorization: Bearer " + _profile_token, "Cache-Control: no-store"]
	var error: Error = _http.request(_url + "/v1/lease/" + operation, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
	if error != OK:
		_pending = false
		_set_status("unavailable", "Could not reach the profile session service. Reconnect to continue.", false)

func _process(_delta: float) -> void:
	if not enabled or not session_ready or _closing:
		return
	var now: int = Time.get_ticks_msec()
	if now >= _lease_deadline_ms:
		_set_status("expired", "The profile session expired. Reconnect to continue.", false)
		return
	if not _pending and now - _last_heartbeat_ms >= HEARTBEAT_MS:
		_send("renew")

func _request_finished(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var operation: String = _pending_op
	_pending = false
	if _closing:
		_set_status("released", "Profile session disconnected.", false)
		return
	if result != HTTPRequest.RESULT_SUCCESS:
		_set_status("unavailable", "Profile session connection was lost. Reconnect to continue.", false)
		return
	var parsed = JSON.parse_string(body.get_string_from_utf8())
	if not parsed is Dictionary:
		_set_status("unavailable", "The profile session service returned an invalid response.", false)
		return
	var data: Dictionary = parsed
	if response_code == 409:
		conflict_title = str(data.get("title", WARNING_TITLE))
		conflict_action = str(data.get("action", WARNING_ACTION))
		_set_status("conflict", str(data.get("message", WARNING_BODY)), false)
		return
	if response_code == 401:
		_set_status("unauthorized", "Profile credentials were rejected. Check your session settings.", false)
		return
	if response_code != 200 or not bool(data.get("ok", false)):
		_set_status("unavailable", "The profile session service could not confirm this session.", false)
		return
	if operation == "release":
		_set_status("released", "Profile session disconnected.", false)
		return
	if operation == "acquire":
		_lease_token = str(data.get("lease_token", ""))
	if _lease_token.length() != 64:
		_set_status("unavailable", "The profile session service returned an invalid lease.", false)
		return
	var ttl: float = clampf(float(data.get("expires_in", 20)), 1.0, 20.0)
	_last_heartbeat_ms = Time.get_ticks_msec()
	_lease_deadline_ms = _last_heartbeat_ms + int(ttl * 1000.0)
	_set_status("connected", "Profile session connected.", true)

func _set_status(next_status: String, next_message: String, next_ready: bool) -> void:
	var changed: bool = status != next_status or session_ready != next_ready or message != next_message
	status = next_status
	message = next_message
	session_ready = next_ready
	if changed:
		status_changed.emit(status)

func _cancel_pending() -> void:
	if _pending and is_instance_valid(_http):
		_http.cancel_request()
	_pending = false

func shutdown() -> void:
	if _closing:
		return
	_closing = true
	_cancel_pending()
	session_ready = false
	if enabled and not _lease_token.is_empty() and is_inside_tree():
		_send("release")
	else:
		_set_status("released" if enabled else "local", "Profile session disconnected." if enabled else "Local gameplay and editor pairing.", not enabled)
