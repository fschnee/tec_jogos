extends KinematicBody

export (NodePath) var orientator

onready var anim_tree := $ModelGimbal/Model/AnimationTree

var inertia := Vector3.ZERO
var last_inertia := Vector3.ZERO
var last_transform := Transform()

var total_air_time := 0.0
var current_push_area :Area = null

# Impulse forces
export var gravity := 50.0
export var push_force := 1.3
export var friction := 3.6
export var speed := 25.0

# Gameplay altering variables
export (float, 0, 0.5) var coyote_time = 0.1

func get_directional_input() -> Vector2:
	return utils.clampv(Vector2(
		Input.get_action_strength(get_name() + "_up")   - Input.get_action_strength(get_name() + "_down"),
		Input.get_action_strength(get_name() + "_left") - Input.get_action_strength(get_name() + "_right")
	))

# Also orients the input relative to the orientator if it set
func get_directional_input_impulse() -> Vector3:
	var input = get_directional_input()

	var orientator_node = get_node_or_null(orientator)
	if orientator_node:
		var ignore_y = Vector3.FORWARD + Vector3.LEFT
		var orientation = Basis(
			(orientator_node.get_global_transform().basis.z * ignore_y).normalized(),
			Vector3.UP,
			(orientator_node.get_global_transform().basis.x * ignore_y).normalized()
		)
		
		return orientation.x * input.x + orientation.z * input.y
	else:
		return Vector3(input.x, 0, input.y)

func is_on_floor() -> bool:
	return .is_on_floor() or $FloorTolerance.is_colliding() 

func get_gravity_impulse(delta):
	# Gravity gets stronger the longer the jump (so jumps feel sharper) and there's
	# also a short buffer of coyote time.
	return Vector3.UP * (
		0 if is_on_floor() \
		else -gravity * delta * clamp(total_air_time - coyote_time, 0, INF) / 30)

func can_begin_jump():
	return total_air_time < coyote_time
	
func move_normally(delta, impulse):
	if inertia.length() + impulse.length() >= 0.1:
		inertia = move_and_slide(
			impulse * delta * speed + inertia,
			Vector3.UP,
			true, 16, deg2rad(46), false
		) * (1 - friction * delta)

func can_push():
	return total_air_time == 0 and current_push_area != null
func collides_with_pushable(col: KinematicCollision) -> bool:
	return col and col.collider.get_node_or_null("PushArea")
func move_pushing_pushable(_delta, impulse):
	if !can_push(): return false

	var col = move_and_collide(impulse, false, true, true)
	if collides_with_pushable(col) and rad2deg((-col.normal).angle_to(impulse)) < 90:
		inertia = -col.normal
		
		if push_force >= col.collider.minimum_push_force:
			var force = impulse / col.collider.weight * push_force
			col.collider.apply_central_impulse(force)
			var _col = move_and_collide( # Supress unused value warning
				force,
				false)
		
		return true
	return false

func can_whistle():
	return true

func _process(delta):
	update_visuals(delta)
	last_inertia = inertia
	last_transform = global_transform

func update_visuals(delta):
	# Update the model to look at the inertia vector
	if inertia and inertia != last_inertia:
		utils.look_at_local_with_interp($ModelGimbal, inertia * Vector3(1, 0, 1), delta * 5)

	var travel = (global_transform.origin - last_transform.origin).length()
	anim_tree.set("parameters/run_speed/blend_position", travel * 9)
	# And rotate the model towards the translation
	#var lerped_rot = $ModelGimbal/Model.get_rotation().linear_interpolate(translation * Vector3(1, 0, 0), delta * 5)
	#$ModelGimbal/Model.set_rotation(lerped_rot)
	
	if not globals.do_player_debug:
		$DebugGizmo.hide()
		return
	$DebugGizmo.show()
	
	if inertia and inertia != last_inertia:
		utils.look_at_local($DebugGizmo/InertiaController, inertia * Vector3(1, 0, 1))
	var directional = get_directional_input_impulse()
	utils.look_at_local($DebugGizmo/DirectionalController, directional)
	var scale = directional.length()
	$DebugGizmo/DirectionalController/Arrow.scale = Vector3(scale, clamp(scale, 0, 1), scale)

func _physics_process(delta):
	total_air_time = 0 if is_on_floor() else total_air_time + delta
	#snap_to_ground()

	var impulse = get_directional_input_impulse()

	if not move_pushing_pushable(delta, impulse):
		move_normally(delta, impulse + get_gravity_impulse(delta))

func _on_PushArea_area_entered(area):
	current_push_area = area
func _on_PushArea_area_exited(_area):
	current_push_area = null
