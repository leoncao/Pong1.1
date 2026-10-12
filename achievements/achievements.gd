# Achievements.gd
extends Node
var achievement_notification_scene = preload("res://achievements/Achievements_ui.tscn")
# The achievements dictionary defined earlier
var achievements = {
	"first_win": {"name": "First Win", "description": "Win your first game.", "unlocked": false},
	"win_streak_3": {"name": "Winning Streak", "description": "Win 3 games in a row.", "unlocked": false},
	"score_10_points": {"name": "Point Master", "description": "Score 10 points in a single game.", "unlocked": false},
	"shutout_game": {"name": "Shutout Game", "description": "Win a game without letting the opponent score.", "unlocked": false},
	"play_10_games": {"name": "Devoted Player", "description": "Play 10 games.", "unlocked": false},
	# Add more achievements...
}

func _ready():
	load_achievements()   # 开游戏时读取已解锁的成就

func unlock(achievement_id):
	if achievements.has(achievement_id) and not achievements[achievement_id]["unlocked"]:
		achievements[achievement_id]["unlocked"] = true
		save_achievements()   # 一解锁就存档，下次打开游戏还在
		# Show the achievement notification
		# Godot 4 修复：原来的 get_node("") 拿到的是没有 text 属性的节点，会报错，
		# 所以提示从来没显示出来。这里改为用一个简单的 Label 显示提示文字。
		var achievement_notification = CanvasLayer.new()
		achievement_notification.layer = 100
		var label = Label.new()
		label.text = tr("ACH_UNLOCKED") % tr(achievements[achievement_id]["name"])
		achievement_notification.add_to_group("AchievementPopup")
		var stacked = get_tree().get_nodes_in_group("AchievementPopup").size()
		label.position = Vector2(20, 20 + 30 * stacked)   # 同时解锁多个成就时往下排，不会叠在一起
		achievement_notification.add_child(label)
		get_tree().root.add_child(achievement_notification)
		# Set a timer to hide the achievement notification after a few seconds
		# 计时器直接连到这个提示的 queue_free：提示如果已经被别处删掉，连接会自动断开，不会崩溃
		get_tree().create_timer(3.0).timeout.connect(achievement_notification.queue_free)

func save_achievements():
	var save_file = ConfigFile.new()
	for achievement_id in achievements.keys():
		save_file.set_value("achievements", achievement_id, achievements[achievement_id])
	save_file.save("user://achievements.cfg")

func load_achievements():
	var save_file = ConfigFile.new()
	if save_file.load("user://achievements.cfg") == OK:
		for achievement_id in achievements.keys():
			achievements[achievement_id] = save_file.get_value("achievements", achievement_id, achievements[achievement_id])
