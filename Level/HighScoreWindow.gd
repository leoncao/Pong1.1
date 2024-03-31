extends Control

var highScore = 0

func _ready():
	hide()

func show_high_score(currentScore):
	if currentScore > highScore:
		highScore = currentScore
	$Label.text = "High Score: " + str(highScore)
	show()
