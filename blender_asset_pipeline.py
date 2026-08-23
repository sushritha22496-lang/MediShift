#!/usr/bin/env python3
"""
MediShift Asset Pipeline - Blender Automation
Modifies downloaded models to create Hanuman character and enemy variations
Run: blender -b -P blender_asset_pipeline.py
"""

import bpy
import os
import sys
from pathlib import Path

# Configuration
ASSETS_DIR = Path(__file__).parent / "assets" / "models"
CHARACTERS_DIR = ASSETS_DIR / "characters"
OUTPUT_DIR = CHARACTERS_DIR / "processed"

# Create output directory
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

def clear_scene():
    """Clear default scene"""
    for obj in bpy.data.objects:
        bpy.data.objects.remove(obj, do_unlink=True)

def import_model(filepath):
    """Import glTF model"""
    print(f"\n📥 Importing: {filepath}")
    bpy.ops.import_scene.gltf(filepath=str(filepath))
    print(f"✓ Imported successfully")

def find_mesh_object(obj):
    """Recursively find first mesh object"""
    if obj.type == 'MESH' and obj.data:
        return obj
    for child in obj.children:
        result = find_mesh_object(child)
        if result:
            return result
    return None

def apply_hanuman_colors(obj):
    """Apply golden/tan colors for Hanuman"""
    # Find actual mesh object
    mesh_obj = find_mesh_object(obj)
    if not mesh_obj:
        print(f"⚠️  No mesh found in {obj.name}")
        return

    print(f"🎨 Applying Hanuman colors to {mesh_obj.name}")

    # Create material
    mat = bpy.data.materials.new(name="hanuman_skin")
    mat.use_nodes = True
    mat.diffuse_color = (0.95, 0.85, 0.5, 1.0)  # Golden tan

    # Add to object
    if mesh_obj.data.materials:
        mesh_obj.data.materials[0] = mat
    else:
        mesh_obj.data.materials.append(mat)

def apply_demon_colors(obj, variant=1):
    """Apply demon colors (red, dark red, purple)"""
    colors = [
        (0.8, 0.1, 0.1, 1.0),   # Red demon
        (0.3, 0.05, 0.05, 1.0), # Dark red demon
        (0.5, 0.1, 0.5, 1.0),   # Purple demon
    ]

    color = colors[min(variant, 2)]

    # Find actual mesh object
    mesh_obj = find_mesh_object(obj)
    if not mesh_obj:
        print(f"⚠️  No mesh found in {obj.name}")
        return

    print(f"🎨 Applying demon color {variant} to {mesh_obj.name}")

    mat = bpy.data.materials.new(name=f"demon_{variant}")
    mat.use_nodes = True
    mat.diffuse_color = color

    if mesh_obj.data.materials:
        mesh_obj.data.materials[0] = mat
    else:
        mesh_obj.data.materials.append(mat)

def scale_object(obj, scale_factor):
    """Scale object"""
    print(f"📏 Scaling {obj.name} by {scale_factor}x")
    obj.scale = (scale_factor, scale_factor, scale_factor)
    bpy.context.view_layer.update()

def export_model(obj, output_name):
    """Export as glTF 2.0"""
    print(f"📤 Exporting: {output_name}")

    # Select object
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)

    # Export
    filepath = str(OUTPUT_DIR / f"{output_name}.glb")
    bpy.ops.export_scene.gltf(
        filepath=filepath
    )
    print(f"✓ Exported to {filepath}")
    return filepath

def process_hanuman():
    """Create Hanuman character"""
    print("\n" + "="*60)
    print("🦁 CREATING HANUMAN CHARACTER")
    print("="*60)

    clear_scene()
    import_model(CHARACTERS_DIR / "mannequin.glb")

    # Get imported object
    obj = bpy.context.selected_objects[0]

    # Customize
    apply_hanuman_colors(obj)
    scale_object(obj, 1.1)  # Slightly larger

    # Export
    export_model(obj, "hanuman_final")
    print("✓ Hanuman created successfully!")

def process_demon_guards():
    """Create demon guard variations"""
    print("\n" + "="*60)
    print("👹 CREATING DEMON GUARD VARIATIONS")
    print("="*60)

    for variant in range(3):
        clear_scene()
        base_model = CHARACTERS_DIR / "enemy_base.glb"
        import_model(base_model)

        obj = bpy.context.selected_objects[0]
        apply_demon_colors(obj, variant)
        scale_object(obj, 0.9 + variant * 0.1)  # Slight size variation

        export_model(obj, f"demon_guard_{variant+1}")

    print("✓ Demon guards created successfully!")

def process_boss():
    """Create Dundhubi boss"""
    print("\n" + "="*60)
    print("👹 CREATING DUNDHUBI BOSS")
    print("="*60)

    clear_scene()
    import_model(CHARACTERS_DIR / "robot.glb")  # Use robot as imposing boss

    obj = bpy.context.selected_objects[0]
    apply_demon_colors(obj, 1)  # Dark red
    scale_object(obj, 2.0)  # Much larger for boss

    export_model(obj, "dundhubi_boss")
    print("✓ Boss created successfully!")

def create_manifest():
    """Create asset manifest"""
    manifest = """# Processed Assets Manifest

## Hanuman Player Character
✅ hanuman_final.glb
- Base: Rigged humanoid mannequin
- Color: Golden/tan skin
- Scale: 1.1x (slightly large for protagonist)
- Status: Ready for game integration

## Demon Guard Variations
✅ demon_guard_1.glb (Red)
✅ demon_guard_2.glb (Dark Red)
✅ demon_guard_3.glb (Purple)
- Base: Enemy model
- Variations: Color + scale differences
- Scales: 0.9x, 1.0x, 1.1x
- Status: Ready for spawning system

## Dundhubi Boss
✅ dundhubi_boss.glb
- Base: Robot character (imposing)
- Color: Dark red (demonic)
- Scale: 2.0x (twice as large)
- Status: Ready for boss encounter

## Asset Pipeline Complete
All models are game-ready glTF 2.0 format
Ready for Godot 4 integration
"""

    manifest_file = OUTPUT_DIR / "MANIFEST.md"
    manifest_file.write_text(manifest)
    print(f"\n✓ Manifest created: {manifest_file}")

def main():
    """Main pipeline"""
    print("\n" + "#"*60)
    print("# MediShift Asset Pipeline - Starting")
    print("#"*60)

    try:
        process_hanuman()
        process_demon_guards()
        process_boss()
        create_manifest()

        print("\n" + "#"*60)
        print("# ✅ ASSET PIPELINE COMPLETE")
        print("#"*60)
        print(f"\nProcessed assets in: {OUTPUT_DIR}")
        print("Ready for Godot integration!")

    except Exception as e:
        print(f"\n❌ ERROR: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()
