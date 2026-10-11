extends CharacterBody2D

var speed = 600
# velocity: Godot 4 的 CharacterBody2D 自带 velocity 属性，这里直接使用
var speed_boost := 1.0   # 蓄力回击时临时加速，会慢慢恢复到 1
var last_hitter = null   # 最后碰到球的球拍（道具效果给谁）
var rally_mult := 1.0     # 同一回合里每次击球都会稍微加速（防止无限对打）
var serve_paddle = null   # 发球方的球拍：倒计时期间球"贴"在它前面
var serve_dir := 1.0      # 发球方向：+1 往右，-1 往左
const SERVE_OFFSET := 75.0
const Difficulty = preload("res://Mechanics/Difficulty.gd")

# 得分方发球：球放到发球方球拍前面，等倒计时结束再发
func prepare_serve(paddle, dir: float):
	serve_paddle = paddle
	serve_dir = dir
	speed = 0
	_hold_serve()

func _hold_serve():
	global_position = Vector2(serve_paddle.global_position.x + serve_dir * SERVE_OFFSET,
		clampf(serve_paddle.global_position.y, 60.0, 660.0))
	var trail = get_node_or_null("BallTrail")   # 球"瞬移"到发球位置：清掉拖尾，避免画出一条横穿屏幕的线
	if trail: trail.call_deferred("clear_points")

func _ready():
	randomize()
	velocity.x = [-1,1][randi() % 2]
	velocity.y = [-0.8,0.8][randi() % 2]

func _physics_process(delta):
	if speed == 0 and serve_paddle != null and is_instance_valid(serve_paddle):
		_hold_serve()   # 跟着发球方的球拍上下移动
		return
	speed_boost = move_toward(speed_boost, 1.0, delta * 0.3)
	var collision_object = move_and_collide(velocity * speed * speed_boost * rally_mult * delta)
	if collision_object:
		velocity = velocity.bounce(collision_object.get_normal())
		var collider = collision_object.get_collider()
		if collider and collider.is_in_group("paddles"):
			last_hitter = collider
			rally_mult = minf(Difficulty.RALLY_MAX, rally_mult + Difficulty.RALLY_STEP)
			if collider.has_method("on_ball_hit"):
				collider.on_ball_hit(self)   # 让球拍知道被球碰了（蓄力回击用）
		$CollisionSound.play()
		play_squash_stretch()
		
		# Rotate the ball to face the direction of travel
	var direction = velocity.normalized()
	look_at(global_position + direction)

	# If your sprite is not facing right by default, adjust the rotation here
	# For example, if it's facing up, subtract 90 degrees (in radians)
	rotation -= PI / 2
		
func play_squash_stretch():
	$AnimationPlayer.play("squash_stretch")

func stop_ball():
	speed = 0

func restart_ball():
	speed = 600
	speed_boost = 1.0
	rally_mult = 1.0
	last_hitter = null
	velocity.x = [-1,1][randi() % 2]
	velocity.y = [-0.8,0.8][randi() % 2]
	if serve_paddle != null and is_instance_valid(serve_paddle):
		# 朝对手方向发球，上下角度随机，速度大小和原来一样
		var vy := randf_range(0.35, 0.8) * (1.0 if randf() < 0.5 else -1.0)
		velocity = Vector2(serve_dir, vy).normalized() * Vector2(1, 0.8).length()
	serve_paddle = null
