# Ramayana Quest - Development Quick Start

## Project Setup

1. **Clone Repository**
   ```
   git clone [repo-url]
   cd MediShift
   ```

2. **Open in Godot 4.7**
   - Open Godot Project Manager
   - Click "Import" and select project.godot
   - Engine should be Godot 4.7

3. **Run Game**
   - Press F5 or click "Run" button
   - Game starts with main scene (game_main.tscn)

## Key Shortcuts

- **F5**: Run game
- **F6**: Run current scene
- **Ctrl+D**: Debug print selected node
- **SPACE** (in-game): Call for help (Rama action)
- **ESC** (in-game): Pause game
- **WASD**: Move Rama
- **Mouse**: Look around
- **Shift**: Dash/run

## Common Tasks

### Add New NPC
1. Create scene extending CharacterBody3D
2. Add Model (Node3D) child
3. Add AnimationPlayer child
4. Add CollisionShape3D
5. Attach script extending HanumanAI or MonkeyNPC
6. Instantiate in scene with add_child()

### Add New Dialogue
```gdscript
var dialogue_lines = [
    ["Speaker: Message text", duration],
    ["Speaker: Next message", duration]
]
for line in dialogue_lines:
    _show_hud_message(line[0])
    await get_tree().create_timer(line[1]).timeout
```

### Add New Quest
```gdscript
var quest = SimpleQuestSystem.Quest.new(
    "quest_id",
    "Quest Title",
    "Quest Description",
    ["Objective 1", "Objective 2"]
)
quest.reward = 100
quests.quests["quest_id"] = quest
```

### Add New Stage
1. Add to GameProgression enum
2. Add to match statement in get_stage_name()
3. Add progression logic in advance_stage()

### Create Animation
1. Use Mixamo or similar for animations
2. Export as GLB file
3. Place in assets/animations/humanoid/
4. Update CharacterAnimationSetup.ANIMATION_PATHS
5. Load via CharacterAnimationSetup.load_animations_for_player()

### Test Character
1. Open scenes3d/tools/character_showcase.tscn
2. Drag character model into scene
3. Press F6 to test with animations loaded

## File Structure Reference

```
scripts3d/
├── core/              # GameController, Bootstrapper
├── managers/          # Scene managers
├── player/            # Player character
├── npcs/              # NPC characters
├── systems/           # Game systems
├── utils/             # Helper utilities
└── ui/                # UI components
```

## Debug Commands

Toggle debug label visibility:
```gdscript
if debug_label:
    debug_label.visible = !debug_label.visible
```

Print character state:
```gdscript
print("Rama: ", rama.global_position)
print("Hanuman: ", hanuman.global_position)
print("Distance: ", rama.global_position.distance_to(hanuman.global_position))
print("State: ", HanumanAI.State.keys()[hanuman.current_state])
```

## Performance Tips

1. **Use Object Pooling**: Reuse spawned monkeys
2. **Limit Particles**: Cap effects in EffectSpawner
3. **LOD for Models**: Use simpler models at distance
4. **Cache References**: Store _onready nodes at start
5. **Profile with Debugger**: Use Godot's built-in profiler

## Common Issues

**Problem**: Game won't compile
- Check syntax with Ctrl+Shift+S
- Verify all class_name declarations
- Ensure all signal connections are valid

**Problem**: Character moves through floor
- Ensure CollisionShape3D has proper shape (CapsuleShape3D)
- Check collision layer/mask settings
- Verify is_on_floor() returns true on ground

**Problem**: Animations don't play
- Check AnimationPlayer has animation library
- Verify animation names match in aliases
- Check animation file exists and loads

**Problem**: Hanuman doesn't approach
- Check hearing_range is large enough (default 50.0)
- Verify approach_distance is reasonable (default 5.5)
- Ensure Rama's call_intensity >= curiosity_threshold (0.7)

## Building for Web

1. Set up web export template in Godot
2. Project > Export > Add HTML5 template
3. Configure export settings
4. Export to HTML5 format
5. Test locally with python -m http.server

## Version Control

```bash
# Check status
git status

# Commit changes
git add -A
git commit -m "Your message"

# Push to remote
git push origin claude/ramayana-game-project-iiel8g
```

## Resources

- Animation Library: Mixamo (free animations)
- Model Library: Sketchfab, Quaternius
- Godot Docs: https://docs.godotengine.org/
- GDScript Reference: https://docs.godotengine.org/en/stable/getting_started/scripting/gdscript/

## Support

For issues or questions:
1. Check GAME_ARCHITECTURE.md for system details
2. Review existing code examples in scripts3d/
3. Check Godot console for error messages
4. Verify file paths and resource references
