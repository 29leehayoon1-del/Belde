extends RefCounted
class_name BeldeArt

var portraits: Dictionary = {}
var actors: Dictionary = {}
var monsters: Dictionary = {}
var cache: Dictionary = {}
var portrait_cache: Dictionary = {}
var actor_cache: Dictionary = {}
var body_font: Font
var display_font: Font

func _init() -> void:
	portraits = _read("res://assets/portraits/manifest.json")
	actors = _read("res://assets/actors/manifest.json")
	monsters = _read("res://assets/enemies/manifest.json")
	body_font = load("res://assets/fonts/body.ttf")
	display_font = load("res://assets/fonts/display.ttf")

func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var result = JSON.parse_string(FileAccess.get_file_as_string(path))
	return result if result is Dictionary else {}

func texture(path: String) -> Texture2D:
	if cache.has(path):
		return cache[path]
	if not FileAccess.file_exists(path):
		return null
	var value = load(path)
	if value is Texture2D:
		cache[path] = value
		return value
	return null

func portrait(id: String) -> Texture2D:
	if portrait_cache.has(id):
		return portrait_cache[id]
	var entry: Dictionary = portraits.get(id, {})
	if entry.is_empty():
		return null
	var source = texture(str(entry.get("file", "")))
	if source == null:
		return null
	var region: Array = entry.get("region", [0, 0, 96, 96])
	var atlas = AtlasTexture.new()
	atlas.atlas = source
	atlas.region = Rect2(float(region[0]), float(region[1]), float(region[2]), float(region[3]))
	portrait_cache[id] = atlas
	return atlas

func actor(id: String, state: String, clock: float) -> Texture2D:
	var entry: Dictionary = actors.get(id, monsters.get(id, {}))
	if entry.is_empty():
		return null
	var source = texture(str(entry.get("file", "")))
	if source == null:
		return null
	var frames: Dictionary = entry.get("frames", {})
	var name = state
	if state in ["walk", "patrol", "advance"]:
		name = "walk_a" if int(clock * 9.0) % 2 == 0 else "walk_b"
	elif state == "run":
		name = "run" if int(clock * 13.0) % 2 == 0 else "walk_a"
	elif state == "surrender":
		name = "idle"
	var frame = int(frames.get(name, 0))
	var key = id + ":" + str(frame)
	if actor_cache.has(key):
		return actor_cache[key]
	var cols = int(entry.get("cols", 8))
	var rows = int(entry.get("rows", 1))
	var cell = Vector2(float(source.get_width()) / cols, float(source.get_height()) / rows)
	var row = int(entry.get("row", 0))
	var y0 = row * cell.y
	var row_bounds: Array = entry.get("row_bounds_px", [])
	if row_bounds.size() > row + 1:
		y0 = float(row_bounds[row])
		cell.y = float(row_bounds[row + 1]) - y0
	var atlas = AtlasTexture.new()
	atlas.atlas = source
	atlas.region = Rect2(Vector2(frame * cell.x, y0), cell)
	actor_cache[key] = atlas
	return atlas

func location(origin: String) -> Texture2D:
	var source = texture("res://assets/portraits/locations.png")
	if source == null:
		return null
	var regions = {
		"Bar": Rect2(12, 113, 516, 257),
		"Kingdom": Rect2(553, 113, 488, 257),
		"Village": Rect2(12, 414, 516, 298),
		"Royal Capital": Rect2(553, 414, 488, 298),
		"Prison": Rect2(12, 753, 1026, 245)
	}
	var atlas = AtlasTexture.new()
	atlas.atlas = source
	atlas.region = regions.get(origin, Rect2(0, 0, 512, 320))
	return atlas

func battlefield(index: int) -> Texture2D:
	var source = texture("res://assets/world/battlefields.png")
	if source == null:
		return null
	var atlas = AtlasTexture.new()
	atlas.atlas = source
	var cell = Vector2(float(source.get_width()) / 3.0, float(source.get_height()) / 2.0)
	atlas.region = Rect2(Vector2((index % 3) * cell.x, (index / 3) * cell.y), cell)
	return atlas

static func class_color(role: String) -> Color:
	match role:
		"Healer": return Color("85c2a2")
		"DPS": return Color("e6a46f")
		"Tanker": return Color("8cadcc")
		"Strategist": return Color("c6acdf")
	return Color("ddcda6")

func actor_entry(id: String) -> Dictionary:
	return actors.get(id, monsters.get(id, {}))

func effect_only(id: String, state: String) -> bool:
	return state in actor_entry(id).get("effect_only_frames", [])

func actor_rect(id: String) -> Rect2:
	var entry = actor_entry(id)
	var source = texture(str(entry.get("file", "")))
	if source == null: return Rect2(-32, -52, 64, 64)
	var rows = int(entry.get("rows", 1))
	var row = int(entry.get("row", 0))
	var cell = Vector2(float(source.get_width()) / int(entry.get("cols", 8)), float(source.get_height()) / rows)
	var bounds: Array = entry.get("row_bounds_px", [])
	if bounds.size() > row + 1: cell.y = float(bounds[row + 1]) - float(bounds[row])
	var ink: Array = entry.get("idle_bounds_px", [cell.x * 0.2, cell.y * 0.15, cell.x * 0.6, cell.y * 0.7])
	var height = 95.0 if id == "BOSS01" else 52.0 if actors.has(id) or id in ["MOB03", "MOB06"] else 39.0
	var scale_factor = height / maxf(float(ink[3]), 1)
	var origin = Vector2(float(ink[0]) + float(ink[2]) * 0.5, float(ink[1]) + float(ink[3]))
	return Rect2(-origin * scale_factor, cell * scale_factor)
