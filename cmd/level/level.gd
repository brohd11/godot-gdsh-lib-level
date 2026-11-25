extends "res://addons/_lib/gdsh/src/core/command_base.gd"
## `level`: level-building tools that work on any ground. Logic lives in ../../src (plain GDScript).

const _HELP = \
"Level building: place, scatter and snap nodes onto the ground, bounds, ground probing.
Ground = registered providers (ProjectSettings gdsh_lib/level/ground_providers), then providers that
sibling packages declare ([level] ground_provider in their package.cfg), then physics colliders;
override per command with --ground=physics|res://provider.gd.
Usage: level <subcommand>"


static func get_command_name() -> String:
	return "level"


static func get_self_command_data() -> Dictionary:
	return _command_data({&"help": _HELP})
