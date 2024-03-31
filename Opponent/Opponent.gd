extends KinematicBody2D

var speed = 200 # Reduced initial speed for the AI opponent
var ball
var colors = [Color.white, Color.lime, Color.yellow, Color.olive, Color.red, Color.white] # Array of colors for each difficulty level
var new_sprite = preload("res://assets/Paddle/final_evil_boss.png")
var frame_count = 0

func _ready():
	randomize()
	ball = get_parent().find_node("Ball")
	
func _physics_process(delta):
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

func increase_difficulty(difficultyLevel):
	speed += 25 # Increase speed by 50 when difficulty increases
	self.modulate = colors[difficultyLevel-1] # Change the color of the sprite based on the difficulty level
	if difficultyLevel == 6: # Assuming 6 is your last level
		$Sprite.texture = new_sprite
		$Sprite.scale = Vector2(2, 2)
		$CollisionPolygon2D.scale = Vector2(2,2) # Change the scale of the sprite to half its original size
