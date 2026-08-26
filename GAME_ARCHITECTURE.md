# Ramayana Quest - Game Architecture

## Core Systems

### GameController (scripts3d/core/GameController.gd)
Central hub managing all game systems:
- Progression tracking
- Tutorial system
- Quest management
- Save/load functionality
- Event bus
- Input handling
- Game state (running, paused, score, playtime)

### Bootstrapper (scripts3d/core/Bootstrapper.gd)
Initializes game on startup:
- Creates GameController
- Loads main scene
- Starts game flow

## Character Systems

### RamaController (scripts3d/player/RamaController.gd)
Player character with:
- Movement via WASD + mouse camera
- Inventory system
- Call for Sita action (SPACE)
- Animation state machine
- Skin coloring via HanumanBuildEnhancer

### HanumanAI (scripts3d/npcs/HanumanAI.gd)
Hanuman NPC with AI behavior:
- 6 behavioral states (IDLE, FORAGING, CURIOUS, APPROACHING, MEETING, FOLLOWING)
- Hearing range detection
- Approach distance management
- Muscular build and Gada weapon
- Follows Rama after meeting

## Game Flow

### ForestManager (scripts3d/managers/ForestManager.gd)
Manages Chapter 1 gameplay:
- Handles Rama-Hanuman meeting
- Triggers dialogue sequences
- Spawns monkey team via MonkeySpawner
- Tracks progression

### MonkeySpawner (scripts3d/systems/MonkeySpawner.gd)
Spawns and manages monkey NPCs:
- Spawns monkeys after meeting Hanuman
- Manages team roster
- Signals when team is complete

### LocationManager (scripts3d/managers/LocationManager.gd)
Simple location tracking:
- Forest, Coast, Village locations
- Current location tracking
- Location switching

## Systems

### GameProgression (scripts3d/systems/GameProgression.gd)
Tracks game stages:
- MEET_HANUMAN → GATHER_MONKEYS → TRAVEL_TO_COAST → CROSS_OCEAN → BATTLE_RAVANA → RESCUE_SITA → COMPLETE
- Provides stage names and descriptions
- Progress percentage calculation

### DialogueManager (scripts3d/systems/DialogueManager.gd)
Manages dialogue sequences:
- Text display callbacks
- Duration management
- Sequential line delivery

### TutorialManager (scripts3d/systems/TutorialManager.gd)
Step-by-step tutorial:
- 8 tutorial stages
- Contextual hints
- Completion tracking

### SimpleQuestSystem (scripts3d/systems/SimpleQuestSystem.gd)
Quest tracking and management:
- Multiple quests with objectives
- Reward system
- Active quest tracking

### CharacterAnimationSetup (scripts3d/utils/CharacterAnimationSetup.gd)
Animation loading system:
- Loads GLB animation files
- Handles animation retargeting
- Supports animation aliasing (idle, walk, run, etc.)

### HanumanBuildEnhancer (scripts3d/utils/HanumanBuildEnhancer.gd)
Procedural character enhancement:
- Muscular build via bone scaling
- Procedural Gada (mace) generation
- Dhoti garment creation
- Skin color application

### AnimationStateMachine (scripts3d/utils/AnimationStateMachine.gd)
Cleaner animation management:
- State-based animation playback
- Animation aliasing
- State callbacks

## Effects & Environment

### EffectSpawner (scripts3d/systems/EffectSpawner.gd)
Visual effects:
- Dust particles
- Highlight effects
- Floating text

### CameraController (scripts3d/systems/CameraController.gd)
Dynamic camera system:
- Third-person camera
- Pitch/yaw control
- Distance and height management

## Input & UI

### InputHandler (scripts3d/systems/InputHandler.gd)
Centralized input management:
- Movement input
- Action signals
- Pause toggling

### HUDSystem (scripts3d/systems/HUDSystem.gd)
HUD management:
- Messages display
- Objective tracking
- Inventory display
- Progress bar
- Debug information

### MainMenu (scripts3d/ui/MainMenu.gd)
Game start menu

### PauseMenu (scripts3d/ui/PauseMenu.gd)
In-game pause menu

### UIHelper (scripts3d/ui/UIHelper.gd)
UI component utilities

## Combat

### SimpleCombat (scripts3d/systems/SimpleCombat.gd)
Basic combat mechanics:
- Combatant class with health/attack/defense
- Damage calculation
- Combat state tracking

## Utility

### EventBus (scripts3d/systems/EventBus.gd)
Decoupled event system:
- Emit events
- Connect to events
- Clear events

### SaveManager (scripts3d/systems/SaveManager.gd)
Save/load functionality:
- File-based persistence
- Multiple save slots
- Game state serialization

### AIBehavior (scripts3d/systems/AIBehavior.gd)
Generic AI system:
- Patrol, follow, attack behaviors
- State transitions
- Waypoint navigation

## Asset Structure

- scripts3d/: All gameplay scripts
  - core/: GameController, Bootstrapper
  - managers/: ForestManager, LocationManager, GameManager
  - player/: RamaController
  - npcs/: HanumanAI, MonkeyNPC
  - systems/: All game systems
  - utils/: Helpers and utilities
  - ui/: UI components

- scenes3d/: Scene files
  - chapters/: Chapter scenes (game_main.tscn)
  - characters/: Character scenes
  - npcs/: NPC scenes
  - enemies/: Enemy scenes
  - items/: Item scenes
  - effects/: Effect scenes

- assets/: Art and audio
  - animations/: GLB animation files
  - models/: Character and object models
  - sounds/: Audio files

## Key Features

1. **Modular Design**: Each system is independent and can be tested/modified separately
2. **Signal-Based Communication**: Systems use Godot signals for loose coupling
3. **Animation System**: Flexible animation loading with retargeting support
4. **Procedural Character Building**: Muscular builds, weapons, and clothing generated at runtime
5. **State Machines**: Both character and gameplay state management
6. **Progression Tracking**: Multi-stage game progression with clear objectives
7. **Extensible UI**: Modular UI components for easy customization

## Gameplay Flow

1. Game starts via Bootstrapper
2. GameController initializes all systems
3. Main scene loads (game_main.tscn)
4. ForestManager handles Chapter 1:
   - Rama searches for help
   - Player calls for help (SPACE)
   - Hanuman hears call and becomes curious
   - Hanuman approaches and meets Rama
   - Dialogue reveals quest
   - Hanuman agrees to help
   - Monkey team spawns and joins
   - Stage progression advances

## Extending the Game

To add new chapters:
1. Create new scene in scenes3d/chapters/
2. Add manager script (e.g., Chapter2Manager)
3. Add stage to GameProgression enum
4. Connect progression events to scene transitions
5. Add quests to SimpleQuestSystem

To add new NPCs:
1. Create character scene with animations
2. Extend MonkeyNPC or create new NPC class
3. Add to spawner or scene
4. Integrate with dialogue/quest systems
