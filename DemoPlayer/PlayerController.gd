extends Node
class_name Player

signal speed_multiplier_changed(multiplier: float)
signal crouch_state_changed(is_crouching: bool)
signal run_state_changed(is_running: bool)

@onready var camera = $Head/Camcorder as Camera3D
@onready var head: Node3D = $Head
@onready var ray_cast: RayCast3D = $Head/Camcorder/RayCast3D
@onready var interaction_label: Label = $CenterContainer/Label
@onready var inventory = $Inventory

# OPTIONAL: if you have a separate movement node (e.g., CharacterBody3D) that
# wants to directly hear our signals, export its path and we’ll auto-connect.
@export var movement_node_path: NodePath

# --- Movement modifiers ---
@export var run_multiplier: float = 1.7
@export var crouch_multiplier: float = 0.55
@export var crouch_height_delta: float = -0.8   # how far the head drops (meters)
@export var crouch_tween_time: float = 0.12
@export var run_fov_boost: float = 4.0          # extra degrees when running
@export var fov_tween_time: float = 0.10

# Mouse/camera
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var can_move_camera = true
@export var mouse_sensibility = 1200

# Internal state
var _is_running := false
var _is_crouching := false
var _mult := 1.0
var _base_fov := 70.0
var _head_start_y := 0.0

# --- Interaction label tween ---
@onready var interaction_tween := create_tween()

func enable_camera_movement():
	can_move_camera = true
	interaction_label.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	Inventory.player = self

	# Cache starting transforms
	_base_fov = camera.fov
	_head_start_y = head.position.y

	# Optionally wire to your movement node so it can react to speed changes
	if movement_node_path != NodePath():
		var n = get_node_or_null(movement_node_path)
		if n:
			self.speed_multiplier_changed.connect(
				func(mult): if n.has_method("set_speed_multiplier"): n.set_speed_multiplier(mult)
			)
			self.crouch_state_changed.connect(
				func(is_c): if n.has_method("set_crouch"): n.set_crouch(is_c)
			)
			self.run_state_changed.connect(
				func(is_r): if n.has_method("set_running"): n.set_running(is_r)
			)

func _process(_delta):
	if ray_cast.is_colliding():
		if not interaction_label.visible and can_move_camera:
			interaction_label.visible = true
			play_label_popin()
	else:
		if interaction_label.visible:
			play_label_popout()

func _input(event):
	# Interact
	if event.is_action_pressed("Interact") and ray_cast.is_colliding():
		var object = ray_cast.get_collider()
		if object is InteractionBase:
			if object is DragInteraction:
				can_move_camera = false
				interaction_label.visible = false
				object.interaction_end.connect(enable_camera_movement, CONNECT_ONE_SHOT)
				object.interact(self)
			else:
				object.interact(self)

	# Inventory toggle locks/unlocks camera just like you had
	if event.is_action_pressed("ToggleInventory"):
		if not inventory.container.visible:
			enable_camera_movement()
		else:
			can_move_camera = false
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# --- RUN (hold) ---
	if event.is_action_pressed("Run"):
		_set_running(true)
	if event.is_action_released("Run"):
		_set_running(false)

	# --- CROUCH (toggle) ---
	if event.is_action_pressed("Crouch"):
		_set_crouch(not _is_crouching)

# ---- Helpers: run / crouch state changes ----
func _set_running(v: bool) -> void:
	# can’t run while crouching
	var desired = v and not _is_crouching and can_move_camera and not inventory.container.visible
	if desired == _is_running:
		return
	_is_running = desired
	_apply_visuals_for_run(_is_running)
	_recompute_multiplier()
	run_state_changed.emit(_is_running)

func _set_crouch(v: bool) -> void:
	if v == _is_crouching:
		return
	_is_crouching = v
	# leaving crouch doesn’t auto-run; user must hold Run again
	if _is_crouching and _is_running:
		_set_running(false)
	_apply_visuals_for_crouch(_is_crouching)
	_recompute_multiplier()
	crouch_state_changed.emit(_is_crouching)

func _recompute_multiplier() -> void:
	var new_mult := 1.0
	if _is_crouching:
		new_mult = crouch_multiplier
	elif _is_running:
		new_mult = run_multiplier
	if abs(new_mult - _mult) > 0.0001:
		_mult = new_mult
		speed_multiplier_changed.emit(_mult)

# ---- Visual polish: FOV kick + head dip ----
func _apply_visuals_for_run(running: bool) -> void:
	var target_fov := _base_fov + (run_fov_boost if running else 0.0)
	var tw = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(camera, "fov", target_fov, fov_tween_time)

func _apply_visuals_for_crouch(crouching: bool) -> void:
	var target_y := _head_start_y + (crouch_height_delta if crouching else 0.0)
	var tw = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(head, "position:y", target_y, crouch_tween_time)

# --- Interaction label pop in/out (unchanged behavior, just tidied) ---
func play_label_popin():
	if interaction_tween:
		interaction_tween.kill()
	interaction_tween = create_tween()
	interaction_label.scale = Vector2(0.7, 0.7)
	interaction_tween.tween_property(interaction_label, "scale", Vector2(1, 1), 0.2)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func play_label_popout():
	if interaction_tween:
		interaction_tween.kill()
	interaction_tween = create_tween()
	interaction_tween.tween_property(interaction_label, "scale", Vector2(0.7, 0.7), 0.15)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	interaction_tween.tween_callback(Callable(self, "_hide_interaction_label"))
	_hide_interaction_label()

func _hide_interaction_label():
	interaction_label.visible = false
