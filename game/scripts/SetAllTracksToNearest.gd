tool
extends EditorScript

func _run():
	var selection = get_editor_interface().get_selection().get_selected_nodes()

	if selection.size() < 1:
		print("Select an AnimationPlayer instance")
		return
	var anim_player: AnimationPlayer = selection[0] if selection[0] is AnimationPlayer else null
	
	if not anim_player:
		print("Select an AnimationPlayer instance")
	
	for trackname in anim_player.get_animation_list():
		var track = anim_player.get_animation(trackname)
		for boneindex in track.get_track_count():
			track.track_set_interpolation_type(boneindex, Animation.INTERPOLATION_NEAREST)
			
	print(
		"Set the interpolation mode of all bones of all tracks of AnimationPlayer " 
		+ anim_player.get_name() + " to Animation.INTERPOLATION_NEAREST"
	)
