extends Line2D

@export var length =50
var point = Vector2()

func _ready():
	# 开箱抽到并装备的拖尾颜色
	var g = Loot.equipped_trail_gradient()
	if g:
		gradient = g

func _process(_delta):
	global_position = Vector2(0,0)
	global_rotation = 0
	
	point = get_parent().global_position
	
	add_point(point)
	while get_point_count()>length:
		remove_point(0)
