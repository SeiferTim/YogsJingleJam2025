# Code Cleanup TODO

## High Priority (After Boss is Working)

### PlayState.hx (435 lines - MESSY)
- **Intro sequence**: Huge switch statement with 15+ states
  - Should be extracted to Cinematic system (see IMPROVEMENTS.md)
  - Each intro step should be reusable component
  - Current: tightly coupled, hard to modify
- **Update method**: Mixed intro logic + gameplay logic
  - Should separate: if (cinematic) vs normal gameplay
- **Collision checks**: Spread across multiple methods
  - Could consolidate into single collision manager
- **Magic numbers**: Lots of hardcoded values (0.5, 1.2, etc.)
  - Should be named constants at top of class

### BossPhase01Larva.hx (531 lines - LARGE)
- **Attack methods**: updateSlamAttack, updateSpitAttack are long
  - Could use state pattern or attack classes
- **Segment positioning**: Manual setCenter calls in slam attack
  - Inconsistent with normal following behavior
- **Timing values**: Hardcoded throughout (1.2, 0.8, 1.5, etc.)
  - Should be class constants with descriptive names
- **Mode enum**: Only 3 modes, could be simpler
  - Consider action queue system instead

### BossSegment.hx (60 lines - GOOD)
- Actually pretty clean!
- Minor: Could add documentation comments
- Minor: followParent logic could be clearer

## Medium Priority

### Weapon.hx
- Not looked at yet - may need review

### Player.hx
- Check for similar issues to Boss
- Ensure consistent patterns

### HUD.hx
- Check for code duplication
- Ensure clean separation of concerns

## Low Priority (Polish)

### File Organization
- All .hx files in one `source/` folder
  - Consider: source/bosses/, source/ui/, source/cinematics/
- AssetPaths usage
  - Works but generates long names with underscores

### Comments & Documentation
- Per your commandment: NO COMMENTS in working code
- But: public APIs could use /** doc comments */ for IDE hints
- Compromise: Doc comments on public interfaces only?

### Naming Conventions
- Generally good
- Some inconsistency: `updateIdle` vs `update_idle` vs `onIdle`
- Pick one pattern and stick to it

## After Game Jam

### Refactoring Ideas
1. **Cinematic System** (detailed in IMPROVEMENTS.md)
   - Reusable steps
   - Easy to compose sequences
   - Testable in isolation

2. **Boss State Machine**
   - Replace mode enum + big switch
   - Each state is class: IdleState, SlamAttackState, etc.
   - Cleaner transitions

3. **Attack System**
   - Attack base class
   - SlamAttack, SpitAttack extend it
   - Boss just executes current attack
   - Easier to add new attacks

4. **Collision Manager**
   - Single place for all collision logic
   - Clear separation: what collides with what
   - Easy to add new collision types

5. **Configuration Class**
   - All timing/distance/speed values in one place
   - Easy to tweak and balance
   - Could even load from JSON for modding

## Notes

- **Priority**: Get game working FIRST
- **Don't refactor working code before jam ends**
- **After jam**: Can refactor properly without time pressure
- **Technical debt is OK** during a jam - shipping > perfect code

## Questions for Later

1. Want to support multiple boss phases?
   - If yes: need boss phase system
   - If no: current approach is fine

2. Want modular level/arena system?
   - If yes: need level loader
   - If no: single map is fine

3. Want to reuse cinematic system elsewhere?
   - Opening cutscene?
   - Ending cutscene?
   - Between-level transitions?

4. How much content post-jam?
   - Just this one boss fight?
   - Multiple levels?
   - Determines how much architecture needed
