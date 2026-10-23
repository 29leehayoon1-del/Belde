extends RefCounted
class_name BeldeSimulation

## Deterministic, tile-space battle model. It owns all live combat and layout state.
## UI and native-message clients use the same validated command entry point.
const FIXED_STEP = 1.0 / 30.0
const MAX_UNITS = 10
const TOWER_COSTS = {"TOWER01": 55, "TOWER02": 45, "TOWER03": 65, "TOWER04": 80}
const TRAP_COSTS = {"TRAP01": 12, "TRAP02": 16, "TRAP03": 14}
const MODES = ["Guard", "Patrol", "Advance"]

var catalog = null
var units: Array = []
var enemies: Array = []
var towers: Array = []
var traps: Array = []
var effects: Array = []
var projectiles: Array = []
var phase: String = "planning"
var map: Dictionary = {}
var wave: int = 0
var max_waves: int = 4
var coins: int = 300
var gate_hp: float = 100.0
var gate_max_hp: float = 100.0:
	set(value):
		gate_max_hp = clampf(value, 100.0, 200.0) if is_finite(value) else 100.0
		gate_hp = minf(gate_hp, gate_max_hp)
var revision: int = 0
var events: Array = []
var speed: float = 1.0
var elapsed: float = 0.0
var kills: int = 0
var surrendered: int = 0
var rescued: int = 0
var damage_dealt: float = 0.0

var _rng = RandomNumberGenerator.new()
var _accumulator: float = 0.0
var _wave_clock: float = 0.0
var _next_uid: int = 1
var _difficulty: float = 1.0
var _enemy_hp_multiplier: float = 1.0
var _map_index: int = 1
var _enemy_paths: Array = []
var _patrol_paths: Array = []
var _spawn_queue: Array = []
var _scheduled: Array = []
var _zones: Array = []
var _history: Array = []
var _future: Array = []
var _enemy_models: Dictionary = {}
var _party_ids: Array = []
var _wave_kills: int = 0
var _wave_surrendered: int = 0
var _seed: int = 20261022
var _fallback_characters: Dictionary = {}
var _fallback_abilities: Dictionary = {}

func _init(source = null):
	catalog = source
	_rng.seed = _seed

func setup(map_data: Dictionary, party_ids: Array, difficulty: float = 1.0, enemy_hp_multiplier: float = 1.0):
	map = map_data.duplicate(true)
	_party_ids = []
	for party_id in party_ids:
		if str(party_id) not in _party_ids:
			_party_ids.append(str(party_id))
	_difficulty = clampf(difficulty, 0.5, 3.0)
	_enemy_hp_multiplier = clampf(enemy_hp_multiplier, 0.25, 3.0) if is_finite(enemy_hp_multiplier) else 1.0
	_map_index = clampi(int(str(map.get("id", "MAP01")).right(2)), 1, 6)
	_rng.seed = _seed + _map_index * 101
	units.clear(); enemies.clear(); towers.clear(); traps.clear()
	effects.clear(); projectiles.clear(); events.clear()
	_history.clear(); _future.clear(); _spawn_queue.clear(); _scheduled.clear(); _zones.clear()
	phase = "planning"; wave = 0; max_waves = int(map.get("runtime_waves", map.get("wave_count", 4)))
	coins = int(map.get("starting_coins", 300 + 30 * max(0, _party_ids.size() - 2)))
	gate_max_hp = 100.0; gate_hp = gate_max_hp; revision = 0; elapsed = 0.0; kills = 0; surrendered = 0; rescued = 0; damage_dealt = 0.0
	_next_uid = 1; _wave_clock = 0.0; _accumulator = 0.0
	_load_models()
	_prepare_paths()
	var starting_cells = [Vector2(20, 9), Vector2(23, 11), Vector2(18, 11), Vector2(25, 9), Vector2(16, 9), Vector2(21, 13), Vector2(25, 13), Vector2(17, 13), Vector2(27, 11), Vector2(27, 8)]
	for i in range(min(_party_ids.size(), MAX_UNITS)):
		var data = _character(str(_party_ids[i]))
		if data.is_empty():
			continue
		var unit = _make_unit(data, starting_cells[i])
		if unit.get("class", "") == "Tanker":
			unit["mode"] = "Advance"
		units.append(unit)
	_event("map_ready", {"map_id": map.get("id", "MAP01"), "party": units.size()})

func _load_models():
	_enemy_models.clear()
	var world: Dictionary = {}
	if catalog != null:
		var loaded = catalog.get("world")
		if loaded is Dictionary:
			world = loaded
	if world.is_empty():
		world = _read_json("res://data/world.json", {})
	for enemy in world.get("enemies", []):
		_enemy_models[str(enemy.get("id", ""))] = enemy
	if catalog == null:
		var chars = _read_json("res://data/characters.json", [])
		if chars is Dictionary:
			chars = chars.get("characters", [])
		for character in chars:
			_fallback_characters[str(character.get("id", ""))] = character
		_fallback_abilities = _read_json("res://data/abilities.json", {})

func _read_json(path: String, default_value):
	if not FileAccess.file_exists(path):
		return default_value
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed != null else default_value

func _character(id: String) -> Dictionary:
	if catalog != null and catalog.has_method("get_character"):
		return catalog.get_character(id)
	return _fallback_characters.get(id, {})

func _ability(id: String, slot: int) -> Dictionary:
	if catalog != null and catalog.has_method("get_ability"):
		return catalog.get_ability(id, slot)
	var entry = _fallback_abilities.get(id + ":" + str(slot), {})
	if entry is Dictionary:
		return entry
	return {}

func _prepare_paths():
	_enemy_paths.clear(); _patrol_paths.clear()
	var tracks = map.get("enemy_tracks", [])
	var main_path: Array = []
	if not tracks.is_empty():
		main_path = _vectors(tracks[0].get("points", []))
	if main_path.size() < 2:
		main_path = [Vector2(1, 10), Vector2(29, 10)]
	for track in tracks:
		var path = _vectors(track.get("points", []))
		if path.size() < 2:
			continue
		if path[-1].distance_to(main_path[-1]) > 0.25:
			var nearest: int = 0
			var distance: float = INF
			for i in range(main_path.size()):
				var d = path[-1].distance_to(main_path[i])
				if d < distance:
					distance = d; nearest = i
			if distance > 0.25:
				path.append(main_path[nearest])
			for i in range(nearest + 1, main_path.size()):
				path.append(main_path[i])
		_enemy_paths.append(path)
	if _enemy_paths.is_empty():
		_enemy_paths.append(main_path)
	for track in map.get("ally_patrol_tracks", []):
		var path = _vectors(track.get("points", []))
		if path.size() >= 2:
			_patrol_paths.append(path)
	if _patrol_paths.is_empty():
		_patrol_paths.append([Vector2(5, 6), Vector2(26, 6)])

func _vectors(points) -> Array:
	var result: Array = []
	for point in points:
		result.append(_vec(point))
	return result

func _vec(value) -> Vector2:
	if value is Vector2:
		return value
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	if value is Dictionary:
		return Vector2(float(value.get("x", 0)), float(value.get("y", 0)))
	return Vector2.ZERO

func _make_unit(data: Dictionary, position: Vector2) -> Dictionary:
	var stats: Dictionary = data.get("stats", {})
	var basic: Dictionary = stats.get("basic_attack", {})
	var role = str(data.get("class", "DPS"))
	var max_health = float(stats.get("hp", 100))
	var delivery = str(basic.get("delivery", "projectile"))
	var unit = {
		"id": str(data.get("id", "")), "uid": "u-" + str(data.get("id", "")),
		"name": str(data.get("name", "Ally")), "class": role, "faction": "ally",
		"pos": position, "anchor": position, "facing": Vector2(1, 0.3),
		"hp": max_health, "max_hp": max_health, "shield": 0.0,
		"damage": float(basic.get("damage", stats.get("basic_attack_damage", 12))),
		"interval": float(basic.get("interval_seconds", stats.get("basic_attack_interval_seconds", 1.0))),
		"range": float(basic.get("range_tiles", stats.get("basic_attack_range_tiles", 3.0))),
		"move_speed": float(stats.get("move_speed_tiles_per_second", 1.8)),
		"heal_rate": float(stats.get("baseline_heal_hp_per_second", stats.get("base_healing_hp_per_second", 12.0 if role == "Healer" else 0.0))),
		"ranged": not ("melee" in delivery or "approach" in delivery),
		"mode": "Guard", "state": "idle", "state_timer": 0.0, "animation_time": 0.0,
		"attack_timer": 0.0, "cooldowns": [0.0, 0.0], "statuses": [],
		"patrol_index": 0, "patrol_direction": 1, "patrol_path": _closest_patrol(position),
		"strategy_timer": 4.0, "tower_uid": "", "kills": 0, "damage_dealt": 0.0,
	}
	return unit

func _closest_patrol(position: Vector2) -> int:
	var best: int = 0
	var distance: float = INF
	for i in range(_patrol_paths.size()):
		for point in _patrol_paths[i]:
			var d = position.distance_to(point)
			if d < distance:
				distance = d; best = i
	return best

func start_wave() -> Dictionary:
	if phase != "planning":
		return _result(false, "Wait until this wave ends.")
	if wave >= max_waves:
		return _result(false, "This battlefield is complete.")
	if survivors().is_empty() and not towers.any(func(t): return t.get("id", "") == "TOWER04"):
		return _result(false, "Deploy an ally or a Bolt Cradle before starting.")
	wave += 1; phase = "combat"; _wave_clock = 0.0; _wave_kills = 0; _wave_surrendered = 0
	_history.clear(); _future.clear(); _spawn_queue.clear()
	for tower in towers:
		tower["fuel"] = 60.0
	var count = int(round((10 + wave * 4 + _map_index * 2) * _difficulty))
	count = clampi(count, 10, 64)
	var spacing = maxf(0.7, 1.45 - wave * 0.09 - _map_index * 0.035)
	for i in range(count):
		var pool: Array = ["MOB01", "MOB02"]
		if _map_index >= 2:
			pool.append("MOB03"); pool.append("MOB05")
		if _map_index >= 3:
			pool.append("MOB04"); pool.append("MOB07")
		if _map_index >= 4:
			pool.append("MOB06"); pool.append("MOB08")
		var model = pool[_rng.randi_range(0, pool.size() - 1)]
		if i < 3 and _map_index == 1:
			model = "MOB01"
		_spawn_queue.append({"at": 0.8 + i * spacing, "id": model, "path": i % _enemy_paths.size(), "neutral": _map_index == 2 and wave == 1 and i < 2})
	if _map_index == 6 and wave == max_waves:
		_spawn_queue.append({"at": count * spacing * 0.55, "id": "BOSS01", "path": 0, "neutral": false})
		_spawn_queue.sort_custom(func(a, b): return a["at"] < b["at"])
	_event("wave_started", {"wave": wave, "count": _spawn_queue.size()})
	return _result(true, "Wave %d is approaching." % wave)

func step(delta: float):
	if delta <= 0.0:
		return
	_accumulator = minf(_accumulator + minf(delta, 1.0) * clampf(speed, 0.0, 4.0), 1.5)
	while _accumulator >= FIXED_STEP:
		_accumulator -= FIXED_STEP
		_tick(FIXED_STEP)

func _tick(dt: float):
	elapsed += dt
	_tick_visuals(dt)
	if phase != "combat":
		if phase == "planning":
			_tick_towers(dt, true)
		return
	_wave_clock += dt
	while not _spawn_queue.is_empty() and float(_spawn_queue[0]["at"]) <= _wave_clock:
		var spawn: Dictionary = _spawn_queue.pop_front()
		_spawn_enemy(str(spawn["id"]), int(spawn["path"]), bool(spawn.get("neutral", false)))
	_tick_scheduled(dt)
	_tick_zones(dt)
	for unit in units:
		_tick_unit(unit, dt)
	for enemy in enemies.duplicate():
		_tick_enemy(enemy, dt)
	_tick_towers(dt, false)
	_tick_traps(dt)
	_tick_projectiles(dt)
	var live_enemies: Array = []
	for enemy in enemies:
		if float(enemy.get("hp", 0.0)) > 0.0 and not bool(enemy.get("escaped", false)):
			live_enemies.append(enemy)
		elif float(enemy.get("corpse_time", 0.0)) > 0.0:
			enemy["corpse_time"] = float(enemy.get("corpse_time", 0.0)) - dt
			live_enemies.append(enemy)
	enemies = live_enemies
	if gate_hp <= 0.0:
		gate_hp = 0.0; phase = "defeat"
		_spawn_queue.clear(); _scheduled.clear()
		_event("battle_lost", {"survivors": survivors()})
		return
	var hostile_remaining = enemies.any(func(e): return e.get("hostile", true) and float(e.get("hp", 0.0)) > 0.0 and not e.get("escaped", false))
	if _spawn_queue.is_empty() and not hostile_remaining:
		_complete_wave()

func _complete_wave():
	coins += 35 + 8 * wave
	_scheduled.clear()
	for unit in units:
		if float(unit["hp"]) > 0:
			unit["hp"] = minf(float(unit["max_hp"]), float(unit["hp"]) + float(unit["max_hp"]) * 0.08)
			unit["state"] = "idle"
			unit["state_timer"] = 0.0
	for enemy in enemies:
		if not enemy.get("hostile", true):
			enemy["escaped"] = true
	if wave >= max_waves:
		phase = "victory"
		_event("battle_won", {"survivors": survivors(), "surrendered": surrendered, "kills": kills})
	else:
		phase = "planning"
		_event("wave_complete", {"wave": wave, "coins": coins, "surrendered": _wave_surrendered})

func _spawn_enemy(id: String, path_index: int, neutral: bool = false, override_pos = null) -> Dictionary:
	var model: Dictionary = _enemy_models.get(id, {})
	var stats: Dictionary = model.get("stats", model.get("runtime_stats", model.get("draft_stats", {})))
	var path: Array = _enemy_paths[posmod(path_index, _enemy_paths.size())]
	var hp = float(stats.get("hp", 2400 if id == "BOSS01" else 30))
	if id != "BOSS01":
		hp *= 0.82 + 0.09 * _map_index + 0.035 * wave
	else:
		hp *= 0.8 + 0.15 * _difficulty
	hp *= _enemy_hp_multiplier
	var position: Vector2 = path[0] if override_pos == null else _vec(override_pos)
	var enemy = {
		"id": id, "uid": "e-" + str(_next_uid), "name": str(model.get("name", id)),
		"pos": position, "facing": Vector2.RIGHT, "hp": hp, "max_hp": hp, "shield": 0.0,
		"damage": float(stats.get("basic_damage", stats.get("damage", 4))),
		"interval": float(stats.get("attack_interval_s", stats.get("interval", stats.get("interval_seconds", 1.2)))),
		"move_speed": float(stats.get("movement_tiles_s", stats.get("move_speed", 0.9))),
		"range": float(stats.get("range", 2.6 if id in ["MOB02", "MOB04", "MOB08"] else 1.1)),
		"ranged": id in ["MOB02", "MOB04", "MOB08"], "hostile": not neutral,
		"faction": "neutral" if neutral else "enemy", "noncombatant": neutral,
		"state": "walk", "state_timer": 0.0, "animation_time": 0.0, "statuses": [],
		"attack_timer": _rng.randf_range(0.3, 1.0), "cooldowns": [_rng.randf_range(5.0, 9.0), _rng.randf_range(10.0, 15.0)],
		"path_index": posmod(path_index, _enemy_paths.size()), "waypoint": 1,
		"corpse_time": 0.0, "escaped": false, "boss_phase": 1,
		"summoned": false, "anchor": false,
	}
	_next_uid += 1
	enemies.append(enemy)
	_event("enemy_spawned", {"id": id, "uid": enemy["uid"], "noncombatant": neutral})
	return enemy

func _tick_visuals(dt: float):
	for entity in units + enemies:
		entity["animation_time"] = float(entity.get("animation_time", 0.0)) + dt
		entity["state_timer"] = maxf(0.0, float(entity.get("state_timer", 0.0)) - dt)
	var alive_effects: Array = []
	for effect in effects:
		effect["ttl"] = float(effect.get("ttl", 0.0)) - dt
		if effect["ttl"] > 0.0:
			alive_effects.append(effect)
	effects = alive_effects

func _tick_unit(unit: Dictionary, dt: float):
	if float(unit["hp"]) <= 0.0:
		unit["state"] = "downed"
		return
	_tick_statuses(unit, dt)
	for i in range(2):
		unit["cooldowns"][i] = maxf(0.0, float(unit["cooldowns"][i]) - dt)
	unit["windup"] = maxf(0.0, float(unit.get("windup", 0)) - dt)
	unit["attack_timer"] = maxf(0.0, float(unit["attack_timer"]) - dt * _stat_multiplier(unit, "attack_speed"))
	if _has_status(unit, "stun"):
		return
	var nearest = _nearest_hostile(unit["pos"], 9.0, bool(unit.get("ranged", false)))
	var healer_target = _healing_target(unit) if unit["class"] == "Healer" else {}
	var target: Dictionary = healer_target if not healer_target.is_empty() else nearest
	var destination: Vector2 = unit["pos"]
	var can_move = not _has_status(unit, "root") and str(unit.get("tower_uid", "")).is_empty()
	if can_move:
		if unit["mode"] == "Patrol":
			destination = _patrol_destination(unit)
		elif unit["mode"] == "Advance" and not target.is_empty():
			var desired = _effective_range(unit) * 0.8
			if unit["pos"].distance_to(target["pos"]) > desired:
				destination = target["pos"]
		elif unit["mode"] == "Advance" and target.is_empty():
			destination = unit["anchor"]
		if unit["class"] == "Strategist" and not nearest.is_empty() and unit["pos"].distance_to(nearest["pos"]) < 1.8:
			destination = unit["pos"] + (unit["pos"] - nearest["pos"]).normalized() * 2.0
			unit["strategy_timer"] = float(unit["strategy_timer"]) - dt
			if unit["strategy_timer"] <= 0.0:
				_make_zone(unit, {"kind": "trap", "damage": 9.0, "slow": 0.25, "duration": 5.0, "radius": 0.8, "max_targets": 2, "ticks": 1}, nearest["pos"])
				unit["strategy_timer"] = 12.0
		if unit["pos"].distance_to(destination) > 0.08:
			_move_entity(unit, destination, dt, false)
		elif float(unit["state_timer"]) <= 0.0:
			unit["state"] = "idle"
	elif float(unit["state_timer"]) <= 0.0:
		unit["state"] = "idle"
	if not healer_target.is_empty() and float(unit["attack_timer"]) <= 0.0 and float(unit.get("windup", 0)) <= 0.0:
		_heal(healer_target, float(unit["heal_rate"]) * float(unit["interval"]), unit)
		unit["attack_timer"] = float(unit["interval"])
		_pose(unit, "attack", 0.32, healer_target["pos"])
	elif not nearest.is_empty() and float(unit["attack_timer"]) <= 0.0 and float(unit.get("windup", 0)) <= 0.0 and unit["pos"].distance_to(nearest["pos"]) <= _effective_range(unit):
		_basic_attack(unit, nearest)
	_update_roost(unit)

func _healing_target(healer: Dictionary) -> Dictionary:
	var best: Dictionary = {}
	var best_score: float = -INF
	for ally in units:
		if float(ally["hp"]) <= 0.0 or float(ally["hp"]) >= float(ally["max_hp"]) - 0.1:
			continue
		if healer["pos"].distance_to(ally["pos"]) > maxf(3.0, _effective_range(healer)):
			continue
		var missing = 1.0 - float(ally["hp"]) / float(ally["max_hp"])
		var priority = 0.12 if ally["class"] in ["Tanker", "DPS"] else 0.0
		var score = missing + priority
		if missing < 0.08:
			continue
		if score > best_score:
			best_score = score; best = ally
	return best

func _patrol_destination(unit: Dictionary) -> Vector2:
	var path: Array = _patrol_paths[posmod(int(unit["patrol_path"]), _patrol_paths.size())]
	var index = clampi(int(unit["patrol_index"]), 0, path.size() - 1)
	if unit["pos"].distance_to(path[index]) < 0.15:
		index += int(unit["patrol_direction"])
		if index >= path.size():
			unit["patrol_direction"] = -1; index = path.size() - 2
		elif index < 0:
			unit["patrol_direction"] = 1; index = 1
		unit["patrol_index"] = index
	return path[index]

func _move_entity(entity: Dictionary, destination: Vector2, dt: float, enemy: bool):
	var direction: Vector2 = destination - entity["pos"]
	if direction.length() < 0.025:
		return
	var velocity = float(entity["move_speed"]) * _stat_multiplier(entity, "move_speed")
	if _has_status(entity, "root") or _has_status(entity, "stun"):
		velocity = 0.0
	var step_length = minf(direction.length(), velocity * dt)
	var proposed: Vector2 = entity["pos"] + direction.normalized() * step_length
	if not enemy and _tower_collision(proposed, str(entity.get("tower_uid", ""))):
		var perpendicular = direction.normalized().orthogonal()
		var alternate: Vector2 = entity["pos"] + perpendicular * step_length
		if _tower_collision(alternate, ""):
			alternate = entity["pos"] - perpendicular * step_length
		proposed = entity["pos"] if _tower_collision(alternate, "") else alternate
	entity["facing"] = direction.normalized()
	entity["pos"] = Vector2(clampf(proposed.x, 0.0, float(_grid_size().x - 1)), clampf(proposed.y, 0.0, float(_grid_size().y - 1)))
	if float(entity.get("state_timer", 0.0)) <= 0.0 and step_length > 0.001:
		entity["state"] = "walk"

func _tick_enemy(enemy: Dictionary, dt: float):
	if float(enemy["hp"]) <= 0.0 or bool(enemy.get("escaped", false)):
		return
	_tick_statuses(enemy, dt)
	if not enemy.get("hostile", true):
		if enemy.get("state", "") == "surrender":
			return
		_advance_enemy(enemy, dt)
		return
	if enemy.get("anchor", false):
		enemy["expires"] = float(enemy.get("expires", 6)) - dt
		if enemy["expires"] <= 0:
			enemy["hp"] = 0.0
			_break_anchor(enemy, false)
		return
	if enemy["id"] == "BOSS01":
		var ratio = float(enemy["hp"]) / float(enemy["max_hp"])
		enemy["boss_phase"] = 3 if ratio < 0.35 else (2 if ratio < 0.7 else 1)
		if enemy["boss_phase"] == 3:
			enemy["move_speed"] = 0.58
	for i in range(2):
		enemy["cooldowns"][i] = maxf(0.0, float(enemy["cooldowns"][i]) - dt)
	enemy["windup"] = maxf(0.0, float(enemy.get("windup", 0)) - dt)
	enemy["attack_timer"] = maxf(0.0, float(enemy["attack_timer"]) - dt * _stat_multiplier(enemy, "attack_speed"))
	if _has_status(enemy, "stun"):
		return
	var target = _enemy_target(enemy)
	if not target.is_empty() and enemy["pos"].distance_to(target["pos"]) <= _effective_range(enemy) and float(enemy["attack_timer"]) <= 0.0 and float(enemy.get("windup", 0)) <= 0.0:
		_basic_attack(enemy, target)
	var stopped = not target.is_empty() and not enemy["ranged"] and enemy["pos"].distance_to(target["pos"]) <= 0.9
	if not stopped and not _has_status(enemy, "root") and float(enemy.get("windup", 0.0)) <= 0.0:
		_advance_enemy(enemy, dt)
	for i in range(2):
		if float(enemy["cooldowns"][i]) <= 0.0:
			var ability = _enemy_ability(enemy, i)
			if not ability.is_empty() and _can_enemy_cast(enemy, ability):
				_cast_ability(enemy, ability, i, true)
				enemy["cooldowns"][i] = float(ability.get("cooldown_seconds", ability.get("cooldown_s", 16.0)))
	if enemy["id"] != "BOSS01" and not enemy.get("summoned", false) and _wave_kills >= 5 and _wave_surrendered < 3 and float(enemy["hp"]) / float(enemy["max_hp"]) < 0.18:
		if _rng.randf() < dt * 0.32:
			_surrender(enemy)

func _advance_enemy(enemy: Dictionary, dt: float):
	if enemy.get("id", "") != "BOSS01":
		for blocker in units:
			if float(blocker.get("hp", 0)) > 0 and _shield_flag(blocker, "blocks_mobs") and enemy["pos"].distance_to(blocker["pos"]) < 1.0:
				return
	var path: Array = _enemy_paths[int(enemy["path_index"])]
	var waypoint = int(enemy["waypoint"])
	if waypoint >= path.size():
		if enemy.get("hostile", true):
			var leak = 30.0 if enemy["id"] == "BOSS01" else (7.0 if enemy["id"] in ["MOB03", "MOB06"] else 4.0)
			gate_hp = maxf(0.0, gate_hp - leak)
			_fx("gate_hit", path[-1], 0.6, "#f39c64", 1.5)
			_event("gate_hit", {"damage": leak, "gate_hp": gate_hp})
		else:
			rescued += 1
		enemy["escaped"] = true
		return
	_move_entity(enemy, path[waypoint], dt, true)
	if enemy["pos"].distance_to(path[waypoint]) < 0.15:
		enemy["waypoint"] = waypoint + 1

func _enemy_target(enemy: Dictionary) -> Dictionary:
	var forced = _status_source(enemy, "taunt")
	if not forced.is_empty() and float(forced.get("hp", 0)) > 0:
		return forced
	var best: Dictionary = {}
	var distance: float = 3.0
	for unit in units:
		if float(unit["hp"]) <= 0:
			continue
		var d = enemy["pos"].distance_to(unit["pos"])
		var preferred = d - (0.45 if unit["class"] == "Tanker" else 0.0)
		if d <= 2.8 and preferred < distance:
			distance = preferred; best = unit
	if best.is_empty():
		for tower in towers:
			if float(tower.get("hp", 0)) > 0:
				var d = enemy["pos"].distance_to(tower["pos"])
				if d < distance and d <= 2.8:
					distance = d; best = tower
	return best

func _nearest_hostile(position: Vector2, radius: float, allow_flying: bool = true) -> Dictionary:
	var best: Dictionary = {}
	var distance = radius
	for enemy in enemies:
		if not enemy.get("hostile", true) or float(enemy.get("hp", 0.0)) <= 0.0 or enemy.get("escaped", false):
			continue
		if not allow_flying and enemy.get("id", "") == "MOB04" and not _is_landed(enemy):
			continue
		var d = position.distance_to(enemy["pos"])
		if d < distance:
			distance = d; best = enemy
	return best

func _basic_attack(source: Dictionary, target: Dictionary):
	source["attack_timer"] = maxf(0.15, float(source["interval"]))
	source["statuses"] = source.get("statuses", []).filter(func(st): return not (st.get("next_attack_only", false) and st.get("stat", "") == "range"))
	var tell = 1.0 if source.get("id", "") == "BOSS01" else 0.18
	_pose(source, "attack", tell + 0.24, target["pos"])
	var damage = float(source["damage"]) * _stat_multiplier(source, "damage") + _consume_flat_damage(source)
	var accuracy = clampf(_stat_multiplier(source, "accuracy"), 0.05, 1.0)
	if source.get("faction", "") == "ally" and source.get("ranged", false) and not str(source.get("tower_uid", "")).is_empty():
		accuracy *= 0.85
	if _rng.randf() > accuracy:
		_fx("miss", target["pos"], 0.35, "#a8b5bd", 0.3)
		_event("miss", {"source": source["uid"], "target": target["uid"]})
		return
	if source.get("id", "") == "BOSS01":
		source["windup"] = tell
		_fx("warning", target["pos"], tell, "#df7c72", 2.0, source["pos"])
	_scheduled.append({"delay": tell, "kind": "basic_shot" if source.get("ranged", false) else "basic_hit", "source_uid": source["uid"], "target_uid": target["uid"], "damage": damage, "generation": int(source.get("cast_revision", 0))})

func _release_basic(source: Dictionary, target: Dictionary, action: Dictionary):
	if target.get("faction", "") != "ally" and not target.get("hostile", true):
		return
	var color = "#f4c86b" if source.get("faction", "") == "ally" else "#ba4f61"
	if action.get("kind", "") == "basic_shot":
		projectiles.append({"pos": source["pos"], "from": source["pos"], "to": target["pos"], "target_uid": target["uid"], "source_uid": source["uid"], "damage": float(action["damage"]), "speed": 13.0, "ttl": 2.0, "kind": "bolt" if source.get("id", "") == "TOWER04" else "shot", "color": color})
	else:
		var reach = 2.0 if source.get("id", "") == "BOSS01" else _effective_range(source) + 0.65
		if source["pos"].distance_to(target["pos"]) <= reach:
			_damage(target, float(action["damage"]), source, false)
			_fx("slash", target["pos"], 0.24, color, 0.7, source["pos"])

func _tick_projectiles(dt: float):
	var active: Array = []
	for projectile in projectiles:
		projectile["ttl"] = float(projectile.get("ttl", 0)) - dt
		var target = _entity(str(projectile.get("target_uid", "")))
		if target.is_empty() or float(target.get("hp", 0)) <= 0 or projectile["ttl"] <= 0.0:
			continue
		if target.get("faction", "") != "ally" and not target.get("hostile", true):
			continue
		projectile["to"] = target["pos"]
		if _projectile_blocked(projectile):
			continue
		var distance = projectile["pos"].distance_to(target["pos"])
		var movement = float(projectile.get("speed", 13.0)) * dt
		if distance <= movement + 0.12:
			_damage(target, float(projectile["damage"]), _entity(str(projectile.get("source_uid", ""))), true)
			_fx("impact", target["pos"], 0.25, str(projectile["color"]), 0.4)
		else:
			projectile["pos"] = projectile["pos"].move_toward(target["pos"], movement)
			active.append(projectile)
	projectiles = active

func _damage(target: Dictionary, amount: float, source: Dictionary, projectile: bool, bypass_intercept: bool = false, is_ability: bool = false):
	if target.is_empty() or amount <= 0.0 or float(target.get("hp", 0)) <= 0:
		return
	if target.get("faction", "") != "ally" and not target.get("hostile", true):
		return
	if not is_ability and _evades(target, projectile):
		_fx("miss", target["pos"], 0.35, "#a8b5bd", 0.5)
		return
	var value = amount * _incoming_multiplier(target, source, is_ability)
	if target.get("class", "") == "Tanker":
		value *= 0.88
	if projectile and not str(target.get("tower_uid", "")).is_empty():
		value *= 0.75
	if not bypass_intercept:
		for status in target.get("statuses", []):
			if status.get("kind", "") == "intercept" and float(status.get("remaining", 0)) > 0:
				var guardian = _entity(str(status.get("source_uid", "")))
				if guardian.is_empty() or float(guardian.get("hp", 0)) <= 0:
					continue
				var redirected = minf(value * float(status.get("amount", 0.3)), float(status.get("damage_left", 40.0)))
				status["damage_left"] = float(status.get("damage_left", 40.0)) - redirected
				value -= redirected
				_damage(guardian, redirected, source, projectile, true, is_ability)
	var shields = _absorb_shield(target, value)
	value -= shields
	if value > 0.0:
		target["hp"] = maxf(0.0, float(target["hp"]) - value)
	if source.get("faction", "") == "ally":
		damage_dealt += value
		source["damage_dealt"] = float(source.get("damage_dealt", 0.0)) + value
	_event("damage", {"source": source.get("uid", ""), "target": target.get("uid", ""), "amount": snappedf(value, 0.1), "pos": _array(target["pos"])})
	if float(target["hp"]) <= 0.0:
		target["state"] = "downed"; target["state_timer"] = 1000.0
		if target.get("id", "") == "DECOY":
			pass
		elif str(target.get("id", "")).begins_with("TOWER"):
			_event("tower_destroyed", {"id": target["id"], "uid": target["uid"]})
			for occupant in units:
				if occupant.get("tower_uid", "") == target["uid"]:
					occupant["tower_uid"] = ""
		elif target.get("faction", "") == "ally":
			_event("ally_downed", {"id": target["id"], "name": target.get("name", "")})
		else:
			target["corpse_time"] = 1.0
			if target.get("anchor", false):
				_break_anchor(target, true)
			if not target.get("anchor", false):
				kills += 1; _wave_kills += 1; coins += 4 if target["id"] != "BOSS01" else 100
			if not source.is_empty():
				source["kills"] = int(source.get("kills", 0)) + 1
			_event("enemy_defeated", {"id": target["id"], "uid": target["uid"]})

func _heal(target: Dictionary, amount: float, source: Dictionary):
	if float(target.get("hp", 0)) <= 0 or amount <= 0:
		return
	var before = float(target["hp"])
	target["hp"] = minf(float(target["max_hp"]), before + amount)
	var actual = float(target["hp"]) - before
	if actual > 0.01:
		_fx("heal", target["pos"], 0.5, "#9be1dc", 0.65)
		_event("heal", {"source": source.get("uid", ""), "target": target["uid"], "amount": snappedf(actual, 0.1)})

func _surrender(enemy: Dictionary):
	enemy["hostile"] = false; enemy["faction"] = "neutral"; enemy["state"] = "surrender"
	enemy["statuses"] = []; enemy["shield"] = 0.0
	surrendered += 1; _wave_surrendered += 1; coins += 3
	_fx("surrender", enemy["pos"], 1.3, "#fff1cf", 0.8)
	_event("surrender", {"uid": enemy["uid"], "name": enemy.get("name", "Monster")})

func _tick_statuses(entity: Dictionary, dt: float):
	var active: Array = []
	for status in entity.get("statuses", []):
		status["remaining"] = float(status.get("remaining", 0.0)) - dt
		if status["remaining"] > 0.0:
			active.append(status)
		elif status.get("kind", "") == "shield":
			var remaining_shield = float(status.get("remaining_shield", status.get("amount", 0.0)))
			entity["shield"] = maxf(0.0, float(entity.get("shield", 0)) - remaining_shield)
			var healing = float(status.get("heal_on_expire", 0.0))
			if remaining_shield > 0.0:
				healing += float(status.get("heal_if_intact", 0.0))
			if healing > 0:
				_heal(entity, healing, _entity(str(status.get("source_uid", ""))))
	entity["statuses"] = active

func _stat_multiplier(entity: Dictionary, stat: String) -> float:
	var value: float = 1.0
	for status in entity.get("statuses", []):
		var kind = str(status.get("kind", ""))
		if kind == "slow" and stat == "move_speed":
			if entity.get("statuses", []).any(func(st): return st.get("slow_immune", false)):
				continue
			var resistance = _shield_resistance(entity, "slow_resist")
			value *= clampf(1.0 - float(status.get("amount", 0.25)) * (1.0 - resistance), 0.15, 1.0)
		elif kind == "buff" and str(status.get("stat", "")) == stat:
			value *= float(status.get("multiplier", 1.0))
		elif kind == "buff" and str(status.get("stat", "")) == "armor" and stat == "damage_taken":
			value /= maxf(0.1, float(status.get("multiplier", 1.0)))
		elif kind == "buff" and str(status.get("stat", "")) == "damage_reduction" and stat == "damage_taken":
			value *= clampf(float(status.get("multiplier", 0.75)), 0.1, 1.0)
	return clampf(value, 0.1, 4.0)

func _has_status(entity: Dictionary, kind: String) -> bool:
	return entity.get("statuses", []).any(func(s): return s.get("kind", "") == kind and float(s.get("remaining", 0)) > 0)

func _status_source(entity: Dictionary, kind: String) -> Dictionary:
	for status in entity.get("statuses", []):
		if status.get("kind", "") == kind:
			return _entity(str(status.get("source_uid", "")))
	return {}

func _consume_flat_damage(entity: Dictionary) -> float:
	var amount: float = 0.0
	var keep: Array = []
	for status in entity.get("statuses", []):
		if status.get("kind", "") == "buff" and status.get("stat", "") == "flat_damage":
			amount += float(status.get("amount", 0))
			if not status.get("next_attack_only", false):
				keep.append(status)
		else:
			keep.append(status)
	entity["statuses"] = keep
	return amount

func _add_status(target: Dictionary, status: Dictionary):
	if status.get("kind", "") == "shield":
		status["remaining_shield"] = float(status.get("amount", 0))
	if not target.has("statuses"):
		target["statuses"] = []
	var list: Array = target["statuses"]
	# Identical named effects refresh instead of multiplying indefinitely.
	for old in list:
		if old.get("key", "") == status.get("key", "!") and old.get("source_uid", "") == status.get("source_uid", "?"):
			if old.get("kind", "") == "shield":
				target["shield"] = maxf(0, float(target.get("shield", 0)) - float(old.get("remaining_shield", old.get("amount", 0))))
			old.merge(status, true)
			if status.get("kind", "") == "shield":
				target["shield"] = float(target.get("shield", 0)) + float(status.get("amount", 0))
			return
	list.append(status)
	if status.get("kind", "") == "shield":
		target["shield"] = float(target.get("shield", 0)) + float(status.get("amount", 0))

func _entity(uid: String) -> Dictionary:
	for entity in units + enemies + towers + _zones:
		if entity.get("uid", "") == uid:
			return entity
	return {}

func _pose(entity: Dictionary, state: String, duration: float, toward: Vector2):
	entity["state"] = state; entity["state_timer"] = duration; entity["animation_time"] = 0.0
	var direction: Vector2 = toward - entity["pos"]
	if direction.length_squared() > 0.001:
		entity["facing"] = direction.normalized()

func _fx(kind: String, position: Vector2, duration: float, color: String, radius: float = 1.0, destination = null):
	var item = {"kind": kind, "pos": position, "ttl": duration, "max_ttl": duration, "color": color, "radius": radius}
	if destination != null:
		item["to"] = _vec(destination)
	effects.append(item)
	if effects.size() > 200:
		effects.pop_front()

func _event(kind: String, data: Dictionary = {}):
	var event = data.duplicate(true)
	event["kind"] = kind; event["time"] = elapsed
	events.append(event)
	if events.size() > 150:
		events.pop_front()

func _enemy_ability(enemy: Dictionary, slot: int) -> Dictionary:
	var model: Dictionary = _enemy_models.get(str(enemy["id"]), {})
	var list: Array = model.get("runtime_abilities", [])
	return list[slot] if slot >= 0 and slot < list.size() else {}

func _can_enemy_cast(enemy: Dictionary, ability: Dictionary) -> bool:
	for effect in ability.get("effects", []):
		if effect.get("target", "enemy") == "self" or effect.get("kind", "") in ["summon", "anchors"]:
			return true
	return not _targets(enemy, {"target": "enemy", "radius": 5.0, "max_targets": 1}).is_empty()

func _cast_ability(source: Dictionary, ability: Dictionary, slot: int, enemy_cast: bool = false) -> bool:
	if float(source.get("hp", 0)) <= 0:
		return false
	var cast_data = ability.duplicate(true)
	var duration = maxf(0.05, float(ability.get("windup", 0.25)))
	for effect in cast_data.get("effects", []):
		duration = maxf(duration, float(effect.get("windup", 0)))
		if effect.get("cancel_out_of_range", false):
			effect["locked_uids"] = _targets(source, effect).map(func(t): return t["uid"])
	var toward = source["pos"] + source.get("facing", Vector2.RIGHT)
	var first_enemy = _nearest_hostile(source["pos"], 6.0) if not enemy_cast else _enemy_target(source)
	if not first_enemy.is_empty():
		toward = first_enemy["pos"]
	_pose(source, "ability_a" if slot == 0 else "ability_b", duration + 0.4, toward)
	source["windup"] = duration
	var color = str(ability.get("color", "#df7c72" if enemy_cast else "#f4c86b"))
	var radius: float = 1.5
	for effect in ability.get("effects", []):
		radius = maxf(radius, float(effect.get("radius", 1.5)))
	_fx("warning" if enemy_cast else "cast", source["pos"], duration, color, radius)
	_scheduled.append({"delay": duration, "kind": "ability", "source_uid": source["uid"], "ability": cast_data, "enemy_cast": enemy_cast, "generation": int(source.get("cast_revision", 0))})
	_event("ability_cast", {"id": source.get("id", ""), "uid": source["uid"], "slot": slot, "name": ability.get("name", "Ability")})
	return true

func _tick_scheduled(dt: float):
	var current: Array = _scheduled
	_scheduled = []
	for action in current:
		action["delay"] = float(action.get("delay", 0.0)) - dt
		if action["delay"] > 0.0:
			_scheduled.append(action)
			continue
		var source = _entity(str(action.get("source_uid", "")))
		if source.is_empty() or float(source.get("hp", 0)) <= 0.0:
			continue
		if action.get("kind", "") in ["ability", "basic_hit", "basic_shot"] and int(action.get("generation", 0)) != int(source.get("cast_revision", 0)):
			continue
		if action.get("kind", "") in ["basic_hit", "basic_shot"]:
			var target = _entity(str(action.get("target_uid", "")))
			if not target.is_empty() and float(target.get("hp", 0)) > 0:
				_release_basic(source, target, action)
		elif action.get("kind", "") == "ability":
			var context = {"previous_targets": [], "damaged_targets": [], "last_damage_success": false}
			for effect in action["ability"].get("effects", []):
				_apply_effect(source, effect, str(action["ability"].get("id", action["ability"].get("name", "ability"))), context)
		elif action.get("kind", "") == "target_effect":
			var target = _entity(str(action.get("target_uid", "")))
			if not target.is_empty() and float(target.get("hp", 0)) > 0:
				if (action["effect"].get("channel", false) or action["effect"].get("cancel_out_of_range", false)) and source["pos"].distance_to(target["pos"]) > float(action["effect"].get("range", 3.0)):
					continue
				_apply_single_effect(source, target, action["effect"], str(action.get("key", "tick")), int(action.get("target_index", 0)))

func _targets(source: Dictionary, effect: Dictionary, center_override = null) -> Array:
	var selector = str(effect.get("target", "enemy"))
	if selector == "self":
		return [source]
	var source_is_ally = source.get("faction", "") == "ally"
	var friendly = selector == "ally"
	var pool: Array = units if (source_is_ally == friendly) else enemies
	var center: Vector2 = source["pos"] if center_override == null else _vec(center_override)
	var radius = float(effect.get("radius", effect.get("range", 3.0)))
	var candidates: Array = []
	for entity in pool:
		if float(entity.get("hp", 0)) <= 0.0 or entity.get("escaped", false):
			continue
		if entity.get("faction", "") != "ally" and not entity.get("hostile", true):
			continue
		if bool(effect.get("boss_immune", false)) and entity.get("id", "") == "BOSS01":
			continue
		if entity["uid"] in effect.get("exclude_uids", []):
			continue
		if effect.has("locked_uids") and entity["uid"] not in effect["locked_uids"]:
			continue
		if source["uid"] == entity["uid"] and effect.get("kind", "") == "intercept":
			continue
		if center.distance_to(entity["pos"]) > radius:
			continue
		if effect.get("revealed_only", false) and not _has_status(entity, "reveal"):
			continue
		candidates.append(entity)
	if str(effect.get("kind", "")) in ["heal", "shield", "intercept", "cleanse"]:
		candidates.sort_custom(func(a, b): return float(a["hp"]) / float(a["max_hp"]) < float(b["hp"]) / float(b["max_hp"]))
	else:
		candidates.sort_custom(func(a, b): return center.distance_squared_to(a["pos"]) < center.distance_squared_to(b["pos"]))
	if effect.get("shape", "") == "line" and not candidates.is_empty():
		var direction: Vector2 = (candidates[0]["pos"] - source["pos"]).normalized()
		candidates = candidates.filter(func(e):
			var offset: Vector2 = e["pos"] - source["pos"]
			return offset.dot(direction) >= -0.1 and absf(offset.cross(direction)) <= 1.0)
	if effect.get("include_self", false) and selector == "ally":
		candidates.erase(source)
		candidates.push_front(source)
	var cap = clampi(int(effect.get("max_targets", 1)), 1, 20)
	if candidates.size() > cap:
		candidates.resize(cap)
	return candidates

func _apply_effect(source: Dictionary, effect: Dictionary, key: String, context: Dictionary = {}):
	if effect.get("condition", "") == "both_targets_survive":
		var previous: Array = context.get("damaged_targets", [])
		if previous.size() < 2 or not previous.all(func(uid): return not _entity(str(uid)).is_empty() and float(_entity(str(uid)).get("hp", 0)) > 0):
			return
	var kind = str(effect.get("kind", "damage"))
	if kind in ["trap", "zone", "decoy"]:
		var center: Vector2 = source["pos"]
		if str(effect.get("target", "enemy")) == "enemy":
			var candidate = _nearest_hostile(center, float(effect.get("range", 4.0))) if source.get("faction", "") == "ally" else _enemy_target(source)
			if not candidate.is_empty():
				center = candidate["pos"]
		_make_zone(source, effect, center, key)
		return
	if kind == "dash":
		var target = _nearest_hostile(source["pos"], 8.0) if source.get("faction", "") == "ally" else _enemy_target(source)
		var direction: Vector2 = source.get("facing", Vector2.RIGHT)
		if not target.is_empty():
			direction = (target["pos"] - source["pos"]).normalized()
		if not bool(effect.get("toward", false)):
			direction = -direction
		var destination: Vector2 = source["pos"] + direction * float(effect.get("distance", 1.5))
		for i in range(1, 11):
			var proposed: Vector2 = source["pos"].lerp(destination, float(i) / 10.0)
			if not _in_bounds(proposed) or _tower_collision(proposed, str(source.get("tower_uid", ""))):
				break
			source["pos"] = proposed
		_fx("dash", source["pos"], 0.45, "#a8d0c5", 0.8)
		return
	if kind == "summon":
		var active = enemies.filter(func(e): return e.get("summoned", false) and e.get("summoner", "") == source["uid"] and float(e.get("hp", 0)) > 0).size()
		var count = mini(int(effect.get("count", 1)), maxi(0, int(effect.get("max_summons", 2)) - active))
		for i in range(count):
			var summoned = _spawn_enemy(str(effect.get("enemy_id", "MOB01")), int(source.get("path_index", 0)), false, source["pos"] + Vector2(-0.5 - i * 0.3, 0.5))
			summoned["summoned"] = true; summoned["summoner"] = source["uid"]
			summoned["waypoint"] = source.get("waypoint", 1)
		return
	if kind == "disable_trap":
		var remaining = int(effect.get("max_targets", 3))
		for trap in traps:
			if remaining <= 0:
				break
			if trap["pos"].distance_to(source["pos"]) <= float(effect.get("radius", 3.0)) and trap.get("state", "") == "armed":
				trap["disabled"] = float(effect.get("duration", 4.0)); remaining -= 1
		return
	if kind == "anchors":
		_spawn_anchors(source, effect, key)
		return
	var selector = effect.duplicate(true)
	var secondary_center = null
	if effect.get("exclude_previous", false):
		selector["exclude_uids"] = context.get("previous_targets", [])
		if not selector["exclude_uids"].is_empty():
			var previous_target = _entity(str(selector["exclude_uids"][0]))
			if not previous_target.is_empty(): secondary_center = previous_target["pos"]
	var targets = _targets(source, selector, secondary_center)
	context["previous_targets"] = targets.map(func(t): return t["uid"])
	if kind == "damage":
		context["damaged_targets"] = context["previous_targets"].duplicate()
		context["last_damage_success"] = not targets.is_empty()
	for i in range(targets.size()):
		var target: Dictionary = targets[i]
		var ticks = maxi(1, int(effect.get("ticks", effect.get("hits", 1))))
		var interval = maxf(0.05, float(effect.get("interval", 1.0)))
		var initial_delay = float(effect.get("delay", 0.0))
		for tick in range(ticks):
			var delay = initial_delay + tick * interval
			if ticks > 1 and kind == "heal" and not effect.has("hits"):
				delay += interval
			if delay <= 0.001:
				_apply_single_effect(source, target, effect, key, i)
			else:
				_scheduled.append({"delay": delay, "kind": "target_effect", "source_uid": source["uid"], "target_uid": target["uid"], "effect": effect.duplicate(true), "key": key, "target_index": i})

func _apply_single_effect(source: Dictionary, target: Dictionary, effect: Dictionary, key: String, target_index: int = 0):
	var kind = str(effect.get("kind", "damage"))
	var amount = float(effect.get("amount", 0.0))
	var duration = maxf(0.05, float(effect.get("duration", 4.0)))
	var color = "#df7c72" if source.get("faction", "") != "ally" else "#f4c86b"
	if effect.has("amounts") and effect["amounts"] is Array and not effect["amounts"].is_empty():
		amount = float(effect["amounts"][mini(target_index, effect["amounts"].size() - 1)])
	match kind:
		"damage":
			_damage(target, amount, source, false, false, true)
			_fx("ability_hit", target["pos"], 0.45, color, 0.9, source["pos"])
			if effect.get("interrupt", false) and not (target.get("id", "") == "BOSS01" and effect.get("boss_immune_interrupt", false)):
				_interrupt(target)
			if float(effect.get("knockback", 0.0)) > 0 and not _shield_flag(target, "knockback_resist") and not (effect.get("large_immune_knockback", false) and target.get("id", "") in ["MOB03", "MOB06", "BOSS01"]):
				if target.get("id", "") == "BOSS01":
					if float(effect.get("boss_slow", 0)) > 0:
						_add_status(target, {"kind": "slow", "amount": float(effect["boss_slow"]), "remaining": float(effect.get("boss_slow_duration", 2)), "source_uid": source["uid"], "key": key + ":boss_slow"})
				else:
					var away: Vector2 = (target["pos"] - source["pos"]).normalized()
					target["pos"] += away * float(effect["knockback"])
		"heal", "regen":
			_heal(target, amount, source)
		"shield":
			_add_status(target, {"kind": "shield", "amount": amount, "remaining": duration, "source_uid": source["uid"], "key": key + ":shield", "heal_on_expire": float(effect.get("heal_on_expire", 0)), "heal_if_intact": float(effect.get("heal_if_intact", 0)), "knockback_resist": bool(effect.get("knockback_resist", false)), "slow_resist": float(effect.get("slow_resist", 0)), "blocks_mobs": bool(effect.get("blocks_mobs", false))})
			_fx("shield", target["pos"], minf(1.5, duration), "#9bd1ed", 0.9)
		"buff":
			_add_status(target, {"kind": "buff", "stat": str(effect.get("stat", "attack_speed")), "amount": amount, "multiplier": float(effect.get("multiplier", 1.0)), "next_attack_only": bool(effect.get("next_attack_only", false)), "one_projectile": bool(effect.get("one_projectile", false)), "front_only": bool(effect.get("front_only", false)), "back_multiplier": float(effect.get("back_multiplier", 1.0)), "break_on_redeploy": bool(effect.get("break_on_redeploy", false)), "basic_only": bool(effect.get("basic_only", false)), "slow_immune": bool(effect.get("slow_immune", false)), "remaining": duration, "source_uid": source["uid"], "key": key + ":" + str(effect.get("stat", "buff"))})
			_fx("buff", target["pos"], 0.9, "#f4c86b", 0.7)
		"taunt", "root", "slow", "stun", "reveal":
			if target.get("id", "") == "BOSS01" and kind in ["taunt", "root", "stun"]:
				return
			_add_status(target, {"kind": kind, "amount": amount, "landed": bool(effect.get("landed", false)), "remaining": duration, "source_uid": source["uid"], "key": key + ":" + kind})
			_fx(kind, target["pos"], 0.7, color, 0.65)
		"cleanse":
			target["statuses"] = target.get("statuses", []).filter(func(s): return s.get("kind", "") not in ["slow", "root", "stun", "dot"] and not (s.get("kind", "") == "buff" and float(s.get("multiplier", 1)) < 1))
			_scheduled = _scheduled.filter(func(s): return not (s.get("target_uid", "") == target["uid"] and s.get("effect", {}).get("dot", false)))
			_fx("heal", target["pos"], 0.6, "#9be1dc", 0.8)
		"intercept":
			_add_status(target, {"kind": "intercept", "amount": amount, "damage_left": float(effect.get("damage_cap", 40)), "remaining": duration, "source_uid": source["uid"], "key": key + ":intercept"})
			_fx("shield", target["pos"], 0.8, "#9bd1ed", 0.9, source["pos"])
	if target.get("id", "") == "BOSS01" and float(effect.get("boss_slow", 0)) > 0 and float(effect.get("root", 0)) > 0:
		_add_status(target, {"kind": "slow", "amount": float(effect["boss_slow"]), "remaining": float(effect.get("boss_slow_duration", 2)), "source_uid": source["uid"], "key": key + ":root_boss_slow"})
	if kind not in ["root", "slow"]:
		if float(effect.get("root", 0)) > 0 and target.get("id", "") != "BOSS01":
			_add_status(target, {"kind": "root", "remaining": float(effect["root"]), "source_uid": source["uid"], "key": key + ":root"})
		if float(effect.get("slow", 0)) > 0:
			_add_status(target, {"kind": "slow", "amount": float(effect["slow"]), "remaining": float(effect.get("slow_duration", 3)), "source_uid": source["uid"], "key": key + ":slow"})

func _make_zone(source: Dictionary, effect: Dictionary, center: Vector2, key: String = "strategy"):
	var same = _zones.filter(func(z): return z.get("source_uid", "") == source["uid"] and z.get("key", "") == key)
	var max_instances = maxi(1, int(effect.get("max_active_instances", 1)))
	while same.size() >= max_instances:
		var oldest: Dictionary = same.pop_front()
		_zones.erase(oldest)
	var zone = {"uid": "z-" + str(_next_uid), "source_uid": source["uid"], "key": key, "pos": center, "effect": effect.duplicate(true), "ttl": float(effect.get("duration", 5.0)), "timer": maxf(0.1, float(effect.get("interval", 1.0))), "arm_timer": float(effect.get("arm_delay", 0.0)), "applied": [], "ticks_done": {}, "hp": float(effect.get("hp", 30.0))}
	_next_uid += 1
	if effect.get("kind", "") == "decoy":
		zone["faction"] = source.get("faction", "ally"); zone["max_hp"] = zone["hp"]; zone["id"] = "DECOY"
		zone["state"] = "idle"; zone["statuses"] = []; zone["shield"] = 0.0
	_zones.append(zone)
	_fx("zone", center, minf(float(zone["ttl"]), 3.0), "#d99855" if source.get("faction", "") == "ally" else "#ba4f61", float(effect.get("radius", 1.0)))

func _tick_zones(dt: float):
	var active: Array = []
	for zone in _zones:
		zone["ttl"] = float(zone["ttl"]) - dt
		var effect: Dictionary = zone["effect"]
		var source = _entity(str(zone["source_uid"]))
		if source.is_empty() or float(source.get("hp", 0)) <= 0 or float(zone["ttl"]) < -dt or float(zone.get("hp", 1)) <= 0:
			if float(effect.get("explosion_damage", 0)) > 0 and float(zone.get("hp", 1)) <= 0 and not source.is_empty():
				var blast = {"kind": "damage", "target": "enemy", "amount": effect["explosion_damage"], "radius": effect.get("explosion_radius", 1.6), "max_targets": effect.get("explosion_targets", 3)}
				for target in _targets(source, blast, zone["pos"]):
					_apply_single_effect(source, target, blast, str(zone["key"]) + ":burst")
			continue
		zone["arm_timer"] = maxf(0.0, float(zone.get("arm_timer", 0)) - dt)
		if zone["arm_timer"] > 0:
			active.append(zone)
			continue
		var candidates = _targets(source, effect, zone["pos"])
		if effect.get("affects_both_sides", false):
			var other_selector = effect.duplicate(true)
			other_selector["target"] = "ally"
			candidates.append_array(_targets(source, other_selector, zone["pos"]))
		var cap = int(effect.get("max_targets", 1))
		for target in candidates:
			if target["uid"] not in zone["applied"] and zone["applied"].size() < cap:
				zone["applied"].append(target["uid"])
		zone["timer"] = float(zone["timer"]) - dt
		if effect.get("kind", "") == "trap" and not candidates.is_empty() and int(effect.get("ticks", 1)) == 1:
			zone["timer"] = 0.0
		if zone["timer"] <= 0.0:
			zone["timer"] += maxf(0.1, float(effect.get("interval", 1.0)))
			for uid in zone["applied"]:
				var target = _entity(str(uid))
				if target.is_empty() or float(target.get("hp", 0)) <= 0:
					continue
				if target["pos"].distance_to(zone["pos"]) > float(effect.get("radius", 1.0)):
					continue
				var used = int(zone["ticks_done"].get(uid, 0))
				var max_ticks = int(effect.get("ticks", maxi(1, int(ceil(float(effect.get("duration", 5)) / maxf(0.1, float(effect.get("interval", 1))))))))
				if used >= max_ticks:
					continue
				zone["ticks_done"][uid] = used + 1
				if float(effect.get("damage", 0)) > 0:
					_apply_single_effect(source, target, {"kind": "damage", "amount": effect["damage"], "slow": effect.get("slow", 0), "root": effect.get("root", 0), "slow_duration": effect.get("slow_duration", 3), "boss_slow": effect.get("boss_slow", 0), "boss_slow_duration": effect.get("boss_slow_duration", 2)}, str(zone["key"]))
				if effect.get("reveal", false):
					_add_status(target, {"kind": "reveal", "remaining": float(effect.get("duration", 4)), "source_uid": source["uid"], "key": str(zone["key"]) + ":reveal"})
				if effect.get("cleanse", false):
					target["statuses"] = target.get("statuses", []).filter(func(st): return st.get("kind", "") not in ["slow", "root", "stun"])
				if float(effect.get("heal", 0)) > 0:
					_heal(target, float(effect["heal"]), source)
				if float(effect.get("slow", 0)) > 0:
					_add_status(target, {"kind": "slow", "amount": float(effect["slow"]), "remaining": float(effect.get("slow_duration", 2)), "source_uid": source["uid"], "key": str(zone["key"]) + ":slow"})
				if float(effect.get("root", 0)) > 0 and target.get("id", "") != "BOSS01":
					_add_status(target, {"kind": "root", "remaining": float(effect["root"]), "source_uid": source["uid"], "key": str(zone["key"]) + ":root"})
				if float(effect.get("accuracy", 0)) > 0:
					_add_status(target, {"kind": "buff", "stat": "accuracy", "multiplier": float(effect["accuracy"]), "remaining": float(effect.get("buff_duration", 2)), "source_uid": source["uid"], "key": str(zone["key"]) + ":accuracy"})
				if float(effect.get("move_speed", 0)) > 0:
					_add_status(target, {"kind": "buff", "stat": "move_speed", "multiplier": float(effect["move_speed"]), "remaining": float(effect.get("buff_duration", 4)), "source_uid": source["uid"], "key": str(zone["key"]) + ":speed"})
				if effect.get("kind", "") == "decoy" and target.get("id", "") != "BOSS01":
					_add_status(target, {"kind": "taunt", "remaining": 1.5, "source_uid": zone["uid"], "key": str(zone["key"]) + ":taunt"})
				_fx("trap" if effect.get("kind", "") == "trap" else "zone_tick", target["pos"], 0.5, "#d99855", 0.7)
			if effect.get("trigger_once", false) and not candidates.is_empty():
				zone["ttl"] = 0.0
		active.append(zone)
	_zones = active

func _spawn_anchors(source: Dictionary, effect: Dictionary, key: String):
	for enemy in enemies:
		if enemy.get("anchor", false) and enemy.get("owner_uid", "") == source["uid"]:
			enemy["hp"] = 0.0
	var count = clampi(int(effect.get("count", 2)), 1, 2)
	for i in range(count):
		var position: Vector2 = source["pos"] + Vector2(-1.0, -2.0 if i == 0 else 2.0)
		var anchor = {"id": "ANCHOR", "uid": "anchor-" + str(_next_uid), "owner_uid": source["uid"], "name": "Oath Anchor", "pos": position, "hp": float(effect.get("hp", 60)), "max_hp": float(effect.get("hp", 60)), "shield": 0.0, "faction": "enemy", "hostile": true, "anchor": true, "state": "idle", "state_timer": 0.0, "animation_time": 0.0, "facing": Vector2.RIGHT, "statuses": [], "corpse_time": 0.0, "expires": float(effect.get("duration", 6.0)), "exposed_duration": float(effect.get("exposed_duration", 3.0))}
		_next_uid += 1; enemies.append(anchor)
	_add_status(source, {"kind": "shield", "amount": float(effect.get("shield_amount", 120)), "remaining": float(effect.get("duration", 6)), "source_uid": source["uid"], "key": key + ":anchors"})
	_fx("shield", source["pos"], 1.0, "#4ca6a8", 2.0)

func _tick_towers(dt: float, between_waves: bool):
	var hearth_claimed: Array = []
	for tower in towers:
		if float(tower.get("hp", 0)) <= 0:
			continue
		tower["attack_timer"] = maxf(0.0, float(tower.get("attack_timer", 0)) - dt)
		var level = int(tower.get("level", 1))
		match str(tower["id"]):
			"TOWER04":
				if between_waves or tower["attack_timer"] > 0:
					continue
				var target: Dictionary = {}
				var nearest: float = 4.0 + 0.3 * (level - 1)
				for candidate in enemies:
					var d = tower["pos"].distance_to(candidate["pos"])
					if candidate.get("hostile", true) and float(candidate.get("hp", 0)) > 0 and d >= 1.5 and d <= nearest:
						nearest = d; target = candidate
				if not target.is_empty() and tower["pos"].distance_to(target["pos"]) >= 1.5:
					tower["damage"] = 18.0 + 3.0 * (level - 1)
					tower["interval"] = 2.0 - 0.12 * (level - 1)
					_basic_attack(tower, target)
			"TOWER03":
				if float(tower.get("fuel", 0)) <= 0:
					continue
				var nearby = units.filter(func(u): return float(u["hp"]) > 0 and float(u["hp"]) < float(u["max_hp"]) and u["pos"].distance_to(tower["pos"]) <= 3.0 and u["uid"] not in hearth_claimed)
				nearby.sort_custom(func(a, b): return float(a["hp"]) / float(a["max_hp"]) < float(b["hp"]) / float(b["max_hp"]))
				if not nearby.is_empty():
					hearth_claimed.append(nearby[0]["uid"])
					var amount = minf(float(tower["fuel"]), dt * (8.0 if between_waves else 4.0))
					var needed = float(nearby[0]["max_hp"]) - float(nearby[0]["hp"])
					amount = minf(amount, needed)
					nearby[0]["hp"] += amount; tower["fuel"] -= amount
					if tower["attack_timer"] <= 0:
						_fx("heal", nearby[0]["pos"], 0.5, "#9be1dc", 0.6)
						tower["attack_timer"] = 0.9
			"TOWER02":
				if between_waves or tower["attack_timer"] > 0:
					continue
				tower["attack_timer"] = 2.0
				var revealed: int = 0
				for enemy in enemies:
					if revealed >= 6:
						break
					if enemy.get("hostile", true) and enemy["pos"].distance_to(tower["pos"]) <= 3.0 + level:
						_add_status(enemy, {"kind": "reveal", "remaining": 3.0, "source_uid": tower["uid"], "key": "beacon"})
						revealed += 1

func _tick_traps(dt: float):
	for trap in traps:
		if trap.get("state", "") != "armed":
			continue
		trap["disabled"] = maxf(0.0, float(trap.get("disabled", 0)) - dt)
		if trap["disabled"] > 0:
			continue
		var candidates: Array = []
		for enemy in enemies:
			if enemy.get("hostile", true) and float(enemy.get("hp", 0)) > 0 and enemy["pos"].distance_to(trap["pos"]) <= 0.8:
				candidates.append(enemy)
		if trap["id"] == "TRAP02":
			var fuse = float(trap.get("fuse", -1.0))
			if fuse < 0.0:
				if candidates.is_empty():
					continue
				fuse = 0.8
				_fx("warning", trap["pos"], 0.8, "#f39c64", 1.0)
			trap["fuse"] = fuse - dt
			if trap["fuse"] > 0:
				continue
			candidates = enemies.filter(func(e): return e.get("hostile", true) and float(e.get("hp", 0)) > 0 and e["pos"].distance_to(trap["pos"]) <= 1.0)
		elif candidates.is_empty():
			continue
		trap["state"] = "spent"
		var owner = {"uid": trap["uid"], "id": trap["id"], "faction": "ally", "pos": trap["pos"]}
		var count = 1 if trap["id"] == "TRAP01" else (4 if trap["id"] == "TRAP02" else 3)
		for i in range(mini(count, candidates.size())):
			var target: Dictionary = candidates[i]
			if trap["id"] == "TRAP01":
				_damage(target, 4.0, owner, false, false, true)
				_add_status(target, {"kind": "slow", "amount": 0.25, "remaining": 2.0, "source_uid": trap["uid"], "key": "snare"})
			elif trap["id"] == "TRAP02":
				_damage(target, 12.0, owner, false, false, true)
			elif target["id"] != "BOSS01":
				_add_status(target, {"kind": "stun", "remaining": 1.5, "source_uid": trap["uid"], "key": "decoy_standard"})
		_fx("trap", trap["pos"], 0.8, "#d99855", 1.2)
		_event("trap_triggered", {"id": trap["id"], "uid": trap["uid"]})

func _update_roost(unit: Dictionary):
	if not unit.get("ranged", false):
		unit["tower_uid"] = ""
		return
	if not str(unit.get("tower_uid", "")).is_empty():
		var assigned = _entity(str(unit["tower_uid"]))
		if assigned.is_empty() or assigned.get("id", "") != "TOWER01" or float(assigned.get("hp", 0)) <= 0:
			unit["tower_uid"] = ""
		else:
			unit["pos"] = assigned["pos"]

var _preview_only: bool = false

func preview_command(cmd: Dictionary) -> Dictionary:
	_preview_only = true
	var result = command(cmd)
	_preview_only = false
	return result

func command(cmd: Dictionary) -> Dictionary:
	var kind = str(cmd.get("kind", ""))
	if kind in ["place_unit", "move_unit", "place_tower", "place_trap"] and not _valid_point(cmd.get("cell")):
		return _result(false, "A snapped grid cell is required.")
	if cmd.has("expected_revision") and int(cmd["expected_revision"]) != revision:
		return _result(false, "The map changed. Refresh before applying this edit.")
	if kind == "cast":
		return _command_cast(cmd)
	if kind == "set_mode":
		return _command_set_mode(cmd)
	if kind == "start_wave":
		if _preview_only:
			return _result(phase == "planning", "Ready." if phase == "planning" else "A wave is already running.")
		return start_wave()
	if phase != "planning":
		return _result(false, "Layout edits are available between waves.")
	match kind:
		"place_unit", "move_unit":
			var uid = str(cmd.get("uid", "u-" + str(cmd.get("id", ""))))
			var unit = _entity(uid)
			var is_new = unit.is_empty()
			if not is_new and unit not in units:
				return _result(false, "Only party allies can use unit movement commands.")
			if is_new:
				if kind != "place_unit" or str(cmd.get("id", "")) not in _party_ids:
					return _result(false, "That ally is not in your party.")
				if units.size() >= MAX_UNITS:
					return _result(false, "The field supports ten allies.")
				var data = _character(str(cmd.get("id", "")))
				if data.is_empty():
					return _result(false, "Unknown ally.")
				unit = _make_unit(data, Vector2.ZERO)
			if unit.get("faction", "") != "ally" or float(unit.get("hp", 0)) <= 0:
				return _result(false, "Only living party allies can be moved.")
			var cell = _vec(cmd.get("cell", []))
			var validation = _validate_cell(cell, "unit", uid)
			if not validation.is_empty():
				return _result(false, validation)
			var mode = str(cmd.get("mode", unit.get("mode", "Guard")))
			if mode not in MODES:
				return _result(false, "Choose Guard, Patrol, or Advance.")
			if _preview_only:
				return _result(true, "Place ally here.")
			_record_history()
			if is_new:
				units.append(unit)
			unit["pos"] = cell; unit["anchor"] = cell; unit["mode"] = mode; unit["tower_uid"] = ""
			unit["statuses"] = unit.get("statuses", []).filter(func(st): return not st.get("break_on_redeploy", false))
			unit["patrol_path"] = _closest_patrol(cell); unit["patrol_index"] = 0
			_layout_changed("Ally placed.")
		"set_mode":
			var unit = _entity(str(cmd.get("uid", "")))
			var mode = str(cmd.get("mode", ""))
			if unit.is_empty() or unit not in units or unit.get("faction", "") != "ally" or float(unit.get("hp", 0)) <= 0 or mode not in MODES:
				return _result(false, "Select an ally and a valid movement mode.")
			if _preview_only:
				return _result(true, "Movement mode available.")
			_record_history(); unit["mode"] = mode; unit["tower_uid"] = ""; _layout_changed("Movement mode changed.")
		"place_tower":
			var id = str(cmd.get("tower_id", ""))
			if id not in TOWER_COSTS:
				return _result(false, "Unknown tower.")
			var cost = _definition_cost(id, TOWER_COSTS[id])
			if coins < cost:
				return _result(false, "Not enough supplies: %d needed." % cost)
			var cell = _vec(cmd.get("cell", []))
			var validation = _validate_cell(cell, "tower", "")
			if not validation.is_empty():
				return _result(false, validation)
			if _preview_only:
				return _result(true, "Build tower for %d supplies." % cost)
			_record_history()
			var tower = {"id": id, "uid": "t-" + str(_next_uid), "pos": cell, "level": 1, "cost": cost, "hp": 100.0, "max_hp": 100.0, "fuel": 60.0, "faction": "ally", "range": 4.0, "ranged": true, "attack_timer": 0.0, "damage": 18.0, "interval": 2.0, "statuses": [], "state": "idle", "state_timer": 0.0, "animation_time": 0.0, "facing": Vector2.RIGHT}
			_next_uid += 1; towers.append(tower); coins -= cost; _layout_changed("Tower built.")
		"upgrade_tower":
			var tower = _entity(str(cmd.get("uid", "")))
			if tower.is_empty() or str(tower.get("id", "")) not in TOWER_COSTS:
				return _result(false, "Select a tower to upgrade.")
			if float(tower.get("hp", 0)) <= 0:
				return _result(false, "Salvage this wreckage before rebuilding.")
			var level = int(tower.get("level", 1))
			if level >= 3:
				return _result(false, "This tower is fully upgraded.")
			var cost = 65 if level == 1 else 95
			if coins < cost:
				return _result(false, "Not enough supplies: %d needed." % cost)
			if _preview_only:
				return _result(true, "Upgrade for %d supplies." % cost)
			_record_history(); tower["level"] = level + 1; tower["max_hp"] += 45.0; tower["hp"] = tower["max_hp"]; tower["cost"] += cost
			coins -= cost; _layout_changed("Tower upgraded.")
		"place_trap":
			var id = str(cmd.get("trap_id", ""))
			if id not in TRAP_COSTS:
				return _result(false, "Unknown trap.")
			var cost = _definition_cost(id, TRAP_COSTS[id])
			if coins < cost:
				return _result(false, "Not enough supplies: %d needed." % cost)
			var cell = _vec(cmd.get("cell", []))
			var validation = _validate_cell(cell, "trap", "")
			if not validation.is_empty():
				return _result(false, validation)
			if traps.size() >= 24:
				return _result(false, "At most twenty-four traps fit on this battlefield.")
			if _preview_only:
				return _result(true, "Set trap for %d supplies." % cost)
			_record_history()
			traps.append({"id": id, "uid": "p-" + str(_next_uid), "pos": cell, "state": "armed", "cost": cost, "disabled": 0.0})
			_next_uid += 1; coins -= cost; _layout_changed("Trap armed.")
		"remove_tower", "remove_trap":
			var collection: Array = towers if kind == "remove_tower" else traps
			var index: int = -1
			for i in range(collection.size()):
				if collection[i]["uid"] == str(cmd.get("uid", "")):
					index = i; break
			if index < 0:
				return _result(false, "Select a placed tower or trap.")
			if _preview_only:
				return _result(true, "Salvage returns half its supply cost.")
			_record_history()
			var removed: Dictionary = collection[index]
			coins += int(float(removed.get("cost", 0)) * 0.5)
			for unit in units:
				if unit.get("tower_uid", "") == removed["uid"]:
					unit["tower_uid"] = ""; unit["pos"] += Vector2(1, 0); unit["anchor"] = unit["pos"]
			collection.remove_at(index); _layout_changed("Defence salvaged.")
		"assign_tower":
			var unit = _entity(str(cmd.get("uid", "")))
			var tower = _entity(str(cmd.get("tower_uid", "")))
			if unit.is_empty() or unit not in units or float(unit.get("hp", 0)) <= 0 or tower.is_empty() or unit.get("faction", "") != "ally" or tower.get("id", "") != "TOWER01" or float(tower.get("hp", 0)) <= 0:
				return _result(false, "Select a ranged ally and a Palisade Roost.")
			if not unit.get("ranged", false):
				return _result(false, "Melee allies cannot fire from a roost.")
			if units.any(func(u): return u.get("tower_uid", "") == tower["uid"] and u["uid"] != unit["uid"]):
				return _result(false, "That roost already has an occupant.")
			if _preview_only:
				return _result(true, "Cover reduces projectile damage by 25%; accuracy becomes 85%.")
			_record_history(); unit["tower_uid"] = tower["uid"]; unit["pos"] = tower["pos"]; unit["anchor"] = tower["pos"]; unit["mode"] = "Guard"
			_layout_changed("Ally assigned to roost.")
		"set_track":
			var raw_points = cmd.get("points", [])
			if not raw_points is Array or not raw_points.all(func(p): return _valid_point(p)):
				return _result(false, "Every patrol point must be a snapped grid cell.")
			var points = _vectors(raw_points)
			var track_id = str(cmd.get("track_id", "patrol-custom"))
			var existing_tracks: Array = map.get("ally_patrol_tracks", [])
			if existing_tracks.size() >= 6 and not existing_tracks.any(func(t): return str(t.get("id", "")) == track_id):
				return _result(false, "At most six patrol routes are supported.")
			var validation = _validate_track(points)
			if not validation.is_empty():
				return _result(false, validation)
			if _preview_only:
				return _result(true, "Patrol route is connected and clear.")
			_record_history()
			var tracks: Array = map.get("ally_patrol_tracks", [])
			var found: bool = false
			for track in tracks:
				if str(track.get("id", "")) == track_id:
					track["points"] = _json_safe(points); found = true
			if not found:
				if tracks.size() >= 6:
					return _result(false, "At most six patrol routes are supported.")
				tracks.append({"id": track_id, "kind": "ally", "points": _json_safe(points)})
			map["ally_patrol_tracks"] = tracks; _prepare_paths()
			for unit in units:
				unit["patrol_path"] = _closest_patrol(unit["pos"]); unit["patrol_index"] = 0
			_layout_changed("Patrol route updated.")
		"undo":
			if _history.is_empty():
				return _result(false, "Nothing to undo.")
			if _preview_only:
				return _result(true, "Undo the last layout edit.")
			_future.append(_layout_snapshot()); _restore_layout(_history.pop_back()); revision += 1
			_event("layout_changed", {"message": "Edit undone.", "revision": revision})
		"redo":
			if _future.is_empty():
				return _result(false, "Nothing to redo.")
			if _preview_only:
				return _result(true, "Redo the last undone edit.")
			_history.append(_layout_snapshot()); _restore_layout(_future.pop_back()); revision += 1
			_event("layout_changed", {"message": "Edit restored.", "revision": revision})
		_:
			return _result(false, "Unknown command: " + kind)
	return _result(true, "Layout updated.")

func _command_cast(cmd: Dictionary) -> Dictionary:
	if phase != "combat":
		return _result(false, "Abilities are used during a wave.")
	var unit = _entity(str(cmd.get("uid", "")))
	var slot = int(cmd.get("slot", -1))
	if unit.is_empty() or unit not in units or unit.get("faction", "") != "ally" or float(unit.get("hp", 0)) <= 0:
		return _result(false, "Select a living ally.")
	if slot < 0 or slot > 1:
		return _result(false, "Choose one of the ally's two abilities.")
	if float(unit["cooldowns"][slot]) > 0:
		return _result(false, "Ability ready in %.1f seconds." % float(unit["cooldowns"][slot]))
	if _has_status(unit, "stun"):
		return _result(false, "That ally is recovering from a stun.")
	var ability = _ability(str(unit["id"]), slot)
	if ability.is_empty():
		return _result(false, "This ability is unavailable.")
	if _preview_only:
		return _result(true, str(ability.get("name", "Ability")) + " is ready.")
	unit["cooldowns"][slot] = float(ability.get("cooldown_seconds", 16))
	_cast_ability(unit, ability, slot)
	return _result(true, str(ability.get("name", "Ability")) + " activated.")

func _definition_cost(id: String, fallback: int) -> int:
	if catalog != null:
		var world = catalog.get("world")
		if world is Dictionary:
			for item in world.get("towers" if id.begins_with("TOWER") else "traps", []):
				if item.get("id", "") == id:
					return int(item.get("cost", fallback))
	return fallback

func _grid_size() -> Vector2i:
	var grid = map.get("grid_tiles", [32, 20])
	return Vector2i(int(grid[0]), int(grid[1]))

func _in_bounds(cell: Vector2) -> bool:
	var grid = _grid_size()
	return is_finite(cell.x) and is_finite(cell.y) and cell.x >= 0 and cell.y >= 0 and cell.x < grid.x and cell.y < grid.y

func _validate_cell(cell: Vector2, kind: String, ignored_uid: String) -> String:
	if not _in_bounds(cell):
		return "Place objects inside the battlefield."
	for blocked in map.get("blocked_cells", []):
		if cell.distance_to(_vec(blocked)) < 0.7:
			return "Terrain blocks this tile."
	if _tower_collision(cell, ""):
		return "A tower already occupies this tile."
	if kind == "tower":
		for path in _enemy_paths:
			for i in range(path.size() - 1):
				if _distance_to_segment(cell, path[i], path[i + 1]) < 0.95:
					return "Towers cannot block an enemy route."
		var pads = _vectors(map.get("tower_pad_centers", []))
		if not pads.is_empty() and not pads.any(func(p): return p.distance_to(cell) < 0.8):
			return "Build towers on a marked stone pad."
	for unit in units:
		if unit["uid"] != ignored_uid and float(unit["hp"]) > 0 and unit["pos"].distance_to(cell) < 0.75:
			return "An ally occupies this tile."
	for trap in traps:
		if trap.get("state", "") == "armed" and trap["pos"].distance_to(cell) < 0.65:
			return "A trap already occupies this tile."
	return ""

func _tower_collision(position: Vector2, ignored_uid: String) -> bool:
	for tower in towers:
		if tower.get("uid", "") != ignored_uid and float(tower.get("hp", 0)) > 0 and tower["pos"].distance_to(position) < 0.8:
			return true
	return false

func _validate_track(points: Array) -> String:
	if points.size() < 2 or points.size() > 64:
		return "A patrol route needs two to sixty-four connected points."
	for point in points:
		if not _in_bounds(point):
			return "Patrol points must stay inside the battlefield."
	for i in range(points.size() - 1):
		var a: Vector2 = points[i]
		var b: Vector2 = points[i + 1]
		if a.distance_to(b) < 0.25 or a.distance_to(b) > 12.0:
			return "Track pieces must connect without gaps or duplicate nodes."
		if absf(a.x - b.x) > 0.1 and absf(a.y - b.y) > 0.1:
			return "Use straight track pieces and right-angle turns."
		var steps = int(ceil(a.distance_to(b) * 3))
		for step_index in range(steps + 1):
			var point: Vector2 = a.lerp(b, float(step_index) / maxf(1, steps))
			if _tower_collision(point, ""):
				return "A tower blocks this patrol route."
			for path in _enemy_paths:
				for j in range(path.size() - 1):
					if _distance_to_segment(point, path[j], path[j + 1]) < 0.65:
						if map.get("id", "") == "MAP03" and point.distance_to(Vector2(6, 4)) < 0.8:
							continue
						return "Patrol tracks cannot cross enemy lanes without a bridge."
	return ""

func _distance_to_segment(point: Vector2, a: Vector2, b: Vector2) -> float:
	var length_squared = a.distance_squared_to(b)
	if length_squared <= 0.00001:
		return point.distance_to(a)
	var fraction = clampf((point - a).dot(b - a) / length_squared, 0.0, 1.0)
	return point.distance_to(a.lerp(b, fraction))

func _record_history():
	_history.append(_layout_snapshot())
	if _history.size() > 50:
		_history.pop_front()
	_future.clear()

func _layout_changed(message: String):
	revision += 1
	_event("layout_changed", {"message": message, "revision": revision})

func _layout_snapshot() -> Dictionary:
	return {"units": units.duplicate(true), "towers": towers.duplicate(true), "traps": traps.duplicate(true), "coins": coins, "map": map.duplicate(true), "next_uid": _next_uid}

func _restore_layout(data: Dictionary):
	units = _restore_vectors(data.get("units", []).duplicate(true))
	towers = _restore_vectors(data.get("towers", []).duplicate(true))
	traps = _restore_vectors(data.get("traps", []).duplicate(true))
	coins = int(data.get("coins", coins)); map = data.get("map", map).duplicate(true)
	_next_uid = int(data.get("next_uid", _next_uid))
	_prepare_paths()

func _result(ok: bool, message: String) -> Dictionary:
	return {"ok": ok, "message": message, "revision": revision, "phase": phase}

func survivors() -> Array:
	var ids: Array = []
	for unit in units:
		if float(unit.get("hp", 0)) > 0 and unit.get("id", "") in _party_ids:
			ids.append(str(unit["id"]))
	return ids

func snapshot() -> Dictionary:
	var data = {
		"version": 1, "map": map, "party_ids": _party_ids, "phase": phase, "wave": wave, "max_waves": max_waves,
		"coins": coins, "gate_hp": gate_hp, "gate_max_hp": gate_max_hp, "revision": revision, "speed": speed, "elapsed": elapsed,
		"kills": kills, "surrendered": surrendered, "rescued": rescued, "damage_dealt": damage_dealt,
		"units": units, "enemies": enemies, "towers": towers, "traps": traps, "effects": effects,
		"projectiles": projectiles, "zones": _zones, "scheduled": _scheduled, "spawn_queue": _spawn_queue,
		"wave_clock": _wave_clock, "next_uid": _next_uid, "difficulty": _difficulty, "enemy_hp_multiplier": _enemy_hp_multiplier, "map_index": _map_index,
		"rng_state": str(_rng.state), "rng_seed": str(_rng.seed), "accumulator": _accumulator,
		"wave_kills": _wave_kills, "wave_surrendered": _wave_surrendered,
		"history": _history, "future": _future,
		"can_undo": not _history.is_empty() and phase == "planning", "can_redo": not _future.is_empty() and phase == "planning",
	}
	return _json_safe(data)

func restore(data: Dictionary) -> Dictionary:
	var validation = _validate_restore(data)
	if not validation.is_empty():
		return _result(false, validation)
	if int(data.get("version", 0)) != 1 or not data.get("map", {}) is Dictionary:
		return _result(false, "This save uses an unsupported battle format.")
	var new_phase = str(data.get("phase", "planning"))
	if new_phase not in ["planning", "combat", "victory", "defeat"]:
		return _result(false, "Invalid saved battle phase.")
	map = data.get("map", {}).duplicate(true); _party_ids = data.get("party_ids", []).duplicate()
	_map_index = int(data.get("map_index", 1)); _difficulty = float(data.get("difficulty", 1.0))
	_enemy_hp_multiplier = clampf(float(data.get("enemy_hp_multiplier", 1.0)), 0.25, 3.0)
	_load_models(); _prepare_paths()
	phase = new_phase; wave = int(data.get("wave", 0)); max_waves = int(data.get("max_waves", 4))
	coins = int(data.get("coins", 300)); gate_max_hp = float(data.get("gate_max_hp", 100))
	gate_hp = clampf(float(data.get("gate_hp", gate_max_hp)), 0, gate_max_hp)
	revision = int(data.get("revision", 0)); speed = clampf(float(data.get("speed", 1)), 0, 4)
	elapsed = float(data.get("elapsed", 0)); kills = int(data.get("kills", 0)); surrendered = int(data.get("surrendered", 0)); rescued = int(data.get("rescued", 0)); damage_dealt = float(data.get("damage_dealt", 0))
	units = _restore_vectors(data.get("units", []).duplicate(true)); enemies = _restore_vectors(data.get("enemies", []).duplicate(true))
	towers = _restore_vectors(data.get("towers", []).duplicate(true)); traps = _restore_vectors(data.get("traps", []).duplicate(true))
	effects = _restore_vectors(data.get("effects", []).duplicate(true)); projectiles = _restore_vectors(data.get("projectiles", []).duplicate(true))
	_zones = _restore_vectors(data.get("zones", []).duplicate(true)); _scheduled = _restore_vectors(data.get("scheduled", []).duplicate(true))
	_spawn_queue = data.get("spawn_queue", []).duplicate(true); _wave_clock = float(data.get("wave_clock", 0))
	_next_uid = int(data.get("next_uid", 1)); _accumulator = float(data.get("accumulator", 0))
	_wave_kills = int(data.get("wave_kills", 0)); _wave_surrendered = int(data.get("wave_surrendered", 0))
	_history = _restore_vectors(data.get("history", []).duplicate(true)); _future = _restore_vectors(data.get("future", []).duplicate(true))
	_rng.seed = int(data.get("rng_seed", str(_seed))); _rng.state = int(data.get("rng_state", str(_rng.state)))
	events.clear()
	return _result(true, "Battle restored.")

func _array(value: Vector2) -> Array:
	return [value.x, value.y]

func _json_safe(value):
	if value is Vector2:
		return _array(value)
	if value is Vector2i:
		return [value.x, value.y]
	if value is Dictionary:
		var result: Dictionary = {}
		for key in value:
			result[str(key)] = _json_safe(value[key])
		return result
	if value is Array:
		var result: Array = []
		for item in value:
			result.append(_json_safe(item))
		return result
	return value

func _restore_vectors(value, key: String = ""):
	if value is Dictionary:
		for subkey in value.keys():
			value[subkey] = _restore_vectors(value[subkey], str(subkey))
		return value
	if value is Array:
		if key in ["pos", "from", "to", "anchor", "facing"] and value.size() == 2 and (value[0] is int or value[0] is float):
			return _vec(value)
		for i in range(value.size()):
			value[i] = _restore_vectors(value[i])
	return value

func _valid_point(value) -> bool:
	if value is Vector2:
		return is_finite(value.x) and is_finite(value.y) and absf(value.x - roundf(value.x)) < 0.001 and absf(value.y - roundf(value.y)) < 0.001
	if not value is Array or value.size() != 2:
		return false
	if not (value[0] is int or value[0] is float) or not (value[1] is int or value[1] is float):
		return false
	return _valid_point(Vector2(float(value[0]), float(value[1])))

func _effective_range(entity: Dictionary) -> float:
	return float(entity.get("range", 3.0)) * _stat_multiplier(entity, "range")

func _break_anchor(anchor: Dictionary, destroyed: bool):
	var owner = _entity(str(anchor.get("owner_uid", "")))
	if owner.is_empty():
		return
	owner["shield"] = 0.0
	owner["statuses"] = owner.get("statuses", []).filter(func(s): return not str(s.get("key", "")).ends_with(":anchors"))
	if destroyed:
		_add_status(owner, {"kind": "buff", "stat": "damage_taken", "multiplier": 1.2, "remaining": float(anchor.get("exposed_duration", 3)), "source_uid": anchor["uid"], "key": "broken_oath"})
		for other in enemies:
			if other.get("anchor", false) and other.get("owner_uid", "") == owner["uid"]:
				other["hp"] = 0.0
		_fx("anchor_break", owner["pos"], 0.8, "#f4c86b", 2.0)

func _incoming_multiplier(target: Dictionary, source: Dictionary, is_ability: bool) -> float:
	var result: float = 1.0
	var mitigation: float = 1.0
	for status in target.get("statuses", []):
		if status.get("kind", "") != "buff":
			continue
		if status.get("basic_only", false) and is_ability:
			continue
		var stat = str(status.get("stat", ""))
		var multiplier = float(status.get("multiplier", 1.0))
		if stat == "damage_taken":
			result *= multiplier
		elif stat == "armor":
			result /= maxf(0.1, multiplier)
		elif stat == "damage_reduction":
			if status.get("front_only", false) and not source.is_empty():
				var toward: Vector2 = (source["pos"] - target["pos"]).normalized()
				var facing: Vector2 = target.get("facing", Vector2.RIGHT)
				if toward.dot(facing) >= 0:
					mitigation *= multiplier
				else:
					result *= float(status.get("back_multiplier", 1.0))
			else:
				mitigation *= multiplier
	return clampf(result * maxf(0.5, mitigation), 0.1, 4.0)

func _absorb_shield(target: Dictionary, incoming: float) -> float:
	var absorbed: float = 0.0
	for status in target.get("statuses", []):
		if status.get("kind", "") != "shield":
			continue
		var remaining = float(status.get("remaining_shield", status.get("amount", 0)))
		var block = minf(remaining, incoming - absorbed)
		status["remaining_shield"] = maxf(0, remaining - block)
		absorbed += block
		if absorbed >= incoming:
			break
	target["shield"] = maxf(0, float(target.get("shield", 0)) - absorbed)
	return absorbed

func _shield_resistance(entity: Dictionary, key: String) -> float:
	var resistance: float = 0.0
	for status in entity.get("statuses", []):
		if status.get("kind", "") == "shield" and float(status.get("remaining_shield", status.get("amount", 0))) > 0:
			resistance = maxf(resistance, float(status.get(key, 0)))
	return resistance

func _shield_flag(entity: Dictionary, key: String) -> bool:
	for status in entity.get("statuses", []):
		if status.get("kind", "") == "shield" and float(status.get("remaining_shield", status.get("amount", 0))) > 0 and status.get(key, false):
			return true
	return false

func _is_landed(entity: Dictionary) -> bool:
	return entity.get("statuses", []).any(func(status): return status.get("landed", false))

func _evades(target: Dictionary, projectile: bool) -> bool:
	var statuses: Array = target.get("statuses", [])
	for i in range(statuses.size() - 1, -1, -1):
		var status: Dictionary = statuses[i]
		if status.get("kind", "") != "buff" or status.get("stat", "") != "evasion":
			continue
		if status.get("one_projectile", false):
			if projectile:
				statuses.remove_at(i)
				return true
		elif _rng.randf() < float(status.get("multiplier", 0.1)):
			return true
	return false

func _interrupt(target: Dictionary):
	target["windup"] = 0.0
	target["cast_revision"] = int(target.get("cast_revision", 0)) + 1
	target["state"] = "hit"; target["state_timer"] = 0.22
	_scheduled = _scheduled.filter(func(action): return not (action.get("source_uid", "") == target["uid"] and (action.get("kind", "") == "ability" or action.get("effect", {}).get("interruptible", false))))
	_fx("interrupt", target["pos"], 0.5, "#eee0b7", 0.7)

func _projectile_blocked(projectile: Dictionary) -> bool:
	var source = _entity(str(projectile.get("source_uid", "")))
	if source.is_empty():
		return false
	for zone in _zones:
		if not zone["effect"].get("blocks_projectile", false) or float(zone.get("hp", 0)) <= 0:
			continue
		if zone.get("faction", "") == source.get("faction", ""):
			continue
		if projectile["pos"].distance_to(zone["pos"]) < 0.8:
			zone["hp"] = 0.0
			_fx("blocked", zone["pos"], 0.4, "#eee0b7", 0.75)
			return true
	return false

func _validate_restore(data: Dictionary) -> String:
	for key in ["gate_hp", "gate_max_hp", "enemy_hp_multiplier"]:
		var value = data.get(key, 1.0 if key == "enemy_hp_multiplier" else 100.0)
		if not (value is int or value is float) or not is_finite(float(value)):
			return "The saved battle has invalid " + key + "."
	for key in ["units", "enemies", "towers", "traps", "effects", "projectiles", "zones", "scheduled", "spawn_queue", "history", "future"]:
		var value = data.get(key, [])
		if not value is Array or not value.all(func(item): return item is Dictionary):
			return "The saved battle contains invalid " + key + "."
	var party = data.get("party_ids", [])
	if not party is Array or party.size() > MAX_UNITS:
		return "The saved party is invalid."
	for key in ["units", "enemies", "towers"]:
		for entity in data.get(key, []):
			if not entity.get("uid", "") is String or str(entity.get("uid", "")).is_empty():
				return "The saved actor identity is invalid."
			var position = entity.get("pos", [])
			if not position is Array or position.size() != 2 or not (position[0] is int or position[0] is float) or not (position[1] is int or position[1] is float):
				return "The saved actor position is invalid."
			if not is_finite(float(position[0])) or not is_finite(float(position[1])):
				return "The saved actor position is not finite."
			if not (entity.get("hp", null) is int or entity.get("hp", null) is float) or not (entity.get("max_hp", null) is int or entity.get("max_hp", null) is float):
				return "The saved actor health is invalid."
			if not entity.get("statuses", []) is Array:
				return "The saved actor statuses are invalid."
			if key == "units" and (not entity.get("cooldowns", []) is Array or entity.get("cooldowns", []).size() != 2):
				return "The saved ability cooldowns are invalid."
	return ""

func _command_set_mode(cmd: Dictionary) -> Dictionary:
	if phase not in ["planning", "combat"]:
		return _result(false, "Movement orders are available in an active battle.")
	var unit = _entity(str(cmd.get("uid", "")))
	var mode = str(cmd.get("mode", ""))
	if unit.is_empty() or unit not in units or float(unit.get("hp", 0)) <= 0 or mode not in MODES:
		return _result(false, "Select a living ally and Guard, Patrol, or Advance.")
	if _preview_only:
		return _result(true, "Movement order available.")
	if phase == "planning":
		_record_history()
	unit["mode"] = mode
	unit["tower_uid"] = ""
	if mode == "Guard":
		unit["anchor"] = unit["pos"]
	elif mode == "Patrol":
		unit["patrol_path"] = _closest_patrol(unit["pos"])
		unit["patrol_index"] = 0
	_layout_changed(mode + " order issued.")
	return _result(true, mode + " order issued.")
