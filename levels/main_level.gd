extends Node3D

@onready var chapter_manager := $ChapterManager
@onready var player := $DemoPlayer
var pause_menu: CanvasLayer
var is_paused := false

func _ready():
	video_player.play()
	
	# Start with normal size
	video_player.scale = Vector2(1, 1)
	
	# Tween to zoom in slowly
	var tween = create_tween()
	tween.tween_property(video_player, "scale", Vector2(1.5, 1.5), 5.0)  # zoom in over 5 seconds
	tween.set_trans(Tween.TRANS_SINE)

	video_player.play()
	video_player.connect("finished", Callable(self, "_on_video_finished"))

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	await chapter_manager.advance()
	chapter_manager._play_in_game_monologue(1)


func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		if is_paused:
			_resume_game()
		else:
			_pause_game()

func _pause_game():
	is_paused = true
	player.can_move_camera = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_create_pause_menu()

func _resume_game():
	is_paused = false
	player.can_move_camera = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if pause_menu:
		pause_menu.queue_free()
		pause_menu = null

func _create_pause_menu():
	pause_menu = CanvasLayer.new()
	pause_menu.layer = 100
	add_child(pause_menu)

	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(300, 200)
	pause_menu.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(vbox)

	var label := Label.new()
	label.text = "Paused"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 28)
	vbox.add_child(label)

	var resume_button := Button.new()
	resume_button.text = "Resume"
	resume_button.pressed.connect(_resume_game)
	vbox.add_child(resume_button)

	var quit_button := Button.new()
	quit_button.text = "Quit"
	quit_button.pressed.connect(func(): get_tree().quit())
	vbox.add_child(quit_button)
	

@onready var video_player =$CanvasLayer/VideoStreamPlayer
var play_count = 0
var max_plays = 4

  
func _on_video_finished():
	play_count += 1
	if play_count < max_plays:
		video_player.play()  # Replay
	else:
		print("Video finished playing", max_plays, "times.")
		# Optional: fade out, change scene, etc.
		# get_tree().change_scene_to_file("res://NextScene.tscn")
