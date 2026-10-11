extends ColorRect


@onready var godotSprite = $Control/GodotAnimatedSprite
@onready var godotTXT = $Control/Godot
@onready var lightFlikceringSound = $LightFlickerSound


func _ready():
	
	godotTXT.modulate = Color(1,1,1,0)
	var tween = create_tween()
	tween.tween_property(godotTXT, 'modulate', Color(1,1,1,1), 1)\
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_IN_OUT)
	

func _on_AnimationPlayTimer_timeout():
	godotSprite.play()
	lightFlikceringSound.play()

func _on_GodotAnimatedSprite_animation_finished():
	
	$ChangeSceneTimer.start()

func _on_ChangeSceneTimer_timeout():
	get_tree().change_scene_to_file("res://MainMenu.tscn")
	# this is called upon completion fo the bootup
	# You should add a get_tree().change_scene() to your title screen
