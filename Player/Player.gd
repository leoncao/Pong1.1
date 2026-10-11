extends CharacterBody2D

var speed = 500

func _physics_process(delta):
	var velocity = Vector2.ZERO
	if Input.is_action_pressed("ui_up"):
		velocity.y -= 1
	if Input.is_action_pressed("ui_down"):
		velocity.y += 1
	#if Input.is_action_pressed("ui_left"):
	#	velocity.x -= 1
	if Input.is_action_pressed("ui_right"):
		velocity.x += 1	
	set_velocity(velocity * speed)
	move_and_slide()
	# Limit the player's x position to the left half of the screen
	if position.x > get_viewport().size.x / 2:
		position.x = get_viewport().size.x / 2
