#!/usr/bin/env python3
"""
MediShift Ramayana Character Creator
Extends the asset pipeline to create all main Ramayana characters
Run: blender -b -P blender_ramayana_characters.py
"""

import bpy
from pathlib import Path

ASSETS_DIR = Path(__file__).parent / "assets" / "models"
CHARACTERS_DIR = ASSETS_DIR / "characters"
OUTPUT_DIR = CHARACTERS_DIR / "processed"

OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

def clear_scene():
    for obj in bpy.data.objects:
        bpy.data.objects.remove(obj, do_unlink=True)

def import_model(filepath):
    print(f"\n📥 Importing: {filepath.name}")
    bpy.ops.import_scene.gltf(filepath=str(filepath))

def apply_color_and_scale(name, color_rgb, scale):
    """Apply color and scale to all mesh objects"""
    for obj in bpy.context.selected_objects:
        if obj.type == 'MESH' and obj.data:
            print(f"🎨 {name}: Color {color_rgb} + Scale {scale}x")
            mat = bpy.data.materials.new(name=f"{name}_mat")
            mat.use_nodes = True
            mat.diffuse_color = (*color_rgb, 1.0)
            if obj.data.materials:
                obj.data.materials[0] = mat
            else:
                obj.data.materials.append(mat)
            obj.scale = (scale, scale, scale)

def export_character(name):
    """Export selected object as glTF"""
    root = bpy.context.selected_objects[0]
    filepath = str(OUTPUT_DIR / f"{name}.glb")
    print(f"📤 Exporting: {name}")
    bpy.ops.export_scene.gltf(filepath=filepath)
    return filepath

def create_rama():
    """Rama - Blue warrior protagonist"""
    print("\n" + "="*60)
    print("🟦 CREATING RAMA - Blue Warrior")
    print("="*60)
    clear_scene()
    import_model(CHARACTERS_DIR / "player_base.glb")
    apply_color_and_scale("Rama", (0.2, 0.5, 0.9), 1.0)  # Blue
    export_character("rama")

def create_sita():
    """Sita - Female divine protagonist"""
    print("\n" + "="*60)
    print("👸 CREATING SITA - Divine Heroine")
    print("="*60)
    clear_scene()
    # Use player model as base, scale down slightly for feminine form
    import_model(CHARACTERS_DIR / "player_base.glb")
    apply_color_and_scale("Sita", (0.95, 0.85, 0.7), 0.85)  # Golden
    export_character("sita")

def create_lakshman():
    """Lakshman - Green warrior, Rama's brother"""
    print("\n" + "="*60)
    print("🟩 CREATING LAKSHMAN - Green Warrior")
    print("="*60)
    clear_scene()
    import_model(CHARACTERS_DIR / "enemy_base.glb")
    apply_color_and_scale("Lakshman", (0.2, 0.7, 0.3), 0.95)  # Green
    export_character("lakshman")

def create_vali():
    """Vali - Monkey king, imposing leader"""
    print("\n" + "="*60)
    print("🐵 CREATING VALI - Monkey King")
    print("="*60)
    clear_scene()
    import_model(CHARACTERS_DIR / "robot.glb")
    apply_color_and_scale("Vali", (0.7, 0.5, 0.3), 1.3)  # Brown, larger
    export_character("vali")

def create_sugreeva():
    """Sugreeva - Monkey warrior, Vali's brother"""
    print("\n" + "="*60)
    print("🐒 CREATING SUGREEVA - Monkey Warrior")
    print("="*60)
    clear_scene()
    import_model(CHARACTERS_DIR / "mob_base.glb")
    apply_color_and_scale("Sugreeva", (0.8, 0.6, 0.4), 1.0)  # Tan monkey
    export_character("sugreeva")

def create_jatayu():
    """Jatayu - Eagle/Vulture warrior"""
    print("\n" + "="*60)
    print("🦅 CREATING JATAYU - Eagle Warrior")
    print("="*60)
    clear_scene()
    # Using mob as base since we don't have bird models yet
    import_model(CHARACTERS_DIR / "mob_base.glb")
    apply_color_and_scale("Jatayu", (0.8, 0.4, 0.1), 1.2)  # Golden eagle
    export_character("jatayu")

def create_vibhishana():
    """Vibhishana - Righteous demon brother of Ravana"""
    print("\n" + "="*60)
    print("👹 CREATING VIBHISHANA - Righteous Demon")
    print("="*60)
    clear_scene()
    import_model(CHARACTERS_DIR / "enemy_base.glb")
    apply_color_and_scale("Vibhishana", (0.9, 0.8, 0.3), 1.0)  # Golden demon
    export_character("vibhishana")

def create_kumbhakarna():
    """Kumbhakarna - Giant demon, Ravana's brother"""
    print("\n" + "="*60)
    print("👹 CREATING KUMBHAKARNA - Giant Demon")
    print("="*60)
    clear_scene()
    import_model(CHARACTERS_DIR / "robot.glb")
    apply_color_and_scale("Kumbhakarna", (0.4, 0.2, 0.1), 3.0)  # GIANT
    export_character("kumbhakarna")

def create_indrajit():
    """Indrajit - Ravana's powerful son"""
    print("\n" + "="*60)
    print("👹 CREATING INDRAJIT - Ravana's Son")
    print("="*60)
    clear_scene()
    import_model(CHARACTERS_DIR / "enemy_base.glb")
    apply_color_and_scale("Indrajit", (0.3, 0.1, 0.4), 1.05)  # Dark purple demon
    export_character("indrajit")

def create_ravana_upgraded():
    """Ravana - Dark lord, ultimate boss (upgraded version)"""
    print("\n" + "="*60)
    print("👹 CREATING RAVANA - DARK LORD BOSS")
    print("="*60)
    clear_scene()
    import_model(CHARACTERS_DIR / "processed" / "dundhubi_boss.glb")
    apply_color_and_scale("Ravana", (0.2, 0.05, 0.05), 2.5)  # Even darker
    export_character("ravana_boss")

def create_monkey_variants():
    """Create 3 monkey soldier variants"""
    print("\n" + "="*60)
    print("🐵 CREATING MONKEY SOLDIER VARIANTS")
    print("="*60)

    colors = [
        ("Monkey_Gold", (0.95, 0.8, 0.3), 0.9),   # Golden
        ("Monkey_Brown", (0.7, 0.5, 0.3), 1.0),   # Brown
        ("Monkey_Tan", (0.8, 0.6, 0.4), 0.95),    # Tan
    ]

    for name, color, scale in colors:
        clear_scene()
        import_model(CHARACTERS_DIR / "mob_base.glb")
        apply_color_and_scale(name, color, scale)
        export_character(f"monkey_{name.lower()}")

def create_demon_variants():
    """Create additional demon soldier variants"""
    print("\n" + "="*60)
    print("👹 CREATING DEMON VARIANTS")
    print("="*60)

    demons = [
        ("Demon_Blue", (0.2, 0.3, 0.6), 0.95),     # Blue demon
        ("Demon_Green", (0.1, 0.5, 0.2), 1.0),     # Green demon
        ("Demon_Orange", (0.9, 0.4, 0.1), 1.05),   # Orange demon
    ]

    for name, color, scale in demons:
        clear_scene()
        import_model(CHARACTERS_DIR / "enemy_base.glb")
        apply_color_and_scale(name, color, scale)
        export_character(f"demon_{name.lower()}")

def main():
    print("\n" + "#"*60)
    print("# Ramayana Character Creator - Starting")
    print("#"*60)

    try:
        # Main protagonists
        create_rama()
        create_sita()
        create_lakshman()

        # Supporting heroes
        create_vali()
        create_sugreeva()
        create_jatayu()

        # Villains
        create_vibhishana()
        create_indrajit()
        create_kumbhakarna()
        create_ravana_upgraded()

        # Crowd characters
        create_monkey_variants()
        create_demon_variants()

        print("\n" + "#"*60)
        print("# ✅ RAMAYANA CHARACTER SET COMPLETE")
        print("#"*60)
        print(f"\nAll characters in: {OUTPUT_DIR}")
        print(f"Total characters created: 20+")

    except Exception as e:
        print(f"\n❌ ERROR: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()
