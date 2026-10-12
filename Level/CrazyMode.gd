extends Node

var lastScored = "" 
var crazyMode = true
var startTime = 0
@export var currentScore = 0
var highestScore = 0  # This will keep track of the coins earned in the current game session
var currentSessionCoins = 0
var save_file = ConfigFile.new()
const Mechanics = preload("res://Mechanics/Mechanics.gd")
var mech            # 新玩法总控
var combo := 0      # 连续接球次数
var alive_time := 0.0   # 本局存活时间(只算球在动的时间)
var _second_acc := 0.0

# 连击倍率：每连续接 5 次球 +0.5 倍，最多 3 倍（金币 = 每秒 0.5 × 倍率）
func coin_multiplier() -> float:
	return minf(3.0, 1.0 + 0.5 * floor(combo / 5.0))

func _ready():
	$CountdownTimer.start()
	get_tree().call_group("BallGroup", "stop_ball")
	$PauseMenu.hide() 
	$ModeLabel.text = tr("MODE_HARDCORE")  # Set the initial mode
	startTime = Time.get_ticks_msec()
	$PauseMenu.set_game_mode(self)
	$Restart.process_mode = Node.PROCESS_MODE_ALWAYS  # Allow the Restart button to process input when the game is paused
	highestScore = load_high_score()  # Load the highest score at the start of the game
	Global.load_coins()  # Load the total coins at the start of the game
	$TotalCoinsLabel.text = tr("TOTAL_COINS") % str(Global.coins)
		# Load the player's selection
	var save_file = ConfigFile.new()  # Create a new ConfigFile instance
	var error = save_file.load("user://selection.cfg")
	if error == OK:
		var texture_path = save_file.get_value("selection", "texture")
		#print("Texture path: ", texture_path)  # Print the texture path
		var texture = load(texture_path)
		#print("Loaded texture: ", texture)  # Print the loaded texture
		#print("Sprite node before: ", $Player/Sprite.texture)  # Print the Sprite node's texture before the assignment
		$Player/Sprite2D.texture = texture
		#print("Sprite node after: ", $Player/Sprite.texture)  # Print the Sprite node's texture after the assignment
	_setup_mechanics()

func _setup_mechanics():
	mech = Mechanics.new()
	mech.name = "Mechanics"
	add_child(mech)
	mech.setup(self, "crazy", $CrazyBall, $Player, $CrazyAI)
	mech.prepare_serve("Player")   # 玩家发球
	$Player.ball_hit.connect(func(_b): combo += 1)

func _on_LeftWall_body_entered(body):
	var kind = mech.classify(body)
	if kind == "other": return
	if kind == "decoy":
		mech.remove_ball(body); return
	if kind == "extra":   # 额外的球漏了不算输：球消失，连击清零
		mech.remove_ball(body)
		if combo > 0: mech.hud.flash(tr("CRAZY_EXTRA_MISSED"), Color("ff8c8c"))
		combo = 0
		return
	$CrazyBall.position = Vector2(640,320)
	lastScored = "AI" 
	stop_game() 
	$GameOver.visible = true 
	$Restart.visible = true
	$mainmenubutton.visible = true  

func _on_RightWall_body_entered(body):
	var kind = mech.classify(body)
	if kind == "other": return
	if kind == "decoy":
		mech.remove_ball(body); return
	if kind == "extra":   # 额外的球打进对方球门：奖励 +3 分、+1 金币
		mech.remove_ball(body); currentScore += 3; currentSessionCoins += 1.0; $ScoreSound.play(); return
	# 疯狂模式：主球打进 AI 的门不再结束本局（以前会直接 Game Over）。
	# 多球时 AI 会去追别的球，主球溜过去很常见 → 改成奖励 +5 分、+2 金币，然后玩家重新发球（球速保持）
	lastScored = "Player"
	currentScore += 5; currentSessionCoins += 2.0
	$ScoreSound.play()
	mech.hud.flash(tr("CRAZY_AI_MISSED"), Color("7CFC9A"))
	_reserve()

# 重新发球：保留当前球速（疯狂模式的难度主要来自球速）
var _resume_speed := 0.0
func _reserve():
	_resume_speed = $CrazyBall.speed
	mech.clear_extra_balls()
	get_tree().call_group("BallGroup", "stop_ball")
	mech.prepare_serve("Player")
	$CountdownLabel.visible = true
	$CountdownTimer.start()

func _process(delta):
	$CountdownLabel.text = str(int($CountdownTimer.time_left) + 1)
	if crazyMode and not get_tree().paused:
		# 改进：只在球真的在动时计时（倒计时期间不算分），金币乘以连击倍率
		if $CrazyBall.speed > 0:
			alive_time += delta
			_second_acc += delta
			if _second_acc >= 1.0:  # If a second has passed
				_second_acc -= 1.0
				currentScore += 1  # Increase the current score
				currentSessionCoins += 0.5 * coin_multiplier()  # Increase the coins earned in the current game session
		mech.hud.set_crazy(alive_time, currentScore, highestScore, currentSessionCoins, combo, coin_multiplier())
		$CurrentScoreLabel.text = tr("CUR_SCORE") % currentScore
		$HighestScoreLabel.text = tr("HIGH_SCORE") % highestScore  # Display the highest score
		$TotalCoinsLabel.text = tr("TOTAL_COINS") % str(Global.coins)  # Update the total coins earned across all game sessions

func _on_CountdownTimer_timeout():
	get_tree().call_group("BallGroup", "restart_ball")
	if _resume_speed > 0.0:
		$CrazyBall.speed = _resume_speed; _resume_speed = 0.0
	mech.on_serve_launched()
	$CountdownLabel.visible = false

func stop_game():
	mech.stop_all()
	get_tree().call_group("BallGroup", "stop_ball") 
	$CrazyAI.speed = 0 
	get_tree().paused = true  # Pause the game
	if crazyMode:
		$GameOver.visible = true  # Show the game over screen
		if currentScore > highestScore:
			highestScore = currentScore
			save_high_score(highestScore)  # Save the new highest score
		Global.coins += currentSessionCoins  # Add the coins earned in the current game session to the total coins
		Global.save_coins()  # Save the total coins
		$ScoreSummary.text = tr("SCORE_SUMMARY") % [currentScore, highestScore, str(currentSessionCoins)]

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		get_tree().paused = !get_tree().paused
		if get_tree().paused:
			show_pause_menu()
		else:
			hide_pause_menu()

func show_pause_menu():
	$PauseMenu.show()
	$PauseMenu.visible = true

func hide_pause_menu():
	$PauseMenu.hide()
	$PauseMenu.visible = false

func _on_Restart_pressed():
	get_tree().paused = false  # Unpause the game before changing the scene
	get_tree().change_scene_to_file("res://Level/CrazyMode.tscn")

func save_high_score(score):
	var file = FileAccess.open("user://high_score.save", FileAccess.WRITE)
	file.store_var(score)
	file.close()

func load_high_score():
	if FileAccess.file_exists("user://high_score.save"):
		var file = FileAccess.open("user://high_score.save", FileAccess.READ)
		var score = file.get_var()
		file.close()
		return score
	else:
		return 0


func _on_mainmenubutton_pressed():
	get_tree().paused = false  # Unpause the game before changing the scene
	get_tree().change_scene_to_file("res://MainMenu.tscn")
