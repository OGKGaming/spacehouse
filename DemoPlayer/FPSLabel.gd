extends Label

@export var update_interval := 0.2  # How often to refresh FPS (seconds)
var time_accumulator := 0.0

func _process(delta):
	time_accumulator += delta
	if time_accumulator >= update_interval:
		var fps = Engine.get_frames_per_second()
		text = "FPS: %d" % fps
		time_accumulator = 0.0
