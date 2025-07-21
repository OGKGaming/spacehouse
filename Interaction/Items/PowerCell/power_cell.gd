extends CollectibleItem

func on_collect():
	chathelp.on_power_cell_collected()
	Inventory.update_power_cells.emit()
	
static func use_item():
	Inventory.player.get_node("Head/Camcorder").try_to_recharge()
	chathelp.try_to_recharge()
