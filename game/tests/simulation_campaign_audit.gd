extends SceneTree
## Deterministic automated tactical audit. Outcomes are observations, not balance claims.
## Every placement, upgrade and cast uses the same command API as the shipped UI.
const Catalog = preload("res://scripts/catalog.gd")
const Simulation = preload("res://scripts/simulation.gd")
const MAX_TICKS = 30000
var catalog = Catalog.new()
var passed: int = 0
var failed: int = 0

func _initialize():
	if "--boss-only" in OS.get_cmdline_user_args():
		run_map("MAP06", ["BAR01", "BAR03", "GEN01", "GEN03", "CAP01", "CAP04", "CAP07"], "standalone-boss")
		print("SIMULATION CAMPAIGN AUDIT: %d passed, %d failed" % [passed, failed])
		quit(1 if failed else 0)
		return
	var party: Array = ["BAR01", "BAR03"]
	var total_seconds: float = 0.0
	var all_won: bool = true
	var previous_won: bool = true
	var original_survived: int = 2
	for index in range(1, 7):
		if index == 3 and previous_won:
			# The requested successful-recruitment route adds two generals after the ford.
			for id in ["GEN01", "GEN03"]:
				if id not in party: party.append(id)
		if index == 4:
			var recruits: Array = ["CAP01", "CAP04", "CAP07"] if previous_won and original_survived > 1 else ["CAP01", "CAP04", "CAP07", "CAP03", "CAP08"]
			for id in recruits:
				if id not in party: party.append(id)
		var result = run_map("MAP%02d" % index, party, "continuous")
		party = result.survivors
		previous_won = result.phase == "victory"
		original_survived = int("BAR01" in party) + int("BAR03" in party)
		total_seconds += result.elapsed
		all_won = all_won and result.phase == "victory"
	for index in range(3, 7):
		run_map("MAP%02d" % index, ["BAR01", "BAR03", "GEN01", "GEN03"] if index == 3 else ["BAR01", "BAR03", "GEN01", "GEN03", "CAP01", "CAP04", "CAP07"], "standalone")
	print("CAMPAIGN AUDIT OBSERVATION: total elapsed including planning %.1fs; all maps won=%s; final survivors=%s" % [total_seconds, str(all_won), str(party)])
	print("SIMULATION CAMPAIGN AUDIT: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)

func check(condition: bool, label: String):
	if condition: passed += 1
	else:
		failed += 1
		push_error("FAIL: " + label)

func run_map(map_id: String, party: Array, mode: String = "standalone") -> Dictionary:
	var started: int = Time.get_ticks_msec()
	var sim = Simulation.new(catalog)
	sim.setup(catalog.get_map(map_id), party)
	var input_party: Array = party.duplicate()
	var ticks: int = 0
	var stopped: bool = false
	var boss_spawned: bool = false
	var boss_defeated: bool = false
	var boss_escaped: bool = false
	var boss_min_hp: float = INF
	var boss_max_phase: int = 0
	var boss_engage_ordered: bool = false
	while sim.phase not in ["victory", "defeat"] and ticks < MAX_TICKS:
		if sim.phase == "planning":
			prepare_defenses(sim)
			if sim.wave > 0:
				for wait_tick in range(240): sim.step(1.0 / 30.0)
			var start = sim.start_wave()
			if not start.ok:
				stopped = true
				print("AUDIT unable to start %s wave %d: %s" % [map_id, sim.wave + 1, start.message])
				break
		if sim.phase == "combat":
			if "--guard-boss" not in OS.get_cmdline_user_args() and not boss_engage_ordered and sim.enemies.any(func(e): return e.id == "BOSS01" and e.hp > 0):
				# Guard holds a point; explicitly engage the longer-reach boss with melee allies.
				for ally in sim.units:
					if ally.hp > 0: sim.command({"kind": "set_mode", "uid": ally.uid, "mode": "Advance"})
				boss_engage_ordered = true
			for u in sim.units:
				for slot in range(2):
					if u.hp > 0 and u.cooldowns[slot] <= 0 and should_cast(sim, u, slot):
						sim.command({"kind": "cast", "uid": u.uid, "slot": slot})
		sim.step(1.0 / 30.0)
		for e in sim.enemies:
			if e.id == "BOSS01":
				boss_spawned = true
				boss_defeated = boss_defeated or e.hp <= 0
				boss_escaped = boss_escaped or e.get("escaped", false)
				boss_min_hp = minf(boss_min_hp, e.hp)
				boss_max_phase = maxi(boss_max_phase, int(e.get("boss_phase", 0)))
		ticks += 1
	var result = {"mode": mode, "map": map_id, "phase": sim.phase, "wave": sim.wave, "gate": sim.gate_hp, "kills": sim.kills, "surrendered": sim.surrendered, "input_party": input_party, "survivors": sim.survivors(), "elapsed": sim.elapsed, "wall_ms": Time.get_ticks_msec() - started, "coins": sim.coins, "boss_spawned": boss_spawned, "boss_defeated": boss_defeated, "boss_escaped": boss_escaped, "boss_min_hp": boss_min_hp if boss_spawned else null, "boss_max_phase": boss_max_phase}
	print("CAMPAIGN AUDIT: " + JSON.stringify(result))
	check(not stopped and sim.phase in ["victory", "defeat"], map_id + " reaches a real terminal result without timeout")
	check(sim.gate_hp >= 0 and sim.gate_hp <= 200 and is_finite(sim.elapsed), map_id + " maintains finite bounded battle state")
	check(sim.survivors().all(func(id): return id in input_party), map_id + " preserves actual survivor membership")
	if map_id == "MAP06" and mode.begins_with("standalone"):
		check(boss_spawned, "standalone final encounter actually spawns the Demon King")
		check(boss_defeated and boss_max_phase == 3, "standalone final encounter defeats all three boss phases")
		check(not boss_escaped, "standalone boss kill is not a gate-leak victory")
	return result

func prepare_defenses(sim):
	# Keep a compact defensive formation rather than sending the lone Tanker upfield.
	# Healers and ranged allies stand immediately behind melee allies, covering both routes.
	var positions: Array = [[22,9], [21,10], [22,10], [23,11], [21,11], [23,9], [24,10], [24,11], [20,10], [20,11]]
	if sim.map.id == "MAP02":
		positions = [[27,10], [26,11], [26,10], [27,11], [25,10], [25,11], [28,10], [28,11], [24,10], [24,11]]
	for i in range(sim.units.size()):
		var u: Dictionary = sim.units[i]
		if u.hp <= 0: continue
		sim.command({"kind": "move_unit", "uid": u.uid, "cell": positions[i], "mode": "Guard"})
	# Five legal marked pads, prioritized for the two downstream enemy approaches.
	var pads: Array = sim.map.get("tower_pad_centers", []).duplicate(true)
	pads.sort_custom(func(a, b): return int(a[0]) > int(b[0]))
	# Salvage destroyed structures before replacing them. Spent traps are removed legally.
	for tower in sim.towers.duplicate():
		if tower.hp <= 0: sim.command({"kind": "remove_tower", "uid": tower.uid})
	for trap in sim.traps.duplicate():
		if trap.state == "spent": sim.command({"kind": "remove_trap", "uid": trap.uid})
	# One Hearthward supports the compact formation; remaining pads carry bolts.
	var hearth_cell: Array = [20,7] if sim.map.id == "MAP01" else [22,15] if sim.map.id == "MAP02" else [21,7] if sim.map.id == "MAP03" else [23,7] if sim.map.id == "MAP04" else [22,7] if sim.map.id == "MAP05" else [21,6]
	if not sim.towers.any(func(t): return t.id == "TOWER03"):
		sim.command({"kind": "place_tower", "tower_id": "TOWER03", "cell": hearth_cell})
	# Two fresh Bolt Cradles plus a Hearthward cost 225 supplies.
	for pad in pads:
		if sim.towers.size() >= 5: break
		sim.command({"kind": "place_tower", "tower_id": "TOWER04", "cell": pad})
	# Upgrading restores a damaged tower and increases its output without any free healing.
	for tower in sim.towers:
		if (sim.towers.size() >= 5 or tower.hp < tower.max_hp * 0.5) and tower.level < 3 and sim.coins >= (65 if tower.level == 1 else 95):
			sim.command({"kind": "upgrade_tower", "uid": tower.uid})
	# Leftover supplies become individually positioned damage/slow traps near late approaches.
	var trap_cells: Array = []
	for track in sim.map.get("enemy_tracks", []):
		var points: Array = track.get("points", [])
		for i in range(points.size() - 1):
			var from = Vector2(points[i][0], points[i][1])
			var to = Vector2(points[i + 1][0], points[i + 1][1])
			var length: int = maxi(1, ceili(from.distance_to(to)))
			for j in range(length + 1):
				var spot: Vector2 = from.lerp(to, float(j) / length).round()
				var cell: Array = [int(spot.x), int(spot.y)]
				if spot.x >= 12 and spot.x <= 27 and cell not in trap_cells: trap_cells.append(cell)
	trap_cells.sort_custom(func(a, b): return int(a[0]) > int(b[0]))
	for cell in trap_cells:
		if sim.coins < 12: break
		sim.command({"kind": "place_trap", "trap_id": "TRAP01", "cell": cell})

func should_cast(sim, unit: Dictionary, slot: int) -> bool:
	var ability: Dictionary = catalog.get_ability(unit.id, slot)
	var nearest: float = INF
	for enemy in sim.enemies:
		if enemy.get("hostile", true) and enemy.hp > 0 and not enemy.get("escaped", false):
			nearest = minf(nearest, unit.pos.distance_to(enemy.pos))
	for effect in ability.get("effects", []):
		var kind: String = str(effect.get("kind", ""))
		var radius: float = minf(float(effect.get("range", 3.0)), float(effect.get("radius", 3.0)))
		if kind == "heal" or kind == "zone" and float(effect.get("heal", 0)) > 0:
			for ally in sim.units:
				if ally.hp > 0 and ally.hp < ally.max_hp * 0.8 and unit.pos.distance_to(ally.pos) <= radius:
					return true
		elif effect.get("target", "enemy") == "enemy" and nearest <= radius:
			return true
		elif kind in ["shield", "buff", "intercept"] and nearest <= maxf(2.5, float(unit.range)):
			return true
	return false
