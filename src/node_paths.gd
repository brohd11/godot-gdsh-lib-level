@tool
extends RefCounted
## Node paths as gdsh tree commands print them: "/scene" is the scene root (the edited scene in
## the editor, the current scene in a game), "/scene/a/b" a node in it, anything else an
## absolute SceneTree path.


static func scene_root() -> Node:
	if Engine.is_editor_hint():
		var ei = Engine.get_singleton(&"EditorInterface")
		if ei:
			return ei.get_edited_scene_root()
	var tree := Engine.get_main_loop() as SceneTree
	return tree.current_scene if tree else null


static func resolve(p: String) -> Node:
	p = p.strip_edges()
	var root := scene_root()
	if p == "/scene":
		return root
	if p.begins_with("/scene/"):
		return root.get_node_or_null(p.substr(7)) if root else null
	var tree := Engine.get_main_loop() as SceneTree
	return tree.root.get_node_or_null(p) if tree else null


static func path_of(n: Node) -> String:
	var root := scene_root()
	if n == root:
		return "/scene"
	if root and root.is_ancestor_of(n):
		return "/scene/" + str(root.get_path_to(n))
	return str(n.get_path())


## Nodes for each non-empty line of text; unresolved lines are appended to errors.
static func nodes_from_lines(text: String, errors: PackedStringArray) -> Array:
	var out := []
	for line in text.split("\n", false):
		if line.strip_edges() == "":
			continue
		var n := resolve(line)
		if n == null:
			errors.append("node not found: " + line.strip_edges())
		else:
			out.append(n)
	return out


## Parses "x,z" into a Vector2, or null.
static func parse_xz(s: String):
	var p := s.split(",")
	if p.size() != 2 or not p[0].strip_edges().is_valid_float() or not p[1].strip_edges().is_valid_float():
		return null
	return Vector2(float(p[0]), float(p[1]))
