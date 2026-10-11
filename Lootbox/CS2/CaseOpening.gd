# CaseOpening.gd —— CS2 风格开箱界面：横向滚动的物品带，慢慢减速，停在中间黄线下的就是你抽到的。
extends Control

const CARD_W := 150.0
const CARD_GAP := 10.0
const STRIDE := CARD_W + CARD_GAP     # 每张卡片占的宽度
const REEL_COUNT := 60                # 物品带上总共放多少张卡片
const WIN_INDEX := 50                 # 中奖卡片放在第几张（前面的都是"陪跑"）
const SPIN_TIME := 6.0                # 滚动时间(秒)
const REEL_W := 1000.0

var case_id := "pong_case"
var spinning := false
var last_tick_index := -1
var pending_result := {}

var coins_label: Label
var open_button: Button
var reel_window: Control
var strip: Control
var tick_player: AudioStreamPlayer
var reveal_player: AudioStreamPlayer
var popup: PanelContainer
var inventory_panel: PanelContainer

func _ready():
	Global.load_coins()
	_build_ui()
	_refresh_coins()
	_fill_strip(Loot.roll_item())   # 进来时先放一条静止的物品带

# ---------- 界面搭建（用代码生成，方便初学者一处看完） ----------
func _build_ui():
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = load("res://assets/UI/Theme/UI.tres")   # 用游戏原有的按钮样式
	var bg := ColorRect.new(); bg.color = Color("15161c"); bg.set_anchors_preset(Control.PRESET_FULL_RECT); add_child(bg)

	var title := _label(Loot.CASES[case_id]["name"].to_upper(), 40, Color.WHITE)
	title.position = Vector2(0, 40); title.size = Vector2(1280, 60)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)

	coins_label = _label("", 24, Color("ffd23f")); coins_label.position = Vector2(40, 40); add_child(coins_label)

	reel_window = Control.new()
	reel_window.name = "ReelWindow"
	reel_window.position = Vector2((1280 - REEL_W) / 2, 190); reel_window.size = Vector2(REEL_W, 190)
	reel_window.clip_contents = true          # 超出窗口的卡片不显示
	add_child(reel_window)
	var reel_bg := ColorRect.new(); reel_bg.color = Color("0c0d11"); reel_bg.size = reel_window.size; reel_window.add_child(reel_bg)
	strip = Control.new(); strip.name = "Strip"; strip.position = Vector2(0, 20); reel_window.add_child(strip)

	var marker := ColorRect.new()   # 中间的黄色指针
	marker.color = Color("ffd23f"); marker.size = Vector2(4, 190); marker.position = Vector2(REEL_W / 2 - 2, 0)
	reel_window.add_child(marker)

	open_button = _button("OPEN CASE  (%d + KEY %d COINS)" % [Loot.CASES[case_id]["price"], Loot.CASES[case_id]["key_price"]], Vector2(440, 420), Vector2(400, 55))
	open_button.pressed.connect(_on_open_pressed)
	var inv_btn := _button("INVENTORY", Vector2(440, 490), Vector2(195, 45)); inv_btn.pressed.connect(_show_inventory)
	var back_btn := _button("BACK", Vector2(645, 490), Vector2(195, 45)); back_btn.pressed.connect(_on_back_pressed)

	# 概率表
	var y := 560.0
	for t in Loot.RARITIES:
		var l := _label("■ %s (%s)  %.2f%%" % [t["name"], t["cn"], t["weight"]], 16, t["color"])
		l.position = Vector2(40, y); add_child(l); y += 24

	tick_player = AudioStreamPlayer.new(); tick_player.stream = load("res://assets/ping_pong_8bit_beeep.ogg"); tick_player.volume_db = -8; add_child(tick_player)
	reveal_player = AudioStreamPlayer.new(); add_child(reveal_player)

func _label(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new(); l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l

func _button(text: String, pos: Vector2, sz: Vector2) -> Button:
	var b := Button.new(); b.text = text; b.position = pos; b.size = sz; add_child(b); return b

func _refresh_coins():
	coins_label.text = "Coins: %s" % str(Global.coins)
	open_button.disabled = spinning or Global.coins < Loot.case_cost(case_id)

# 一张物品卡片：深色底 + 底部稀有度颜色条 + 图片 + 名字
func make_card(item: Dictionary) -> Control:
	var tier = Loot.RARITIES[item["tier"]]
	var card := Panel.new()
	card.custom_minimum_size = Vector2(CARD_W, 150); card.size = Vector2(CARD_W, 150)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("23252e"); sb.border_color = tier["color"]; sb.border_width_bottom = 8
	sb.set_corner_radius_all(4)
	card.add_theme_stylebox_override("panel", sb)
	if item["type"] == "paddle":
		var tr := TextureRect.new()
		tr.texture = load(item["texture"])
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.position = Vector2(10, 8); tr.size = Vector2(CARD_W - 20, 100)
		card.add_child(tr)
	else:   # 拖尾：用渐变色生成一条"彩带"图片
		var gt := GradientTexture2D.new(); gt.gradient = Loot.trail_gradient(item["id"]); gt.width = 128; gt.height = 24
		var tr := TextureRect.new(); tr.texture = gt
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.position = Vector2(15, 45); tr.size = Vector2(CARD_W - 30, 24)
		card.add_child(tr)
	var name_l := _label(item["name"], 13, Color.WHITE)
	name_l.position = Vector2(0, 112); name_l.size = Vector2(CARD_W, 20)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.clip_text = true
	card.add_child(name_l)
	return card

# 铺物品带：60 张随机卡片，第 50 张换成真正抽中的物品
func _fill_strip(winner: Dictionary):
	for c in strip.get_children(): c.queue_free()
	for i in REEL_COUNT:
		var it = winner if i == WIN_INDEX else Loot.roll_item()
		var card := make_card(it)
		card.position = Vector2(i * STRIDE, 0)
		strip.add_child(card)
	strip.position.x = 0

# ---------- 开箱 ----------
func _on_open_pressed():
	if spinning: return
	var result := Loot.open_case(case_id)   # 结果在动画开始前就决定好了（和 CS2 一样）
	if result.is_empty():
		return
	pending_result = result
	_fill_strip(result["item"])
	spinning = true
	_refresh_coins()
	if popup: popup.queue_free(); popup = null
	# 目标：让第 WIN_INDEX 张卡片停在指针下，并加一点随机偏移，看起来更真实
	var jitter := randf_range(-CARD_W * 0.4, CARD_W * 0.4)
	var target_x := REEL_W / 2 - (WIN_INDEX * STRIDE + CARD_W / 2 + jitter)
	last_tick_index = -1
	var tween := create_tween()
	tween.tween_property(strip, "position:x", target_x, SPIN_TIME)\
		.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)   # 先快后慢
	tween.finished.connect(_on_spin_finished)

func _process(_delta):
	if not spinning: return
	# 每当有新卡片经过指针就"嗒"一声
	var idx := int((REEL_W / 2 - strip.position.x) / STRIDE)
	if idx != last_tick_index:
		last_tick_index = idx
		tick_player.pitch_scale = randf_range(0.95, 1.1)
		tick_player.play()

func _on_spin_finished():
	spinning = false
	_refresh_coins()
	_show_reveal(pending_result)

func _show_reveal(result: Dictionary):
	var item: Dictionary = result["item"]
	var tier = Loot.RARITIES[item["tier"]]
	reveal_player.stream = load("res://assets/Sounds/391539__unlistenable__electro-win-sound.wav" if item["tier"] >= 3 else "res://assets/levelup.wav")
	reveal_player.play()
	popup = PanelContainer.new(); popup.name = "RevealPopup"
	var sb := StyleBoxFlat.new(); sb.bg_color = Color(0.08, 0.08, 0.1, 0.96); sb.border_color = tier["color"]
	sb.set_border_width_all(6); sb.set_corner_radius_all(8); sb.set_content_margin_all(20)
	popup.add_theme_stylebox_override("panel", sb)
	popup.position = Vector2(390, 150); popup.custom_minimum_size = Vector2(500, 380)
	var vb := VBoxContainer.new(); vb.alignment = BoxContainer.ALIGNMENT_CENTER; popup.add_child(vb)
	var t1 := _label("%s (%s)" % [tier["name"], tier["cn"]], 22, tier["color"]); t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; vb.add_child(t1)
	var card := make_card(item); var holder := CenterContainer.new(); holder.add_child(card); vb.add_child(holder)
	var t2 := _label(item["name"], 28, Color.WHITE); t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; vb.add_child(t2)
	var msg := "重复物品！已换成 +%d 金币" % result["refund"] if result["duplicate"] else "新物品！已放进背包"
	var t3 := _label(msg, 18, Color("ffd23f") if result["duplicate"] else Color("7CFC9A")); t3.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; vb.add_child(t3)
	var hb := HBoxContainer.new(); hb.alignment = BoxContainer.ALIGNMENT_CENTER; vb.add_child(hb)
	if not result["duplicate"]:
		var eq := Button.new(); eq.text = "EQUIP"; eq.pressed.connect(func(): Loot.equip(item["id"]); eq.text = "EQUIPPED ✓"; eq.disabled = true); hb.add_child(eq)
	var ok := Button.new(); ok.text = "OK"; ok.pressed.connect(func(): popup.queue_free(); popup = null); hb.add_child(ok)
	add_child(popup)
	# 弹出动画：从小变大
	popup.pivot_offset = popup.custom_minimum_size / 2; popup.scale = Vector2(0.6, 0.6)
	create_tween().tween_property(popup, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# ---------- 背包 ----------
func _show_inventory():
	if inventory_panel: inventory_panel.queue_free()
	inventory_panel = PanelContainer.new(); inventory_panel.name = "InventoryPanel"
	inventory_panel.position = Vector2(140, 90); inventory_panel.custom_minimum_size = Vector2(1000, 560)
	var root := VBoxContainer.new(); inventory_panel.add_child(root)
	root.add_child(_label("INVENTORY  (开过 %d 个箱子)" % Loot.cases_opened, 24, Color.WHITE))
	var sc := ScrollContainer.new(); sc.custom_minimum_size = Vector2(980, 450); root.add_child(sc)
	var grid := GridContainer.new(); grid.columns = 6; sc.add_child(grid)
	for it in Loot.ITEMS:
		if not Loot.inventory.has(it["id"]): continue
		var vb := VBoxContainer.new(); vb.add_child(make_card(it))
		var b := Button.new(); b.text = "EQUIP"
		var id: String = it["id"]
		b.pressed.connect(func(): Loot.equip(id); b.text = "EQUIPPED ✓")
		vb.add_child(b); grid.add_child(vb)
	var close := Button.new(); close.text = "CLOSE"; close.pressed.connect(func(): inventory_panel.queue_free(); inventory_panel = null); root.add_child(close)
	add_child(inventory_panel)

func _on_back_pressed():
	if spinning: return
	get_tree().change_scene_to_file("res://MainMenu.tscn")

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"): _on_back_pressed()
