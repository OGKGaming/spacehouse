extends Camera3D

@onready var light : SpotLight3D = $SpotLight3D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var rec_animation: AnimationPlayer = $RecordingIconAnimation
@onready var batteries_label :Label = $UIContainer/EnergyContainer/FlowContainer/BatteriesLabel
@onready var rec_time_label: Label = $UIContainer/RecordingContainer/FlowContainer/MarginContainer/RecordingTimeLabel
@onready var ui_container: Control = $UIContainer
@onready var timer: Timer = $Timer
@onready var zoom_label: Label = $UIContainer/RecordingContainer/ZoomLabel
@onready var night_vision_mesh: MeshInstance3D = $NightVisionMesh


@onready var camera = $PlayerController/Camera3D

# --- ADDED: Dynamic UI flicker effect when power is low ---
var flicker_timer := 0.0
var flicker_interval := 0.25
var ui_flicker_active := false
var low_power_threshold := 1
var bob_timer := 0.0
var bob_speed := 8.0
var bob_amount := 0.05
var elapsed_time = 0
var material: Material

@export var normal_speed = 1
@export var reduced_speed = .3
@export var min_fov = 1
@export var max_fov = 75
@export var zoom_sensibiity = 1
@export var max_zoom_rate = 2 

var last_fov = 0

enum CAM_MODES {
	NIGHT_VISION_ON,
	NIGHT_VISION_OFF,
	POWER_OFF
}
var current_mode: CAM_MODES
var last_mode: CAM_MODES
var startup_grace_period := false

func _ready():
	# Wait half a second before allowing game over
	await get_tree().create_timer(0.5).timeout
	startup_grace_period = false
	animation_player.animation_finished.connect(_on_energy_drain_finished)


	material = night_vision_mesh.get_active_material(0)
	rec_animation.play("Rec Icon Animation")
	update_power_cells({"item_name": "Power Cell"})
	Inventory.add_new_item.connect(update_power_cells)
	Inventory.update_item.connect(update_power_cells)
	animation_player.play("Decrease Energy")
	set_nightvision_mode(CAM_MODES.NIGHT_VISION_ON)
	fov = max_fov
	last_fov = fov
	print("📷 Camcorder ready. Initial mode: NIGHT_VISION_ON")

func set_nightvision_mode(mode: CAM_MODES):
	print("🎛 Switching camera mode to: ", mode)

	if mode == CAM_MODES.NIGHT_VISION_ON:
		print("🟢 Night vision enabled.")
		light.visible = true
		ui_container.visible = true
		animation_player.speed_scale = normal_speed
		material.set_shader_parameter("ENABLE_NIGHT_VISION", true)
		material.set_shader_parameter("ENABLE_NOISE", true)

	elif mode == CAM_MODES.NIGHT_VISION_OFF:
		print("🕶 Night vision disabled.")
		light.visible = false
		ui_container.visible = true
		animation_player.speed_scale = reduced_speed
		material.set_shader_parameter("ENABLE_NIGHT_VISION", true)
		material.set_shader_parameter("ENABLE_NOISE", true)

	elif  mode == CAM_MODES.POWER_OFF:
		print("🔌 Camera powered off.")
		light.visible = false
		animation_player.speed_scale = 0
		ui_container.visible = false
		last_fov = fov
		fov = max_fov
		timer.stop()
		material.set_shader_parameter("ENABLE_NIGHT_VISION", false)
		material.set_shader_parameter("ENABLE_NOISE", false)
		
	current_mode = mode
		
func _input(event):
	if event.is_action_pressed("ToggleCamcorder"):
		print("🎛 Toggling camcorder power.")
		if current_mode == CAM_MODES.POWER_OFF:
			set_nightvision_mode(last_mode)
			timer.start()
			fov = last_fov
		else:
			last_mode = current_mode
			set_nightvision_mode(CAM_MODES.POWER_OFF)
		return
	
	if current_mode != CAM_MODES.POWER_OFF:	
		if event.is_action_pressed("ToggleLight"):
			print("💡 Toggling light...")
			if current_mode == CAM_MODES.NIGHT_VISION_ON:
				if animation_player.current_animation_position == animation_player.current_animation_length:
					print("⚡ Power drained. Attempting recharge.")
					try_to_recharge()
					return
				set_nightvision_mode(CAM_MODES.NIGHT_VISION_OFF)
				return
			if not animation_player.assigned_animation:
				try_to_recharge()
				return
			if animation_player.current_animation_position == animation_player.current_animation_length:
				print("⚠ Energy depleted. Recharge needed.")
				try_to_recharge()
			else:
				set_nightvision_mode(CAM_MODES.NIGHT_VISION_ON)

		if event is InputEventMouseButton:
			var new_fov = fov
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				new_fov -= zoom_sensibiity
				if new_fov < min_fov:
					new_fov = min_fov
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				new_fov += zoom_sensibiity
				if new_fov > max_fov:
					new_fov = max_fov
			if new_fov != fov:
				fov = new_fov
				var max_abs_difference = abs(min_fov - max_fov)
				var current_abs_difference = abs(new_fov - max_fov)
				var zoom_value = (max_abs_difference + current_abs_difference * (max_zoom_rate - 1)) / max_abs_difference 
				update_zoom_label(zoom_value)
				print("🔍 Zoom changed: %.2f" % zoom_value)

func update_zoom_label(new_zoom: float):
	zoom_label.text = "%.2f X" % new_zoom
		
func update_power_cells(item):
	if item.item_name != "Power Cell":
		return
	var power_cells = Inventory.get_item("Power Cell")
	var quantity = 0
	if power_cells:
		quantity = power_cells.quantity	
	print("🔋 Battery UI updated. Power Cells: %d" % quantity)
	batteries_label.text = str(quantity) + "/" + str(8)
	

func try_to_recharge():
	var power_cells = Inventory.get_item("Power Cell")
	if power_cells and power_cells.quantity > 0:	
		print("🔌 Consuming 1 power cell to recharge.")
		Inventory.remove_item(power_cells.item_name, 1)
		animation_player.stop()
		animation_player.play("Decrease Energy")
	else:
		print("❌ No power cells available for recharge.")
		if not startup_grace_period:
			print("💀 Triggering game over scene...")
			get_tree().change_scene_to_file("res://GameOver.tscn")

func format_elapsed_time(_elapsed_time: int) -> String:
	var hours = _elapsed_time / 3600.0
	var minutes = (_elapsed_time % 3600) / 60.0
	var seconds: int = _elapsed_time % 60
	var formatted_hours: String = str(int(hours)).pad_zeros(2)
	var formatted_minutes: String = str(int(minutes)).pad_zeros(2)
	var formatted_seconds: String = str(seconds).pad_zeros(2)
	return formatted_hours + ":" + formatted_minutes + ":" + formatted_seconds

func _on_timer_timeout():
	elapsed_time += 1
	var elapsed_str = format_elapsed_time(elapsed_time)
	rec_time_label.text = elapsed_str
	#print("⏱️ Recording time updated: ", elapsed_str)
	
func _on_energy_drain_finished(anim_name: String):
	if anim_name == "Decrease Energy":
		print("⚠️ Energy depleted from animation. Checking for recharge...")
		try_to_recharge()




func _process(delta):
	if current_mode == CAM_MODES.POWER_OFF:
		return

	var power_cells = Inventory.get_item("Power Cell")
	var quantity = power_cells.quantity if power_cells else 0

	if quantity <= low_power_threshold:
		ui_flicker_active = true
	else:
		ui_flicker_active = false
		ui_container.modulate = Color(1, 1, 1, 1)  # reset to normal

	if ui_flicker_active:
		flicker_timer += delta
		if flicker_timer >= flicker_interval:
			flicker_timer = 0
			var flicker_alpha = randf_range(0.4, 1.0)
			ui_container.modulate = Color(1, 1, 1, flicker_alpha)
