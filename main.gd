extends Node2D

const SCREEN := Vector2(1280.0, 720.0)
const PLAYER_SPEED := 270.0
const PLAYER_RADIUS := 15.0
const CORE_POS := Vector2(640.0, 360.0)
const CORE_RADIUS := 42.0
const BOSS_TIME := 420.0
const MAX_RUN_TIME := 600.0
const MAX_ENEMIES := 180
const MAX_BULLETS := 320
const MAX_XP_ORBS := 260
const MAX_SPARKS := 520
const MAX_DAMAGE_NUMBERS := 140
const MAX_ARC_EFFECTS := 80
const SAVE_PATH := "user://last_defense_save.cfg"

var player_pos := Vector2(640.0, 470.0)
var player_hp := 100.0
var player_max_hp := 100.0
var player_speed := 270.0
var pickup_radius := 70.0
var core_hp := 300.0
var elapsed := 0.0
var spawn_timer := 0.0
var shot_timer := 0.0
var game_over := false
var victory := false
var choosing_upgrade := false
var kills := 0
var level := 1
var xp := 0
var xp_needed := 6
var shot_damage := 12.0
var shot_interval := 0.42
var projectile_count := 1
var arc_level := 0
var orbit_level := 0
var energy_level := 1
var damage_upgrade_count := 0
var fire_rate_upgrade_count := 0
var multishot_upgrade_count := 0
var arc_timer := 0.0
var orbit_angle := 0.0
var boss_spawned := false
var boss_alive := false
var boss_max_hp := 1.0
var chain_pulse_active := false
var overload_blade_active := false
var game_started := false
var game_paused := false
var animation_time := 0.0
var screen_shake := 0.0
var player_flash := 0.0
var core_flash := 0.0
var announcement_text := ""
var announcement_time := 0.0
var sound_enabled := true
var screen_shake_enabled := true
var tutorial_completed := false
var tutorial_step := 0
var stage_index := 0
var event_timer := 55.0
var damage_boost_timer := 0.0
var hazard_tick := 0.0
var nearby_terminal := ""
var result_recorded := false
var best_kills := 0
var best_time := 0.0
var total_runs := 0
var total_wins := 0
var selected_mode := "normal"
var boss_wave := 1
var next_boss_time := BOSS_TIME
var rare_execution := false
var rare_reactive := false
var rare_vampiric := false
var rare_terminal_mastery := false
var reactive_cooldown := 0.0
var terminal_damage_bonus := 0.0

var enemies: Array[Dictionary] = []
var bullets: Array[Dictionary] = []
var sparks: Array[Dictionary] = []
var arc_effects: Array[Dictionary] = []
var xp_orbs: Array[Dictionary] = []
var upgrade_options: Array[Dictionary] = []
var damage_numbers: Array[Dictionary] = []
var stars: Array[Dictionary] = []
var sfx: Dictionary = {}
var obstacles: Array[Dictionary] = []
var hazards: Array[Dictionary] = []
var terminals: Array[Dictionary] = []
var defense_modules: Array[Dictionary] = []
var player_texture: Texture2D
var enemy_normal_texture: Texture2D
var enemy_heavy_texture: Texture2D
var boss_texture: Texture2D
var core_texture: Texture2D

var upgrades: Array[Dictionary] = [
	{"id": "damage", "name": "DAMAGE", "desc": "Projectile damage +25%"},
	{"id": "fire_rate", "name": "FIRE RATE", "desc": "Attack interval -15%"},
	{"id": "speed", "name": "MOBILITY", "desc": "Movement speed +12%"},
	{"id": "armor", "name": "ARMOR", "desc": "Max HP +20 and heal 35"},
	{"id": "multishot", "name": "MULTISHOT", "desc": "Fire one more projectile"},
	{"id": "magnet", "name": "MAGNET", "desc": "Pickup range +35%"},
	{"id": "energy", "name": "ENERGY CANNON", "desc": "Energy weapon level +1"},
	{"id": "arc", "name": "ARC MODULE", "desc": "Unlock or improve chain lightning"},
	{"id": "orbit", "name": "ORBIT BLADES", "desc": "Unlock or improve orbiting blades"},
	{"id": "defense_turret", "name": "SENTRY TURRET", "desc": "Install or upgrade an automatic core turret"},
	{"id": "defense_slow", "name": "STASIS PYLON", "desc": "Install or upgrade a slowing field"},
	{"id": "defense_repair", "name": "REPAIR DRONE", "desc": "Install or upgrade automatic core repair"}
]
var rare_upgrades: Array[Dictionary] = [
	{"id": "execution_protocol", "name": "EXECUTION PROTOCOL", "desc": "RARE: +60% damage, but -25 max HP", "rarity": "rare"},
	{"id": "reactive_core", "name": "REACTIVE CORE", "desc": "RARE: core damage releases a defensive EMP", "rarity": "rare"},
	{"id": "vampiric_cells", "name": "VAMPIRIC CELLS", "desc": "RARE: every 12 kills restores armor", "rarity": "rare"},
	{"id": "terminal_mastery", "name": "TERMINAL MASTERY", "desc": "RARE: terminals permanently amplify damage", "rarity": "rare"}
]

func _ready() -> void:
	load_progress()
	load_visual_assets()
	setup_audio()
	create_starfield()
	setup_arena_features()
	queue_redraw()

func load_visual_assets() -> void:
	player_texture = load("res://assets/sprites/generated/player-robot-game-v1.png")
	enemy_normal_texture = load("res://assets/sprites/generated/enemy-normal-game-v1.png")
	enemy_heavy_texture = load("res://assets/sprites/generated/enemy-heavy-game-v1.png")
	boss_texture = load("res://assets/sprites/generated/boss-titan-game-v1.png")
	core_texture = load("res://assets/sprites/generated/energy-core-game-v1.png")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if not game_started and event.keycode == KEY_ENTER:
			start_game()
		elif not game_started and event.keycode in [KEY_1, KEY_2, KEY_3]:
			selected_mode = ["normal", "challenge", "endless"][event.keycode - KEY_1]
			play_sfx("pickup")
		elif game_over and event.keycode == KEY_R:
			start_game()
		elif (game_over or game_paused) and event.keycode == KEY_Q:
			return_to_title()
		elif game_started and not game_over and not choosing_upgrade and event.keycode == KEY_ESCAPE:
			game_paused = not game_paused
			play_sfx("pickup")
		elif game_paused and event.keycode == KEY_ENTER:
			game_paused = false
		elif choosing_upgrade:
			if event.keycode == KEY_1:
				choose_upgrade(0)
			elif event.keycode == KEY_2:
				choose_upgrade(1)
			elif event.keycode == KEY_3:
				choose_upgrade(2)
		elif game_started and not game_over and event.keycode == KEY_E:
			activate_nearby_terminal()
		elif event.keycode == KEY_M:
			sound_enabled = not sound_enabled
			save_progress()
		elif event.keycode == KEY_V:
			screen_shake_enabled = not screen_shake_enabled
			save_progress()
		elif event.keycode == KEY_F11:
			toggle_fullscreen()
		elif not game_started and event.keycode == KEY_T:
			tutorial_completed = false
			tutorial_step = 0
			save_progress()

func _process(delta: float) -> void:
	animation_time += delta
	update_feedback(delta)
	if not game_started or game_paused:
		queue_redraw()
		return
	if game_over:
		queue_redraw()
		return
	if choosing_upgrade:
		queue_redraw()
		return

	elapsed += delta
	reactive_cooldown = max(0.0, reactive_cooldown - delta)
	update_stage()
	if selected_mode != "endless" and elapsed >= MAX_RUN_TIME:
		finish_run(false)
		queue_redraw()
		return
	update_boss_schedule()
	update_arena_features(delta)
	update_defense_modules(delta)
	update_player(delta)
	update_spawning(delta)
	update_shooting(delta)
	update_arc_weapon(delta)
	update_orbit_weapon(delta)
	update_bullets(delta)
	update_enemies(delta)
	update_xp_orbs(delta)
	update_sparks(delta)
	update_arc_effects(delta)
	if player_hp <= 0.0 or core_hp <= 0.0:
		finish_run(false)
	queue_redraw()

func load_progress() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	best_kills = int(config.get_value("records", "best_kills", 0))
	best_time = float(config.get_value("records", "best_time", 0.0))
	total_runs = int(config.get_value("records", "total_runs", 0))
	total_wins = int(config.get_value("records", "total_wins", 0))
	sound_enabled = bool(config.get_value("settings", "sound_enabled", true))
	screen_shake_enabled = bool(config.get_value("settings", "screen_shake_enabled", true))
	tutorial_completed = bool(config.get_value("progress", "tutorial_completed", false))

func save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("records", "best_kills", best_kills)
	config.set_value("records", "best_time", best_time)
	config.set_value("records", "total_runs", total_runs)
	config.set_value("records", "total_wins", total_wins)
	config.set_value("settings", "sound_enabled", sound_enabled)
	config.set_value("settings", "screen_shake_enabled", screen_shake_enabled)
	config.set_value("progress", "tutorial_completed", tutorial_completed)
	config.save(SAVE_PATH)

func toggle_fullscreen() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func update_stage() -> void:
	var next_stage := 0
	if elapsed >= 300.0:
		next_stage = 2
	elif elapsed >= 120.0:
		next_stage = 1
	if next_stage == stage_index:
		return
	stage_index = next_stage
	if stage_index == 1:
		announcement_text = "PHASE II: ESCALATION"
	else:
		announcement_text = "PHASE III: FINAL ASSAULT"
	announcement_time = 2.8
	play_sfx("boss")

func stage_name() -> String:
	if selected_mode == "endless" and boss_wave > 1:
		return "ENDLESS WAVE %d" % boss_wave
	if boss_spawned:
		return "BOSS: SIEGE TITAN"
	if stage_index == 2:
		return "PHASE III: FINAL ASSAULT"
	if stage_index == 1:
		return "PHASE II: ESCALATION"
	return "PHASE I: BREACH"

func finish_run(won: bool) -> void:
	if result_recorded:
		return
	result_recorded = true
	victory = won
	game_over = true
	total_runs += 1
	if won:
		total_wins += 1
	best_kills = max(best_kills, kills)
	best_time = max(best_time, elapsed)
	announcement_text = "CORE SECURED" if won else "SIGNAL LOST"
	announcement_time = 4.0 if won else 2.0
	if won:
		screen_shake = 18.0
		play_sfx("victory")
	else:
		play_sfx("damage")
	save_progress()

func return_to_title() -> void:
	game_started = false
	game_paused = false
	game_over = false
	choosing_upgrade = false
	announcement_text = ""
	announcement_time = 0.0

func setup_audio() -> void:
	var audio_files := {
		"shoot": "res://assets/audio/shoot.wav",
		"hit": "res://assets/audio/hit.wav",
		"pickup": "res://assets/audio/pickup.wav",
		"upgrade": "res://assets/audio/upgrade.wav",
		"boss": "res://assets/audio/boss.wav",
		"damage": "res://assets/audio/damage.wav",
		"victory": "res://assets/audio/victory.wav"
	}
	for key in audio_files:
		var player := AudioStreamPlayer.new()
		player.stream = load(audio_files[key])
		player.volume_db = -10.0 if key == "shoot" else -6.0
		add_child(player)
		sfx[key] = player

func play_sfx(key: String) -> void:
	if not sound_enabled or not sfx.has(key):
		return
	var player: AudioStreamPlayer = sfx[key]
	player.play()

func create_starfield() -> void:
	var generator := RandomNumberGenerator.new()
	generator.seed = 73421
	for i in range(80):
		stars.append({
			"pos": Vector2(generator.randf_range(0.0, SCREEN.x), generator.randf_range(74.0, SCREEN.y)),
			"size": generator.randf_range(0.7, 2.1),
			"phase": generator.randf_range(0.0, TAU)
		})

func start_game() -> void:
	reset_game()
	game_started = true
	game_paused = false
	tutorial_step = -1 if tutorial_completed else 0
	announcement_text = "DEFEND THE CORE"
	announcement_time = 2.2
	play_sfx("upgrade")

func advance_tutorial(expected_step: int) -> void:
	if tutorial_completed or tutorial_step != expected_step:
		return
	tutorial_step += 1
	if tutorial_step >= 4:
		tutorial_completed = true
		tutorial_step = -1
		announcement_text = "TRAINING COMPLETE"
		announcement_time = 2.0
		save_progress()

func update_feedback(delta: float) -> void:
	screen_shake = max(0.0, screen_shake - delta * 24.0)
	player_flash = max(0.0, player_flash - delta)
	core_flash = max(0.0, core_flash - delta)
	announcement_time = max(0.0, announcement_time - delta)
	for i in range(damage_numbers.size() - 1, -1, -1):
		damage_numbers[i]["pos"] += Vector2(0.0, -34.0) * delta
		damage_numbers[i]["life"] -= delta
		if damage_numbers[i]["life"] <= 0.0:
			damage_numbers.remove_at(i)

func setup_arena_features() -> void:
	obstacles = [
		{"pos": Vector2(420, 245), "radius": 34.0},
		{"pos": Vector2(860, 245), "radius": 34.0},
		{"pos": Vector2(420, 505), "radius": 34.0},
		{"pos": Vector2(860, 505), "radius": 34.0},
		{"pos": Vector2(250, 360), "radius": 30.0},
		{"pos": Vector2(1030, 360), "radius": 30.0}
	]
	hazards = [
		{"type": "corrosion", "pos": Vector2(250, 570), "radius": 82.0},
		{"type": "slow", "pos": Vector2(1030, 570), "radius": 92.0}
	]
	terminals = [
		{"id": "repair", "name": "CORE REPAIR", "pos": Vector2(120, 170), "cooldown": 0.0, "max_cd": 45.0, "color": Color("64ff9d")},
		{"id": "weapon", "name": "OVERCHARGE", "pos": Vector2(1160, 170), "cooldown": 0.0, "max_cd": 60.0, "color": Color("ffcf70")},
		{"id": "supply", "name": "MED STATION", "pos": Vector2(640, 650), "cooldown": 0.0, "max_cd": 40.0, "color": Color("72f8ff")}
	]
	defense_modules = [
		{"pos": Vector2(640, 255), "type": "", "level": 0, "cooldown": 0.0},
		{"pos": Vector2(550, 415), "type": "", "level": 0, "cooldown": 0.0},
		{"pos": Vector2(730, 415), "type": "", "level": 0, "cooldown": 0.0}
	]

func update_defense_modules(delta: float) -> void:
	for module in defense_modules:
		if module["type"].is_empty():
			continue
		module["cooldown"] = max(0.0, module["cooldown"] - delta)
		if module["type"] == "repair":
			if module["cooldown"] <= 0.0 and core_hp < 300.0:
				core_hp = min(300.0, core_hp + 2.0 + float(module["level"]) * 1.5)
				module["cooldown"] = max(1.5, 4.0 - float(module["level"]) * 0.35)
				create_spark(CORE_POS, Color("64ff9d"), 5)
		elif module["type"] == "turret" and module["cooldown"] <= 0.0:
			var target_index := find_nearest_enemy(module["pos"], 270.0 + float(module["level"]) * 18.0)
			if target_index >= 0:
				var target_pos: Vector2 = enemies[target_index]["pos"]
				append_arc_effect(module["pos"], target_pos, 0.10)
				damage_enemy(target_index, 8.0 + float(module["level"]) * 4.0)
				module["cooldown"] = max(0.24, 0.80 - float(module["level"]) * 0.08)

func find_nearest_enemy(origin: Vector2, search_range: float) -> int:
	var target_index := -1
	var best_distance := search_range * search_range
	for i in range(enemies.size()):
		var distance: float = origin.distance_squared_to(enemies[i]["pos"])
		if distance < best_distance:
			best_distance = distance
			target_index = i
	return target_index

func defense_slow_multiplier(pos: Vector2) -> float:
	var multiplier := 1.0
	for module in defense_modules:
		if module["type"] != "slow":
			continue
		var effect_range: float = 125.0 + float(module["level"]) * 18.0
		if pos.distance_to(module["pos"]) < effect_range:
			multiplier = min(multiplier, max(0.38, 0.72 - float(module["level"]) * 0.06))
	return multiplier

func install_defense_module(module_type: String) -> void:
	for module in defense_modules:
		if module["type"] == module_type:
			module["level"] = min(5, int(module["level"]) + 1)
			return
	for module in defense_modules:
		if module["type"].is_empty():
			module["type"] = module_type
			module["level"] = 1
			module["cooldown"] = 0.0
			return

func update_arena_features(delta: float) -> void:
	damage_boost_timer = max(0.0, damage_boost_timer - delta)
	hazard_tick -= delta
	nearby_terminal = ""
	for terminal in terminals:
		terminal["cooldown"] = max(0.0, terminal["cooldown"] - delta)
		if player_pos.distance_to(terminal["pos"]) < 58.0:
			nearby_terminal = terminal["id"]
	for hazard in hazards:
		if hazard["type"] == "corrosion" and player_pos.distance_to(hazard["pos"]) < hazard["radius"]:
			if hazard_tick <= 0.0:
				player_hp -= 5.0
				player_flash = 0.16
				hazard_tick = 0.55
	event_timer -= delta
	if event_timer <= 0.0 and not boss_alive:
		trigger_random_event()
		event_timer = randf_range(68.0, 88.0)

func activate_nearby_terminal() -> void:
	if nearby_terminal.is_empty():
		return
	for terminal in terminals:
		if terminal["id"] != nearby_terminal:
			continue
		if terminal["cooldown"] > 0.0:
			announcement_text = terminal["name"] + " RECHARGING"
			announcement_time = 1.2
			return
		if terminal["id"] == "repair":
			if selected_mode == "challenge":
				announcement_text = "REPAIR TERMINAL OFFLINE"
				announcement_time = 1.5
				return
			core_hp = min(300.0, core_hp + 75.0)
			announcement_text = "CORE INTEGRITY RESTORED"
		elif terminal["id"] == "weapon":
			damage_boost_timer = 25.0
			announcement_text = "WEAPONS OVERCHARGED"
		else:
			player_hp = min(player_max_hp, player_hp + 55.0)
			announcement_text = "ARMOR RESTORED"
		terminal["cooldown"] = terminal["max_cd"]
		if rare_terminal_mastery:
			terminal_damage_bonus += 0.05
			shot_damage *= 1.05
		announcement_time = 1.8
		create_spark(terminal["pos"], terminal["color"], 16)
		play_sfx("upgrade")
		advance_tutorial(3)
		return

func trigger_random_event() -> void:
	var event_id := randi() % 3
	if event_id == 0:
		announcement_text = "EVENT: CORE ASSAULT"
		for i in range(7):
			spawn_enemy()
	elif event_id == 1:
		announcement_text = "EVENT: ELITE SIGNAL"
		spawn_enemy(true)
	else:
		announcement_text = "EVENT: SYSTEM RECHARGE"
		for terminal in terminals:
			terminal["cooldown"] = 0.0
	announcement_time = 2.5
	play_sfx("boss")

func update_player(delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction.length_squared() > 0.01:
		advance_tutorial(0)
	var speed_factor := 1.0
	for hazard in hazards:
		if hazard["type"] == "slow" and player_pos.distance_to(hazard["pos"]) < hazard["radius"]:
			speed_factor = 0.58
	player_pos += direction * player_speed * speed_factor * delta
	player_pos.x = clamp(player_pos.x, 28.0, SCREEN.x - 28.0)
	player_pos.y = clamp(player_pos.y, 82.0, SCREEN.y - 28.0)
	resolve_player_obstacles()

func resolve_player_obstacles() -> void:
	for obstacle in obstacles:
		var minimum_distance: float = obstacle["radius"] + PLAYER_RADIUS + 3.0
		var offset: Vector2 = player_pos - obstacle["pos"]
		if offset.length() < minimum_distance:
			if offset.length_squared() < 0.01:
				offset = Vector2.RIGHT
			player_pos = obstacle["pos"] + offset.normalized() * minimum_distance

func steer_around_obstacles(pos: Vector2, desired: Vector2, body_radius: float) -> Vector2:
	var steering := desired
	for obstacle in obstacles:
		var offset: Vector2 = pos - obstacle["pos"]
		var avoid_distance: float = obstacle["radius"] + body_radius + 42.0
		if offset.length() < avoid_distance:
			var strength: float = 1.0 - offset.length() / avoid_distance
			steering += offset.normalized() * strength * 2.4
	return steering.normalized()

func resolve_enemy_obstacle(index: int) -> void:
	if index < 0 or index >= enemies.size():
		return
	for obstacle in obstacles:
		var minimum_distance: float = obstacle["radius"] + enemies[index]["radius"] + 2.0
		var offset: Vector2 = enemies[index]["pos"] - obstacle["pos"]
		if offset.length() < minimum_distance:
			if offset.length_squared() < 0.01:
				offset = Vector2.RIGHT
			enemies[index]["pos"] = obstacle["pos"] + offset.normalized() * minimum_distance

func update_spawning(delta: float) -> void:
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_enemy()
		if elapsed > 75.0 and randf() < 0.35:
			spawn_enemy()
		spawn_timer = max(0.30, 1.10 - elapsed * 0.0045)

func update_boss_schedule() -> void:
	if not boss_alive and elapsed >= next_boss_time:
		spawn_boss()

func spawn_boss() -> void:
	if enemies.size() >= MAX_ENEMIES:
		enemies.pop_front()
	boss_spawned = true
	boss_alive = true
	boss_max_hp = 1650.0 * (1.0 + float(boss_wave - 1) * 0.55)
	announcement_text = "WARNING: TITAN SIGNAL"
	announcement_time = 3.0
	screen_shake = 14.0
	play_sfx("boss")
	enemies.append({
		"pos": Vector2(SCREEN.x * 0.5, 92.0),
		"hp": boss_max_hp,
		"speed": 56.0,
		"radius": 46.0,
		"damage": 20.0 + float(boss_wave - 1) * 5.0,
		"type": "boss",
		"hit_cd": 0.0,
		"orbit_cd": 0.0,
		"charge_cd": 3.5,
		"charge_time": 0.0,
		"charge_dir": Vector2.ZERO,
		"summon_cd": 5.0
	})

func spawn_enemy(elite: bool = false) -> void:
	if enemies.size() >= MAX_ENEMIES:
		return
	var side := randi() % 4
	var pos := Vector2.ZERO
	match side:
		0: pos = Vector2(randf_range(0.0, SCREEN.x), 72.0)
		1: pos = Vector2(SCREEN.x - 8.0, randf_range(72.0, SCREEN.y))
		2: pos = Vector2(randf_range(0.0, SCREEN.x), SCREEN.y - 8.0)
		_: pos = Vector2(8.0, randf_range(72.0, SCREEN.y))
	var roll := randf()
	var enemy_type := "normal"
	var enemy_hp := 25.0 + elapsed * 0.08
	var enemy_speed := 76.0
	var enemy_radius := 15.0
	var enemy_damage := 7.0
	if elapsed > 25.0 and roll < 0.28:
		enemy_type = "fast"
		enemy_hp = 15.0 + elapsed * 0.045
		enemy_speed = 145.0
		enemy_radius = 10.0
		enemy_damage = 5.0
	elif elapsed > 80.0 and roll > 0.82:
		enemy_type = "heavy"
		enemy_hp = 75.0 + elapsed * 0.16
		enemy_speed = 48.0
		enemy_radius = 22.0
		enemy_damage = 14.0
	var affix := ""
	if elite:
		enemy_type = "elite"
		enemy_hp = 220.0 + elapsed * 0.22
		enemy_speed = 82.0
		enemy_radius = 27.0
		enemy_damage = 18.0
		affix = ["shield", "split", "frenzy", "healer", "explosive"].pick_random()
	if selected_mode == "challenge":
		enemy_speed *= 1.25
	enemies.append({
		"pos": pos,
		"hp": enemy_hp,
		"speed": enemy_speed,
		"radius": enemy_radius,
		"damage": enemy_damage,
		"type": enemy_type,
		"hit_cd": 0.0,
		"orbit_cd": 0.0,
		"affix": affix,
		"shield": 100.0 if affix == "shield" else 0.0,
		"heal_cd": 2.0
	})

func spawn_enemy_at(pos: Vector2, elite: bool = false) -> void:
	var before := enemies.size()
	spawn_enemy(elite)
	if enemies.size() > before:
		enemies[-1]["pos"] = pos

func spawn_enemy_nests() -> void:
	for pos in [Vector2(105, 570), Vector2(1175, 570)]:
		if enemies.size() >= MAX_ENEMIES:
			return
		enemies.append({"pos": pos, "hp": 340.0, "speed": 0.0, "radius": 32.0, "damage": 0.0, "type": "nest", "hit_cd": 0.0, "orbit_cd": 0.0, "spawn_cd": randf_range(5.0, 8.0), "affix": "", "shield": 0.0, "heal_cd": 0.0})

func update_shooting(delta: float) -> void:
	shot_timer -= delta
	if shot_timer > 0.0 or enemies.is_empty():
		return
	var nearest_index := -1
	var nearest_distance := INF
	for i in range(enemies.size()):
		var distance: float = player_pos.distance_squared_to(enemies[i]["pos"])
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_index = i
	if nearest_index >= 0:
		var base_direction: Vector2 = (enemies[nearest_index]["pos"] - player_pos).normalized()
		for i in range(projectile_count):
			if bullets.size() >= MAX_BULLETS:
				break
			var spread := (float(i) - float(projectile_count - 1) * 0.5) * 0.14
			var direction := base_direction.rotated(spread)
			var boosted_damage := shot_damage * (1.35 if damage_boost_timer > 0.0 else 1.0)
			bullets.append({"pos": player_pos, "velocity": direction * 590.0, "life": 1.3, "damage": boosted_damage})
		shot_timer = shot_interval
		play_sfx("shoot")

func update_arc_weapon(delta: float) -> void:
	if arc_level <= 0 or enemies.is_empty():
		return
	arc_timer -= delta
	if arc_timer > 0.0:
		return
	var current_pos := player_pos
	var hit_targets: Array[Dictionary] = []
	var jumps: int = min(4, 1 + arc_level)
	for jump in range(jumps):
		var target_index := -1
		var best_distance := 330.0 * 330.0
		for i in range(enemies.size()):
			if hit_targets.has(enemies[i]):
				continue
			var distance: float = current_pos.distance_squared_to(enemies[i]["pos"])
			if distance < best_distance:
				best_distance = distance
				target_index = i
		if target_index < 0:
			break
		var target_ref: Dictionary = enemies[target_index]
		var target_pos: Vector2 = target_ref["pos"]
		hit_targets.append(target_ref)
		append_arc_effect(current_pos, target_pos, 0.16)
		var arc_damage := 6.0 + float(arc_level) * 3.5
		damage_enemy(target_index, arc_damage)
		current_pos = target_pos
	arc_timer = max(0.48, 1.35 - float(arc_level) * 0.12)

func chain_from(origin: Vector2, excluded_index: int, damage: float, jumps: int) -> void:
	var current_pos := origin
	for jump in range(jumps):
		var target_index := -1
		var best_distance := 150.0 * 150.0
		for i in range(enemies.size()):
			if i == excluded_index:
				continue
			var distance: float = current_pos.distance_squared_to(enemies[i]["pos"])
			if distance < best_distance:
				best_distance = distance
				target_index = i
		if target_index < 0:
			return
		var target_pos: Vector2 = enemies[target_index]["pos"]
		append_arc_effect(current_pos, target_pos, 0.13)
		damage_enemy(target_index, damage)
		current_pos = target_pos

func update_orbit_weapon(delta: float) -> void:
	if orbit_level <= 0:
		return
	var orbit_speed := 2.4 + float(orbit_level) * 0.18
	var orbit_radius := 68.0
	var orbit_damage := 7.0 + float(orbit_level) * 4.0
	if overload_blade_active:
		orbit_speed *= 1.45
		orbit_radius = 88.0
		orbit_damage *= 1.7
	orbit_angle += delta * orbit_speed
	var blade_count: int = min(3, orbit_level)
	for i in range(enemies.size() - 1, -1, -1):
		enemies[i]["orbit_cd"] = max(0.0, enemies[i]["orbit_cd"] - delta)
		if enemies[i]["orbit_cd"] > 0.0:
			continue
		for blade_index in range(blade_count):
			var angle := orbit_angle + TAU * float(blade_index) / float(blade_count)
			var blade_pos := player_pos + Vector2.from_angle(angle) * orbit_radius
			if blade_pos.distance_to(enemies[i]["pos"]) < enemies[i]["radius"] + 13.0:
				enemies[i]["orbit_cd"] = 0.34
				create_spark(blade_pos, Color("ffba61"), 4)
				damage_enemy(i, orbit_damage)
				break

func update_bullets(delta: float) -> void:
	for i in range(bullets.size() - 1, -1, -1):
		bullets[i]["pos"] += bullets[i]["velocity"] * delta
		bullets[i]["life"] -= delta
		var hit := false
		for j in range(enemies.size() - 1, -1, -1):
			var hit_range: float = enemies[j]["radius"] + 5.0
			if bullets[i]["pos"].distance_squared_to(enemies[j]["pos"]) <= hit_range * hit_range:
				create_spark(bullets[i]["pos"], Color("70f6ff"))
				var hit_pos: Vector2 = enemies[j]["pos"]
				var killed := damage_enemy(j, bullets[i]["damage"])
				if chain_pulse_active and not killed:
					chain_from(hit_pos, j, shot_damage * 0.45, 1)
				hit = true
				break
		if hit or bullets[i]["life"] <= 0.0:
			bullets.remove_at(i)

func damage_enemy(index: int, amount: float) -> bool:
	if index < 0 or index >= enemies.size():
		return false
	if float(enemies[index].get("shield", 0.0)) > 0.0:
		var absorbed: float = min(amount, float(enemies[index]["shield"]))
		enemies[index]["shield"] -= absorbed
		amount -= absorbed
		create_spark(enemies[index]["pos"], Color("72f8ff"), 4)
		if amount <= 0.0:
			return false
	var number_pos: Vector2 = enemies[index]["pos"] + Vector2(randf_range(-7.0, 7.0), -12.0)
	if damage_numbers.size() >= MAX_DAMAGE_NUMBERS:
		damage_numbers.pop_front()
	damage_numbers.append({"pos": number_pos, "value": int(round(amount)), "life": 0.55, "color": enemy_color(enemies[index]["type"])})
	enemies[index]["hp"] -= amount
	play_sfx("hit")
	if enemies[index]["hp"] > 0.0:
		return false
	var dead_pos: Vector2 = enemies[index]["pos"]
	var dead_type: String = enemies[index]["type"]
	var dead_affix: String = enemies[index].get("affix", "")
	var orb_value := 1
	if dead_type == "heavy":
		orb_value = 2
	elif dead_type == "elite":
		orb_value = 5
	elif dead_type == "boss":
		orb_value = 12
	elif dead_type == "nest":
		orb_value = 8
	if xp_orbs.size() >= MAX_XP_ORBS:
		xp_orbs.pop_front()
	xp_orbs.append({"pos": dead_pos, "value": orb_value})
	create_spark(dead_pos, enemy_color(dead_type), 12 if dead_type == "boss" else 9)
	enemies.remove_at(index)
	kills += 1
	if rare_vampiric and kills % 12 == 0:
		player_hp = min(player_max_hp, player_hp + 18.0)
	if dead_affix == "split":
		for offset in [Vector2(-18, 0), Vector2(18, 0), Vector2(0, 18)]:
			spawn_enemy_at(dead_pos + offset)
	elif dead_affix == "explosive":
		if dead_pos.distance_to(player_pos) < 145.0:
			player_hp -= 22.0
		if dead_pos.distance_to(CORE_POS) < 145.0:
			damage_core(22.0)
		create_spark(dead_pos, Color("ff6b4a"), 28)
	if dead_type == "boss":
		boss_alive = false
		if selected_mode == "endless":
			boss_wave += 1
			next_boss_time = elapsed + 180.0
			announcement_text = "TITAN DESTROYED // WAVE %d INCOMING" % boss_wave
			announcement_time = 3.0
		else:
			finish_run(true)
	return true

func damage_core(amount: float) -> void:
	core_hp -= amount
	if rare_reactive and reactive_cooldown <= 0.0:
		reactive_cooldown = 8.0
		for i in range(enemies.size() - 1, -1, -1):
			if enemies[i]["type"] != "nest" and enemies[i]["pos"].distance_to(CORE_POS) < 250.0:
				damage_enemy(i, 70.0)
		append_arc_effect(CORE_POS + Vector2(-100, 0), CORE_POS + Vector2(100, 0), 0.3)

func update_enemies(delta: float) -> void:
	for i in range(enemies.size() - 1, -1, -1):
		if i >= enemies.size():
			continue
		enemies[i]["hit_cd"] = max(0.0, enemies[i]["hit_cd"] - delta)
		if enemies[i]["type"] == "nest":
			enemies[i]["spawn_cd"] -= delta
			if enemies[i]["spawn_cd"] <= 0.0:
				spawn_enemy_at(enemies[i]["pos"] + Vector2(randf_range(-35, 35), randf_range(-35, 35)))
				enemies[i]["spawn_cd"] = max(3.2, 7.5 - elapsed * 0.006)
			continue
		elif enemies[i]["type"] == "boss":
			update_boss_enemy(i, delta)
		else:
			var to_player: float = enemies[i]["pos"].distance_to(player_pos)
			var target := player_pos if to_player < 220.0 else CORE_POS
			var direction: Vector2 = (target - enemies[i]["pos"]).normalized()
			direction = steer_around_obstacles(enemies[i]["pos"], direction, enemies[i]["radius"])
			var slow_multiplier := defense_slow_multiplier(enemies[i]["pos"])
			if enemies[i].get("affix", "") == "frenzy" and float(enemies[i]["hp"]) < 110.0:
				slow_multiplier *= 1.65
			enemies[i]["pos"] += direction * float(enemies[i]["speed"]) * slow_multiplier * delta
			resolve_enemy_obstacle(i)
			if enemies[i].get("affix", "") == "healer":
				enemies[i]["heal_cd"] -= delta
				if enemies[i]["heal_cd"] <= 0.0:
					for ally in enemies:
						if ally["pos"].distance_to(enemies[i]["pos"]) < 135.0:
							ally["hp"] += 9.0
					enemies[i]["heal_cd"] = 2.0
		if enemies[i]["hit_cd"] <= 0.0:
			if enemies[i]["pos"].distance_to(player_pos) < float(enemies[i]["radius"]) + PLAYER_RADIUS:
				player_hp -= enemies[i]["damage"]
				enemies[i]["hit_cd"] = 0.65
				create_spark(player_pos, Color("ff476f"), 5)
				player_flash = 0.22
				screen_shake = max(screen_shake, 7.0)
				play_sfx("damage")
			elif enemies[i]["pos"].distance_to(CORE_POS) < float(enemies[i]["radius"]) + CORE_RADIUS:
				var core_damage: float = enemies[i]["damage"]
				enemies[i]["hit_cd"] = 0.65
				create_spark(CORE_POS, Color("ffb347"), 5)
				core_flash = 0.22
				screen_shake = max(screen_shake, 5.0)
				play_sfx("damage")
				damage_core(core_damage)

func update_boss_enemy(index: int, delta: float) -> void:
	if index < 0 or index >= enemies.size():
		return
	enemies[index]["charge_cd"] -= delta
	enemies[index]["summon_cd"] -= delta
	if enemies[index]["summon_cd"] <= 0.0:
		for i in range(3):
			spawn_enemy()
		enemies[index]["summon_cd"] = 6.0
		create_spark(enemies[index]["pos"], Color("c06cff"), 14)
	if enemies[index]["charge_time"] > 0.0:
		enemies[index]["charge_time"] -= delta
		enemies[index]["pos"] += enemies[index]["charge_dir"] * 285.0 * delta
	else:
		var target := CORE_POS
		if enemies[index]["pos"].distance_to(player_pos) < 280.0:
			target = player_pos
		var direction: Vector2 = (target - enemies[index]["pos"]).normalized()
		direction = steer_around_obstacles(enemies[index]["pos"], direction, enemies[index]["radius"])
		enemies[index]["charge_dir"] = direction
		enemies[index]["pos"] += direction * enemies[index]["speed"] * defense_slow_multiplier(enemies[index]["pos"]) * delta
		if enemies[index]["charge_cd"] <= 0.0:
			enemies[index]["charge_dir"] = direction
			enemies[index]["charge_time"] = 0.72
			enemies[index]["charge_cd"] = 4.2
	enemies[index]["pos"].x = clamp(enemies[index]["pos"].x, 18.0, SCREEN.x - 18.0)
	enemies[index]["pos"].y = clamp(enemies[index]["pos"].y, 82.0, SCREEN.y - 18.0)
	resolve_enemy_obstacle(index)

func create_spark(pos: Vector2, color: Color, count: int = 4) -> void:
	for i in range(count):
		if sparks.size() >= MAX_SPARKS:
			sparks.pop_front()
		var angle := randf() * TAU
		sparks.append({
			"pos": pos,
			"velocity": Vector2.from_angle(angle) * randf_range(45.0, 150.0),
			"life": randf_range(0.18, 0.45),
			"color": color
		})

func append_arc_effect(from: Vector2, to: Vector2, life: float) -> void:
	if arc_effects.size() >= MAX_ARC_EFFECTS:
		arc_effects.pop_front()
	arc_effects.append({"from": from, "to": to, "life": life})

func update_xp_orbs(delta: float) -> void:
	for i in range(xp_orbs.size() - 1, -1, -1):
		var distance: float = xp_orbs[i]["pos"].distance_to(player_pos)
		if distance < pickup_radius:
			var direction: Vector2 = (player_pos - xp_orbs[i]["pos"]).normalized()
			xp_orbs[i]["pos"] += direction * 430.0 * delta
		if xp_orbs[i]["pos"].distance_to(player_pos) < PLAYER_RADIUS + 9.0:
			gain_xp(xp_orbs[i]["value"])
			play_sfx("pickup")
			xp_orbs.remove_at(i)

func gain_xp(amount: int) -> void:
	xp += amount
	advance_tutorial(1)
	if xp >= xp_needed and not choosing_upgrade:
		xp -= xp_needed
		level += 1
		xp_needed = 5 + level * 3
		open_upgrade_menu()

func open_upgrade_menu() -> void:
	choosing_upgrade = true
	announcement_text = "SYSTEM UPGRADE AVAILABLE"
	announcement_time = 1.2
	upgrade_options.clear()
	for upgrade in upgrades:
		upgrade_options.append(upgrade.duplicate(true))
	upgrade_options.shuffle()
	upgrade_options.resize(3)
	if randf() < 0.12:
		upgrade_options[randi() % 3] = rare_upgrades.pick_random().duplicate(true)
	if level == 2:
		upgrade_options[0] = upgrades[7].duplicate(true)
	elif level == 3:
		upgrade_options[0] = upgrades[8].duplicate(true)

func choose_upgrade(index: int) -> void:
	if not choosing_upgrade or index < 0 or index >= upgrade_options.size():
		return
	var upgrade_id: String = upgrade_options[index]["id"]
	if upgrade_id == "damage":
		shot_damage *= 1.25
		damage_upgrade_count += 1
	elif upgrade_id == "fire_rate":
		shot_interval = max(0.12, shot_interval * 0.85)
		fire_rate_upgrade_count += 1
	elif upgrade_id == "speed":
		player_speed *= 1.12
	elif upgrade_id == "armor":
		player_max_hp += 20.0
		player_hp = min(player_max_hp, player_hp + 35.0)
	elif upgrade_id == "multishot":
		projectile_count = min(5, projectile_count + 1)
		multishot_upgrade_count += 1
	elif upgrade_id == "magnet":
		pickup_radius *= 1.35
	elif upgrade_id == "energy":
		energy_level += 1
		shot_damage *= 1.12
	elif upgrade_id == "arc":
		arc_level = min(5, arc_level + 1)
	elif upgrade_id == "orbit":
		orbit_level = min(5, orbit_level + 1)
	elif upgrade_id == "defense_turret":
		install_defense_module("turret")
	elif upgrade_id == "defense_slow":
		install_defense_module("slow")
	elif upgrade_id == "defense_repair":
		install_defense_module("repair")
	elif upgrade_id == "execution_protocol":
		rare_execution = true
		shot_damage *= 1.60
		player_max_hp = max(35.0, player_max_hp - 25.0)
		player_hp = min(player_hp, player_max_hp)
	elif upgrade_id == "reactive_core":
		rare_reactive = true
	elif upgrade_id == "vampiric_cells":
		rare_vampiric = true
	elif upgrade_id == "terminal_mastery":
		rare_terminal_mastery = true
	refresh_fusions()
	advance_tutorial(2)
	play_sfx("upgrade")
	announcement_text = upgrade_options[index]["name"] + " INSTALLED"
	announcement_time = 1.5
	choosing_upgrade = false
	upgrade_options.clear()

func refresh_fusions() -> void:
	chain_pulse_active = arc_level >= 1 and multishot_upgrade_count >= 1
	overload_blade_active = orbit_level >= 1 and damage_upgrade_count >= 1 and fire_rate_upgrade_count >= 1

func build_fusion_name() -> String:
	if chain_pulse_active and overload_blade_active:
		return "Chain Pulse + Overload Blade"
	if chain_pulse_active:
		return "Chain Pulse"
	if overload_blade_active:
		return "Overload Blade"
	return "No Fusion"

func enemy_color(enemy_type: String) -> Color:
	if enemy_type == "nest":
		return Color("ff673d")
	if enemy_type == "boss":
		return Color("d94dff")
	if enemy_type == "fast":
		return Color("ff4f73")
	if enemy_type == "heavy":
		return Color("c06cff")
	if enemy_type == "elite":
		return Color("ffcf70")
	return Color("ff8a5b")

func update_sparks(delta: float) -> void:
	for i in range(sparks.size() - 1, -1, -1):
		sparks[i]["pos"] += sparks[i]["velocity"] * delta
		sparks[i]["life"] -= delta
		if sparks[i]["life"] <= 0.0:
			sparks.remove_at(i)

func update_arc_effects(delta: float) -> void:
	for i in range(arc_effects.size() - 1, -1, -1):
		arc_effects[i]["life"] -= delta
		if arc_effects[i]["life"] <= 0.0:
			arc_effects.remove_at(i)

func reset_game() -> void:
	player_pos = Vector2(640.0, 470.0)
	player_hp = 100.0
	player_max_hp = 100.0
	player_speed = 270.0
	pickup_radius = 70.0
	core_hp = 1.0 if selected_mode == "challenge" else 300.0
	elapsed = 0.0
	spawn_timer = 0.0
	shot_timer = 0.0
	shot_damage = 12.0
	shot_interval = 0.42
	projectile_count = 1
	arc_level = 0
	orbit_level = 0
	energy_level = 1
	damage_upgrade_count = 0
	fire_rate_upgrade_count = 0
	multishot_upgrade_count = 0
	arc_timer = 0.0
	orbit_angle = 0.0
	boss_spawned = false
	boss_alive = false
	boss_max_hp = 1.0
	boss_wave = 1
	next_boss_time = BOSS_TIME
	rare_execution = false
	rare_reactive = false
	rare_vampiric = false
	rare_terminal_mastery = false
	reactive_cooldown = 0.0
	terminal_damage_bonus = 0.0
	chain_pulse_active = false
	overload_blade_active = false
	event_timer = 55.0
	damage_boost_timer = 0.0
	hazard_tick = 0.0
	nearby_terminal = ""
	screen_shake = 0.0
	player_flash = 0.0
	core_flash = 0.0
	announcement_text = ""
	announcement_time = 0.0
	kills = 0
	level = 1
	xp = 0
	xp_needed = 6
	game_over = false
	victory = false
	choosing_upgrade = false
	result_recorded = false
	stage_index = 0
	enemies.clear()
	bullets.clear()
	sparks.clear()
	arc_effects.clear()
	xp_orbs.clear()
	upgrade_options.clear()
	damage_numbers.clear()
	for terminal in terminals:
		terminal["cooldown"] = 0.0
	for module in defense_modules:
		module["type"] = ""
		module["level"] = 0
		module["cooldown"] = 0.0
	for i in range(6):
		spawn_enemy()
	spawn_enemy_nests()

func _draw() -> void:
	draw_starfield()
	if not game_started:
		draw_title_screen()
		return
	var shake_offset := Vector2.ZERO
	if screen_shake_enabled and screen_shake > 0.0:
		shake_offset = Vector2(randf_range(-screen_shake, screen_shake), randf_range(-screen_shake, screen_shake))
	draw_set_transform(shake_offset)
	# arena grid
	for x in range(0, 1281, 64):
		draw_line(Vector2(x, 70), Vector2(x, 720), Color(0.08, 0.13, 0.22, 0.55), 1.0)
	for y in range(80, 721, 64):
		draw_line(Vector2(0, y), Vector2(1280, y), Color(0.08, 0.13, 0.22, 0.55), 1.0)
	draw_arena_features()

	# header
	draw_rect(Rect2(0, 0, 1280, 70), Color("10182b"))
	draw_string(ThemeDB.fallback_font, Vector2(26, 33), "LAST DEFENSE  //  PRESENTATION BUILD", HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color("d9f5ff"))
	draw_string(ThemeDB.fallback_font, Vector2(26, 57), "Move: WASD / Arrows  •  E terminal  •  ESC pause  •  M sound", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("8198b8"))
	draw_string(ThemeDB.fallback_font, Vector2(500, 33), stage_name(), HORIZONTAL_ALIGNMENT_CENTER, 390, 16, Color("b5c9e8"))
	var remaining: int = max(0, int(BOSS_TIME - elapsed))
	if selected_mode == "endless":
		remaining = max(0, int(next_boss_time - elapsed))
	var objective_text := "BOSS IN %02d:%02d" % [int(remaining / 60.0), remaining % 60]
	if boss_spawned:
		objective_text = "DEFEAT THE BOSS"
	draw_string(ThemeDB.fallback_font, Vector2(930, 34), objective_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("9bdcff"))
	draw_string(ThemeDB.fallback_font, Vector2(1145, 34), "KILLS  %d" % kills, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("ffca7a"))

	# defense core
	var core_pulse := 70.0 + sin(animation_time * 3.2) * 4.0
	draw_circle(CORE_POS, core_pulse, Color(0.1, 0.55, 0.85, 0.07))
	draw_arc(CORE_POS, core_pulse, 0.0, TAU, 64, Color(0.18, 0.66, 0.92, 0.32), 2.0)
	draw_texture_centered(core_texture, CORE_POS, 112.0, Color("fff3a6") if core_flash > 0.0 else Color.WHITE)
	draw_string(ThemeDB.fallback_font, CORE_POS + Vector2(-42, 92), "ENERGY CORE", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("71dfff"))
	draw_bar(Vector2(535, 466), 210.0, core_hp / 300.0, Color("35c9ff"), "CORE %d" % max(0, int(core_hp)))
	draw_defense_modules()

	# entities
	for orb in xp_orbs:
		draw_circle(orb["pos"], 8.0, Color(0.3, 1.0, 0.55, 0.15))
		draw_circle(orb["pos"], 4.0, Color("64ff9d"))
	for enemy in enemies:
		var color := enemy_color(enemy["type"])
		draw_circle(enemy["pos"], enemy["radius"] + 4.0, Color(color, 0.13))
		if enemy["type"] == "nest":
			draw_circle(enemy["pos"], 31.0 + sin(animation_time * 4.0) * 3.0, Color("ff673d"))
			draw_arc(enemy["pos"], 42.0, animation_time, TAU + animation_time, 16, Color("ffcf70"), 4.0)
			draw_string(ThemeDB.fallback_font, enemy["pos"] + Vector2(-30, 58), "NEST", HORIZONTAL_ALIGNMENT_CENTER, 60, 12, Color("ffcf70"))
		elif enemy["type"] == "boss":
			if enemy["charge_time"] <= 0.0 and enemy["charge_cd"] < 1.0:
				var warning_end: Vector2 = enemy["pos"] + enemy["charge_dir"] * 520.0
				draw_line(enemy["pos"], warning_end, Color(1.0, 0.15, 0.42, 0.25 + sin(animation_time * 16.0) * 0.12), 18.0)
				draw_line(enemy["pos"], warning_end, Color("ff4778"), 2.0)
			draw_texture_centered(boss_texture, enemy["pos"], 154.0)
		elif enemy["type"] == "heavy":
			draw_texture_centered(enemy_heavy_texture, enemy["pos"], 76.0)
		elif enemy["type"] == "elite":
			draw_texture_centered(enemy_heavy_texture, enemy["pos"], 90.0, Color(1.2, 1.0, 0.52, 1.0))
			var affix_color: Color = {"shield": Color("72f8ff"), "split": Color("64ff9d"), "frenzy": Color("ff476f"), "healer": Color("b6ff70"), "explosive": Color("ff7b3d")}.get(enemy.get("affix", ""), Color.WHITE)
			draw_arc(enemy["pos"], 36.0, 0.0, TAU, 32, affix_color, 3.0)
			draw_string(ThemeDB.fallback_font, enemy["pos"] + Vector2(-40, 48), str(enemy.get("affix", "")).to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 80, 10, affix_color)
		elif enemy["type"] == "fast":
			draw_texture_centered(enemy_normal_texture, enemy["pos"], 42.0, Color(1.2, 0.62, 0.72, 1.0))
		else:
			draw_texture_centered(enemy_normal_texture, enemy["pos"], 52.0)
	for bullet in bullets:
		draw_circle(bullet["pos"], 8.0, Color(0.2, 0.95, 1.0, 0.17))
		draw_circle(bullet["pos"], 4.0, Color("72f8ff"))
	for spark in sparks:
		draw_circle(spark["pos"], 3.0, spark["color"])
	for effect in arc_effects:
		draw_line(effect["from"], effect["to"], Color("7ff7ff"), 4.0)
		draw_line(effect["from"], effect["to"], Color.WHITE, 1.0)
	for number in damage_numbers:
		var alpha: float = clamp(number["life"] / 0.55, 0.0, 1.0)
		draw_string(ThemeDB.fallback_font, number["pos"], str(number["value"]), HORIZONTAL_ALIGNMENT_CENTER, 42, 16, Color(number["color"], alpha))

	# player robot
	draw_arc(player_pos, pickup_radius, 0.0, TAU, 48, Color(0.2, 0.9, 1.0, 0.06), 1.0)
	draw_circle(player_pos, 25.0, Color(0.1, 0.8, 1.0, 0.12))
	draw_texture_centered(player_texture, player_pos, 68.0, Color("fff3a6") if player_flash > 0.0 else Color.WHITE)
	if orbit_level > 0:
		var orbit_radius := 88.0 if overload_blade_active else 68.0
		var blade_count: int = min(3, orbit_level)
		for blade_index in range(blade_count):
			var angle := orbit_angle + TAU * float(blade_index) / float(blade_count)
			var blade_pos := player_pos + Vector2.from_angle(angle) * orbit_radius
			draw_circle(blade_pos, 14.0, Color(1.0, 0.62, 0.2, 0.15))
			draw_colored_polygon(PackedVector2Array([blade_pos + Vector2(0, -12), blade_pos + Vector2(8, 8), blade_pos + Vector2(-8, 8)]), Color("ffba61"))
	draw_bar(Vector2(24, 88), 250.0, player_hp / player_max_hp, Color("5de1ff"), "ROBOT HP %d/%d" % [max(0, int(player_hp)), int(player_max_hp)])
	draw_bar(Vector2(24, 116), 250.0, float(xp) / float(xp_needed), Color("64ff9d"), "LEVEL %d   XP %d/%d" % [level, xp, xp_needed])
	draw_string(ThemeDB.fallback_font, Vector2(24, 160), "WEAPONS  Energy Lv.%d  Arc Lv.%d  Orbit Lv.%d" % [energy_level, arc_level, orbit_level], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("b8cae4"))
	var fusion_text := "FUSION  None"
	if chain_pulse_active and overload_blade_active:
		fusion_text = "FUSION  Chain Pulse + Overload Blade"
	elif chain_pulse_active:
		fusion_text = "FUSION  Chain Pulse"
	elif overload_blade_active:
		fusion_text = "FUSION  Overload Blade"
	draw_string(ThemeDB.fallback_font, Vector2(24, 184), fusion_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("ffcf70"))
	draw_string(ThemeDB.fallback_font, Vector2(24, 208), defense_module_summary(), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("91a9c7"))
	draw_boss_bar()
	draw_set_transform(Vector2.ZERO)
	draw_damage_vignette()
	draw_announcement()
	draw_tutorial_hint()
	draw_terminal_prompt()

	if choosing_upgrade:
		draw_upgrade_menu()
	if game_paused:
		draw_pause_menu()

	if game_over:
		draw_rect(Rect2(0, 0, SCREEN.x, SCREEN.y), Color(0.01, 0.02, 0.05, 0.82))
		var result_title := "THE CORE SURVIVED" if victory else "THE LAST DEFENSE HAS FALLEN"
		var result_color := Color("64ff9d") if victory else Color("ff6b81")
		draw_string(ThemeDB.fallback_font, Vector2(0, 300), result_title, HORIZONTAL_ALIGNMENT_CENTER, 1280, 40, result_color)
		draw_string(ThemeDB.fallback_font, Vector2(0, 350), "Survived %.1f seconds  •  Level %d  •  %d enemies destroyed" % [elapsed, level, kills], HORIZONTAL_ALIGNMENT_CENTER, 1280, 20, Color("d7e8ff"))
		draw_string(ThemeDB.fallback_font, Vector2(0, 382), "BEST  %.1fs  •  %d kills  •  %d wins / %d runs" % [best_time, best_kills, total_wins, total_runs], HORIZONTAL_ALIGNMENT_CENTER, 1280, 16, Color("9fb2cb"))
		draw_string(ThemeDB.fallback_font, Vector2(0, 410), "BUILD  Energy %d  •  Arc %d  •  Orbit %d  •  %s" % [energy_level, arc_level, orbit_level, build_fusion_name()], HORIZONTAL_ALIGNMENT_CENTER, 1280, 16, Color("ffcf70"))
		draw_string(ThemeDB.fallback_font, Vector2(0, 455), "[ R ]  DEPLOY AGAIN     [ Q ]  TITLE", HORIZONTAL_ALIGNMENT_CENTER, 1280, 22, Color("72f8ff"))

func draw_starfield() -> void:
	draw_rect(Rect2(0, 0, SCREEN.x, SCREEN.y), Color("070b18"))
	for star in stars:
		var pulse: float = 0.35 + (sin(animation_time * 1.5 + star["phase"]) + 1.0) * 0.22
		draw_circle(star["pos"], star["size"], Color(0.45, 0.72, 1.0, pulse))

func draw_title_screen() -> void:
	var center := SCREEN * 0.5
	for ring in range(4):
		var radius := 88.0 + float(ring) * 27.0 + sin(animation_time * 1.8 + ring) * 5.0
		draw_arc(center + Vector2(0, -55), radius, animation_time * (0.18 + ring * 0.03), TAU + animation_time * (0.18 + ring * 0.03), 72, Color(0.2, 0.75, 1.0, 0.15), 2.0)
	draw_texture_centered(core_texture, center + Vector2(0, -55), 148.0)
	draw_string(ThemeDB.fallback_font, Vector2(0, 405), "LAST DEFENSE", HORIZONTAL_ALIGNMENT_CENTER, 1280, 54, Color("dff9ff"))
	draw_string(ThemeDB.fallback_font, Vector2(0, 444), "THE CORE MUST SURVIVE", HORIZONTAL_ALIGNMENT_CENTER, 1280, 17, Color("6fcce8"))
	var blink := 0.55 + (sin(animation_time * 4.0) + 1.0) * 0.2
	draw_rect(Rect2(455, 500, 370, 58), Color(0.06, 0.17, 0.28, 0.92))
	draw_rect(Rect2(455, 500, 370, 58), Color("4fd9ff"), false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(455, 537), "[ ENTER ]  INITIALIZE DEFENSE", HORIZONTAL_ALIGNMENT_CENTER, 370, 20, Color(0.75, 0.96, 1.0, blink))
	draw_string(ThemeDB.fallback_font, Vector2(0, 585), "RECORD  %.1fs  •  %d kills  •  %d wins / %d runs" % [best_time, best_kills, total_wins, total_runs], HORIZONTAL_ALIGNMENT_CENTER, 1280, 15, Color("91a9c7"))
	draw_string(ThemeDB.fallback_font, Vector2(0, 620), "MOVE: WASD / ARROWS     •     INTERACT: E     •     ESC TO PAUSE", HORIZONTAL_ALIGNMENT_CENTER, 1280, 14, Color("7185a6"))
	draw_string(ThemeDB.fallback_font, Vector2(0, 650), "F11 FULLSCREEN  •  M SOUND  •  V SHAKE  •  T REPLAY TRAINING", HORIZONTAL_ALIGNMENT_CENTER, 1280, 13, Color("536985"))
	draw_string(ThemeDB.fallback_font, Vector2(0, 680), "[1] STANDARD   [2] CORE CRISIS   [3] ENDLESS   //   SELECTED: %s" % selected_mode.to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 1280, 14, Color("ffcf70"))

func draw_damage_vignette() -> void:
	var danger: float = 1.0 - min(player_hp / player_max_hp, core_hp / 300.0)
	if danger < 0.45:
		return
	var alpha := (danger - 0.45) * 0.38 * (0.75 + sin(animation_time * 5.0) * 0.25)
	draw_rect(Rect2(0, 0, 1280, 20), Color(0.85, 0.04, 0.12, alpha))
	draw_rect(Rect2(0, 700, 1280, 20), Color(0.85, 0.04, 0.12, alpha))
	draw_rect(Rect2(0, 0, 20, 720), Color(0.85, 0.04, 0.12, alpha))
	draw_rect(Rect2(1260, 0, 20, 720), Color(0.85, 0.04, 0.12, alpha))

func draw_announcement() -> void:
	if announcement_time <= 0.0 or announcement_text.is_empty():
		return
	var alpha: float = clamp(announcement_time, 0.0, 1.0)
	draw_rect(Rect2(350, 205, 580, 66), Color(0.02, 0.07, 0.14, 0.78 * alpha))
	draw_line(Vector2(350, 205), Vector2(930, 205), Color(0.3, 0.9, 1.0, alpha), 2.0)
	draw_line(Vector2(350, 271), Vector2(930, 271), Color(0.3, 0.9, 1.0, alpha), 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(350, 247), announcement_text, HORIZONTAL_ALIGNMENT_CENTER, 580, 24, Color(0.86, 0.98, 1.0, alpha))

func draw_tutorial_hint() -> void:
	if tutorial_completed or tutorial_step < 0 or game_over or game_paused or choosing_upgrade:
		return
	var hint := ""
	if tutorial_step == 0:
		hint = "TRAINING 1/4  •  MOVE WITH WASD OR ARROW KEYS"
	elif tutorial_step == 1:
		hint = "TRAINING 2/4  •  DEFEAT ENEMIES AND COLLECT GREEN ENERGY"
	elif tutorial_step == 2:
		hint = "TRAINING 3/4  •  LEVEL UP AND INSTALL A MODULE"
	else:
		hint = "TRAINING 4/4  •  APPROACH A MAP TERMINAL AND PRESS E"
	draw_rect(Rect2(350, 82, 580, 38), Color(0.02, 0.08, 0.15, 0.90))
	draw_rect(Rect2(350, 82, 580, 38), Color("4fd9ff"), false, 1.5)
	draw_string(ThemeDB.fallback_font, Vector2(350, 107), hint, HORIZONTAL_ALIGNMENT_CENTER, 580, 14, Color("dff9ff"))

func draw_pause_menu() -> void:
	draw_rect(Rect2(0, 0, SCREEN.x, SCREEN.y), Color(0.01, 0.02, 0.06, 0.82))
	draw_string(ThemeDB.fallback_font, Vector2(0, 285), "DEFENSE PAUSED", HORIZONTAL_ALIGNMENT_CENTER, 1280, 38, Color("dff9ff"))
	draw_string(ThemeDB.fallback_font, Vector2(0, 345), "[ ENTER / ESC ]  RESUME", HORIZONTAL_ALIGNMENT_CENTER, 1280, 20, Color("72f8ff"))
	draw_string(ThemeDB.fallback_font, Vector2(0, 386), "[ M ]  SOUND: %s" % ("ON" if sound_enabled else "OFF"), HORIZONTAL_ALIGNMENT_CENTER, 1280, 17, Color("9fb2cb"))
	draw_string(ThemeDB.fallback_font, Vector2(0, 421), "[ V ]  SCREEN SHAKE: %s     [ F11 ]  FULLSCREEN" % ("ON" if screen_shake_enabled else "OFF"), HORIZONTAL_ALIGNMENT_CENTER, 1280, 17, Color("9fb2cb"))
	draw_string(ThemeDB.fallback_font, Vector2(0, 458), "[ Q ]  RETURN TO TITLE", HORIZONTAL_ALIGNMENT_CENTER, 1280, 17, Color("9fb2cb"))

func draw_defense_modules() -> void:
	for module in defense_modules:
		var pos: Vector2 = module["pos"]
		if module["type"].is_empty():
			draw_circle(pos, 22.0, Color(0.08, 0.13, 0.22, 0.50))
			draw_arc(pos, 22.0, 0.0, TAU, 24, Color(0.25, 0.38, 0.55, 0.45), 2.0)
			continue
		if module["type"] == "turret":
			draw_circle(pos, 27.0, Color(0.2, 0.9, 1.0, 0.09))
			draw_circle(pos, 17.0, Color("173659"))
			draw_colored_polygon(PackedVector2Array([pos + Vector2(0, -18), pos + Vector2(10, 10), pos + Vector2(-10, 10)]), Color("5de1ff"))
		elif module["type"] == "slow":
			var effect_range: float = 125.0 + float(module["level"]) * 18.0
			draw_circle(pos, effect_range, Color(0.45, 0.25, 1.0, 0.035))
			draw_arc(pos, effect_range, animation_time * 0.25, TAU + animation_time * 0.25, 48, Color(0.55, 0.35, 1.0, 0.20), 2.0)
			draw_circle(pos, 18.0, Color("3a2466"))
			draw_arc(pos, 13.0, 0.0, TAU, 20, Color("c06cff"), 4.0)
		else:
			draw_circle(pos, 22.0, Color(0.2, 1.0, 0.55, 0.09))
			draw_circle(pos, 17.0, Color("173d35"))
			draw_rect(Rect2(pos - Vector2(4, 12), Vector2(8, 24)), Color("64ff9d"))
			draw_rect(Rect2(pos - Vector2(12, 4), Vector2(24, 8)), Color("64ff9d"))
		draw_string(ThemeDB.fallback_font, pos + Vector2(-20, 39), "Lv.%d" % module["level"], HORIZONTAL_ALIGNMENT_CENTER, 40, 11, Color("dff9ff"))

func defense_module_summary() -> String:
	var turret_level := 0
	var slow_level := 0
	var repair_level := 0
	for module in defense_modules:
		if module["type"] == "turret":
			turret_level = module["level"]
		elif module["type"] == "slow":
			slow_level = module["level"]
		elif module["type"] == "repair":
			repair_level = module["level"]
	return "DEFENSE  Turret %d  •  Stasis %d  •  Repair %d" % [turret_level, slow_level, repair_level]

func draw_arena_features() -> void:
	for hazard in hazards:
		var pulse: float = 0.75 + sin(animation_time * 2.5) * 0.12
		var hazard_color := Color("ff476f") if hazard["type"] == "corrosion" else Color("4f8dff")
		draw_circle(hazard["pos"], hazard["radius"], Color(hazard_color, 0.08 * pulse))
		draw_arc(hazard["pos"], hazard["radius"], 0.0, TAU, 64, Color(hazard_color, 0.42), 2.0)
		for ring in range(3):
			draw_arc(hazard["pos"], hazard["radius"] - 18.0 - ring * 17.0, animation_time * 0.3 + ring, PI + animation_time * 0.3 + ring, 28, Color(hazard_color, 0.18), 2.0)
	for obstacle in obstacles:
		draw_circle(obstacle["pos"], obstacle["radius"] + 8.0, Color(0.02, 0.05, 0.1, 0.72))
		draw_circle(obstacle["pos"], obstacle["radius"], Color("263550"))
		draw_circle(obstacle["pos"], obstacle["radius"] - 8.0, Color("101a2d"))
		draw_arc(obstacle["pos"], obstacle["radius"] - 5.0, animation_time * 0.4, TAU + animation_time * 0.4, 8, Color("4b779a"), 3.0)
	for terminal in terminals:
		var ready: bool = terminal["cooldown"] <= 0.0
		var color: Color = terminal["color"] if ready else Color("4f5d72")
		draw_circle(terminal["pos"], 32.0, Color(color, 0.10))
		draw_circle(terminal["pos"], 21.0, Color("14233d"))
		draw_arc(terminal["pos"], 27.0, 0.0, TAU, 32, color, 3.0)
		draw_rect(Rect2(terminal["pos"] - Vector2(7, 7), Vector2(14, 14)), color)
		if not ready:
			var progress: float = 1.0 - terminal["cooldown"] / terminal["max_cd"]
			draw_arc(terminal["pos"], 34.0, -PI * 0.5, -PI * 0.5 + TAU * progress, 32, terminal["color"], 4.0)
		draw_string(ThemeDB.fallback_font, terminal["pos"] + Vector2(-65, 52), terminal["name"], HORIZONTAL_ALIGNMENT_CENTER, 130, 12, color)

func draw_terminal_prompt() -> void:
	if nearby_terminal.is_empty() or choosing_upgrade or game_over or game_paused:
		return
	var label := ""
	for terminal in terminals:
		if terminal["id"] == nearby_terminal:
			label = terminal["name"]
			break
	draw_rect(Rect2(455, 610, 370, 52), Color(0.02, 0.08, 0.15, 0.92))
	draw_rect(Rect2(455, 610, 370, 52), Color("72f8ff"), false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(455, 643), "[ E ]  ACTIVATE " + label, HORIZONTAL_ALIGNMENT_CENTER, 370, 18, Color("dff9ff"))

func draw_boss_bar() -> void:
	if not boss_alive:
		return
	var boss_hp := 0.0
	for enemy in enemies:
		if enemy["type"] == "boss":
			boss_hp = enemy["hp"]
			break
	draw_bar(Vector2(390, 82), 500.0, boss_hp / boss_max_hp, Color("d94dff"), "BOSS  %d/%d" % [max(0, int(boss_hp)), int(boss_max_hp)])

func draw_upgrade_menu() -> void:
	draw_rect(Rect2(0, 0, SCREEN.x, SCREEN.y), Color(0.01, 0.02, 0.05, 0.84))
	draw_string(ThemeDB.fallback_font, Vector2(0, 164), "SYSTEM UPGRADE", HORIZONTAL_ALIGNMENT_CENTER, 1280, 34, Color("72f8ff"))
	draw_string(ThemeDB.fallback_font, Vector2(0, 198), "Press 1, 2 or 3 to install a module", HORIZONTAL_ALIGNMENT_CENTER, 1280, 17, Color("a7b9d4"))
	for i in range(upgrade_options.size()):
		var rect := Rect2(170 + i * 320, 245, 280, 230)
		draw_rect(rect, Color("14233d"))
		var rare: bool = upgrade_options[i].get("rarity", "common") == "rare"
		draw_rect(rect, Color("ffcf70") if rare else Color("4fc9ed"), false, 4.0 if rare else 2.0)
		if rare:
			draw_string(ThemeDB.fallback_font, rect.position + Vector2(180, 35), "RARE", HORIZONTAL_ALIGNMENT_CENTER, 70, 13, Color("ffcf70"))
		draw_circle(rect.position + Vector2(38, 38), 20.0, Color("27577a"))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(31, 45), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(24, 102), upgrade_options[i]["name"], HORIZONTAL_ALIGNMENT_LEFT, 232, 24, Color("d9f5ff"))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(24, 150), upgrade_options[i]["desc"], HORIZONTAL_ALIGNMENT_LEFT, 232, 16, Color("9fb2cb"))

func draw_bar(pos: Vector2, width: float, ratio: float, color: Color, label: String) -> void:
	draw_rect(Rect2(pos, Vector2(width, 22)), Color("151d31"))
	draw_rect(Rect2(pos + Vector2(3, 3), Vector2((width - 6) * clamp(ratio, 0.0, 1.0), 16)), color)
	draw_string(ThemeDB.fallback_font, pos + Vector2(8, 17), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)

func draw_texture_centered(texture: Texture2D, center: Vector2, size: float, modulate: Color = Color.WHITE) -> void:
	if texture == null:
		return
	var rect := Rect2(center - Vector2(size, size) * 0.5, Vector2(size, size))
	draw_texture_rect(texture, rect, false, modulate)
