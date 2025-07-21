extends CharacterBody3D

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var controller = $PlayerController
@export var SPEED = 5.0
@export var JUMP_VELOCITY = 4.5

@export var mouse_sensibility = 1200
@export var ladder_height_subtract = 1

var min_camera_x = deg_to_rad(-90)
var max_camera_x =  deg_to_rad(90)
var camera
var ladder_height = 0

@export var show_velocity_debug := false
@export var allow_rotation := true

enum PLAYER_MODES {
	WALK,
	LADDER
}
var current_mode := PLAYER_MODES.WALK

var tween

func _ready():
	camera = controller.camera
	print("🧍 Player ready. Mode: WALK")

func _physics_process(delta):
	if show_velocity_debug:
		print("📈 Velocity: ", velocity)
		
	match current_mode:
		PLAYER_MODES.WALK:
			walk_process(delta)
		PLAYER_MODES.LADDER:
			ladder_process(delta)

func walk_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		if Input.is_action_just_pressed("Jump"):
			velocity.y = JUMP_VELOCITY
			print("🦘 Jump pressed! Velocity: ", velocity.y)

	var input_dir = Input.get_vector("moveLeft", "moveRight", "moveUp", "moveDown")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		# placeholder: trigger walking sound here
		# play_footstep()
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func ladder_process(_delta):
	if Input.is_action_just_pressed("Jump"):
		velocity.y = JUMP_VELOCITY
		print("🧗 Jumped off ladder.")
		set_player_mode(PLAYER_MODES.WALK)
		return
	
	var input_dir = Input.get_vector("moveLeft", "moveRight", "moveDown", "moveUp")
	var direction = (transform.basis * Vector3(0, input_dir.y, 0)).normalized()

	if direction:
		velocity.y = direction.y * SPEED
	else:
		velocity.y = move_toward(velocity.y, 0, SPEED)

	if position.y >= ladder_height - ladder_height_subtract and velocity.y > 0:
		velocity.y = 0
		print("🛑 Reached top of ladder.")

	move_and_slide()

func _input(event):
	if event is InputEventMouseMotion and controller.can_move_camera and allow_rotation:
		rotation.y -= event.relative.x / mouse_sensibility
		camera.rotation.x -= event.relative.y / mouse_sensibility
		camera.rotation.x = clamp(camera.rotation.x, min_camera_x, max_camera_x)

		if camera.rotation.x <= min_camera_x or camera.rotation.x >= max_camera_x:
			print("⚠️ Camera clamped at vertical limit.")

func set_player_mode(mode: PLAYER_MODES):
	current_mode = mode
	print("🔁 Player mode changed to: ", mode)

func set_on_ladder(on_ladder, height, reference: Node3D):
	if on_ladder:
		print("🪜 Player grabbed ladder.")
		velocity = Vector3.ZERO
		var ref_pos = reference.global_position
		var new_position = Vector3(ref_pos.x, position.y, ref_pos.z)
		tween = create_tween()
		tween.tween_property(self, "position", new_position, 0.2) 
		tween.tween_property(self, "quaternion", reference.quaternion, 0.2) 
		
		velocity = Vector3.ZERO
		set_player_mode(PLAYER_MODES.LADDER)
		velocity = Vector3.ZERO
	else:
		print("⬇️ Player left ladder.")
		set_player_mode(PLAYER_MODES.WALK)

	ladder_height = height
