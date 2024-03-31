extends KinematicBody2D

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
	move_and_slide(velocity * speed)
	# Limit the player's x position to the left half of the screen
	if position.x > get_viewport().size.x / 2:
		position.x = get_viewport().size.x / 2
