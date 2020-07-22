extends Node

export var push_impulse := 15
export (float, 0, 1) var deadzone = 0.1

var pushable: PushableBox = null
var normal := Vector3.ZERO

func goes_toward_normal(vec: Vector3):
	return rad2deg(vec.angle_to(normal)) < 40

func enter_state(player: KinematicBody, extra_info):
	pushable = extra_info["pushable"]
func exit_state(player: KinematicBody, extra_info) -> bool:
	pushable = null
	normal = Vector3.ZERO
	return true

func do_state(delta: float, player: KinematicBody):
	var pushable_speed = pushable.get_linear_velocity()
	var directional = utils.v2_to_v3(player.get_oriented_directional_input())
	var distance = \
		pushable.global_transform.origin * Vector3(1, 0, 1) - player.global_transform.origin * Vector3(1, 0, 1)
	normal = (-distance).normalized()
	
	if pushable_speed.length() >= 3 \
		or pushable_speed.y >= 0.1 or \
		(directional.length() >= deadzone and goes_toward_normal(directional)) \
		or distance.length() >= 2.5:
		player.change_state($"../NormalMovement")
		return
	
	if pushable.allow_push_by(player.get_name()) and pushable_speed.length() <= 2.5:
		pushable.apply_central_impulse(directional * delta * push_impulse)

	player.move_and_slide(distance * pushable_speed.length(), Vector3.UP, true, 4, deg2rad(46), false)

func do_state_visual(delta: float, player: KinematicBody):
	var pushable_speed = pushable.get_linear_velocity()
	utils.look_at_local_with_interp(player.get_node("ModelGimbal"), pushable_speed * Vector3(1, 0, 1), delta * 5)
	
	if not globals.do_player_debug:
		player.get_node("DebugGizmo").hide()
		return
	
	utils.look_at_local(player.get_node("DebugGizmo/InertiaController"), normal * Vector3(1, 0, 1))
	var directional = utils.v2_to_v3(player.get_oriented_directional_input())
	utils.look_at_local(player.get_node("DebugGizmo/DirectionalController"), directional)
	var scale = directional.length()
	player.get_node("DebugGizmo/DirectionalController/Arrow").scale = Vector3(scale, clamp(scale, 0, 1), scale)
	

