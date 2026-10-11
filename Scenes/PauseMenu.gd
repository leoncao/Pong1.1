extends CanvasLayer

var currentGameMode = null

func set_game_mode(gameMode):
	currentGameMode = gameMode

func _on_ResumeButton_pressed():
	get_tree().paused = false
	currentGameMode.hide_pause_menu()

func _on_MainMenuButton_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://MainMenu.tscn")

func _on_QuitButton_pressed():
	get_tree().quit()


func _on_Credit_pressed():
	get_tree().change_scene_to_file("res://assets/godot-credits-master/GodotCredits.tscn")
