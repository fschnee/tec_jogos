extends RigidBody

class_name LivingBox

export var allow_push_by_p1 := true
export var allow_push_by_p2 := true
export var allow_attract_by_p1 := true
export var allow_attract_by_p2 := true

func allow_push_by(character: String):
	return {
		"P1": allow_push_by_p1,
		"P2": allow_push_by_p2,
	}.get(character, false)
	
func allow_attract_by(character: String):
	return {
		"P1": allow_attract_by_p1,
		"P2": allow_attract_by_p2,
	}.get(character, false)

func _on_AttractArea_area_entered(area):
	area.get_parent().emit_signal("stepped_into_noise_range_of_living_box", self)

func _on_AttractArea_area_exited(area):
	area.get_parent().emit_signal("stepped_out_of_noise_range_of_living_box", self)
