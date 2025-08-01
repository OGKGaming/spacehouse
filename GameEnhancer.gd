extends Node
class_name GameEnhancer

# 📦 Inventory stats
var power_cells := 0

# 📡 Radio/Camcorder logic
var recharge_count := 0
signal radio_online

# 📋 UI Elements (link these at runtime or in ready)
@onready var interaction_info: Label = null
@onready var interaction_anim_player: AnimationPlayer = null

# Call this once to bind UI elements
func bind_ui(info_label: Label, anim: AnimationPlayer):
	print("🔧 Binding UI elements to GameEnhancer")
	interaction_info = info_label
	interaction_anim_player = anim

# Call this from PowerCell.on_collect()
func on_power_cell_collected():
	power_cells += 1
	print("✅ Power cell collected! Current count: %d" % power_cells)
	show_popup("Power cell collected! (%d)" % power_cells)
	try_to_recharge()
	chathelp.maybe_whisper_hint()

# Call this from PowerCell.use_item()
func try_to_recharge():
	print("⚙️  Attempting radio recharge...")
	print("🔢 Current recharge count: %d" % recharge_count)

	if recharge_count >= 5:
		print("⚠ Radio already online. Recharge attempt ignored.")
		return
	
	recharge_count += 1
	print("🔋 Power cell inserted (%d/5)" % recharge_count)
	chathelp.maybe_whisper_hint()

	
	# 💡 Simulate lights flickering
	var lights = get_tree().get_nodes_in_group("flicker_lights")
	print("🕹 Found %d lights to flicker." % lights.size())
	for light in lights:
		if light.has_method("flicker"):
			print("⚡ Flickering light: ", light.name)
			light.flicker()
		else:
			print("❌ Light '%s' has no 'flicker()' method." % light.name)

	# 🔊 Trigger radio once full
	if recharge_count == 5:
		print("📻 RADIO ONLINE! Static... then: '...hello?'")
		emit_signal("radio_online")
		show_popup("📻 Signal found...")

		var voice_path = "/root/DemoLevel/VoicePlayer"
		if has_node(voice_path):
			print("🎤 Playing voice line from: ", voice_path)
			get_node(voice_path).play()
		else:
			print("❗ VoicePlayer node not found at: ", voice_path)

# Call this from any context to trigger info animation
func show_popup(text: String):
	if not interaction_info or not interaction_anim_player:
		print("❗ UI not bound. Use bind_ui() first.")
		return
	
	print("🪧 Showing popup: ", text)

	if interaction_anim_player.is_playing():
		print("⏹ Animation already playing — restarting")
		interaction_anim_player.stop()
		interaction_info.modulate.a = 0
	
	interaction_info.text = text
	interaction_anim_player.play("Interaction Info")

# Utility: safely duplicate mesh
static func clone_mesh(mesh: Mesh) -> Mesh:
	print("🛠 Cloning mesh resource.")
	return mesh.duplicate() if mesh else null
	
	# 🔁 Reset everything (for testing, cutscene, restart)
func reset_radio():
	print("🔄 Resetting radio and power cell state.")
	power_cells = 0
	recharge_count = 0

# ✅ Returns true if radio is fully powered
func is_radio_online() -> bool:
	return recharge_count >= 5

# 📊 Returns status string like "3/5 power cells"
func get_power_cell_status() -> String:
	return "%d/5 Power Cells Inserted" % recharge_count

# 🔊 Force play the voice line (even if not fully charged)
func force_voice_playback():
	var voice_path = "/root/DemoLevel/VoicePlayer"
	if has_node(voice_path):
		print("🔊 Force playing voice line: ", voice_path)
		get_node(voice_path).play()
	else:
		print("❗ VoicePlayer node not found at: ", voice_path)

# 🧠 Print full internal status (for debugging, logs)
func log_summary():
	print("📋 --- GameEnhancer Summary ---")
	print("🔋 Power Cells: ", power_cells)
	print("🔌 Recharge Count: ", recharge_count)
	print("📡 Radio Online: ", is_radio_online())
	print("📋 UI Bound: ", interaction_info != null and interaction_anim_player != null)
	print("💡 Lights flicker group size: ", get_tree().get_nodes_in_group("flicker_lights").size())




func trigger_environmental_flicker():
	var lights = get_tree().get_nodes_in_group("flicker_lights")
	for light in lights:
		if light.has_method("flicker"):
			light.flicker()

# 💀 Handle player death logic
func kill_player():
	print("💀 Player has died from battery loss.")
	get_tree().change_scene_to_file("res://GameOver.tscn")
	
	# 💡 Quick white screen flash (simulate fear or impact)
func trigger_screen_flash(duration := 0.2):
	var flash := ColorRect.new()
	flash.color = Color(1, 1, 1, 0.8)
	flash.name = "FlashOverlay"
	flash.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flash.size_flags_vertical = Control.SIZE_EXPAND_FILL
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var tween := create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, duration)
	await tween.finished
	flash.queue_free()

# 📺 Simulate a glitchy screen effect
func trigger_screen_glitch():
	var glitch := ColorRect.new()
	glitch.color = Color(1, 0, 0, 0.15)
	glitch.name = "GlitchOverlay"
	glitch.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	glitch.size_flags_vertical = Control.SIZE_EXPAND_FILL
	glitch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glitch)
	glitch.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var tween := create_tween()
	tween.tween_property(glitch, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_SINE)
	await tween.finished
	glitch.queue_free()

	
	
	
	# 😱 Jump scare trigger with sound and screen flash
func trigger_jump_scare(scare_sound_path := "res://sounds/scream.ogg"):
	show_popup("👁 You are not alone...")
	trigger_screen_flash(0.4)
	trigger_screen_glitch()
	_play_sound(scare_sound_path)

# 👁 Creep camera or environment (random horror noise, flickers)
func ambient_horror_event():
	var creepy_sounds = [
		"res://sounds/creak.ogg",
		"res://sounds/whisper.ogg",
		"res://sounds/static.ogg"
	]
	var rand_sound = creepy_sounds[randi() % creepy_sounds.size()]
	_play_sound(rand_sound)
	trigger_environmental_flicker()
	show_popup("...did you hear that?")

# 🕳 Sink player into the floor slowly


# 🎭 Overlay hallucination mesh or visual
func hallucination_overlay(mesh_instance: MeshInstance3D):
	mesh_instance.visible = true
	var tween := create_tween()
	tween.tween_property(mesh_instance, "modulate:a", 0.8, 0.5).set_trans(Tween.TRANS_SINE)
	await get_tree().create_timer(2.0).timeout
	tween = create_tween()
	tween.tween_property(mesh_instance, "modulate:a", 0.0, 1.0).set_trans(Tween.TRANS_SINE)
	await tween.finished
	mesh_instance.visible = false

# 🦴 Stutter screen / simulate panic
func panic_effect():
	trigger_screen_flash(0.2)
	trigger_screen_glitch()
	show_popup("💀 Your heart is racing...")
	ambient_horror_event()

# 📢 Internal helper: play sound by path
func _play_sound(path: String):
	if ResourceLoader.exists(path):
		var snd := AudioStreamPlayer.new()
		snd.stream = load(path)
		add_child(snd)
		snd.play()
		snd.finished.connect(snd.queue_free)
	else:
		print("❗ Missing sound: ", path)


# 🧠 Player whisper effect when recharge_count is close to full
func maybe_whisper_hint():
	if recharge_count == 1 :  # One cell away from radio
		var whispers = [
			"...just one more...",
			"...you're close...",
			"...can you hear it?",
			"...they're listening too..."
		]
		var msg = whispers[randi() % whispers.size()]
		show_popup(msg)
		_play_sound("res://sounds/soft_whisper.ogg")  # Make sure you have this or swap path
