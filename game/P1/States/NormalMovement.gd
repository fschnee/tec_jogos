extends Node

var inertia := Vector3.ZERO
var last_inertia := Vector3.ZERO
var last_transform := Transform()

var air_time := 0.0
var discounted_air_time := 0.0

# Impulse forces
export var gravity := 9.8
export var friction := 3.6
export var speed := 30.0
export var jump_impulse := 1000.0

# Gameplay altering variables
export (float, 0, 0.5) var coyote_time = 0.2
## Max amount of time where holding the jump button adds force (in seconds)
export var max_jump_time := 0.2
var was_jumping_last_frame = false
var jump_time := 0.0

func enter_state(_player: KinematicBody, _extra_info):
	pass
func exit_state(_player: KinematicBody, _extra_info) -> bool:
	inertia = Vector3.ZERO
	last_inertia = Vector3.ZERO
	last_transform = Transform()
	air_time = 0.0
	discounted_air_time = 0.0
	was_jumping_last_frame = false
	jump_time = 0.0
	return true

func get_gravity_impulse():
	# Gravity gets stronger the longer the jump (so jumps feel sharper) and there's
	# also a short buffer of coyote time.
	# We don't need to multiply by delta since we're already relating 
	# it to time via _air_time_ 
	return Vector3.DOWN * gravity * clamp(air_time - discounted_air_time, 0, INF) / 2

func get_pushable_collision(player: KinematicBody):
	for i in player.get_slide_count():
		var col = player.get_slide_collision(i)
		if col and col.collider.is_in_group("Pushable"):
			return col
	return null

func snap_to_ground(_player: KinematicBody):
	pass
#	var floor_dist = player.floor_distance()
#	if floor_dist >= 0.4 and floor_dist <= 0.6 and not was_jumping_last_frame:
#		player.move_and_collide(Vector3(0, -floor_dist, 0), false)

func do_state(delta: float, player: KinematicBody):
	air_time = 0.0 if player.is_on_floor() else air_time + delta
	discounted_air_time = 0.0 if player.is_on_floor() else discounted_air_time
	jump_time = 0.0 if player.is_on_floor() else jump_time
	snap_to_ground(player)

	var impulse = utils.v2_to_v3(player.get_oriented_directional_input()) + get_gravity_impulse()
	if Input.is_action_pressed(player.get_name() + "_jump") and \
		(player.is_on_floor() or was_jumping_last_frame or air_time <= coyote_time) and \
		jump_time < max_jump_time:
		discounted_air_time = air_time
		was_jumping_last_frame = true
		impulse.y += jump_impulse * delta * clamp(max_jump_time - jump_time, 0, INF)
		jump_time += delta
	else: 
		was_jumping_last_frame = false

	if inertia.length() + impulse.length() >= 0.1:
		inertia = player.move_and_slide(
			impulse * delta * speed + inertia,
			Vector3.UP,
			true, 4, deg2rad(46), false
		) * (1 - friction * delta)
		
		if player.is_on_floor():
			var col = get_pushable_collision(player)
			# col.normal.y >= 0 means the player is somewhere above the middle of 
			# (the y axis of) the pushable since the player's origin is at the feet 
			# and the pushable's origin is at it's center of mass.
			# Also only allow changing the state if the player is actually trying
			# to move against a pushable and not being pushed into one.
			if col and col.normal.y < 0.2 and rad2deg((impulse + inertia).angle_to(-col.normal)) <= 90:
				player.change_state($"../AgainstPushable", {"pushable": col.collider})

func do_state_visual(delta: float, player: KinematicBody):
	# Update the model to look at the inertia vector
	if inertia and inertia != last_inertia:
		utils.look_at_local_with_interp(player.get_node("ModelGimbal"), inertia * Vector3(1, 0, 1), delta * 5)

	var travel = (player.global_transform.origin - last_transform.origin).length()
	player.anim_tree.set("parameters/run_speed/blend_position", travel * 9)
	# And rotate the model towards the translation
	#var lerped_rot = $ModelGimbal/Model.get_rotation().linear_interpolate(translation * Vector3(1, 0, 0), delta * 5)
	#$ModelGimbal/Model.set_rotation(lerped_rot)
	
	if not globals.do_player_debug:
		player.get_node("DebugGizmo").hide()
		return
	player.get_node("DebugGizmo").show()
	
	if inertia and inertia != last_inertia:
		utils.look_at_local(player.get_node("DebugGizmo/InertiaController"), inertia * Vector3(1, 0, 1))
	var directional = utils.v2_to_v3(player.get_oriented_directional_input())
	utils.look_at_local(player.get_node("DebugGizmo/DirectionalController"), directional)
	var scale = directional.length()
	player.get_node("DebugGizmo/DirectionalController/Arrow").scale = Vector3(scale, clamp(scale, 0, 1), scale)
	
	last_inertia = inertia
	last_transform = player.global_transform
