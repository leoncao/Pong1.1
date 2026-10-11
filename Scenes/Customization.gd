extends Node2D

var items = [
	{'texture': "res://assets/Paddle/initialboss_pub.png", 'is_locked': true,'price': 0},
	{'texture': "res://assets/Paddle/door_green.png",'is_locked': true,'price': 50},
	{'texture': "res://assets/Paddle/paddle_cadpat_green.png",'is_locked': true,'price': 50},
	{'texture': "res://assets/Paddle/levelingrod_rare.png",'is_locked': true,'price': 200}
	]

var current_item_index = 0
#var item_prices = {
	#"res://assets/Paddle/atheboss.png": 0,
	#"res://assets/Paddle/door.png": 10,
	#"res://assets/Paddle/paddle_cadpat.png": 50,
	#"res://Assets/Paddle/.png":1000,
	#"res://Assets/Paddle/Paddle-boss_100.png": 2000, # Add more items...
#3#}

func _ready():

	# Load the unlocked state
	var save_file = ConfigFile.new()
	if save_file.load("user://unlocked.cfg") == OK:
		for item in items:
			if save_file.has_section_key("unlocked", item['texture']):
				item['is_locked'] = not save_file.get_value("unlocked", item['texture'])
	update_item_display()


func update_item_display():
	var item = items[current_item_index]
	$Sprite2D.texture = ResourceLoader.load(item['texture'])  # Use ResourceLoader.load() instead of load()
	if item['is_locked']:
		$Sprite2D.modulate = Color.GRAY
		$PriceLabel.text = "Price: " + str(item['price'])
	else:
		$Sprite2D.modulate = Color.WHITE
		$PriceLabel.text = "Unlocked"
		
func _on_item_unlocked(texture):
	# Update the items array
	for item in items:
		if item['texture'] == texture:
			item['is_locked'] = false
	update_item_display()  # Update the display
	# Save the unlocked state
	var save_file = ConfigFile.new()
	save_file.set_value("unlocked", true)
	save_file.save("user://unlocked.cfg")
#
func _on_SelectButton_pressed():
	var item = items[current_item_index]
	if item['is_locked']:
		# Check if the player has enough coins
		if Global.coins >= item['price']:  # Compare with the item's price
			Global.coins -= item['price']  # Deduct the cost from the player's coins
			item['is_locked'] = false  # Unlock the item
			update_item_display()
			Global.save_coins()
			# Don't forget to save the updated coin count and unlocked item
		else:
			show_message("You don't have enough coins.")
			#_on_MessageTimer_timeout()
	else:
		save_selection(item)
func show_message(message):
	$MessageLabel.text = str(message)
	$MessageTimer.start()

func _on_MessageTimer_timeout():
	$MessageLabel.text = ""  # Clear the message

func save_selection(item):
	var save_file = ConfigFile.new()
	save_file.load("user://selection.cfg")  # Load the file (even if it doesn't exist yet)
	save_file.set_value("selection", "texture", item['texture'])
	var error = save_file.save("user://selection.cfg")
	if error != OK:
		print("Error saving file: ", error)  # Print an error message if the file is not saved correctly

func _on_RightButton_pressed():
	current_item_index = int(fposmod(current_item_index + 1, items.size()))
	update_item_display()

func _on_LeftButton_pressed():
	current_item_index = int(fposmod(current_item_index - 1, items.size()))
	update_item_display()

func _on_Play_pressed():
	get_tree().change_scene_to_file("res://Level/Level.tscn")

func _on_BackButton_pressed():
	get_tree().change_scene_to_file("res://MainMenu.tscn")
	
func _exit_tree():
	# Save the unlocked state
	var save_file = ConfigFile.new()
	for item in items:
		if not item['is_locked']:
			save_file.set_value("unlocked", item['texture'], true)
	var error = save_file.save("user://unlocked.cfg")
	if error != OK:
		print("Error saving file: ", error)

func _on_Play2_pressed():
	get_tree().change_scene_to_file("res://Level/CrazyMode.tscn")
