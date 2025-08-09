extends ProgressBar  # or TextureProgressBar

func _ready():
	connect("value_changed", _on_value_changed)

func _on_value_changed(value: float) -> void:
	#print("ProgressBar value -> ", value)
	#print_stack()  # shows the caller file & line
	return
