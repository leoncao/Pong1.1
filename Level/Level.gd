extends Node
#onready var pauseMenu = preload("res://Scenes/PauseMenu.tscn").instance()
onready var blur = $Blur
var blur_amount = 0
export var PlayerScore = 28
export var OpponentScore = 0
export var difficultyLevel = 5
var lastScored = "" 
var save_file = ConfigFile.new()
var bossdefeat = load("res://assets/Sounds/boss_defeat.mp3")  # Load the "Defeated" sound
#bossdefeat.loop = false  # Stop the sound from looping
var bossSound = load("res://assets/Sounds/boss_sound.wav")  # Load the "Boss" sound
var popup = Label.new()  # Create a new Label node for the popup text
var tween = Tween.new()  # Create a new Tween node for the animation

func _ready():
	$CountdownTimer.start()
	get_tree().call_group("BallGroup", "stop_ball")
	$PauseMenu.hide() 
	$ModeLabel.text = "Mode: Classic"  # Set the initial mode
	$PauseMenu.set_game_mode(self)
		# Add the popup and tween nodes to the scene
	var save_file = ConfigFile.new()  # Create a new ConfigFile instance
	var error = save_file.load("user://selection.cfg")
	if error == OK:
		var texture_path = save_file.get_value("selection", "texture")
		var texture = load(texture_path)
		$Player/Sprite.texture = texture
	# Add the popup and tween nodes to the scene
	add_child(popup)
	add_child(tween)
	popup.text = "You reached Level 1"
	popup.rect_min_size = Vector2(200, 50)  # Set the size of the popup
	#popup.rect_centered = true  # Center the popup
	popup.align = Label.ALIGN_CENTER  # Align the text to the center
	popup.valign = Label.VALIGN_CENTER  # Vertically align the text to the center
	popup.rect_position = get_viewport().size / 2 - popup.rect_min_size / 2 # Position the popup in the center of the screen
	popup.hide()  # Hide the popup initially
	
func _on_LeftWall_body_entered(body):
	#$Ball.position = Vector2(640,320)
	OpponentScore += 1
	lastScored = "AI" 
	score_achieved()
	shake_camera(1,0.3)
	if OpponentScore == 1 and PlayerScore == 0:
		Achievements.unlock("shutout_game")

func _on_RightWall_body_entered(body):
	#$Ball.position = Vector2(640,320)
	PlayerScore += 1
	lastScored = "Player" 
	score_achieved()
	shake_camera(1,0.2)
	if PlayerScore == 10:
		Achievements.unlock("score_10_points")
		
func _process(delta):
	$PlayerScore.text = str(PlayerScore)
	$OpponentScore.text = str(OpponentScore)
	$CountdownLabel.text = str(int($CountdownTimer.time_left) + 1)
	if PlayerScore > OpponentScore and PlayerScore >= 1 and not Achievements.achievements["first_win"]["unlocked"]:
		Achievements.unlock("first_win")
		
		
func _on_CountdownTimer_timeout():
	get_tree().call_group("BallGroup", "restart_ball")
	$CountdownLabel.visible = false
func score_achieved():
	$Ball.position = Vector2(640,320)
	get_tree().call_group("BallGroup", "stop_ball")
	$CountdownTimer.start()
	$CountdownLabel.visible = true
	$ScoreSound.play()
	$Player.position.x = 35
	$Opponent.position.x = 1280 - 35
	
	if PlayerScore in [5, 10, 15, 20, 25, 29] and lastScored == "Player": 
		difficultyLevel += 1
		print("Difficulty level increased to " + str(difficultyLevel)) 
		$Opponent.increase_difficulty(difficultyLevel) 
		$levelUpSound.play() # Play the level up sound
		if difficultyLevel >= 3: 
			get_tree().call_group("BallGroup", "increase_speed")
		# Show the level up popup
		if difficultyLevel <= 5:
			popup.text = "You reached Level " + str(difficultyLevel)
		else:
			popup.text = "THE BOSS APPEARS"
		# ... rest of your code ...		# Show the level up popup
		
		popup.show()  # Show the popup
		tween.interpolate_property(popup, "modulate:a", 0, 1, 1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)  # Fade in
		tween.start()
		yield(get_tree().create_timer(3), "timeout")  # Wait for 3 seconds
		tween.interpolate_property(popup, "modulate:a", 1, 0, 1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)  # Fade out
		tween.start()
		yield(tween, "tween_completed")  # Wait for the animation to complete
		popup.hide()  # Hide the popup
	
	if PlayerScore == 25: 
		$Opponent.speed += 50
	if PlayerScore == 29:
		$PlayerScore.hide()  # Hide the player score label
		$OpponentScore.hide()  # Hide the opponent score label
#		get_tree().root.get_node("CanvasLayer").modulate = Color(1, 0, 0)  # Change the screen background to red
		$bossSound.play()  # Play the "Boss" sound
		shake_camera(5,0.5)
		$Opponent.speed += 100  # Increase the AI paddle speed
		#$Opponent.scale *= 1  # Increase the AI paddle size
		#$Opponent/CollisionPolygon2D.scale *= 0.2  # Increase the AI paddle collision shape
	if PlayerScore == 30:
		$bossdefeat.play()  # Play the "Defeated" sound
		bossdefeat.loop = false 
		stop_game()
	if OpponentScore == 30:
		$gameover.play()
		game_over()

func shake_camera(intensity, duration):
	var timer = 0.0
	while timer < duration:
		var offset = Vector2(rand_range(-intensity, intensity), rand_range(-intensity, intensity))
		$Camera2D.offset = offset
		timer += get_process_delta_time()
		yield(get_tree().create_timer(0.05), "timeout")
	$Camera2D.offset = Vector2.ZERO

func game_over():
	get_tree().call_group("BallGroup", "stop_ball") 
	$Opponent.speed = 0 
	$CountdownTimer.stop()
	blur_amount = 15 # Set the blur amount to 5
	blur.material.set_shader_param("blur_amount", blur_amount) # Apply the blur effect 
	$Player.speed = 0
	$GameOver.show()  # Show the "You Win" popup
	$Restart.show()
	$ParallaxBackground.show()
	
func stop_game():
	get_tree().call_group("BallGroup", "stop_ball") 
	$Opponent.speed = 0 
	$CountdownTimer.stop()
	blur_amount = 15 # Set the blur amount to 5
	blur.material.set_shader_param("blur_amount", blur_amount) # Apply the blur effect 
	$Player.speed = 0
	$YouWin.show()  # Show the "You Win" popup
	$Restart.show()
	$ParallaxBackground.show()
	
	
func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		get_tree().paused = !get_tree().paused
		if get_tree().paused:
			show_pause_menu()
			$Player.set_process(false)  # Stop the player's movement
		else:
			hide_pause_menu()
			$Player.set_process(true)  # Resume the player's movement
			
			
func show_pause_menu():
	$PauseMenu.show()
	$PauseMenu.visible = true
func hide_pause_menu():
	$PauseMenu.hide()
	$PauseMenu.visible = false
	
func _on_Restart_pressed():
	$ParallaxBackground.set_offset(Vector2(0, 0))  # Reset the parallax background
	get_tree().change_scene("res://Level/Level.tscn")
