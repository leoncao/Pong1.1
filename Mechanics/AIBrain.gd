# AIBrain.gd —— 电脑球拍的"大脑"：预判落点 + 反应延迟 + 瞄准误差
extends RefCounted

const Difficulty = preload("res://Mechanics/Difficulty.gd")

var target_y := 360.0
var approaching := false
var react_left := 0.0
var error := 0.0
var rng := RandomNumberGenerator.new()

func _init():
	rng.randomize()

# 返回希望球拍去的 y；approaching=false 表示没有球朝它飞来
func think(paddle: Node2D, delta: float, reaction: float, aim_error: float, predict: float, aim_bias: float = 0.0, lapse: float = 0.0) -> float:
	var face_x := paddle.global_position.x - 40.0 * signf(paddle.global_position.x - 640.0)
	var toward := signf(paddle.global_position.x - 640.0)   # 右边的 AI = +1
	# 多球时：找最快到达的那个真球（AI 知道假球是假的，不理它）
	var best = null
	var best_t := INF
	for b in paddle.get_tree().get_nodes_in_group("BallGroup"):
		if not is_instance_valid(b) or b.speed == 0 or signf(b.velocity.x) != toward:
			continue
		var t: float = (face_x - b.global_position.x) / (b.velocity.x * b.speed * b.speed_boost)
		if t >= 0.0 and t < best_t:
			best_t = t; best = b
	if best == null:
		approaching = false
		target_y = 360.0
		return target_y
	var charged: bool = best.speed_boost > Difficulty.CHARGED_BOOST_MIN
	if charged:   # 蓄力快球：AI 看不清
		predict = minf(predict, Difficulty.CHARGED_PREDICT)
	if not approaching:   # 新的来球：先"愣一下"，并决定这次瞄偏多少
		approaching = true
		react_left = reaction + (Difficulty.CHARGED_SURPRISE if charged else 0.0)
		error = rng.randf_range(-aim_error, aim_error)
		# 故意用球拍边缘接球：球拍停在球"上方" → 球打在下半边 → 往下飞。
		# 玩家在上半场 → 往下打（目标往上偏）；玩家在下半场 → 往上打
		var pl = paddle.get_tree().get_first_node_in_group("player_paddle")
		if pl and aim_bias > 0.0:
			error += aim_bias * (1.0 if pl.global_position.y > 360.0 else -1.0)
		# 误差最多到球拍边缘：AI 不会"故意"漏球，漏球只因为来不及跑到位
		var catch_half := 50.0 * absf(paddle.get_node("CollisionPolygon2D").scale.y / 1.11979)
		error = clampf(error, -catch_half, catch_half)
		if rng.randf() < lapse:   # 偶尔判断失误：瞄偏到球拍接不到的地方
			error = (catch_half * 2.0 + rng.randf_range(10.0, 60.0)) * (1.0 if rng.randf() < 0.5 else -1.0)
	if react_left > 0.0:
		react_left -= delta
		return target_y   # 还没反应过来，继续去旧目标
	var predicted := Difficulty.predict_y(best.global_position, best.velocity, face_x)
	target_y = lerpf(best.global_position.y, predicted, predict) + error
	return target_y

# 电脑回球的角度：球打在球拍中间 → 平；打在边缘 → 斜（和经典 Pong 一样）
static func english(paddle: Node2D, ball: Node2D, angle: float):
	var half := 63.0 * absf(paddle.get_node("CollisionPolygon2D").scale.y / 1.11979)
	var rel := clampf((ball.global_position.y - paddle.global_position.y) / half, -1.0, 1.0)
	var dir_x := -signf(paddle.global_position.x - 640.0)
	var vy: float = rel * angle + ball.velocity.y * 0.5
	if absf(vy) < Difficulty.MIN_RETURN_SLOPE:
		vy = Difficulty.MIN_RETURN_SLOPE * (signf(vy) if vy != 0.0 else 1.0)
	ball.velocity = Vector2(dir_x, vy).normalized() * Vector2(1, 0.8).length()

# 把目标变成球拍速度（越近越慢，避免抖动）
static func steer(paddle_y: float, target: float, max_speed: float) -> float:
	var dy := target - paddle_y
	if absf(dy) < 4.0:
		return 0.0
	return signf(dy) * minf(max_speed, absf(dy) * 10.0)
