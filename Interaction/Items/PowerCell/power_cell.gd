extends CollectibleItem

func on_collect():
	Inventory.update_power_cells.emit()
	
