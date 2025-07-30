extends CollectibleItem
var collected_count := 0

func on_collect():
	chathelp.on_power_cell_collected()
	Inventory.update_power_cells.emit()
	collected_count += 1
	print("🔋 Power Cell collected! Total:", collected_count)

static func use_item():
	Inventory.player.get_node("Head/Camcorder").try_to_recharge()
	chathelp.try_to_recharge()

# --- ADDED: Simple pickup log and counter ---
