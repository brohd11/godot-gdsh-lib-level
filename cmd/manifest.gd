extends RefCounted
## Preloads every level command, so exporters that follow preloads include them. GDSh.Load
## skips this file. Register the commands with load_package(<package dir>), or add this
## directory (cmd/) as a command folder.

const NAMESPACES = [preload("res://addons/_lib/gdsh_lib/level/cmd/level/level.gd")]

const COMMANDS = [
	preload("res://addons/_lib/gdsh_lib/level/cmd/level/aabb/aabb.gd"),
	preload("res://addons/_lib/gdsh_lib/level/cmd/level/level.gd"),
	preload("res://addons/_lib/gdsh_lib/level/cmd/level/probe/probe.gd"),
	preload("res://addons/_lib/gdsh_lib/level/cmd/level/scatter/scatter.gd"),
	preload("res://addons/_lib/gdsh_lib/level/cmd/level/snap/snap.gd"),
]
