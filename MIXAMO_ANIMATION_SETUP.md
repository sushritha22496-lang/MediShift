# 🎬 MIXAMO ANIMATION SETUP GUIDE

## Free Animations for Ramayana Game

### How to Download from Mixamo

1. **Create Free Account**
   - Visit: https://www.mixamo.com
   - Sign up with Adobe ID (free)

2. **Search & Download Animations**
   - Download the following animations as **FBX** format
   - Settings: 60fps, Without Skin

### Required Animations for Characters

#### RAMA (Player Character)
1. **Idle** - Search: "Idle" → Download "Idle (2)"
2. **Walk** - Search: "Walk" → Download "Walk Forward"
3. **Run** - Search: "Run" → Download "Run Forward"
4. **Jump** - Search: "Jump" → Download "Jump"
5. **Attack** - Search: "Attack" → Download "Sword Attack"
6. **Celebration** - Search: "Celebration" → Download "Victory"

#### HANUMAN (Main NPC)
- Same as Rama (12 animations total)

#### MONKEY SCOUTS (5 NPCs)
- Same set as Rama

#### SCOUT NPCs (3 NPCs)
- Same set as Rama

### File Organization

```
res://assets/animations/
├── rama/
│   ├── idle.fbx
│   ├── walk.fbx
│   ├── run.fbx
│   ├── jump.fbx
│   ├── attack.fbx
│   └── celebration.fbx
├── hanuman/
│   └── [same files]
├── monkey/
│   └── [same files]
└── scout/
    └── [same files]
```

### Godot Import Settings

For each FBX file:
1. Import as: Skeletal Animation
2. Reimport after placing in assets folder
3. Use in AnimationPlayer nodes

### Alternative: Use Pre-converted GLB Files

If you have animation GLB files from Phase 6:
- `hanuman_final_animations.glb`
- `demon_demon_blue_animations.glb`

These contain multiple animations and can be used directly.
