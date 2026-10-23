class_name BeldeCampaign
extends RefCounted

const SAVE_VERSION: int = 2
const MAX_PARTY: int = 10
const VALID_ORIGINS: Array = ["Bar", "Kingdom", "Village"]
const MAP_IDS: Array = ["MAP01", "MAP02", "MAP03", "MAP04", "MAP05", "MAP06"]
const VALID_STAGES: Array = ["title", "origin", "recruit", "story", "battle", "generals", "reinforce", "ending"]

var catalog = null
var act: int = 1
var stage: String = "title"
var party: Array = []
var fallen: Array = []
var flags: Dictionary = {}
var history: Array = []
var origin: String = ""
var recruit_limit: int = 2
var selected: Array = []
var map_index: int = 0
var story_key: String = "act1_gate"
var recruitment_origin: String = "Royal Capital"
var ending_data: Dictionary = {}

func _init(content = null) -> void:
	catalog = content
	if catalog == null:
		catalog = load("res://scripts/catalog.gd").new()

func _result(ok: bool, message: String = "") -> Dictionary:
	return {"ok": ok, "message": message, "stage": stage, "act": act}

func _record(kind: String, details: Dictionary = {}) -> void:
	var entry: Dictionary = {"kind": kind, "act": act, "map": current_map_id(), "order": history.size()}
	entry.merge(details, true)
	history.append(entry)

func new_run(chosen_origin: String = "") -> Dictionary:
	if not chosen_origin.is_empty() and not chosen_origin in VALID_ORIGINS:
		return _result(false, "Choose the bar, kingdom, or village.")
	act = 1
	stage = "origin" if chosen_origin.is_empty() else "recruit"
	party.clear()
	fallen.clear()
	flags = {"wins": 0, "losses": 0, "mercy": 0, "crowns_bonus": 0, "gate_bonus": 0, "enemy_hp_multiplier": 1.0, "rallies": 0}
	history.clear()
	origin = chosen_origin
	recruit_limit = 2
	selected.clear()
	map_index = 0
	story_key = "act1_gate"
	recruitment_origin = "Royal Capital"
	ending_data.clear()
	if not chosen_origin.is_empty():
		_record("origin", {"origin": chosen_origin})
	return _result(true, "Choose two allies for the first watch.")

func available_candidates() -> Array:
	var pool: Array = []
	if stage == "recruit":
		pool = catalog.candidates(origin)
	elif stage == "generals":
		pool = catalog.candidates("Monster General")
	elif stage == "reinforce":
		pool = catalog.candidates("Royal Capital") + catalog.candidates("Prison")
	var result: Array = []
	for character in pool:
		var id: String = str(character.get("id", ""))
		if not id in party and not id in fallen:
			result.append(character)
	return result

func recruit(id: String) -> Dictionary:
	if not stage in ["recruit", "generals", "reinforce"]:
		return _result(false, "Recruitment is not open right now.")
	if id in selected:
		selected.erase(id)
		return _result(true, "Selection removed.")
	if selected.size() >= recruit_limit:
		return _result(false, "You have selected all " + str(recruit_limit) + " available places.")
	if party.size() + selected.size() >= MAX_PARTY:
		return _result(false, "The company is full.")
	var eligible: bool = false
	for character in available_candidates():
		if str(character.get("id", "")) == id:
			eligible = true
			break
	if not eligible:
		return _result(false, "That recruit is not available at this location.")
	selected.append(id)
	return _result(true, str(catalog.get_character(id).get("name", id)) + " joins the selection.")

func confirm_recruits() -> Dictionary:
	if not stage in ["recruit", "generals", "reinforce"]:
		return _result(false, "Recruitment is not open right now.")
	if selected.size() != recruit_limit:
		return _result(false, "Choose exactly " + str(recruit_limit) + " allies before continuing.")
	var previous_stage: String = stage
	for id in selected:
		if not id in party:
			party.append(id)
	_record("recruits", {"source": previous_stage, "ids": selected.duplicate()})
	selected.clear()
	if previous_stage == "recruit":
		flags["initial_ids"] = party.duplicate()
		_set_story("act1_gate", 1, 0)
	elif previous_stage == "generals":
		flags["generals_recruited"] = true
		flags["mercy"] = int(flags.get("mercy", 0)) + 1
		_set_story("act3_rescue", 3, 2)
	else:
		flags["reinforcements_chosen"] = true
		_set_story("act4_road", 4, 3)
	return _result(true, "The company is ready.")

func _set_story(key: String, act_number: int, next_map: int) -> void:
	story_key = key
	act = act_number
	map_index = next_map
	stage = "story"

func current_map_id() -> String:
	return str(MAP_IDS[clampi(map_index, 0, MAP_IDS.size() - 1)])

func current_story() -> Dictionary:
	var stories: Dictionary = catalog.story.get("stories", {})
	var data: Dictionary = stories.get(story_key, {}).duplicate(true)
	var first_name: String = "The last watchkeeper"
	if not party.is_empty():
		first_name = str(catalog.get_character(str(party[0])).get("name", "An ally"))
	var lines: Array = []
	for line in data.get("dialogue", []):
		line["speaker"] = str(line.get("speaker", "")).replace("{ally}", first_name)
		line["text"] = str(line.get("text", "")).replace("{ally}", first_name)
		lines.append(str(line["speaker"]) + ": " + str(line["text"]))
	data["lines"] = lines
	if story_key == "act3_rescue" and not fallen.is_empty():
		var rescue_id: String = str(fallen.back())
		data["choices"][0]["label"] = "Search for " + str(catalog.get_character(rescue_id).get("name", rescue_id))
	if story_key == "act4_return":
		var count: int = 5 if bool(flags.get("last_loss", false)) or surviving_originals() <= 1 else 3
		data["subtitle"] = "Choose " + str(count) + " volunteers from the capital and prison."
	return data

func surviving_originals() -> int:
	var count: int = 0
	for id in flags.get("initial_ids", []):
		if id in party:
			count += 1
	return count

func choose_story(choice_id: String) -> Dictionary:
	if stage == "origin":
		return new_run(choice_id)
	if stage == "reinforce" and choice_id in ["visit_capital", "visit_prison"]:
		recruitment_origin = "Prison" if choice_id == "visit_prison" else "Royal Capital"
		return _result(true, "Recruitment location changed; your selections are retained.")
	if stage == "generals" and choice_id in ["skip_generals", "refuse_generals"]:
		flags["refused_generals"] = true
		selected.clear()
		_record("choice", {"choice": "refuse_generals"})
		_set_story("act3_rescue", 3, 2)
		return _result(true, "The generals accept your refusal and withdraw their banners.")
	if stage != "story":
		return _result(false, "There is no story decision to make right now.")
	var data: Dictionary = current_story()
	var choices: Array = data.get("choices", [])
	if choice_id == "continue" and not choices.is_empty():
		choice_id = str(choices[0].get("id", ""))
	var valid: bool = false
	for choice in choices:
		if str(choice.get("id", "")) == choice_id:
			valid = true
			break
	if not valid:
		return _result(false, "Choose one of the decisions shown.")
	_record("choice", {"story": story_key, "choice": choice_id})
	flags[choice_id] = true
	match choice_id:
		"show_orders": flags["crowns_bonus"] = int(flags.get("crowns_bonus", 0)) + 20
		"stand_together": flags["gate_bonus"] = int(flags.get("gate_bonus", 0)) + 10
		"offer_parley": flags["mercy"] = int(flags.get("mercy", 0)) + 1
		"hold_the_gate": flags["crowns_bonus"] = int(flags.get("crowns_bonus", 0)) + 15
		"rescue_ally":
			if not fallen.is_empty() and party.size() < MAX_PARTY:
				var recovered: String = str(fallen.pop_back())
				party.append(recovered)
				flags["rescued_ally"] = recovered
				_record("rescue", {"id": recovered})
			else:
				flags["crowns_bonus"] = int(flags.get("crowns_bonus", 0)) + 25
		"rescue_families":
			flags["mercy"] = int(flags.get("mercy", 0)) + 2
			flags["crowns_bonus"] = int(flags.get("crowns_bonus", 0)) + 35
		"hire_capital", "open_prison":
			recruitment_origin = "Prison" if choice_id == "open_prison" else "Royal Capital"
			recruit_limit = 5 if bool(flags.get("last_loss", false)) or surviving_originals() <= 1 else 3
			recruit_limit = mini(recruit_limit, MAX_PARTY - party.size())
			selected.clear()
			stage = "reinforce"
			return _result(true, "Choose " + str(recruit_limit) + " reinforcements from either location.")
		"take_shortcut":
			flags["skipped_road"] = true
			_set_story("act5_court", 5, 4)
			return _result(true, "You reach Crownroot Court before the siege scouts.")
		"break_oaths": flags["crowns_bonus"] = int(flags.get("crowns_bonus", 0)) + 40
		"protect_wounded": flags["gate_bonus"] = int(flags.get("gate_bonus", 0)) + 15
		"name_the_fallen": flags["enemy_hp_multiplier"] = 0.92
		"challenge_crown": flags["crowns_bonus"] = int(flags.get("crowns_bonus", 0)) + 25
		"forgive":
			ending(true)
			return _result(true, "The crown is set down.")
		"refuse_pardon":
			ending(false)
			return _result(true, "The crown is sealed for judgment.")
		"rally_again":
			flags["rallies"] = int(flags.get("rallies", 0)) + 1
			flags["crowns_bonus"] = int(flags.get("crowns_bonus", 0)) + 150
			stage = "battle"
			return _result(true, "The surviving company rallies for the threshold.")
		"accept_defeat":
			flags["accepted_defeat"] = true
			ending(false)
			return _result(true, "The survivors take the last open road.")
	stage = "battle"
	return _result(true, "Prepare your defenses, then begin the first wave.")

func battle_finished(won: bool, surviving_ids: Array) -> Dictionary:
	if stage != "battle":
		return _result(false, "This battle has already been resolved.")
	var valid_survivors: Array = []
	for id in surviving_ids:
		if id in party and not id in valid_survivors:
			valid_survivors.append(id)
	var lost: Array = []
	for id in party:
		if not id in valid_survivors:
			lost.append(id)
			if not id in fallen:
				fallen.append(id)
	party = valid_survivors
	flags["last_loss"] = not won
	flags["last_battle_won"] = won
	flags["wins" if won else "losses"] = int(flags.get("wins" if won else "losses", 0)) + 1
	flags["crowns_bonus"] = 0
	flags["gate_bonus"] = 0
	flags["enemy_hp_multiplier"] = 1.0
	_record("battle", {"won": won, "survivors": party.duplicate(), "lost": lost})
	match map_index:
		0:
			flags["gate_won"] = won
			_set_story("act2_ford", 2, 1)
		1:
			flags["ford_won"] = won
			if won:
				stage = "generals"
				act = 2
				recruit_limit = mini(2, MAX_PARTY - party.size())
				selected.clear()
			else:
				_set_story("act3_rescue", 3, 2)
		2:
			flags["siege_won"] = won
			_set_story("act4_return", 4, 3)
		3:
			flags["escort_won"] = won
			if won:
				flags["crowns_bonus"] = 75
			_set_story("act5_court", 5, 4)
		4:
			flags["court_won"] = won
			_set_story("act5_throne", 5, 5)
		5:
			flags["final_won"] = won
			_set_story("judgment" if won else "defeat_finale", 5, 5)
	return _result(true, "The company carries its survivors onward.")

func battle_modifiers() -> Dictionary:
	return {
		"crowns_bonus": int(flags.get("crowns_bonus", 0)),
		"gate_bonus": int(flags.get("gate_bonus", 0)),
		"enemy_hp_multiplier": float(flags.get("enemy_hp_multiplier", 1.0)),
		"empty_party_supply": 150 if party.is_empty() else 0
	}

func _stable_hash(value: String) -> int:
	var number: int = 5381
	for index in value.length():
		number = ((number * 33) ^ value.unicode_at(index)) & 0x7fffffff
	return number

func _earned_title_parts() -> Dictionary:
	var epithets: Array = ["Wayward", "Quiet", "Lantern-Bearing"]
	if bool(flags.get("forgiven", false)) and int(flags.get("mercy", 0)) > 0:
		epithets.append("Merciful")
	if int(flags.get("wins", 0)) >= 3:
		epithets.append("Unbroken")
	if origin == "Village":
		epithets.append("Briar-Crowned")
	if origin == "Kingdom":
		epithets.append("Oathbound")
	if not fallen.is_empty():
		epithets.append("Ash-Worn")
		epithets.append("Last")
	if bool(flags.get("final_won", false)):
		epithets.append("Uncrowned")
	var deeds: Array = ["Witness of the Crown", "Guardian of the Hearth"]
	var conditions: Dictionary = {
		"gate_won": "Keeper of the Gate", "offer_parley": "Friend of the Ford",
		"open_prison": "Breaker of Chains", "rescue_families": "Shield of the Lost",
		"show_orders": "Reader of Letters", "siege_won": "Bearer of Five Banners",
		"escort_won": "Warden of Roads", "challenge_crown": "Voice in the Storm"
	}
	for condition in conditions:
		if bool(flags.get(condition, false)):
			deeds.append(conditions[condition])
	var legacies: Array = ["of the Returning"]
	if origin == "Bar":
		legacies.append("of the Bent Lantern")
	if origin == "Village":
		legacies.append("of Reedwake")
	var has_prison_ally: bool = party.any(func(id): return str(id).begins_with("PRI"))
	if has_prison_ally or bool(flags.get("open_prison", false)):
		legacies.append("of the Quiet Cells")
	if bool(flags.get("forgiven", false)):
		legacies.append("of the Dawn Pact")
	else:
		legacies.append("of the Broken Oath")
	if bool(flags.get("escort_won", false)):
		legacies.append("of the Kindled Road")
	if bool(flags.get("final_won", false)):
		legacies.append("of the Empty Throne")
	if flags.has("rescued_ally") or bool(flags.get("rescue_families", false)):
		legacies.append("of the Saved")
	if not fallen.is_empty():
		legacies.append("of the Remembered")
	return {"epithets": epithets, "deeds": deeds, "legacies": legacies}

func ending(forgive: bool) -> Dictionary:
	flags["forgiven"] = forgive
	var defeated: bool = bool(flags.get("accepted_defeat", false))
	var variant: String = "defeat" if defeated else "forgive" if forgive else "refuse_pardon"
	var earned_parts: Dictionary = _earned_title_parts()
	var epithets: Array = earned_parts["epithets"]
	var deeds: Array = earned_parts["deeds"]
	var legacies: Array = earned_parts["legacies"]
	var action_ids: Array = []
	for event in history:
		if event.get("kind", "") == "choice":
			action_ids.append(str(event.get("choice", "")))
	var identity: String = JSON.stringify([origin, party, fallen, action_ids, flags.get("wins", 0), flags.get("losses", 0), forgive])
	var digest: int = _stable_hash(identity)
	var epithet: String = str(epithets[digest % epithets.size()])
	var deed: String = str(deeds[int(float(digest) / 11.0) % deeds.size()])
	var legacy: String = str(legacies[int(float(digest) / 137.0) % legacies.size()])
	var verse: String = "Under an Open Crown" if forgive else "Beneath a Sealed Crown"
	if defeated:
		verse = "Beyond the Unbroken Road"
	var names: Array = []
	for id in party:
		names.append(str(catalog.get_character(str(id)).get("name", id)))
	ending_data = {
		"title": "The " + epithet + " " + deed + " " + legacy,
		"verse": verse,
		"ending_id": variant,
		"forgiven": forgive,
		"summary": str(catalog.story.get("ending_copy", {}).get(variant, "")),
		"survivors": party.duplicate(), "survivor_names": names,
		"fallen": fallen.duplicate(), "flags": flags.duplicate(true),
		"choices": action_ids, "won": bool(flags.get("final_won", false)),
		"epithet": epithet, "deed": deed, "legacy": legacy,
		"earned_title_parts": earned_parts
	}
	stage = "ending"
	_record("ending", {"variant": variant, "title": ending_data["title"]})
	return ending_data.duplicate(true)

func snapshot() -> Dictionary:
	return {
		"version": SAVE_VERSION, "act": act, "stage": stage,
		"party": party.duplicate(), "fallen": fallen.duplicate(),
		"flags": flags.duplicate(true), "history": history.duplicate(true),
		"origin": origin, "recruit_limit": recruit_limit, "selected": selected.duplicate(),
		"map_index": map_index, "map_id": current_map_id(), "story_key": story_key,
		"recruitment_origin": recruitment_origin,
		"recruitment_origins": ["Royal Capital", "Prison"] if stage == "reinforce" else ["Monster General"] if stage == "generals" else [origin],
		"story": current_story(), "battle_modifiers": battle_modifiers(),
		"surviving_originals": surviving_originals(), "ending": ending_data.duplicate(true)
	}

func restore(data: Dictionary) -> Dictionary:
	var version: int = int(data.get("version", 0))
	if version < 1 or version > SAVE_VERSION:
		return _result(false, "This campaign save version is not supported.")
	var saved_stage: String = str(data.get("stage", ""))
	var saved_origin: String = str(data.get("origin", ""))
	var saved_party = data.get("party", [])
	var saved_fallen = data.get("fallen", [])
	var saved_selected = data.get("selected", [])
	var saved_map: int = int(data.get("map_index", 0))
	if not saved_stage in VALID_STAGES or not saved_origin in VALID_ORIGINS + [""]:
		return _result(false, "The campaign save has an invalid location or stage.")
	if not saved_party is Array or not saved_fallen is Array or not saved_selected is Array:
		return _result(false, "The campaign save has an invalid roster.")
	if saved_party.size() > MAX_PARTY or saved_party.size() + saved_selected.size() > MAX_PARTY or saved_map < 0 or saved_map >= MAP_IDS.size():
		return _result(false, "The campaign save exceeds its roster or map limits.")
	var seen: Dictionary = {}
	for id in saved_party + saved_fallen:
		if not id is String or catalog.get_character(id).is_empty() or seen.has(id):
			return _result(false, "The campaign save contains a duplicate or unknown character.")
		seen[id] = true
	var selected_seen: Dictionary = {}
	for id in saved_selected:
		if not id is String or catalog.get_character(id).is_empty() or id in saved_party or id in saved_fallen or selected_seen.has(id):
			return _result(false, "The campaign save contains an invalid recruitment selection.")
		var candidate_origin: String = str(catalog.get_character(id).get("origin", ""))
		if (saved_stage == "recruit" and candidate_origin != saved_origin) or (saved_stage == "generals" and candidate_origin != "Monster General") or (saved_stage == "reinforce" and not candidate_origin in ["Royal Capital", "Prison"]):
			return _result(false, "A saved recruit does not belong to the open recruitment offer.")
		selected_seen[id] = true
	if not data.get("flags", {}) is Dictionary or not data.get("history", []) is Array:
		return _result(false, "The campaign save contains invalid story history.")
	var saved_flags: Dictionary = data.get("flags", {})
	for counter in ["wins", "losses", "mercy", "crowns_bonus", "gate_bonus", "rallies"]:
		var number = saved_flags.get(counter, 0)
		if not typeof(number) in [TYPE_INT, TYPE_FLOAT] or float(number) < 0 or float(number) > 100000:
			return _result(false, "The campaign save contains an invalid story resource.")
	var enemy_scale = saved_flags.get("enemy_hp_multiplier", 1.0)
	if not typeof(enemy_scale) in [TYPE_INT, TYPE_FLOAT] or float(enemy_scale) < 0.1 or float(enemy_scale) > 3:
		return _result(false, "The campaign save contains an invalid difficulty modifier.")
	var original_ids = saved_flags.get("initial_ids", [])
	if not original_ids is Array or original_ids.size() > 2:
		return _result(false, "The campaign save contains an invalid first watch.")
	for id in original_ids:
		if not id is String or catalog.get_character(id).is_empty():
			return _result(false, "The campaign save contains an unknown first-watch ally.")
	var saved_story: String = str(data.get("story_key", "act1_gate"))
	if not catalog.story.get("stories", {}).has(saved_story):
		return _result(false, "The campaign save contains an unknown story scene.")
	var saved_history: Array = data.get("history", [])
	if saved_history.size() > 1024:
		return _result(false, "The campaign save contains too much story history.")
	for event in saved_history:
		if not event is Dictionary or not event.get("kind", "") is String:
			return _result(false, "The campaign save contains an invalid history entry.")
	var saved_limit: int = int(data.get("recruit_limit", 2))
	if saved_limit < 0 or saved_limit > 5 or saved_selected.size() > saved_limit:
		return _result(false, "The campaign save has an invalid recruitment limit.")
	act = clampi(int(data.get("act", 1)), 1, 5)
	stage = saved_stage
	origin = saved_origin
	party = saved_party.duplicate()
	fallen = saved_fallen.duplicate()
	selected = saved_selected.duplicate()
	flags = data.get("flags", {}).duplicate(true)
	history = data.get("history", []).duplicate(true)
	map_index = saved_map
	story_key = str(data.get("story_key", "act1_gate"))
	recruitment_origin = str(data.get("recruitment_origin", "Royal Capital"))
	recruit_limit = saved_limit
	ending_data = data.get("ending", {}).duplicate(true) if data.get("ending", {}) is Dictionary else {}
	return _result(true, "Campaign restored.")
