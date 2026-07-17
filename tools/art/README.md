# tools/art, AI art generation pipeline

## Isometric board-led pipeline

Round 005 uses manifests under `manifests/`. Generate a dressed style board
first, then compact same-geometry category sheets, individual buildings, a
neutral player master, and one compact six-frame grid per immutable facing.
Run `ingest_generated_sheet.py` before `process_assets.py`. Ingestion rejects
missing provenance, malformed grids, empty cells, edge contact, bad anchors,
and undeclared runtime ids. Processing normalizes only by declared anchors and
derives footprint-only cast masks plus tight contact masks under one fixed light
vector. It never chooses frames.

The fixed facing order is `E, SE, S, SW, W, NW, N, NE`. The full policy,
including the exact sector boundary rule and distance-driven cycle contract,
lives in `manifests/player-walk-policy.json`.

All longwalk game art is AI-generated, not downloaded from asset packs. This
directory is the source of truth for regenerating or extending it: prompts
and style config are committed, not just the output images, so any asset can
be regenerated or iterated on.

## How it works

- `style.md`: the shared house style, prepended to every asset prompt.
  Perspective, lighting, palette, and "what not to do" rules that every
  asset must follow so the set reads as one consistent game, not a
  collection of unrelated renders. Edit this file when the house style
  changes.
- `prompts/<asset-name>.md`: one prompt per asset, following the labeled
  spec schema (`Use case`, `Asset type`, `Primary request`, `Subject`,
  `Style/medium`, and so on). This is the same schema pattern used
  elsewhere for this workspace owner's codex-driven art generation.
- `generate.sh <prompt-file> <output-name.png>`: generates one asset and
  writes it to `out/<output-name.png>`.
- `out/`: committed generated output.

## Generating an asset

Requires the `codex` CLI installed and authenticated (`codex login`; this
pipeline uses codex's built-in `image_gen` tool, no separate API key
wiring).

```
tools/art/generate.sh tools/art/prompts/ground_path_tile.md ground_path_tile.png
```

To add a new asset, write a new prompt file under `prompts/` following the
schema in the existing ones, then run `generate.sh` against it. Re-running
against an existing prompt file (after editing `style.md` or the prompt
itself) regenerates that asset; overwrite the file in `out/` with the new
result once you are happy with it.

## How the pipeline invokes codex (and one sandbox caveat)

`generate.sh` calls `codex exec --sandbox workspace-write` with the style
guide plus the asset prompt as the instruction, and tells codex to use its
built-in `image_gen` tool and stop, no follow-up shell commands. codex writes
the raw generated PNG under `~/.codex/generated_images/<session>/`; the
script diffs that directory before and after the run to find the new file
and copies it into `out/` itself with plain `cp`.

That last step matters: in this environment, asking codex to run its own
follow-up shell commands (for example to resize or rename the file with
`magick`) fails with a filesystem-sandbox networking error (`bwrap: loopback:
Failed RTM_NEWADDR: Operation not permitted`), even though image generation
itself works fine. Keeping every post-processing step outside codex, in
plain bash, sidesteps that entirely. If you see that error, it means a
prompt asked codex to do something after generating the image; keep prompts
generation-only.

Occasionally a generation is flagged by output moderation on the first try
even for a benign brief (this happened once while proving out this
pipeline, for the player-character sprite) and codex retries automatically
with an adjusted prompt. If a generation fails outright, rerun `codex exec`
directly with the same prompt text to see the full transcript and error.

## Current output

`out/` retains the five raw and processed assets from the starter-town
prototype. They predate the manifest-driven isometric pipeline and are not
inputs or outputs of `process_assets.py` now. The three player appearance
variants under `out/processed/` are built by `build_player_walk.py`, as
described below.

The current manifest-driven assets live under `out/iso/`. Raw generated sheets
use the `_raw.png` suffix, ingestion writes validated transparent assets to
`out/iso/ingested/`, and processing writes normalized runtime images and shadow
masks to `out/iso/processed/`.

## Manifest-driven post-processing

`process_assets.py` requires a processing manifest. Each asset entry names its
ingested source, output path and size, source and target anchors, and optional
scale and shadow generation. Processing normalizes the transparent source to
the declared anchor. For assets with shadows enabled, it also derives cast and
contact masks from the bottom footprint slice using the manifest's fixed light
vector. It does not remove backgrounds, crop content, generate appearance
variants, or choose animation frames.

Run it locally with plain Python/PIL and numpy, not inside the codex
sandbox (same caveat as image generation above, though this script has no
codex or network dependency at all, so the caveat mostly does not apply
here; it is just kept out of `generate.sh` for the same separation of
concerns):

```
python3 tools/art/process_assets.py tools/art/manifests/process-iso.json
```

The canonical manifest reproduces the committed cottage, neutral player, six
east-facing walk frames, and the cottage and player shadow masks under
`out/iso/processed/`. Regenerating one of these assets means regenerating its
raw sheet, running `ingest_generated_sheet.py` with the corresponding generated
manifest, then running the command above to refresh every declared processed
output.

## Player walk-cycle build

The option C artifact predates the manifest-driven `build_player_walk.py`
assembler. Its historical authoring operation is preserved separately in
`rebuild_player_walk_option_c.py`. The script reads the committed colored-boot
revision 3 sheet, retains its side row, completes the down and up rows as
symmetric four-frame cycles, and writes the colored option C artifact:

```
python3 tools/art/rebuild_player_walk_option_c.py \
  --output tools/art/out/player_walk_sheet_option_c_colored.png
```

The current `build_player_walk.py` has a different contract. It composites 48
declared 160 px frame images into an eight-facing, six-frame atlas from a
manifest with a top-level `frames` map. It does not author cycles, mirror rows,
align subjects, or recolor pixels. No production frames manifest is committed
yet, so it is tested with synthetic fixtures but is not the regeneration path
for the historical option C artifact. The current `check_walk_sheet.py` also
validates that newer 960 by 1280 atlas format, not the historical 1448 by 1086
option C source sheet.

The reproducible in-engine review montage uses the real starter town, player
scene, atlas regions, camera, and one-to-one shipping scale:

```
xvfb-run -a tools/godot/Godot_v4.3-stable_linux.x86_64 \
  --path . --script res://tools/art/capture_player_walk.gd
```
