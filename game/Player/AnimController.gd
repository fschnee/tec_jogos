tool
extends Node

onready var tree = $"../AnimationTree"

class_name PlayerAnimationController

export (bool) var is_jumping := false
export (bool) var is_on_air := false
export (bool) var is_pushing := false
export (bool) var is_idle := false
export (float, 0, 1) var move_speed := 0.0
