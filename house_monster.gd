extends CharacterBody3D

@export var speed := 2.2
@export var chase_speed := 2.8
@export var detection_radius := 16.0
@export var attack_radius := 1.8
@export var wander_radius := 12.0
@export var step_interval_at_speed1 := 0.45
@export var flip_forward := false # set true if model faces +Z

@onready var agent: NavigationAgent3D = $NavigationAgent3D
@onready var model: Node3D = $model_walk
@onready var anim: AnimationPlayer = $model_walk/AnimationPlayer
@onready var sfx: AudioStreamPlayer3D = $Footsteps

var home := Vector3.ZERO
var target := Vector3.ZERO
var walk_anim := ""
var step_accum := 0.0
var gravity := ProjectSettings.get_setting("physics/3d/default_gravity") as float

enum { WANDER, CHASE, ATTACK }
var state := WANDER

func _ready() -> void:
	home = global_transform.origin

	# Animation: find any "walk" and loop
	anim.root_node = ".."
	for n in anim.get_animation_list():
		if n.to_lower().find("walk") != -1:
			walk_anim = n
			break
	if walk_anim != "":
		var a: Animation = anim.get_animation(walk_anim)
		if a: a.loop_mode = Animation.LOOP_LINEAR
		anim.play(walk_anim)

	# Navigation/avoidance
	agent.avoidance_enabled = true
	agent.radius = 0.6   # tune to your collider width
	agent.height = 3.0   # tune to monster height
	agent.max_speed = chase_speed

	_pick_wander()

func _physics_process(delta: float) -> void:
	# gravity
	if not is_on_floor(): velocity.y -= gravity * delta
	else: velocity.y = 0.0

	var player := _get_player()
	var pos := global_transform.origin

	match state:
		WANDER:
			if player and pos.distance_to(player.global_transform.origin) <= detection_radius:
				state = CHASE
			_move_towards(target, speed)
			if pos.distance_to(target) < 0.5:
				_pick_wander()

		CHASE:
			if not player:
				state = WANDER
			else:
				target = player.global_transform.origin
				_move_towards(target, chase_speed)
				if pos.distance_to(target) <= attack_radius:
					state = ATTACK

		ATTACK:
			if player:
				target = player.global_transform.origin
				_move_towards(target, chase_speed)
				if pos.distance_to(target) > attack_radius * 1.25:
					state = CHASE
			else:
				state = WANDER

	move_and_slide()

	# footsteps cadence ~ horizontal speed
	var horiz := Vector2(velocity.x, velocity.z).length()
	if is_on_floor() and horiz > 0.1:
		var step_interval := 1
		step_accum += delta
		if step_accum >= step_interval:
			step_accum = 0.0
			if sfx: sfx.play()

func _move_towards(goal: Vector3, spd: float) -> void:
	agent.set_target_position(goal)
	var next := agent.get_next_path_position()
	var dir := next - global_transform.origin
	dir.y = 0.0
	if dir.length() > 0.001:
		dir = dir.normalized()
		var face: Vector3 = (-dir) if flip_forward else dir
		# rotate only the visual so collider keeps heading from velocity
		model.look_at(model.global_transform.origin + face, Vector3.UP)
		velocity.x = dir.x * spd
		velocity.z = dir.z * spd
	else:
		velocity.x = move_toward(velocity.x, 0.0, 8.0)
		velocity.z = move_toward(velocity.z, 0.0, 8.0)

func _pick_wander() -> void:
	var off := Vector3(randf_range(-wander_radius, wander_radius), 0, randf_range(-wander_radius, wander_radius))
	target = home + off

func _get_player() -> Node3D:
	var n := get_tree().get_first_node_in_group("player")
	return n if n is Node3D else null
