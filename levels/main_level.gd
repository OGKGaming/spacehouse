extends Node3D

@onready var chapter_manager := $ChapterManager
@onready var player := $DemoPlayer
var pause_menu: CanvasLayer
var is_paused := false

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	await chapter_manager.advance()

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
