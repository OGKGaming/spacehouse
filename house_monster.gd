extends CharacterBody3D

@export var speed := 2.2
@export var chase_speed := 2.8
@export var detection_radius := 10.0
@export var attack_radius := 4.0
@export var wander_radius := 12.0
@export var step_interval_at_speed1 := 0.45
@export var flip_forward := false # set true if model faces +Z

# Robust kill checks
@export var use_planar_distance := true        # ignore Y when checking distance
@export var require_line_of_sight := true      # don’t kill through walls
@export var kill_hold_time := 0.25             # must stay within attack radius this long
var _close_timer := 0.0
var _game_over_fired := false

@onready var agent: NavigationAgent3D = $NavigationAgent3D
@onready var model: Node3D = $model_walk
@onready var anim: AnimationPlayer = $model_walk/AnimationPlayer
@onready var sfx: AudioStreamPlayer3D = $Footsteps

var home := Vector3.ZERO
var target := Vector3.ZERO
var walk_anim := ""
var step_accum := 0.0
var gravity := ProjectSettings.get_setting("physics/3d/default_gravity") as float

enum { WANDER, CHASE }
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

	# --------- STATE MACHINE ----------
	match state:
		WANDER:
			# ✅ actually move while wandering
			_move_towards(target, speed)
			if player and _dist_to_node(pos, player) <= detection_radius:
				state = CHASE
			if pos.distance_to(target) < 3.5:
				_pick_wander()

		CHASE:
			if not player:
				state = WANDER
			else:
				target = player.global_transform.origin
				_move_towards(target, chase_speed)

	# --------- KILL CHECK (works in ANY state) ----------
	if player:
		var d := _dist_to_node(global_transform.origin, player)
		if d <= attack_radius and _has_los(player):
			_close_timer += delta
		else:
			_close_timer = max(0.0, _close_timer - delta * 0.5)

		if _close_timer >= kill_hold_time:
			_trigger_game_over()

	move_and_slide()

	# footsteps cadence ~ horizontal speed
	var horiz := Vector2(velocity.x, velocity.z).length()
	if is_on_floor() and horiz > 0.1:
		var step_interval := 1.0
		step_accum += delta
		if step_accum >= step_interval:
			step_accum = 0.0
			if sfx: sfx.play()

func _move_towards(goal: Vector3, spd: float) -> void:
	agent.set_target_position(goal)
	var next := agent.get_next_path_position()
	var dir := next - global_transform.origin

	# If navmesh ends (common “after a certain point” issue), fall back to direct steering
	if not agent.is_navigation_finished() and next == Vector3.ZERO:
		dir = goal - global_transform.origin

	dir.y = 0.0
	if dir.length() > 0.001:
		dir = dir.normalized()
		var face: Vector3 = (-dir) if flip_forward else dir
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

# ----------------- HELPERS -----------------
func _dist_to_node(from_pos: Vector3, node: Node3D) -> float:
	var p := node.global_transform.origin
	if use_planar_distance:
		return Vector2(from_pos.x, from_pos.z).distance_to(Vector2(p.x, p.z))
	return from_pos.distance_to(p)

func _has_los(player: Node3D) -> bool:
	if not require_line_of_sight:
		return true
	var from := global_transform.origin + Vector3.UP * 1.6
	var to := player.global_transform.origin + Vector3.UP * 1.6
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.exclude = [self, player]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	return not hit or hit.get("collider") == player

func _trigger_game_over() -> void:
	if _game_over_fired:
		return
	_game_over_fired = true
	# change scene safely outside physics
	call_deferred("_swap_to_game_over")

func _swap_to_game_over() -> void:
	get_tree().change_scene_to_file("res://GameOver.tscn")
