# Colored-boot walk-sheet spike

All three revisions used the existing `player_character.png` as the visible
identity and project-style reference. The source shape was fixed at three rows
by four columns: down, up, and right-facing side. Every prompt required a
solid `#FF00FF` background, stable grounded sole baselines, a magenta-pink
anatomical left boot, a cyan-blue anatomical right boot, and opposite contact
poses in columns 1 and 3.

## Revision 1

The first prompt specified the full sheet and exact locomotion sequence. It
required the left boot to lead in column 1, the right boot to lead in column 3,
opposite passing poses in columns 2 and 4, and no whole-body vertical motion.

Gate result: rejected. Several down and side frames omitted the cyan marker.
The up row kept the same boot leading throughout. Anchor drift stayed below
the 0.05 limit in every row.

## Revision 2

The second prompt edited revision 1. It required both complete boots to remain
visible in all twelve cells, bound each marker color to one anatomical foot,
and restated forward direction in image coordinates for every row.

Gate result: rejected. Down and up kept the same boot leading. The last side
frame omitted the cyan marker. Anchor drift again stayed below the limit.

## Revision 3

The third prompt edited revision 2 with cell-specific image-coordinate rules.
It required a minimum one-boot-width reversal between contact frames and dark
outlines around both markers so neither could merge into the background.

Gate result: rejected. Side alternation passed with signed x separations
`[0.2193, 0.2308, -0.2569, -0.2311]`. Down and up still kept the same boot
leading in both contact frames. Anchor drift was 0.0026, 0.0014, and 0.0039
cell heights for down, up, and side respectively, all below the 0.05 limit.

The colored artifacts remain unrecolored and unmirrored. No final brown-boot
sheet was produced because recoloring would destroy the diagnostic signal on
rejected source art.
