# The Ramayana 3D Game - Complete Guide

## Overview
A fully functional 3D game adaptation of the Hindu epic Ramayana, developed in Godot 4.7. The game follows Rama's journey to rescue his wife Sita from the demon king Ravana across 6 chapters.

## Game Chapters

### Chapter 1: Forest Meeting (game_main.tscn)
- **Objective**: Meet Hanuman and gain his assistance
- **Location**: Dense forest with procedurally generated trees
- **Systems**: 
  - Rama controlled by player (WASD movement + mouse camera)
  - Hanuman AI pathfinding and dialogue
  - Monkey spawning system
  - Quest tracking
  - HUD with inventory and objectives

### Chapter 2: Gathering Allies (chapter_2_gathering.tscn)
- **Objective**: Recruit 5 monkey warriors
- **Location**: Sparse forest with scattered monkeys
- **Systems**:
  - Enemy encounters (forest demons)
  - Combat encounters
  - Monkey recruitment quests

### Chapter 3: Journey to Coast (chapter_3_coast.tscn)
- **Objective**: Navigate to the ocean shore
- **Location**: Coastal terrain with sand and water
- **Systems**:
  - Waypoint-based progression
  - Environmental variety
  - Direction guidance from Hanuman

### Chapter 4: Ocean Crossing (chapter_4_ocean.tscn)
- **Objective**: Cross the ocean to reach Lanka
- **Location**: Vast ocean with islands
- **Systems**:
  - Bridge-building narrative
  - Hanuman's leap demonstration
  - Ocean environment with waves

### Chapter 5: Battle of Lanka (chapter_5_fortress.tscn)
- **Objective**: Defeat Ravana
- **Location**: Ravana's fortress with multiple towers
- **Systems**:
  - Combat engine with turn-based battles
  - Multiple enemy types (demons, guards, commanders)
  - Boss battle mechanics
  - Visual effects and lighting

### Chapter 6: Rescue and Return (chapter_6_rescue.tscn)
- **Objective**: Rescue Sita and complete the quest
- **Location**: Ravana's throne room
- **Systems**:
  - Reunion dialogue sequences
  - Game completion tracking
  - Ending cinematics

## Core Systems

### Character System
- **Rama (Player)**: 
  - Movement: 5.0 walk speed, 9.0 run speed
  - Abilities: Call for Sita (Press SPACE), Jump (Press W+SPACE)
  - Inventory system for tracking collected items

- **Hanuman (NPC)**:
  - States: IDLE, FORAGING, CURIOUS, APPROACHING, MEETING, FOLLOWING
  - AI pathfinding with approach distance = 5.5
  - Meeting dialogue triggers at 5.5m distance
  - Becomes follower after agreement

- **Monkeys**:
  - States: IDLE, PLAYING, EATING, CLIMBING, EXPLORING, RESTING
  - Procedurally varied activities
  - Team recruitment mechanic

### Combat Engine
```
Turn-based combat with:
- Character stats: health, attack, defense, speed, level
- Damage calculation: (attacker.attack - defender.defense) * random(0.8-1.2)
- 5 enemy types with stat variations:
  * FOREST_DEMON: health=30, attack=5
  * SEA_DEMON: health=45, attack=8
  * LANKA_GUARD: health=60, attack=12
  * RAVANA_COMMANDER: health=80, attack=15
  * RAVANA_BOSS: health=200, attack=25
```

### Environment System (EnvironmentBuilder)
- **Forest**: 50 trees with collision, procedurally placed
- **Coast**: Sand plane (50x30) + water plane + trees
- **Ocean**: Water plane (300x300) + islands with trees
- **Fortress**: Central tower + side towers + walls + main hall

### Lighting System (LightingSetup)
- **Forest**: Directional sun (-45°, 45°), energy 1.2, with sky environment
- **Coast**: Directional sun (-60°, 45°), energy 1.5, bright ambient
- **Ocean**: Directional sun (-50°, 30°), energy 1.3, with fog
- **Fortress**: Dark theme with torch lighting (1000K color) and torches at 2000K
- **Throne Room**: Central spotlight + ambient low light

### Progression System (GameProgression)
8 stages:
1. MEET_HANUMAN - Meet and convince Hanuman
2. MONKEYS_GATHERED - Recruit 5 monkey allies
3. TRAVEL_TO_COAST - Journey to ocean shore
4. OCEAN_CROSSING - Build and cross bridge
5. BATTLE_RAVANA - Defeat Ravana in combat
6. RESCUE_SITA - Rescue Sita from throne room
7. RETURN_HOME - Journey back to Ayodhya
8. COMPLETE - Game finished

### HUD System (EnhancedHUD)
Displays:
- Main message (center, large text)
- Objectives (top center)
- Inventory (top right)
- Health bar (top left)
- Progress bar (top left, below health)
- Chapter name (top center)
- Distance/ETA to target (bottom left)
- FPS/Debug info (top left corner)

### Animation System (CharacterAnimationSetup)
- Loads animations from GLB files
- State-based animation switching
- Supports: idle, walk, run, call, fight

### Scene Transition (SceneTransition)
- Fade to black over 1 second
- Load new scene
- Fade from black over 1 second
- Static method: `SceneTransition.fade_to_scene(caller_node, "path/to/scene.tscn")`

## File Structure

```
scripts3d/
├── core/
│   ├── GameController.gd (central game manager)
│   ├── GameBootstrap.gd (initialization)
│   └── Bootstrapper.gd (entry point)
├── managers/
│   ├── ForestManager.gd (Chapter 1)
│   ├── Chapter2Manager.gd (Chapter 2)
│   ├── Chapter3Manager.gd (Chapter 3)
│   ├── Chapter4OceanManager.gd (Chapter 4)
│   ├── Chapter5Manager.gd (Chapter 5)
│   ├── Chapter6Manager.gd (Chapter 6)
│   └── LocationManager.gd (location tracking)
├── npcs/
│   ├── HanumanAI.gd (Hanuman NPC with 6-state AI)
│   └── MonkeyNPC.gd (Generic monkey with 6 states)
├── player/
│   └── RamaController.gd (player character controller)
├── systems/
│   ├── AnimationStateMachine.gd (animation management)
│   ├── CameraController.gd (third-person camera)
│   ├── CombatEngine.gd (turn-based combat)
│   ├── EffectSpawner.gd (visual effects)
│   ├── EnemyFactory.gd (enemy spawning)
│   ├── EnvironmentBuilder.gd (procedural environments)
│   ├── EventBus.gd (event system)
│   ├── InputHandler.gd (input management)
│   ├── LightingSetup.gd (lighting for each scene)
│   ├── MonkeySpawner.gd (monkey team recruitment)
│   ├── ParticleEffects.gd (dust, hits, victory effects)
│   ├── QuestSystem.gd (quest tracking)
│   ├── SaveManager.gd (save/load persistence)
│   ├── SceneTransition.gd (fade transitions)
│   └── TutorialManager.gd (8-step tutorial)
├── ui/
│   ├── EnhancedHUD.gd (main HUD display)
│   ├── MainMenu.gd (menu system)
│   ├── PauseMenu.gd (pause functionality)
│   └── UIHelper.gd (UI utilities)
└── utils/
    ├── CharacterAnimationSetup.gd (animation loading)
    ├── HanumanBuildEnhancer.gd (procedural character building)
    └── AIBehavior.gd (generic NPC pathfinding)

scenes3d/
├── chapters/
│   ├── game_main.tscn (Chapter 1: Forest)
│   ├── chapter_2_gathering.tscn (Chapter 2: Gathering)
│   ├── chapter_3_coast.tscn (Chapter 3: Coast)
│   ├── chapter_4_ocean.tscn (Chapter 4: Ocean)
│   ├── chapter_5_fortress.tscn (Chapter 5: Fortress)
│   └── chapter_6_rescue.tscn (Chapter 6: Throne Room)
├── characters/
│   ├── rama_3d.tscn
│   └── hanuman_3d.tscn
├── npcs/
│   └── monkey_npc_3d.tscn
└── menu/
    └── main_menu.tscn
```

## Controls

### Player Controls (Rama)
- **WASD**: Move forward/backward/strafe left/right
- **Mouse**: Look around (camera control)
- **SPACE**: Call for Sita / Jump
- **SHIFT**: Run (hold while moving)
- **ESC**: Pause game

### Development Controls
- **ESC**: Show debug info (distance, ETA, AI state)
- Can be extended in RamaController._process()

## Key Gameplay Mechanics

### Calling System
- Rama can call for Sita (cooldown: 5 seconds)
- Call intensity: 0.8-1.0 (random)
- Hanuman hears call if within 50m AND intensity >= 0.7

### Meeting Mechanics
- Hanuman approaches when curious
- Meeting triggered when distance < 5.5m
- Dialogue plays out with 3.5-second delay
- Agreement signal triggers state progression

### Combat Mechanics
- Turn-based combat starts when enemy encountered
- Damage = (attack - defense) * random(0.8-1.2)
- Defense reduces damage taken
- Speed determines turn order
- Battle ends when one side health reaches 0

### Progression Mechanics
- Game tracks current stage (1-8)
- Each chapter advances stage on completion
- Quests link to stage progression
- Save system persists progression

## Adding New Content

### Create New Chapter
1. Create new manager script inheriting from Node3D:
```gdscript
extends Node3D
class_name ChapterXManager

func _ready() -> void:
    _create_environment()
    progression = GameProgression.new()
    add_child(progression)
```

2. Create scene file with required nodes:
   - Environment
   - Characters
   - HUD (with MainLabel, ObjectiveLabel)
   - Any chapter-specific nodes

3. Add environment creation:
```gdscript
func _create_environment() -> void:
    var env = Node3D.new()
    env.name = "Environment"
    add_child(env)
    EnvironmentBuilder.create_TYPE_environment(env)
    LightingSetup.setup_TYPE_lighting(env)
```

4. Register in GameController or chapter managers

### Create New Enemy Type
Add to EnemyFactory.gd:
```gdscript
var CUSTOM_ENEMY = {
    "health": 100,
    "attack": 10,
    "defense": 5,
    "speed": 8
}
```

### Create New NPC
1. Create script inheriting CharacterBody3D
2. Implement state machine and behaviors
3. Add to scene
4. Connect signals to manager

## Performance Considerations

- **Tree LOD**: Distance-based rendering of trees
- **Monkey Spawning**: Limited to 5 active monkeys per chapter
- **Particle Limits**: 30 particles max per effect
- **Light Count**: 2-4 lights per scene (directional + omni)
- **Physics**: Simplified collision shapes for NPCs

## Asset Pipeline

### Character Models
- Using hanuman_final.glb for base character
- Procedural mesh generation for weapons/accessories
- StandardMaterial3D with albedo color overrides for skin tones

### Animations
- Loaded from GLB files on demand
- Retargeted to character skeletons
- 6 core animations: idle, walk, run, call, fight, jump

### Textures
- Procedural noise for terrain/trees
- Color-based materials for simplicity
- No external texture dependencies

## Game Balance

### Difficulty Curve
- Ch. 1: Introduction, no combat
- Ch. 2: Light demons (health 30, attack 5)
- Ch. 3: Travel only, no combat
- Ch. 4: Narrative focus, no combat
- Ch. 5: Boss battles (Ravana health 200)
- Ch. 6: Final story sequence

### Player Stats (by default)
- Rama max health: 150
- Hanuman max health: 120
- Default attack: 20
- Default defense: 10

## Debugging

Enable debug output:
- Press ESC in-game to show distance/ETA/AI state
- Console prints show progression stages
- Check debug_label in HUD for FPS and positions

## Future Enhancements

1. **Voice Acting**: Integrate dialogue voice lines
2. **Cinematics**: Camera-based cutscenes for story beats
3. **Side Quests**: Optional encounters for progression
4. **Multiple Endings**: Dialogue choices affecting outcome
5. **Multiplayer**: Cooperative mode for team actions
6. **Mobile Support**: Touch-based controls
7. **Achievements**: Milestone tracking system
8. **High Scores**: Leaderboard for completion time
