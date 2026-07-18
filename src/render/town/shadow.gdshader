shader_type canvas_item;

// Grounding-shadow feather (decision 016 D1, second iteration). The baked seam
// masks (assets/village/seams/<id>_{contact,cast}.png, codex's bake) carry their
// shadow shape in ALPHA. The first cut drew them as flat pure-black Sprite2Ds
// (modulate = Color(0,0,0,strength)) with NO feather, so the mask's own hard
// alpha edge showed and pure black read as a painted polygon (agy QA D1: the
// inn-sign cast "solid, unnaturally dark and sharp-edged grey polygon", the tree
// shadow "pitch-black, hard-edged blob", the sunflower basal "sharp-edged
// rectangular shape"). This material fixes that render-side WITHOUT re-baking:
//
//   1. FEATHER: a small separable-shaped Gaussian over the mask alpha grades the
//      hard alpha boundary into the ground. feather_px sets the texel spread, so
//      the wider CAST grounding pool can feather more than the tight CONTACT core
//      (village_render.gd passes a larger feather for cast).
//   2. LIGHTEN + WARM: the shadow is tinted a dark desaturated earth-brown
//      (shadow_color), never pure black, so it reads as cast light-occlusion on
//      soil rather than a black shape. strength scales the feathered alpha.
//
// The mask RGB is 0 (shape is alpha-only), so we substitute shadow_color for the
// tint and drive opacity from the blurred alpha. Determinism holds: no TIME, no
// screen input, a pure function of the committed mask texels.

// Dark desaturated earth-brown the shadow grades toward (NOT pure black). Matches
// the spike's soft brown contact value rather than a painted black polygon.
uniform vec3 shadow_color : source_color = vec3(0.09, 0.07, 0.05);

// Texel spread of the feather. The Gaussian taps step by feather_px * texel, so a
// larger value softens a wider band (cast > contact). 0 collapses to no blur.
uniform float feather_px : hint_range(0.0, 6.0) = 1.2;

// Opacity scale on the feathered alpha (bounded per-object in village_render.gd).
uniform float strength : hint_range(0.0, 1.0) = 0.55;

// Gaussian shape constant over the fixed 7x7 tap grid (i,j in -3..3). Taps are
// weighted exp(-(i*i+j*j)/(2*SIGMA*SIGMA)); feather_px scales their pixel step.
const int R = 3;
const float SIGMA = 1.4;

void fragment() {
	vec2 texel = TEXTURE_PIXEL_SIZE * feather_px;
	float acc = 0.0;
	float wsum = 0.0;
	for (int j = -R; j <= R; j++) {
		for (int i = -R; i <= R; i++) {
			float w = exp(-float(i * i + j * j) / (2.0 * SIGMA * SIGMA));
			// Only the alpha carries the shadow shape; RGB is 0 in the mask.
			acc += texture(TEXTURE, UV + vec2(float(i), float(j)) * texel).a * w;
			wsum += w;
		}
	}
	float feathered = (wsum > 0.0) ? acc / wsum : 0.0;
	// Output the earth-brown tint with the FEATHERED alpha. We drive alpha from the
	// blurred mask (not the raw COLOR.a, which is mask*MODULATE and would re-clip
	// the feather back to the mask's hard shape); the per-item MODULATE.a still lets
	// a caller fade the whole layer. This lets the soft edge grade past the mask's
	// hard boundary into the ground, which is the whole point of the feather.
	COLOR = vec4(shadow_color, feathered * strength * MODULATE.a);
}
