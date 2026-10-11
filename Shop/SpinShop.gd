extends Control

var paddles = ["Paddle1", "Paddle2", "Paddle3"]  # List of paddles that can be won
var selectedPaddle = ""

func _ready():
	if not $Spin.pressed.is_connected(_on_Spin_pressed):  # 场景里已连好信号，避免 Godot 4 重复连接报错
		$Spin.pressed.connect(_on_Spin_pressed)

func _on_Spin_pressed():
	selectedPaddle = paddles[randi() % paddles.size()]
	print("You won: " + selectedPaddle)


