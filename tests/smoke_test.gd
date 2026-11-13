extends SceneTree

func _initialize() -> void:
	call_deferred("run_test")

func run_test() -> void:
	var scene: PackedScene = load("res://main.tscn")
	var game: Node = scene.instantiate()
	root.add_child(game)

	game.sound_enabled = false
	game.start_game()
	game.open_upgrade_menu()
	game.choose_upgrade(0)
	game.install_defense_module("turret")
	game.install_defense_module("slow")
	game.install_defense_module("repair")
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
	var elite_affix: String = game.enemies[-1].get("affix", "")
	if elite_affix.is_empty():
		push_error("Elite affix was not assigned")
		quit(1)
		return
	game.choosing_upgrade = true
	game.upgrade_options.clear()
	game.upgrade_options.append(game.rare_upgrades[1].duplicate(true))
	game.choose_upgrade(0)
	game.elapsed = 121.0
	game.update_stage()
	if game.stage_index != 1:
		push_error("Phase II did not activate")
		quit(1)
		return
	game.elapsed = 301.0
	game.update_stage()
	if game.stage_index != 2:
		push_error("Phase III did not activate")
		quit(1)
		return
	game.spawn_boss()
	for i in range(240):
		game.spawn_enemy()
	for i in range(700):
		game.create_spark(Vector2.ZERO, Color.WHITE, 1)

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
	if game.defense_modules.size() != 3 or game.defense_modules[0]["level"] < 1:
		push_error("Defense modules were not installed")
		quit(1)
		return
	var nest_count := 0
	for enemy in game.enemies:
		if enemy["type"] == "nest":
			nest_count += 1
	if nest_count != 2:
		push_error("Enemy nests are incomplete")
		quit(1)
		return
	if not game.rare_reactive:
		push_error("Rare upgrade did not activate")
		quit(1)
		return
	game.selected_mode = "endless"
	game.boss_wave = 2
	game.next_boss_time = game.elapsed
	game.boss_alive = false
	game.update_boss_schedule()
	if not game.boss_alive or game.boss_max_hp <= 1650.0:
		push_error("Endless boss scaling did not activate")
		quit(1)
		return
	if game.enemies.size() > game.MAX_ENEMIES:
		push_error("Enemy cap was exceeded")
		quit(1)
		return
	if game.sparks.size() > game.MAX_SPARKS:
		push_error("Spark cap was exceeded")
		quit(1)
		return

	print("SMOKE_TEST_OK enemies=", game.enemies.size(), " bullets=", game.bullets.size())
	for player in game.sfx.values():
		player.stop()
	game.sfx.clear()
	game.free()
	game = null
	scene = null
	for frame in range(3):
		await process_frame
	quit(0)
