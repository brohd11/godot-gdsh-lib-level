extends "res://addons/_lib/gdsh/src/core/command_base.gd"
## `level snap`: drop stdin nodes onto the ground.

const _HELP = \
"Move each stdin node onto the ground under its X,Z (plus --offset). Undoable.
Usage: ... | level snap [--offset=0] [--lowest] [--align] [--ground=auto] [--mask=N]
  --lowest  lowest ground under the node's footprint (AABB corners + center), so wide objects don't float
  --align   tilt the node's up axis to the ground normal
  --ground  auto | physics | res://provider.gd[,...]   (the node's own colliders are ignored)
  --mask    physics layers to hit (e.g. only the ground's layer, to skip other props)"

var offset_flag := 0.0
var lowest_flag := false
var align_flag := false
var ground_flag := "auto"
var mask_flag := 0xFFFFFFFF


static func get_command_name() -> String:
	return "snap"


static func get_self_command_data() -> Dictionary:
	return _command_data({&"help": _HELP})


func _get_flags() -> Dictionary:
	var o = Options.new()
	o.add_option("--offset=", {&"help": "added to the ground height"})
	o.add_option("--lowest", {&"help": "lowest ground under the footprint"})
	o.add_option("--align", {&"help": "align up axis to the ground normal"})
	o.add_option("--ground=", {&"help": "auto | physics | provider script path(s)"})
	o.add_option("--mask=", {&"help": "physics collision mask"})
	return o.get_options()


## This package's src/ (cmd/level/<cmd>/<cmd>.gd -> package root), loaded fresh so edits apply.
func _src(file: String):
	var pkg := ProjectSettings.localize_path(get_script().resource_path).get_base_dir().get_base_dir().get_base_dir().get_base_dir()
	return ResourceLoader.load(pkg.path_join("src").path_join(file), "", ResourceLoader.CACHE_MODE_IGNORE_DEEP)


func _execute(ctx:Context):
	var NP = _src("node_paths.gd")
	var errs := PackedStringArray()
	var nodes: Array = NP.nodes_from_lines(ctx.stdin, errs)
	var root: Node = NP.scene_root()
	if root == null:
		ctx.append_error("no scene open")
		return ExitCode.ERR
	var ground = _src("ground.gd").make(root, ground_flag, mask_flag, errs)
	var res: Dictionary = _src("snap.gd").snap(nodes, ground, {offset = offset_flag, lowest = lowest_flag, align = align_flag}, EditorInterface.get_editor_undo_redo())
	errs.append_array(res.errors)
	for e in errs: ctx.append_error(e)
	for l in res.lines: ctx.append_output(l)
	return ExitCode.OK if errs.is_empty() else ExitCode.ERR
