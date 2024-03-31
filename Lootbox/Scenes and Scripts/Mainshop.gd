extends Control

# Called when the node enters the scene tree for the first time.
func _ready():
	$TotalCoinsLabel.text = "Total Coins: " + str(Global.coins)  # Display the total coins earned across all game sessions


func _on_Button_pressed():
	get_tree().change_scene("res://MainMenu.tscn")
