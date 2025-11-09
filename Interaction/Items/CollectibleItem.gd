extends InteractionBase
class_name CollectibleItem

@export var item: ItemResource
@export var amount: int = 1
@export var consume_on_pickup: bool = true  # remove node after successful pickup

func _ready() -> void:
	if not item:
		push_warning("CollectibleItem: 'item' is not set.")
		return
	if has_method("use_item"):
		item.use_item_function = use_item
	print("🎒 Collectible ready -> %s x%d" % [item.item_name, amount])

func interact(_parameters: Variant = null) -> void:
	if not item:
		push_warning("❗ No item assigned to CollectibleItem.")
		return

	# Give Inventory its own copy of the resource
	var to_emit: ItemResource = item.duplicate(true)

	# Set quantity if that property exists on the resource
	if _has_property(to_emit, "quantity"):
		to_emit.set("quantity", amount)

	# Your Inventory is wired: collect.connect(add_item)
	if Inventory.has_signal("collect"):
		Inventory.collect.emit(to_emit)
	else:
		push_warning("❗ Inventory.collect signal not found.")
		return

	# Optional UI ping (your Inventory exposes this helper)
	if Inventory.has_method("display_interaction_info"):
		Inventory.display_interaction_info("✅ Picked up: %s x%d" % [to_emit.item_name, amount])

	if consume_on_pickup:
		queue_free()

func use_item(_ctx: Variant = null) -> void:
	print("🔧 Using item:", item.item_name)

# ---- Helpers ----
func _has_property(obj: Object, prop_name: String) -> bool:
	for p in obj.get_property_list():
		# each p is a Dictionary with key "
		if p.has("name") and p["name"] == prop_name:
			return true
	return false
