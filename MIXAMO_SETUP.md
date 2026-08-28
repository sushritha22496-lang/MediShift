# Mixamo Character Setup Guide

## Overview
This game uses rigged characters from Adobe Mixamo for professional animations. Characters automatically fallback to procedural generation if Mixamo models aren't available.

## Setup Instructions

### 1. Download Characters from Mixamo
Visit https://www.mixamo.com/ and download these models:

#### Rama (Human Warrior)
- Search: "Warrior", "Paladin", or "Knight"
- Recommended: Any humanoid male character with serious/noble appearance
- Format: **FBX** (Autodesk FBX 2020 or later)
- Settings:
  - Skin: Yes
  - Armature: Yes
  - Frames per Second: 60

#### Hanuman (Monkey Warrior)
- Search: "Monkey", "Primate", "Chimpanzee"
- Recommended: Muscular, powerful appearance
- Format: **FBX** (Autodesk FBX 2020 or later)
- Settings: Same as above

#### Monkey NPCs (Warrior)
- Search: "Monkey", "Primate", "Jungle warrior"
- Recommended: Medium build, battle-ready
- Format: **FBX** (Autodesk FBX 2020 or later)
- Settings: Same as above

### 2. Rename Downloaded Files
After download, rename to:
```
rama_rigged.fbx          → assets/characters/rama_rigged.fbx
hanuman_rigged.fbx       → assets/characters/hanuman_rigged.fbx
monkey_warrior_rigged.fbx → assets/characters/monkey_warrior_rigged.fbx
```

### 3. Create Directory Structure
```bash
mkdir -p assets/characters
```

### 4. Import to Godot
- Copy FBX files to `assets/characters/`
- Godot will auto-import as scenes
- Animation names will be extracted from Mixamo (e.g., "Idle", "Running", "Attacking")

### 5. Verify Animations
In Godot editor:
1. Open imported FBX scene
2. Check AnimationPlayer node for available animations
3. Verify these states exist (or update ANIMATION_MAP in RiggedCharacterLoader.gd):
   - Idle, Walking, Running
   - Jump, Falling
   - Climbing, Swimming
   - Attacking, Hit, Dying
   - Shouting/Calling

### 6. Test in Game
Run the game. Characters should load with full animation sets.
If Mixamo models missing, procedural ProfessionalCharacterBuilder kicks in automatically.

## Available Mixamo Animations
Each character model includes:
- **Locomotion**: Idle, Walk, Run, Sprint, Strafe
- **Actions**: Jump, Fall, Climb, Swim, Slide
- **Combat**: Attack (various), Hit/Damage, Death animations
- **Expressions**: Gestures, Calling, Emotes
- **Environmental**: Interact with objects, Climbing

## Customization

### Add More Animations
1. Download animation from Mixamo (same skeleton)
2. Import to Godot
3. Add to AnimationPlayer in character scene
4. Update ANIMATION_MAP if using new state names

### Change Character Models
Edit MODEL_PATHS in RiggedCharacterLoader.gd:
```gdscript
const MODEL_PATHS = {
	"rama": "res://assets/characters/rama_rigged.fbx",
	"hanuman": "res://assets/characters/hanuman_rigged.fbx",
	"monkey": "res://assets/characters/monkey_warrior_rigged.fbx"
}
```

## Fallback Behavior
If Mixamo models not found:
- Game logs warning: "Model not found: res://assets/characters/..."
- Character spawns with ProfessionalCharacterBuilder (procedural)
- Game remains playable with limited animations

## Performance Tips
- Mixamo FBX files are already optimized
- Godot compresses animations on import
- Multiple instances of same character share animation data (efficient)
- Consider LOD (level of detail) if 50+ characters on screen

## Troubleshooting

**"Animation 'X' not found"**
- Check Mixamo model has that animation
- Verify ANIMATION_MAP spelling matches Mixamo export name
- Download animation pack from Mixamo for missing actions

**Character doesn't animate**
- Verify AnimationPlayer exists in imported model
- Check character's _physics_process calls RiggedCharacterLoader.play_animation()
- Review Godot console for import errors

**Model looks wrong in Godot**
- Mixamo models may have different scale/rotation
- Adjust in imported scene (right-click → Re-Import with transform adjustments)
- Or scale character node: `character.scale = Vector3(1, 1, 1) * 0.01` (example)

## Next Steps
1. Download characters from Mixamo
2. Place FBX files in `assets/characters/`
3. Run game and verify animations play
4. Add more animation states as needed

---
**Status**: Ready for professional AAA-grade animations once Mixamo models added
