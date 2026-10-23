class_name BeldeCatalog
extends RefCounted

var characters: Array = []
var by_id: Dictionary = {}
var world: Dictionary = {}
var abilities: Dictionary = {}
var story: Dictionary = {}
var enemy_by_id: Dictionary = {}
var map_by_id: Dictionary = {}
var errors: Array = []

func _init() -> void:
	var character_data = _load_json("res://data/characters.json")
	characters = character_data.get("characters", [])
	for character in characters:
		by_id[str(character.get("id", ""))] = character
	world = _load_json("res://data/world.json")
	abilities = _load_json("res://data/abilities.json")
	story = _load_json("res://data/story.json")
	for enemy in world.get("enemies", []):
		enemy_by_id[str(enemy.get("id", ""))] = enemy
	for battlefield in world.get("maps", []):
		map_by_id[str(battlefield.get("id", ""))] = battlefield
	if characters.size() != 58 or abilities.size() != 116:
		errors.append("Content inventory must contain 58 characters and 116 abilities.")

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		errors.append("Missing content: " + path)
		return {}
	var parser = JSON.new()
	var result = parser.parse(FileAccess.get_file_as_string(path))
	if result != OK or not parser.data is Dictionary:
		errors.append("Invalid content JSON: " + path)
		return {}
	return parser.data

func get_character(id: String) -> Dictionary:
	return by_id.get(id, {})

func get_ability(id: String, slot: int) -> Dictionary:
	return abilities.get(id + ":" + str(slot), {})

func get_enemy(id: String) -> Dictionary:
	return enemy_by_id.get(id, {})

func get_enemy_ability(id: String, slot: int) -> Dictionary:
	var enemy = get_enemy(id)
	var entries: Array = enemy.get("runtime_abilities", [])
	if slot < 0 or slot >= entries.size():
		return {}
	return entries[slot]

func get_map(id: String) -> Dictionary:
	return map_by_id.get(id, {})

func candidates(origin: String) -> Array:
	var result: Array = []
	for character in characters:
		if str(character.get("origin", "")) == origin:
			result.append(character)
	return result

func get_origin_description(origin: String) -> String:
	var descriptions = {
		"Bar": "The Bent Lantern · six rough-edged caravan guards and travelers.",
		"Kingdom": "The Crownward Yard · fifteen trained knights and royal specialists.",
		"Village": "Reedwake Common · ten resourceful neighbors with repaired equipment.",
		"Royal Capital": "Glassmarket Contracts · ten mercenaries whose consciences come with the contract.",
		"Prison": "The Quiet Cells · twelve volunteers ready to be more than a sentence.",
		"Monster General": "Five banners, five stories · choose two generals whose surrender you will honor."
	}
	return str(descriptions.get(origin, origin))
