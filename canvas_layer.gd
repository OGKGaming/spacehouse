extends CanvasLayer
class_name SplashScreen

@export_file("*.tscn") var next_scene: String = "res://MainMenu.tscn"
@export var fade_in_time: float = 0.8
@export var hold_time: float = 1.1
@export var fade_out_time: float = 0.8

@onready var logo: TextureRect = $Logo

func _ready() -> void:
	# Start transparent
	#logo.modulate.a = 0.0

	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(logo, "modulate:a", 1.0, fade_in_time)   # Fade in
	tween.tween_interval(hold_time)                               # Hold
	tween.tween_property(logo, "modulate:a", 0.0, fade_out_time)  # Fade out
	tween.tween_callback(_go_next)

func _go_next() -> void:
	if next_scene != "":
		get_tree().change_scene_to_file(next_scene)
	else:
		queue_free()
