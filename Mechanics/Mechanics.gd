# Mechanics.gd —— 新玩法总控：道具、多球、BOSS 技能(假球/黑暗)、蓄力回击特效、障碍砖块和传送门、HUD。
# 经典模式 Level.gd 和疯狂模式 CrazyMode.gd 在 _ready() 里各创建一个，用法一样。
extends Node

const PowerUp = preload("res://Mechanics/PowerUp.gd")
const Portal = preload("res://Mechanics/Portal.gd")
const Hud = preload("res://Mechanics/Hud.gd")
const TRAIL_SCENE = preload("res://Scenes/BallTrail.tscn")
const Difficulty = preload("res://Mechanics/Difficulty.gd")

# ---- 平衡参数（想调整手感就改这里）----
const POWERUP_TYPES := ["long", "multi", "slow"]
const POWERUP_INTERVAL := Vector2(8.0, 12.0)    # 每隔 8~12 秒刷新一个道具（场上最多 1 个）
const POWERUP_X := Vector2(420.0, 860.0)        # 出现在两个球拍之间的中段
const POWERUP_LANE_SPREAD := 110.0              # 放在球"将要经过的路线"附近 ±110 像素
const SERVE_CLEAR_TIME := 1.0                   # 发球后 1 秒内砖块是"虚影"，不挡发球
const LONG_TIME := 8.0          # 长球拍持续 8 秒
const LONG_SCALE := 1.6         # 变长 1.6 倍
const SLOW_TIME := 6.0          # 减速持续 6 秒
const SLOW_MULT := 0.5          # 速度变成一半
const MAX_EXTRA_BALLS := 4
const DECOY_INTERVAL := Difficulty.BOSS_DECOY_INTERVAL    # BOSS 放假球的间隔（数值在 Difficulty.gd）
const DECOY_LIFE := 7.0
const DARK_INTERVAL := Difficulty.BOSS_DARK_INTERVAL   # BOSS 让场地变黑的间隔
const DARK_TIME := 2.5

var game: Node
var mode := "classic"
var ball_scene: PackedScene
var main_ball: Node2D
var player: Node2D
var opponent: Node2D
var hud: Hud
var rng := RandomNumberGenerator.new()

var active := true
var powerups_enabled := false
var boss_active := false
var dark_active := false
var darkness: ColorRect
var effects := {}         # 正在生效的道具效果
var obstacles := []
var spawn_timer := 8.0
var decoy_timer := 4.0
var dark_timer := 8.0
var crazy_time := 0.0
var crazy_stage := 0
var _trail_states := {}
var serving := false     # 发球阶段（倒计时 + 发出后 1 秒）
var _serve_id := 0       # 每次发球编号 +1，旧的计时器就知道自己"过期"了
var sfx := {}
var stats := {"powerups": 0, "decoys": 0, "darkness": 0, "teleports": 0, "charged": 0}

func setup(g: Node, m: String, ball: Node2D, pl: Node2D, opp: Node2D):
	game = g; mode = m; main_ball = ball; player = pl; opponent = opp
	ball_scene = load(ball.scene_file_path)
	rng.randomize()
	pl.add_to_group("paddles"); opp.add_to_group("paddles"); pl.add_to_group("player_paddle")
	for p in [pl, opp]:   # 玩家蓄力球 和 BOSS 快球 都放特效
		if p.has_signal("charged_shot"):
			p.charged_shot.connect(_on_charged_shot)
	var sounds := {"pickup": "res://assets/levelup.wav", "decoy": "res://assets/Sounds/boss_laugh.mp3",
			"dark": "res://assets/Sounds/boss_sound.wav", "portal": "res://assets/Sounds/pingpongboard.ogg",
			"charge": "res://assets/Sounds/pingpongbat.ogg", "spawn": "res://assets/ping_pong_8bit_plop.ogg"}
	for k in sounds:   # 音效全部复用项目里已有的声音
		var p := AudioStreamPlayer.new(); p.stream = load(sounds[k]); p.volume_db = -4; add_child(p); sfx[k] = p
	_make_darkness()
	if get_viewport().get_camera_2d() == null:   # 疯狂模式原来没有摄像机，加一个(画面不变)用来做震屏
		var cam := Camera2D.new(); cam.position = Vector2(640, 360); game.add_child.call_deferred(cam)
	hud = Hud.new(); add_child(hud); hud.build(mode)
	powerups_enabled = (mode == "classic")

func play(name: String):
	if sfx.has(name): sfx[name].play()

func _physics_process(delta):
	if not active: return
	_update_effects(delta)
	var in_play := _ball_in_play()
	if powerups_enabled and in_play:
		spawn_timer -= delta
		if spawn_timer <= 0.0:
			if get_tree().get_nodes_in_group("PowerUp").is_empty():
				spawn_powerup(POWERUP_TYPES[rng.randi() % POWERUP_TYPES.size()])
			spawn_timer = rng.randf_range(POWERUP_INTERVAL.x, POWERUP_INTERVAL.y)
	if boss_active and in_play:
		decoy_timer -= delta
		if decoy_timer <= 0.0:
			fire_decoy(); decoy_timer = DECOY_INTERVAL
		dark_timer -= delta
		if dark_timer <= 0.0:
			start_darkness(); dark_timer = rng.randf_range(DARK_INTERVAL.x, DARK_INTERVAL.y)
	if mode == "crazy" and in_play:
		crazy_time += delta
		_crazy_milestones()

func _ball_in_play() -> bool:
	return is_instance_valid(main_ball) and main_ball.speed > 0

# ================= 道具 =================
func spawn_powerup(kind: String, pos = null) -> Node:
	var p := PowerUp.new()
	p.kind = kind
	p.position = pos if pos != null else _powerup_spot()
	p.collected.connect(_on_powerup_collected)
	game.add_child(p)
	play("spawn")
	return p

# 道具放在球"真的会经过"的地方：用预判算出球飞到 x 时的 y，再随机偏一点
func _powerup_spot() -> Vector2:
	var x := rng.randf_range(POWERUP_X.x, POWERUP_X.y)
	var y := rng.randf_range(120.0, 600.0)
	if _ball_in_play():
		var v: Vector2 = main_ball.velocity
		var lane := Difficulty.predict_y(main_ball.global_position, v, x)
		# 如果球正在远离这个 x，就算它反弹回来后的路线（方向反过来再算一次）
		if signf(x - main_ball.global_position.x) != signf(v.x):
			var far_x := 1180.0 if v.x > 0 else 100.0
			var far_y := Difficulty.predict_y(main_ball.global_position, v, far_x)
			lane = Difficulty.predict_y(Vector2(far_x, far_y), Vector2(-v.x, v.y), x)
		y = lane + rng.randf_range(-POWERUP_LANE_SPREAD, POWERUP_LANE_SPREAD)
	return Vector2(x, clampf(y, 90.0, 630.0))

func _on_powerup_collected(kind: String, ball: Node):
	# 碰撞回调里不能直接加/改物理物体，所以"等这一帧物理算完"再生效
	call_deferred("_apply_powerup", kind, ball)

func _apply_powerup(kind: String, ball: Node):
	if not is_instance_valid(ball): return
	play("pickup")
	stats["powerups"] += 1
	var hitter = ball.last_hitter if ("last_hitter" in ball and is_instance_valid(ball.last_hitter)) else player
	var other = opponent if hitter == player else player
	match kind:
		"long": apply_long(hitter)        # 最后碰球的人球拍变长
		"multi": spawn_multiball(ball)    # 一个球变三个
		"slow": apply_slow(other)         # 另一方球拍变慢
	hud.flash(PowerUp.INFO[kind]["name"], PowerUp.INFO[kind]["color"])

func _who(p: Node) -> String:
	return "(你 YOU)" if p == player else "(对手 AI)"

func _scaled_parts(paddle: Node) -> Array:
	var parts := []
	for c in paddle.get_children():
		if (c is Sprite2D and c.name == "Sprite2D") or c is CollisionShape2D or c is CollisionPolygon2D:
			parts.append(c)
	return parts

func apply_long(paddle: Node):
	var key := "long_" + paddle.name
	if effects.has(key):
		effects[key]["time_left"] = LONG_TIME   # 再吃一次就刷新时间
		return
	var saved := {}
	for c in _scaled_parts(paddle):
		saved[c] = c.scale
		c.scale.y *= LONG_SCALE
	effects[key] = {"kind": "long", "target": paddle, "time_left": LONG_TIME, "saved": saved,
		"label": PowerUp.INFO["long"]["name"], "who": _who(paddle)}

func apply_slow(paddle: Node):
	var key := "slow_" + paddle.name
	if not effects.has(key):
		paddle.speed_mult = SLOW_MULT
		var spr = paddle.get_node_or_null("Sprite2D")
		if spr: spr.self_modulate = Color("6ad1ff")
	effects[key] = {"kind": "slow", "target": paddle, "time_left": SLOW_TIME,
		"label": PowerUp.INFO["slow"]["name"], "who": _who(paddle)}

func _update_effects(delta: float):
	for key in effects.keys():
		effects[key]["time_left"] -= delta
		if effects[key]["time_left"] <= 0.0:
			_expire(key)
	hud.set_effects(effects)

func _expire(key: String):
	var e = effects[key]
	var paddle = e["target"]
	if is_instance_valid(paddle):
		if e["kind"] == "long":
			for c in e["saved"]:
				# 只有没被别的东西(比如 BOSS 变身)改过时才恢复
				if is_instance_valid(c) and c.scale.is_equal_approx(Vector2(e["saved"][c].x, e["saved"][c].y * LONG_SCALE)):
					c.scale = e["saved"][c]
		elif e["kind"] == "slow":
			paddle.speed_mult = 1.0
			var spr = paddle.get_node_or_null("Sprite2D")
			if spr: spr.self_modulate = Color.WHITE
	effects.erase(key)

# ================= 多球 / 假球 =================
func all_balls() -> Array:
	return get_tree().get_nodes_in_group("BallGroup") + get_tree().get_nodes_in_group("DecoyBall")

func _new_ball(at: Vector2, vel: Vector2, spd: float, groups: Array) -> Node:
	var b = ball_scene.instantiate()
	# 先把位置设好再放进场景！以前是先 add_child 再移动，
	# 球会在 (0,0) —— 左边球门里 —— 待一个物理帧，被左墙当成"进球"立刻删掉（多球、假球都因此消失）
	b.position = game.to_local(at) if game is Node2D else at
	for g in groups: b.add_to_group(g)
	game.add_child(b)
	b.global_position = at
	b.velocity = vel
	b.speed = spd
	for other in all_balls():
		if other != b:
			b.add_collision_exception_with(other)   # 球和球之间互相穿过，不会卡在一起
	var t = TRAIL_SCENE.instantiate()
	b.add_child(t)
	var main_trail = main_ball.get_node_or_null("BallTrail") if is_instance_valid(main_ball) else null
	t.visible = main_trail.visible if main_trail else false
	return b

func spawn_multiball(src: Node) -> Array:
	var made := []
	var spd: float = src.speed if src.speed > 0 else 600.0
	for ang in [-0.45, 0.45]:
		if get_tree().get_nodes_in_group("ExtraBall").size() >= MAX_EXTRA_BALLS: break
		var b = _new_ball(src.global_position, src.velocity.rotated(ang), spd, ["ExtraBall"])
		b.last_hitter = src.last_hitter
		made.append(b)
	return made

func fire_decoy() -> Node:
	if not is_instance_valid(opponent): return null
	var spd: float = main_ball.speed if main_ball.speed > 0 else 600.0
	var start: Vector2 = opponent.global_position + Vector2(-80, 0)
	# 假球瞄准玩家球拍的"另一边"，逼你去追
	var aim_y: float = 600.0 if player.global_position.y < 360.0 else 120.0
	var dir := (Vector2(60, aim_y) - start).normalized()
	var b = _new_ball(start, Vector2(-1, dir.y / absf(dir.x)), spd * 1.1, ["DecoyBall"])
	b.remove_from_group("BallGroup")    # 假球不会被"暂停/重新发球"影响，也不能吃道具
	b.modulate = Color(1, 0.35, 0.35, 0.8)
	get_tree().create_timer(DECOY_LIFE, false).timeout.connect(b.queue_free)   # 7 秒后自动消失（球先没了也没关系）
	play("decoy")
	stats["decoys"] += 1
	return b

# 球进了左右边界时，关卡脚本先问一下"这是哪种球"
func classify(body: Node) -> String:
	if body == null: return "main"   # 防御：没有传球进来时按主球处理
	if body.is_in_group("DecoyBall"): return "decoy"
	if body.is_in_group("ExtraBall"): return "extra"
	if body == main_ball: return "main"
	return "other"

func remove_ball(body: Node):
	body.queue_free()

func clear_extra_balls():
	for b in get_tree().get_nodes_in_group("ExtraBall") + get_tree().get_nodes_in_group("DecoyBall"):
		b.queue_free()

# ================= BOSS 技能：黑暗 =================
func start_boss():
	boss_active = true
	decoy_timer = 4.0
	dark_timer = 8.0
	hud.flash("BOSS 技能：假球 + 黑暗！ / BOSS SKILLS!", Color("eb4b4b"))

func _make_darkness():
	darkness = ColorRect.new()
	darkness.name = "Darkness"
	darkness.color = Color(0, 0, 0, 0.94)
	darkness.position = Vector2(-200, -200); darkness.size = Vector2(1680, 1120)
	darkness.z_index = 50
	darkness.mouse_filter = Control.MOUSE_FILTER_IGNORE
	darkness.visible = false
	game.add_child.call_deferred(darkness)

func start_darkness(duration: float = DARK_TIME):
	if dark_active: return
	dark_active = true
	stats["darkness"] += 1
	play("dark")
	darkness.visible = true
	darkness.modulate.a = 0.0
	create_tween().tween_property(darkness, "modulate:a", 1.0, 0.3)
	# 黑暗中只看得见球的拖尾：把拖尾临时显示出来，并画在黑幕上面
	_trail_states.clear()
	for b in all_balls():
		var t = b.get_node_or_null("BallTrail")
		if t:
			_trail_states[t] = [t.visible, t.z_index, t.z_as_relative]
			t.visible = true; t.z_as_relative = false; t.z_index = 100
	get_tree().create_timer(duration, false).timeout.connect(end_darkness)

func end_darkness():
	if not dark_active: return
	dark_active = false
	var tw := create_tween()
	tw.tween_property(darkness, "modulate:a", 0.0, 0.3)
	tw.tween_callback(func(): darkness.visible = false)
	for t in _trail_states:
		if is_instance_valid(t):
			t.visible = _trail_states[t][0]; t.z_index = _trail_states[t][1]; t.z_as_relative = _trail_states[t][2]
	_trail_states.clear()

# ================= 蓄力回击特效 =================
func _on_charged_shot(ball: Node, charge: float):
	stats["charged"] += 1
	play("charge")
	shake(3.0 + 7.0 * charge, 0.25)
	burst(ball.global_position, Color("ffd23f").lerp(Color("eb4b4b"), charge))

func shake(intensity: float, duration: float):
	var cam := get_viewport().get_camera_2d()
	if cam == null: return
	var tw := create_tween()
	for i in int(duration / 0.04):
		tw.tween_property(cam, "offset", Vector2(rng.randf_range(-intensity, intensity), rng.randf_range(-intensity, intensity)), 0.04)
	tw.tween_property(cam, "offset", Vector2.ZERO, 0.04)

func burst(pos: Vector2, color: Color):
	var p := CPUParticles2D.new()
	p.position = pos
	p.one_shot = true
	p.amount = 40
	p.lifetime = 0.6
	p.explosiveness = 1.0
	p.spread = 180.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 150.0
	p.initial_velocity_max = 380.0
	p.scale_amount_min = 3.0
	p.scale_amount_max = 6.0
	p.color = color
	p.z_index = 60
	p.add_to_group("FxBurst")
	game.add_child(p)
	p.emitting = true
	get_tree().create_timer(1.2).timeout.connect(p.queue_free)

# ================= 障碍：移动砖块 + 传送门 =================
func add_brick(x: float, y_from: float, y_to: float, period: float = 3.0) -> Node:
	var b := AnimatableBody2D.new()
	b.name = "Brick%d" % obstacles.size()
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new(); r.size = Vector2(24, 110)
	cs.shape = r; b.add_child(cs)
	var vis := ColorRect.new()
	vis.size = Vector2(24, 110); vis.position = Vector2(-12, -55); vis.color = Color("e4ae39")
	b.add_child(vis)
	b.position = Vector2(x, y_from)
	b.add_to_group("Obstacle")
	game.add_child(b)
	if serving: _ghost_brick(b, true)   # 升级时正好在发球阶段：先做虚影
	var tw := b.create_tween().set_loops()
	tw.tween_property(b, "position:y", y_to, period).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(b, "position:y", y_from, period).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	obstacles.append(b)
	hud.flash("新障碍：移动砖块 / NEW: moving brick", Color("e4ae39"))
	return b

func add_portal_pair(a: Vector2, b: Vector2) -> Array:
	var p1 := Portal.new(); p1.position = a; p1.color = Color("8847ff")
	var p2 := Portal.new(); p2.position = b; p2.color = Color("ff8c00")
	p1.partner = p2; p2.partner = p1
	for p in [p1, p2]:
		p.teleported.connect(func(_ball): stats["teleports"] += 1; play("portal"))
		game.add_child(p)
		obstacles.append(p)
	hud.flash("新障碍：传送门 / NEW: portals", Color("8847ff"))
	return [p1, p2]

# 经典模式每升一级加一个障碍（最多 3 个，避免太乱）
func on_level_up(level: int):
	call_deferred("_add_level_obstacle", level)   # 同样：等物理回调结束再加

func _add_level_obstacle(level: int):
	match level:
		1: add_brick(640, 230, 490)
		2: add_portal_pair(Vector2(450, 175), Vector2(830, 575))
		3: add_brick(540, 490, 230, 2.5)

# 疯狂模式按存活时间逐步加料
func _crazy_milestones():
	if crazy_stage == 0 and crazy_time >= 20.0:
		crazy_stage = 1; powerups_enabled = true; spawn_timer = 0.0
		hud.flash("道具出现！/ POWER-UPS ON")
	elif crazy_stage == 1 and crazy_time >= 40.0:
		crazy_stage = 2; add_brick(640, 230, 490)
	elif crazy_stage == 2 and crazy_time >= 70.0:
		crazy_stage = 3; add_portal_pair(Vector2(450, 175), Vector2(830, 575))
	elif crazy_stage == 3 and crazy_time >= 100.0:
		crazy_stage = 4; add_brick(540, 490, 230, 2.5)
	elif crazy_stage == 4 and crazy_time >= 120.0:
		crazy_stage = 5; start_boss()

# ================= 发球 =================
# 得分的一方发球：球贴在得分方球拍前面，倒计时结束后朝对手发出
func prepare_serve(winner: String):
	var paddle = player if winner != "AI" else opponent
	var dir := 1.0 if paddle == player else -1.0
	if is_instance_valid(main_ball) and main_ball.has_method("prepare_serve"):
		main_ball.prepare_serve(paddle, dir)
	serving = true
	_serve_id += 1
	_ghost_bricks(true)

# 倒计时结束、球发出去时调用
func on_serve_launched():
	var my_id := _serve_id
	get_tree().create_timer(SERVE_CLEAR_TIME, false).timeout.connect(func():
		if my_id != _serve_id: return   # 这期间又发了新球，不管
		serving = false
		_ghost_bricks(false))

func _ghost_bricks(on: bool):
	for b in get_tree().get_nodes_in_group("Obstacle"):
		if b is AnimatableBody2D:
			_ghost_brick(b, on)

func _ghost_brick(b: Node, on: bool):
	b.get_child(0).set_deferred("disabled", on)   # 关掉碰撞
	b.modulate.a = 0.3 if on else 1.0              # 半透明 = 虚影

# 游戏结束时调用：停止所有新玩法
func stop_all():
	active = false
	boss_active = false
	for key in effects.keys(): _expire(key)
	hud.set_effects(effects)
	clear_extra_balls()
	for p in get_tree().get_nodes_in_group("PowerUp"): p.queue_free()
	end_darkness()
