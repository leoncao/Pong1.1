# Loot.gd —— CS2 风格开箱系统的"大脑"（自动加载为全局单例 Loot）
# 负责：稀有度和概率、物品池、加权随机抽奖、背包存档、重复物品换金币、和商店皮肤联动。
extends Node

const INVENTORY_PATH := "user://inventory.cfg"
const UNLOCKED_PATH := "user://unlocked.cfg"     # 原来商店(Customization)用的存档
const SELECTION_PATH := "user://selection.cfg"   # 原来"当前球拍皮肤"的存档

# 稀有度（颜色和概率模仿 CS2）。weight 越大越容易抽到，总和 = 100。
const RARITIES := [
	{"name": "Mil-Spec",   "cn": "军规级", "color": Color("4b69ff"), "weight": 79.92, "dup_coins": 5},
	{"name": "Restricted", "cn": "受限",   "color": Color("8847ff"), "weight": 15.98, "dup_coins": 15},
	{"name": "Classified", "cn": "保密",   "color": Color("d32ce6"), "weight": 3.20,  "dup_coins": 40},
	{"name": "Covert",     "cn": "隐秘",   "color": Color("eb4b4b"), "weight": 0.64,  "dup_coins": 100},
	{"name": "Rare Special","cn": "★ 稀有特殊", "color": Color("e4ae39"), "weight": 0.26, "dup_coins": 300},
]

# 物品池：type = "paddle"(球拍皮肤，用现有图片) 或 "trail"(球拖尾，用颜色生成)
const ITEMS := [
	# 默认物品：所有人一开始就有，不会从箱子里开出来
	{"id": "paddle_initialboss", "name": "Default",  "type": "paddle", "tier": -1, "default": true, "texture": "res://assets/Paddle/initialboss_pub.png"},
	{"id": "trail_none",         "name": "Default",  "type": "trail",  "tier": -1, "default": true, "colors": []},
	{"id": "paddle_door",        "name": "Door",            "type": "paddle", "tier": 0, "texture": "res://assets/Paddle/door.png"},
	{"id": "paddle_cadpat",      "name": "Cadpat",          "type": "paddle", "tier": 0, "texture": "res://assets/Paddle/paddle_cadpat.png"},
	{"id": "paddle_star",        "name": "Star",            "type": "paddle", "tier": 0, "texture": "res://assets/Paddle/star.png"},
	{"id": "trail_ocean",        "name": "Trail | Ocean",   "type": "trail",  "tier": 0, "colors": ["4b69ff", "9fb4ff"]},
	{"id": "paddle_door_green",  "name": "Green Door",      "type": "paddle", "tier": 1, "texture": "res://assets/Paddle/door_green.png"},
	{"id": "paddle_cadpat_green","name": "Green Cadpat",    "type": "paddle", "tier": 1, "texture": "res://assets/Paddle/paddle_cadpat_green.png"},
	{"id": "paddle_star_scale",  "name": "Star Scale",      "type": "paddle", "tier": 1, "texture": "res://assets/Paddle/star_scale.png"},
	{"id": "trail_violet",       "name": "Trail | Violet",  "type": "trail",  "tier": 1, "colors": ["8847ff", "d0b8ff"]},
	{"id": "paddle_atheboss",    "name": "The Boss",        "type": "paddle", "tier": 2, "texture": "res://assets/Paddle/atheboss.png"},
	{"id": "trail_neon",         "name": "Trail | Neon",    "type": "trail",  "tier": 2, "colors": ["d32ce6", "2ce6d3"]},
	{"id": "paddle_finalboss",   "name": "Final Boss",      "type": "paddle", "tier": 3, "texture": "res://assets/Paddle/finalboss_pub.png"},
	{"id": "paddle_levelingrod", "name": "Leveling Rod",    "type": "paddle", "tier": 3, "texture": "res://assets/Paddle/levelingrod_rare.png"},
	{"id": "trail_fire",         "name": "Trail | Fire",    "type": "trail",  "tier": 3, "colors": ["eb4b4b", "ffd23f"]},
	{"id": "paddle_evil",        "name": "★ Evil Boss",     "type": "paddle", "tier": 4, "texture": "res://assets/Paddle/final_evil_boss.png"},
	{"id": "paddle_hidden",      "name": "★ Hidden Boss",   "type": "paddle", "tier": 4, "texture": "res://assets/Paddle/hidden_boss1.png"},
	{"id": "paddle_skull",       "name": "★ Skull",         "type": "paddle", "tier": 4, "texture": "res://assets/Paddle/skull_rare.png"},
	{"id": "trail_gold",         "name": "★ Trail | Gold",  "type": "trail",  "tier": 4, "colors": ["e4ae39", "fff3c4", "e4ae39"]},
]

# 箱子：价格 + 钥匙价格，都用游戏里已有的金币支付
# 默认物品的"稀有度"显示
const DEFAULT_RARITY := {"name": "Default", "cn": "默认", "color": Color("9aa0a6"), "weight": 0.0, "dup_coins": 0}

const CASES := {
	"pong_case": {"name": "Pong Case", "price": 20, "key_price": 5},
}

var rng := RandomNumberGenerator.new()
var inventory := {}       # 物品 id -> 数量(拥有就是 1)
var cases_opened := 0
var equipped_trail := ""  # 当前装备的拖尾 id，"" = 默认

func _ready():
	rng.randomize()
	load_inventory()
	migrate_shop_unlocks()

# ---------- 抽奖 ----------
func item_by_id(id: String) -> Dictionary:
	for it in ITEMS:
		if it["id"] == id: return it
	return {}

func items_of_tier(tier: int) -> Array:
	return ITEMS.filter(func(it): return it["tier"] == tier and not it.get("default", false))

func rarity_of(item: Dictionary) -> Dictionary:
	return DEFAULT_RARITY if item.get("tier", -1) < 0 else RARITIES[item["tier"]]

# 加权随机：把所有权重排成一条"尺子"，随机扔一个点，看落在哪一段
func roll_tier(r: RandomNumberGenerator = rng) -> int:
	var total := 0.0
	for t in RARITIES: total += t["weight"]
	var point := r.randf() * total
	for i in RARITIES.size():
		point -= RARITIES[i]["weight"]
		if point < 0.0: return i
	return 0

func roll_item(r: RandomNumberGenerator = rng) -> Dictionary:
	var pool := items_of_tier(roll_tier(r))
	return pool[r.randi() % pool.size()]

func case_cost(case_id: String) -> int:
	var c = CASES[case_id]
	return c["price"] + c["key_price"]

# 真正开箱：先扣钱，再抽奖，再入库。返回结果；钱不够返回空字典。
func open_case(case_id: String = "pong_case") -> Dictionary:
	var cost := case_cost(case_id)
	if Global.coins < cost:
		return {}
	Global.coins -= cost
	var item := roll_item()
	var result := grant_item(item)
	cases_opened += 1
	Global.save_coins()
	save_inventory()
	return result

# 发放物品：已拥有 -> 换成金币；新物品 -> 放进背包，球拍同时解锁到原来的商店
func grant_item(item: Dictionary) -> Dictionary:
	var dup := owns(item["id"])
	var refund := 0
	if dup:
		refund = RARITIES[item["tier"]]["dup_coins"]
		Global.coins += refund
	else:
		inventory[item["id"]] = 1
		if item["type"] == "paddle":
			_unlock_in_shop(item["texture"])
	return {"item": item, "duplicate": dup, "refund": refund}

func owns(id: String) -> bool:
	if inventory.has(id): return true
	var it := item_by_id(id)
	if it.get("default", false): return true   # 默认物品永远拥有
	if it.get("type") == "paddle":   # 在原来商店里买过的也算拥有
		var cf := ConfigFile.new()
		if cf.load(UNLOCKED_PATH) == OK and cf.get_value("unlocked", it["texture"], false):
			return true
	return false

func _unlock_in_shop(texture_path: String):
	var cf := ConfigFile.new()
	cf.load(UNLOCKED_PATH)
	cf.set_value("unlocked", texture_path, true)
	cf.save(UNLOCKED_PATH)

# 背包里拥有的物品（type = "paddle" / "trail"），默认物品排最前，然后按稀有度从高到低
func owned_items(type: String) -> Array:
	var list := ITEMS.filter(func(it): return it["type"] == type and owns(it["id"]))
	list.sort_custom(func(a, b):
		if a.get("default", false) != b.get("default", false): return a.get("default", false)
		return a["tier"] > b["tier"])
	return list

func owned_paddles() -> Array:
	return owned_items("paddle")

# 当前装备的球拍 id（没选过 = 默认）
func equipped_paddle_id() -> String:
	var cf := ConfigFile.new()
	if cf.load(SELECTION_PATH) == OK:
		var tex = cf.get_value("selection", "texture", "")
		for it in ITEMS:
			if it["type"] == "paddle" and it["texture"] == tex: return it["id"]
	return "paddle_initialboss"

func equipped_trail_id() -> String:
	return equipped_trail if equipped_trail != "" else "trail_none"

func is_equipped(id: String) -> bool:
	return id == equipped_paddle_id() or id == equipped_trail_id()

# ---------- 装备 ----------
func equip(id: String):
	var it := item_by_id(id)
	if it.is_empty() or not owns(id): return
	if it["type"] == "paddle":
		var cf := ConfigFile.new()
		cf.load(SELECTION_PATH)
		cf.set_value("selection", "texture", it["texture"])
		cf.save(SELECTION_PATH)
	else:
		equipped_trail = "" if it.get("default", false) else id   # 默认 = 不用彩色拖尾
		save_inventory()

func trail_gradient(id: String) -> Gradient:
	var it := item_by_id(id)
	if it.is_empty() or it["type"] != "trail" or it.get("default", false): return null
	var g := Gradient.new()
	var cols: Array = it["colors"]
	g.offsets = PackedFloat32Array()
	g.colors = PackedColorArray()
	for i in cols.size():
		var c := Color(cols[i]); c.a = 0.2 + 0.6 * float(i + 1) / cols.size()
		g.add_point(float(i) / max(1, cols.size() - 1), c)
	return g

func equipped_trail_gradient() -> Gradient:
	return trail_gradient(equipped_trail) if equipped_trail != "" else null

# ---------- 存档 ----------
func save_inventory():
	var cf := ConfigFile.new()
	for id in inventory.keys(): cf.set_value("inventory", id, inventory[id])
	cf.set_value("stats", "cases_opened", cases_opened)
	cf.set_value("equipped", "trail", equipped_trail)
	cf.save(INVENTORY_PATH)

func load_inventory():
	inventory = {}
	var cf := ConfigFile.new()
	if cf.load(INVENTORY_PATH) != OK: return
	if cf.has_section("inventory"):
		for id in cf.get_section_keys("inventory"):
			inventory[id] = cf.get_value("inventory", id)
	cases_opened = cf.get_value("stats", "cases_opened", 0)
	equipped_trail = cf.get_value("equipped", "trail", "")

# 迁移：以前在商店(Customization)用金币买过/解锁过的皮肤，全部放进背包，什么都不会丢
func migrate_shop_unlocks() -> int:
	var added := 0
	var cf := ConfigFile.new()
	if cf.load(UNLOCKED_PATH) == OK and cf.has_section("unlocked"):
		for tex in cf.get_section_keys("unlocked"):
			if not cf.get_value("unlocked", tex, false): continue
			for it in ITEMS:
				if it["type"] == "paddle" and it["texture"] == tex and not it.get("default", false) and not inventory.has(it["id"]):
					inventory[it["id"]] = 1; added += 1
	# 当前正在用的皮肤也算拥有
	var sel := ConfigFile.new()
	if sel.load(SELECTION_PATH) == OK:
		var cur = sel.get_value("selection", "texture", "")
		for it in ITEMS:
			if it["type"] == "paddle" and it["texture"] == cur and not it.get("default", false) and not inventory.has(it["id"]):
				inventory[it["id"]] = 1; added += 1
	if added > 0: save_inventory()
	return added
