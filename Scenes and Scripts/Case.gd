extends VBoxContainer
var case_opening = preload("res://Scenes and Scripts/CaseSystem.tscn")
# Add this line at the top of your script to define the signal
signal item_unlocked(shape, texture)
export (Array, Texture) var blue_items
export (Array, Texture) var purple_items
export (Array, Texture) var red_items
export (Array, Texture) var special_items
var item_list = {}
var items = []

func _ready():
	Global.load_coins()  # Load the coin count
	item_list = {
	"blue_items": blue_items,
	"purple_items": purple_items,
	"red_items": red_items,
	"special_items": special_items
	}
	#get_node("Case").connect("spin_done", self, "_on_spin_done")
# In your loot box script
func _on_Button_pressed():
	if Global.coins >= 0:  # Check if the player has enough coins
		Global.coins -= 0  # Deduct the cost of opening the box
		Global.save_coins()  # Save the updated coin count
		var opening_scene = case_opening.instance()
		opening_scene.item_list = item_list
		opening_scene.items = items
		opening_scene.connect("item_selected", self, "_on_item_selected")
		get_tree().get_root().add_child(opening_scene)
	else:
		print("Not enough coins to open the box.")

func _on_item_selected(item_texture):
	for i in range(items.size()):
		if items[i]['texture'] == str(item_texture):
			items[i]['is_locked'] = false
			save_unlocked_item(items[i])  # Save the unlocked item
			print ("The item is unlocked")
			self.add_to_group("unlocked_items")  # Add this node to a group
			break

func save_unlocked_item(item):
	var save_file = ConfigFile.new()
	if save_file.load("user://items.cfg") == OK:
		save_file.set_value("items", item['texture'], item['is_locked'])
	else:
		save_file.set_value("items", item['texture'], item['is_locked'])
	save_file.save("user://items.cfg")
	
func _on_spin_done(texture):
	for i in range(items.size()):
		if items[i]['texture'] == str(texture):
			items[i]['is_locked'] = false
			save_unlocked_item(items[i])  # Save the unlocked item
			print ("The item is unlocked")
			break
