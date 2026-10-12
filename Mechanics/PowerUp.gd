# PowerUp.gd —— 场地中间随机出现的道具。球碰到就触发效果。
extends Area2D

signal collected(kind: String, ball: Node)

const GameFont = preload("res://Mechanics/GameFont.gd")
const RADIUS := 30.0        # 画出来的大小
const PICKUP_RADIUS := 40.0 # 实际拾取范围比画的大一点，更容易吃到
const DRIFT := 45.0         # 上下慢慢漂动的幅度
const INFO := {
	"long":  {"color": Color("7CFC9A"), "text": "PU_LONG_ICON", "name": "PU_LONG"},
	"multi": {"color": Color("ffb347"), "text": "PU_MULTI_ICON", "name": "PU_MULTI"},
	"slow":  {"color": Color("6ad1ff"), "text": "PU_SLOW_ICON", "name": "PU_SLOW"},
}

var kind := "long"
var life := 14.0   # 14 秒没人碰就消失
var _t := 0.0
var _base_y := 0.0

func _ready():
	add_to_group("PowerUp")
	var cs := CollisionShape2D.new()
	var shape := CircleShape2D.new(); shape.radius = PICKUP_RADIUS
	_base_y = position.y
	cs.shape = shape; add_child(cs)
	var l := Label.new()
	l.text = tr(INFO[kind]["text"])
	l.add_theme_font_override("font", GameFont.get_font())
	l.add_theme_font_size_override("font_size", 20)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.position = Vector2(-RADIUS, -RADIUS); l.size = Vector2(RADIUS * 2, RADIUS * 2)
	add_child(l)
	body_entered.connect(_on_body_entered)
	# 一闪一闪的呼吸动画
	scale = Vector2.ZERO
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func():
		var pulse := create_tween().set_loops()
		pulse.tween_property(self, "scale", Vector2(1.15, 1.15), 0.5)
		pulse.tween_property(self, "scale", Vector2.ONE, 0.5))

func _draw():
	var c: Color = INFO[kind]["color"]
	draw_circle(Vector2.ZERO, RADIUS, Color(c.r, c.g, c.b, 0.25))
	draw_arc(Vector2.ZERO, RADIUS, 0, TAU, 40, c, 4.0, true)

func _process(delta):
	life -= delta
	_t += delta
	position.y = _base_y + sin(_t * TAU / 5.0) * DRIFT   # 慢慢上下漂，扫过更多路线
	if life < 2.0:
		modulate.a = 0.4 + 0.6 * absf(sin(life * 10.0))   # 快消失时闪烁
	if life <= 0.0:
		queue_free()

func _on_body_entered(body):
	# 只有真正的球（不是 BOSS 的假球）能吃道具
	if body.is_in_group("BallGroup") and not body.is_in_group("DecoyBall"):
		collected.emit(kind, body)
		queue_free()
