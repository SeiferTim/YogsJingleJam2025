# Game Improvements & Research

## Current Issues to Fix

### 1. Boss Segment Visibility
- **Problem**: Blue last-segment not visible when boss extended
- **Likely Cause**: Segments stacking incorrectly or followDistance too small
- **Solution**: Check segment positions during extended state, may need to adjust followDistance values

### 2. Segment Pushing During Upward Movement
- **Problem**: When boss moves up (slam attack), segments don't get pushed down properly
- **Current Logic**: Segments follow parent's direction but may overlap
- **Solution**: Need to enforce minimum spacing when head moves opposite to segment chain direction

## Features to Add

### 1. Boss Undulation/Wiggle
**Goal**: Add organic wiggling motion to segments when boss moves

**Approach**:
- Add sine wave offset to each segment's position
- Each segment has phase offset based on its position in chain
- Only apply when boss is moving (velocity-based)
- Parameters:
  - Amplitude: 5-10 pixels
  - Frequency: Based on movement speed
  - Phase offset: 0.5-1.0 radians between segments

**Implementation**:
```haxe
// In BossSegment or BossPhase01Larva
var wiggleTime:Float = 0;
var wiggleAmplitude:Float = 8;
var wiggleFrequency:Float = 4;

// In update when moving:
wiggleTime += elapsed;
var wiggleOffset = Math.sin(wiggleTime * wiggleFrequency + segmentIndex) * wiggleAmplitude;
// Apply perpendicular to movement direction
```

### 2. Minor Enemies - Mayflies
**Concept**: Flying pickups that drop hearts

**Stats**:
- Health: 1 hit to kill
- Movement: Erratic flitting pattern in corners
- Spawn: Random corners, 1-3 at a time
- Drop Rate: 50% chance to drop heart on death
- Heart Heal: 10-20 HP

**Implementation Pattern**:
```haxe
class Mayfly extends FlxSprite
{
    var moveTimer:Float;
    var targetX:Float;
    var targetY:Float;
    
    // Flit to random nearby point every 0.5-1.5 seconds
    // Stay in assigned corner area
}
```

### 3. Minor Enemies - Spider Mites
**Concept**: Ground crawlers that appear periodically

**Stats**:
- Health: 2-3 hits
- Movement: Crawl from edges toward player slowly
- Spawn: Every 30-45 seconds, 2-4 at a time
- Drop Rate: 30% heart, 20% arrow refill
- Damage: 5 on contact

**Implementation Pattern**:
```haxe
class SpiderMite extends FlxSprite
{
    var crawlSpeed:Float = 15;
    
    // Simple move toward player
    // Avoid boss
    // Despawn after 20 seconds if not killed
}
```

## Aseprite Export Solution

### The Problem
Aseprite's TexturePacker JSON format includes `spriteSourceSize` offsets that FlxAtlasFrames applies automatically, causing positioning issues.

### Solutions (in order of preference):

#### Option 1: Export Individual PNGs (SIMPLEST)
1. In Aseprite: File → Export Sprite Sheet
2. Settings:
   - Output File: `boss-phase-01-{tag}.png`
   - Trim: ✓ Trim Cels
   - Layout: Each tag as separate file
   - Don't export JSON
3. Load in Flixel:
```haxe
sprite.loadGraphic("assets/images/boss-phase-01-head.png");
```
**Pros**: No offset issues, simple to use
**Cons**: Multiple files to manage

#### Option 2: Export Packed Atlas Without Trim
1. In Aseprite: File → Export Sprite Sheet
2. Settings:
   - Trim: ✗ DISABLE all trim options
   - Padding: 1-2 pixels
   - Output: JSON Array format (not JSON Hash)
3. This removes `spriteSourceSize` offsets
**Pros**: Single file, no offsets
**Cons**: Larger file size

#### Option 3: Custom Sprite Loading
Create helper that ignores spriteSourceSize:
```haxe
class AtlasHelper
{
    public static function loadSprite(sprite:FlxSprite, atlasPath:String, frameName:String):Void
    {
        var atlas = FlxAtlasFrames.fromTexturePackerJson(atlasPath);
        var frame = atlas.getByName(frameName);
        // Manually set frame without applying offsets
        sprite.loadGraphic(atlas.parent.bitmap);
        sprite.animation.add("idle", [frame.frame.x, frame.frame.y, frame.frame.width, frame.frame.height]);
    }
}
```

#### Option 4: Use Aseprite Layers for Segments
Export as single sprite sheet with all segments on separate layers:
1. Each segment = separate layer
2. Export all layers to single PNG grid
3. Load as tileset in Flixel
**Pros**: Good for animation later
**Cons**: Need careful layer organization

**RECOMMENDATION**: Start with Option 1 (individual PNGs) - it's the simplest and works perfectly for testing. Can optimize later.

## Code Architecture Improvements

### Current Problems
- PlayState is 435+ lines with intro logic mixed with gameplay
- Hard to add new cinematics
- Intro states tightly coupled to specific boss intro

### Proposed Solution: Cinematic System

#### 1. Create Cinematic Class
```haxe
class Cinematic
{
    var steps:Array<CinematicStep>;
    var currentStep:Int = 0;
    var stepTimer:Float = 0;
    var onComplete:Void->Void;
    
    public function new() { steps = []; }
    
    public function addStep(step:CinematicStep):Void
    {
        steps.push(step);
    }
    
    public function update(elapsed:Float):Bool
    {
        if (currentStep >= steps.length)
        {
            if (onComplete != null) onComplete();
            return true; // Complete
        }
        
        var step = steps[currentStep];
        step.update(elapsed);
        
        if (step.isComplete())
        {
            step.cleanup();
            currentStep++;
            stepTimer = 0;
        }
        
        return false;
    }
}

interface CinematicStep
{
    function update(elapsed:Float):Void;
    function isComplete():Bool;
    function cleanup():Void;
}
```

#### 2. Example Cinematic Steps
```haxe
class FadeStep implements CinematicStep
{
    var target:FlxSprite;
    var duration:Float;
    var timer:Float = 0;
    var fromAlpha:Float;
    var toAlpha:Float;
    
    public function new(target:FlxSprite, from:Float, to:Float, duration:Float)
    {
        this.target = target;
        this.fromAlpha = from;
        this.toAlpha = to;
        this.duration = duration;
    }
    
    public function update(elapsed:Float):Void
    {
        timer += elapsed;
        var progress = Math.min(timer / duration, 1.0);
        target.alpha = FlxMath.lerp(fromAlpha, toAlpha, progress);
    }
    
    public function isComplete():Bool { return timer >= duration; }
    public function cleanup():Void { target.alpha = toAlpha; }
}

class CameraTrackStep implements CinematicStep
{
    var camera:FlxCamera;
    var target:FlxObject;
    
    public function new(camera:FlxCamera, target:FlxObject)
    {
        this.camera = camera;
        this.target = target;
    }
    
    public function update(elapsed:Float):Void
    {
        camera.focusOn(target.getPosition());
    }
    
    public function isComplete():Bool { return false; } // Never completes on its own
    public function cleanup():Void {}
}

class WaitStep implements CinematicStep
{
    var duration:Float;
    var timer:Float = 0;
    
    public function new(duration:Float) { this.duration = duration; }
    
    public function update(elapsed:Float):Void { timer += elapsed; }
    public function isComplete():Bool { return timer >= duration; }
    public function cleanup():Void {}
}

class CallbackStep implements CinematicStep
{
    var callback:Void->Void;
    var done:Bool = false;
    
    public function new(callback:Void->Void) { this.callback = callback; }
    
    public function update(elapsed:Float):Void
    {
        if (!done)
        {
            callback();
            done = true;
        }
    }
    
    public function isComplete():Bool { return done; }
    public function cleanup():Void {}
}
```

#### 3. Simplified PlayState Usage
```haxe
class PlayState extends FlxState
{
    var introCinematic:Cinematic;
    
    override public function create()
    {
        super.create();
        
        // Setup map, player, boss, etc...
        
        // Build intro cinematic
        introCinematic = new Cinematic();
        introCinematic.addStep(new WaitStep(0.5));
        introCinematic.addStep(new ScrollToStep(camera, eggSprite, 1.0));
        introCinematic.addStep(new EggCrackSequenceStep(eggSprite));
        introCinematic.addStep(new BossFadeInStep(boss, 1.5));
        introCinematic.addStep(new BossUnfurlStep(boss, 1.5));
        introCinematic.addStep(new BossMoveToStep(boss, camera, map.width/2, map.height-80));
        introCinematic.addStep(new HealthBarAppearStep(hud, 0.8));
        introCinematic.addStep(new BossRoarStep(boss, eggSprite, 1.5));
        introCinematic.addStep(new ScrollToStep(camera, player, 0.5));
        introCinematic.onComplete = startBattle;
    }
    
    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);
        
        if (introCinematic != null)
        {
            if (introCinematic.update(elapsed))
            {
                introCinematic = null; // Done
            }
            return;
        }
        
        // Normal gameplay...
    }
}
```

### Benefits
- Each cinematic step is reusable
- Easy to add new cinematics anywhere
- Steps are testable individually  
- No more massive switch statements
- Clear separation: intro logic vs gameplay logic

### Implementation Priority
1. Create basic Cinematic + CinematicStep classes
2. Implement simple steps: Wait, Callback, Fade
3. Implement boss-specific steps: BossFadeInStep, BossUnfurlStep, etc.
4. Refactor current intro to use new system
5. Keep old code commented until new system proven

## Next Steps (When You Return)

1. **DON'T TOUCH WORKING CODE** - Only add new features
2. Fix last-segment visibility issue (just check values, don't rebuild)
3. Add undulation as OPTIONAL feature (can be disabled)
4. Create Mayfly class (simple, non-intrusive)
5. Document Aseprite export settings for you to try
6. Prototype Cinematic system in separate file (don't touch PlayState yet)

## Questions for You

1. **Segment visibility**: Should I just increase followDistance values or is there something else?
2. **Undulation**: How much wiggle do you want? Subtle or obvious?
3. **Minor enemies**: Want these now or after boss is 100% working?
4. **Cinematics**: Want me to prototype this or wait until game is more complete?
5. **Aseprite**: Want to try individual PNGs first or keep trying packed atlas?
