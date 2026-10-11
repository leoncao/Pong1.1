extends ColorRect


@onready var godotSprite = $Control/GodotAnimatedSprite
@onready var tween = $Tween
@onready var godotTXT = $Control/Godot
@onready var lightFlikceringSound = $LightFlickerSound


func _ready():
	
	tween.interpolate_property(godotTXT, 'modulate', Color(1,1,1,0), Color(1,1,1,1),
	 1, Tween.TRANS_BOUNCE, Tween.EASE_IN_OUT)
	tween.start()
	

func _on_AnimationPlayTimer_timeout():
	godotSprite.play()
	lightFlikceringSound.play()

func _on_GodotAnimatedSprite_animation_finished():
	
	$ChangeSceneTimer.start()

func _on_ChangeSceneTimer_timeout():
	get_tree().change_scene_to_file("res://MainMenu.tscn")
	# this is called upon completion fo the bootup
	# You should add a get_tree().change_scene() to your title screen
