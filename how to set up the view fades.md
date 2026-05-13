# Domain Switch Transition Setup

This document describes the changes made to implement domain switch transitions and the setup required in the scene editor.

## Changes Made

### 1. UIManager (`scenes/master/ui_manager.gd`)
Added two new TextureRect export variables:
- `fade_overlay_node: TextureRect` - For the black fade overlay
- `white_fade_overlay_node: TextureRect` - For the white fade overlay

Added new static methods for fade control:
- `fade_in_black(duration: float = 0.5)` - Fades in black overlay
- `fade_out_black(duration: float = 0.5)` - Fades out black overlay
- `set_black_overlay_opaque()` - Sets black overlay fully opaque instantly
- `set_black_overlay_transparent()` - Sets black overlay fully transparent instantly
- `fade_in_white(duration: float = 0.5)` - Fades in white overlay
- `fade_out_white(duration: float = 0.5)` - Fades out white overlay
- `set_white_overlay_opaque()` - Sets white overlay fully opaque instantly
- `set_white_overlay_transparent()` - Sets white overlay fully transparent instantly

### 2. CharacterAnimation (`scenes/character/character_animation.gd`)
Added new method:
- `play_vr_on_animation()` - Plays the "vr_on" animation on the character

### 3. Level (`scenes/level/level.gd`)
Updated `set_domain_view(use_vr_domain: bool)` to implement full transition sequences:

**When switching TO VR (IRL → VR):**
1. Fades in to black (0.5s)
2. Plays "vr_on" SFX on master channel
3. After 0.5s fade completes, switches to VR domain
4. Plays "vr_on" animation on character
5. Cuts to white overlay at full opacity
6. Fades out white (0.5s), revealing VR view

**When switching TO IRL (VR → IRL):**
1. Cuts to black instantly (overlay at full opacity)
2. Plays "vr_off" SFX on master channel
3. Immediately switches to IRL domain
4. Fades out black (1.0s), revealing IRL view

## Scene Setup Required

In your Master scene (or wherever UIManager is located), you need to:

1. **Ensure UIManager has these TextureRect nodes as children:**
   - One TextureRect for the black fade overlay named something like `FadeOverlay`
   - One TextureRect for the white fade overlay named something like `WhiteFadeOverlay`

2. **Configure the TextureRects:**
   - Set Layout to "Full Rect" so they cover the entire screen
   - Initially set modulate alpha to 0.0 (transparent)
   - Use black and white images/colors for each overlay respectively
   - Set them to be above all other UI elements in layer order

3. **Assign in UIManager inspector:**
   - Drag the black TextureRect to the `fade_overlay_node` export variable
   - Drag the white TextureRect to the `white_fade_overlay_node` export variable

4. **Audio Library:**
   - Ensure your AudioManager has "vr_on" and "vr_off" SFX files in its `sfx_library`

## Notes

- The transitions are now fully asynchronous, using `await` to maintain proper timing
- The character animation reference assumes the character has an `animation_handler` property
- All fade animations use Godot 4's tween system for smooth transitions
- The overlays persist on screen and can be reused for other transitions if needed
