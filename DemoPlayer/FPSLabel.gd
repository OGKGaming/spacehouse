extends Label

@export var update_interval := 0.2  # How often to refresh FPS (seconds)
var time_accumulator := 0.0

# --- ADDED CODE ---
var phrases := [
	"Keep it smooth 🛼",
	"Pixel-perfect timing!",
	"You're blazing fast! 🔥",
	"Just vibin' at %d FPS 🎮",
	"Hold tight! 🚀",
	"Frame-tastic performance!",
	"Like butter on code toast 🧈",
]

func _process(delta):
	time_accumulator += delta
	if time_accumulator >= update_interval:
		var fps = Engine.get_frames_per_second()
		text = "FPS: %d" % fps
		time_accumulator = 0.0

		# --- ADDED CODE ---
		var phrase = phrases[randi() % phrases.size()]
		var message = "FPS: %d - %s" % [fps, phrase % fps if "%d" in phrase else phrase]
		#print(message)

		if fps > 100:
			modulate = Color.GREEN
		elif fps > 60:
			modulate = Color.YELLOW
		else:
			modulate = Color.RED
