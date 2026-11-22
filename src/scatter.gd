@tool
extends RefCounted
## Instance scenes at random spots on a ground (see ground.gd), under a parent.
## undo: an UndoRedo or EditorUndoRedoManager, or null to apply directly.

## opts: count, center (Vector2), radius, inner, min_dist, scale_min, scale_max, sink,
## max_slope (deg), seed, align (bool). Returns {nodes: Array, errors: PackedStringArray}.
static func scatter(parent: Node, owner: Node, scenes: Array, ground, opts: Dictionary, undo = null) -> Dictionary:
	var count := int(opts.get("count", 10))
	var center: Vector2 = opts.get("center", Vector2.ZERO)
	var radius := float(opts.get("radius", 20.0))
	var inner := float(opts.get("inner", 0.0))
	var min_dist := float(opts.get("min_dist", 2.0))
	var smin := float(opts.get("scale_min", 1.0))
	var smax := float(opts.get("scale_max", smin))
	var sink := float(opts.get("sink", 0.0))
	var max_slope := float(opts.get("max_slope", 90.0))
	var align := bool(opts.get("align", false))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(opts.get("seed", 0))

	var placed: Array[Vector2] = []
	for n in parent.get_children():
		if n is Node3D:
			placed.append(Vector2(n.global_position.x, n.global_position.z))
	if undo:
		undo.create_action("Scatter %d" % count)
	var made := []
	var tries := 0
	while made.size() < count and tries < count * 50:
		tries += 1
		var ang := rng.randf() * TAU
		var dist := sqrt(rng.randf_range(inner * inner, radius * radius))
		var xz := center + Vector2(cos(ang), sin(ang)) * dist
		var ok := true
		for q in placed:
			if q.distance_to(xz) < min_dist:
				ok = false
				break
		if not ok:
			continue
		var h: float = ground.height_at(xz.x, xz.y)
		if is_nan(h):
			continue
		var nrm: Vector3 = ground.normal_at(xz.x, xz.y)
		if max_slope < 90.0 and rad_to_deg(nrm.angle_to(Vector3.UP)) > max_slope:
			continue
		var inst: Node3D = scenes[rng.randi() % scenes.size()].instantiate()
		var sc := rng.randf_range(smin, smax)
		var basis := Basis(Vector3.UP, rng.randf() * TAU)
		if align:
			basis = Basis(Quaternion(Vector3.UP, nrm.normalized())) * basis
		# parent is assumed unrotated/unscaled at the origin of placement space (typical group node)
		var local := Vector3(xz.x, h - sink, xz.y)
		if parent is Node3D:
			local = (parent as Node3D).global_transform.affine_inverse() * local
		inst.transform = Transform3D(basis.scaled(Vector3.ONE * sc), local)
		if undo:
			undo.add_do_method(parent, &"add_child", inst, true)
			undo.add_do_method(inst, &"set_owner", owner)
			undo.add_do_reference(inst)
			undo.add_undo_method(parent, &"remove_child", inst)
		else:
			parent.add_child(inst, true)
			inst.owner = owner
		placed.append(xz)
		made.append(inst)
	if undo:
		undo.commit_action()
	var errors := PackedStringArray()
	if made.size() < count:
		errors.append("placed %d of %d (ran out of valid spots)" % [made.size(), count])
	return {nodes = made, errors = errors}
