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

# Call this from PowerCell.use_item()
func try_to_recharge():
	print("⚙️  Attempting radio recharge...")
	print("🔢 Current recharge count: %d" % recharge_count)

	if recharge_count >= 5:
		print("⚠ Radio already online. Recharge attempt ignored.")
		return
	
	recharge_count += 1
	print("🔋 Power cell inserted (%d/5)" % recharge_count)
	
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
