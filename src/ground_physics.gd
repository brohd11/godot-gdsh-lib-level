@tool
extends RefCounted
## Ground provider: a downward ray against colliders in the scene's World3D.
## Works on anything with collision (StaticBody meshes, CSG, ground addons that build
## editor collision). Contract shared by all ground providers (duck-typed):
##   covers(x, z) -> bool, height_at(x, z) -> float (NAN if none), normal_at(x, z) -> Vector3

const NAME := "physics"

var world: World3D
var mask: int = 0xFFFFFFFF
var top := 2000.0
var bottom := -2000.0
var _exclude: Array[RID] = []


func _init(root: Node, p_mask: int = 0xFFFFFFFF) -> void:
	world = root.get_world_3d() if root is Node3D else root.get_viewport().find_world_3d()
	mask = p_mask


## Ignore the colliders under node (e.g. the object being placed).
func exclude_node(node: Node) -> void:
	var stack := [node]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is CollisionObject3D:
			_exclude.append(n.get_rid())
		stack.append_array(n.get_children())


func clear_excludes() -> void:
	_exclude.clear()


func hit(x: float, z: float) -> Dictionary:
	if world == null:
		return {}
	var q := PhysicsRayQueryParameters3D.create(Vector3(x, top, z), Vector3(x, bottom, z), mask, _exclude)
	q.collide_with_areas = false
	q.hit_back_faces = false
	return world.direct_space_state.intersect_ray(q)


func covers(x: float, z: float) -> bool:
	return not hit(x, z).is_empty()


func height_at(x: float, z: float) -> float:
	var h := hit(x, z)
	return h.position.y if not h.is_empty() else NAN


func normal_at(x: float, z: float) -> Vector3:
	var h := hit(x, z)
	return h.normal if not h.is_empty() else Vector3.UP


## What was hit, for diagnostics.
func describe(x: float, z: float) -> String:
	var h := hit(x, z)
	if h.is_empty():
		return "-"
	var c = h.get("collider")
	return str(c.name) if c is Node else str(c)
