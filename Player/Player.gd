extends CharacterBody2D

# 蓄力回击：按住 → 蓄力（球拍旁边出现能量条），在球碰到球拍的那一刻前后松开，
# 球会以更快、更斜的角度弹回去。
signal charged_shot(ball, charge)
signal ball_hit(ball)

const CHARGE_TIME := 1.0       # 按住 1 秒蓄满
const RELEASE_WINDOW := 0.3    # 松开后 0.3 秒内碰到球都算
const LATE_WINDOW := 0.2       # 球先碰到、0.2 秒内再松开也算
const MIN_CHARGE := 0.15       # 蓄力太少不算

var speed = 500
var speed_mult := 1.0          # 减速道具会改它
var charge := 0.0              # 正在蓄的力 (0~1)
var released_charge := 0.0     # 刚松开时的力
var release_timer := 0.0
var late_ball = null           # 先碰到的球（等你松开）
var late_timer := 0.0

func _ready():
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING  # 和 Godot 3 一样：没有"地板"概念

func _physics_process(delta):
	var direction = Vector2.ZERO
	if Input.is_action_pressed("ui_up"):
		direction.y -= 1
	if Input.is_action_pressed("ui_down"):
		direction.y += 1
	#if Input.is_action_pressed("ui_left"):
	#	velocity.x -= 1
	if Input.is_action_pressed("ui_right"):
		direction.x += 1	
	velocity = direction * speed * speed_mult
	move_and_slide()
	# Limit the player's x position to the left half of the screen
	if position.x > get_viewport_rect().size.x / 2:
		position.x = get_viewport_rect().size.x / 2
	_update_charge(delta)

func _update_charge(delta):
	if speed == 0:   # 游戏结束了
		charge = 0.0
	elif Input.is_action_pressed("ui_right"):
		charge = minf(1.0, charge + delta / CHARGE_TIME)
	elif charge > 0.0:   # 刚刚松开
		released_charge = charge
		release_timer = RELEASE_WINDOW
		charge = 0.0
		if late_timer > 0.0 and is_instance_valid(late_ball):   # 球刚碰过，现在才松开
			apply_charged_shot(late_ball, released_charge)
			late_ball = null; late_timer = 0.0
	release_timer = maxf(0.0, release_timer - delta)
	late_timer = maxf(0.0, late_timer - delta)
	queue_redraw()

# 球碰到球拍时，由 Ball.gd 调用
func on_ball_hit(ball):
	ball_hit.emit(ball)
	if release_timer > 0.0 and released_charge >= MIN_CHARGE:
		apply_charged_shot(ball, released_charge)
		release_timer = 0.0
	elif charge >= MIN_CHARGE:
		late_ball = ball
		late_timer = LATE_WINDOW

func apply_charged_shot(ball, c: float):
	if c < MIN_CHARGE: return
	var dir_y: float = signf(ball.velocity.y) if absf(ball.velocity.y) > 0.01 else (1.0 if randf() < 0.5 else -1.0)
	ball.velocity = Vector2(1.0, dir_y * (0.8 + 0.7 * c))   # 往右飞，蓄得越满角度越陡
	ball.speed_boost = 1.0 + 0.8 * c                          # 蓄满 = 1.8 倍速度
	released_charge = 0.0
	charged_shot.emit(ball, c)

# 画能量条（球拍左边一条竖条，蓄得越满越长、越红）
func _draw():
	var c := charge if charge > 0.0 else (released_charge if release_timer > 0.0 else 0.0)
	if c <= 0.0: return
	var h := 100.0
	draw_rect(Rect2(-34, -h / 2, 8, h), Color(0, 0, 0, 0.5))
	draw_rect(Rect2(-34, h / 2 - h * c, 8, h * c), Color("ffd23f").lerp(Color("eb4b4b"), c))
