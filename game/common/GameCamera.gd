tool
extends Spatial

export (Array, NodePath) var lerp_targets

export var follow_speed = 2
export var rotate_speed = 6
export (float) var distance = 30 setget set_camera_distance
export (float, -90, 0) var camera_angle = -rad2deg(atan(sqrt(2))) setget set_camera_angle
var camera_size = 30

func set_camera_distance(newdist):
	distance = newdist
	recalc_camera()
func set_camera_angle(newangle):
	camera_angle = newangle
	recalc_camera()
func recalc_camera():
	# In case this is being called when not _ready()
	if not is_inside_tree(): return

	$Camera.set_rotation_degrees(Vector3(camera_angle, 0, 0))
	# Set the camera _distance_ away (basic trig).
	var y_dist = sin(deg2rad(abs(camera_angle))) * distance
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

func _physics_process(delta):
	var cam_action_left = Input.is_action_just_pressed("Camera_action_left")
	var cam_action_right = Input.is_action_just_pressed("Camera_action_right")
	var select = Input.is_action_pressed("UI_select")
	var start = Input.is_action_pressed("UI_start")
	if select and cam_action_right:
		var delay = 0.1
		if $Tween.is_active():
			$Tween.stop($Camera, "size")
			delay = 0.0

		camera_size = clamp(camera_size - 10, 10, 60)
		$Tween.interpolate_property(
			$Camera, "size", $Camera.size, camera_size, 1,
			Tween.TRANS_SINE, Tween.EASE_IN_OUT, delay)
		$Tween.start()
	elif start and cam_action_left:
		var delay = 0.1
		if $Tween.is_active():
			$Tween.stop($Camera, "size")
			delay = 0.0

		camera_size = clamp(camera_size + 10, 10, 60)
		$Tween.interpolate_property(
			$Camera, "size", $Camera.size, camera_size, 1,
			Tween.TRANS_SINE, Tween.EASE_IN_OUT, delay)
		$Tween.start()
	elif not (start or select):
		target_rot = wrapi(
			(
				target_rot +
				int(cam_action_right) -
				int(cam_action_left)
			),
			0, rotations.size())
	
	# Rotate to the arm to the right angle
	transform.basis = Basis(
		Quat(transform.basis).slerp(rotations[target_rot], delta * rotate_speed)
	)

	# And set the target (the arm origin) to the average of the position of the _lerp_targets_
	var final_target = Vector3.ZERO
	var target_count = 0
	for maybe_t in lerp_targets:
		var t = get_node_or_null(maybe_t)
		if t:
			final_target += t.get_global_transform().origin
			target_count += 1
	global_transform.origin = global_transform.origin.linear_interpolate(
			final_target / (target_count if target_count != 0 else 1),
			delta * follow_speed)
