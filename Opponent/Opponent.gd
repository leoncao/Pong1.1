extends CharacterBody2D

# 经典模式电脑球拍。难度数值都在 res://Mechanics/Difficulty.gd
const Difficulty = preload("res://Mechanics/Difficulty.gd")
const AIBrain = preload("res://Mechanics/AIBrain.gd")

signal charged_shot(ball, charge)   # BOSS 打出快球时发出（用来放特效）

var speed = Difficulty.AI_MAX_SPEED[0]   # 最大速度；游戏结束时会被设成 0
var ball
var colors = [Color.WHITE, Color.LIME, Color.YELLOW, Color.OLIVE, Color.RED, Color.WHITE] # Array of colors for each difficulty level
var new_sprite = preload("res://assets/Paddle/final_evil_boss.png")
var frame_count = 0
var speed_mult := 1.0   # 减速道具会把它变成 0.5
var level := 0
var brain := AIBrain.new()

func _ready():
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING  # 和 Godot 3 一样：没有"地板"概念
	randomize()
	ball = get_parent().find_child("Ball")

func set_level(l: int):
	level = l
	speed = Difficulty.level_value(Difficulty.AI_MAX_SPEED, l)

func _physics_process(delta):
	var target := brain.think(self, delta,
		Difficulty.level_value(Difficulty.AI_REACTION, level),
		Difficulty.level_value(Difficulty.AI_AIM_ERROR, level),
		Difficulty.level_value(Difficulty.AI_PREDICT, level),
		Difficulty.level_value(Difficulty.AI_AIM_BIAS, level),
		Difficulty.level_value(Difficulty.AI_LAPSE, level))
	var max_speed: float = speed * (1.0 if brain.approaching else Difficulty.AI_HOME_SPEED)
	velocity = Vector2(0, AIBrain.steer(position.y, target, max_speed)) * speed_mult
	move_and_slide()

# 球碰到这个球拍时由 Ball.gd 调用：BOSS 有概率打出斜线快球
func on_ball_hit(b):
	AIBrain.english(self, b, Difficulty.level_value(Difficulty.AI_RETURN_ANGLE, level))
	if level >= Difficulty.BOSS_LEVEL and randf() < Difficulty.BOSS_SMASH_CHANCE:
		var dir_y := 1.0 if randf() < 0.5 else -1.0
		b.velocity = Vector2(-1.0, dir_y * randf_range(1.0, 1.4))
		b.speed_boost = Difficulty.BOSS_SMASH_BOOST
		charged_shot.emit(b, 0.6)

func increase_difficulty(difficultyLevel):
	set_level(difficultyLevel)   # 原来是 speed += 25，现在按 Difficulty.gd 的表
	self.modulate = colors[difficultyLevel-1] # Change the color of the sprite based on the difficulty level
	if difficultyLevel == 6: # Assuming 6 is your last level
		$Sprite2D.texture = new_sprite
		$Sprite2D.scale = Vector2(2, 2)
		$CollisionPolygon2D.scale = Vector2(2,2) # Change the scale of the sprite to half its original size
