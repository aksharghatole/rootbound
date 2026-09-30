extends Node
## AudioManager — Milestone 7
## Procedural SFX and ambient music. No asset files required.
##
## Each sound is a pre-rendered AudioStreamWAV generated once at _ready().
## Playback is a simple stream swap + play(). Safe to call headless.

const SAMPLE_RATE: int = 22050

var sfx_player: AudioStreamPlayer
var music_player: AudioStreamPlayer

var _sfx_cache: Dictionary = {}
var _music_cache: Dictionary = {}

var sfx_volume_db: float = -6.0
var music_volume_db: float = -18.0


func _ready() -> void:
	sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = "Master"
	sfx_player.volume_db = sfx_volume_db
	add_child(sfx_player)

	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	music_player.volume_db = music_volume_db
	add_child(music_player)

	_build_all_sfx()
	_build_all_music()

	print("AudioManager ready. SFX: %d. Music: %d." % [
		_sfx_cache.size(), _music_cache.size()
	])


# ---------------------------------------------------------------- public API

func play_sfx(name: String) -> void:
	if not _sfx_cache.has(name):
		push_warning("AudioManager.play_sfx: unknown sfx '%s'" % name)
		return
	sfx_player.stream = _sfx_cache[name]
	sfx_player.play()


func play_music(name: String) -> void:
	if not _music_cache.has(name):
		push_warning("AudioManager.play_music: unknown track '%s'" % name)
		return
	if music_player.stream == _music_cache[name] and music_player.playing:
		return
	music_player.stream = _music_cache[name]
	music_player.play()


func stop_music() -> void:
	music_player.stop()


func set_sfx_volume_db(db: float) -> void:
	sfx_volume_db = db
	sfx_player.volume_db = db


func set_music_volume_db(db: float) -> void:
	music_volume_db = db
	music_player.volume_db = db


func has_sfx(name: String) -> bool:
	return _sfx_cache.has(name)


func has_music(name: String) -> bool:
	return _music_cache.has(name)


func is_music_playing() -> bool:
	return music_player.playing


func is_sfx_playing() -> bool:
	return sfx_player.playing


# ---------------------------------------------------------------- generators

func _build_all_sfx() -> void:
	_sfx_cache["tap"] = _make_tone(880.0, 0.08, -12.0, 1.5)
	_sfx_cache["event"] = _make_tone(440.0, 0.20, -8.0, 1.0)
	_sfx_cache["death"] = _make_descending(220.0, 110.0, 0.60)
	_sfx_cache["win"] = _make_arpeggio(
		PackedFloat32Array([523.25, 659.25, 783.99, 1046.50]),
		0.16
	)


func _build_all_music() -> void:
	_music_cache["ambient"] = _make_ambient_loop(4.0)


# ---------------------------------------------------------------- helpers

func _make_tone(freq: float, duration: float, attack_frac: float, release_frac: float) -> AudioStreamWAV:
	## Short tone with linear attack and release envelope.
	var sample_count: int = int(SAMPLE_RATE * duration)
	var attack_samples: int = int(float(sample_count) * clampf(attack_frac, 0.0, 1.0))
	var release_samples: int = int(float(sample_count) * clampf(release_frac, 0.0, 1.0))
	var data: PackedByteArray = PackedByteArray()
	data.resize(sample_count * 2)  # 16-bit mono

	for i in range(sample_count):
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = 1.0
		if i < attack_samples:
			env = float(i) / float(max(1, attack_samples))
		elif i > sample_count - release_samples:
			var rel_i: int = i - (sample_count - release_samples)
			env = 1.0 - float(rel_i) / float(max(1, release_samples))
		var s: float = sin(TAU * freq * t) * env * 0.35
		var v: int = int(clampf(s, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, v)

	return _to_stream(data)


func _make_descending(f0: float, f1: float, duration: float) -> AudioStreamWAV:
	## Frequency sweep f0 -> f1 with a soft envelope.
	var sample_count: int = int(SAMPLE_RATE * duration)
	var data: PackedByteArray = PackedByteArray()
	data.resize(sample_count * 2)
	var phase: float = 0.0

	for i in range(sample_count):
		var frac: float = float(i) / float(sample_count)
		var freq: float = lerp(f0, f1, frac)
		phase += TAU * freq / float(SAMPLE_RATE)
		var env: float = 1.0 - frac * 0.9
		var s: float = sin(phase) * env * 0.35
		var v: int = int(clampf(s, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, v)

	return _to_stream(data)


func _make_arpeggio(freqs: PackedFloat32Array, note_duration: float) -> AudioStreamWAV:
	## Quick successive tones, each with attack/release.
	var per_note: int = int(SAMPLE_RATE * note_duration)
	var total: int = per_note * freqs.size()
	var data: PackedByteArray = PackedByteArray()
	data.resize(total * 2)

	var write_index: int = 0
	for f in freqs:
		for i in range(per_note):
			var t: float = float(i) / float(SAMPLE_RATE)
			var frac: float = float(i) / float(per_note)
			var env: float = 1.0
			if frac < 0.05:
				env = frac / 0.05
			elif frac > 0.85:
				env = (1.0 - frac) / 0.15
			var s: float = sin(TAU * f * t) * env * 0.30
			var v: int = int(clampf(s, -1.0, 1.0) * 32767.0)
			data.encode_s16(write_index * 2, v)
			write_index += 1

	return _to_stream(data)


func _make_ambient_loop(duration: float) -> AudioStreamWAV:
	## Low drone with slow amplitude modulation. Seamless loop.
	var sample_count: int = int(SAMPLE_RATE * duration)
	var data: PackedByteArray = PackedByteArray()
	data.resize(sample_count * 2)

	var base_freq: float = 110.0
	var fifth_freq: float = 164.81

	for i in range(sample_count):
		var t: float = float(i) / float(SAMPLE_RATE)
		var lfo: float = 0.6 + 0.4 * sin(TAU * 0.15 * t)
		# Make the loop seamless: scale by a window that returns to the same
		# value at start and end. Use a slow sine aligned to the whole duration.
		var wrap: float = sin(TAU * t / duration)
		var amp: float = 0.18 * lfo
		var s: float = (
			sin(TAU * base_freq * t) * 0.6
			+ sin(TAU * fifth_freq * t) * 0.3
		) * amp * (0.7 + 0.3 * wrap)
		var v: int = int(clampf(s, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, v)

	var stream: AudioStreamWAV = _to_stream(data)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = sample_count
	return stream


func _to_stream(data: PackedByteArray) -> AudioStreamWAV:
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream
