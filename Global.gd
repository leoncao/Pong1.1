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

# ================= 语言（中文 / English）=================
# 翻译表：res://localization/strings.csv（Godot 导入后生成 .translation 文件，在 project.godot 里登记）
const SETTINGS_PATH := "user://settings.cfg"
const CJK_FONT := preload("res://assets/fonts/NotoSansSC-subset.otf")
var language := ""   # "zh_CN" 或 "en"

func _ready():
	load_language()
	# 每个新出现的界面节点，都给它的字体加上"中文备用字体"，这样任何字体都能显示中文
	get_tree().node_added.connect(_on_node_added)
	_add_cjk_fallback(ThemeDB.fallback_font)

func load_language():
	var cf := ConfigFile.new()
	if cf.load(SETTINGS_PATH) == OK:
		language = cf.get_value("settings", "language", "")
	if language == "":
		# 第一次启动：跟随系统语言（系统是中文就用中文，否则英文）
		language = "zh_CN" if OS.get_locale_language() == "zh" else "en"
	TranslationServer.set_locale(language)

func set_language(lang: String):
	language = lang
	TranslationServer.set_locale(lang)
	var cf := ConfigFile.new()
	cf.load(SETTINGS_PATH)
	cf.set_value("settings", "language", lang)
	cf.save(SETTINGS_PATH)

func toggle_language():
	set_language("en" if language == "zh_CN" else "zh_CN")

var _fixed_fonts := {}
func _add_cjk_fallback(f: Font):
	if f == null or f == CJK_FONT or _fixed_fonts.has(f.get_instance_id()): return
	_fixed_fonts[f.get_instance_id()] = true
	if f is FontVariation and f.base_font:
		_add_cjk_fallback(f.base_font)
	var fb: Array[Font] = f.fallbacks
	if not fb.has(CJK_FONT):
		fb.append(CJK_FONT)
		f.fallbacks = fb

func _on_node_added(n: Node):
	if n is Control:
		_add_cjk_fallback.call_deferred(n.get_theme_font("font"))
		if n is RichTextLabel:
			_add_cjk_fallback.call_deferred(n.get_theme_font("normal_font"))
