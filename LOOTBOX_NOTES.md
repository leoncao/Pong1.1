# CS2 风格开箱系统说明（写给编程初学者）

> 代码在 Git 分支 `lootbox-cs2`（只在本地，**还没推送**到 GitHub）。
> 截图：`/workspace/godot-upgrade/shot_spin.png`（滚动中）、`shot_reveal.png`（开出结果）。

## 1. 玩家看到什么

1. 主菜单多了一个 **CASES** 按钮（在 CUSTOMIZATION 下面）。
2. 进去后是 "PONG CASE" 开箱界面：中间一条横向物品带，正中间有一根**黄色指针**。
3. 点 **OPEN CASE (20 + KEY 5 COINS)**：花 25 金币（箱子 20 + 钥匙 5，用的是游戏原来的金币）。
4. 物品带飞快滚动，**越来越慢**，每经过一张卡片"嗒"一声，最后停在指针下的那张就是你抽到的。
5. 弹出结果框，边框颜色 = 稀有度颜色：
   - 新物品 → "新物品！已放进背包"，可以点 **EQUIP** 立刻装备；
   - 已经有了 → "重复物品！已换成 +X 金币"。
6. **INVENTORY** 可以看所有抽到的东西并装备；按 **BACK** 或 ESC 回主菜单。
7. 抽到的**球拍皮肤**会自动出现在原来的 CUSTOMIZATION 商店里（已解锁，按 CONFIRM 选用）；
   抽到的**球拖尾**装备后，经典模式和疯狂模式里球后面的尾巴会变色。

## 2. 稀有度和概率（模仿 CS2）

| 稀有度 | 颜色 | 概率 | 重复时换多少金币 | 物品 |
|---|---|---|---|---|
| Mil-Spec 军规级 | 蓝 | 79.92% | 5 | Door、Cadpat、Star、Trail Ocean |
| Restricted 受限 | 紫 | 15.98% | 15 | Green Door、Green Cadpat、Star Scale、Trail Violet |
| Classified 保密 | 粉 | 3.20% | 40 | The Boss、Initial Boss、Trail Neon |
| Covert 隐秘 | 红 | 0.64% | 100 | Final Boss、Leveling Rod、Trail Fire |
| ★ Rare Special 稀有特殊 | 金 | 0.26% | 300 | Evil Boss、Hidden Boss、Skull、Trail Gold |

球拍皮肤用的都是项目里已有的图片（`assets/Paddle/`），拖尾是用颜色渐变"现场生成"的，不需要新图片。

## 3. 核心原理一：加权随机（怎么决定抽到什么）

想象一把 100 厘米长的尺子，按概率切成 5 段：前 79.92 厘米是蓝色，接着 15.98 厘米紫色……最后 0.26 厘米金色。
闭上眼睛在尺子上随便点一个位置，点在哪段就是哪个稀有度。段越长，越容易被点中。

```gdscript
func roll_tier(r) -> int:
	var total := 0.0
	for t in RARITIES: total += t["weight"]     # 尺子总长 = 100
	var point := r.randf() * total               # 随机点一个位置 (0~100)
	for i in RARITIES.size():
		point -= RARITIES[i]["weight"]           # 一段一段减过去
		if point < 0.0: return i                 # 减成负数 = 落在这一段
	return 0
```
选出稀有度后，再从这个稀有度的物品里**平均**随机挑一个。

**和 CS2 一样，结果在动画开始之前就已经决定了**，后面的滚动只是"表演"。

## 4. 核心原理二：滚动动画（怎么停在正确的卡片上）

1. 先抽出结果，然后铺 60 张卡片，第 50 张换成中奖物品，其他 59 张随便抽来"陪跑"。
2. 算出"要把物品带往左移多远，第 50 张才刚好在指针下"，再加一点随机偏移（不会每次都正中间，更真实）。
3. 用 Tween 在 6 秒内移过去，曲线选"先快后慢"（`TRANS_QUART` + `EASE_OUT`）。

```gdscript
var jitter := randf_range(-CARD_W * 0.4, CARD_W * 0.4)          # 随机偏一点
var target_x := REEL_W / 2 - (WIN_INDEX * STRIDE + CARD_W / 2 + jitter)
var tween := create_tween()
tween.tween_property(strip, "position:x", target_x, SPIN_TIME)\
	.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)      # 先快后慢
```

"嗒嗒"声：每一帧算一下"现在指针下面是第几张卡"，编号一变就播放一次声音：
```gdscript
var idx := int((REEL_W / 2 - strip.position.x) / STRIDE)
if idx != last_tick_index:
	last_tick_index = idx
	tick_player.play()
```

## 5. 存档和与原有系统的联动

| 存档文件 | 内容 |
|---|---|
| `user://inventory.cfg`（新） | 背包物品、开过多少箱、当前装备的拖尾 |
| `user://savefile.cfg`（原有） | 金币（开箱扣钱、重复换钱都写这里） |
| `user://unlocked.cfg`（原有） | 商店已解锁皮肤——抽到球拍时也写进去，所以商店里会显示"已解锁" |
| `user://selection.cfg`（原有） | 当前使用的球拍皮肤——EQUIP 球拍时写这里，进游戏就换上 |

在原来商店里买过的皮肤，开箱再抽到也算"重复"，会换成金币。

## 6. 文件在哪

- `Lootbox/CS2/Loot.gd`：大脑（概率、物品池、抽奖、背包存档）。已注册为全局单例 `Loot`。
- `Lootbox/CS2/CaseOpening.gd` / `.tscn`：开箱界面（物品带、指针、音效、弹窗、背包）。
- 小改动：`MainMenu.gd`（加 CASES 按钮）、`Scenes/Customization.gd`（显示抽到的皮肤）、`Scenes/BallTrail.gd`（拖尾颜色）。
- 原来的旧开箱场景（`Lootbox/Scenes and Scripts/`、`Scenes and Scripts/`）没动，仍然可以打开。

想调整？
- 改概率：改 `Loot.gd` 里 `RARITIES` 的 `weight`。
- 加新物品：在 `ITEMS` 里加一行（球拍填图片路径，拖尾填颜色）。
- 改价格：改 `CASES` 里的 `price` 和 `key_price`。
- 改滚动时间/手感：改 `CaseOpening.gd` 顶部的 `SPIN_TIME`。

## 7. 测试结果

- 用电脑模拟抽了 **20 万次**，实际比例和设定几乎一样：蓝 79.95%、紫 15.96%、粉 3.21%、红 0.64%、金 0.24%。
- 连开 300 箱：金币扣得一分不差（含重复换回的金币）；关掉再读档，背包、开箱次数、装备的拖尾、金币全部一致。
- 金币不够时按钮不能用，也不会扣钱。
- 物品带停下时，指针下面正好是第 50 张（中奖那张）；滚动过程中响了约 48 次"嗒"；结果弹窗正常出现。
- 抽到的球拍出现在商店里；装备的拖尾会应用到球上。
- 原有的所有场景再跑一遍，**没有脚本错误**。

## 8. 需要你亲手试玩的地方

- 滚动 6 秒的节奏、"嗒嗒"声的音量是否舒服（用的是球碰撞的 beep 音效）。
- 弹窗、按钮在你电脑上的大小和位置；主菜单里 CASES 按钮的位置。
- 金币平衡：疯狂模式每秒 0.5 金币，开一箱 25 金币 ≈ 玩 50 秒。觉得太贵/太便宜可以改价格。
- 拖尾颜色在游戏里好不好看。

> 小提醒：CS2 真实的开箱是花真钱的。这个游戏里只用游戏内金币，不涉及真钱。
