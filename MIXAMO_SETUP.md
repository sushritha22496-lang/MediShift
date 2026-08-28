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
In Godot editor, launch game and check console output:
```
Character loaded with 145 animations: [Idle, Walking, Running, Jump, Dance_001, Dance_002, ...]
```

All animations are **auto-discovered** - no manual mapping needed. The system supports:

## Available Mixamo Animations (100+ per character)
Every animation from Mixamo is accessible - the system auto-discovers them all:

- **Locomotion**: Idle, Walk, Run, Sprint, Strafe, Crouch, Crawl
- **Jumps & Falls**: Jump, Double Jump, Falling, Landing
- **Climbing**: Climbing, Wall Climb, Rope Climb
- **Swimming**: Swimming, Treading Water, Diving
- **Combat**: Attack (20+ variants), Hit, Block, Parry, Death animations
- **Expressions**: Dance (100+ styles), Sing, Chant, Laugh, Cry
- **Gestures**: Point, Salute, Wave, Bow, Kneel, Pray, Meditate
- **Emotes**: Happy, Sad, Angry, Confused, Surprised, Thinking
- **Environmental**: Interact with objects, Pick up, Throw, Push, Pull
- **Special**: Victory, Defeat, Celebrate, Mourn, Sleep

### 6. Test in Game
Run the game. Check console to see all loaded animations:
```
Character loaded with 147 animations: [Idle, Walking, Running, Jumping, Dance_Samba, Dance_Hiphop, Singing, Chanting, ...]
```

All animations accessible via `RiggedCharacterLoader.play_animation(character, "animation_name")`
If Mixamo models missing, procedural ProfessionalCharacterBuilder kicks in automatically.

## Using Animations in Code

### Play Any Animation
```gdscript
# Direct animation name (exact match from Mixamo)
RiggedCharacterLoader.play_animation(character, "Dancing")

# Core action names (auto-mapped)
RiggedCharacterLoader.play_animation(character, "idle")      # Finds "Idle"
RiggedCharacterLoader.play_animation(character, "dance")     # Finds any Dance animation
RiggedCharacterLoader.play_animation(character, "sing")      # Finds "Singing"
RiggedCharacterLoader.play_animation(character, "chant")     # Finds "Chanting"
```

### Get All Available Animations
```gdscript
var all_anims = RiggedCharacterLoader.get_all_animations(character)
print("Available: ", all_anims)  # [Idle, Walking, Running, Dancing, ...]
```

### Play Random Animation
```gdscript
# Random from any animation
var random = RiggedCharacterLoader.random_animation(character)
RiggedCharacterLoader.play_animation(character, random)

# Random filtered by type
var dance = RiggedCharacterLoader.random_animation(character, "dance")
var gesture = RiggedCharacterLoader.random_animation(character, "gesture")
```

### Smart Animation Names
System tries in order:
1. Exact name match: "Running" → plays "Running"
2. Case-insensitive: "running" → plays "Running"
3. Alias lookup: "dance" → tries "Dancing", "Dance", "dance"
4. Partial match: "run" → plays first animation containing "run"

## Customization

### Add More Animations
1. Download animation from Mixamo (same skeleton)
2. Import to Godot (FBX auto-imports)
3. Animation auto-discovered by RiggedCharacterLoader
4. Immediately playable via `play_animation(character, "NewAnimationName")`

### Change Character Models
Edit MODEL_PATHS in RiggedCharacterLoader.gd:
```gdscript
const MODEL_PATHS = {
	"rama": "res://assets/characters/rama_rigged.fbx",
	"hanuman": "res://assets/characters/hanuman_rigged.fbx",
	"monkey": "res://assets/characters/monkey_warrior_rigged.fbx"
}
```

### Add New Animation Aliases
Add to ANIMATION_ALIASES in RiggedCharacterLoader.gd:
```gdscript
const ANIMATION_ALIASES = {
	"meditate": ["Meditating", "Meditation", "Contemplate"],
	"pray": ["Praying", "Prayer", "Kneel Pray"],
	"celebrate": ["Celebrate", "Victory", "Cheer"],
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
