extends CharacterBody3D
# Enemy AI: wander → chase → attack (no shoving), NavMesh-safe wandering,
# anti-stuck recovery, and footstep SFX.

# ── Tunables ──────────────────────────────────────────────────────────────────
@export var wander_radius: float = 10.0
@export var speed: float = 2.0
@export var chase_speed: float = 2.6
@export var detection_radius: float = 14.0
@export var attack_radius: float = 1.7
@export var stop_distance: float = 0.35
@export var gravity_strength: float = 9.8
@export var step_interval_at_speed1: float = 0.45   # seconds per step at horiz speed = 1

# ── Scene refs (names match your screenshots) ─────────────────────────────────
@onready var ap: AnimationPlayer      = $AnimationPlayer
@onready var agent: NavigationAgent3D = $NavigationAgent3D
@onready var sfx: AudioStreamPlayer3D = $AudioStreamPlayer3D

# ── State ─────────────────────────────────────────────────────────────────────
enum { WANDER, CHASE, ATTACK }
var state: int = WANDER
var home: Vector3 = Vector3.ZERO
var target: Vector3 = Vector3.ZERO
var using_nav: bool = true
var step_accum: float = 0.0

# anti-stuck bookkeeping
var _last_pos: Vector3 = Vector3.ZERO
var _stuck_time: float = 0.0
const _STUCK_MOVE_EPS: float = 0.03   # meters considered "progress"
const _STUCK_TIME: float = 0.9        # seconds before we unstick

# Layers: 1=World, 2=Player, 3=Enemy
const L_WORLD: int  = 1 << 0
const L_PLAYER: int = 1 << 1
const L_ENEMY: int  = 1 << 2

# ── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	# collide with world only (avoid pushing the player)
	collision_layer = L_ENEMY
	collision_mask  = L_WORLD

	home = global_position

	# Loop any "walk" animation if present
	var anims: PackedStringArray = ap.get_animation_list()
	for n in anims:
		var lname: String = String(n).to_lower()
		if lname.find("walk") != -1:
			var a: Animation = ap.get_animation(n)
			if a:
				a.loop_mode = Animation.LOOP_LINEAR
			ap.play(n)
			break

	# Navigation sanity check
	if agent:
		agent.target_desired_distance = stop_distance
		agent.path_max_distance = 64.0
		_set_nav_target(global_position + Vector3(0.1, 0.0, 0.1))
		await get_tree().process_frame
		var nxt: Vector3 = agent.get_next_path_position()
		using_nav = (nxt - global_position).length() > 0.001
	else:
		using_nav = false

	_pick_wander()

func _physics_process(delta: float) -> void:
	# gravity
	if not is_on_floor():
		velocity.y -= gravity_strength * delta
	else:
		velocity.y = 0.0

	var player: Node3D = _get_player()

	match state:
		WANDER:
			if _can_detect(player):
				state = CHASE
			_move_towards(target, speed, delta)
			if global_position.distance_to(target) < 0.6:
				_pick_wander()

		CHASE:
			if not _can_detect(player):
				state = WANDER
			else:
				target = player.global_position
				_move_towards(target, chase_speed, delta)
				if global_position.distance_to(target) <= attack_radius:
					state = ATTACK

		ATTACK:
			if not _can_detect(player):
				state = WANDER
			else:
				target = player.global_position
				_move_towards(target, chase_speed, delta)
				if global_position.distance_to(target) > attack_radius * 1.25:
					state = CHASE
				else:
					_do_attack(player) # hook

	move_and_slide()
	_update_footsteps(delta)

	# --- anti-stuck monitor ---
	var moved: float = (global_position - _last_pos).length()
	if moved < _STUCK_MOVE_EPS:
		_stuck_time += delta
	else:
		_stuck_time = 0.0
		_last_pos = global_position

	if _stuck_time > _STUCK_TIME:
		_unstick()

# ── Movement helpers ──────────────────────────────────────────────────────────
func _move_towards(goal: Vector3, spd: float, delta: float) -> void:
	var to_goal: Vector3 = goal - global_position
	to_goal.y = 0.0
	var dist: float = to_goal.length()

	# stop a bit early to avoid jitter/pushing
	if dist <= stop_distance:
		velocity.x = move_toward(velocity.x, 0.0, spd)
		velocity.z = move_toward(velocity.z, 0.0, spd)
		return

	var dir: Vector3 = to_goal / max(dist, 0.0001)

	if using_nav and agent:
		_set_nav_target(goal)
		var next: Vector3 = agent.get_next_path_position()
		next.y = global_position.y
		var step: Vector3 = next - global_position
		step.y = 0.0
		if step.length() > 0.001:
			dir = step.normalized()

	# face movement direction (flip if your model faces +Z)
	look_at(global_position + dir, Vector3.UP)

	# accelerate horizontally toward desired velocity
	var desired: Vector3 = dir * spd
	velocity.x = move_toward(velocity.x, desired.x, spd * 4.0 * delta)
	velocity.z = move_toward(velocity.z, desired.z, spd * 4.0 * delta)

func _set_nav_target(goal: Vector3) -> void:
	# keep navigation queries on our Y plane
	var g: Vector3 = goal
	g.y = global_position.y
	agent.set_target_position(g)

# ── AI helpers ────────────────────────────────────────────────────────────────
func _pick_wander() -> void:
	# pick random offset
	var off: Vector3 = Vector3(
		randf_range(-wander_radius, wander_radius),
		0.0,
		randf_range(-wander_radius, wander_radius)
	)
	var raw: Vector3 = home + off
	raw.y = global_position.y

	# project to NavMesh so target is reachable (prevents walking into walls)
	if using_nav and agent:
		var map_rid: RID = agent.get_navigation_map()
		var on_nav: Vector3 = NavigationServer3D.map_get_closest_point(map_rid, raw)
		target = on_nav
		_set_nav_target(target)
	else:
		target = raw

	_last_pos = global_position
	_stuck_time = 0.0

func _unstick() -> void:
	# Try a small lateral nudge along the wall; pick the better of left/right
	var right_dir: Vector3 = Vector3.FORWARD.rotated(Vector3.UP, rotation.y + PI * 0.5)
	var try1: Vector3 = global_position + right_dir * 0.6
	var try2: Vector3 = global_position - right_dir * 0.6
	try1.y = global_position.y
	try2.y = global_position.y

	if using_nav and agent:
		var map_rid: RID = agent.get_navigation_map()
		var p1: Vector3 = NavigationServer3D.map_get_closest_point(map_rid, try1)
		var p2: Vector3 = NavigationServer3D.map_get_closest_point(map_rid, try2)
		# choose the one farther from current position to get off the wall
		if p1.distance_to(global_position) > p2.distance_to(global_position):
			target = p1
		else:
			target = p2
		_set_nav_target(target)
	else:
		_pick_wander()

	_last_pos = global_position
	_stuck_time = 0.0

func _get_player() -> Node3D:
	var n: Node = get_tree().get_first_node_in_group("player")
	return n if n is Node3D else null

func _can_detect(player: Node3D) -> bool:
	return player != null and global_position.distance_to(player.global_position) <= detection_radius

func _do_attack(_player: Node3D) -> void:
	# TODO: play attack anim / apply damage with an Area3D hitbox and cooldown
	pass

# ── Footsteps ─────────────────────────────────────────────────────────────────
func _update_footsteps(delta: float) -> void:
	var horiz: float = Vector2(velocity.x, velocity.z).length()
	if horiz < 0.1:
		step_accum = 0.0
		return

	var step_interval: float = step_interval_at_speed1 / max(horiz, 0.01)
	step_accum += delta
	if step_accum >= step_interval and sfx:
		step_accum = 0.0
		sfx.pitch_scale = clamp(0.9 + randf() * 0.2, 0.85, 1.12)
		sfx.play()
