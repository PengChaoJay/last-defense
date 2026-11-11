extends SceneTree

func _initialize() -> void:
	call_deferred("run_test")

func run_test() -> void:
	var scene: PackedScene = load("res://main.tscn")
	var game: Node = scene.instantiate()
	root.add_child(game)

	game.start_game()
	game.open_upgrade_menu()
	game.choose_upgrade(0)
	game.arc_level = 2
	game.orbit_level = 2
	game.multishot_upgrade_count = 1
	game.damage_upgrade_count = 1
	game.fire_rate_upgrade_count = 1
	game.refresh_fusions()
	game.player_pos = Vector2(1160, 170)
	game.update_arena_features(0.016)
	game.activate_nearby_terminal()
	game.spawn_enemy(true)
	game.spawn_boss()

	for frame in range(180):
		await process_frame

	if not game.chain_pulse_active:
		push_error("Chain Pulse fusion did not activate")
		quit(1)
		return
	if not game.overload_blade_active:
		push_error("Overload Blade fusion did not activate")
		quit(1)
		return
	if not game.boss_spawned:
		push_error("Boss did not spawn")
		quit(1)
		return
	if game.damage_boost_timer <= 0.0:
		push_error("Weapon terminal did not activate")
		quit(1)
		return
	if game.obstacles.size() != 6 or game.terminals.size() != 3:
		push_error("Arena features are incomplete")
		quit(1)
		return

	print("SMOKE_TEST_OK enemies=", game.enemies.size(), " bullets=", game.bullets.size())
	game.queue_free()
	await process_frame
	game = null
	scene = null
	await process_frame
	quit(0)
