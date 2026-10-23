extends SceneTree
## Exercises the shipped scene and button callbacks with the headless display.
## This checks application wiring; it does not claim GPU, mouse, or visual review.

var checks: int = 0
var failures: int = 0
var app
var saved_files: Dictionary = {}

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("UI_FLOW_FAILED: " + label)

func _init() -> void:
	call_deferred("run")

func settle() -> void:
	await process_frame
	await process_frame

func find_button(node: Node, label: String) -> Button:
	if node is Button and node.text == label and not node.is_queued_for_deletion():
		return node
	for child in node.get_children():
		if child.is_queued_for_deletion(): continue
		var found = find_button(child, label)
		if found != null: return found
	return null

func press(label: String) -> void:
	var button = find_button(app.screen, label)
	check(button != null, "button exists: " + label)
	if button == null: return
	check(not button.disabled, "button enabled: " + label)
	if not button.disabled: button.pressed.emit()
	await settle()

func preserve_save() -> void:
	for path in ["user://campaign_v2.json", "user://campaign_v2.json.bak"]:
		saved_files[path] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null

func restore_save() -> void:
	for path in saved_files:
		if saved_files[path] == null:
			if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		else:
			var file = FileAccess.open(path, FileAccess.WRITE)
			if file != null: file.store_buffer(saved_files[path]); file.close()

func valid_cell(kind: String, id: String = "TOWER02") -> Vector2i:
	for y in range(2, 18):
		for x in range(2, 30):
			var command = {"kind": kind, "cell": [x,y], "tower_id": id, "trap_id": "TRAP01"}
			if app.preview_command(command).get("ok", false): return Vector2i(x,y)
	return Vector2i(-1,-1)

func run() -> void:
	preserve_save()
	app = load("res://main.tscn").instantiate()
	root.add_child(app)
	await settle()
	app.set_process(false) # Deterministic flow; bridge children retain their processing.
	check(app.single_instance, "test has a unique bridge port")
	check(app.screen_name == "title", "actual scene starts at title")
	await press("Begin a new story")
	check(app.screen_name == "origins", "new story opens origins")
	await press("Visit The Bent Lantern")
	check(app.screen_name == "recruitment" and app.ui["recruit_cards"].size() == 6, "bar shows six actual recruit cards")
	check(app.ui["recruit_confirm"].disabled, "empty company cannot confirm")
	app.ui["recruit_cards"]["BAR01"].pressed.emit()
	app.ui["recruit_cards"]["BAR03"].pressed.emit()
	await settle()
	check(app.campaign.selected.size() == 2, "actual card callbacks select two allies")
	check(not app.ui["recruit_confirm"].disabled, "two selected allies unlock confirmation")
	await press("Set out together")
	check(app.screen_name == "story", "recruit confirmation enters dialogue")
	var choice = app.campaign.current_story()["choices"][0]
	await press(str(choice["label"]))
	check(app.screen_name == "battle" and app.sim.units.size() == 2, "story callback creates actual battlefield with two units")
	check(app.sim.phase == "planning", "battle begins in planning")
	check(app.board.size == Vector2(1024,640), "board matches map canvas")
	check(app.ui["party_buttons"].size() == 2, "party cards created")
	check(app.ui["ability_0"].disabled, "abilities disabled before combat")
	var cell = valid_cell("place_tower")
	check(cell.x >= 0, "map offers a valid defense location")
	var initial_coins = app.sim.coins
	var initial_revision = app.sim.revision
	app.apply_tool("tower:TOWER02", cell)
	check(app.sim.towers.size() == 1 and app.sim.coins < initial_coins, "palette command builds and pays for tower")
	check(not app.preview_command({"kind":"place_tower","tower_id":"TOWER02","cell":[cell.x,cell.y]}).get("ok",true), "preview rejects occupied tile")
	var conflict = app._remote_command({"kind":"undo","expected_revision":initial_revision})
	check(not conflict.get("ok",true) and conflict.get("conflict",false), "stale editor revision rejected")
	await press("Undo")
	check(app.sim.towers.is_empty() and app.sim.coins == initial_coins, "undo restores tower cost and layout")
	await press("Redo")
	check(app.sim.towers.size() == 1, "redo restores placement")
	app.track_draft.clear()
	app.append_track_cell(Vector2i(5,3))
	app.append_track_cell(Vector2i(8,5))
	check(app.track_draft.size() == 6, "fast track drag fills skipped cells")
	for i in range(1,app.track_draft.size()):
		var a = app.track_draft[i-1]
		var b = app.track_draft[i]
		check(absi(a[0]-b[0])+absi(a[1]-b[1]) == 1, "track drag stays orthogonal")
	app.track_draft.clear()
	app.ui["wave_button"].pressed.emit()
	app.sim.step(0.1)
	app._update_battle_hud()
	check(app.sim.phase == "combat", "wave button starts real simulation")
	check(not app.ui["ability_0"].disabled, "live combat enables ability button")
	app.ui["ability_0"].pressed.emit()
	check(float(app._selected_unit()["cooldowns"][0]) > 0, "ability callback starts actual cooldown")
	app._update_battle_hud()
	check(app.ui["ability_0"].disabled, "cooldown updates button state")
	app.paused = true
	check(not app._remote_command({"kind":"cast","uid":app.selected_uid,"slot":1}).get("ok",true), "paused remote cast rejected")
	app.paused = false
	var queued = app._remote_command({"kind":"place_trap","trap_id":"TRAP01","cell":[10,10],"expected_revision":app.sim.revision})
	check(queued.get("status","") == "queued" and app.pending_edits.size() == 1, "combat layout command waits for planning")
	check(not app._remote_command({"kind":"start_wave"}).get("ok",true) and app.pending_edits.size() == 1, "duplicate remote wave cannot discard queued edits")
	var snapshot = app.sim.snapshot()
	app.settings["volume"] = 0.21
	app.settings["speed"] = 2.0
	check(app._save_game(), "actual application writes versioned save")
	app.sim.coins = 0
	app.settings["volume"] = 0.6
	app._load_game()
	await settle()
	check(app.sim.coins == snapshot["coins"], "load restores battle economy")
	check(app.pending_edits.size() == 1, "load restores queued editor changes")
	check(is_equal_approx(float(app.settings["volume"]),0.21), "load restores sound settings")
	check(app.battle_preparation.get("stage","") == "battle", "retry preparation preserved")
	var valid_save = FileAccess.get_file_as_string("user://campaign_v2.json")
	var original_campaign = app.campaign
	for broken_key in ["campaign", "battle_preparation", "settings", "pending_edits", "run_seconds", "version"]:
		var broken: Dictionary = JSON.parse_string(valid_save)
		broken[broken_key] = [] if broken_key in ["campaign","battle_preparation","settings","run_seconds","version"] else "invalid"
		var output = FileAccess.open("user://campaign_v2.json",FileAccess.WRITE)
		output.store_string(JSON.stringify(broken)); output.close()
		app._load_game()
		check(app.campaign == original_campaign, "corrupt nested save rejected without replacing current run: " + broken_key)
	var restored_file = FileAccess.open("user://campaign_v2.json",FileAccess.WRITE)
	restored_file.store_string(valid_save); restored_file.close()
	await press("Settings")
	check(app.notice_modal != null and app.paused, "settings modal pauses battlefield")
	await press("Done")
	check(app.notice_modal == null and not app.paused, "closing settings restores previous pause state")
	app.pending_edits.clear()
	var battles = 0
	var loops = 0
	# Resolve outcomes directly here: combat itself is covered by simulation tests.
	# Every transition below uses the real visible screen's button callback.
	while app.campaign.stage != "ending" and loops < 24:
		loops += 1
		match app.campaign.stage:
			"battle":
				var modifiers = app.campaign.battle_modifiers()
				check(is_equal_approx(app.sim.gate_max_hp,100.0+float(modifiers.get("gate_bonus",0))), "story fortifications affect actual gate capacity")
				check(is_equal_approx(float(app.sim.snapshot().get("enemy_hp_multiplier",1)),float(modifiers.get("enemy_hp_multiplier",1))), "story health reward reaches actual simulation")
				app.sim.phase = "victory"
				app._process(0.0)
				await settle()
				check(app.result_open and app.notice_modal != null, "battle outcome displays result modal")
				await press("Continue the story")
				battles += 1
			"story":
				var choices: Array = app.campaign.current_story()["choices"]
				await press(str(choices[0]["label"]))
			"generals", "reinforce":
				if app.campaign.stage == "reinforce":
					check(app.recruit_filter == app.campaign.recruitment_origin, "story destination selects corresponding recruitment tab")
					await press("All")
				else:
					check(find_button(app.screen,"Decline the alliance and continue") != null, "general refusal is visible and reachable")
					var alliance_offer = app.campaign.snapshot()
					await press("Decline the alliance and continue")
					check(app.campaign.stage == "story" and app.campaign.flags.get("refused_generals",false), "general refusal callback advances actual story")
					check(app.campaign.restore(alliance_offer).get("ok",false), "restore alliance offer for acceptance branch")
					app._refresh_stage()
					await settle()
				check(app.ui["recruit_cards"].size() == (5 if app.campaign.stage == "generals" else 22), "late recruitment shows all candidates")
				for candidate in app.campaign.available_candidates():
					if app.campaign.selected.size() >= app.campaign.recruit_limit: break
					app.ui["recruit_cards"][str(candidate["id"])].pressed.emit()
				await settle()
				await press("Set out together")
			_:
				check(false,"unexpected flow stage " + app.campaign.stage)
				break
	check(battles >= 5 and app.screen_name == "ending", "actual screen flow reaches final judgment and epilogue")
	check(not app.campaign.ending_data.get("title","").is_empty(), "ending displays earned title")
	await press("Return to title")
	await press("Meet the 58 companions")
	check(app.screen_name == "codex", "title opens full character codex")
	for character in app.catalog.characters:
		app._show_character_dialog(str(character["id"]))
		await settle()
		check(app.notice_modal != null, "character introduction loads " + str(character["id"]))
		await press("Close")
	app.bridge.shutdown()
	if app.global_session != null: app.global_session.shutdown()
	app.queue_free()
	await settle()
	restore_save()
	print("UI_FLOW: ", checks, " checks, ", failures, " failures")
	quit(0 if failures == 0 else 1)
