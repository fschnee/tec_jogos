extends Node

var inertia := Vector3.ZERO
var last_inertia := Vector3.ZERO
var last_transform := Transform()

var air_time := 0.0
var discounted_air_time := 0.0
var player_was_jumping = false
var jump_time := 0.0

# Impulse forces
export var gravity := 9.8 * 44
export var friction := 3.6
export var speed := 30.0
export var jump_speed := 120.0

# Gameplay altering variables
export (float, 0, 0.5) var coyote_time = 0.2
## Max amount of time where holding the jump button adds force (in seconds)
export var max_jump_time := 1.0/12.0

func enter_state(_player: KinematicBody, _extra_info):
	pass
func exit_state(_player: KinematicBody, _extra_info) -> bool:
	inertia = Vector3.ZERO
	last_inertia = Vector3.ZERO
	last_transform = Transform()
	air_time = 0.0
	discounted_air_time = 0.0
	player_was_jumping = false
	jump_time = 0.0
	return true

func get_gravity_impulse(delta):
	# Gravity gets stronger the longer the player is on air
	return Vector3.DOWN * gravity * clamp(air_time - discounted_air_time, 0, INF) * delta

func get_pushable_collision(player: KinematicBody):
	for i in player.get_slide_count():
		var col = player.get_slide_collision(i)
		if col and col.collider is PushableBox:
			return col
	return null

func can_jump(player: KinematicBody):
	var can_begin_jump = \
		air_time <= coyote_time and not player_was_jumping
	var can_continue_jump = \
		player_was_jumping and jump_time <= max_jump_time and not player.is_on_floor()
	return can_begin_jump or can_continue_jump

func get_jump_impulse(delta, player: KinematicBody, direction: Vector2):
	var ret = Vector3.ZERO
	if Input.is_action_pressed(player.get_name() + "_jump") and can_jump(player):
		var jump_completion = jump_time / max_jump_time
		# We don't need to multiply by delta since we're already relating 
		# it to time via jump_completion.
		# (1 - jump_completion) means the jump gets weaker as it gets
		# closer to it`s max time.
		ret.y += jump_speed * (1 - jump_completion) * delta
		# Boost the player a little in the direction of the jump
		if jump_time <= 0.03 :
			ret += utils.v2_to_v3(direction) * jump_speed * delta * (1 - jump_completion) / 3
		
		discounted_air_time = air_time
		player_was_jumping = true
		jump_time += delta
	else:
		player_was_jumping = false
	
	return ret

func snap_to_ground(_player: KinematicBody):
	pass
#	var floor_dist = player.floor_distance()
#	if floor_dist >= 0.4 and floor_dist <= 0.6 and not player_was_jumping:
#		player.move_and_collide(Vector3(0, -floor_dist, 0), false)

func do_state(delta: float, player: KinematicBody):
	air_time = 0.0 if player.is_on_floor() else air_time + delta
	discounted_air_time = 0.0 if player.is_on_floor() else discounted_air_time
	jump_time = 0.0 if player.is_on_floor() else jump_time
	snap_to_ground(player)
	
	var directional_impulse = player.get_oriented_directional_input()
	var jump_impulse = get_jump_impulse(delta, player, directional_impulse)
	# gravity_impulse must come after jump_impulse since it sets discounted_air_time
	var gravity_impulse = get_gravity_impulse(delta)
	var total_impulse = \
		utils.v2_to_v3(directional_impulse * delta * speed) + gravity_impulse + jump_impulse
	if inertia.length() + total_impulse.length() >= 0.1:
		inertia = player.move_and_slide(
			total_impulse + inertia,
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
			if col and col.normal.y < 0.2 and rad2deg(inertia.angle_to(-col.normal)) <= 90:
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
	else:
		player.get_node("DebugGizmo").show()
	
		if inertia and inertia != last_inertia:
			utils.look_at_local(player.get_node("DebugGizmo/InertiaController"), inertia * Vector3(1, 0, 1))
		var directional = utils.v2_to_v3(player.get_oriented_directional_input())
		utils.look_at_local(player.get_node("DebugGizmo/DirectionalController"), directional)
		var scale = directional.length()
		player.get_node("DebugGizmo/DirectionalController/Arrow").scale = Vector3(scale, clamp(scale, 0, 1), scale)
	
	last_inertia = inertia
	last_transform = player.global_transform
