# Difficulty.gd —— 所有难度数值集中放在这里（想调难度只改这个文件）
# 下标 0~6 = 经典模式等级 0~5，6 = BOSS
extends RefCounted

# ---------- 经典模式 AI ----------
const AI_MAX_SPEED   := [400.0, 450.0, 500.0, 550.0, 600.0, 650.0, 700.0]  # 球拍最大速度 (像素/秒)
const AI_REACTION    := [0.28, 0.24, 0.20, 0.16, 0.13, 0.10, 0.07]         # 反应延迟 (秒)：球朝它飞来后，多久才开始"算"
const AI_AIM_ERROR   := [95.0, 85.0, 75.0, 65.0, 55.0, 45.0, 100.0]  # 瞄准误差 (像素)：每次来球随机偏差 ±这么多
# (普通球拍能接住的范围约 ±88 像素，BOSS 球拍变大约 ±150，所以 BOSS 的误差数字更大)
const AI_LAPSE      := [0.15, 0.12, 0.10, 0.08, 0.065, 0.05, 0.025]       # 每次接球"失误/判断错"的概率（越高级越少）
const AI_AIM_BIAS    := [10.0, 20.0, 30.0, 38.0, 45.0, 50.0, 60.0]           # 故意用球拍边缘接球(像素)，把球打向玩家的反方向
const AI_RETURN_ANGLE := [0.8, 0.9, 1.0, 1.1, 1.2, 1.3, 1.4]             # 回球角度：打在球拍边缘时，球斜得多厉害
const AI_PREDICT     := [0.55, 0.7, 0.85, 1.0, 1.0, 1.0, 1.0]              # 预判程度：0=只盯着球现在的位置，1=完整预判落点(含墙壁反弹)
const AI_HOME_SPEED  := 0.5          # 球飞走时，回到中间的速度比例

# ---------- BOSS ----------
const BOSS_LEVEL := 6
const BOSS_SMASH_CHANCE := 0.30      # BOSS 回球时 30% 概率打出"斜线快球"
const BOSS_SMASH_BOOST := 1.35       # 快球速度倍数
const BOSS_DECOY_INTERVAL := 6.0     # BOSS 假球间隔 (秒)（原来 10 秒）
const BOSS_DARK_INTERVAL := Vector2(10.0, 15.0)  # 黑暗间隔 (秒)（原来 14~20 秒）

# ---------- 蓄力球 = 克制 AI 的手段 ----------
# 玩家的蓄力快球(speed_boost > 1.3)会让 AI "看不清"：多愣一下，而且只能部分预判反弹
const CHARGED_BOOST_MIN := 1.3
const CHARGED_SURPRISE := 0.2        # 额外反应延迟 (秒)
const CHARGED_PREDICT := 0.3         # 预判程度降到 0.3（大部分时候只能追着球跑）

# ---------- 疯狂模式 AI：随存活时间变强（0 秒 → RAMP_TIME 秒）----------
const CRAZY_RAMP_TIME := 150.0
# 疯狂模式里 AI 漏球也会结束本局，所以它要"稳"，变强体现在回球越来越刁钻
const CRAZY_SPEED_FACTOR := Vector2(1.0, 1.3)     # AI 速度 = 球速 × 这个(从左值涨到右值)
const CRAZY_REACTION := Vector2(0.15, 0.04)
const CRAZY_AIM_ERROR := Vector2(45.0, 20.0)
const CRAZY_RETURN_ANGLE := Vector2(0.5, 1.3)
const CRAZY_AIM_BIAS := Vector2(0.0, 35.0)
const CRAZY_LAPSE := Vector2(0.04, 0.01)
const MIN_RETURN_SLOPE := 0.3        # 回球至少有这么"斜"，防止球水平来回、谁都不用动

# ---------- 回合加速（防止无限对打）----------
const RALLY_STEP := 0.06             # 每次球拍击球，球速 +6%
const RALLY_MAX := 2.4               # 最多 2.4 倍，下一次发球恢复

# ---------- 场地（球心能到的上下范围，球半径约 25）----------
const FIELD_TOP := 25.0
const FIELD_BOTTOM := 695.0

static func level_value(table: Array, level: int):
	return table[clampi(level, 0, table.size() - 1)]

# 预测球飞到 target_x 时的 y 坐标（把上下墙壁的反弹"折叠"进去）
static func predict_y(pos: Vector2, vel: Vector2, target_x: float) -> float:
	if absf(vel.x) < 0.001:
		return pos.y
	var y := pos.y + vel.y / vel.x * (target_x - pos.x)   # 不考虑墙时的落点
	var h := FIELD_BOTTOM - FIELD_TOP
	var m := fposmod(y - FIELD_TOP, 2.0 * h)            # 每走 2h 就回到原样
	if m > h:
		m = 2.0 * h - m                                  # 后半段是"反弹回来"的
	return FIELD_TOP + m
