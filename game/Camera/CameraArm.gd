tool
extends Spatial

export (Array, NodePath) var lerp_targets setget set_lerp_targets
var _lerp_targets: Array

func set_lerp_targets(new_lerp_targets):
	lerp_targets = new_lerp_targets
	recalc_targets()

func recalc_targets():
	_lerp_targets.clear()
	for t in lerp_targets:
		_lerp_targets.append(get_node(t))

export var follow_speed = 2
export var rotate_speed = 6
export (float) var distance = 20 setget set_camera_distance
export (float, -90, 0) var camera_angle = -45 setget set_camera_angle

func set_camera_distance(newdist):
	distance = newdist
	recalc_camera()
func set_camera_angle(newangle):
	camera_angle = newangle
	$Camera.set_rotation_degrees(Vector3(camera_angle, 0, 0))
	recalc_camera()
func recalc_camera():
	# Set the camera _distance_ away (basic trig).
	var y_dist = sin(abs($Camera.get_rotation().x)) * distance
	var z_dist = sqrt(distance * distance - y_dist * y_dist)
	$Camera.set_translation(Vector3(0, y_dist, z_dist))

var target_rot = 0
const rotations = [
	Quat(Vector3.UP, deg2rad(45)),
	Quat(Vector3.UP, deg2rad(135)),
	Quat(Vector3.UP, deg2rad(225)),
	Quat(Vector3.UP, deg2rad(315)),
]

func _ready():
	recalc_camera()
	recalc_targets()

func _physics_process(delta):
	# Rotate to the arm to the right angle
	target_rot = wrapi(
		(
			target_rot +
			int(Input.is_action_just_pressed("Cam_rotate_left")) -
			int(Input.is_action_just_pressed("Cam_rotate_right"))
		),
		0, rotations.size())
	transform.basis = Basis(
		Quat(transform.basis).slerp(rotations[target_rot], delta * rotate_speed)
	)

	# And set the target (the arm origin) to the average of the position of the _lerp_targets_
	var final_target = Vector3.ZERO
	for t in _lerp_targets:
		final_target += t.get_global_transform().origin / lerp_targets.size()
	global_transform.origin = global_transform.origin.linear_interpolate(
			final_target,
			delta * follow_speed)
