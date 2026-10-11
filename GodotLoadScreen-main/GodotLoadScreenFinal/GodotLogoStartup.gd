extends AnimatedSprite2D


@onready var particles = $GPUParticles2D


func _on_AnimatedSprite_animation_finished():
	particles.set_emitting(true)
