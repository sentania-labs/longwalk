import bpy
import math
import sys
import os

# Add the directory containing blender_calibration.py to sys.path so we can import it
sys.path.append(os.path.dirname(__file__))
import blender_calibration

def setup_scene_and_camera():
    scene = blender_calibration.setup_scene()
    
    # We want to output composite nodes to separate passes for PNGs
    scene.use_nodes = True
    tree = scene.node_tree
    tree.nodes.clear()
    
    render_layers = tree.nodes.new(type="CompositorNodeRLayers")
    
    # We will set up FileOutput node in the render function
    cam_obj = blender_calibration.setup_camera(scene)
    return scene, cam_obj

def load_character(filepath):
    # clear objects except camera
    for obj in bpy.data.objects:
        if obj.name != 'Camera':
            bpy.data.objects.remove(obj)
            
    bpy.ops.import_scene.gltf(filepath=filepath)
    
    armature = None
    for obj in bpy.data.objects:
        if obj.type == 'ARMATURE':
            armature = obj
            break
            
    return armature

def set_facing(armature, facing_label):
    """
    Sets the character's rotation around the world-Z axis to match the isometric facing.
    The camera stays fixed at the calibrated iso pose (azimuth 45).
    
    Godot (X,Y) -> Blender (X,-Y,0)
    Blender +X = Godot +X (SE, screen angle 45)
    Blender -Y = Godot +Y (SW, screen angle 135)
    Blender +Y = Godot -Y (NE, screen angle 315)
    Blender -X = Godot -X (NW, screen angle 225)
    
    Assuming the character faces +Y (NE) at 0 rotation (standard GLB import in Blender).
    To face SE (+X), we rotate -90 deg.
    Let's map labels to Blender Z rotation (in degrees):
    """
    # Assuming character base orientation is +Y
    # +Y is NE (315 screen).
    # To get E (0 screen), rotate -45 from NE.
    # To get SE (45 screen), rotate -90 from NE.
    
    facing_to_rot_z = {
        "SW": 0.0,
        "S":  45.0,
        "SE": 90.0,
        "E":  135.0,
        "NE": 180.0,
        "N":  -135.0,
        "NW": -90.0,
        "W":  -45.0
    }
    
    rot_z_deg = facing_to_rot_z[facing_label]
    armature.rotation_mode = 'XYZ'
    armature.rotation_euler[2] = math.radians(rot_z_deg)
    bpy.context.view_layer.update()
    
    return facing_to_rot_z

def set_pose(armature, frame_index, total_poses=6):
    """
    Samples `total_poses` keyframe poses evenly across the walk action frame range.
    The known walk action is roughly frames 1 to 25.
    We will interpolate from frame 1 to 25.
    """
    action = None
    for act in bpy.data.actions:
        if "walk" in act.name.lower() or "baselayer" in act.name.lower():
            action = act
            break
            
    if action:
        armature.animation_data_create()
        armature.animation_data.action = action
        
        # Action frame range is typically 1 to 25.
        start_frame, end_frame = action.frame_range
        start_frame = math.ceil(start_frame)
        end_frame = math.floor(end_frame)
        
        # We need 6 poses evenly spaced.
        if total_poses > 1:
            step = (end_frame - start_frame) / (total_poses - 1)
        else:
            step = 0
            
        target_frame = start_frame + step * frame_index
        bpy.context.scene.frame_set(int(round(target_frame)))
        bpy.context.view_layer.update()
    
def render_frame(scene, out_dir, facing, pose_idx):
    """
    Renders the current frame and saves the requested passes to PNGs.
    Naming contract: {facing}_{pose_idx}_{pass}.png
    Example: E_0_color.png, E_0_z.png
    """
    tree = scene.node_tree
    tree.nodes.clear()
    
    file_output = tree.nodes.new(type="CompositorNodeOutputFile")
    file_output.base_path = out_dir
    file_output.format.file_format = 'PNG'
    file_output.format.color_mode = 'RGBA'
    
    render_layers = tree.nodes.new(type="CompositorNodeRLayers")
    
    file_output.file_slots.clear()
    
    # Add slots for each pass we care about
    file_output.file_slots.new("color")
    file_output.file_slots.new("z")
    file_output.file_slots.new("normal")
    file_output.file_slots.new("position")
    file_output.file_slots.new("uv")
    file_output.file_slots.new("shadow")
    
    tree.links.new(render_layers.outputs['Image'], file_output.inputs['color'])
    tree.links.new(render_layers.outputs['Depth'], file_output.inputs['z'])
    tree.links.new(render_layers.outputs.get('Normal'), file_output.inputs['normal'])
    tree.links.new(render_layers.outputs.get('Position'), file_output.inputs['position'])
    tree.links.new(render_layers.outputs.get('UV'), file_output.inputs['uv'])
    if 'Shadow' in render_layers.outputs:
        tree.links.new(render_layers.outputs['Shadow'], file_output.inputs['shadow'])
    elif 'Shadows' in render_layers.outputs:
        tree.links.new(render_layers.outputs['Shadows'], file_output.inputs['shadow'])

    # Set the naming template for this specific render
    file_output.file_slots['color'].path = f"{facing}_{pose_idx}_color_"
    file_output.file_slots['z'].path = f"{facing}_{pose_idx}_z_"
    file_output.file_slots['normal'].path = f"{facing}_{pose_idx}_normal_"
    file_output.file_slots['position'].path = f"{facing}_{pose_idx}_position_"
    file_output.file_slots['uv'].path = f"{facing}_{pose_idx}_uv_"
    file_output.file_slots['shadow'].path = f"{facing}_{pose_idx}_shadow_"

    # Render
    result = bpy.ops.render.render(write_still=False)
    if 'FINISHED' not in result:
        sys.exit(f"Render failed for facing {facing} pose {pose_idx}!")

    # Pass names we created:
    pass_names = ["color", "z", "normal", "position", "uv", "shadow"]

    import glob
    for pass_name in pass_names:
        expected_path = os.path.join(out_dir, f"{facing}_{pose_idx}_{pass_name}.png")
        search_pattern = os.path.join(out_dir, f"{facing}_{pose_idx}_{pass_name}_*.png")
        actual_files = glob.glob(search_pattern)
        
        if not actual_files:
            if pass_name == "shadow":
                continue
            else:
                sys.exit(f"Expected pass {pass_name} missing for {facing} {pose_idx}! Searched: {search_pattern}")
                
        actual_path = actual_files[0]
        if os.path.exists(expected_path):
            os.remove(expected_path)
        os.rename(actual_path, expected_path)

def run_sanity():
    # Setup
    scene, cam_obj = setup_scene_and_camera()
    scene.cycles.samples = 16  # Low samples for sanity
    
    filepath = os.path.abspath("assets/art_src/pilot/cleaned/player_walk.glb")
    armature = load_character(filepath)
    
    out_dir = os.path.abspath("assets/art_src/pilot/sanity_render")
    if os.path.exists(out_dir):
        import shutil
        shutil.rmtree(out_dir)
    os.makedirs(out_dir, exist_ok=True)
    
    facings_to_test = ["SE"]
    for facing in facings_to_test:
        set_facing(armature, facing)
        
        poses = range(6)
        out = out_dir

        for i in poses:
            set_pose(armature, i, 6)
            render_frame(scene, out, facing, i)

    # Extra validation requested by Codex (NE and S).
    # We output them to a separate directory so sanity_render stays at exactly 30 files.
    validate_dir = out_dir + "_validate"
    os.makedirs(validate_dir, exist_ok=True)
    for facing in ["NE", "S"]:
        set_facing(armature, facing)
        set_pose(armature, 0, 6)
        render_frame(scene, validate_dir, facing, 0)

    # Verify sanity_render has exactly 30 files
    expected_count = 30
    actual_count = len([f for f in os.listdir(out_dir) if f.endswith(".png")])
    if actual_count != expected_count:
        sys.exit(f"Sanity render failed: expected {expected_count} files, found {actual_count}")

if __name__ == "__main__":
    if "--sanity" in sys.argv:
        run_sanity()
