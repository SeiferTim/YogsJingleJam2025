# 🎨 ART TO DO - Yogscast Jingle Jam 2025# Art Assets Needed - Priority Order



**Last Updated:** December 4, 2025## ⚠️ CRITICAL PATH (Game won't work without these)



---### Boss Phase 2 (Bug with Legs) - **~6-8 hours**

- [ ] **Idle stance** - Bug body with 4-6 legs, more upright

## ✅ COMPLETED- [ ] **Charge attack** - Lean forward, legs tensed

- [ ] **Leg sweep** - One or two legs swiping across ground

- [x] Boss Phase 1 (Larva) - All segments, mouth, pincers- [ ] **Spit attack** - Can reuse larva mouth/head if needed

- [x] Boss Phase 1.5 Cocoon (closed egg)- **Dimensions:** Similar to phase 1 (~256x144), legs can extend beyond

- [x] Player sprite

- [x] Mayfly enemy (simple flying bug)### Boss Phase 3 (Winged Final Form) - **~6-8 hours**

- [x] Heart pickup sprite- [ ] **Idle hover** - Wings spread, body elevated

- [x] Ground/arena tiles- [ ] **Dive attack** - Wings pulled back, diving down

- [x] Arrow projectile- [ ] **Wing gust** - Wings flapping to create shockwave

- [ ] **Death animation** (optional) - Collapse/fade

---- **Dimensions:** Larger, ~320x180, wings are main feature



## 🔥 CRITICAL PATH (MUST HAVE)### Boss Phase 1.5 / 2.5 (Cocoon) - **~2 hours**

- [X] **Cocoon closed** - Simple oval/egg shape, pulsing

### Boss Phase 2 Sprites - **~6-8 hours**- **Dimensions:** ~128x96, centered where boss was

**Status:** ❌ NOT STARTED | **Priority:** HIGHEST

## 🔹 HIGH PRIORITY (Needed for core loop)

- [ ] **Idle stance** - Bug with 4-6 legs, upright posture

  - Dimensions: ~256x144, legs extend to ground### Weapon Attack Effects - **~2-3 hours total**

  - Legs should be clearly visible for walking animation

- [ ] **Charge telegraph pose** (OPTIONAL - can use idle + code bounce)#### Sword Slash Effect - `sword-slash.png`

  - Lean forward, legs tensed- **Dimensions:** 20x20 pixels

- [ ] **Spit attack pose** (OPTIONAL - can reuse Phase 1 mouth)- **Animation:** 3-4 frames (optional, can be single frame)

- [ ] **Claw swipe frames** (OPTIONAL - can tween existing arm sprites)- **Direction:** Facing RIGHT (0°) - code will rotate it

- **Design:** Arc/crescent slash effect

**Export:** Individual PNGs per pose (Trim Cels: YES, JSON: NO)  - Frame 1: Slash starts (thin arc)

**Place in:** `assets/images/`  - Frame 2: Mid-slash (wider arc, most visible)

  - Frame 3: Slash ends (fading/dissipating)

---- **Color:** White/light blue energy, semi-transparent

- **Pivot Point:** Center (10, 10) - slash should arc around this point

### Boss Phase 3 Sprites - **~6-8 hours**- **Duration:** Shows for 0.2 seconds

**Status:** ❌ NOT STARTED | **Priority:** HIGH (after Phase 2 works)- **Notes:** This is the visual effect that appears in front of player when they swing. Currently invisible hitbox.



- [ ] **Idle hover** - Wings spread, body elevated#### Halberd Jab Effect - `halberd-jab.png`

  - Dimensions: ~320x180 - WINGS are the main feature- **Dimensions:** 12x12 pixels (or 4x16 elongated)

- [ ] **Dive attack** - Wings pulled back, diving down- **Animation:** Single frame or 2 frames

- [ ] **Wing gust** - Wings spread wide, flapping- **Direction:** Pointing RIGHT (0°) - code will rotate it

- [ ] **Death animation** (OPTIONAL)- **Design:** Quick thrust/stab indicator

  - Sharp point on right edge

**Notes:** Make wings BIG and dramatic - they're the star of Phase 3!  - Could be: Energy burst, weapon tip glow, or motion lines

- **Color:** Yellow/white energy flash

---- **Pivot Point:** Left edge (0, 6) or (0, 8) - spawns 12px from player

- **Duration:** Shows briefly during jab (0.1-0.15 seconds per jab)

## 🟡 HIGH PRIORITY (Needed for Polish)- **Notes:** Player can do 1-5 rapid jabs in sequence. Keep it simple/small.



### Weapon Attack Effects - **~2-3 hours total**#### Magic Ball Projectile - `magic-ball.png`

**Status:** ⚠️ Weapons exist, need visual effects- **Dimensions:** 4x4 pixels

- **Animation:** Optional 2-frame pulse/glow

#### Sword Slash - `sword-slash.png`- **Design:** Glowing cyan/blue orb

- [ ] 20x20 pixels, 3-4 frames (or single frame)  - Frame 1: Slightly smaller, brighter core

- [ ] Arc/crescent slash, semi-transparent white/blue energy  - Frame 2: Slightly larger, dimmer outer glow

- [ ] Direction: Facing RIGHT (code rotates it)  - Should look mystical/arcane

- **Color:** Cyan (#00FFFF) with bright white core

#### Halberd Jab - `halberd-jab.png`- **Notes:** Currently using solid cyan square. This homes toward enemies, so make it look "seeking"

- [ ] 12x12 pixels (or 4x16 elongated)- **Trail Effect (optional):** Could leave faint particle trail (code can do this)

- [ ] Quick thrust indicator, yellow/white energy flash

- [ ] Single frame or 2 frames#### Fireball Projectile - `fireball.png`

- **Dimensions:** 6x6 pixels (scales up to 12x12 when fully charged)

#### Magic Ball - `magic-ball.png`- **Animation:** 2-3 frame flame flicker

- [ ] 4x4 pixels, optional 2-frame pulse/glow- **Design:** Orange/red fireball

- [ ] Cyan/blue orb with bright white core  - Frame 1: Bright orange core, red outer

- [ ] Should look mystical (homes toward enemies)  - Frame 2: Flickering flames

  - Frame 3: Return to frame 1 (loop)

#### Fireball - `fireball.png`- **Color:** Orange (#FF4400) with yellow highlights

- [ ] 6x6 pixels, 2-3 frame flicker- **Notes:** Currently solid orange square. Charge attack scales sprite up, so make sure it looks good at different sizes

- [ ] Orange/red flames with yellow highlights- **Scaling:** Will be shown at 1x, 1.5x, and 2x size

- [ ] Scales to 12x12 when charged

#### Burn Effect (On Enemies) - `burn-particle.png` (OPTIONAL)

---- **Dimensions:** 4x4 pixels

- **Animation:** 3-frame flicker

## 🔵 NICE TO HAVE (Polish)- **Design:** Small flame particle that floats above burning enemy

- **Color:** Orange/red/yellow

### UI Elements - **~2 hours**- **Notes:** Code could spawn 2-3 of these above enemies with burn DOT. Not critical - colored tint might be enough.

- [ ] **Stat icons** (8x8 each): ATK sword, SPD boot, CDN clock

- [ ] **Title screen logo**### Weapons - **~3-4 hours total**

- [ ] **Victory screen art**- [ ] **Sword** - Simple blade, ~16x16, swing animation optional

- [ ] **Magic Wand** - Staff/wand, ~16x16

---- [ ] **Magic Projectile** - Colored orb/bolt, ~8x8

- **Can reuse player sprite**, just draw weapon overlays

## 📐 EXPORT SETTINGS (Aseprite)

### Minor Enemy - Mayfly - **~1 hour**

**CRITICAL:** Follow these to avoid offset bugs!- [X] **Simple flying bug** - ~8x8 or 12x12, 2-frame wing flap

1. File → Export Sprite Sheet- **Keep it TINY and simple**, just needs to look like a bug

2. ✓ Trim Cels (checked)

3. Output: Individual PNGs `{name}-{tag}.png`### Health/XP Orbs - **~30 min**

4. ❌ DO NOT export JSON- [X] **Health orb** - Green/red glow, ~8x8 (can be heart recolor)

5. Place in `assets/images/`- [ ] **XP orb** - Blue/purple glow, ~8x8

- **Can be simple circles with glow effect**

---

## 🔸 NICE TO HAVE (Polish)

## ⏱️ TIME ESTIMATES

- Phase 2 Boss: 6-8 hours (CRITICAL)### UI Elements - **~2 hours**

- Phase 3 Boss: 6-8 hours

- Weapon Effects: 2-3 hours#### Character Card Stat Icons - `stat-icons.png`

- UI: 2-3 hours- **Dimensions:** 8x8 pixels, 3 frames in one sprite sheet

- **Total: ~18-24 hours**- **Frame 0: ATK (Attack)** - Sword or crosshair icon

- **Frame 1: SPD (Speed)** - Boot or wing icon

---- **Frame 2: CDN (Cooldown)** - Clock or hourglass icon

- **Style:** Simple, recognizable silhouettes

## 🎯 WORK ORDER RECOMMENDATION- **Color:** Can be monochrome (code will tint with +/- modifiers)

1. **Boss Phase 2 idle pose** (blocks Phase 2 implementation)- **Notes:** These replace the "ATK/SPD/CDN" text labels on character cards. +/- symbols appear above them in green/red.

2. **Weapon effects** (high value, quick wins)

3. **Boss Phase 3** (when Phase 2 is working)- [ ] **Title screen logo** - Game name, cool font

4. **UI polish** (if time permits)- [ ] **Character portraits** - 32x32 faces for selection (optional)

- [ ] **Victory screen art** - Boss defeated image (optional)

### Effects - **~1 hour**
- [ ] **Ghost shader/sprite** - Grayscale filter + alpha (CODE can do this)
- [ ] **Level up effect** - Particle burst (CODE can generate)
- [ ] **Death effect** - Player explode/fade (CODE can do)

---

## 📐 **EXPORT SETTINGS (Aseprite)**

For ALL sprites:
1. File → Export Sprite Sheet
2. **Trim Cels:** ✓ (checked)
3. **Output:** Individual PNGs named `{name}-{tag}.png`
4. **DO NOT export JSON** (causes offset issues)
5. Place in `assets/images/`

## 🎨 **ART STYLE GUIDE**

- Keep pixel art consistent with existing player/boss
- Simple silhouettes - player should recognize at a glance
- Phase 2: More legs, upright posture
- Phase 3: WINGS are the key feature, make them big
- Don't stress details - game camera is zoomed out

---

## ⏱️ **TIME ESTIMATE: ~22-28 hours art total**

If you work 8 hours/day on art, that's ~3-4 days.
I'll handle ALL the code while you draw.

**START WITH:** Boss Phase 2 idle + attack poses
**REASON:** That's the critical path blocker
