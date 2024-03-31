extends Node

var lastScored = "" 
var crazyMode = true
var startTime = 0
export var currentScore = 0
var highestScore = 0  # This will keep track of the coins earned in the current game session
var currentSessionCoins = 0
var save_file = ConfigFile.new()
func _ready():
	$CountdownTimer.start()
	get_tree().call_group("BallGroup", "stop_ball")
	$PauseMenu.hide() 
	$ModeLabel.text = "Mode: Hardcore"  # Set the initial mode
	startTime = OS.get_ticks_msec()
	$PauseMenu.set_game_mode(self)
	$Restart.pause_mode = Node.PAUSE_MODE_PROCESS  # Allow the Restart button to process input when the game is paused
	highestScore = load_high_score()  # Load the highest score at the start of the game
	Global.load_coins()  # Load the total coins at the start of the game
	$TotalCoinsLabel.text = "Total Coins: " + str(Global.coins)  # Display the total coins earned across all game sessions
		# Load the player's selection
	var save_file = ConfigFile.new()  # Create a new ConfigFile instance
	var error = save_file.load("user://selection.cfg")
	if error == OK:
		var texture_path = save_file.get_value("selection", "texture")
		#print("Texture path: ", texture_path)  # Print the texture path
		var texture = load(texture_path)
		#print("Loaded texture: ", texture)  # Print the loaded texture
		#print("Sprite node before: ", $Player/Sprite.texture)  # Print the Sprite node's texture before the assignment
		$Player/Sprite.texture = texture
		#print("Sprite node after: ", $Player/Sprite.texture)  # Print the Sprite node's texture after the assignment
	
		
func _on_LeftWall_body_entered(body):
	$CrazyBall.position = Vector2(640,320)
	lastScored = "AI" 
	stop_game() 
	$GameOver.visible = true 
	$Restart.visible = true
	$mainmenubutton.visible = true  

func _on_RightWall_body_entered(body):
	$CrazyBall.position = Vector2(640,320)
	lastScored = "Player" 
	stop_game()
	if not $GameOver.visible:  # Only show the You Win text if the Game Over text is not visible
		$YouWin.visible = true 
	$Restart.visible = true
	$mainmenubutton.visible = true 

func _process(delta):
	$CountdownLabel.text = str(int($CountdownTimer.time_left) + 1)
	if crazyMode and not get_tree().paused:
		if OS.get_ticks_msec() - startTime >= 1000:  # If a second has passed
			currentScore += 1  # Increase the current score
			currentSessionCoins += 0.5  # Increase the coins earned in the current game session
			startTime = OS.get_ticks_msec()  # Reset the start time
		$CurrentScoreLabel.text = "Current Score: " + str(currentScore)
		$HighestScoreLabel.text = "Highest Score: " + str(highestScore)  # Display the highest score
		$TotalCoinsLabel.text = "Total Coins: " + str(Global.coins)  # Update the total coins earned across all game sessions

func _on_CountdownTimer_timeout():
	get_tree().call_group("BallGroup", "restart_ball")
	$CountdownLabel.visible = false

func stop_game():
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
		$ScoreSummary.text = "Current Score: " + str(currentScore) + "\nHighest Score: " + str(highestScore) + "\nCoins Earned: " + str(currentSessionCoins)

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
	get_tree().change_scene("res://Level/CrazyMode.tscn")

func save_high_score(score):
	var file = File.new()
	file.open("user://high_score.save", File.WRITE)
	file.store_var(score)
	file.close()

func load_high_score():
	var file = File.new()
	if file.file_exists("user://high_score.save"):
		file.open("user://high_score.save", File.READ)
		var score = file.get_var()
		file.close()
		return score
	else:
		return 0


func _on_mainmenubutton_pressed():
	get_tree().paused = false  # Unpause the game before changing the scene
	get_tree().change_scene("res://MainMenu.tscn")
