import bpy
import math
import sys
import os
from mathutils import Vector
from bpy_extras.object_utils import world_to_camera_view

def setup_scene():
    # Clear existing data
    bpy.ops.wm.read_factory_settings(use_empty=True)
    
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    scene.cycles.device = 'CPU'
    scene.render.film_transparent = True
    scene.view_settings.view_transform = 'Standard'
    scene.view_settings.look = 'None'
    
    # Pass settings (Constraint 1)
    view_layer = scene.view_layers[0]
    view_layer.use_pass_z = True
    view_layer.use_pass_normal = True
    view_layer.use_pass_position = True
    view_layer.use_pass_uv = True
    view_layer.use_pass_shadow = True
    
    # Render resolution
    scene.render.resolution_x = 1024
    scene.render.resolution_y = 1024
    scene.render.resolution_percentage = 100
    
    return scene

def setup_camera(scene):
    cam_data = bpy.data.cameras.new('Camera')
    cam_data.type = 'ORTHO'
    cam_obj = bpy.data.objects.new('Camera', cam_data)
    scene.collection.objects.link(cam_obj)
    scene.camera = cam_obj
    
    # 2:1 Dimetric requires elevation = arcsin(0.5) = 30 degrees.
    # The prompt hints at atan(0.5), but the math for a true 2:1 pixel ratio
    # given orthographic projection requires an elevation of exactly 30 degrees.
    # Rotation X = 90 - elevation = 60 degrees.
    # Azimuth = 45 degrees.
    elevation_deg = 30.0
    azimuth_deg = 45.0
    
    cam_obj.rotation_euler = (
        math.radians(90 - elevation_deg),
        0,
        math.radians(azimuth_deg)
    )
    
    # Position the camera so it looks directly at the origin.
    # The local Z axis of the camera points OUT of the lens (backward).
    # We move the camera along its local Z axis by 100 units.
    bpy.context.view_layer.update()
    cam_obj.location = cam_obj.matrix_world.to_3x3() @ Vector((0.0, 0.0, 100.0))
    
    # Orthographic scale: to get 1 Blender unit to project to 128 pixels wide (Godot's TILE_W).
    # Math: scale = resolution_x / (TILE_W / sqrt(2) * 2?)
    # Based on our calibration, scale = 1024 / (64 * sqrt(2)) approx 11.3137
    scale = 1024 / (64 * math.sqrt(2))
    cam_data.ortho_scale = scale
    
    bpy.context.view_layer.update()
    return cam_obj

def get_pixel_coords(scene, cam_obj, world_loc):
    ndc = world_to_camera_view(scene, cam_obj, world_loc)
    # Convert from Blender NDC (Y up) to Image Pixel Coordinates (Y down)
    px = (ndc.x - 0.5) * scene.render.resolution_x
    py = (0.5 - ndc.y) * scene.render.resolution_y
    return px, py

def run_calibration():
    scene = setup_scene()
    cam_obj = setup_camera(scene)
    
    # Test cases: (Godot Cell X, Godot Cell Y)
    test_cells = [
        (0, 0),
        (1, 0),
        (0, 1),
        (1, 1),
        (3, 4),
        (-2, 1)
    ]
    
    print("\n--- CAMERA CALIBRATION RESULTS ---")
    
    max_error = 0.0
    
    for gx, gy in test_cells:
        # Godot (X, Y) maps to Blender (X, -Y, 0)
        blender_loc = Vector((gx, -gy, 0.0))
        
        px, py = get_pixel_coords(scene, cam_obj, blender_loc)
        
        # Calculate Godot expected
        godot_px = (gx - gy) * 64.0
        godot_py = (gx + gy) * 32.0
        
        # Calculate difference
        diff_x = abs(px - godot_px)
        diff_y = abs(py - godot_py)
        error = max(diff_x, diff_y)
        max_error = max(max_error, error)
        
        print(f"Cell ({gx}, {gy}):")
        print(f"  Blender Proj: ({px:.2f}, {py:.2f})")
        print(f"  Godot Proj:   ({godot_px:.2f}, {godot_py:.2f})")
        print(f"  Error:        {error:.4f} px")
        
    print("\n--- FOOTPRINT CONTACT POINT TESTS ---")
    
    test_footprints = [
        # (origin_x, origin_y, footprint_w, footprint_h)
        (0, 0, 1, 1),
        (0, 0, 2, 2),
        (2, 3, 3, 2),
        (-1, -1, 4, 4)
    ]
    
    for ox, oy, fw, fh in test_footprints:
        # Godot projection.gd: building_contact_cell
        godot_contact_x = float(ox) + float(fw) / 2.0
        godot_contact_y = float(oy) + float(fh)
        
        godot_px = (godot_contact_x - godot_contact_y) * 64.0
        godot_px = (godot_contact_x - godot_contact_y) * 64.0
        godot_py = (godot_contact_x + godot_contact_y) * 32.0
        
        # In Blender, the contact point is mapped just like cells:
        blender_contact = Vector((godot_contact_x, -godot_contact_y, 0.0))
        px, py = get_pixel_coords(scene, cam_obj, blender_contact)
        
        diff_x = abs(px - godot_px)
        diff_y = abs(py - godot_py)
        error = max(diff_x, diff_y)
        max_error = max(max_error, error)
        
        print(f"Footprint Origin ({ox}, {oy}), Size ({fw}x{fh}):")
        print(f"  Contact Cell: ({godot_contact_x}, {godot_contact_y})")
        print(f"  Blender Proj: ({px:.2f}, {py:.2f})")
        print(f"  Godot Proj:   ({godot_px:.2f}, {godot_py:.2f})")
        print(f"  Error:        {error:.4f} px")

    print(f"\nMax Pixel Error: {max_error:.4f} px")
    print("----------------------------------\n")
    
    if max_error > 0.1:
        print("CALIBRATION FAILED!")
        sys.exit(1)
    else:
        print("CALIBRATION PASSED!")

if __name__ == "__main__":
    run_calibration()
