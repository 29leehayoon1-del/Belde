extends SceneTree

const Client = preload("res://scripts/global_session.gd")
var first
var second

func _initialize() -> void:
	Engine.max_fps = 120
	call_deferred("_run")

func _until(predicate: Callable, seconds: float = 7.0) -> bool:
	var deadline: int = Time.get_ticks_msec() + int(seconds * 1000)
	while Time.get_ticks_msec() < deadline:
		if predicate.call():
			return true
		await create_timer(0.04).timeout
	return false

func _require(condition: bool, label: String) -> bool:
	if not condition:
		printerr("GLOBAL_CLIENT_FAILED ", label)
		quit(1)
	return condition

func _run() -> void:
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	var mode: String = str(arguments[0]) if arguments.size() else "lease"
	first = Client.new()
	root.add_child(first)
	if mode == "configuration":
		OS.set_environment("BELDE_SESSION_URL", "")
		if not _require(first.configure_from_environment() == OK and first.session_ready and not first.enabled, "local default"):
			return
		OS.set_environment("BELDE_SESSION_URL", "http://example.com")
		OS.set_environment("BELDE_PROFILE_ID", "player-one")
		OS.set_environment("BELDE_PROFILE_TOKEN", "test-profile-credential-only-configuration-0000")
		if not _require(first.configure_from_environment() == ERR_INVALID_PARAMETER and not first.session_ready, "remote plaintext rejected"):
			return
		OS.set_environment("BELDE_SESSION_URL", "https://example.com")
		if not _require(first.configure_from_environment() == OK, "HTTPS settings accepted"):
			return
		if not _require(first.get("_http").max_redirects == 0, "credential redirects disabled"):
			return
		OS.set_environment("BELDE_PROFILE_TOKEN", "invalid\r\nheader")
		if not _require(first.configure_from_environment() == ERR_UNCONFIGURED and not first.session_ready, "header credentials rejected"):
			return
		print("GLOBAL_CLIENT_CONFIGURATION_PASS")
		quit(0)
		return
	if not _require(first.configure_from_environment() == OK, "first configuration"):
		return
	first.start()
	if mode == "unavailable":
		if not _require(await _until(func(): return first.status in ["unavailable", "unauthorized", "configuration_error"]), "unavailable result"):
			return
		if not _require(not first.session_ready, "unavailable fails closed"):
			return
		print("GLOBAL_CLIENT_UNAVAILABLE_PASS")
		quit(0)
		return
	if not _require(await _until(func(): return first.session_ready), "first acquire"):
		return
	print("GLOBAL_CLIENT_ACQUIRED")
	second = Client.new()
	root.add_child(second)
	if not _require(second.configure_from_environment() == OK, "second configuration"):
		return
	second.start()
	if not _require(await _until(func(): return second.status == "conflict"), "second PC rejected"):
		return
	if not _require(not second.session_ready and second.conflict_title == "Multiple Game Instances Detected", "conflict blocks game"):
		return
	second.force_takeover()
	if not _require(await _until(func(): return second.session_ready), "explicit takeover"):
		return
	if not _require(await _until(func(): return not first.session_ready, 8), "old client loses lease on heartbeat"):
		return
	second.shutdown()
	await create_timer(0.3).timeout
	first.start()
	if not _require(await _until(func(): return first.session_ready), "release permits reconnect"):
		return
	print("GLOBAL_CLIENT_REACQUIRED")
	# The Python harness stops the actual coordinator now.
	if not _require(await _until(func(): return not first.session_ready, 10), "coordinator outage fails closed"):
		return
	if not _require(first.status in ["unavailable", "expired"], "outage status"):
		return
	print("GLOBAL_CLIENT_LEASE_PASS")
	quit(0)
