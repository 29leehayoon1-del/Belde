extends SceneTree

var game

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: PackedScene = load("res://main.tscn")
	game = scene.instantiate()
	root.add_child(game)
	await create_timer(0.25).timeout
	if game.bridge == null or not game.single_instance or game.campaign.stage != "battle":
		printerr("BRIDGE_GAME_START_FAILED")
		quit(1)
		return
	print("BRIDGE_GAME_READY ", game.bridge.pairing_code)
