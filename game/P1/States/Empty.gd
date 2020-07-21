extends Node

func enter_state(_player: KinematicBody, _extra_info):
	pass
func exit_state(_player: KinematicBody, _extra_info) -> bool:
	return true

func do_state(_delta: float, _player: KinematicBody):
	pass
func do_state_visual(_delta: float, _player: KinematicBody):
	pass
