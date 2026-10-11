extends CharacterBody2D

# 疯狂模式电脑球拍：速度跟着球速走，并且随存活时间越来越准（数值见 Difficulty.gd）
const Difficulty = preload("res://Mechanics/Difficulty.gd")
const AIBrain = preload("res://Mechanics/AIBrain.gd")

var ball
var speed = 300  # Define the speed variable
var colors = Color.MAROON
var frame_count = 0
var speed_mult := 1.0   # 减速道具会把它变成 0.5
var brain := AIBrain.new()

func _ready():
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING  # 和 Godot 3 一样：没有"地板"概念
	randomize()
	ball = get_parent().find_child("CrazyBall")

# 0 = 刚开局，1 = 已经活了 CRAZY_RAMP_TIME 秒
func ramp() -> float:
	var t = get_parent().get("alive_time")
	return clampf((t if t != null else 0.0) / Difficulty.CRAZY_RAMP_TIME, 0.0, 1.0)

func on_ball_hit(b):
	AIBrain.english(self, b, lerpf(Difficulty.CRAZY_RETURN_ANGLE.x, Difficulty.CRAZY_RETURN_ANGLE.y, ramp()))

func _physics_process(delta):
	if true:   # (游戏结束时整个场景会暂停，所以这里不用再判断)
		var r := ramp()
		speed = ball.speed * lerpf(Difficulty.CRAZY_SPEED_FACTOR.x, Difficulty.CRAZY_SPEED_FACTOR.y, r)
		var target := brain.think(self, delta,
			lerpf(Difficulty.CRAZY_REACTION.x, Difficulty.CRAZY_REACTION.y, r),
			lerpf(Difficulty.CRAZY_AIM_ERROR.x, Difficulty.CRAZY_AIM_ERROR.y, r), 1.0,
			lerpf(Difficulty.CRAZY_AIM_BIAS.x, Difficulty.CRAZY_AIM_BIAS.y, r),
			lerpf(Difficulty.CRAZY_LAPSE.x, Difficulty.CRAZY_LAPSE.y, r))
		var max_speed: float = maxf(speed, 300.0) * (1.0 if brain.approaching else Difficulty.AI_HOME_SPEED)
		velocity = Vector2(0, AIBrain.steer(position.y, target, max_speed)) * speed_mult
	move_and_slide()
