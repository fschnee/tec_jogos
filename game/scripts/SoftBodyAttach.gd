tool
extends EditorScript

# Attach all pinned_points of SoftBody (selection 1) to a BoneAttachment (selection 2)
func _run():
	var selections = get_editor_interface().get_selection().get_selected_nodes()
	if selections.size() < 2: 
		print("Select the BoneAttachment and the SoftBody")
		return

	var s0 = selections[0]
	var s1 = selections[1]
	var attachment: Spatial = \
		s0 if s0 is Spatial else (s1 if s1 is Spatial else null)
	var softbody: SoftBody = \
		s1 if s1 is SoftBody else (s0 if s0 is SoftBody else null)

	if not (attachment and softbody) or not attachment.is_inside_tree(): 
		print("Select the BoneAttachment and the SoftBody")
		return
	
	for i in range(softbody.pinned_points.size()):
		softbody.set("attachments/" + str(i) + "/spatial_attachment_path", softbody.get_path_to(attachment))
		# If we reset the offsets all points will be moved to the attachment point
		# and that may or may not be what you want.
		#softbody.set("attachments/" + str(i) + "/offset", Vector3.ZERO)
	print(
		"Attached all the SoftBody's (" + softbody.get_name() + 
		") pinned points to the Spatial (" + attachment.get_name() +
		") as " + softbody.get_path_to(attachment)
	)
