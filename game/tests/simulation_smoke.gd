extends SceneTree
const Catalog = preload("res://scripts/catalog.gd")
const Simulation = preload("res://scripts/simulation.gd")
var passed: int = 0
var failed: int = 0

func _initialize():
	var catalog = Catalog.new()
	var sim = Simulation.new(catalog)
	sim.setup(catalog.get_map("MAP01"), ["BAR01", "BAR03"])
	check(sim.units.size() == 2, "real roster deploys two allies")
	check(sim.phase == "planning", "battle begins in planning")
	check(sim.units[0]["pos"] != sim.units[1]["pos"], "allies are spaced")
	var before = JSON.stringify(sim.snapshot())
	var ghost = sim.preview_command({"kind": "place_tower", "tower_id": "TOWER04", "cell": [8, 6]})
	check(ghost.ok, "preview accepts a real tower pad")
	check(JSON.stringify(sim.snapshot()) == before, "preview is nonmutating")
	var result = sim.command({"kind": "place_tower", "tower_id": "TOWER04", "cell": [8, 6]})
	check(result.ok and sim.towers.size() == 1 and sim.coins == 220, "tower uses runtime supply cost")
	check(not sim.command({"kind": "place_tower", "tower_id": "TOWER04", "cell": [8, 6]}).ok, "occupied placement rejected")
	check(not sim.command({"kind": "place_tower", "tower_id": "TOWER04", "cell": [15, 10]}).ok, "enemy route cannot be blocked")
	check(not sim.command({"kind": "move_unit", "uid": sim.units[0].uid, "cell": [-1, 3]}).ok, "out-of-bounds move rejected")
	check(sim.command({"kind": "undo"}).ok and sim.coins == 300 and sim.towers.is_empty(), "undo restores layout and supplies")
	check(sim.command({"kind": "redo"}).ok and sim.coins == 220 and sim.towers.size() == 1, "redo restores purchase once")
	check(sim.start_wave().ok and sim.phase == "combat", "wave starts")
	check(not sim.command({"kind": "move_unit", "uid": sim.units[0].uid, "cell": [5, 5]}).ok, "combat edits rejected")
	for i in range(900): sim.step(1.0 / 30.0)
	check(sim.elapsed > 29.0, "fixed-step clock advances")
	check(sim.kills > 0, "real unit/tower attacks defeat enemies")
	check(sim.damage_dealt > 0, "damage is actually applied")
	var save = JSON.parse_string(JSON.stringify(sim.snapshot()))
	var restored = Simulation.new(catalog)
	check(restored.restore(save).ok, "JSON round trip restores")
	check(restored.units.size() == sim.units.size() and restored.coins == sim.coins and restored.wave == sim.wave, "save preserves party/economy/wave")
	for i in range(300):
		sim.step(1.0 / 30.0); restored.step(1.0 / 30.0)
	check(absf(sim.gate_hp - restored.gate_hp) < 0.1 and sim.kills == restored.kills, "restored combat remains deterministic")
	check(not restored.restore({"version": 99}).ok, "unknown save version rejected")
	print("SIMULATION SMOKE: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)

func check(condition: bool, label: String):
	if condition: passed += 1
	else:
		failed += 1
		push_error("FAIL: " + label)
