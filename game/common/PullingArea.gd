extends Area

class_name PullingArea

func get_tp_point() -> Spatial:
	var tp_obj = get_node_or_null("telepoint")
	tp_obj = tp_obj if tp_obj else self
	return tp_obj.global_transform.origin

func _on_PullingArea_body_entered(body):
#	if not (body is PlayerController): return
#	body = body as PlayerController
	body.emit_signal("entered_pullingarea", self)

func _on_PullingArea_body_exited(body):
#	if not (body is PlayerController): return
#	body = body as PlayerController
	body.emit_signal("exited_pullingarea", self)
