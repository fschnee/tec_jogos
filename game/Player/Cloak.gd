tool
extends SoftBody

export (NodePath) var attachment = @"../Mesh/rig/Skeleton/CloakAttachment" setget set_attachment
onready var _attachment: Spatial = get_node_or_null(attachment)
func set_attachment(newattachment):
	attachment = newattachment
	_attachment = get_node_or_null(newattachment)
	config_attachment()

func config_attachment():
	for i in range(self.pinned_points.size()):
		set("attachments/" + str(i) + "/spatial_attachment_path", get_path_to(_attachment))

func _ready():
	config_attachment()
