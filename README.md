# Glow Grid

**The satisfying neon block puzzle for Android.**
Made with Godot Engine 4.7. Free, offline, no ads, no sign-up.

| | |
|---|---|
| Version | 1.0 (version code 1) |
| Platform | Android 7.0 and above |
| Google Play | Under process |
| Package name | `com.hex.glowgrid` |

---

## About the game

Drag the 3 blocks onto the 8×8 grid. Fill a full **row** or **column** and it bursts.
When none of your blocks fit anywhere, the game is over. Try to beat your best score.

It's easy to learn, relaxing because there's no timer, and hard to put down.

## Features

- **Placement preview:** a ghost shows where the block will land, and lines about to clear glow in advance
- **Satisfying clears:** a ripple wave, particle bursts, screen shake, a flash and vibration
- **Combos:** chimes rise in pitch as your combo grows
- **Praise pop-ups:** Nice!, Great!, Excellent!, Amazing!, Incredible! and LEGENDARY!
- **PERFECT! bonus:** +300 for clearing the whole board
- **NEW BEST celebration** when you beat your high score
- **Grey blocks** show which pieces can't fit anywhere
- **Auto-save:** close the app and tap CONTINUE later
- **Pause menu** with sound and vibration on/off
- **Android back button** support
- **Works fully offline** and collects no data

## How to play

1. Press **PLAY**.
2. Drag a block from the tray onto the grid.
3. Fill complete rows or columns to clear them and score points.
4. Clear lines on consecutive moves to build a **combo**.
5. When no block fits, the game ends.

## Scoring

| Action | Points |
|---|---|
| Place a block | +1 per square |
| Clear lines at once (L lines) | 10 × L × (L+1) ÷ 2 |
| Combo | line points × combo number |
| Clear the whole board | +300 bonus |

The combo grows each time a move clears a line. It survives up to 2 moves without a clear in between.

## Project structure

```
project.godot        Project settings (portrait 720×1280, GL Compatibility)
export_presets.cfg   Android export presets (debug APK + release AAB)
build_release.sh     One command to build the signed Play Store bundle
icon.svg             App icon

scenes/
  main.tscn          Main scene

scripts/
  main.gd            Game controller: input, scoring, menus, save/resume
  board.gd           8×8 grid logic, preview and clear animations
  piece.gd           Draggable block piece
  shapes.gd          Block shapes, colours, drawing, font
  fx.gd              Particles and floating text
  bg.gd              Animated background
  sfx.gd             Sound and vibration (autoload)

assets/
  fonts/             Fredoka font + licence
  sfx/               Sound effects (made for this game)
  icons/             Android launcher icons

store/               Play Store listing images (icon, feature graphic, screenshots)
tests/               Developer test scenes (not included in the app)
```

## Requirements to build

- Godot Engine 4.7.2
- Godot 4.7.2 export templates
- Android SDK (platform-tools, build-tools 36, platform 36)
- JDK 17

## Run on PC

```
godot4 --path .
```

## Build a debug APK (for testing on a phone)

```
godot4 --headless --path . --export-debug Android build/GlowGrid-debug.apk
```

## Build the release AAB (for Google Play)

1. Put the release keystore in the `keystore/` folder (it is not in git).
2. Increase `version/code` in `export_presets.cfg` for every new upload.
3. Run:

```
./build_release.sh
```

The signed bundle is created at `build/GlowGrid-release.aab`.

> The keystore and its password are private. They are listed in `.gitignore` and must never be committed or shared.

## Release status

| Step | Status |
|---|---|
| Game development | Done |
| Testing on PC | Done |
| Signed release AAB | Done |
| Store listing images | Done |
| Google Play upload | Under process |
| Privacy policy page | Under process |
| Public release | Under process |

## Credits

- Game design and code: Glow Grid team
- Engine: Godot Engine (MIT licence)
- Font: Fredoka (SIL Open Font License 1.1)
- Sound effects: created for this game

## Licence

All rights reserved © 2026 Glow Grid.
