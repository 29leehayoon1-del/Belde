extends Control
class_name BeldeBattleView

var app
var sim
var art: BeldeArt
var hovered_cell: Vector2i = Vector2i(-1, -1)
var clock: float = 0.0
var drag_uid: String = ""
var drag_start: Vector2 = Vector2.ZERO
var dragging: bool = false
var show_grid: bool = false
var show_routes: bool = true
var map_index: int = 0
var foliage: Array = []
const TILE: float = 32.0
const INK: Color = Color("18232c")
const GOLD: Color = Color("d5aa69")

func configure(owner_app, simulation, visual: BeldeArt, index: int) -> void:
	app = owner_app
	sim = simulation
	art = visual
	map_index = index
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	for i in range(44):
		foliage.append(Vector3(fmod(i * 113.0, 1024.0), fmod(i * 61.0, 640.0), float(i % 4)))

func _process(delta: float) -> void:
	clock += delta
	queue_redraw()

func _point(v) -> Vector2:
	if v is Vector2:
		return v
	if v is Vector2i:
		return Vector2(v)
	if v is Array and v.size() >= 2:
		return Vector2(float(v[0]), float(v[1]))
	return Vector2.ZERO

func _screen(v) -> Vector2:
	return (_point(v) + Vector2(0.5, 0.5)) * TILE

func _draw() -> void:
	if sim == null:
		return
	_draw_ground()
	_draw_routes()
	_draw_gate()
	for tower in sim.towers:
		_draw_tower(tower)
	for trap in sim.traps:
		_draw_trap(trap)
	if not app.selected_uid.is_empty():
		for u in sim.units:
			if str(u.get("uid", "")) == app.selected_uid and float(u.get("hp", 0)) > 0:
				var pos = _screen(u.get("pos", Vector2.ZERO))
				var radius = float(u.get("range", 3)) * TILE
				draw_circle(pos, radius, Color(0.6, 0.8, 0.78, 0.035))
				draw_arc(pos, radius, 0, TAU, 72, Color(0.57, 0.78, 0.73, 0.35), 1.0, true)
	var entities: Array = []
	for u in sim.units:
		entities.append({"unit": u, "enemy": false})
	for e in sim.enemies:
		entities.append({"unit": e, "enemy": true})
	entities.sort_custom(func(a, b): return _point(a.unit.get("pos", Vector2.ZERO)).y < _point(b.unit.get("pos", Vector2.ZERO)).y)
	for entry in entities:
		_draw_actor(entry.unit, entry.enemy)
	for projectile in sim.projectiles:
		_draw_projectile(projectile)
	for effect in sim.effects:
		_draw_effect(effect)
	_draw_placement()
	for f in app.floating_texts:
		var p = _screen(f.get("pos", Vector2.ZERO)) - Vector2(0, 38 + (1.0 - float(f.get("ttl", 1.0))) * 20.0)
		draw_string(art.body_font, p - Vector2(14, 0), str(f.get("text", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(f.get("color", "fff1cf")))
	if app.paused and sim.phase == "combat":
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.07, 0.1, 0.32))
		draw_string(art.display_font, Vector2(410, 318), "PAUSED", HORIZONTAL_ALIGNMENT_LEFT, -1, 35, Color("eee0b7"))
	draw_rect(Rect2(Vector2.ZERO, size), Color("77634e"), false, 2.0)

func _draw_ground() -> void:
	var base = [Color("425443"), Color("3c5550"), Color("4e4d45"), Color("514f43"), Color("404b42"), Color("3c4a45")][map_index % 6]
	draw_rect(Rect2(Vector2.ZERO, size), base)
	var bg = art.battlefield(map_index)
	if bg != null:
		draw_texture_rect(bg, Rect2(Vector2.ZERO, size), false, Color(0.78, 0.82, 0.8, 0.92))
	else:
		for y in range(20):
			for x in range(32):
				var variation = float((x * 29 + y * 13) % 11) / 110.0 - 0.035
				draw_rect(Rect2(x * 32, y * 32, 32, 32), base.lightened(variation))
				if (x * 5 + y * 7) % 13 == 0:
					draw_line(Vector2(x * 32 + 8, y * 32 + 19), Vector2(x * 32 + 10, y * 32 + 15), base.lightened(0.17), 2)
					draw_line(Vector2(x * 32 + 14, y * 32 + 21), Vector2(x * 32 + 16, y * 32 + 17), base.lightened(0.12), 2)
	if show_grid or app.tool != "select" or not app.drag_tool.is_empty():
		for x in range(33):
			draw_line(Vector2(x * TILE, 0), Vector2(x * TILE, 640), Color(0.88, 0.85, 0.69, 0.12), 1)
		for y in range(21):
			draw_line(Vector2(0, y * TILE), Vector2(1024, y * TILE), Color(0.88, 0.85, 0.69, 0.12), 1)
	for f in ([] if app.settings.get("reduced_effects", false) else foliage):
		var p = Vector2(f.x + sin(clock * 0.3 + f.y) * 15, fmod(f.y + clock * (2.0 + f.z), 640.0))
		draw_rect(Rect2(p, Vector2(2, 1)), Color(0.83, 0.72, 0.43, 0.25))

func _draw_routes() -> void:
	for track in sim.map.get("enemy_tracks", []):
		var points = PackedVector2Array()
		for p in track.get("points", []):
			points.append(_screen(p))
		if points.size() < 2:
			continue
		draw_polyline(points, Color("3a362d"), 38, true)
		draw_polyline(points, Color("8d7650"), 31, true)
		draw_polyline(points, Color("b29b6b"), 24, true)
		for i in range(points.size() - 1):
			var a = points[i]
			var b = points[i + 1]
			var direction = (b - a).normalized()
			for d in range(20, int(a.distance_to(b)), 55):
				var p = a + direction * d
				var n = direction.orthogonal()
				draw_line(p - direction * 4 + n * 3, p + direction * 2, Color(0.32, 0.28, 0.2, 0.38), 1)
				draw_line(p - direction * 4 - n * 3, p + direction * 2, Color(0.32, 0.28, 0.2, 0.38), 1)
		var entry = points[0]
		draw_line(entry - Vector2(0, 30), entry + Vector2(0, 8), Color("4b3231"), 3)
		draw_colored_polygon(PackedVector2Array([entry + Vector2(0, -28), entry + Vector2(18, -24), entry + Vector2(0, -14)]), Color("ad6660"))
		if show_routes:
			for i in range(points.size() - 1):
				var p = (points[i] + points[i + 1]) * 0.5
				var dir = (points[i + 1] - points[i]).normalized()
				draw_line(p - dir * 6 + dir.orthogonal() * 4, p + dir * 3, Color("b8735a"), 2)
				draw_line(p - dir * 6 - dir.orthogonal() * 4, p + dir * 3, Color("b8735a"), 2)
	if show_routes:
		for track in sim.map.get("ally_patrol_tracks", []):
			var points: Array = track.get("points", [])
			for i in range(points.size() - 1):
				var a = _screen(points[i])
				var b = _screen(points[i + 1])
				var direction = (b - a).normalized()
				for d in range(0, int(a.distance_to(b)), 15):
					var start = a + direction * d
					var finish = a + direction * minf(d + 8, a.distance_to(b))
					draw_line(start - direction.orthogonal() * 2, finish - direction.orthogonal() * 2, Color(0.47, 0.76, 0.74, 0.62), 1)
					draw_line(start + direction.orthogonal() * 2, finish + direction.orthogonal() * 2, Color(0.47, 0.76, 0.74, 0.62), 1)
			for p in points:
				draw_arc(_screen(p), 5, 0, TAU, 12, Color("85b8ae"), 1.0, true)
	for p in sim.map.get("tower_pad_centers", []):
		var pos = _screen(p)
		draw_rect(Rect2(pos - Vector2(11, 11), Vector2(22, 22)), Color(0.09, 0.13, 0.15, 0.35))
		draw_rect(Rect2(pos - Vector2(9, 9), Vector2(18, 18)), Color(0.8, 0.72, 0.49, 0.5), false, 1)

func _draw_gate() -> void:
	var tracks = sim.map.get("enemy_tracks", [])
	var pos = Vector2(960, 336)
	if not tracks.is_empty():
		var points = tracks[0].get("points", [])
		if not points.is_empty():
			pos = _screen(points[-1])
	draw_rect(Rect2(pos - Vector2(18, 30), Vector2(36, 48)), Color("333d41"))
	draw_rect(Rect2(pos - Vector2(22, 35), Vector2(13, 58)), Color("8b8a77"))
	draw_rect(Rect2(pos + Vector2(9, -35), Vector2(13, 58)), Color("8b8a77"))
	draw_rect(Rect2(pos - Vector2(13, 33), Vector2(26, 13)), Color("c2ad79"))
	for x in [-8, -3, 2, 7]:
		draw_line(pos + Vector2(x, -18), pos + Vector2(x, 20), Color("9b7952"), 2)
	var ratio = clampf(float(sim.gate_hp) / maxf(1.0,float(sim.gate_max_hp)), 0.0, 1.0)
	draw_rect(Rect2(pos - Vector2(25, 46), Vector2(50, 5)), Color("202c31"))
	draw_rect(Rect2(pos - Vector2(25, 46), Vector2(50 * ratio, 5)), Color("a2bd84"))

func _draw_tower(tower: Dictionary) -> void:
	var p = _screen(tower.get("pos", tower.get("cell", Vector2.ZERO)))
	var level = int(tower.get("level", 1))
	var id = str(tower.get("id", tower.get("tower_id", "TOWER04")))
	draw_circle(p + Vector2(0, 6), 20, Color(0, 0, 0, 0.2))
	draw_rect(Rect2(p - Vector2(14, 4), Vector2(28, 13)), Color("5c635d"))
	draw_rect(Rect2(p - Vector2(12, 7), Vector2(24, 10)), Color("a59b7c"))
	match id:
		"TOWER01":
			draw_rect(Rect2(p - Vector2(11, 31), Vector2(22, 30)), Color("776044"))
			draw_rect(Rect2(p - Vector2(7, 24), Vector2(14, 12)), Color("172b30"))
			draw_colored_polygon(PackedVector2Array([p + Vector2(-18, -29), p + Vector2(0, -42), p + Vector2(18, -29)]), Color("b39f6a"))
		"TOWER02":
			draw_line(p, p - Vector2(0, 42), Color("71533d"), 6)
			draw_line(p + Vector2(-15, -31), p + Vector2(15, -31), GOLD, 4)
			draw_circle(p - Vector2(0, 26), 8, Color("d7a55d"))
			draw_line(p - Vector2(0, 35), p - Vector2(0, 15), Color("66523d"), 2)
		"TOWER03":
			draw_circle(p - Vector2(0, 10), 13, Color("8d6d50"))
			draw_circle(p - Vector2(0, 13), 9, Color("e7b86f"))
			draw_colored_polygon(PackedVector2Array([p + Vector2(-6, -17), p + Vector2(-2, -30), p + Vector2(4, -21), p + Vector2(8, -15)]), Color("f4d190"))
		"TOWER04":
			draw_rect(Rect2(p - Vector2(6, 27), Vector2(12, 28)), Color("816444"))
			draw_line(p + Vector2(-18, -25), p + Vector2(18, -17), GOLD, 5)
			draw_line(p + Vector2(-18, -25), p + Vector2(6, -37), Color("c7b58a"), 1)
			draw_line(p + Vector2(18, -17), p + Vector2(6, -37), Color("c7b58a"), 1)
			draw_line(p + Vector2(0, -14), p + Vector2(10, -42), Color("e3c78d"), 3)
	for i in range(level):
		draw_rect(Rect2(p + Vector2(-9 + i * 7, 9), Vector2(4, 3)), GOLD)
	if str(tower.get("uid", "")) == app.selected_tower:
		draw_rect(Rect2(p - Vector2(21, 42), Vector2(42, 58)), Color("e3d29b"), false, 1)

func _draw_trap(trap: Dictionary) -> void:
	var p = _screen(trap.get("pos", Vector2.ZERO))
	var color = Color("d7b06a")
	if str(trap.get("state", "")) in ["spent", "triggered"]:
		color.a = 0.28
	var points = PackedVector2Array()
	for i in range(7):
		points.append(p + Vector2(cos(i * TAU / 6), sin(i * TAU / 6)) * 11)
	draw_polyline(points, color, 1.0, true)
	var id = str(trap.get("id", trap.get("trap_id", "TRAP01")))
	if id == "TRAP02":
		draw_circle(p, 6, Color("b67847"))
		draw_line(p + Vector2(0, -5), p + Vector2(4, -11), Color("d9c68d"), 1)
	elif id == "TRAP03":
		draw_line(p + Vector2(-3, 6), p + Vector2(-3, -18), Color("b6935f"), 2)
		draw_colored_polygon(PackedVector2Array([p + Vector2(-3, -18), p + Vector2(9, -15), p + Vector2(-3, -8)]), Color("e2d2a8"))
	else:
		draw_line(p + Vector2(-7, -6), p + Vector2(7, 6), color, 1)
		draw_line(p + Vector2(7, -6), p + Vector2(-7, 6), color, 1)

func _draw_actor(entity: Dictionary, enemy: bool) -> void:
	var p = _screen(entity.get("pos", Vector2.ZERO))
	var hp = float(entity.get("hp", 1))
	var state = str(entity.get("state", "idle"))
	var id = str(entity.get("id", ""))
	var uid = str(entity.get("uid", ""))
	var role = str(entity.get("class", "DPS"))
	var nonhostile = state in ["surrender", "surrendered", "noncombatant"] or bool(entity.get("surrendered", false)) or bool(entity.get("noncombatant", false))
	var selected = uid == app.selected_uid
	var color = Color("cc8476") if enemy else BeldeArt.class_color(role)
	if nonhostile:
		color = Color("e6ddbe")
	if hp <= 0:
		state = "downed"
	var hop = 0.0
	if state in ["walk", "run"] and hp > 0:
		hop = absf(sin(clock * (11 if state == "run" else 7) + p.x)) * 2.5
	draw_set_transform(p + Vector2(0, 3), 0, Vector2(1.0, 0.32))
	draw_circle(Vector2.ZERO, 17 if id != "BOSS01" else 32, Color(0, 0, 0, 0.28))
	draw_set_transform(Vector2.ZERO)
	if selected:
		draw_arc(p, 20, 0, TAU, 32, Color("ead6a3"), 2, true)
	elif hp > 0:
		draw_arc(p, 11, 0, TAU, 18, Color(color, 0.55), 1, true)
	var body = art.actor(id, state, clock + float(entity.get("animation_time", 0)))
	if body != null:
		var sprite_rect = art.actor_rect(id)
		sprite_rect.position.y -= hop
		var facing = _point(entity.get("facing", Vector2.RIGHT))
		draw_set_transform(p, 0, Vector2(-1 if facing.x < -0.1 else 1, 1))
		if art.effect_only(id, state):
			var idle_body = art.actor(id, "idle", clock)
			if idle_body != null: draw_texture_rect(idle_body, sprite_rect, false)
		draw_texture_rect(body, sprite_rect, false, Color(1, 1, 1, 0.63 if hp <= 0 else 1.0))
		draw_set_transform(Vector2.ZERO)
	else:
		_draw_fallback_actor(p, role, color, enemy, hp <= 0, hop)
	if hp > 0 and (not enemy or hp < float(entity.get("max_hp", hp)) or id == "BOSS01"):
		var bar = Rect2(p - Vector2(17, 54 if id != "BOSS01" else 105), Vector2(34, 4))
		draw_rect(bar.grow(1), INK)
		var fill = bar
		fill.size.x *= clampf(hp / maxf(1, float(entity.get("max_hp", hp))), 0, 1)
		draw_rect(fill, color)
	if float(entity.get("shield", 0)) > 0:
		draw_arc(p - Vector2(0, 20), 25, PI, TAU, 20, Color("a5d0db"), 2, true)
	if nonhostile:
		draw_line(p + Vector2(12, -13), p + Vector2(12, -41), Color("d7c99b"), 2)
		draw_colored_polygon(PackedVector2Array([p + Vector2(12, -41), p + Vector2(28, -37), p + Vector2(13, -28)]), Color("f3ebd3"))
	elif hp <= 0 and not enemy:
		draw_string(art.body_font, p + Vector2(-4, -8), "+", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("e4c89b"))
	if selected and hp > 0:
		var mark = "o" if str(entity.get("mode", "Guard")) == "Guard" else ("↔" if str(entity.get("mode", "")) == "Patrol" else "↑")
		draw_string(art.body_font, p + Vector2(-5, 18), mark, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("ead6a3"))

func _draw_fallback_actor(p: Vector2, role: String, color: Color, enemy: bool, downed: bool, hop: float) -> void:
	var y = -25.0 - hop
	if downed:
		draw_rect(Rect2(p + Vector2(-14, -9), Vector2(27, 8)), color.darkened(0.2))
		return
	draw_rect(Rect2(p + Vector2(-10, y), Vector2(20, 23)), color.darkened(0.28))
	draw_circle(p + Vector2(0, y - 5), 8, Color("c5a47c") if not enemy else color.lightened(0.2))
	draw_rect(Rect2(p + Vector2(-8, -3), Vector2(6, 8)), INK)
	draw_rect(Rect2(p + Vector2(2, -3), Vector2(6, 8)), INK)
	if role == "Tanker":
		draw_rect(Rect2(p + Vector2(-18, y + 3), Vector2(12, 19)), Color("a2b4bb"))
	elif role == "Healer":
		draw_line(p + Vector2(12, -1), p + Vector2(12, y - 10), Color("bba071"), 3)
		draw_circle(p + Vector2(12, y - 10), 4, Color("a9d1a7"))
	else:
		draw_line(p + Vector2(8, y + 9), p + Vector2(22, y - 4), Color("cfbd8a"), 3)

func _draw_projectile(projectile: Dictionary) -> void:
	var p = _screen(projectile.get("pos", Vector2.ZERO))
	var color = Color(str(projectile.get("color", "edc78a")))
	var direction = (_point(projectile.get("to", Vector2.RIGHT)) - _point(projectile.get("from", Vector2.ZERO))).normalized()
	draw_line(p - direction * 8, p, Color(color, 0.4), 3)
	draw_circle(p, 2.2, color)

func _draw_effect(effect: Dictionary) -> void:
	var p = _screen(effect.get("pos", Vector2.ZERO))
	var ttl = float(effect.get("ttl", 0.2))
	var duration = maxf(float(effect.get("max_ttl", 0.5)), 0.01)
	var alpha = clampf(ttl / duration, 0, 1)
	var color = Color(str(effect.get("color", "e1bb76")))
	color.a = alpha * 0.8
	var kind = str(effect.get("kind", "hit"))
	var radius = float(effect.get("radius", 0.6)) * 32
	if kind in ["heal", "regen", "cleanse"]:
		for i in range(4):
			var o = Vector2((i % 2) * 15 - 8, -15 - (1 - alpha) * 22 - (i / 2) * 12)
			draw_line(p + o - Vector2(3, 0), p + o + Vector2(3, 0), color, 2)
			draw_line(p + o - Vector2(0, 3), p + o + Vector2(0, 3), color, 2)
	elif kind in ["shield", "intercept", "damage_reduction"]:
		draw_arc(p - Vector2(0, 15), maxf(20, radius), PI * 0.9, TAU * 1.05, 24, color, 2.5, true)
	elif kind in ["telegraph", "warning"]:
		draw_circle(p, radius, Color(color, alpha * 0.12))
		draw_arc(p, radius, 0, TAU, 36, color, 2, true)
	elif kind in ["trap", "zone", "slow", "root"]:
		var polygon = PackedVector2Array()
		for i in range(7):
			polygon.append(p + Vector2(cos(i * TAU / 6), sin(i * TAU / 6)) * maxf(13, radius))
		draw_polyline(polygon, color, 2, true)
	else:
		draw_arc(p - Vector2(0, 10), maxf(9, radius * (1.0 - alpha * 0.4)), -1.2 + (1.0 - alpha), 1.0 + (1.0 - alpha), 14, color, 2.0, true)
		for i in range(3):
			var o = Vector2(cos(i * 2.0), sin(i * 2.0)) * (12 + (1 - alpha) * 12)
			draw_rect(Rect2(p + o - Vector2(1, 14), Vector2(2, 2)), color)

func _draw_placement() -> void:
	var current = app.drag_tool if not app.drag_tool.is_empty() else app.tool
	if current != "select" and hovered_cell.x >= 0 and hovered_cell.x < 32 and hovered_cell.y >= 0 and hovered_cell.y < 20:
		var cmd = app.command_for_tool(current, hovered_cell)
		var result = app.preview_command(cmd)
		var valid = bool(result.get("ok", false))
		var p = _screen(hovered_cell)
		var color = Color("8bcec2") if valid else Color("d38d82")
		draw_rect(Rect2(p - Vector2(16, 16), Vector2(32, 32)), Color(color, 0.17))
		draw_rect(Rect2(p - Vector2(15, 15), Vector2(30, 30)), color, false, 2)
		if not valid:
			draw_line(p - Vector2(10, 10), p + Vector2(10, 10), color, 2)
			draw_line(p + Vector2(10, -10), p + Vector2(-10, 10), color, 2)
		elif current.begins_with("tower:"):
			_draw_tower({"id": current.trim_prefix("tower:"), "pos": Vector2(hovered_cell), "level": 1})
		elif current.begins_with("trap:"):
			_draw_trap({"id": current.trim_prefix("trap:"), "pos": Vector2(hovered_cell)})
	if not app.track_draft.is_empty():
		var points = PackedVector2Array()
		for p in app.track_draft:
			points.append(_screen(p))
		if points.size() > 1:
			draw_polyline(points, Color("91d8c7"), 3, true)
		for p in points:
			draw_circle(p, 3, Color("e0d8b3"))

func _gui_input(event: InputEvent) -> void:
	var mouse = get_local_mouse_position()
	hovered_cell = Vector2i(floori(mouse.x / TILE), floori(mouse.y / TILE))
	if event is InputEventMouseMotion:
		if not drag_uid.is_empty() and mouse.distance_to(drag_start) > 8:
			dragging = true
		if app.tool == "track" and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			app.append_track_cell(hovered_cell)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			app.set_tool("select")
			app.track_draft.clear()
			return
		if event.button_index != MOUSE_BUTTON_LEFT:
			return
		if event.pressed:
			if app.tool == "track":
				app.track_draft.clear()
				app.append_track_cell(hovered_cell)
			elif app.tool == "select" and app.drag_tool.is_empty():
				var closest = _entity_at(Vector2(hovered_cell))
				if not closest.is_empty():
					if closest.get("entity_type", "") == "tower":
						app.select_tower(str(closest.get("uid", "")))
					else:
						app.select_unit(str(closest.get("uid", "")))
						drag_uid = str(closest.get("uid", ""))
						drag_start = mouse
						dragging = false
		else:
			if not app.drag_tool.is_empty():
				app.apply_tool(app.drag_tool, hovered_cell)
				app.drag_tool = ""
			elif app.tool == "track":
				app.commit_track()
			elif dragging and not drag_uid.is_empty():
				app.apply_tool("move:" + drag_uid, hovered_cell)
			elif app.tool != "select":
				app.apply_tool(app.tool, hovered_cell)
			dragging = false
			drag_uid = ""

func _entity_at(pos: Vector2) -> Dictionary:
	for u in sim.units:
		if float(u.get("hp", 0)) > 0 and _point(u.get("pos", Vector2.ZERO)).distance_to(pos) < 1.0:
			return u
	for t in sim.towers:
		if _point(t.get("pos", Vector2.ZERO)).distance_to(pos) < 1.0:
			var result = t.duplicate()
			result["entity_type"] = "tower"
			return result
	return {}
