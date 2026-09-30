extends SceneTree
## Headless test: AudioManager API. Cannot verify actual sound, but verifies
## stream creation, cache population, and call safety.
## Run: godot --headless --script tests/test_audio_manager.gd

var failures: int = 0


func _init() -> void:
	process_frame.connect(_on_first_frame, CONNECT_ONE_SHOT)


func _on_first_frame() -> void:
	_run_tests()


func _run_tests() -> void:
	var am: Node = root.get_node_or_null("AudioManager")
	if am == null:
		_fail("AudioManager autoload not found")
		_finish()
		return

	# --- Cache populated ---
	for name in ["tap", "event", "death", "win"]:
		if not am.has_sfx(name):
			_fail("missing sfx: %s" % name)
	if not am.has_music("ambient"):
		_fail("missing music: ambient")

	# --- Streams are valid AudioStreamWAV with data ---
	# We can't reach into _sfx_cache directly from outside cleanly, but we
	# can verify via play and check the player's stream.
	am.play_sfx("tap")
	var sp: AudioStreamPlayer = am.sfx_player
	if sp.stream == null:
		_fail("tap stream is null after play_sfx")
	elif not (sp.stream is AudioStreamWAV):
		_fail("tap stream should be AudioStreamWAV")

	# --- Unknown SFX: should warn, not crash ---
	am.play_sfx("not_a_real_sfx")
	# If we reached here without an exception, we're fine.

	# --- Unknown music: should warn, not crash ---
	am.play_music("not_a_real_music")

	# --- Volume setters ---
	am.set_sfx_volume_db(-20.0)
	if abs(am.sfx_volume_db - (-20.0)) > 0.001:
		_fail("sfx volume should be -20, got %f" % am.sfx_volume_db)
	if abs(sp.volume_db - (-20.0)) > 0.001:
		_fail("sfx_player.volume_db should reflect setter")

	am.set_music_volume_db(-30.0)
	if abs(am.music_volume_db - (-30.0)) > 0.001:
		_fail("music volume should be -30, got %f" % am.music_volume_db)

	# --- Music play/stop state ---
	am.play_music("ambient")
	if am.music_player.stream == null:
		_fail("music stream is null after play_music")

	am.stop_music()
	if am.music_player.playing:
		_fail("music should be stopped after stop_music")

	# --- Ambient has loop enabled ---
	var music_stream: AudioStreamWAV = am.music_player.stream as AudioStreamWAV
	if music_stream != null and music_stream.loop_mode != AudioStreamWAV.LOOP_FORWARD:
		_fail("ambient should have LOOP_FORWARD, got %d" % music_stream.loop_mode)

	_finish()


func _fail(msg: String) -> void:
	push_error("FAIL: %s" % msg)
	failures += 1


func _finish() -> void:
	if failures == 0:
		print("PASS: test_audio_manager (all assertions)")
		quit(0)
	else:
		push_error("FAILED: %d assertion(s)" % failures)
		quit(1)
