extends SceneTree

var bridge: Node
var revision: int = 3
var commands: Array = []

func _initialize() -> void:
	var bridge_script: GDScript = load("res://scripts/local_bridge.gd")
	bridge = bridge_script.new()
	root.add_child(bridge)
	bridge.lease_ttl_seconds = 1.2
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	var port: int = int(arguments[0]) if arguments.size() > 0 else 43129
	var result: Error = bridge.configure(_state, _command, port)
	if result != OK:
		printerr("BRIDGE_TEST_START_FAILED ", result)
		quit(1)
		return
	print("BRIDGE_TEST_READY ", bridge.pairing_code)

func _state() -> Dictionary:
	return {"revision": revision, "simulation": {"phase": "planning", "units": [], "map": {"grid_tiles": [32, 20]}}, "campaign": {"act": 1}, "commands": commands}

func _command(command: Dictionary) -> Dictionary:
	if str(command.get("kind", "")) == "force_conflict":
		return {"ok": false, "conflict": true, "message": "A test edit changed on the PC. Refresh before editing.", "revision": revision}
	if int(command.get("expected_revision", -1)) != revision:
		return {"ok": false, "conflict": true, "message": "The layout changed on the PC. Refresh before editing.", "revision": revision}
	commands.append(command)
	revision += 1
	return {"ok": true, "message": "Applied", "revision": revision}
