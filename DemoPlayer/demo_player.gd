extends CharacterBody3D

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var controller = $PlayerController
@export var SPEED = 5.0
@export var JUMP_VELOCITY = 4.5
var can_move_camera := true

var last_footstep_time := 0.0
const FOOTSTEP_INTERVAL := 0.4  # seconds between steps


@export var footstep_sounds: Array[AudioStream] = []  # Assign sounds in inspector
var is_walking := false
@onready var footstep_timer: Timer = get_node("/root/DemoLevel/FootstepTimer")
@onready var footstep_player: AudioStreamPlayer3D = $"../FootstepPlayer"


@export var mouse_sensibility = 1200
@export var ladder_height_subtract = 1

var min_camera_x = deg_to_rad(-90)
var max_camera_x =  deg_to_rad(90)
var camera
var ladder_height = 0

@export var show_velocity_debug := false
@export var allow_rotation := true

var bob_timer := 0.0
@export var bob_amount := 0.05
@export var bob_speed := 10.0
var original_camera_y := 0.0


enum PLAYER_MODES {
	WALK,
	LADDER
}
var current_mode := PLAYER_MODES.WALK

var tween


func apply_camera_bob(delta):
	if is_walking:
		bob_timer += delta * bob_speed
		camera.position.y = original_camera_y + sin(bob_timer) * bob_amount
	else:
		camera.position.y = lerp(camera.position.y, original_camera_y, 10 * delta)

func _ready():
	camera = controller.camera
	original_camera_y = camera.position.y
	print("🧍 Player ready. Mode: WALK")

func _physics_process(delta):
	if show_velocity_debug:
		print("📈 Velocity: ", velocity)
		
	match current_mode:
		PLAYER_MODES.WALK:
			walk_process(delta)
		PLAYER_MODES.LADDER:
			ladder_process(delta)
	apply_camera_bob(delta)

func walk_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		if Input.is_action_just_pressed("Jump"):
			velocity.y = JUMP_VELOCITY
			print("🦘 Jump pressed! Velocity: ", velocity.y)

	# move this BEFORE using `direction`
	var input_dir = Input.get_vector("moveLeft", "moveRight", "moveUp", "moveDown")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED

		if not is_walking:
			is_walking = true
			footstep_timer.start(0.5)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

		if is_walking:
			is_walking = false
			footstep_timer.stop()


	_post_walk_effects() # 🔁 Check for horror events

	if direction:
		if not is_walking:
			is_walking = true
			footstep_timer.start()
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		if is_walking:
			is_walking = false
			footstep_timer.stop()

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
			
	if event is InputEventKey and event.pressed:
		if event.keycode in [KEY_W, KEY_A, KEY_S, KEY_D]:
			var now = Time.get_ticks_msec() / 1000.0
			if now - last_footstep_time > FOOTSTEP_INTERVAL:
				play_footstep_sound()
				last_footstep_time = now



func set_player_mode(mode: PLAYER_MODES):
	current_mode = mode
	print("🔁 Player mode changed to: ", mode)
	if mode == PLAYER_MODES.LADDER:
		_post_ladder_effects() # 👻 Horror cue for ladders


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
	
	
	# 🧪 Optional scary ambient triggers (e.g. after jumping or walking a lot)
var step_counter := 0
var horror_threshold := 25

func maybe_trigger_horror():
	step_counter += 1
	if step_counter >= horror_threshold:
		step_counter = 0
		if Engine.has_singleton("GameEnhancer"):
			var enhancer = Engine.get_singleton("GameEnhancer")
			if enhancer.has_method("ambient_horror_event"):
				enhancer.ambient_horror_event()

# 🚶 Call horror checks after walking
func _post_walk_effects():
	step_counter += 1
	if step_counter >= horror_threshold:
		step_counter = 0
		if Engine.has_singleton("GameEnhancer"):
			var enhancer = Engine.get_singleton("GameEnhancer")
			if enhancer.has_method("ambient_horror_event"):
				enhancer.ambient_horror_event()

# 🪜 Ladder transitions can trigger eerie sounds
func _post_ladder_effects():
	if Engine.has_singleton("GameEnhancer"):
		var enhancer = Engine.get_singleton("GameEnhancer")
		if enhancer.has_method("trigger_screen_glitch"):
			enhancer.trigger_screen_glitch()

func play_footstep_sound():
	footstep_player.play()
	print("👣 Footstep sound played")

func _on_footstep_timer_timeout():
	if footstep_sounds.size() > 0:
		var sfx = footstep_sounds[randi() % footstep_sounds.size()]
		footstep_player.stream = sfx
		footstep_player.play()
		if step_counter >= horror_threshold:
			Engine.get_singleton("GameEnhancer").panic_effect()

		
		


# --- ADDED: Breathing and Heartbeat Horror System ---
@onready var breathing_player: AudioStreamPlayer3D = $"../breath"
@onready var heartbeat_player: AudioStreamPlayer3D = $"../AudioStreamPlayer3D"
var calm_timer := 0.0
var panic_level := 0.0  # 0 = calm, 1 = max panic
var PANIC_DECAY := 0.1
var PANIC_INCREMENT := 0.05
var PANIC_THRESHOLD := 0.6

func _process(delta):
	_update_panic(delta)
	_handle_audio_feedback()

func _update_panic(delta):
	if is_walking:
		panic_level = clamp(panic_level + PANIC_INCREMENT * delta, 0, 1)
	else:
		panic_level = clamp(panic_level - PANIC_DECAY * delta, 0, 1)

func _handle_audio_feedback():
	if panic_level > 0.01:
		if not breathing_player.playing:
			breathing_player.play()
		if not heartbeat_player.playing and panic_level > PANIC_THRESHOLD:
			heartbeat_player.play()
	else:
		if breathing_player.playing:
			breathing_player.stop()
		if heartbeat_player.playing:
			heartbeat_player.stop()
