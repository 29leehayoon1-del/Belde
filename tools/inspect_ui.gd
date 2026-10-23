extends SceneTree

func _initialize() -> void:
	call_deferred("_inspect")

func _inspect() -> void:
	var packed = load("res://main.tscn")
	var main = packed.instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	print("UI_PROBE root viewport ", root.get_visible_rect(), " main ", main.size, " canvas ", main.canvas.size, " canvas scale ", main.canvas.scale, " screen ", main.screen.size, " screen name ", main.screen_name)
	print("UI_PROBE window visible ", DisplayServer.window_get_mode(), " position ", DisplayServer.window_get_position(), " size ", DisplayServer.window_get_size())
	var output = ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			output = argument.trim_prefix("--output=")
	if not output.is_empty():
		await RenderingServer.frame_post_draw
		var result = root.get_texture().get_image().save_png(output)
		print("UI_PROBE viewport image result ", result)
	main.queue_free()
	await process_frame
	quit()
