FAIL

## Generated evidence

I generated two raw 3x4 sprite-sheet candidates with one `image_gen` call per
candidate. Each sheet contains rows for down, up, and right-side facings, with
four intended walk-cycle frames per row. The prompts and raw outputs are:

- `tools/art/prompts/player_walk_sheet_candidate_1.md`
- `tools/art/out/player_walk_sheet_candidate_1.png`
- `tools/art/prompts/player_walk_sheet_candidate_2.md`
- `tools/art/out/player_walk_sheet_candidate_2.png`

Candidate one was the initial generation. Candidate two used the one permitted
prompt revision.

## Game-scale inspection

I divided each 1448 by 1086 raw sheet into its regular 4 by 3 cells and resized
each cell to 160 pixels tall with Lanczos resampling. I viewed the resulting
728 by 480 preview at its native size, so every character cell was judged at
the pinned shipping height rather than by zooming into the raw sheet.

Candidate one remained readable at that scale and kept one character design
across all twelve cells. The down row showed a recognizable change of leading
leg and opposing arm motion. The up row also changed its leg overlap enough to
suggest alternation. The side row failed: frames one and three had essentially
the same contact silhouette and the same leg forward. Its passing frames also
did not establish a clear opposite-foot progression. In motion this would read
as two repeated poses, not a four-frame alternating walk.

I revised the prompt to name that failure directly. The second prompt specified
opposite near-leg and far-leg positions for side contact frames one and three,
opposite passing poses for frames two and four, and explicitly prohibited
repeating those pairs.

Candidate two kept a coherent character, costume, scale, and facing within the
sheet. The side row had clear contact and raised-knee silhouettes, but frames
one and three again repeated the same extended-stride silhouette rather than
reversing which leg led. Frames two and four read as two raised-knee poses, not
clearly opposite passing legs. The down and up rows were weaker than candidate
one: their leg silhouettes changed slightly, but the same leg appeared to lead
through most or all columns, so the feet did not visibly alternate at game
scale.

## Gate reason

Both candidates are coherent sprite-sheet art, but neither is a shippable walk
cycle under the agreed rejection criterion. The legs articulate and some
silhouettes change, yet the feet do not alternate reliably across all three
facings. Candidate two exhausted the single allowed prompt revision, so this
spike selects the documented fallback path and requires the decision record's
Scott escalation before that fallback can redefine the assignment minimum.
