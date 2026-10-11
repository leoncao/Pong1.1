extends CharacterBody2D

var speed = 500

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
	velocity = direction * speed
	move_and_slide()
	# Limit the player's x position to the left half of the screen
	if position.x > get_viewport_rect().size.x / 2:
		position.x = get_viewport_rect().size.x / 2
