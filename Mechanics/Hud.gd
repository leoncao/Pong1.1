# Hud.gd —— 屏幕上方的信息栏（比分、等级、BOSS 提示、道具剩余时间、蓄力提示）
extends CanvasLayer

const GameFont = preload("res://Mechanics/GameFont.gd")

var main_label: Label
var sub_label: Label
var boss_label: Label
var effects_label: Label
var hint_label: Label
var flash_label: Label
var _t := 0.0

func build(_mode: String):
	layer = 5
	main_label = _mk(Vector2(440, 24), Vector2(400, 56), 44, Color.WHITE)
	main_label.name = "HudMain"
	sub_label = _mk(Vector2(290, 78), Vector2(700, 26), 17, Color(0.82, 0.82, 0.88))
	boss_label = _mk(Vector2(190, 106), Vector2(900, 34), 24, Color("ffb347"))
	effects_label = _mk(Vector2(240, 650), Vector2(800, 26), 18, Color("7CFC9A"))
	hint_label = _mk(Vector2(756, 692), Vector2(510, 24), 14, Color(1, 1, 1, 0.55))
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint_label.text = "按住 → 蓄力回击 / Hold → to charge a power shot"
	flash_label = _mk(Vector2(140, 300), Vector2(1000, 60), 34, Color("ffd23f"))
	flash_label.visible = false

func _mk(pos: Vector2, sz: Vector2, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.position = pos; l.size = sz
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", GameFont.get_font())
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l

func _process(delta):
	_t += delta
	if boss_label.text != "":
		boss_label.modulate.a = 0.55 + 0.45 * absf(sin(_t * 4.0))   # BOSS 提示一闪一闪

# 经典模式：玩家分数显示成 "12/30"
func set_classic(player_score: int, opponent_score: int, level: int):
	main_label.text = "%d/30" % player_score
	sub_label.text = "得分 SCORE   ·   等级 LEVEL %d/6   ·   对手 AI %d/30" % [level, opponent_score]
	if player_score >= 29:
		boss_label.text = "!! BOSS 出现！再得 1 分获胜 / BOSS FIGHT — 1 point to win !!"
		boss_label.add_theme_color_override("font_color", Color("eb4b4b"))
	elif player_score >= 25:
		boss_label.text = "BOSS 即将来临 / Boss incoming — 还差 %d 分 (%d to go)" % [29 - player_score, 29 - player_score]
		boss_label.add_theme_color_override("font_color", Color("ffb347"))
	else:
		boss_label.text = ""
		boss_label.modulate.a = 1.0

# 疯狂模式：时间、最高分、本局金币、连击倍率
func set_crazy(seconds: float, score: int, best: int, coins: float, combo: int, mult: float):
	main_label.text = "%02d:%02d" % [int(seconds) / 60, int(seconds) % 60]
	sub_label.text = "得分 SCORE %d   ·   最高 BEST %d   ·   本局金币 COINS +%.1f" % [score, best, coins]
	boss_label.text = ("连击 COMBO %d   金币 ×%.1f" % [combo, mult]) if combo > 0 else ""
	boss_label.add_theme_color_override("font_color", Color("ffd23f"))

func set_effects(effects: Dictionary):
	var parts := []
	for key in effects:
		var e = effects[key]
		parts.append("%s %s %.0fs" % [e["label"], e["who"], ceilf(e["time_left"])])
	effects_label.text = "   ".join(parts)

func flash(text: String, color: Color = Color("ffd23f")):
	flash_label.text = text
	flash_label.add_theme_color_override("font_color", color)
	flash_label.visible = true
	flash_label.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(1.6)
	tw.tween_property(flash_label, "modulate:a", 0.0, 0.6)
	tw.tween_callback(func(): flash_label.visible = false)
