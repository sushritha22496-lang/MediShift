#!/usr/bin/env python3
"""
Animation Generator for Ramayana Game Characters
Creates keyframe-based animations for all character states
Run: blender -b -P blender_generate_animations.py
"""

import bpy
from pathlib import Path

ASSETS_DIR = Path(__file__).parent / "assets" / "models"
CHARACTERS_DIR = ASSETS_DIR / "characters"
PROCESSED_DIR = CHARACTERS_DIR / "processed"
ANIMATIONS_DIR = Path(__file__).parent / "assets" / "animations"

# Create animation folders
ANIMATIONS_DIR.mkdir(parents=True, exist_ok=True)
(ANIMATIONS_DIR / "humanoid" / "locomotion").mkdir(parents=True, exist_ok=True)
(ANIMATIONS_DIR / "humanoid" / "combat").mkdir(parents=True, exist_ok=True)
(ANIMATIONS_DIR / "humanoid" / "effects").mkdir(parents=True, exist_ok=True)

def clear_scene():
    """Clear all objects from scene"""
    for obj in bpy.data.objects:
        bpy.data.objects.remove(obj, do_unlink=True)

def import_character(glb_path):
    """Import character model"""
    print(f"\n📥 Importing: {glb_path.name}")
    bpy.ops.import_scene.gltf(filepath=str(glb_path))
    return bpy.context.selected_objects[0] if bpy.context.selected_objects else None

def find_mesh_object(obj):
    """Recursively find mesh object in hierarchy"""
    if obj.type == 'MESH' and obj.data:
        return obj
    for child in obj.children:
        result = find_mesh_object(child)
        if result:
            return result
    return None

def create_animation(character_name: str, anim_name: str, anim_data: dict) -> None:
    """Create a keyframe animation"""
    print(f"🎬 Creating animation: {character_name} - {anim_name}")

    # Create action for this animation
    action = bpy.data.actions.new(name=f"{character_name}_{anim_name}")

    # Get all objects in scene (potential bones/armature)
    objects_to_animate = [obj for obj in bpy.context.scene.objects if obj.type in ['ARMATURE', 'MESH']]

    if not objects_to_animate:
        print(f"  ⚠️ No animatable objects found for {character_name}")
        return

    # Assign action to first object (usually armature)
    target = objects_to_animate[0]
    if target.animation_data is None:
        target.animation_data_create()
    target.animation_data.action = action

    # Create FCurves for basic animation (location/rotation over time)
    frames = anim_data.get("frames", 60)

    # Add location keyframes (simple movement)
    if "location" in anim_data:
        loc = anim_data["location"]
        fcurve_x = action.fcurves.new(data_path="location", index=0)
        fcurve_y = action.fcurves.new(data_path="location", index=1)
        fcurve_z = action.fcurves.new(data_path="location", index=2)

        fcurve_x.keyframe_points.insert(0, 0)
        fcurve_x.keyframe_points.insert(frames, loc[0])

        fcurve_y.keyframe_points.insert(0, 0)
        fcurve_y.keyframe_points.insert(frames, loc[1])

        fcurve_z.keyframe_points.insert(0, 0)
        fcurve_z.keyframe_points.insert(frames, loc[2])

    # Add scale animation for specific animations
    if "scale" in anim_data:
        scale = anim_data["scale"]
        for i in range(3):
            fcurve = action.fcurves.new(data_path="scale", index=i)
            fcurve.keyframe_points.insert(0, 1.0)
            fcurve.keyframe_points.insert(frames, scale)

    print(f"  ✅ Animation created: {anim_name} ({frames} frames)")

def create_character_animations(character_glb_path):
    """Create all animations for a character"""
    clear_scene()

    # Import character
    root = import_character(character_glb_path)
    if not root:
        print(f"❌ Failed to import {character_glb_path}")
        return

    character_name = character_glb_path.stem

    # Animation definitions: (name, frames, data)
    animations = [
        # Locomotion
        ("idle", 30, {"frames": 30}),  # Idle: standing still
        ("walk", 40, {"frames": 40, "location": (2.0, 0, 0)}),  # Walk: move forward 2 units
        ("run", 30, {"frames": 30, "location": (3.0, 0, 0)}),   # Run: move forward 3 units

        # Combat
        ("attack", 20, {"frames": 20, "scale": 1.1}),           # Attack: scale up slightly
        ("attack_range", 25, {"frames": 25, "location": (0.5, 0, 0)}),  # Ranged attack

        # Damage/Status
        ("get_hit", 15, {"frames": 15, "scale": 0.95}),         # Get hit: scale down
        ("death", 40, {"frames": 40, "scale": 0.8}),            # Death: collapse

        # Special
        ("jump", 20, {"frames": 20, "location": (0, 1.5, 0)}),  # Jump: up and down
        ("celebration", 30, {"frames": 30, "scale": 1.05}),     # Celebration: bounce
    ]

    for anim_name, frames, data in animations:
        data["frames"] = frames
        create_animation(character_name, anim_name, data)

    # Export as glTF with all animations
    export_path = str(ANIMATIONS_DIR / "humanoid" / f"{character_name}_animations.glb")
    print(f"📤 Exporting animations to: {export_path}")
    bpy.ops.export_scene.gltf(filepath=export_path)

    print(f"✅ {character_name}: All animations created")

def main():
    print("\n" + "#"*60)
    print("# Animation Generator - Starting")
    print("#"*60)

    # Get all character models
    character_files = list(PROCESSED_DIR.glob("*.glb"))

    # Exclude manifest files
    character_files = [f for f in character_files if not f.name.startswith(("MANIFEST", "RAMAYANA"))]

    print(f"\n📊 Found {len(character_files)} characters to animate")

    if not character_files:
        print("❌ No character files found!")
        return

    # Generate animations for sample characters (player, enemies, bosses)
    key_characters = [
        "hanuman_final.glb",      # Player
        "demon_demon_blue.glb",    # Enemy 1
        "demon_demon_green.glb",   # Enemy 2
        "dundhubi_boss.glb",       # Boss
        "kumbhakarna.glb",         # Large boss
    ]

    # Only process characters that exist
    for char_name in key_characters:
        char_path = PROCESSED_DIR / char_name
        if char_path.exists():
            try:
                create_character_animations(char_path)
            except Exception as e:
                print(f"❌ Error processing {char_name}: {e}")
                import traceback
                traceback.print_exc()

    print("\n" + "#"*60)
    print("# ✅ ANIMATION GENERATION COMPLETE")
    print("#"*60)
    print(f"\nAll animations saved to: {ANIMATIONS_DIR}")
    print("Ready for Godot import!")

if __name__ == "__main__":
    main()
