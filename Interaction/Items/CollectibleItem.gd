extends InteractionBase
class_name CollectibleItem

@export var item: ItemResource
@export var amount: int = 1
@export var consume_on_pickup: bool = false   # true = remove node after success

func _ready():
	if not item:
		push_warning("CollectibleItem: 'item' is not set.")
		return
	# If this script defines a use function, wire it into the item (optional pattern)
	if has_method("use_item"):
		item.use_item_function = use_item
	print("🎒 Collectible ready ->", item.item_name, "x", amount)

func interact(_parameters = null) -> void:
	if not item:
		push_warning("❗ No item assigned to CollectibleItem.")
		return
	if typeof(Inventory) == TYPE_NIL:
		push_warning("❗ Inventory autoload not found.")
		return
	if not Inventory.has_method("add_item"):
		push_warning("❗ Inventory.add_item() not found.")
		return

	# Some inventories need unique resource instances per stack/slot
	var to_add: ItemResource = item.duplicate(true)

	# If your ItemResource tracks quantity internally, update it.
	if "quantity" in to_add:
		to_add.quantity = amount

	# ---- Try flexible add() signatures ----
	# Preferred: add_item(ItemResource, amount)
	var ok := false
	var res = Inventory.callv("add_item", [to_add, amount])
	if typeof(res) == TYPE_BOOL:
		ok = res
	else:
		# If your add_item returns void, assume success if no errors thrown.
		ok = true

	# Fallback: some inventories want (name, amount)
	if not ok:
		res = Inventory.callv("add_item", [to_add.item_name, amount])
		ok = (typeof(res) != TYPE_BOOL) or res

	if not ok:
		_print_and_bubble("⚠️ Could not add item to inventory.")
		return

	# Tell UI to refresh if your Inventory exposes this signal/hook
	if "update_item" in Inventory:
		Inventory.update_item.emit()

	_print_and_bubble("✅ Picked up: %s x%d" % [to_add.item_name, amount])

	if consume_on_pickup:
		queue_free()

# Optional: a local use handler if you want to wire it in _ready()
func use_item(_ctx = null) -> void:
	print("🔧 Using item:", item.item_name)

func _print_and_bubble(msg: String) -> void:
	print(msg)
	if Inventory and Inventory.has_method("display_interaction_info"):
		Inventory.display_interaction_info(msg)
