extends Node

class_name utils

static func clampv(vec, size = 1):
	return vec if vec.length() <= size else vec.normalized() * size

static func is_between(val, min_val, max_val):
	return val >= min_val and val <= max_val

static func look_at_local(obj, target, up = Vector3.UP):
	if target != Vector3.ZERO:
		obj.look_at(obj.global_transform.origin + target, up)

static func look_at_local_with_interp(obj, target, time, up = Vector3.UP):
	var old_transform = obj.global_transform
	look_at_local(obj, target, up)
	obj.global_transform = old_transform.interpolate_with(obj.global_transform, time)

static func raycast_col_distance(raycast: RayCast):
	return raycast.global_transform.origin.distance_to(raycast.get_collision_point())
