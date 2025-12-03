# Boss Offset-Based Animation System

## Core Concept
**All animations happen via `sprite.offset` changes, NOT position changes.**

This means:
- `sprite.x` and `sprite.y` stay at their "base" positions (where shadows would be)
- Visual movement happens by changing `sprite.offset.x` and `sprite.offset.y`
- Shadows can be drawn at `sprite.y + sprite.height` and won't move during animations

## Segment Positioning

### Spawn (squished)
All segments start at same center position (headX, headY):
- head: offset (0, 0)
- fore: offset (0, 0)  
- back: offset (0, 0)
- last: offset (0, 0)

### Unfurl Animation
Progress from 0→1 tweens offsets to stretch out:
```haxe
foreSegment.sprite.offset.y = -25 * progress;  // moves UP via negative offset
backSegment.sprite.offset.y = -45 * progress;
lastSegment.sprite.offset.y = -60 * progress;
```

### Normal State (extended)
Boss fully stretched with segments pointing down (south):
- head: offset (0, 0)
- fore: offset (0, -25)  // 25px above base position
- back: offset (0, -45)  // 45px above base position  
- last: offset (0, -60)  // 60px above base position

### Wiggle During Movement
Small horizontal sine wave added to offset.x:
```haxe
amplitude = 0.3;  // very subtle (was 3, now 10%)
wiggle1 = sin(time) * 0.3
wiggle2 = sin(time + 0.8) * 0.3
wiggle3 = sin(time + 1.6) * 0.3
```

### Slam Attack (raise up)
Segments raise by increasing negative Y offsets:
```haxe
raiseProgress = 0→1 over 1.2 seconds
raise = 80 * raiseProgress

head.offset.y = -raise
fore.offset.y = -(baseOffsetY + raise * 0.75)  // raises 75% as much
back.offset.y = -(baseOffsetY + raise * 0.5)   // raises 50% as much
last.offset.y = -(baseOffsetY + raise * 0.25)  // raises 25% as much
```

Then slam down over 0.1s by tweening back to normal offsets.

## Mouth & Pincers

Loaded as 2-frame sprite sheets:
```haxe
mouth.loadGraphic(path, true, 40, 40);
mouth.animation.add("closed", [0]);
mouth.animation.add("open", [1]);
```

Toggle via: `mouth.animation.play(open ? "open" : "closed")`

## Benefits

1. **Simple**: No complex physics or parent-child following
2. **Predictable**: All animations are deterministic tweens/sine waves
3. **Shadow-friendly**: Shadows stay at sprite.y while visual moves via offset
4. **Extensible**: Easy to add new animations (squash/stretch, bounce, etc)
5. **Performant**: No distance calculations or iterative solving

## How It Looks

```
Spawn (squished):          Unfurled:              Slam Attack:
   🟣 all stacked            🟣 last                   🟣 last (raised high)
                             🟣 back                   🟣 back (raised medium)
                             🟣 fore                   🟣 fore (raised low)
                             🟣 head                   🟣 head (raised highest)
                           ↓ facing south          ↑ raised off ground
```

All achieved by changing offsets, not positions!
