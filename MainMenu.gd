extends Control


func _on_Play_pressed():
	get_tree().change_scene("res://Level/Level.tscn")

func _on_How_to_Play_pressed():
	get_tree().change_scene("res://Scenes/HowToPlay.tscn")

func _on_crazyMode_pressed():
	get_tree().change_scene("res://Level/CrazyMode.tscn")

func _on_Credit_pressed():
	get_tree().change_scene("res://godot-credits-master/GodotCredits.tscn")

func _on_Quit_pressed():
	get_tree().quit() # Replace with function body.

func _on_Shop_pressed():
	get_tree().change_scene("res://Scenes/Customization.tscn")

func _on_PatchNote_pressed():
	get_tree().change_scene("res://Scenes/What\'s New.tscn")
