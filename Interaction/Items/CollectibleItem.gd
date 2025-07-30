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
# --- ADDED: Creative flavor reaction on collect ---

	var reactions = {
		"Power Cell": "⚡ Juice secured. Let's keep the lights on.",
		"Keycard": "🔑 Access... maybe.",
		"Old Coin": "🪙 Feels cursed. Probably is.",
		"Bandaid": "🩹 It won't stop the bleeding, but it'll help.",
		"": "📦 It's... something. Hopefully useful."
	}

	var msg = reactions.get(item.item_name, "📦 Picked up: " + item.item_name)
	print(msg)
