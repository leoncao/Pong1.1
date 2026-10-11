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

func unlock(achievement_id):
	if achievements.has(achievement_id) and not achievements[achievement_id]["unlocked"]:
		achievements[achievement_id]["unlocked"] = true
		# Show the achievement notification
		# Godot 4 修复：原来的 get_node("") 拿到的是没有 text 属性的节点，会报错，
		# 所以提示从来没显示出来。这里改为用一个简单的 Label 显示提示文字。
		var achievement_notification = CanvasLayer.new()
		achievement_notification.layer = 100
		var label = Label.new()
		label.text = "Achievement Unlocked: " + achievements[achievement_id]["name"]
		label.position = Vector2(20, 20)
		achievement_notification.add_child(label)
		get_tree().root.add_child(achievement_notification)
		# Set a timer to hide the achievement notification after a few seconds
		await get_tree().create_timer(3.0).timeout
		achievement_notification.queue_free()

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
