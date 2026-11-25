@tool
extends RefCounted
## Ground resolution for level tools. A ground is any object with
##   covers(x, z) -> bool, height_at(x, z) -> float (NAN if none), normal_at(x, z) -> Vector3
## Providers are scripts whose _init takes the scene root. They come from:
##   --ground=physics            colliders only
##   --ground=res://x.gd[,y.gd]  these providers, then physics as the fallback
##   --ground=auto (default)     the providers listed in ProjectSettings SETTING, then those that
##                               sibling packages declare, then physics
## A sibling package (beside level, wherever both are installed) declares its provider in its
## package.cfg:  [level] ground_provider="src/my_ground.gd"  (relative to that package).
## Level tools never know which addon a provider belongs to.

const SETTING := "gdsh_lib/level/ground_providers"
const SECTION := "level"
const KEY := "ground_provider"
const GroundPhysics = preload("ground_physics.gd")


## A chain of providers: the first one covering x,z answers.
class Chain extends RefCounted:
	var providers: Array = []
	var physics: GroundPhysics

	func _first(x: float, z: float):
		for p in providers:
			if p.covers(x, z):
				return p
		return null

	func covers(x: float, z: float) -> bool:
		return _first(x, z) != null

	func height_at(x: float, z: float) -> float:
		var p = _first(x, z)
		return p.height_at(x, z) if p else NAN

	func normal_at(x: float, z: float) -> Vector3:
		var p = _first(x, z)
		return p.normal_at(x, z) if p else Vector3.UP

	## Name of the provider answering at x,z.
	func source_at(x: float, z: float) -> String:
		var p = _first(x, z)
		if p == null:
			return "-"
		return p.NAME if "NAME" in p else str(p.get_script().resource_path.get_file().get_basename())

	## Excludes the node's colliders from physics hits (no-op for other providers).
	func exclude_node(node: Node) -> void:
		if physics:
			physics.exclude_node(node)

	func clear_excludes() -> void:
		if physics:
			physics.clear_excludes()


## Provider script paths that auto mode uses.
static func registered_providers() -> PackedStringArray:
	return PackedStringArray(ProjectSettings.get_setting(SETTING, PackedStringArray()))


## Provider script paths that sibling packages declare ([level] ground_provider in their
## package.cfg), by package folder name.
static func discovered_providers() -> PackedStringArray:
	var out := PackedStringArray()
	# src/ground_physics.gd -> level -> the folder level and its siblings are installed in.
	var physics_script: Script = GroundPhysics
	var level_dir := ProjectSettings.localize_path(physics_script.resource_path).get_base_dir().get_base_dir()
	if level_dir.is_empty():
		return out
	var parent := level_dir.get_base_dir()
	var dirs := Array(DirAccess.get_directories_at(parent))
	dirs.sort()
	for name: String in dirs:
		var pkg := parent.path_join(name)
		if name.begins_with(".") or pkg == level_dir:
			continue
		var cfg := ConfigFile.new()
		if cfg.load(pkg.path_join("package.cfg")) != OK:
			continue
		var rel = cfg.get_value(SECTION, KEY, "")
		if not rel is String or rel.is_empty():
			continue
		var path := pkg.path_join(rel).simplify_path()
		if path.begins_with(pkg + "/") and FileAccess.file_exists(path):
			out.append(path)
	return out


## Builds a ground for the scene. errors receives unloadable provider paths.
static func make(root: Node, spec := "auto", mask: int = 0xFFFFFFFF, errors: PackedStringArray = PackedStringArray()) -> Chain:
	var chain := Chain.new()
	var paths := PackedStringArray()
	if spec == "auto" or spec == "":
		paths = registered_providers()
		var seen := {}
		for p in paths:
			seen[ProjectSettings.localize_path(p.strip_edges())] = true
		for p in discovered_providers():
			if not seen.has(p):
				paths.append(p)
	elif spec != "physics":
		paths = spec.split(",", false)
	for p in paths:
		var s = load(p.strip_edges())
		if not s is Script:
			errors.append("ground provider not found: " + p)
			continue
		chain.providers.append(s.new(root))
	chain.physics = GroundPhysics.new(root, mask)
	chain.providers.append(chain.physics)
	return chain
