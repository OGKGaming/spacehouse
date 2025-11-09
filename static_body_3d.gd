extends Area3D

@export_file("*.tscn") var target_scene_path: String = "res://levels/main_level.tscn"
var _fired := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if _fired: 
		return
	if body.is_in_group("player"):
		_fired = true
		monitoring = false              # stop retrigger
		set_deferred("monitoring", false)
		get_tree().change_scene_to_file(target_scene_path)
