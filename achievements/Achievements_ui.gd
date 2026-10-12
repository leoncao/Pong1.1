extends Node2D

# Preload your locked and unlocked textures
var locked_texture = preload("res://achievements/achievement_locked.png")
var unlocked_texture = preload("res://achievements/achievement_unlock.png")
func _ready():
	update_ui()

func update_ui():
	# Get the ScrollContainer node
	var scroll_container = get_node("ScrollContainer")
	# Get the VBoxContainer node
	var vbox_container = scroll_container.get_node("VBoxContainer")
	# Clear the VBoxContainer
	for child in vbox_container.get_children():
		child.queue_free()
	# Add achievements to the VBoxContainer
	for achievement_id in Achievements.achievements.keys():
		var achievement = Achievements.achievements[achievement_id]
		var hbox_container = HBoxContainer.new()
		var name_label = Label.new()
		name_label.text = tr(achievement["name"])
		hbox_container.add_child(name_label)
		var status_texture = TextureRect.new()
		if achievement["unlocked"]:
			status_texture.texture = unlocked_texture
		else:
			status_texture.texture = locked_texture
		hbox_container.add_child(status_texture)
		vbox_container.add_child(hbox_container)
