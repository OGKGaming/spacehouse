extends InteractionBase
class_name CollectibleItem

@export var item: ItemResource

func _ready():
	var script: Script = get_script()
	if script.has_method("use_item"):
		item.use_item_function = get_script().use_item
	print("🎒 Collectible ready:", item.item_name)

func interact(_parameters = null):
	if not item:
		push_warning("❗ No item assigned to CollectibleItem.")
		return
	
	print("🧲 Interacted with collectible:", item.item_name)
	Inventory.collect.emit(item)
	on_collect()
	queue_free()

func on_collect():
	print("✅ Collected:", item.item_name)
