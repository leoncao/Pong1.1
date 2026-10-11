extends CharacterBody2D
var speed = 250
# velocity: Godot 4 的 CharacterBody2D 自带 velocity 属性，这里直接使用
var speed_boost := 1.0   # 蓄力回击时临时加速，会慢慢恢复到 1
var last_hitter = null   # 最后碰到球的球拍（道具效果给谁）
func _ready():
	randomize()
	velocity.x = [-1,1][randi() % 2]
	velocity.y = [-0.8,0.8][randi() % 2]
func _physics_process(delta):
	speed_boost = move_toward(speed_boost, 1.0, delta * 0.3)
	var collision_object = move_and_collide(velocity * speed * speed_boost * delta)
	if collision_object:
		velocity = velocity.bounce(collision_object.get_normal())
		var collider = collision_object.get_collider()
		if collider and collider.is_in_group("paddles"):
			last_hitter = collider
			if collider.has_method("on_ball_hit"):
				collider.on_ball_hit(self)   # 让球拍知道被球碰了（蓄力回击用）
		$CollisionSound.play()
		play_squash_stretch()
		var cm = get_tree().root.get_node_or_null("CrazyMode")
		if cm and cm.crazyMode:
			speed += 10  # Increase the ball speed
	var direction = velocity.normalized()
	look_at(global_position + direction)
	rotation -= PI / 2		
	
func play_squash_stretch():
	$AnimationPlayer.play("squash_stretch")
	
func stop_ball():
	speed = 0
func restart_ball():
	speed = 250
	speed_boost = 1.0
	last_hitter = null
	velocity.x = [-1,1][randi() % 2]
	velocity.y = [-0.8,0.8][randi() % 2]
