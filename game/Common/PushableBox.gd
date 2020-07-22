extends RigidBody

class_name PushableBox

export var allow_p1 := true
export var allow_p2 := true

func allow_push_by(character: String):
	return {
		"P1": allow_p1,
		"P2": allow_p2,
	}.get(character, false)
