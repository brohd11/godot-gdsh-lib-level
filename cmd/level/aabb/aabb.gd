extends "res://addons/_lib/gdsh/src/core/command_base.gd"
## `level aabb`: world-space bounds of stdin nodes.

const _HELP = \
"Print the merged world AABB of the visual nodes under each stdin node.
Usage: ... | level aabb      -> path  min=(x,y,z) max=(x,y,z) size=(x,y,z) center=(x,y,z)"


static func get_command_name() -> String:
	return "aabb"


static func get_self_command_data() -> Dictionary:
	return _command_data({&"help": _HELP})


## This package's src/ (cmd/level/<cmd>/<cmd>.gd -> package root), loaded fresh so edits apply.
func _src(file: String):
	var pkg := ProjectSettings.localize_path(get_script().resource_path).get_base_dir().get_base_dir().get_base_dir().get_base_dir()
	return ResourceLoader.load(pkg.path_join("src").path_join(file), "", ResourceLoader.CACHE_MODE_IGNORE_DEEP)


func _execute(ctx:Context):
	var NP = _src("node_paths.gd")
	var Bounds = _src("bounds.gd")
	var errs := PackedStringArray()
	var nodes: Array = NP.nodes_from_lines(ctx.stdin, errs)
	for e in errs: ctx.append_error(e)
	for n in nodes:
		var b: AABB = Bounds.world_aabb(n)
		var r := func(v: Vector3): return str(v.snapped(Vector3.ONE * 0.01))
		ctx.append_output("%s  min=%s max=%s size=%s center=%s" % [NP.path_of(n), r.call(b.position), r.call(b.end), r.call(b.size), r.call(b.get_center())])
	return ExitCode.OK if errs.is_empty() else ExitCode.ERR
