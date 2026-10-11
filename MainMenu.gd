extends Control

# 开箱系统：复制"CUSTOMIZATION"按钮(保持一样的字体和样式)，改成"CASES"放在它下面
func _ready():
	var shop_box = $MarginContainer3/VBoxContainer/MarginContainer3
	var cases_box = shop_box.duplicate()
	cases_box.name = "MarginContainerCases"
	shop_box.add_sibling(cases_box)
	var cases_btn: Button = cases_box.get_node("Shop")
	cases_btn.name = "Cases"
	cases_btn.text = "CASES"
	for c in cases_btn.pressed.get_connections():
		cases_btn.pressed.disconnect(c["callable"])
	cases_btn.pressed.connect(_on_Cases_pressed)

func _on_Cases_pressed():
	get_tree().change_scene_to_file("res://Lootbox/CS2/CaseOpening.tscn")


func _on_Play_pressed():
	get_tree().change_scene_to_file("res://Level/Level.tscn")

func _on_How_to_Play_pressed():
	get_tree().change_scene_to_file("res://Scenes/HowToPlay.tscn")

func _on_crazyMode_pressed():
	get_tree().change_scene_to_file("res://Level/CrazyMode.tscn")

func _on_Credit_pressed():
	get_tree().change_scene_to_file("res://godot-credits-master/GodotCredits.tscn")

func _on_Quit_pressed():
	get_tree().quit() # Replace with function body.

func _on_Shop_pressed():
	get_tree().change_scene_to_file("res://Scenes/Customization.tscn")

func _on_PatchNote_pressed():
	get_tree().change_scene_to_file("res://Scenes/What\'s New.tscn")
