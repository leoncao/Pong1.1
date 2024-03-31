extends KinematicBody2D

var speed = 600
var velocity = Vector2.ZERO

func _ready():
	randomize()
	velocity.x = [-1,1][randi() % 2]
	velocity.y = [-0.8,0.8][randi() % 2]

func _physics_process(delta):
	var collision_object = move_and_collide(velocity * speed * delta)
	if collision_object:
		velocity = velocity.bounce(collision_object.normal)
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
	velocity.x = [-1,1][randi() % 2]
	velocity.y = [-0.8,0.8][randi() % 2]
