extends "res://addons/_lib/gdsh/src/core/command_base.gd"
## `level scatter`: instance scenes at random spots on the ground, under the stdin node.

const _HELP = \
"Instance scenes at random positions in a ring around --center, on the ground, with random yaw and
scale, under the (single) stdin node. Several scenes are picked from at random. Prints the new
node paths. Undoable.
Usage: ... | level scatter SCENE [SCENE...] [--count=10] [--center=x,z] [--radius=20] [--inner=0]
           [--min-dist=2] [--scale=min,max] [--sink=0] [--max-slope=90] [--seed=0] [--align]
           [--ground=auto] [--mask=N]
  --inner      keep this far from the center (an exclusion zone, e.g. around a building)
  --min-dist   minimum spacing between instances (existing children of the parent count too)
  --sink       lower each instance by this much (bury trunks / bases)
  --max-slope  skip spots steeper than this, in degrees
  --mask       physics layers to land on; physics ground also hits props, so restrict it to the
               ground's layer when scattering near other objects"

var count_flag := 10
var center_flag := "0,0"
var radius_flag := 20.0
var inner_flag := 0.0
var min_dist_flag := 2.0
var scale_flag := "1,1"
var sink_flag := 0.0
var max_slope_flag := 90.0
var seed_flag := 0
var align_flag := false
var ground_flag := "auto"
var mask_flag := 0xFFFFFFFF


static func get_command_name() -> String:
	return "scatter"


static func get_self_command_data() -> Dictionary:
	return _command_data({&"help": _HELP, &"positional_count": "min:1", &"allow_positional_paths": true})


func _get_flags() -> Dictionary:
	var o = Options.new()
	for f in ["--count=", "--center=", "--radius=", "--inner=", "--min-dist=", "--scale=", "--sink=", "--max-slope=", "--seed=", "--ground=", "--mask="]:
		o.add_option(f, {&"help": f.trim_prefix("--").trim_suffix("=")})
	o.add_option("--align", {&"help": "align to the ground normal"})
	return o.get_options()


## This package's src/ (cmd/level/<cmd>/<cmd>.gd -> package root), loaded fresh so edits apply.
func _src(file: String):
	var pkg := ProjectSettings.localize_path(get_script().resource_path).get_base_dir().get_base_dir().get_base_dir().get_base_dir()
	return ResourceLoader.load(pkg.path_join("src").path_join(file), "", ResourceLoader.CACHE_MODE_IGNORE_DEEP)


func _execute(ctx:Context):
	var NP = _src("node_paths.gd")
	var errs := PackedStringArray()
	var parents: Array = NP.nodes_from_lines(ctx.stdin, errs)
	if parents.size() != 1:
		ctx.append_error("pipe exactly one parent node, e.g. echo /scene/Props | level scatter ...")
		return ExitCode.ERR
	var root: Node = NP.scene_root()
	var center = NP.parse_xz(center_flag)
	if center == null:
		ctx.append_error("--center needs x,z")
		return ExitCode.ERR
	var scenes := []
	for p in positional_args:
		var ps = load(p)
		if not ps is PackedScene:
			ctx.append_error("not a scene: " + p)
			return ExitCode.ERR
		scenes.append(ps)
	var s := scale_flag.split(",")
	var ground = _src("ground.gd").make(root, ground_flag, mask_flag, errs)
	var res: Dictionary = _src("scatter.gd").scatter(parents[0], root, scenes, ground, {
		count = count_flag, center = center, radius = radius_flag, inner = inner_flag, min_dist = min_dist_flag,
		scale_min = float(s[0]), scale_max = float(s[1]) if s.size() > 1 else float(s[0]),
		sink = sink_flag, max_slope = max_slope_flag, seed = seed_flag, align = align_flag,
	}, EditorInterface.get_editor_undo_redo())
	errs.append_array(res.errors)
	for n in res.nodes: ctx.append_output(NP.path_of(n))
	for e in errs: ctx.append_error(e)
	return ExitCode.OK if errs.is_empty() else ExitCode.ERR
