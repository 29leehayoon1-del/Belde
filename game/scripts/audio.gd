extends Node
class_name BeldeAudio

var enabled: bool = true
var music_enabled: bool = true
var volume: float = 0.28
var music_player: AudioStreamPlayer
var players: Array = []
var tones: Dictionary = {}
var note_clock: float = 0.0
var note_index: int = 0
var notes: Array = [146.83, 174.61, 220.0, 196.0, 146.83, 130.81, 174.61, 164.81]

func _ready() -> void:
	for i in range(8):
		var p = AudioStreamPlayer.new()
		add_child(p)
		players.append(p)
	music_player = AudioStreamPlayer.new()
	music_player.volume_db = -24.0
	add_child(music_player)
	tones["click"] = _tone(590.0, 0.07, 0)
	tones["hit"] = _tone(170.0, 0.055, 1)
	tones["heal"] = _tone(784.0, 0.17, 0)
	tones["ability"] = _tone(440.0, 0.22, 2)
	tones["wave"] = _tone(220.0, 0.52, 2)
	tones["victory"] = _tone(523.25, 0.75, 2)
	tones["defeat"] = _tone(110.0, 0.75, 1)
	tones["error"] = _tone(105.0, 0.13, 1)
	for i in range(notes.size()):
		tones["music_" + str(i)] = _tone(float(notes[i]), 2.4, 3)

func _process(delta: float) -> void:
	if DisplayServer.get_name() == "headless" or not music_enabled:
		return
	music_player.volume_db = linear_to_db(maxf(volume, 0.001)) - 15.0
	note_clock -= delta
	if note_clock <= 0:
		note_clock = 2.5
		music_player.stream = tones["music_" + str(note_index % notes.size())]
		music_player.play()
		note_index += 1

func play_cue(name: String) -> void:
	if DisplayServer.get_name() == "headless" or not enabled or not tones.has(name):
		return
	for p in players:
		if not p.playing:
			p.stream = tones[name]
			p.volume_db = linear_to_db(maxf(volume, 0.001)) - 7.0
			p.play()
			return

func _tone(frequency: float, duration: float, type: int) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.stereo = false
	var frames = int(duration * 22050)
	var data = PackedByteArray()
	data.resize(frames * 2)
	for i in range(frames):
		var t = float(i) / 22050.0
		var envelope = minf(t / 0.012, 1.0) * pow(maxf(0, 1.0 - t / duration), 1.8)
		var f = frequency
		if type == 1:
			f *= 1.0 - 0.45 * t / duration
		var wave = sin(TAU * f * t) * 0.62 + sin(TAU * f * 2 * t) * 0.15
		if type == 2:
			wave += sin(TAU * f * 1.5 * t) * 0.22 + sin(TAU * f * 1.25 * t) * 0.12
		if type == 3:
			wave = sin(TAU * f * t) * 0.25 + sin(TAU * f * 1.5 * t) * 0.17
		var value = int(clampf(wave * envelope, -1.0, 1.0) * 18500)
		data.encode_s16(i * 2, value)
	stream.data = data
	return stream

func _exit_tree() -> void:
	if is_instance_valid(music_player):
		music_player.stop()
		music_player.stream = null
	for p in players:
		if is_instance_valid(p):
			p.stop()
			p.stream = null
	tones.clear()
