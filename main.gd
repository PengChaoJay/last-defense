extends Node2D

const SCREEN := Vector2(1280.0, 720.0)
const PLAYER_SPEED := 270.0
const PLAYER_RADIUS := 15.0
const CORE_POS := Vector2(640.0, 360.0)
const CORE_RADIUS := 42.0
const BOSS_TIME := 420.0
const MAX_RUN_TIME := 600.0

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
var event_timer := 55.0
var damage_boost_timer := 0.0
var hazard_tick := 0.0
var nearby_terminal := ""

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
	{"id": "orbit", "name": "ORBIT BLADES", "desc": "Unlock or improve orbiting blades"}
]

func _ready() -> void:
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
		elif game_over and event.keycode == KEY_R:
			start_game()
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
	if elapsed >= MAX_RUN_TIME:
		victory = false
		game_over = true
		queue_redraw()
		return
	update_boss_schedule()
	update_arena_features(delta)
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
		game_over = true
		announcement_text = "SIGNAL LOST"
		announcement_time = 2.0
		play_sfx("damage")
	queue_redraw()

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
	announcement_text = "DEFEND THE CORE"
	announcement_time = 2.2
	play_sfx("upgrade")

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
			core_hp = min(300.0, core_hp + 75.0)
			announcement_text = "CORE INTEGRITY RESTORED"
		elif terminal["id"] == "weapon":
			damage_boost_timer = 25.0
			announcement_text = "WEAPONS OVERCHARGED"
		else:
			player_hp = min(player_max_hp, player_hp + 55.0)
			announcement_text = "ARMOR RESTORED"
		terminal["cooldown"] = terminal["max_cd"]
		announcement_time = 1.8
		create_spark(terminal["pos"], terminal["color"], 16)
		play_sfx("upgrade")
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
	if not boss_spawned and elapsed >= BOSS_TIME:
		spawn_boss()

func spawn_boss() -> void:
	boss_spawned = true
	boss_alive = true
	boss_max_hp = 1650.0
	announcement_text = "WARNING: TITAN SIGNAL"
	announcement_time = 3.0
	screen_shake = 14.0
	play_sfx("boss")
	enemies.append({
		"pos": Vector2(SCREEN.x * 0.5, 92.0),
		"hp": boss_max_hp,
		"speed": 56.0,
		"radius": 46.0,
		"damage": 20.0,
		"type": "boss",
		"hit_cd": 0.0,
		"orbit_cd": 0.0,
		"charge_cd": 3.5,
		"charge_time": 0.0,
		"charge_dir": Vector2.ZERO,
		"summon_cd": 5.0
	})

func spawn_enemy(elite: bool = false) -> void:
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
	if elite:
		enemy_type = "elite"
		enemy_hp = 220.0 + elapsed * 0.22
		enemy_speed = 82.0
		enemy_radius = 27.0
		enemy_damage = 18.0
	enemies.append({
		"pos": pos,
		"hp": enemy_hp,
		"speed": enemy_speed,
		"radius": enemy_radius,
		"damage": enemy_damage,
		"type": enemy_type,
		"hit_cd": 0.0,
		"orbit_cd": 0.0
	})

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
		arc_effects.append({"from": current_pos, "to": target_pos, "life": 0.16})
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
		arc_effects.append({"from": current_pos, "to": target_pos, "life": 0.13})
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
	var number_pos: Vector2 = enemies[index]["pos"] + Vector2(randf_range(-7.0, 7.0), -12.0)
	damage_numbers.append({"pos": number_pos, "value": int(round(amount)), "life": 0.55, "color": enemy_color(enemies[index]["type"])})
	enemies[index]["hp"] -= amount
	play_sfx("hit")
	if enemies[index]["hp"] > 0.0:
		return false
	var dead_pos: Vector2 = enemies[index]["pos"]
	var dead_type: String = enemies[index]["type"]
	var orb_value := 1
	if dead_type == "heavy":
		orb_value = 2
	elif dead_type == "elite":
		orb_value = 5
	elif dead_type == "boss":
		orb_value = 12
	xp_orbs.append({"pos": dead_pos, "value": orb_value})
	create_spark(dead_pos, enemy_color(dead_type), 12 if dead_type == "boss" else 9)
	enemies.remove_at(index)
	kills += 1
	if dead_type == "boss":
		boss_alive = false
		victory = true
		game_over = true
		screen_shake = 18.0
		announcement_text = "CORE SECURED"
		announcement_time = 4.0
		play_sfx("victory")
	return true

func update_enemies(delta: float) -> void:
	for i in range(enemies.size() - 1, -1, -1):
		enemies[i]["hit_cd"] = max(0.0, enemies[i]["hit_cd"] - delta)
		if enemies[i]["type"] == "boss":
			update_boss_enemy(i, delta)
		else:
			var to_player: float = enemies[i]["pos"].distance_to(player_pos)
			var target := player_pos if to_player < 220.0 else CORE_POS
			var direction: Vector2 = (target - enemies[i]["pos"]).normalized()
			direction = steer_around_obstacles(enemies[i]["pos"], direction, enemies[i]["radius"])
			enemies[i]["pos"] += direction * float(enemies[i]["speed"]) * delta
			resolve_enemy_obstacle(i)
		if enemies[i]["hit_cd"] <= 0.0:
			if enemies[i]["pos"].distance_to(player_pos) < float(enemies[i]["radius"]) + PLAYER_RADIUS:
				player_hp -= enemies[i]["damage"]
				enemies[i]["hit_cd"] = 0.65
				create_spark(player_pos, Color("ff476f"), 5)
				player_flash = 0.22
				screen_shake = max(screen_shake, 7.0)
				play_sfx("damage")
			elif enemies[i]["pos"].distance_to(CORE_POS) < float(enemies[i]["radius"]) + CORE_RADIUS:
				core_hp -= enemies[i]["damage"]
				enemies[i]["hit_cd"] = 0.65
				create_spark(CORE_POS, Color("ffb347"), 5)
				core_flash = 0.22
				screen_shake = max(screen_shake, 5.0)
				play_sfx("damage")

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
		enemies[index]["pos"] += direction * enemies[index]["speed"] * delta
		if enemies[index]["charge_cd"] <= 0.0:
			enemies[index]["charge_dir"] = direction
			enemies[index]["charge_time"] = 0.72
			enemies[index]["charge_cd"] = 4.2
	enemies[index]["pos"].x = clamp(enemies[index]["pos"].x, 18.0, SCREEN.x - 18.0)
	enemies[index]["pos"].y = clamp(enemies[index]["pos"].y, 82.0, SCREEN.y - 18.0)
	resolve_enemy_obstacle(index)

func create_spark(pos: Vector2, color: Color, count: int = 4) -> void:
	for i in range(count):
		var angle := randf() * TAU
		sparks.append({
			"pos": pos,
			"velocity": Vector2.from_angle(angle) * randf_range(45.0, 150.0),
			"life": randf_range(0.18, 0.45),
			"color": color
		})

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
	refresh_fusions()
	play_sfx("upgrade")
	announcement_text = upgrade_options[index]["name"] + " INSTALLED"
	announcement_time = 1.5
	choosing_upgrade = false
	upgrade_options.clear()

func refresh_fusions() -> void:
	chain_pulse_active = arc_level >= 1 and multishot_upgrade_count >= 1
	overload_blade_active = orbit_level >= 1 and damage_upgrade_count >= 1 and fire_rate_upgrade_count >= 1

func enemy_color(enemy_type: String) -> Color:
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
	core_hp = 300.0
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
	enemies.clear()
	bullets.clear()
	sparks.clear()
	arc_effects.clear()
	xp_orbs.clear()
	upgrade_options.clear()
	damage_numbers.clear()
	for terminal in terminals:
		terminal["cooldown"] = 0.0
	for i in range(6):
		spawn_enemy()

func _draw() -> void:
	draw_starfield()
	if not game_started:
		draw_title_screen()
		return
	var shake_offset := Vector2.ZERO
	if screen_shake > 0.0:
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
	var remaining: int = max(0, int(BOSS_TIME - elapsed))
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

	# entities
	for orb in xp_orbs:
		draw_circle(orb["pos"], 8.0, Color(0.3, 1.0, 0.55, 0.15))
		draw_circle(orb["pos"], 4.0, Color("64ff9d"))
	for enemy in enemies:
		var color := enemy_color(enemy["type"])
		draw_circle(enemy["pos"], enemy["radius"] + 4.0, Color(color, 0.13))
		if enemy["type"] == "boss":
			if enemy["charge_time"] <= 0.0 and enemy["charge_cd"] < 1.0:
				var warning_end: Vector2 = enemy["pos"] + enemy["charge_dir"] * 520.0
				draw_line(enemy["pos"], warning_end, Color(1.0, 0.15, 0.42, 0.25 + sin(animation_time * 16.0) * 0.12), 18.0)
				draw_line(enemy["pos"], warning_end, Color("ff4778"), 2.0)
			draw_texture_centered(boss_texture, enemy["pos"], 154.0)
		elif enemy["type"] == "heavy":
			draw_texture_centered(enemy_heavy_texture, enemy["pos"], 76.0)
		elif enemy["type"] == "elite":
			draw_texture_centered(enemy_heavy_texture, enemy["pos"], 90.0, Color(1.2, 1.0, 0.52, 1.0))
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
	draw_boss_bar()
	draw_set_transform(Vector2.ZERO)
	draw_damage_vignette()
	draw_announcement()
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
		draw_string(ThemeDB.fallback_font, Vector2(0, 410), "[ R ]  DEPLOY AGAIN", HORIZONTAL_ALIGNMENT_CENTER, 1280, 22, Color("72f8ff"))

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
	draw_string(ThemeDB.fallback_font, Vector2(0, 620), "MOVE: WASD / ARROWS     •     INTERACT: E     •     ESC TO PAUSE", HORIZONTAL_ALIGNMENT_CENTER, 1280, 14, Color("7185a6"))

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

func draw_pause_menu() -> void:
	draw_rect(Rect2(0, 0, SCREEN.x, SCREEN.y), Color(0.01, 0.02, 0.06, 0.82))
	draw_string(ThemeDB.fallback_font, Vector2(0, 285), "DEFENSE PAUSED", HORIZONTAL_ALIGNMENT_CENTER, 1280, 38, Color("dff9ff"))
	draw_string(ThemeDB.fallback_font, Vector2(0, 345), "[ ENTER / ESC ]  RESUME", HORIZONTAL_ALIGNMENT_CENTER, 1280, 20, Color("72f8ff"))
	draw_string(ThemeDB.fallback_font, Vector2(0, 386), "[ M ]  SOUND: %s" % ("ON" if sound_enabled else "OFF"), HORIZONTAL_ALIGNMENT_CENTER, 1280, 17, Color("9fb2cb"))

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
		draw_rect(rect, Color("4fc9ed"), false, 2.0)
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
