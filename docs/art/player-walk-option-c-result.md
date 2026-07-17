# Player walk option C result

Option C keeps the right-facing side row from
`player_walk_sheet_colored_revision_3.png`. At 160 px, its first and third
frames show clearly opposed planted strides. The middle frames preserve forward
motion rather than collapsing into a stationary shuffle.

The down and up rows are hand-authored programmatically in
`tools/art/build_player_walk.py`. Generated poses zero and one supply a contact
and transition half-cycle. Their full-body horizontal mirrors supply the
opposite transition and contact, and the script restores magenta and cyan to
their anatomical boots after the mirror. This changes the actual arm and leg
geometry rather than merely exchanging marker colors. The build is a pure
function of the committed revision 3 input and uses no RNG.

The unchanged pre-recolor gate reported no rejection:

| Source row | Contact separation | Reversed | Anchor drift at 160 px |
| --- | --- | --- | --- |
| down | -0.1508, +0.1900 | yes | 0.21 px |
| up | -0.1493, +0.1548 | yes | 0.25 px |
| side | +0.2193, -0.2558 | yes | 0.62 px |

The artifact of record is
`tools/art/out/player_walk_sheet_option_c_colored.png`. Validation happens on
that three-row colored source before the side mirror and leather recolor. The
processed 4 by 4 appearance atlases keep opaque sole pixels on zero-based row
159 in every frame.

## Shipping-size judgment

`player-walk-option-c-capture.png` is a Godot-rendered montage from the real
starter-town scene at one-to-one 160 px scale. Side alternation is unmistakable.
Down and up visibly exchange the near planted foot while their sole line stays
fixed. Their torso motion is restrained, so these are modest cycles rather than
exaggerated walks, but they read as grounded walking and beat the repeated
same-leg shuffle from round 1. I accept the capture on that basis.
