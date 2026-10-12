# UiStyle.gd —— 代码生成的界面主题（按钮有明确的背景色、边框、文字颜色和字体）
# 不依赖 UI.tres：那个文件里的旧位图字体在 Godot 4.7 重新保存后坏了（所有字形大小为 0，按钮文字画不出来），
# 而且它的按钮背景是全透明的 → 在开箱界面里按钮完全看不见。
extends RefCounted

const GameFont = preload("res://Mechanics/GameFont.gd")

static func _box(bg: Color, border: Color, bw: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 14; sb.content_margin_right = 14
	sb.content_margin_top = 6; sb.content_margin_bottom = 6
	return sb

static func make_theme() -> Theme:
	var th := Theme.new()
	var f := GameFont.get_font()
	th.default_font = f
	th.default_font_size = 18
	th.set_font("font", "Button", f)
	th.set_font_size("font_size", "Button", 18)
	th.set_stylebox("normal", "Button", _box(Color("2a2d38"), Color("5a6078"), 2))
	th.set_stylebox("hover", "Button", _box(Color("3a3f52"), Color("ffd23f"), 2))
	th.set_stylebox("pressed", "Button", _box(Color("4a3f1c"), Color("ffd23f"), 3))
	th.set_stylebox("disabled", "Button", _box(Color("1d1f27"), Color("33364a"), 2))
	th.set_stylebox("focus", "Button", _box(Color(0, 0, 0, 0), Color("ffd23f"), 2))
	th.set_color("font_color", "Button", Color("f2f2f2"))
	th.set_color("font_hover_color", "Button", Color("ffd23f"))
	th.set_color("font_pressed_color", "Button", Color("ffffff"))
	th.set_color("font_focus_color", "Button", Color("f2f2f2"))
	th.set_color("font_disabled_color", "Button", Color("7a7f92"))
	th.set_color("font_color", "Label", Color("f2f2f2"))
	th.set_font("font", "Label", f)
	return th
