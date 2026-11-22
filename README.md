# gdsh_lib/level

Level-building tools for Godot as gdsh commands (mcp-sh-godot bridge / Editor Console), on top of
plain GDScript modules usable from any tool script.

```
level probe X,Z...                         ground height/normal per provider (debug ground setup)
... | level snap [--lowest] [--align]      drop nodes onto the ground (undoable)
... | level scatter SCENE... [--count ...] instance scenes around a point on the ground (undoable)
... | level aabb                           world bounds of node subtrees
```

## Layout (gdsh package standard)
```
cmd/                      command root: what the shell loads (load_package registers it)
  manifest.gd             preloads every command, for export
  level/level.gd          the `level` namespace; subcommands in level/<sub>/<sub>.gd
src/                      plain GDScript, no gdsh or editor dependency, not loaded by default
```
- `src/`: `node_paths.gd`, `bounds.gd`, `ground.gd`, `ground_physics.gd`, `snap.gd`, `scatter.gd`. Undo is duck-typed (`UndoRedo` or `EditorUndoRedoManager`, or null).
- The commands are thin. They load `src/` relative to their own file, so the package can move.

## Ground
Level tools never know what the ground is. A ground provider is any script with `_init(root)` and:

```gdscript
func covers(x: float, z: float) -> bool
func height_at(x: float, z: float) -> float   # NAN when there is no ground
func normal_at(x: float, z: float) -> Vector3
```

How the ground is resolved (`src/ground.gd`), selected per command with `--ground=`:
- `auto` (the default): the providers in ProjectSettings `gdsh_lib/level/ground_providers` (script paths, tried in order), then physics.
- `physics`: colliders only. A downward ray in the scene's World3D. The node being placed is excluded, and `--mask=` limits the layers.
- `res://a.gd[,b.gd]`: those providers, then physics.

Physics works with any collider, including ground addons that build editor collision. It was checked
in the Godot 4.7 editor with Jolt. Physics rays also hit props (tree canopies, rocks), so when scattering
near other objects, use `--mask=` with the ground's layer, or register a provider for the ground.

## Status
Commands extend the neutral `res://addons/_lib/gdsh/src/core/command_base.gd`. mcp-sh-godot 0.1.6
only rebuilds commands against its own gdsh when they are outside `res://` or under `res://.mcp-sh/`.
**Until it rebuilds by registered folder (load_package), register `cmd/` by absolute path** in
`res://.mcp-sh/godot/bridge.json` `commandDirs`. `mcp_sh_godot gdsh add` stores a `res://` path, so
edit the file by hand. Then restart the bridge.
