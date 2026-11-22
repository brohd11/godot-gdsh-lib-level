@tool
extends RefCounted
## Drop nodes onto a ground (see ground.gd). undo: an UndoRedo or EditorUndoRedoManager, or null
## to apply directly.

const Bounds = preload("bounds.gd")


## opts: offset (float), lowest (bool: lowest ground under the AABB footprint), align (bool:
## tilt up-axis to the ground normal). Returns {lines: PackedStringArray, errors: PackedStringArray}.
static func snap(nodes: Array, ground, opts: Dictionary, undo = null) -> Dictionary:
	var lines := PackedStringArray()
	var errors := PackedStringArray()
	var offset := float(opts.get("offset", 0.0))
	var lowest := bool(opts.get("lowest", false))
	var align := bool(opts.get("align", false))
	if undo:
		undo.create_action("Snap to ground")
	for n in nodes:
		if not n is Node3D:
			errors.append("not a Node3D: " + str(n.name))
			continue
		if ground.has_method("clear_excludes"):
			ground.clear_excludes()
			ground.exclude_node(n)
		var xf: Transform3D = n.global_transform
		var p := xf.origin
		var h: float = ground.height_at(p.x, p.z)
		if lowest:
			var b := Bounds.world_aabb(n)
			if b.size != Vector3.ZERO:
				for pt in Bounds.footprint(b):
					var hh: float = ground.height_at(pt.x, pt.y)
					if not is_nan(hh):
						h = hh if is_nan(h) else minf(h, hh)
		if is_nan(h):
			errors.append("no ground under " + str(n.name))
			continue
		var nx := xf
		nx.origin = Vector3(p.x, h + offset, p.z)
		if align:
			var up: Vector3 = ground.normal_at(p.x, p.z).normalized()
			var fwd := nx.basis.z.slide(up).normalized()
			if fwd.length_squared() < 0.001:
				fwd = nx.basis.x.cross(up).normalized()
			var sc := nx.basis.get_scale()
			nx.basis = Basis(up.cross(fwd), up, fwd).scaled(sc)
		if undo:
			undo.add_do_property(n, &"global_transform", nx)
			undo.add_undo_property(n, &"global_transform", xf)
		else:
			n.global_transform = nx
		lines.append("%s y %.2f -> %.2f" % [n.name, p.y, nx.origin.y])
	if undo:
		undo.commit_action()
	if ground.has_method("clear_excludes"):
		ground.clear_excludes()
	return {lines = lines, errors = errors}
