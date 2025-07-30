extends Node

class_name Player

@onready var camera = $Head/Camcorder as Camera3D
@onready var ray_cast: RayCast3D = $Head/Camcorder/RayCast3D
@onready var interaction_label: Label = $CenterContainer/Label
@onready var inventory = $Inventory

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var can_move_camera = true
@export var mouse_sensibility = 1200

func enable_camera_movement():
	can_move_camera = true
	interaction_label.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	Inventory.player = self

func _process(_delta):
	if ray_cast.is_colliding():
		if not interaction_label.visible and can_move_camera:
			interaction_label.visible = true
			play_label_popin()
	else:
		if interaction_label.visible:
			play_label_popout()

			
func _input(event):
	if event.is_action_pressed("Interact") and ray_cast.is_colliding():
		var object = ray_cast.get_collider()
		
		if object is InteractionBase:
			if object is DragInteraction:
				can_move_camera = false
				interaction_label.visible = false
				object.interaction_end.connect(enable_camera_movement,CONNECT_ONE_SHOT)
				object.interact(self)
			else:
				object.interact(self)

	if event.is_action_pressed("ToggleInventory"):
		if not inventory.container.visible:
			enable_camera_movement()
		else:
			can_move_camera = false
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				

# --- ADDED: Smooth scale pop-in effect for interaction label ---
@onready var interaction_tween := create_tween()


func play_label_popin():
	if interaction_tween:
		interaction_tween.kill()
	interaction_tween = create_tween()
	interaction_label.scale = Vector2(0.7, 0.7)
	interaction_tween.tween_property(interaction_label, "scale", Vector2(1, 1), 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
func play_label_popout():
	if interaction_tween:
		interaction_tween.kill()
	interaction_tween = create_tween()
	interaction_tween.tween_property(interaction_label, "scale", Vector2(0.7, 0.7), 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	interaction_tween.tween_callback(Callable(self, "_hide_interaction_label"))
	_hide_interaction_label()

func _hide_interaction_label():
	interaction_label.visible = false
	
