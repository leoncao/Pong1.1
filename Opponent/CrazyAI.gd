extends KinematicBody2D

var ball
var speed = 300  # Define the speed variable
var colors = Color.maroon
var frame_count = 0
func _ready():
	randomize()
	ball = get_parent().find_node("CrazyBall")

func _physics_process(delta):
	speed = ball.speed # Set the AI speed to be the same as the ball speed
	move_and_slide(Vector2(0,get_opponent_direction()) * speed)

func get_opponent_direction():
	frame_count += 1
	var random_movement = 0
	if frame_count % 60 == 0: # Apply random movement every 60 frames
		random_movement = rand_range(-1, 1)
	if abs(ball.position.y - position.y) > 25:
		if ball.position.y > position.y: return 1 + random_movement
		else: return -1 + random_movement
	else: return 0 + random_movement
