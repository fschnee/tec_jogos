extends KinematicBody

class_name PlayerController

export (NodePath) var orientator setget set_orientator
onready var _orientator = get_node_or_null(orientator)
func set_orientator(neworientator: NodePath) -> void:
	orientator = neworientator
	_orientator = get_node_or_null(neworientator)

export (NodePath) var pull_partner setget set_pull_partner
onready var _pull_partner = get_node_or_null(pull_partner)
func set_pull_partner(newpullpartner: NodePath) -> void:
	pull_partner = newpullpartner
	_pull_partner = get_node_or_null(newpullpartner)

onready var _model_gimbal: Spatial = $ModelGimbal
onready var anims: PlayerAnimationController = $ModelGimbal/Model/AnimController
onready var state: Node = $States/Empty

signal entered_pullingarea(area)
signal exited_pullingarea(area)
signal being_pulled(area)
signal stepped_into_noise_range_of_living_box(box)
signal stepped_out_of_noise_range_of_living_box(box)

func player_name():
	return get_name()

func get_raw_directional_input() -> Vector2:
	return utils.clampv(Vector2(
		Input.get_action_strength(player_name() + "_up")   - Input.get_action_strength(player_name() + "_down"),
		Input.get_action_strength(player_name() + "_left") - Input.get_action_strength(player_name() + "_right")
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

	var state_changed = state.exit_state(exit_info)
	print_debug(
		player_name() + ": " + ("SUCCEDED" if state_changed else "FAILED") + " state transition" +
		" from: " + state.get_name() + " - " + str(exit_info) +
		" to: " + to.get_name() + " - " + str(enter_info))

	if state_changed:
		to.enter_state(enter_info)
		state = to

func _ready():
	change_state($States/NormalMovement)

func _physics_process(delta):
	state.do_state(delta)

func _process(delta):
	state.do_state_visual(delta)

func _on_Controller_being_pulled(area):
	area = area as PullingArea
	
	global_transform.origin = area.get_tp_point()
	change_state($States/NormalMovement, {"begin_pulled": true})
