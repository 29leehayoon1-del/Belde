extends Control

const Catalog = preload("res://scripts/catalog.gd")
const Campaign = preload("res://scripts/campaign.gd")
const Simulation = preload("res://scripts/simulation.gd")
const Art = preload("res://scripts/art.gd")
const BattleView = preload("res://scripts/battle_view.gd")
const Audio = preload("res://scripts/audio.gd")
const Bridge = preload("res://scripts/local_bridge.gd")
const SAVE_PATH = "user://campaign_v2.json"
const INK = Color("111d2a")
const PANEL = Color("1c2c39")
const PAPER = Color("e8dabb")
const GOLD = Color("d6aa6b")
const MUTED = Color("9daeb5")

var catalog
var campaign
var sim
var art
var audio
var bridge
var global_session
var canvas: Control
var screen: Control
var board
var toast_label: Label
var toast_time: float = 0
var paused: bool = false
var screen_name: String = "title"
var tool: String = "select"
var drag_tool: String = ""
var selected_uid: String = ""
var selected_tower: String = ""
var track_draft: Array = []
var pending_edits: Array = []
var floating_texts: Array = []
var settings: Dictionary = {"sound": true, "music": true, "volume": 0.32, "speed": 1.0, "reduced_effects": false, "routes": true}
var ui: Dictionary = {}
var selected_candidate: String = ""
var recruit_filter: String = "All"
var recruit_scroll: int = 0
var battle_preparation: Dictionary = {}
var result_open: bool = false
var stats_clock: float = 0
var run_seconds: float = 0
var notice_modal: Control
var single_instance: bool = true
var run_started: bool = false
var title_gallery: int = 0
var paused_before_modal: bool = false

func _ready() -> void:
	Engine.max_fps = 60
	catalog = Catalog.new()
	campaign = Campaign.new(catalog)
	sim = Simulation.new(catalog)
	art = Art.new()
	audio = Audio.new()
	add_child(audio)
	canvas = Control.new()
	add_child(canvas)
	canvas.size = Vector2(1440, 900)
	resized.connect(_fit_canvas)
	_fit_canvas()
	_build_theme()
	bridge = Bridge.new()
	add_child(bridge)
	var port = _bridge_port()
	var result = bridge.configure(_remote_state, _remote_command, port)
	single_instance = result == OK
	if FileAccess.file_exists("res://scripts/global_session.gd"):
		var global_script = load("res://scripts/global_session.gd")
		if global_script != null:
			global_session = global_script.new()
			add_child(global_session)
			global_session.configure_from_environment()
			global_session.status_changed.connect(_global_status)
			global_session.start()
	if single_instance:
		_show_title()
	else:
		_show_instance_warning()
	get_tree().auto_accept_quit = false
	var args = OS.get_cmdline_user_args()
	call_deferred("_report_ready")
	if "--battle-preview" in args and single_instance:
		campaign.new_run("Bar")
		campaign.recruit("BAR01")
		campaign.recruit("BAR03")
		campaign.confirm_recruits()
		while campaign.stage == "story":
			campaign.choose_story("continue")
		_begin_battle()

func _report_ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	print("BELDE_READY stage=" + screen_name)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if run_started and not _save_game():
			return
		if bridge != null:
			bridge.shutdown()
		if global_session != null:
			global_session.shutdown()
		get_tree().quit()

func _fit_canvas() -> void:
	if canvas == null:
		return
	var factor = minf(size.x / 1440.0, size.y / 900.0)
	canvas.scale = Vector2(factor, factor)
	canvas.position = (size - Vector2(1440, 900) * factor) * 0.5

func _build_theme() -> void:
	var t = Theme.new()
	t.default_font = art.body_font
	t.default_font_size = 17
	t.set_color("font_color", "Label", PAPER)
	t.set_color("font_color", "Button", PAPER)
	t.set_color("font_hover_color", "Button", Color("fff0cd"))
	t.set_color("font_disabled_color", "Button", Color("64757e"))
	t.set_stylebox("normal", "Button", _style(Color("253744"), Color("526069"), 5))
	t.set_stylebox("hover", "Button", _style(Color("344b56"), GOLD, 5))
	t.set_stylebox("pressed", "Button", _style(Color("415d62"), Color("9ec5b5"), 5))
	t.set_stylebox("disabled", "Button", _style(Color("1a2934"), Color("35444e"), 5))
	t.set_stylebox("focus", "Button", _style(Color(0, 0, 0, 0), Color("e5c893"), 5, 2))
	t.set_stylebox("panel", "PanelContainer", _style(PANEL, Color("5a5a51"), 7))
	t.set_stylebox("panel", "TooltipPanel", _style(Color("142330"), GOLD, 4))
	t.set_font_size("font_size", "TooltipLabel", 15)
	t.set_color("font_color", "TooltipLabel", PAPER)
	canvas.theme = t

func _style(bg: Color, border: Color, radius: int = 4, width: int = 1) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 13
	s.content_margin_right = 13
	s.content_margin_top = 9
	s.content_margin_bottom = 9
	return s

func _clear_screen(name: String) -> void:
	screen_name = name
	if screen != null:
		screen.queue_free()
	screen = Control.new()
	screen.size = Vector2(1440, 900)
	canvas.add_child(screen)
	ui.clear()
	board = null
	notice_modal = null
	var bg = ColorRect.new()
	bg.color = INK
	bg.size = screen.size
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(bg)
	toast_label = _label(screen, "", Rect2(352, 854, 1024, 32), 15, Color("f1ce94"))
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.z_index = 80

func _label(parent: Node, text: String, rect: Rect2, font_size: int = 18, color: Color = PAPER, display: bool = false) -> Label:
	var l = Label.new()
	l.text = text
	l.position = rect.position
	l.size = rect.size
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_override("font", art.display_font if display else art.body_font)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l

func _paragraph(parent: Node, text: String, rect: Rect2, font_size: int = 17, color: Color = MUTED) -> Label:
	var l = _label(parent, text, rect, font_size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	return l

func _button(parent: Node, text: String, rect: Rect2, action: Callable, accent: bool = false) -> Button:
	var b = Button.new()
	b.text = text
	b.position = rect.position
	b.size = rect.size
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.pressed.connect(func(): audio.play_cue("click"); action.call())
	if accent:
		b.add_theme_stylebox_override("normal", _style(Color("806445"), Color("d4b57b"), 5))
		b.add_theme_stylebox_override("hover", _style(Color("a27e51"), Color("ffe2a3"), 5))
	parent.add_child(b)
	return b

func _panel(parent: Node, rect: Rect2, color: Color = PANEL, border: Color = Color("4f5b5e")) -> Panel:
	var p = Panel.new()
	p.position = rect.position
	p.size = rect.size
	p.add_theme_stylebox_override("panel", _style(color, border, 6))
	parent.add_child(p)
	return p

func _image(parent: Node, texture: Texture2D, rect: Rect2) -> TextureRect:
	var r = TextureRect.new()
	r.texture = texture
	r.position = rect.position
	r.size = rect.size
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	parent.add_child(r)
	return r

func _heading(title: String, subtitle: String, back: Callable = Callable()) -> void:
	_label(screen, "BELDE", Rect2(32, 20, 220, 44), 34, GOLD, true)
	_label(screen, title, Rect2(352, 24, 970, 38), 28, PAPER, true)
	_label(screen, subtitle, Rect2(352, 66, 1040, 30), 15, MUTED)
	if back.is_valid():
		_button(screen, "Back", Rect2(32, 80, 106, 34), back)
	_button(screen, "Settings", Rect2(1300, 25, 108, 36), _show_settings)

func _show_title() -> void:
	paused = true
	_clear_screen("title")
	var title_art = art.texture("res://assets/ui/title.png")
	if title_art != null:
		_image(screen, title_art, Rect2(0, 0, 1440, 900))
		var shade = ColorRect.new()
		shade.size = Vector2(760, 900)
		shade.color = Color(0.035, 0.065, 0.1, 0.91)
		shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		screen.add_child(shade)
	else:
		_image(screen, art.location("Kingdom"), Rect2(640, 0, 800, 900))
		var shade = ColorRect.new()
		shade.position = Vector2(640, 0)
		shade.size = Vector2(800, 900)
		shade.color = Color(0.04, 0.07, 0.1, 0.45)
		shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		screen.add_child(shade)
	_label(screen, "A KINGDOM WORTH SAVING", Rect2(76, 125, 650, 28), 14, Color("9eb6b2"))
	_label(screen, "BELDE", Rect2(66, 166, 730, 130), 112, GOLD, true)
	_label(screen, "The Wrong Commander", Rect2(78, 305, 700, 50), 32, PAPER, true)
	_paragraph(screen, "The order bears your name.\nThe crown has the wrong commander.\nThe people at the gate still need you.", Rect2(79, 386, 550, 124), 20, Color("b7c5c3"))
	var resume = _button(screen, "Continue your chronicle", Rect2(78, 543, 430, 57), _load_game, true)
	resume.disabled = not FileAccess.file_exists(SAVE_PATH)
	_button(screen, "Begin a new story", Rect2(78, 615, 430, 56), _show_origins)
	_button(screen, "Meet the 58 companions", Rect2(78, 686, 430, 48), _show_codex)
	_button(screen, "Settings & connected editor", Rect2(78, 749, 430, 45), _show_settings)
	_label(screen, "A five-act campaign · six battlefields · every ally matters", Rect2(78, 838, 1000, 30), 14, MUTED)

func _show_origins() -> void:
	paused = true
	_clear_screen("origins")
	_heading("Where will you look for allies?", "Choose a place. Recruit two people. Your first companions will remember why you came.", _show_title)
	var origins = [
		["Bar", "The Bent Lantern", "6 candidates · fierce and unconventional", "Caravan guards, old brawlers and people with nowhere else to go. Their loyalty is earned over an honest table."],
		["Kingdom", "The Crownward Yard", "15 candidates · disciplined and well equipped", "Royal knights and practiced retainers. They know the crown's orders. Not all of them agree with those orders."],
		["Village", "Reedwake Common", "10 candidates · resourceful and resilient", "Mended coats, borrowed tools, steady hands. The village has less silver and more reasons to defend the road."]
	]
	for i in range(3):
		var entry = origins[i]
		var x = 32 + i * 466
		var p = _panel(screen, Rect2(x, 150, 444, 640))
		_image(p, art.location(entry[0]), Rect2(12, 12, 420, 260))
		_label(p, entry[1], Rect2(24, 295, 400, 48), 27, GOLD, true)
		_label(p, entry[2], Rect2(24, 348, 400, 30), 15, BeldeArt.class_color("Healer"))
		_paragraph(p, entry[3], Rect2(24, 402, 394, 110), 18, PAPER)
		var origin = str(entry[0])
		_button(p, "Visit " + str(entry[1]), Rect2(24, 546, 396, 60), func():
			campaign.new_run(origin)
			run_started = true
			run_seconds = 0
			selected_candidate = ""
			recruit_filter = "All"
			recruit_scroll = 0
			_refresh_stage(), true)
	_label(screen, "All origins share fair combat budgets. People differ in tools, tactics and convictions.", Rect2(40, 820, 1360, 30), 15, MUTED)

func _refresh_stage() -> void:
	if campaign.stage == "reinforce" and screen_name != "recruitment":
		recruit_filter = str(campaign.recruitment_origin)
	match campaign.stage:
		"recruit", "generals", "reinforce": _show_recruitment()
		"story": _show_story()
		"battle": _begin_battle()
		"ending": _show_ending()
		_: _show_origins()

func _show_recruitment() -> void:
	paused = true
	_clear_screen("recruitment")
	var title = "Choose your first two companions"
	var subtitle = "Read their stories and abilities. Select a card to invite or remove a recruit."
	if campaign.stage == "generals":
		title = "Two generals offer a different road"
		subtitle = "The monsters have lowered their weapons. Choose two of the five leaders to join your cause."
	elif campaign.stage == "reinforce":
		title = "The capital and the quiet cells"
		subtitle = "Choose %d reinforcements. Your losses change how much help the city offers." % campaign.recruit_limit
	_heading(title, subtitle)
	var counter = _label(screen, "", Rect2(32, 115, 900, 35), 20, GOLD)
	ui["recruit_counter"] = counter
	var candidates = campaign.available_candidates()
	if campaign.stage == "reinforce":
		for i in range(3):
			var filter = ["All", "Royal Capital", "Prison"][i]
			_button(screen, filter, Rect2(32 + i * 190, 156, 178, 35), func():
				recruit_filter = filter
				recruit_scroll = 0
				_show_recruitment(), filter == recruit_filter)
	var list_y = 207 if campaign.stage == "reinforce" else 165
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(32, list_y)
	scroll.size = Vector2(860, 758 - list_y)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	screen.add_child(scroll)
	var grid = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(grid)
	ui["recruit_cards"] = {}
	for c_value in candidates:
		var c = catalog.get_character(str(c_value)) if c_value is String else c_value
		if not c is Dictionary or c.is_empty():
			continue
		if recruit_filter != "All" and campaign.stage == "reinforce" and str(c.get("origin", "")) != recruit_filter:
			continue
		var id = str(c["id"])
		var b = Button.new()
		b.custom_minimum_size = Vector2(198, 214)
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		grid.add_child(b)
		_image(b, art.portrait(id), Rect2(18, 14, 78, 78))
		_label(b, str(c.get("class", "")), Rect2(105, 18, 85, 27), 14, BeldeArt.class_color(str(c.get("class", ""))))
		_label(b, "Age %s" % c.get("age", ""), Rect2(105, 51, 85, 25), 13, MUTED)
		var label = _label(b, str(c.get("name", id)), Rect2(14, 105, 172, 48), 16, PAPER, true)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var stats = c.get("stats", {})
		_label(b, "HP %s  ·  ATK %s" % [stats.get("hp", 0), stats.get("basic_attack", {}).get("damage", 0)], Rect2(14, 163, 178, 24), 13, MUTED)
		_label(b, "INVITED" if id in campaign.selected else "Read & invite", Rect2(14, 187, 178, 20), 12, GOLD)
		b.tooltip_text = str(c.get("intro", ""))
		b.pressed.connect(func():
			selected_candidate = id
			var result = campaign.recruit(id)
			if not result.get("ok", false): toast(str(result.get("message", "Your party is full.")))
			_update_recruitment()
			audio.play_cue("click"))
		ui["recruit_cards"][id] = b
	scroll.scroll_vertical = recruit_scroll
	scroll.scroll_ended.connect(func(): recruit_scroll = scroll.scroll_vertical)
	ui["candidate_detail"] = _panel(screen, Rect2(918, 125, 490, 637))
	ui["recruit_confirm"] = _button(screen, "Set out together", Rect2(918, 785, 490, 64), func():
		var result = campaign.confirm_recruits()
		if result.get("ok", false):
			_save_game()
			_refresh_stage()
		else: toast(str(result.get("message", "Choose your companions first."))), true)
	if campaign.stage == "generals":
		_button(screen, "Decline the alliance and continue", Rect2(32, 766, 860, 38), func():
			var result = campaign.choose_story("refuse_generals")
			if result.get("ok", false):
				_save_game()
				selected_candidate = ""
				_refresh_stage())
	_label(screen, "Each companion has two active abilities. Healers favor wounded defenders and damage dealers.", Rect2(32, 817 if campaign.stage == "generals" else 797, 840, 56), 14, MUTED).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if selected_candidate.is_empty() and not candidates.is_empty():
		selected_candidate = str(candidates[0].get("id", "")) if candidates[0] is Dictionary else str(candidates[0])
	_update_recruitment()

func _update_recruitment() -> void:
	ui["recruit_counter"].text = "%d / %d invited   ·   %d companions already at your side" % [campaign.selected.size(), campaign.recruit_limit, campaign.party.size()]
	ui["recruit_confirm"].disabled = campaign.selected.size() != campaign.recruit_limit
	for id in ui["recruit_cards"]:
		var b: Button = ui["recruit_cards"][id]
		b.add_theme_stylebox_override("normal", _style(Color("354d51") if id in campaign.selected else PANEL, GOLD if id in campaign.selected else Color("4f5d66"), 5, 2 if id in campaign.selected else 1))
	var p = ui["candidate_detail"]
	for child in p.get_children():
		child.queue_free()
	var c = catalog.get_character(selected_candidate)
	if c.is_empty(): return
	_image(p, art.portrait(selected_candidate), Rect2(22, 24, 116, 116))
	var name = _label(p, str(c["name"]), Rect2(158, 22, 305, 70), 26, GOLD, true)
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label(p, "%s · Age %s" % [c["class"], c["age"]], Rect2(158, 101, 310, 30), 16, BeldeArt.class_color(str(c["class"])))
	_paragraph(p, "“%s”" % c.get("intro", c.get("recruitment_intro", "")), Rect2(24, 166, 441, 76), 17, PAPER)
	var s = c.get("stats", {})
	var a = s.get("basic_attack", {})
	_label(p, "HP %s   ·   Basic %s / %ss   ·   Range %s" % [s.get("hp", 0), a.get("damage", 0), a.get("interval_seconds", 1), a.get("range_tiles", 1)], Rect2(24, 258, 445, 34), 15, MUTED)
	for slot in range(2):
		var ability = catalog.get_ability(selected_candidate, slot)
		var y = 311 + slot * 121
		var card = _panel(p, Rect2(20, y, 450, 108), Color("223541"), Color("526568"))
		_label(card, str(ability.get("name", "Ability")), Rect2(15, 8, 340, 30), 18, GOLD)
		_label(card, "%ss" % ability.get("cooldown", ability.get("cooldown_seconds", 15)), Rect2(367, 9, 65, 28), 16, Color("99c5b2"))
		_paragraph(card, str(ability.get("short_description", ability.get("description", ability.get("effect_target", "")))), Rect2(15, 43, 417, 55), 14, PAPER)
	_paragraph(p, str(c.get("story_hook", c.get("story", ""))), Rect2(24, 567, 440, 56), 13, MUTED)

func _show_story() -> void:
	paused = true
	_clear_screen("story")
	var story = campaign.current_story()
	_heading(str(story.get("title", "A road between battles")), str(story.get("subtitle", "Every command leaves a mark.")))
	var map_id = campaign.current_map_id()
	var index = maxi(0, int(map_id.trim_prefix("MAP")) - 1)
	var bg = art.battlefield(index)
	if bg == null:
		bg = art.location("Kingdom" if campaign.act > 2 else campaign.origin)
	_image(screen, bg, Rect2(32, 129, 1376, 660))
	var shade = _panel(screen, Rect2(58, 157, 940, 604), Color(0.06, 0.1, 0.14, 0.95), Color("8e7858"))
	_label(shade, "ACT %s  ·  YOUR CHRONICLE" % campaign.act, Rect2(30, 22, 850, 30), 13, GOLD)
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(28, 70)
	scroll.size = Vector2(877, 310)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	shade.add_child(scroll)
	var lines = VBoxContainer.new()
	lines.custom_minimum_size.x = 853
	lines.add_theme_constant_override("separation", 18)
	scroll.add_child(lines)
	var dialogue: Array = story.get("dialogue", [])
	if dialogue.is_empty():
		for line in story.get("lines", []): dialogue.append({"speaker": "", "text": line})
	for line in dialogue:
		var speaker = str(line.get("speaker", ""))
		var label = Label.new()
		label.custom_minimum_size = Vector2(850, 0)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.text = (speaker + ":  " if not speaker.is_empty() else "") + str(line.get("text", ""))
		label.add_theme_font_size_override("font_size", 20)
		label.add_theme_color_override("font_color", PAPER)
		lines.add_child(label)
	var choices: Array = story.get("choices", [])
	if choices.is_empty(): choices = [{"id": "continue", "label": "Continue", "detail": ""}]
	var y = 408
	for choice in choices:
		var choice_id = str(choice.get("id", "continue"))
		var b = _button(shade, str(choice.get("label", "Continue")), Rect2(28, y, 880, 51), func():
			var result = campaign.choose_story(choice_id)
			if result.get("ok", false):
				_save_game()
				_refresh_stage()
			else: toast(str(result.get("message", "Choose a road."))), true)
		b.tooltip_text = str(choice.get("detail", ""))
		y += 62
	var portrait_x = 1030
	var count = mini(3, campaign.party.size())
	for i in range(count):
		var id = str(campaign.party[i])
		_image(screen, art.portrait(id), Rect2(portrait_x, 180 + i * 185, 128, 128))
		var c = catalog.get_character(id)
		_label(screen, str(c.get("name", id)), Rect2(portrait_x, 309 + i * 185, 320, 34), 15, PAPER)
	_label(screen, "Your choices remain in the chronicle. No decision timer runs during dialogue.", Rect2(58, 813, 1320, 32), 15, MUTED)

func _begin_battle(restored: bool = false) -> void:
	if not restored:
		battle_preparation = campaign.snapshot()
		var map_data = catalog.get_map(campaign.current_map_id())
		var modifiers = campaign.battle_modifiers()
		sim.setup(map_data, campaign.party, 1.0, float(modifiers.get("enemy_hp_multiplier", 1.0)))
		sim.coins += int(modifiers.get("crowns_bonus", 0)) + int(modifiers.get("empty_party_supply", 0))
		sim.gate_max_hp = 100.0 + clampf(float(modifiers.get("gate_bonus", 0)), 0, 100)
		sim.gate_hp = sim.gate_max_hp
		pending_edits.clear()
		selected_uid = str(sim.units[0].get("uid", "")) if not sim.units.is_empty() else ""
		selected_tower = ""
		floating_texts.clear()
	paused = false
	result_open = false
	tool = "select"
	drag_tool = ""
	track_draft.clear()
	run_started = true
	_clear_screen("battle")
	var map_name = str(sim.map.get("name", "The gate"))
	_heading(map_name, "ACT %s  ·  %s   /   Guard the gate. Preserve the people." % [campaign.act, campaign.origin])
	_button(screen, "Pause", Rect2(32, 79, 82, 34), _toggle_pause)
	_button(screen, "Save", Rect2(123, 79, 77, 34), _save_with_feedback)
	_button(screen, "Editor", Rect2(210, 79, 117, 34), _show_editor)
	ui["gate"] = _label(screen, "", Rect2(352, 88, 215, 30), 19, Color("a4c199"))
	ui["wave"] = _label(screen, "", Rect2(577, 88, 215, 30), 18, PAPER)
	ui["coins"] = _label(screen, "", Rect2(900, 88, 145, 30), 18, GOLD)
	ui["wave_button"] = _button(screen, "Begin wave", Rect2(1170, 80, 206, 39), _start_wave, true)
	ui["speed_button"] = _button(screen, "1×", Rect2(1065, 80, 85, 39), _cycle_speed)
	board = BattleView.new()
	board.position = Vector2(352, 132)
	board.size = Vector2(1024, 640)
	board.configure(self, sim, art, maxi(0, int(campaign.current_map_id().right(2)) - 1))
	board.show_routes = bool(settings.get("routes", true))
	screen.add_child(board)
	ui["selected_panel"] = _panel(screen, Rect2(24, 132, 304, 287))
	_build_tools()
	_build_party_strip()
	_update_selection_panel()
	_update_battle_hud()
	_label(screen, "SPACE  call wave / pause     1 · 2  abilities     G  grid     R  routes     F5  save     ESC  pause", Rect2(352, 882, 1024, 18), 11, MUTED)
	if not restored:
		_save_game()
		toast("Place your defenses. Drag a companion to reposition; Space begins the wave.", 7)

func _build_tools() -> void:
	var p = _panel(screen, Rect2(24, 431, 304, 258))
	_label(p, "BUILD A DEFENSE", Rect2(14, 8, 274, 27), 13, GOLD)
	for i in range(4):
		var model: Dictionary = catalog.world.get("towers", [])[i]
		var id = str(model.get("id", "TOWER04"))
		var name = str(model.get("name", "Tower"))
		var label = name + " · " + str(model.get("cost", 80))
		var b = _button(p, label, Rect2(12 + (i % 2) * 144, 43 + (i / 2) * 49, 136, 42), func(): set_tool("tower:" + id))
		b.add_theme_font_size_override("font_size", 12)
		b.tooltip_text = str(model.get("draft_effect", "")) + "\nClick or drag onto a valid tile."
		b.button_down.connect(func(): drag_tool = "tower:" + id; set_tool(drag_tool))
	for i in range(3):
		var model: Dictionary = catalog.world.get("traps", [])[i]
		var id = str(model.get("id", "TRAP01"))
		var name = ["Snare", "Cinder", "Decoy"][i]
		var b = _button(p, name + " · " + str(model.get("cost", 12)), Rect2(12 + i * 96, 148, 88, 34), func(): set_tool("trap:" + id))
		b.add_theme_font_size_override("font_size", 12)
		b.tooltip_text = str(model.get("draft_effect", ""))
		b.button_down.connect(func(): drag_tool = "trap:" + id; set_tool(drag_tool))
	_button(p, "Patrol track", Rect2(12, 194, 136, 38), func(): set_tool("track")).tooltip_text = "Draw a connected path on free tiles. Release to confirm. Right-click cancels."
	_button(p, "Select [Esc]", Rect2(156, 194, 136, 38), func(): set_tool("select"))
	var help = _panel(screen, Rect2(24, 701, 304, 128))
	ui["tool_label"] = _label(help, "COMMAND THE COMPANY", Rect2(12, 7, 282, 24), 12, GOLD)
	ui["tool_help"] = _paragraph(help, "Drag people from the bottom cards.\nPatrol follows the cyan rails.\nAdvance closes on enemies.", Rect2(12, 36, 280, 64), 12, MUTED)
	_button(screen, "Undo", Rect2(24, 842, 93, 32), func(): issue_command({"kind": "undo"})).tooltip_text = "Ctrl+Z · planning only"
	_button(screen, "Redo", Rect2(126, 842, 93, 32), func(): issue_command({"kind": "redo"})).tooltip_text = "Ctrl+Shift+Z · planning only"
	_button(screen, "Menu", Rect2(228, 842, 100, 32), _show_pause)

func _build_party_strip() -> void:
	if ui.has("party_strip") and is_instance_valid(ui["party_strip"]):
		ui["party_strip"].queue_free()
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(352, 782)
	scroll.size = Vector2(1024, 69)
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	screen.add_child(scroll)
	ui["party_strip"] = scroll
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	scroll.add_child(row)
	ui["party_buttons"] = {}
	for unit in sim.units:
		var uid = str(unit.get("uid", ""))
		var id = str(unit.get("id", ""))
		var data = catalog.get_character(id)
		var b = Button.new()
		b.custom_minimum_size = Vector2(145, 62)
		b.pressed.connect(func(): select_unit(uid))
		b.button_down.connect(func(): drag_tool = "move:" + uid)
		b.tooltip_text = str(data.get("name", id)) + " · " + str(data.get("class", "")) + "\nClick to command, or drag to move during planning."
		row.add_child(b)
		_image(b, art.portrait(id), Rect2(7, 8, 42, 42))
		var first_name = str(data.get("name", id)).split(" ")[0]
		if first_name in ["Sister", "Sir", "Dame", "Brother", "General"]:
			first_name = str(data.get("name", id)).split(" ")[1]
		_label(b, first_name, Rect2(57, 7, 84, 22), 12, PAPER)
		var health = _label(b, "", Rect2(57, 31, 84, 21), 11, BeldeArt.class_color(str(data.get("class", ""))))
		ui["party_buttons"][uid] = {"button": b, "health": health}

func select_unit(uid: String) -> void:
	selected_uid = uid
	selected_tower = ""
	tool = "select"
	if screen_name == "battle":
		_update_selection_panel()
		audio.play_cue("click")

func select_tower(uid: String) -> void:
	selected_tower = uid
	selected_uid = ""
	tool = "select"
	_update_selection_panel()

func _selected_unit() -> Dictionary:
	for unit in sim.units:
		if str(unit.get("uid", "")) == selected_uid:
			return unit
	return {}

func _update_selection_panel() -> void:
	if not ui.has("selected_panel"):
		return
	var p = ui["selected_panel"]
	for child in p.get_children(): child.queue_free()
	ui.erase("ability_0"); ui.erase("ability_1"); ui.erase("selected_hp")
	if not selected_tower.is_empty():
		for tower in sim.towers:
			if str(tower.get("uid", "")) != selected_tower: continue
			var model: Dictionary = {}
			for entry in catalog.world.get("towers", []):
				if str(entry.get("id", "")) == str(tower.get("id", "")): model = entry
			_label(p, str(model.get("name", "Defense")), Rect2(16, 16, 275, 56), 23, GOLD, true).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_label(p, "Level %d / 3" % int(tower.get("level", 1)), Rect2(16, 77, 270, 28), 17, PAPER)
			_paragraph(p, str(model.get("purpose", "")), Rect2(16, 116, 270, 51), 16, MUTED)
			var b = _button(p, "Upgrade defense [U]", Rect2(14, 188, 276, 39), func(): issue_command({"kind": "upgrade_tower", "uid": selected_tower}))
			b.disabled = int(tower.get("level", 1)) >= 3
			_button(p, "Dismantle · 50% refund", Rect2(14, 238, 276, 35), func():
				var result = issue_command({"kind": "remove_tower", "uid": selected_tower})
				if result.get("ok", false): selected_tower = ""; _update_selection_panel())
			return
	var unit = _selected_unit()
	if unit.is_empty():
		_label(p, "THE GATE NEEDS YOU", Rect2(15, 18, 275, 31), 17, GOLD)
		_paragraph(p, "Select a companion to set their role, cast an ability, or inspect their health.\n\nA Bolt Cradle can hold the road even when no ally remains.", Rect2(15, 69, 274, 164), 16, MUTED)
		return
	var id = str(unit.get("id", ""))
	var data = catalog.get_character(id)
	_image(p, art.portrait(id), Rect2(14, 14, 65, 65))
	_label(p, str(data.get("name", id)), Rect2(93, 12, 198, 53), 18, PAPER, true).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label(p, str(data.get("class", "")), Rect2(93, 63, 198, 25), 13, BeldeArt.class_color(str(data.get("class", ""))))
	ui["selected_hp"] = _label(p, "", Rect2(14, 94, 275, 26), 14, MUTED)
	for i in range(3):
		var mode = ["Guard", "Patrol", "Advance"][i]
		var b = _button(p, mode, Rect2(12 + i * 96, 130, 88, 32), func(): issue_command({"kind": "set_mode", "uid": selected_uid, "mode": mode}); _update_selection_panel(), str(unit.get("mode", "")) == mode)
		b.add_theme_font_size_override("font_size", 12)
	for slot in range(2):
		var ability = catalog.get_ability(id, slot)
		var b = _button(p, str(ability.get("name", "Ability")), Rect2(12, 178 + slot * 49, 280, 41), func(): issue_command({"kind": "cast", "uid": selected_uid, "slot": slot}))
		b.add_theme_font_size_override("font_size", 13)
		b.tooltip_text = str(ability.get("description", "")) + "\nCooldown: %ss" % ability.get("cooldown_seconds", 15)
		ui["ability_" + str(slot)] = b

func _update_battle_hud() -> void:
	if screen_name != "battle" or not ui.has("gate"):
		return
	ui["gate"].text = "GATE  %d / %d" % [maxi(0, int(sim.gate_hp)), int(sim.gate_max_hp)]
	ui["wave"].text = "WAVE  %d / %d" % [sim.wave, sim.max_waves]
	ui["coins"].text = "%d crowns" % sim.coins
	ui["speed_button"].text = str(int(settings.get("speed", 1.0))) + "×"
	ui["wave_button"].text = "Begin wave %d  [Space]" % (sim.wave + 1) if sim.phase == "planning" else ("Paused" if paused else "Wave in progress")
	ui["wave_button"].disabled = sim.phase != "planning" or not _session_ready()
	var unit = _selected_unit()
	if not unit.is_empty() and ui.has("selected_hp"):
		ui["selected_hp"].text = "HP %d / %d   ·   %s" % [maxi(0, int(unit.get("hp", 0))), int(unit.get("max_hp", 0)), str(unit.get("mode", "Guard"))]
		for slot in range(2):
			var key = "ability_" + str(slot)
			if not ui.has(key): continue
			var ability = catalog.get_ability(str(unit.get("id", "")), slot)
			var cooldowns: Array = unit.get("cooldowns", [0.0, 0.0])
			var cooldown = float(cooldowns[slot])
			ui[key].text = "%d  %s%s" % [slot + 1, str(ability.get("name", "")), " · %ds" % ceili(cooldown) if cooldown > 0 else ""]
			ui[key].disabled = cooldown > 0 or sim.phase != "combat" or float(unit.get("hp", 0)) <= 0 or paused
	for u in sim.units:
		var uid = str(u.get("uid", ""))
		if not ui.get("party_buttons", {}).has(uid): continue
		var item = ui["party_buttons"][uid]
		item["health"].text = "DOWNED" if float(u.get("hp", 0)) <= 0 else "%d / %d" % [int(u.get("hp", 0)), int(u.get("max_hp", 0))]
		item["button"].add_theme_stylebox_override("normal", _style(Color("344e50") if uid == selected_uid else PANEL, GOLD if uid == selected_uid else Color("4f5b64"), 4))

func set_tool(value: String) -> void:
	tool = value
	if ui.has("tool_label"):
		ui["tool_label"].text = "DRAW A PATROL TRACK" if value == "track" else "PLACE A DEFENSE" if value.begins_with("tower:") else "PLACE A TRAP" if value.begins_with("trap:") else "COMMAND THE COMPANY"
	if ui.has("tool_help"):
		ui["tool_help"].text = "Click and drag a connected path.\nKeep clear of the enemy lanes.\nRight-click cancels." if value == "track" else "Click a tile, or drag from the palette.\nTeal is clear; hatching is blocked.\nCombat edits wait for the next pause." if value != "select" else "Drag people from the bottom cards.\nPatrol follows the cyan rails.\nAdvance closes on enemies."

func command_for_tool(value: String, cell: Vector2i) -> Dictionary:
	var point = [cell.x, cell.y]
	if value.begins_with("tower:"): return {"kind": "place_tower", "tower_id": value.trim_prefix("tower:"), "cell": point}
	if value.begins_with("trap:"): return {"kind": "place_trap", "trap_id": value.trim_prefix("trap:"), "cell": point}
	if value.begins_with("move:"):
		for tower in sim.towers:
			var tower_pos = tower.get("pos", Vector2.ZERO)
			if tower_pos is Vector2 and tower_pos.distance_to(Vector2(cell)) < 0.7 and tower.get("id", "") == "TOWER01":
				return {"kind": "assign_tower", "uid": value.trim_prefix("move:"), "tower_uid": str(tower.get("uid", ""))}
		return {"kind": "move_unit", "uid": value.trim_prefix("move:"), "cell": point}
	return {}

func preview_command(command: Dictionary) -> Dictionary:
	if command.is_empty(): return {"ok": false}
	if sim.has_method("preview_command"):
		return sim.preview_command(command)
	var cell = command.get("cell", [-1, -1])
	return {"ok": int(cell[0]) >= 0 and int(cell[0]) < 32 and int(cell[1]) >= 0 and int(cell[1]) < 20}

func apply_tool(value: String, cell: Vector2i) -> void:
	var command = command_for_tool(value, cell)
	if not command.is_empty(): issue_command(command)

func append_track_cell(cell: Vector2i) -> void:
	if cell.x < 0 or cell.x > 31 or cell.y < 0 or cell.y > 19: return
	if track_draft.is_empty(): track_draft.append([cell.x, cell.y]); return
	var previous = Vector2i(int(track_draft[-1][0]), int(track_draft[-1][1]))
	while previous != cell and track_draft.size() < 64:
		var dx = cell.x - previous.x
		var dy = cell.y - previous.y
		if absi(dx) >= absi(dy) and dx != 0: previous.x += 1 if dx > 0 else -1
		elif dy != 0: previous.y += 1 if dy > 0 else -1
		track_draft.append([previous.x, previous.y])

func commit_track() -> void:
	if track_draft.size() > 1:
		issue_command({"kind": "set_track", "track_id": "commander-patrol", "points": track_draft.duplicate(true)})
	track_draft.clear()

func issue_command(command: Dictionary) -> Dictionary:
	var result = _remote_command(command)
	if result.get("ok", false):
		audio.play_cue("ability" if str(command.get("kind", "")) == "cast" else "click")
	else: audio.play_cue("error")
	toast(str(result.get("message", "Command received.")), 3.5)
	if screen_name == "battle": _update_battle_hud()
	return result

func _remote_command(command: Dictionary) -> Dictionary:
	if not _session_ready():
		return {"ok": false, "message": "Reconnect your profile session before commanding the game.", "revision": sim.revision}
	if campaign.stage != "battle" or sim.map.is_empty():
		return {"ok": false, "message": "Enter a battlefield before editing.", "revision": sim.revision}
	var expected = int(command.get("expected_revision", sim.revision))
	if expected != sim.revision:
		return {"ok": false, "conflict": true, "message": "The map changed. Refresh the editor and try again.", "revision": sim.revision}
	var kind = str(command.get("kind", ""))
	if kind == "cast" and paused:
		return {"ok": false, "message": "Resume the battle before casting.", "revision": sim.revision}
	if kind == "start_wave": return _launch_wave()
	var layouts = ["place_unit", "move_unit", "place_tower", "upgrade_tower", "remove_tower", "place_trap", "remove_trap", "set_track", "assign_tower", "undo", "redo"]
	if sim.phase == "combat" and kind in layouts:
		if pending_edits.size() >= 32: return {"ok": false, "message": "The command queue is full.", "revision": sim.revision}
		pending_edits.append(command.duplicate(true))
		return {"ok": true, "status": "queued", "message": "Edit queued for the next planning phase.", "revision": sim.revision}
	var result = sim.command(command)
	if result.get("ok", false) and kind in layouts:
		_save_game()
	if result.get("ok", false) and screen_name == "battle":
		_update_selection_panel()
		_update_battle_hud()
	return result

func _apply_pending() -> void:
	var queued = pending_edits.duplicate(true)
	pending_edits.clear()
	var rejected = 0
	for command in queued:
		command.erase("expected_revision")
		var result = sim.command(command)
		if not result.get("ok", false): rejected += 1
	if not queued.is_empty():
		toast("Queued edits applied." if rejected == 0 else "%d queued edits could not be placed. Refresh the editor." % rejected, 5)

func _remote_state() -> Dictionary:
	var people: Array = []
	for c in catalog.characters:
		people.append({"id": c.get("id", ""), "name": c.get("name", ""), "class": c.get("class", ""), "origin": c.get("origin", ""), "stats": c.get("stats", {}), "tower_eligible": c.get("tower_eligible", false)})
	return {"game": "Belde", "version": "0.1.0", "revision": sim.revision, "campaign": campaign.snapshot(), "simulation": sim.snapshot(), "characters": people, "pending_edits": pending_edits.duplicate(true), "paused": paused, "towers": catalog.world.get("towers", []), "traps": catalog.world.get("traps", [])}

func _start_wave() -> void:
	if not _session_ready(): toast("Reconnect your profile session before starting."); return
	if sim.phase == "combat": _toggle_pause(); return
	var result = _launch_wave()
	toast(str(result.get("message", "Prepare your defense first.")))

func _launch_wave() -> Dictionary:
	if sim.phase != "planning":
		return {"ok": false, "message": "A wave can begin only during planning.", "revision": sim.revision}
	_apply_pending()
	var result = sim.start_wave()
	if result.get("ok", false):
		paused = false
		audio.play_cue("wave")
	_update_battle_hud()
	return result

func _cycle_speed() -> void:
	var speed = float(settings.get("speed", 1.0))
	settings["speed"] = 2.0 if speed == 1.0 else 3.0 if speed == 2.0 else 1.0
	sim.speed = settings["speed"]
	_update_battle_hud()

func _toggle_pause() -> void:
	paused = not paused
	_update_battle_hud()
	toast("Paused. You can review the company." if paused else "The watch resumes.", 2)

func _process(delta: float) -> void:
	if toast_time > 0:
		toast_time -= delta
		if toast_time <= 0 and is_instance_valid(toast_label): toast_label.text = ""
	for f in floating_texts: f["ttl"] = float(f.get("ttl", 1)) - delta
	floating_texts = floating_texts.filter(func(f): return float(f.get("ttl", 0)) > 0)
	if screen_name != "battle" or sim == null: return
	if not paused and not result_open and _session_ready():
		sim.speed = float(settings.get("speed", 1.0))
		sim.step(delta)
		run_seconds += delta
	while not sim.events.is_empty():
		var event: Dictionary = sim.events.pop_front()
		_handle_event(event)
	stats_clock -= delta
	if stats_clock <= 0:
		stats_clock = 0.12
		_update_battle_hud()
	if not result_open and sim.phase in ["victory", "defeat"]:
		result_open = true
		paused = true
		_show_battle_result()

func _handle_event(event: Dictionary) -> void:
	var kind = str(event.get("type", event.get("kind", "")))
	if kind == "wave_complete":
		_apply_pending()
		_save_game()
		toast("Wave held. Reinforce the line before the next assault.", 6)
	elif kind in ["damage", "heal"] and floating_texts.size() < 36:
		var pos = event.get("pos", Vector2.ZERO)
		var uid = str(event.get("uid", event.get("target_uid", "")))
		for entity in sim.units + sim.enemies:
			if str(entity.get("uid", "")) == uid: pos = entity.get("pos", pos); break
		var amount = int(event.get("amount", 0))
		if amount > 0:
			floating_texts.append({"pos": pos, "text": ("+" if kind == "heal" else "−") + str(amount), "ttl": 0.9, "color": "b0d0a8" if kind == "heal" else "e6c49b"})
	elif kind == "ally_downed":
		toast("A companion has fallen. Hold the road, and remember them.", 5)
	elif kind == "surrender":
		toast("A white flag. These monsters have stopped fighting.", 5)

func _show_battle_result() -> void:
	var won = sim.phase == "victory"
	audio.play_cue("victory" if won else "defeat")
	var modal = _modal_panel(Rect2(402, 225, 700, 425))
	_label(modal, "THE GATE HOLDS" if won else "THE WATCH RETREATS", Rect2(28, 28, 645, 60), 35, GOLD, true)
	var alive: Array = sim.survivors()
	var body = "%d companions stand with you. %d enemies defeated. %d white flags honored.\n\n" % [alive.size(), int(sim.kills), int(sim.surrendered)]
	body += "The next road carries the weight of this victory." if won else "The story continues. A defeat can open new help at the capital and prison."
	_paragraph(modal, body, Rect2(30, 106, 640, 138), 19, PAPER)
	_button(modal, "Continue the story", Rect2(30, 264, 640, 56), func():
		_close_modal()
		campaign.battle_finished(won, alive)
		_save_game()
		selected_candidate = ""
		_refresh_stage(), true)
	_button(modal, "Retry this defense", Rect2(30, 337, 640, 45), func():
		_close_modal()
		campaign.restore(battle_preparation)
		_begin_battle())

func _modal_panel(rect: Rect2) -> Panel:
	if notice_modal != null:
		notice_modal.queue_free()
	paused_before_modal = paused
	paused = true
	notice_modal = Control.new()
	notice_modal.size = Vector2(1440, 900)
	notice_modal.z_index = 100
	screen.add_child(notice_modal)
	var shade = ColorRect.new()
	shade.size = Vector2(1440, 900)
	shade.color = Color(0.015, 0.03, 0.045, 0.84)
	notice_modal.add_child(shade)
	return _panel(notice_modal, rect, Color("192a37"), GOLD)

func _close_modal() -> void:
	if notice_modal != null:
		notice_modal.queue_free()
		notice_modal = null
	if not result_open:
		paused = paused_before_modal

func _show_pause() -> void:
	if screen_name != "battle": return
	var p = _modal_panel(Rect2(478, 212, 484, 476))
	_label(p, "THE WATCH RESTS", Rect2(30, 25, 430, 60), 29, GOLD, true)
	_label(p, "%d editor changes waiting" % pending_edits.size(), Rect2(30, 91, 430, 28), 15, MUTED)
	_button(p, "Resume the defense", Rect2(30, 144, 424, 53), func(): _close_modal(); paused = false, true)
	_button(p, "Save chronicle", Rect2(30, 211, 424, 46), _save_with_feedback)
	_button(p, "Settings & connected editor", Rect2(30, 271, 424, 46), func(): _close_modal(); _show_settings())
	_button(p, "Return to title", Rect2(30, 331, 424, 46), func():
		if _save_game(): _show_title())
	_button(p, "Save and exit", Rect2(30, 391, 424, 46), func():
		if not _save_game(): return
		bridge.shutdown()
		if global_session != null: global_session.shutdown()
		get_tree().quit())

func _show_settings() -> void:
	var p = _modal_panel(Rect2(422, 164, 596, 572))
	_label(p, "A QUIETER KIND OF COMMAND", Rect2(28, 23, 545, 43), 24, GOLD, true)
	var sound = CheckButton.new()
	sound.text = "Sound effects"
	sound.button_pressed = bool(settings.get("sound", true))
	sound.position = Vector2(26, 95); sound.size = Vector2(540, 42)
	sound.toggled.connect(func(value): settings["sound"] = value; audio.enabled = value)
	p.add_child(sound)
	var music = CheckButton.new()
	music.text = "Quiet harp accompaniment"
	music.button_pressed = bool(settings.get("music", true))
	music.position = Vector2(26, 151); music.size = Vector2(540, 42)
	music.toggled.connect(func(value): settings["music"] = value; audio.music_enabled = value; if not value: audio.music_player.stop())
	p.add_child(music)
	_label(p, "Volume", Rect2(27, 215, 170, 30), 17, PAPER)
	var volume = HSlider.new()
	volume.position = Vector2(202, 217); volume.size = Vector2(357, 28)
	volume.min_value = 0; volume.max_value = 0.65; volume.step = 0.01
	volume.value = float(settings.get("volume", 0.32))
	volume.value_changed.connect(func(value): settings["volume"] = value; audio.volume = value)
	p.add_child(volume)
	var effects = CheckButton.new()
	effects.text = "Reduce decorative effects"
	effects.button_pressed = bool(settings.get("reduced_effects", false))
	effects.position = Vector2(26, 275); effects.size = Vector2(540, 42)
	effects.toggled.connect(func(value): settings["reduced_effects"] = value)
	p.add_child(effects)
	var routes = CheckButton.new()
	routes.text = "Show allied patrol tracks"
	routes.button_pressed = bool(settings.get("routes", true))
	routes.position = Vector2(26, 331); routes.size = Vector2(540, 42)
	routes.toggled.connect(func(value): settings["routes"] = value; if is_instance_valid(board): board.show_routes = value)
	p.add_child(routes)
	_button(p, "Connected editor & profile session", Rect2(28, 401, 540, 50), func(): _close_modal(); _show_editor())
	_button(p, "Done", Rect2(28, 489, 540, 51), func(): _close_modal(); if run_started: _save_game(), true)

func _show_editor() -> void:
	var p = _modal_panel(Rect2(372, 144, 696, 612))
	_label(p, "ONE GAME. ONE CONNECTED EDITOR.", Rect2(29, 25, 640, 40), 25, GOLD, true)
	_paragraph(p, "Open the Belde Chrome extension, connect to this game, and enter the code below. The game validates every placement; both screens share the same map.", Rect2(30, 90, 635, 94), 18, PAPER)
	_label(p, "PAIRING CODE", Rect2(30, 201, 630, 28), 13, MUTED)
	_label(p, str(bridge.pairing_code), Rect2(28, 230, 637, 77), 56, GOLD, true).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var connected = bool(bridge.editor_connected)
	_label(p, "EDITOR CONNECTED" if connected else "WAITING FOR YOUR EDITOR", Rect2(30, 326, 635, 32), 16, Color("9cc3b3"))
	var session_text = "This device allows one active game and one paired editor. Expired editor connections release automatically."
	if global_session != null and global_session.enabled:
		session_text = str(global_session.message)
	_paragraph(p, session_text, Rect2(30, 376, 635, 79), 15, MUTED)
	if connected:
		_button(p, "Disconnect current editor", Rect2(30, 472, 310, 43), func(): bridge.disconnect_editor(); _close_modal(); toast("Editor disconnected."))
	if global_session != null and global_session.enabled and not global_session.session_ready:
		_button(p, "Disconnect other session to continue", Rect2(30, 472, 635, 43), func(): global_session.force_takeover(); _close_modal())
	_button(p, "Done", Rect2(30, 541, 635, 43), _close_modal, true)

func _show_instance_warning() -> void:
	_clear_screen("instance")
	var p = _panel(screen, Rect2(344, 228, 752, 432), PANEL, GOLD)
	_label(p, "Multiple Game Instances Detected", Rect2(28, 28, 696, 80), 32, GOLD, true).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_paragraph(p, "Your game is currently active on another device or platform. Only one active PC gameplay session and one connected editor session are permitted.\n\nClose the other local game, then retry. Its authorized editor counts as part of that connected pair.", Rect2(28, 128, 696, 158), 19, PAPER)
	_button(p, "Retry after closing the other game", Rect2(28, 316, 696, 52), func():
		var port = _bridge_port()
		var result = bridge.configure(_remote_state, _remote_command, port)
		if result == OK: single_instance = true; _show_title()
		else: toast("The other game still owns this profile connection.", 4), true)

func _session_ready() -> bool:
	return single_instance and (global_session == null or not global_session.enabled or global_session.session_ready)

func _global_status(_status: String) -> void:
	if global_session != null and global_session.enabled and not global_session.session_ready:
		paused = true
		if is_instance_valid(screen): toast(str(global_session.message), 7)

func _bridge_port() -> int:
	if OS.has_environment("BELDE_BRIDGE_PORT"): return int(OS.get_environment("BELDE_BRIDGE_PORT"))
	if OS.has_environment("BELDE_PORT"): return int(OS.get_environment("BELDE_PORT"))
	return 43127

func _save_game() -> bool:
	if not run_started or not single_instance: return false
	var data = {"version": 2, "campaign": campaign.snapshot(), "simulation": sim.snapshot() if campaign.stage == "battle" else {}, "settings": settings, "pending_edits": pending_edits, "run_seconds": run_seconds, "battle_preparation": battle_preparation}
	var text = JSON.stringify(data, "\t")
	if JSON.parse_string(text) == null: return false
	var temporary = SAVE_PATH + ".tmp"
	var file = FileAccess.open(temporary, FileAccess.WRITE)
	if file == null: toast("The chronicle could not be written. Check available disk space.", 6); return false
	file.store_string(text)
	file.flush()
	file.close()
	var destination = ProjectSettings.globalize_path(SAVE_PATH)
	if FileAccess.file_exists(SAVE_PATH):
		var backup_error = DirAccess.copy_absolute(destination, destination + ".bak")
		if backup_error != OK:
			toast("The chronicle backup could not be written. Your previous save is preserved.", 6)
			return false
	var error = DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), destination)
	if error != OK: toast("The chronicle could not replace the previous save. Your previous save is preserved.", 6)
	return error == OK

func _save_with_feedback() -> void:
	if _save_game(): toast("Chronicle saved.")

func _load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH): toast("No chronicle has been saved yet."); return
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not data is Dictionary or not typeof(data.get("version")) in [TYPE_INT, TYPE_FLOAT] or int(data.get("version", 0)) != 2:
		toast("This chronicle is unreadable or from a different version. The backup is preserved.", 7); return
	if not data.get("campaign") is Dictionary or not data.get("battle_preparation", {}) is Dictionary or not data.get("settings", {}) is Dictionary or not data.get("pending_edits", []) is Array:
		toast("This chronicle contains invalid save data. Your current game is preserved.", 7); return
	if not typeof(data.get("run_seconds", 0)) in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(data.get("run_seconds", 0))):
		toast("This chronicle contains an invalid play time.", 7); return
	var saved_settings: Dictionary = data.get("settings", {})
	for key in ["sound", "music", "reduced_effects", "routes"]:
		if saved_settings.has(key) and not saved_settings[key] is bool:
			toast("This chronicle contains an invalid setting.", 7); return
	for key in ["volume", "speed"]:
		if saved_settings.has(key) and (not typeof(saved_settings[key]) in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(saved_settings[key]))):
			toast("This chronicle contains an invalid setting.", 7); return
	var saved_pending: Array = data.get("pending_edits", [])
	if saved_pending.size() > 32 or not saved_pending.all(func(edit): return edit is Dictionary):
		toast("This chronicle contains an invalid editor queue.", 7); return
	var candidate = Campaign.new(catalog)
	var result = candidate.restore(data.get("campaign", {}))
	if not result.get("ok", false): toast(str(result.get("message", "This chronicle is not valid.")), 7); return
	var candidate_sim = Simulation.new(catalog)
	if candidate.stage == "battle":
		var saved_sim = data.get("simulation", {})
		if not saved_sim is Dictionary or saved_sim.is_empty(): toast("The saved battlefield is missing.", 6); return
		var simulation_result = candidate_sim.restore(saved_sim)
		if simulation_result is Dictionary and not simulation_result.get("ok", false): toast(str(simulation_result.get("message", "The saved battlefield is invalid.")), 6); return
		if str(candidate_sim.map.get("id", "")) != candidate.current_map_id() or saved_sim.get("party_ids", []) != candidate.party:
			toast("The saved battlefield does not match this company.", 6); return
		var preparation = Campaign.new(catalog)
		if not preparation.restore(data.get("battle_preparation", candidate.snapshot())).get("ok", false):
			toast("The saved defense preparation is invalid.", 6); return
	campaign = candidate
	sim = candidate_sim
	if data.get("settings", {}) is Dictionary: settings.merge(data["settings"], true)
	pending_edits = data.get("pending_edits", []).duplicate(true) if data.get("pending_edits", []) is Array else []
	battle_preparation = data.get("battle_preparation", campaign.snapshot()).duplicate(true)
	run_seconds = maxf(0, float(data.get("run_seconds", 0)))
	run_started = true
	audio.enabled = bool(settings.get("sound", true))
	audio.music_enabled = bool(settings.get("music", true))
	audio.volume = clampf(float(settings.get("volume", 0.32)), 0, 0.65)
	settings["speed"] = clampf(float(settings.get("speed", 1)), 1, 3)
	if campaign.stage == "battle":
		selected_uid = str(sim.units[0].get("uid", "")) if not sim.units.is_empty() else ""
		selected_tower = ""
		_begin_battle(true)
	else: _refresh_stage()
	toast("The chronicle resumes.", 4)

func _show_codex() -> void:
	paused = true
	_clear_screen("codex")
	_heading("People of the five roads", "58 companions. Four classes. Two abilities each. A face and a reason to stand with you.", _show_title)
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(32, 145); scroll.size = Vector2(1376, 687)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	screen.add_child(scroll)
	var grid = GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(grid)
	for c in catalog.characters:
		var id = str(c["id"])
		var b = Button.new()
		b.custom_minimum_size = Vector2(216, 176)
		grid.add_child(b)
		_image(b, art.portrait(id), Rect2(12, 12, 76, 76))
		_label(b, str(c.get("class", "")), Rect2(102, 16, 104, 28), 13, BeldeArt.class_color(str(c.get("class", ""))))
		_label(b, "Age %s" % c.get("age", ""), Rect2(102, 52, 104, 25), 12, MUTED)
		_label(b, str(c.get("name", id)), Rect2(12, 105, 194, 57), 17, PAPER, true).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.pressed.connect(func(): _show_character_dialog(id))

func _show_character_dialog(id: String) -> void:
	var c = catalog.get_character(id)
	var p = _modal_panel(Rect2(392, 117, 656, 666))
	_image(p, art.portrait(id), Rect2(28, 28, 117, 117))
	_label(p, str(c["name"]), Rect2(168, 28, 455, 76), 29, GOLD, true).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label(p, "%s · Age %s · %s" % [c["class"], c["age"], c["origin"]], Rect2(168, 111, 455, 33), 15, BeldeArt.class_color(str(c["class"])))
	_paragraph(p, "“%s”" % c.get("intro", ""), Rect2(28, 179, 600, 88), 18, PAPER)
	var stats = c.get("stats", {})
	var attack = stats.get("basic_attack", {})
	_label(p, "HP %s · Basic %s every %ss · Range %s" % [stats.get("hp", 0), attack.get("damage", 0), attack.get("interval_seconds", 1), attack.get("range_tiles", 1)], Rect2(28, 283, 600, 32), 17, MUTED)
	for slot in range(2):
		var ability = catalog.get_ability(id, slot)
		_label(p, "%s · %ss" % [ability.get("name", ""), ability.get("cooldown_seconds", 15)], Rect2(28, 336 + slot * 112, 600, 32), 22, GOLD)
		_paragraph(p, str(ability.get("description", "")), Rect2(28, 376 + slot * 112, 600, 71), 16, PAPER)
	_button(p, "Close", Rect2(28, 594, 600, 44), _close_modal, true)

func _show_ending() -> void:
	paused = true
	_clear_screen("ending")
	var ending_data: Dictionary = campaign.ending_data
	if ending_data.is_empty(): ending_data = campaign.ending(bool(campaign.flags.get("forgiven", false)))
	_heading("The chronicle remembers", str(ending_data.get("verse", "A road still waiting")))
	var bg = art.battlefield(5)
	if bg != null:
		_image(screen, bg, Rect2(32, 127, 1376, 700))
	var p = _panel(screen, Rect2(110, 160, 1220, 618), Color(0.06, 0.1, 0.14, 0.94), GOLD)
	_label(p, "A TITLE EARNED BY YOUR COMMANDS", Rect2(40, 30, 1140, 28), 13, GOLD)
	_label(p, str(ending_data.get("title", "The Keeper of a Quiet Gate")), Rect2(40, 81, 1140, 120), 35, PAPER, true).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_paragraph(p, str(ending_data.get("summary", "")), Rect2(40, 221, 1140, 92), 20, PAPER)
	_label(p, "THOSE WHO WALK BESIDE YOU", Rect2(40, 337, 1140, 28), 13, GOLD)
	var survivors: Array = ending_data.get("survivors", [])
	for i in range(mini(10, survivors.size())):
		_image(p, art.portrait(str(survivors[i])), Rect2(40 + i * 111, 385, 85, 85))
	_label(p, "%d remembered · %d victories · %d retreats · %.0f minutes on the road" % [campaign.fallen.size(), int(campaign.flags.get("wins", 0)), int(campaign.flags.get("losses", 0)), run_seconds / 60.0], Rect2(40, 491, 1140, 31), 16, MUTED)
	_button(p, "Begin another chronicle", Rect2(40, 548, 550, 47), _show_origins, true)
	_button(p, "Return to title", Rect2(628, 548, 550, 47), _show_title)
	_save_game()

func toast(message: String, duration: float = 4.0) -> void:
	if is_instance_valid(toast_label): toast_label.text = message
	toast_time = duration

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and not drag_tool.is_empty():
		if is_instance_valid(board) and board.get_global_rect().has_point(event.position):
			var local = board.get_local_mouse_position()
			apply_tool(drag_tool, Vector2i(floori(local.x / 32), floori(local.y / 32)))
			drag_tool = ""
			get_viewport().set_input_as_handled()
		else: drag_tool = ""
	if not event is InputEventKey or not event.pressed or event.echo: return
	if event.keycode == KEY_ESCAPE:
		if is_instance_valid(notice_modal) and not result_open: _close_modal()
		elif screen_name == "battle":
			if tool != "select": set_tool("select"); track_draft.clear()
			else: _show_pause()
		get_viewport().set_input_as_handled()
	if screen_name != "battle" or is_instance_valid(notice_modal): return
	match event.keycode:
		KEY_SPACE: _start_wave(); get_viewport().set_input_as_handled()
		KEY_1: if not selected_uid.is_empty(): issue_command({"kind": "cast", "uid": selected_uid, "slot": 0})
		KEY_2: if not selected_uid.is_empty(): issue_command({"kind": "cast", "uid": selected_uid, "slot": 1})
		KEY_G: if is_instance_valid(board): board.show_grid = not board.show_grid
		KEY_R:
			if is_instance_valid(board):
				board.show_routes = not board.show_routes
				settings["routes"] = board.show_routes
		KEY_F5: _save_with_feedback()
		KEY_U: if not selected_tower.is_empty(): issue_command({"kind": "upgrade_tower", "uid": selected_tower}); _update_selection_panel()
		KEY_Z:
			if event.ctrl_pressed or event.meta_pressed: issue_command({"kind": "redo" if event.shift_pressed else "undo"})
		KEY_Y:
			if event.ctrl_pressed or event.meta_pressed: issue_command({"kind": "redo"})
