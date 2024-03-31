extends Node

var unlocked_items = {}
var coins = 0

func save_coins():
	var save_file = ConfigFile.new()
	save_file.set_value("data", "coins", coins)
	save_file.save("user://savefile.cfg")

func load_coins():
	var save_file = ConfigFile.new()
	if save_file.load("user://savefile.cfg") == OK:
		if save_file.has_section_key("data", "coins"):
			coins = save_file.get_value("data", "coins")
