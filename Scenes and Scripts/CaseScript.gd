extends Control
# Add this line at the top of your script to define the signal
signal spin_done(texture)
onready var item_container = $"Case Scroll Container/Item Container"
onready var case_container = $"Case Scroll Container"
onready var panel = $Panel
var items = []
signal item_selected(item)

var blue_range = range(1,61)
var purple_range = range(61,90)
var red_range = range(90,100)

var item_list = {}
var texture_rects = []
var increase_value = 0
var index_number = 2
var high_limit = 270
var speed = 40
var case_stopped = false

func _ready():
	case_container.get_h_scrollbar().rect_scale.x = 0
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	for i in range(0,100):
		var chance = rng.randi_range(1, 100)
		if chance in blue_range:
			create_item("blue_items")
		elif chance in purple_range:
			create_item("purple_items")
		elif chance in red_range:
			create_item("red_items")
		else:
			create_item("special_items")
func _process(delta):
	if not case_stopped:
		increase_value += 1 * speed
		case_container.scroll_horizontal = increase_value
		if case_container.scroll_horizontal > high_limit:
			index_number += 1
			high_limit += 260
func create_item(item_type_key):
	var img_texture = randi() % item_list.get(item_type_key).size()
	var img = TextureRect.new()
	img.texture = item_list.get(item_type_key)[img_texture]
	texture_rects.append(img)
	item_container.add_child(img)
func _on_Timer_timeout():
	if speed > 0 and not case_stopped:
		speed -= 0.5
	elif speed <= 0:
		case_stopped = true
		panel.get_node("TextureRect").texture = texture_rects[index_number].texture
		panel.show()
		emit_signal("item_selected", texture_rects[index_number].texture)  # Emit the signal here

func _on_ButtonPanel_pressed():
	# Confirm the spin result
	var item_texture = panel.get_node("TextureRect").texture
	# Emit the signal with the texture of the spun item
	emit_signal("spin_done", item_texture)
	# Then delete the node
	queue_free()


func _on_Button_pressed():
	var item_texture = panel.get_node("TextureRect").texture
	# Emit the signal with the texture of the spun item
	emit_signal("spin_done", item_texture)
	# Then delete the node
	queue_free()

