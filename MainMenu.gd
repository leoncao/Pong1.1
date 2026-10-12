extends Control

# 开箱系统：复制原来"CUSTOMIZATION"按钮(保持一样的字体和样式)，改成"CASES"放在它下面；
# 原来的商店按钮改成「背包 BACKPACK」（皮肤只从箱子里获得，不再用金币直接买）
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
	var bp_btn: Button = shop_box.get_node("Shop")
	bp_btn.text = "BACKPACK"   # 这是翻译 key，会自动显示成"背包"或"BACKPACK"
	_add_language_button()

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
	get_tree().change_scene_to_file("res://Lootbox/CS2/Backpack.tscn")   # 原来是商店 Customization.tscn

func _on_PatchNote_pressed():
	get_tree().change_scene_to_file("res://Scenes/What\'s New.tscn")

# 右上角的语言切换按钮：中文 ⇄ English（选择会保存，下次启动还是这个语言）
func _add_language_button():
	var b := Button.new()
	b.name = "LanguageButton"
	b.text = "LANG_TOGGLE"   # 英文界面显示"中文"，中文界面显示"English"
	b.theme = preload("res://Mechanics/UiStyle.gd").make_theme()
	b.position = Vector2(1120, 20); b.size = Vector2(140, 44)
	b.pressed.connect(func():
		Global.toggle_language()
		get_tree().reload_current_scene())
	add_child(b)

