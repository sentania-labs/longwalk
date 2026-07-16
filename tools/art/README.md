# tools/art, AI art generation pipeline

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

Three assets prove the pipeline end to end (`ground_path_tile.png`,
`building_facade.png`, `player_character.png`). They are raw generator
output: high-resolution (1254x1254 or 1536x1024), uncropped, on a plain
cream background rather than true alpha transparency. Cropping to exact game
tile/sprite dimensions and background removal are manual post-processing
steps for a later dispatch (do them locally with, for example, Python/PIL,
not inside the codex sandbox, per the caveat above); this dispatch's job was
proving the generation pipeline works and is regenerable, not final asset
processing.
