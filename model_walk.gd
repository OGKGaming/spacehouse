extends Node3D

@export var wander_radius := 10.0
@export var speed := 2.0
@export var chase_speed := 2.6
@export var detection_radius := 14.0
@export var attack_radius := 1.7
@export var step_interval_at_speed1 := 0.45

@onready var ap: AnimationPlayer = $AnimationPlayer
@onready var agent: NavigationAgent3D = $NavigationAgent3D
@onready var sfx: AudioStreamPlayer3D = $Footsteps

var home := Vector3.ZERO
var target := Vector3.ZERO
var walk_anim := ""
var step_accum := 0.0
var using_nav := true

enum { WANDER, CHASE, ATTACK }
var state := WANDER

func _ready() -> void:
	home = global_transform.origin

	# Bind animation + loop
	ap.root_node = ".."
	for n in ap.get_animation_list():
		if n.to_lower().find("walk") != -1:
			walk_anim = n
			break
	if walk_anim != "":
		var a: Animation = ap.get_animation(walk_anim)
		if a: a.loop_mode = Animation.LOOP_LINEAR
		ap.play(walk_anim)
	else:
		push_warning("No *walk* animation found: " + str(ap.get_animation_list()))

	# Quick nav sanity
	if agent == null:
		using_nav = false
		push_warning("No NavigationAgent3D found. Using simple movement.")
	else:
		# try a tiny path; if next == origin, nav likely not set up
		agent.set_target_position(global_transform.origin + Vector3(0.1, 0, 0.1))
		await get_tree().process_frame
		var nxt := agent.get_next_path_position()
		if (nxt - global_transform.origin).length() < 0.001:
			using_nav = false
			push_warning("NavMesh/Region missing or monster not on it. Falling back to simple wandering.")

	_pick_wander()

func _physics_process(delta: float) -> void:
	var player := _get_player()
	var pos := global_transform.origin

	match state:
		WANDER:
			if player and pos.distance_to(player.global_transform.origin) <= detection_radius:
				state = CHASE
			_move_towards(target, speed, delta)
			if pos.distance_to(target) < 0.5:
				_pick_wander()

		CHASE:
			if not player:
				state = WANDER
			else:
				target = player.global_transform.origin
				_move_towards(target, chase_speed, delta)
				if pos.distance_to(target) <= attack_radius:
					state = ATTACK

		ATTACK:
			if player:
				target = player.global_transform.origin
				_move_towards(target, chase_speed, delta)
				if pos.distance_to(target) > attack_radius * 1.25:
					state = CHASE
			else:
				state = WANDER

	# footsteps (cadence ~ speed)
	var v := _horiz_speed_estimate()
	if v > 0.1:
		var step_interval := 3
		step_accum += delta
		if step_accum >= step_interval:
			step_accum = 0.0
			if sfx:
				sfx.pitch_scale = clamp(0.9 + randf()*0.2, 0.85, 1.12)
				sfx.play()

func _move_towards(goal: Vector3, spd: float, delta: float) -> void:
	var dir := Vector3.ZERO
	if using_nav:
		agent.set_target_position(goal)
		var next := agent.get_next_path_position()
		dir = next - global_transform.origin
	else:
		dir = goal - global_transform.origin

	dir.y = 0.0
	var d := dir.length()
	if d > 0.001:
		dir /= d
		look_at(global_transform.origin + dir, Vector3.UP)
		global_transform.origin += dir * spd * delta

func _pick_wander() -> void:
	var off := Vector3(
		randf_range(-wander_radius, wander_radius),
		0.0,
		randf_range(-wander_radius, wander_radius)
	)
	target = home + off

func _get_player() -> Node3D:
	var n := get_tree().get_first_node_in_group("player")
	return n if n is Node3D else null

func _horiz_speed_estimate() -> float:
	# cheap estimate from current target vector
	var a: Vector3 = agent.get_next_path_position() if using_nav else target
	var b := global_transform.origin
	a.y = 0.0; b.y = 0.0
	return (a - b).length()
