extends SceneTree
const Catalog = preload("res://scripts/catalog.gd")
const Simulation = preload("res://scripts/simulation.gd")
var passed: int = 0
var failed: int = 0
var catalog = Catalog.new()

func _initialize():
	_test_every_recruit_ability()
	_test_mitigation_and_shields()
	_test_conditional_abilities()
	_test_zones_and_decoys()
	_test_enemies_and_boss()
	_test_editor_transactions()
	_test_trap_fuse()
	_test_gate_capacity()
	_test_enemy_health_modifier()
	_test_full_battle()
	print("SIMULATION REGRESSION: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)

func check(condition: bool, label: String):
	if condition: passed += 1
	else:
		failed += 1
		push_error("FAIL: " + label)

func battle(ids: Array = ["BAR01", "BAR02", "BAR03"]) -> RefCounted:
	var sim = Simulation.new(catalog)
	sim.setup(catalog.get_map("MAP01"), ids)
	sim.phase = "combat"
	for i in range(sim.units.size()):
		var u: Dictionary = sim.units[i]
		u["pos"] = Vector2(15 + (i % 2) * 0.5, 10 + floori(i / 2.0) * 0.5)
		u["anchor"] = u["pos"]; u["mode"] = "Guard"; u["attack_timer"] = 100.0; u["strategy_timer"] = 100.0
	return sim

func enemy(sim, id: String = "MOB01", pos: Vector2 = Vector2(16, 10)) -> Dictionary:
	var e = sim._spawn_enemy(id, 0, false, pos)
	e["hp"] = 1000.0; e["max_hp"] = 1000.0; e["move_speed"] = 0.0; e["attack_timer"] = 100.0; e["cooldowns"] = [100.0, 100.0]
	return e

func tick(sim, seconds: float):
	for i in range(int(ceil(seconds * 30.0))): sim.step(1.0 / 30.0)

func _test_every_recruit_ability():
	for character in catalog.characters:
		for slot in range(2):
			var ids = [character.id]
			for fallback in ["BAR01", "BAR02", "BAR03"]:
				if fallback not in ids: ids.append(fallback)
			var sim = battle(ids)
			for u in sim.units: u["hp"] = float(u["max_hp"]) * 0.4
			enemy(sim); enemy(sim, "MOB03", Vector2(16, 10.5)); enemy(sim, "MOB06", Vector2(16.5, 10))
			var result = sim.command({"kind": "cast", "uid": "u-" + character.id, "slot": slot})
			check(result.ok, character.id + " ability " + str(slot) + " executes")
			check(not sim.command({"kind": "cast", "uid": "u-" + character.id, "slot": slot}).ok, "cooldown prevents repeat " + character.id + ":" + str(slot))
			tick(sim, 1.1)
			check(sim.units[0]["cooldowns"][slot] > 0, "cooldown progresses " + character.id + ":" + str(slot))
			check(sim.revision == 0, "ability does not create layout conflict " + character.id + ":" + str(slot))

func _test_mitigation_and_shields():
	var sim = battle()
	var source: Dictionary = sim.units[0]
	var target = enemy(sim, "MOB03")
	target["facing"] = Vector2.RIGHT; source["pos"] = target["pos"] + Vector2.RIGHT
	sim._apply_single_effect(target, target, {"kind": "buff", "stat": "damage_reduction", "multiplier": 0.6, "front_only": true, "back_multiplier": 1.1, "duration": 3}, "front")
	sim._damage(target, 100, source, false)
	check(absf(target.hp - 940) < 0.001, "front bulwark reduces incoming damage")
	source["pos"] = target["pos"] - Vector2.RIGHT
	sim._damage(target, 100, source, false)
	check(absf(target.hp - 830) < 0.001, "back bulwark vulnerability applies")
	var ally: Dictionary = sim.units[0]
	ally["hp"] = ally["max_hp"]
	sim._apply_single_effect(ally, ally, {"kind": "shield", "amount": 20, "duration": 1}, "short")
	sim._apply_single_effect(ally, ally, {"kind": "shield", "amount": 30, "duration": 4}, "long")
	sim._damage(ally, 25, target, false)
	check(absf(ally.shield - 25) < 0.001, "multiple shields absorb once")
	sim._tick_statuses(ally, 1.1)
	check(absf(ally.shield - 25) < 0.001, "expired consumed shield does not erase another shield")
	sim._damage(ally, 30, target, false)
	check(absf(ally.hp - (ally.max_hp - 5)) < 0.001, "remaining shield and HP share exact damage")
	var dodge = enemy(sim, "MOB02", Vector2(17, 11))
	sim._apply_single_effect(dodge, dodge, {"kind": "buff", "stat": "evasion", "multiplier": 1.0, "one_projectile": true, "duration": 1}, "dodge")
	sim._damage(dodge, 20, source, true)
	check(dodge.hp == 1000.0, "Lantern Skip blocks first projectile")
	sim._damage(dodge, 20, source, true)
	check(dodge.hp == 980.0, "Lantern Skip does not give permanent invulnerability")

func _test_conditional_abilities():
	var sim = battle(["CAP04", "BAR01", "BAR03"])
	for u in sim.units: u["hp"] = 10.0
	var source: Dictionary = sim.units[0]
	var context = {"previous_targets": [], "damaged_targets": []}
	for e in catalog.get_ability("CAP04", 0).effects: sim._apply_effect(source, e, "sutures", context)
	check(sim.units[2].hp == 46.0, "Lantern Sutures primary heal is 36 to the lowest-health percentage ally")
	check(source.hp == 22.0 or sim.units[1].hp == 22.0, "Lantern Sutures secondary heal selects a different adjacent ally")
	var conditional = battle(["PRI09"])
	var a = enemy(conditional); var b = enemy(conditional, "MOB03", Vector2(16, 10.5))
	var actor: Dictionary = conditional.units[0]
	var ctx = {"previous_targets": [], "damaged_targets": []}
	for e in catalog.get_ability("PRI09", 1).effects: conditional._apply_effect(actor, e, "verse", ctx)
	check(actor.shield == 10.0, "Second Verse grants shield when both targets survive")
	actor["shield"] = 0.0; actor["statuses"] = []; a["hp"] = 10.0; b["hp"] = 1000.0
	ctx = {"previous_targets": [], "damaged_targets": []}
	for e in catalog.get_ability("PRI09", 1).effects: conditional._apply_effect(actor, e, "verse2", ctx)
	check(actor.shield == 0.0, "Second Verse does not grant shield after killing a target")
	var locked = battle(["GEN03"])
	var victim = enemy(locked)
	locked.command({"kind": "cast", "uid": "u-GEN03", "slot": 1})
	victim["pos"] = Vector2(25, 10)
	var replacement = enemy(locked, "MOB03", Vector2(16, 10))
	tick(locked, 0.7)
	check(victim.hp == 1000.0 and replacement.hp == 1000.0, "Oathbound Strike cancels rather than retargeting after range break")

func _test_zones_and_decoys():
	var sim = battle(["BAR02", "BAR01"])
	var source: Dictionary = sim.units[0]
	var target: Dictionary = sim.units[1]
	target["hp"] = 10.0
	sim._make_zone(source, {"kind": "zone", "target": "ally", "duration": 5, "radius": 2, "max_targets": 2, "heal": 4, "ticks": 5, "interval": 1}, source.pos, "five-ticks")
	for i in range(154): sim._tick_zones(1.0 / 30.0)
	check(absf(target.hp - 30.0) < 0.001, "healing zone executes all five one-second ticks")
	check(sim._zones.is_empty(), "healing zone expires")
	var victim = enemy(sim)
	sim._make_zone(source, {"kind": "decoy", "target": "enemy", "duration": 0.2, "radius": 2, "max_targets": 3, "hp": 10, "explosion_damage": 16, "explosion_targets": 3, "explosion_radius": 2}, victim.pos, "pot")
	sim._tick_zones(0.3)
	check(victim.hp == 1000.0, "expired decoy does not explode")
	sim._make_zone(source, {"kind": "decoy", "target": "enemy", "duration": 4, "radius": 2, "max_targets": 3, "hp": 10, "explosion_damage": 16, "explosion_targets": 3, "explosion_radius": 2}, victim.pos, "pot")
	sim._zones[-1]["hp"] = 0.0; sim._tick_zones(0.05)
	check(victim.hp < 1000.0, "destroyed decoy causes its bounded burst")

func _test_enemies_and_boss():
	for model in catalog.world.enemies:
		for slot in range(2):
			var trial = battle()
			var caster = enemy(trial, model.id)
			var ability = catalog.get_enemy_ability(model.id, slot)
			check(trial._cast_ability(caster, ability, slot, true), model.id + " enemy ability " + str(slot) + " has executable effects")
			trial._tick_scheduled(2.1)
			check(caster.hp > 0 and trial._scheduled.all(func(action): return action is Dictionary), model.id + " enemy ability released without corrupting battle state")
	var sim = battle()
	var boss = enemy(sim, "BOSS01", Vector2(20, 10))
	sim._spawn_anchors(boss, {"count": 2, "hp": 60, "duration": 6, "shield_amount": 120, "exposed_duration": 3}, "oath")
	check(boss.shield == 120 and sim.enemies.filter(func(e): return e.get("anchor", false) and e.hp > 0).size() == 2, "boss creates exactly two anchors and bounded shield")
	var anchor = sim.enemies.filter(func(e): return e.get("anchor", false) and e.hp > 0)[0]
	sim._damage(anchor, 100, sim.units[0], false)
	check(boss.shield == 0 and sim.enemies.filter(func(e): return e.get("anchor", false) and e.hp > 0).is_empty(), "breaking either anchor removes both and boss shield")
	var neutral = sim._spawn_enemy("MOB01", 0, true, Vector2(16, 10))
	sim._damage(neutral, 100, sim.units[0], false)
	check(neutral.hp == neutral.max_hp, "noncombatant is never damaged")
	var surrendering = enemy(sim, "MOB01", Vector2(16, 10))
	sim._surrender(surrendering)
	sim._damage(surrendering, 100, sim.units[0], false)
	check(surrendering.hp == 1000 and surrendering.state == "surrender" and not surrendering.hostile, "surrender removes a monster from combat targeting")

func _test_editor_transactions():
	var sim = Simulation.new(catalog); sim.setup(catalog.get_map("MAP01"), ["BAR01", "BAR03"])
	var original = JSON.stringify(sim.snapshot())
	check(not sim.command({"kind": "place_tower", "tower_id": "TOWER04"}).ok, "missing grid coordinates rejected")
	check(not sim.command({"kind": "move_unit", "uid": "u-BAR01", "cell": [3.5, 4]}).ok, "fractional unsnapped coordinates rejected")
	check(not sim.command({"kind": "set_track", "points": [[4, 4], [30, 4]]}).ok, "disconnected track jump rejected")
	check(not sim.command({"kind": "set_track", "points": [[4, 4], [10, 10]]}).ok, "diagonal unsupported track rejected")
	check(JSON.stringify(sim.snapshot()) == original, "failed editor commands are nonmutating")
	check(sim.command({"kind": "place_tower", "tower_id": "TOWER01", "cell": [8, 6]}).ok, "roost can be built")
	var roost: Dictionary = sim.towers[0]
	check(sim.command({"kind": "assign_tower", "uid": "u-BAR01", "tower_uid": roost.uid}).ok, "ranged ally can occupy a roost")
	check(not sim.command({"kind": "assign_tower", "uid": "u-BAR03", "tower_uid": roost.uid}).ok, "melee ally cannot occupy ranged tower")
	var balance = sim.coins
	for i in range(4):
		sim.command({"kind": "undo"}); sim.command({"kind": "redo"})
	check(sim.coins == balance, "undo/redo cannot manufacture supplies")
	check(sim.command({"kind": "remove_tower", "uid": roost.uid}).ok and sim.towers.is_empty(), "tower salvage succeeds")
	check(sim.units[0].tower_uid == "", "salvage releases occupant")
	sim.start_wave()
	check(sim.command({"kind": "set_mode", "uid": "u-BAR01", "mode": "Patrol"}).ok and sim.units[0].mode == "Patrol", "movement orders can change live during combat")
	check(not sim.command({"kind": "cast", "uid": roost.uid, "slot": 0}).ok, "structures cannot impersonate recruit abilities")
	check(not sim.restore({"version": 1, "map": {}, "units": "corrupt"}).ok, "malformed save arrays rejected safely")

func _test_full_battle():
	var sim = Simulation.new(catalog); sim.setup(catalog.get_map("MAP01"), ["BAR01", "BAR03"])
	sim.command({"kind": "place_tower", "tower_id": "TOWER04", "cell": [20, 7]})
	sim.command({"kind": "place_tower", "tower_id": "TOWER04", "cell": [23, 13]})
	var ticks: int = 0
	while sim.phase not in ["victory", "defeat"] and ticks < 30000:
		if sim.phase == "planning": sim.start_wave()
		if sim.phase == "combat":
			for u in sim.units:
				for slot in range(2):
					if u.hp > 0 and u.cooldowns[slot] <= 0: sim.command({"kind": "cast", "uid": u.uid, "slot": slot})
		sim.step(1.0 / 30.0); ticks += 1
	print("First-battle harness: phase=%s wave=%d gate=%.1f kills=%d elapsed=%.1f" % [sim.phase, sim.wave, sim.gate_hp, sim.kills, sim.elapsed])
	check(sim.phase == "victory", "first four-wave battle is winnable with two allies and planned defences")
	check(sim.wave == 4 and sim.kills > 30 and sim.gate_hp > 0, "four actual waves completed")
	var single = Simulation.new(catalog); single.setup(catalog.get_map("MAP01"), [])
	single.phase = "combat"; single.wave = 1
	var one = single._spawn_enemy("MOB01", 0, false, Vector2(29, 10)); one.waypoint = single._enemy_paths[0].size()
	single.step(1.0 / 30.0); single.step(1.0 / 30.0)
	check(single.gate_hp == 96.0, "an escaped monster damages the gate exactly once")
	var losing = Simulation.new(catalog); losing.setup(catalog.get_map("MAP01"), [])
	losing.phase = "combat"; losing.wave = 1
	for i in range(26):
		var leak = losing._spawn_enemy("MOB01", 0, false, Vector2(29, 10)); leak.waypoint = losing._enemy_paths[0].size()
	losing.step(1.0 / 30.0)
	check(losing.phase == "defeat" and losing.gate_hp == 0, "gate reaches actual defeat at zero")

func _test_trap_fuse():
	var sim = Simulation.new(catalog); sim.setup(catalog.get_map("MAP01"), ["BAR01"])
	sim.command({"kind": "place_trap", "trap_id": "TRAP02", "cell": [12, 10]})
	var target = enemy(sim, "MOB01", Vector2(12, 10))
	sim._tick_traps(0.4)
	check(target.hp == 1000.0 and sim.traps[0].state == "armed", "Cinder Pot warns before dealing damage")
	sim._tick_traps(0.39)
	check(target.hp == 1000.0, "Cinder Pot preserves its full visible 0.8-second fuse")
	sim._tick_traps(0.02)
	check(target.hp == 988.0 and sim.traps[0].state == "spent", "Cinder Pot deals bounded damage once after its fuse")

func _test_gate_capacity():
	var sim = Simulation.new(catalog)
	sim.setup(catalog.get_map("MAP01"), [])
	check(sim.gate_max_hp == 100.0 and sim.gate_hp == 100.0, "gate defaults to 100 capacity")
	sim.gate_max_hp = 115.0; sim.gate_hp = sim.gate_max_hp
	var restored = Simulation.new(catalog)
	var save = JSON.parse_string(JSON.stringify(sim.snapshot()))
	check(save.gate_max_hp == 115.0 and restored.restore(save).ok, "story gate capacity is JSON saved and restored")
	check(restored.gate_max_hp == 115.0 and restored.gate_hp == 115.0, "restoring a story reward preserves health above 100")
	restored.phase = "combat"; restored.wave = 1
	for i in range(26):
		var leak = restored._spawn_enemy("MOB01", 0, false, Vector2(29, 10))
		leak.waypoint = restored._enemy_paths[0].size()
	restored.step(1.0 / 30.0)
	check(restored.gate_hp == 11.0 and restored.phase != "defeat", "bonus health actually survives damage that destroys a normal gate")
	var damaged_save = JSON.parse_string(JSON.stringify(restored.snapshot()))
	check(sim.restore(damaged_save).ok and sim.gate_hp == 11.0 and sim.gate_max_hp == 115.0, "damaged fortified gates retain their current and maximum health")
	var legacy = save.duplicate(true); legacy.erase("gate_max_hp"); legacy.gate_hp = 73.0
	check(sim.restore(legacy).ok and sim.gate_hp == 73.0 and sim.gate_max_hp == 100.0, "version-one saves without gate capacity remain compatible")
	var excessive = save.duplicate(true); excessive.gate_max_hp = 1000.0; excessive.gate_hp = 999.0
	check(sim.restore(excessive).ok and sim.gate_max_hp == 200.0 and sim.gate_hp == 200.0, "gate restoration bounds maximum health at 200")
	var invalid = save.duplicate(true); invalid.gate_max_hp = "broken"
	var before = JSON.stringify(sim.snapshot())
	check(not sim.restore(invalid).ok and JSON.stringify(sim.snapshot()) == before, "invalid gate capacity is rejected without mutating the battle")
	invalid = save.duplicate(true); invalid.gate_hp = NAN
	check(not sim.restore(invalid).ok, "nonfinite gate health cannot corrupt a save restore")
	sim.setup(catalog.get_map("MAP02"), [])
	check(sim.gate_max_hp == 100.0 and sim.gate_hp == 100.0, "new battles reset capacity before applying their own story rewards")

func _test_enemy_health_modifier():
	var baseline = Simulation.new(catalog)
	var rewarded = Simulation.new(catalog)
	baseline.setup(catalog.get_map("MAP06"), ["BAR01"], 1.0)
	rewarded.setup(catalog.get_map("MAP06"), ["BAR01"], 1.0, 0.92)
	baseline.start_wave(); rewarded.start_wave()
	check(baseline._spawn_queue == rewarded._spawn_queue, "story enemy-health reduction preserves swarm sizes and timing")
	for model in catalog.world.enemies:
		var normal = baseline._spawn_enemy(model.id, 0)
		var reduced = rewarded._spawn_enemy(model.id, 0)
		check(absf(reduced.max_hp - normal.max_hp * 0.92) < 0.0001 and reduced.hp == reduced.max_hp, model.id + " receives the full story HP reduction")
	var restored = Simulation.new(catalog)
	var save = JSON.parse_string(JSON.stringify(rewarded.snapshot()))
	check(restored.restore(save).ok, "enemy-health story modifier can be JSON restored")
	var spawned = restored._spawn_enemy("MOB01", 0)
	var expected = baseline._spawn_enemy("MOB01", 0)
	check(absf(spawned.max_hp - expected.max_hp * 0.92) < 0.0001, "enemies spawned after a restore retain the story health reduction")
	var legacy = save.duplicate(true); legacy.erase("enemy_hp_multiplier")
	check(restored.restore(legacy).ok and restored._enemy_hp_multiplier == 1.0, "older saves default to normal enemy health without rewriting living enemies")
	check(absf(restored.enemies[0].max_hp - rewarded.enemies[0].max_hp) < 0.0001, "restoring existing health does not apply the modifier twice")
	var invalid = save.duplicate(true); invalid.enemy_hp_multiplier = {"broken": true}
	check(not restored.restore(invalid).ok, "malformed saved enemy health modifiers are rejected")
	rewarded.setup(catalog.get_map("MAP01"), ["BAR01"])
	check(rewarded._enemy_hp_multiplier == 1.0, "a fresh battle resets the previous story health modifier")
