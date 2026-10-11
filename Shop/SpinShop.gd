extends Control

var paddles = ["Paddle1", "Paddle2", "Paddle3"]  # List of paddles that can be won
var selectedPaddle = ""

func _ready():
	$Spin.connect("pressed", Callable(self, "_on_Spin_pressed"))

func _on_Spin_pressed():
	selectedPaddle = paddles[randi() % paddles.size()]
	print("You won: " + selectedPaddle)


