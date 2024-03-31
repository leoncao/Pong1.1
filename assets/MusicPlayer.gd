extends Node

var audioStreamPlayer

func _ready():
	audioStreamPlayer = AudioStreamPlayer.new()
	audioStreamPlayer.stream = load("res://assets/Sounds/pong.mp3")
	audioStreamPlayer.connect("finished", self, "_on_AudioStreamPlayer_finished")
	add_child(audioStreamPlayer)
	audioStreamPlayer.play()

func _on_AudioStreamPlayer_finished():
	audioStreamPlayer.play()
