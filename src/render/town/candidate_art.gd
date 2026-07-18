extends RefCounted
class_name CandidateArt

# RENDER-side candidate-art selector for the round-006 pilot. This is the single
# deterministic switch that decides which frozen art set the starter town wires:
# the round-005 proxy art (default), or pilot candidate A or B.
#
# The switch is one environment variable, LONGWALK_ART_CANDIDATE, read once at
# scene setup. It is side-effect-free (a pure read) so the acceptance-capture
# harness can set it per capture without touching any other state:
#
#   unset / "current" -> "" : the shipped round-005 proxy art, unchanged.
#   "a"               -> "a": pilot candidate A (8-facing player + cottage).
#   "b"               -> "b": pilot candidate B (8-facing player + cottage).
#
# The candidate art lives under assets/art_src/pilot/candidate_*/, and those
# directories carry a .gdignore so the Godot importer deliberately skips them
# (they are authoring sources, not imported game resources). The loaders below
# therefore read the raw files straight off disk (Image.load / FileAccess),
# which does not go through the import system and so is unaffected by .gdignore.

const ENV_VAR := "LONGWALK_ART_CANDIDATE"
const CANDIDATE_IDS := ["a", "b"]


# Returns "a", "b", or "" (the default proxy art). Pure read of the one env var;
# any value other than a known candidate id (including "current" or unset) means
# the default, so nothing regresses when the variable is absent.
static func selected() -> String:
	var raw := OS.get_environment(ENV_VAR).strip_edges().to_lower()
	if raw in CANDIDATE_IDS:
		return raw
	return ""


static func base_dir(candidate_id: String) -> String:
	return "res://assets/art_src/pilot/candidate_%s" % candidate_id


static func player_manifest_path(candidate_id: String) -> String:
	return base_dir(candidate_id) + "/player_walk_manifest.json"


static func player_atlas_path(candidate_id: String) -> String:
	return base_dir(candidate_id) + "/player_walk_atlas.png"


static func cottage_texture_path(candidate_id: String) -> String:
	return base_dir(candidate_id) + "/finished/cottage/cottage_w.png"


static func cottage_scale_path(candidate_id: String) -> String:
	return base_dir(candidate_id) + "/cottage_scale.json"


# Reads a JSON object off disk. Uses FileAccess rather than load()/ResourceLoader
# so it works for the .gdignore'd candidate directories.
static func load_json(res_path: String) -> Dictionary:
	var file := FileAccess.open(res_path, FileAccess.READ)
	assert(file != null, "candidate art: cannot open %s" % res_path)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	assert(parsed is Dictionary, "candidate art: malformed json %s" % res_path)
	return parsed


# Loads a PNG into an ImageTexture off disk, bypassing the import system so the
# .gdignore'd candidate atlases and cottage sprites resolve.
static func load_texture(res_path: String) -> Texture2D:
	var image := Image.new()
	var err := image.load(res_path)
	assert(err == OK, "candidate art: cannot load image %s (error %d)" % [res_path, err])
	return ImageTexture.create_from_image(image)
