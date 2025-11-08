extends VideoStreamPlayer

var playlist := [	
	preload("res://intro.ogv"),
	preload("res://Hailuo_Video_A wide, cinematic shot of a gr_441545213864075273.ogv"),
	preload("res://Hailuo_Video_A dark, barely lit room Julia_441554228283150337.ogv"),
	preload("res://Hailuo_Video_A wide, cinematic shot of a gr_441545213864075273.ogv"),
]

var index := 0

func _ready():
	connect("finished", Callable(self, "_on_video_finished"))
	play_next()

func play_next():
	if index >= playlist.size():
		print("All videos done.")
		return
	stream = playlist[index]
	index += 1
	play()

func _on_video_finished():
	play_next()
