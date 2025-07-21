extends Resource

class_name ItemResource

@export var item_name: String =""
@export var texture: CompressedTexture2D
@export var mesh: Mesh
@export var quantity: int = 0
@export var crafted_items: Array[CraftItem]
@export_multiline var description: String

var use_item_function: Callable


@export var max_stack: int = 99

static func create_new_item(item: ItemResource):
	var new_item = ItemResource.new()
	new_item.item_name = item.item_name
	new_item.texture = item.texture
	new_item.mesh = chathelp.clone_mesh(item.mesh)
	new_item.quantity = item.quantity
	new_item.use_item_function = item.use_item_function
	new_item.crafted_items = item.crafted_items
	new_item.description = item.description
	return new_item

func on_used():
	pass

signal use_item
