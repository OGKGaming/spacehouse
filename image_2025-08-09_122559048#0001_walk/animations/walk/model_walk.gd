extends Node3D

@onready var anim: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	anim.root_node = ".."  # point to model_walk (parent of rig)

	# Find the first animation with "walk" in its name
	var walk_anim := ""
	for name in anim.get_animation_list():
		if name.to_lower().find("walk") != -1:
			walk_anim = name
			break

	if walk_anim != "":
		# Enable looping for that animation
		var anim_data: Animation = anim.get_animation(walk_anim)
		if anim_data:
			anim_data.loop_mode = Animation.LOOP_LINEAR
		anim.play(walk_anim)
	else:
		push_error("No walk animation found!")
