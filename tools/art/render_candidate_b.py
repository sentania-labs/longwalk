"""Candidate B render driver: render the cleaned GLBs with a Meshy-restyled albedo.

Candidate B is the generative-stylization arm of the round-006 pilot (decision
009 Q1, option 1: texture-space albedo restyle applied once per asset). The
geometry, camera, cell grid, lighting, and anchor deliberately MATCH candidate A
so the acceptance comparison is apples to apples; the ONLY difference is the
base-color texture, which for candidate B is a Meshy retexture output instead of
candidate A's deterministic NPR palette quantization.

The restyled albedo is applied onto the SAME cleaned geometry candidate A renders
(assets/art_src/pilot/cleaned/*.glb), not onto the raw Meshy retexture mesh, so
the mesh, UVs, pose action, and silhouette are identical to candidate A. The
restyled albedo PNGs are committed under assets/art_src/pilot/candidate_b/ and are
the frozen generative output; this script needs NO Meshy call to run.

Lighting/camera/sample constants below are copied verbatim from candidate A's
production render so both candidates render under identical conditions. This file
is candidate B's own copy on purpose (slice isolation: it does not edit
blender_pose_rig.py, which candidate A owns).

Run inside Blender:
    blender -b --python tools/art/render_candidate_b.py -- --production
"""

import bpy
import math
import sys
import os

sys.path.append(os.path.dirname(__file__))
import blender_calibration
from blender_pose_rig import set_facing, set_pose, render_frame

FACING_ORDER = ("E", "SE", "S", "SW", "W", "NW", "N", "NE")
PRODUCTION_SAMPLES = 32

PLAYER_GLB = "assets/art_src/pilot/cleaned/player_walk.glb"
COTTAGE_GLB = "assets/art_src/pilot/cleaned/cottage.glb"
PLAYER_ALBEDO = "assets/art_src/pilot/candidate_b/player_restyled_albedo.png"
COTTAGE_ALBEDO = "assets/art_src/pilot/candidate_b/cottage_restyled_albedo.png"
RENDER_ROOT = "assets/art_src/pilot/candidate_b/render"


def setup_scene_and_camera():
    """Identical scene/camera/lighting to candidate A's production render."""
    scene = blender_calibration.setup_scene()

    scene.use_nodes = True
    tree = scene.node_tree
    tree.nodes.clear()
    tree.nodes.new(type="CompositorNodeRLayers")

    cam_obj = blender_calibration.setup_camera(scene)
    scene.cycles.use_denoising = True

    world = bpy.data.worlds.new("Two Rivers World")
    scene.world = world
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.42, 0.48, 0.39, 1.0)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.65

    sun_data = bpy.data.lights.new("Warm Key", type='SUN')
    sun_data.energy = 2.2
    sun_data.angle = math.radians(12.0)
    sun = bpy.data.objects.new("Warm Key", sun_data)
    scene.collection.objects.link(sun)
    sun.rotation_euler = (math.radians(28.0), math.radians(-18.0), math.radians(-38.0))

    area_data = bpy.data.lights.new("Cool Fill", type='AREA')
    area_data.energy = 260.0
    area_data.shape = 'DISK'
    area_data.size = 5.0
    area = bpy.data.objects.new("Cool Fill", area_data)
    scene.collection.objects.link(area)
    area.location = (-4.0, 2.0, 6.0)
    area.rotation_euler = (0.0, 0.0, math.radians(140.0))
    return scene, cam_obj


def clear_imported():
    for obj in list(bpy.data.objects):
        if obj.name == 'Camera' or obj.type == 'LIGHT':
            continue
        bpy.data.objects.remove(obj)


def apply_albedo(mesh_objs, albedo_path):
    """Repoint every base-color/emission image node to the restyled albedo.

    The restyled PNG lives in the same UV space as the cleaned GLB (Meshy
    retexture with enable_original_uv=true, run on the cleaned mesh's direct Meshy
    parent task), so the painterly texture maps correctly onto the cleaned UVs.
    """
    abspath = os.path.abspath(albedo_path)
    if not os.path.exists(abspath):
        sys.exit(f"Restyled albedo missing: {abspath}. Commit it before rendering.")
    img = bpy.data.images.load(abspath, check_existing=True)
    swapped = 0
    for obj in mesh_objs:
        for mat in obj.data.materials:
            if mat is None or not mat.use_nodes:
                continue
            for node in mat.node_tree.nodes:
                if node.type == 'TEX_IMAGE':
                    node.image = img
                    swapped += 1
    if swapped == 0:
        sys.exit(f"No image nodes found to swap for {albedo_path}")
    print(f"Applied {albedo_path} to {swapped} texture node(s)")


def load_player():
    clear_imported()
    bpy.ops.import_scene.gltf(filepath=os.path.abspath(PLAYER_GLB))
    armature = None
    for obj in bpy.data.objects:
        if obj.type == 'ARMATURE':
            armature = obj
            break
    if armature is None:
        sys.exit("Player GLB contains no armature")
    # Keep only the armature-skinned character mesh; drop stray junk (a
    # non-parented, unskinned Icosphere ships inside the cleaned GLB and would
    # render as a blob over the legs). char1 has an ARMATURE modifier + weights.
    character = []
    for obj in list(bpy.data.objects):
        if obj.type != 'MESH':
            continue
        skinned = any(m.type == 'ARMATURE' for m in obj.modifiers)
        if skinned:
            character.append(obj)
        else:
            print(f"Dropping stray unskinned mesh: {obj.name}")
            bpy.data.objects.remove(obj)
    apply_albedo(character, PLAYER_ALBEDO)
    return armature


def load_cottage():
    clear_imported()
    bpy.ops.import_scene.gltf(filepath=os.path.abspath(COTTAGE_GLB))
    meshes = [o for o in bpy.data.objects if o.type == 'MESH']
    apply_albedo(meshes, COTTAGE_ALBEDO)
    return meshes


def rotate_roots(roots, facing_label):
    rotation = {
        "SW": 0.0, "S": 45.0, "SE": 90.0, "E": 135.0,
        "NE": 180.0, "N": -135.0, "NW": -90.0, "W": -45.0,
    }[facing_label]
    for root in roots:
        root.rotation_mode = 'XYZ'
        root.rotation_euler[2] = math.radians(rotation)
    bpy.context.view_layer.update()


def run_production():
    scene, _cam = setup_scene_and_camera()
    scene.cycles.samples = PRODUCTION_SAMPLES
    player_dir = os.path.abspath(os.path.join(RENDER_ROOT, "player"))
    cottage_dir = os.path.abspath(os.path.join(RENDER_ROOT, "cottage"))
    os.makedirs(player_dir, exist_ok=True)
    os.makedirs(cottage_dir, exist_ok=True)

    armature = load_player()
    for facing in FACING_ORDER:
        set_facing(armature, facing)
        for pose_idx in range(6):
            set_pose(armature, pose_idx, 6)
            render_frame(scene, player_dir, facing, pose_idx)

    meshes = load_cottage()
    for facing in FACING_ORDER:
        rotate_roots(meshes, facing)
        render_frame(scene, cottage_dir, facing, 0)


def run_smoke():
    """One player frame + one cottage frame, original texture, to validate the
    rig before spending Meshy credits. Writes to <RENDER_ROOT>/_smoke."""
    scene, _cam = setup_scene_and_camera()
    scene.cycles.samples = PRODUCTION_SAMPLES
    out = os.path.abspath(os.path.join(RENDER_ROOT, "_smoke"))
    os.makedirs(out, exist_ok=True)

    clear_imported()
    bpy.ops.import_scene.gltf(filepath=os.path.abspath(PLAYER_GLB))
    armature = next((o for o in bpy.data.objects if o.type == 'ARMATURE'), None)
    for obj in list(bpy.data.objects):
        if obj.type == 'MESH' and not any(m.type == 'ARMATURE' for m in obj.modifiers):
            print(f"Dropping stray unskinned mesh: {obj.name}")
            bpy.data.objects.remove(obj)
    character = [o for o in bpy.data.objects if o.type == 'MESH']
    apply_albedo(character, PLAYER_ALBEDO)
    set_facing(armature, "SE")
    set_pose(armature, 2, 6)
    render_frame(scene, out, "SE", 2)


if __name__ == "__main__":
    if "--production" in sys.argv:
        run_production()
    elif "--smoke" in sys.argv:
        run_smoke()
    else:
        sys.exit("pass --production or --smoke")
