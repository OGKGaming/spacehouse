extends CharacterBody3D

@onready var eaten_sound: AudioStreamPlayer3D = $"../AudioStreamPlayer3D2"  # Add an AudioStreamPlayer3D node


var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var controller = $PlayerController
@export var SPEED = 5.0
@export var JUMP_VELOCITY = 4.5
var can_move_camera := true

# === Screen bend (barrel warp) – runtime-created ===
@export var enable_screen_bend := true
var _curve_base := 0.12        # baseline bend amount
var _curve_pulse := 0.0        # transient pulse on roar
var _screen_layer: CanvasLayer = null
var _screen_rect: ColorRect = null
var _screen_mat: ShaderMaterial = null


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

var stuck_timer := 0.0
const STUCK_THRESHOLD := 1  # Time in seconds before sound triggers
const STUCK_SPEED := 0.1      # Max speed to be considered "stuck"



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
	camera = controller.camera
	original_camera_y = camera.position.y
	print("🧍 Player ready. Mode: WALK")
	_init_screen_bend()  # <<< ADD THIS

	

func _physics_process(delta):
	if show_velocity_debug:
		print("📈 Velocity: ", velocity)
		
	match current_mode:
		PLAYER_MODES.WALK:
			walk_process(delta)
		PLAYER_MODES.LADDER:
			ladder_process(delta)
	apply_camera_bob(delta)
	# -- STUCK DETECTION DEBUG --
	var input_pressed := Input.is_action_pressed("moveLeft") \
		or Input.is_action_pressed("moveRight") \
		or Input.is_action_pressed("moveUp") \
		or Input.is_action_pressed("moveDown")

	var is_moving := velocity.length() > 0.05

	if input_pressed and not is_moving:
		stuck_timer += delta
		print("⛔ STUCK: ", stuck_timer)
		eaten_sound.play()
		_curve_pulse = 60   # <<< bend spike when the house roars
		print("🎧 Playing 'eaten' sound")
		
	else:
		stuck_timer = 0.0

	if stuck_timer > STUCK_THRESHOLD:
		if not eaten_sound.playing:
			print("🎧 Playing 'eaten' sound")
			eaten_sound.play()
		# --- Screen bend drive ---
	if _screen_mat:
		# decay any roar pulse
		_curve_pulse = max(0.0, _curve_pulse - delta * 1.2)
		# bend grows slightly with panic, spikes with pulse
		var curve := _curve_base + (panic_level * 0.04) + (_curve_pulse * 0.08)
		_screen_mat.set_shader_parameter("curve", curve)




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
	#wprint("👣 Footstep sound played")

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
		# --- Screen bend drive (post) ---
	if _screen_mat:
		_curve_pulse = max(0.0, _curve_pulse - delta * 1.2) # decay roar pulse
		var curve := _curve_base + (panic_level * 0.04) + (_curve_pulse * 0.08)
		_screen_mat.set_shader_parameter("curve", curve)


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




func _init_screen_bend():
	if not enable_screen_bend: return
	if _screen_mat: return  # already set up

	# Create shader from code (kept INSIDE this script as requested)
	var shader_code := """
shader_type canvas_item;
uniform float curve : hint_range(0.0, 0.5) = 0.12;
void fragment() {
	vec2 uv = SCREEN_UV * 2.0 - 1.0;
	float r2 = dot(uv, uv);
	vec2 barrel = uv * (1.0 + curve * r2);
	vec3 col = texture(SCREEN_TEXTURE, barrel * 0.5 + 0.5).rgb;
	COLOR = vec4(col, 1.0);
}
"""
	var sh := Shader.new()
	sh.code = shader_code
	_screen_mat = ShaderMaterial.new()
	_screen_mat.shader = sh

	_screen_layer = CanvasLayer.new()
	_screen_layer.layer = 100  # on top of UI
	add_child(_screen_layer)

	_screen_rect = ColorRect.new()
	_screen_rect.color = Color(1,1,1,0)  # invisible; shader shows screen
	_screen_rect.material = _screen_mat
	_screen_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Fullscreen anchors
	_screen_rect.anchor_left = 0.0
	_screen_rect.anchor_top = 0.0
	_screen_rect.anchor_right = 1.0
	_screen_rect.anchor_bottom = 1.0
	_screen_rect.offset_left = 0
	_screen_rect.offset_top = 0
	_screen_rect.offset_right = 0
	_screen_rect.offset_bottom = 0

	_screen_layer.add_child(_screen_rect)
# Keep it sized on resize (anchors already handle this, but safe to connect)
	var vp := get_viewport()
	if not vp.size_changed.is_connected(Callable(self, "_on_viewport_resized")):
		vp.size_changed.connect(_on_viewport_resized)


func _on_viewport_resized():
	if _screen_rect:
		# anchors stretch, but force a refresh just in case
		_screen_rect.queue_redraw()
