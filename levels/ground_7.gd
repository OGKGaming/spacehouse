extends MeshInstance3D

@onready var warning_sound := $AudioStreamPlayer3D2
func _on_body_entered(body):
	if body.name == "Player":
		if not warning_sound.playing:
			warning_sound.play()

func _on_body_exited(body):
	if body.name == "Player":
		if warning_sound.playing:
			warning_sound.stop()
