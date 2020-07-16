tool
extends Spatial

export (Array, NodePath) var lerp_targets

export var follow_speed = 2
export var rotate_speed = 6
export var distance = 20

var target_rot = 0
var rotations = [
	Quat(Vector3.UP, deg2rad(45)),
	Quat(Vector3.UP, deg2rad(135)),
	Quat(Vector3.UP, deg2rad(225)),
	Quat(Vector3.UP, deg2rad(315)),
]

func _physics_process(delta):
	# Set the camera _distance_ away
	$Camera.set_translation(Vector3(0, distance, distance))

	# Then rotate to the arm to the right angle
	target_rot = wrapi(
		(
			target_rot +
			int(Input.is_action_just_pressed("camera_rotate_left")) -
			int(Input.is_action_just_pressed("camera_rotate_right"))
		),
		0, rotations.size())
	transform.basis = Basis(
		Quat(transform.basis).slerp(rotations[target_rot], delta * rotate_speed)
	)

	# And set the target (the arm origin) to the average of the position of the _lerp_targets_
	var final_target = Vector3.ZERO
	for t in lerp_targets:
		final_target += get_node_or_null(t).get_global_transform().origin / lerp_targets.size()
	global_transform.origin = global_transform.origin.linear_interpolate(
			final_target,
			delta * follow_speed)
