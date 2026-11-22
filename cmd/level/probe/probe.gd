extends "res://addons/_lib/gdsh/src/core/command_base.gd"
## `level probe`: ground height/normal at points, per provider (debugging ground setup).

const _HELP = \
"Print the ground height at each x,z, which provider answered, and every provider's own answer.
Usage: level probe X,Z [X,Z...] [--ground=auto|physics|res://provider.gd[,...]] [--mask=N]"

var ground_flag := "auto"
var mask_flag := 0xFFFFFFFF


static func get_command_name() -> String:
	return "probe"


static func get_self_command_data() -> Dictionary:
	return _command_data({&"help": _HELP, &"positional_count": "min:1"})


func _get_flags() -> Dictionary:
	var o = Options.new()
	o.add_option("--ground=", {&"help": "auto | physics | provider script path(s)"})
	o.add_option("--mask=", {&"help": "physics collision mask"})
	return o.get_options()


## This package's src/ (cmd/level/<cmd>/<cmd>.gd -> package root), loaded fresh so edits apply.
func _src(file: String):
	var pkg := ProjectSettings.localize_path(get_script().resource_path).get_base_dir().get_base_dir().get_base_dir().get_base_dir()
	return ResourceLoader.load(pkg.path_join("src").path_join(file), "", ResourceLoader.CACHE_MODE_IGNORE_DEEP)


func _execute(ctx:Context):
	var NP = _src("node_paths.gd")
	var root: Node = NP.scene_root()
	if root == null:
		ctx.append_error("no scene open")
		return ExitCode.ERR
	var errs := PackedStringArray()
	var g = _src("ground.gd").make(root, ground_flag, mask_flag, errs)
	for a in positional_args:
		var xz = NP.parse_xz(a)
		if xz == null:
			errs.append("bad point %s (want x,z)" % a)
			continue
		var line := "%s,%s  ground=%.3f via %s" % [xz.x, xz.y, g.height_at(xz.x, xz.y), g.source_at(xz.x, xz.y)]
		for prov in g.providers:
			var nm: String = prov.NAME if "NAME" in prov else prov.get_script().resource_path.get_file()
			var extra: String = (" [%s]" % prov.describe(xz.x, xz.y)) if prov.has_method("describe") else ""
			line += "  |  %s=%.3f %s%s" % [nm, prov.height_at(xz.x, xz.y), str(prov.normal_at(xz.x, xz.y).snapped(Vector3.ONE * 0.01)), extra]
		ctx.append_output(line)
	for e in errs: ctx.append_error(e)
	return ExitCode.OK if errs.is_empty() else ExitCode.ERR
