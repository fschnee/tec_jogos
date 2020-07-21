extends KinematicBody

export (NodePath) var orientator
onready var _orientator = get_node_or_null(orientator)

onready var anim_tree := $ModelGimbal/Model/AnimationTree
onready var state = $States/Empty

func get_raw_directional_input() -> Vector2:
	return utils.clampv(Vector2(
		Input.get_action_strength(get_name() + "_up")   - Input.get_action_strength(get_name() + "_down"),
		Input.get_action_strength(get_name() + "_left") - Input.get_action_strength(get_name() + "_right")
	))

func get_oriented_directional_input() -> Vector2:
	var input = get_raw_directional_input()

	if _orientator:
		var ignore_y = Vector3(-1, 0, -1)
		var orientation = Basis(
			(_orientator.get_global_transform().basis.z * ignore_y).normalized(),
			Vector3.UP,
			(_orientator.get_global_transform().basis.x * ignore_y).normalized()
		)
		
		return utils.v3_to_v2(orientation.x * input.x + orientation.z * input.y)
	else:
		return input

func is_on_floor() -> bool:
	return .is_on_floor() or $FloorTolerance.is_colliding()

func floor_distance() -> float:
	if $FloorDistanceDetector.is_colliding():
		return utils.raycast_col_distance($FloorDistanceDetector) - 0.5
	else: return $FloorDistanceDetector.cast_to.length()

func change_state(to: Node, enter_info = null, exit_info = null) -> void:
	assert(to != null)

	var state_changed = state.exit_state(self, exit_info)
	print_debug(
		get_name() + ": " + ("SUCCEDED" if state_changed else "FAILED") + " state transition" +
		" from: " + state.get_name() + " - " + str(exit_info) +
		" to: " + to.get_name() + " - " + str(enter_info))

	if state_changed:
		to.enter_state(self, enter_info)
		state = to

func _ready():
	change_state($States/NormalMovement)

func _physics_process(delta):
	state.do_state(delta, self)

func _process(delta):
	state.do_state_visual(delta, self)
