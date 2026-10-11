# Backpack.gd —— 背包：列出拥有的所有物品（球拍皮肤 + 球拖尾），按稀有度上色，可以装备。
# 皮肤只能从箱子(CASES)里开出来；以前商店里买过的皮肤会自动迁移进来（见 Loot.migrate_shop_unlocks）。
extends Control

const GameFont = preload("res://Mechanics/GameFont.gd")
const CARD := Vector2(170, 236)

var content: VBoxContainer
var header: Label

func _ready():
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var th: Theme = load("res://assets/UI/Theme/UI.tres").duplicate()
	th.default_font = GameFont.get_font()
	theme = th
	var bg := ColorRect.new(); bg.color = Color("14151b"); bg.set_anchors_preset(Control.PRESET_FULL_RECT); add_child(bg)
	var title := _label("背包 / BACKPACK", 40, Color.WHITE); title.position = Vector2(40, 18); add_child(title)
	header = _label("", 18, Color(0.8, 0.8, 0.85)); header.position = Vector2(44, 76); add_child(header)
	var cases_btn := _button("开箱 CASES", Vector2(860, 26), Vector2(180, 48)); cases_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://Lootbox/CS2/CaseOpening.tscn"))
	var back_btn := _button("返回 BACK", Vector2(1056, 26), Vector2(180, 48)); back_btn.pressed.connect(_on_back)
	var sc := ScrollContainer.new(); sc.name = "Scroll"
	sc.position = Vector2(30, 110); sc.size = Vector2(1220, 595)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(sc)
	content = VBoxContainer.new(); content.add_theme_constant_override("separation", 14)
	content.custom_minimum_size = Vector2(1200, 0)
	sc.add_child(content)
	refresh()

func refresh():
	for c in content.get_children(): c.queue_free()
	var owned := 0; var total := 0
	for it in Loot.ITEMS:
		if it.get("default", false): continue
		total += 1
		if Loot.owns(it["id"]): owned += 1
	header.text = "已收集 Collected %d/%d   ·   开过箱子 Cases opened %d   ·   金币 Coins %s" % [owned, total, Loot.cases_opened, str(Global.coins)]
	_section("球拍皮肤 / PADDLE SKINS", Loot.owned_items("paddle"))
	_section("球拖尾 / BALL TRAILS", Loot.owned_items("trail"))
	var tip := _label("想要更多皮肤？去「开箱 CASES」用金币开箱。重复物品会自动换成金币。", 16, Color(0.7, 0.7, 0.75))
	content.add_child(tip)

func _section(title: String, items: Array):
	content.add_child(_label("%s  (%d)" % [title, items.size()], 24, Color("ffd23f")))
	var grid := GridContainer.new(); grid.columns = 6
	grid.add_theme_constant_override("h_separation", 26); grid.add_theme_constant_override("v_separation", 18)
	for it in items: grid.add_child(make_card(it))
	content.add_child(grid)

# 一张卡片：稀有度颜色边框 + 图片 + 名字 + 稀有度 + 装备按钮；已装备的金色粗边框高亮
func make_card(item: Dictionary) -> Control:
	var rarity := Loot.rarity_of(item)
	var equipped := Loot.is_equipped(item["id"])
	var card := Panel.new(); card.name = "Card_" + item["id"]
	card.custom_minimum_size = CARD
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("23252e") if not equipped else Color("2e2a1c")
	sb.border_color = Color("ffd23f") if equipped else rarity["color"]
	sb.set_border_width_all(6 if equipped else 2)
	sb.border_width_bottom = 10
	if not equipped: sb.border_color = rarity["color"]
	sb.set_corner_radius_all(6)
	card.add_theme_stylebox_override("panel", sb)
	if item["type"] == "paddle":
		var tr := TextureRect.new(); tr.texture = load(item["texture"])
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.position = Vector2(20, 14); tr.size = Vector2(CARD.x - 40, 100)
		card.add_child(tr)
	else:
		var g := Loot.trail_gradient(item["id"])
		if g:
			var gt := GradientTexture2D.new(); gt.gradient = g; gt.width = 128; gt.height = 24
			var tr := TextureRect.new(); tr.texture = gt; tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.position = Vector2(18, 52); tr.size = Vector2(CARD.x - 36, 26)
			card.add_child(tr)
		else:
			var none := _label("(无拖尾 no trail)", 14, Color(0.6, 0.6, 0.65)); none.position = Vector2(0, 52); none.size = Vector2(CARD.x, 24)
			none.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; card.add_child(none)
	var name_l := _label(item["name"], 15, Color.WHITE); name_l.position = Vector2(4, 120); name_l.size = Vector2(CARD.x - 8, 22)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; name_l.clip_text = true; card.add_child(name_l)
	var r_l := _label("%s %s" % [rarity["cn"], rarity["name"]], 12, rarity["color"]); r_l.position = Vector2(4, 144); r_l.size = Vector2(CARD.x - 8, 20)
	r_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; card.add_child(r_l)
	var b := Button.new(); b.name = "Equip"
	b.add_theme_font_override("font", GameFont.get_font()); b.add_theme_font_size_override("font_size", 16)
	b.position = Vector2(14, 176); b.size = Vector2(CARD.x - 28, 40)
	b.text = "已装备 ✓" if equipped else "装备 EQUIP"
	b.disabled = equipped
	var id: String = item["id"]
	b.pressed.connect(func():
		Loot.equip(id)
		refresh())
	card.add_child(b)
	return card

func _label(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new(); l.text = text
	l.add_theme_font_override("font", GameFont.get_font())
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l

func _button(text: String, pos: Vector2, sz: Vector2) -> Button:
	var b := Button.new(); b.text = text; b.position = pos; b.size = sz
	b.add_theme_font_override("font", GameFont.get_font()); b.add_theme_font_size_override("font_size", 18)
	add_child(b); return b

func _on_back():
	get_tree().change_scene_to_file("res://MainMenu.tscn")

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"): _on_back()
