# GameFont.gd —— 游戏原有字体 Anta + 中文备用字体（网页版没有系统中文字体，所以要自带）
extends RefCounted

static var _font: Font

static func get_font() -> Font:
	if _font == null:
		var fv := FontVariation.new()
		fv.base_font = load("res://assets/Anta-Regular.ttf")
		fv.fallbacks = [load("res://assets/fonts/NotoSansSC-subset.otf")]
		_font = fv
	return _font
