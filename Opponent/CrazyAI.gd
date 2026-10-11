extends CharacterBody2D

var ball
var speed = 300  # Define the speed variable
var colors = Color.MAROON
var frame_count = 0
func _ready():
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING  # 和 Godot 3 一样：没有"地板"概念
	randomize()
	ball = get_parent().find_child("CrazyBall")

func _physics_process(delta):
	speed = ball.speed # Set the AI speed to be the same as the ball speed
	velocity = Vector2(0,get_opponent_direction()) * speed
	move_and_slide()

func get_opponent_direction():
	frame_count += 1
	var random_movement = 0
	if frame_count % 60 == 0: # Apply random movement every 60 frames
		random_movement = randf_range(-1, 1)
	if abs(ball.position.y - position.y) > 25:
		if ball.position.y > position.y: return 1 + random_movement
		else: return -1 + random_movement
	else: return 0 + random_movement
