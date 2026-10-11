# Portal.gd —— 传送门（成对出现）。球从一个门进去，从另一个门出来，速度和方向不变。
extends Area2D

signal teleported(ball: Node)

const RADIUS := 30.0
const COOLDOWN_MS := 600   # 传送后 0.6 秒内不能再传送，防止在两个门之间来回卡住

var partner: Area2D
var color := Color("8847ff")

func _ready():
	add_to_group("Portal")
	var cs := CollisionShape2D.new()
	var shape := CircleShape2D.new(); shape.radius = RADIUS
	cs.shape = shape; add_child(cs)
	body_entered.connect(_on_body_entered)

func _draw():
	draw_circle(Vector2.ZERO, RADIUS, Color(color.r, color.g, color.b, 0.25))
	draw_arc(Vector2.ZERO, RADIUS, 0, TAU, 40, color, 5.0, true)
	draw_arc(Vector2.ZERO, RADIUS * 0.6, 0.5, 4.5, 24, color.lightened(0.4), 3.0, true)

func _process(delta):
	rotation += delta * 2.5   # 转起来

func _on_body_entered(body):
	if partner == null or not (body is CharacterBody2D) or body.is_in_group("paddles"):
		return
	var now := Time.get_ticks_msec()
	if int(body.get_meta("portal_until", 0)) > now:
		return
	body.set_meta("portal_until", now + COOLDOWN_MS)
	var dir: Vector2 = body.velocity.normalized() if body.velocity.length() > 0.01 else Vector2.RIGHT
	# 从另一个门"前方"出来（沿着原来的飞行方向），速度 velocity 完全不动
	body.set_deferred("global_position", partner.global_position + dir * (RADIUS + 32.0))
	var trail = body.get_node_or_null("BallTrail")
	if trail: trail.call_deferred("clear_points")
	teleported.emit(body)
