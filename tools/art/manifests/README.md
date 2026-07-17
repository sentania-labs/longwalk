# Generated art manifest contract

`longwalk.generated-sheet.v1` is the blind generation contract for round 005.
Every visible asset records its prompt, style board, generator, exact grid,
magenta key, cell role, output id, and per-cell ground-contact anchor. Runtime
ids are declared as a closed set. Ingestion rejects missing provenance, wrong
dimensions or grids, edge contact, empty cells, and undeclared runtime assets.

The walk manifest uses immutable facing order `E, SE, S, SW, W, NW, N, NE`
with six frames per facing. A facing is regenerated as one unit when it fails.
Frames are never selected or replaced because one pose looks better. Mirroring
is forbidden unless declared in the manifest before generation.

Shadow masks use the shared screen-space light vector `[18, 9]`. The cast mask
starts from only the bottom footprint slice at the declared contact line.
Upper wall and roof alpha is excluded. A separate compact contact mask is
emitted for grounding on similar-valued terrain.
