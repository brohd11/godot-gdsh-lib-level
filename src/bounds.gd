@tool
extends RefCounted
## World-space bounds of node subtrees.


## Merged world AABB of the visible VisualInstance3D nodes under (and including) n.
## skip_classes: class names to ignore (e.g. a ground node whose AABB covers the whole map).
static func world_aabb(n: Node, skip_classes: PackedStringArray = PackedStringArray()) -> AABB:
	var acc := AABB()
	var first := true
	var stack := [n]
	while not stack.is_empty():
		var c: Node = stack.pop_back()
		var skip := false
		for cls in skip_classes:
			if c.is_class(cls):
				skip = true
				break
		if skip:
			continue
		if c is VisualInstance3D and c.is_visible_in_tree():
			var b: AABB = c.global_transform * c.get_aabb()
			if b.size != Vector3.ZERO:
				acc = b if first else acc.merge(b)
				first = false
		stack.append_array(c.get_children())
	return acc


## The four footprint corners and the center of an AABB, as x,z points.
static func footprint(b: AABB) -> Array[Vector2]:
	var c := b.get_center()
	return [Vector2(b.position.x, b.position.z), Vector2(b.end.x, b.position.z),
		Vector2(b.position.x, b.end.z), Vector2(b.end.x, b.end.z), Vector2(c.x, c.z)]
