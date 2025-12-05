# 🧪 TESTING TO DO - Yogscast Jingle Jam 2025

**Last Updated:** December 4, 2025

---

## ✅ TESTED & VERIFIED

### Core Systems
- [x] Player movement (8 directions, collisions)
- [x] Player aiming (follows mouse, rotates correctly)
- [x] Player dodge (iframes, cooldown display)
- [x] All 4 weapons fire correctly
- [x] Weapon cooldowns display on HUD
- [x] Character selection works
- [x] XP bar fills on level up
- [x] HUD updates correctly

### Boss Phase 1
- [x] Larva spawns and moves correctly
- [x] Mouth opens/closes animation
- [x] Spit attack fires projectiles
- [x] Chomp attack (lunge forward)
- [x] Pincers open/close
- [x] Segment animations
- [x] Health bar tracks damage
- [x] Boss name reveals letter-by-letter
- [x] Damage numbers appear and fade
- [x] Boss flashes red when hit
- [x] Death animation and transition to Phase 1.5

### Boss Phase 1.5
- [x] Cocoon appears after Phase 1 death
- [x] Mayflies spawn from cocoon
- [x] Mayflies enter from off-screen
- [x] Mayflies drop hearts on death
- [x] Hearts can be picked up
- [x] Cocoon hatches into Phase 2

---

## 🔥 CRITICAL - NEEDS TESTING

### Boss Phase 2 - WANDER
- [x] Spider body parts position correctly
- [x] Leg walking animation works
- [x] WANDER state chooses random targets
- [x] Movement speed (25) feels right
- [ ] **NEEDS RETEST:** Ensure legs sync with movement

### Boss Phase 2 - CHARGE
- [x] Telegraph animation (4 bounces, 0.8s)
- [x] Charge dash (50 speed)
- [x] Charge stops at max distance (80px)
- [x] Charge stops on wall collision
- [x] Charge times out (0.6s)
- [ ] **NEEDS RETEST:** Player can react to telegraph
- [ ] **NEEDS RETEST:** Charge damage + knockback amount

### Boss Phase 2 - SPIT
- [ ] **NOT IMPLEMENTED YET**

### Boss Phase 2 - SLASH
- [ ] **NOT IMPLEMENTED YET**

### Boss Phase 2 - State Machine
- [ ] Attack rotation works (wander → spit → charge → claw)
- [ ] State transitions are smooth
- [ ] Attacks don't overlap weirdly
- [ ] Boss doesn't get stuck in one attack

---

## 🟡 HIGH PRIORITY - NEEDS TESTING

### Player Combat
- [ ] All 4 weapons deal correct damage
- [ ] Projectiles hit boss hitboxes accurately
- [ ] Charge attacks work (hold to charge)
- [ ] Cooldown timings feel right
- [ ] Player can dodge boss attacks reliably

### Boss Damage & Health
- [ ] Boss takes damage from all weapons
- [ ] Damage numbers accumulate correctly
- [ ] Health bar drains smoothly
- [ ] Boss defeat triggers phase transition

### Phase Transitions
- [ ] Phase 1 → Phase 1.5 smooth
- [ ] Phase 1.5 → Phase 2 smooth
- [ ] Phase 2 → Phase 2.5 (when implemented)
- [ ] Phase 2.5 → Phase 3 (when implemented)

### Ghost Spawning (Phase 1.5/2.5)
- [ ] **NEEDS RETEST:** Ghosts spawn if player didn't collect hearts
- [ ] **NEEDS RETEST:** Mayflies spawn if player collected hearts
- [ ] Logic correctly tracks player behavior
- [ ] Transition timing feels good

---

## 🔵 MEDIUM PRIORITY - NEEDS TESTING

### Mayfly Behavior
- [ ] Mayflies spawn at correct intervals
- [ ] Mayflies enter from off-screen smoothly
- [ ] Mayflies fly around randomly
- [ ] Mayflies don't fly off-screen
- [ ] Hearts spawn at mayfly death location
- [ ] Hearts can be picked up by player

### Boss Collision
- [ ] Boss segments don't overlap weirdly
- [ ] Boss doesn't clip through walls
- [ ] Boss hitboxes feel fair
- [ ] Player can't clip inside boss

### Player Stats & Leveling
- [ ] XP gain from killing enemies
- [ ] Level up increases stats
- [ ] Random stat generation at character select
- [ ] Stat differences noticeable in gameplay

---

## 🟢 LOW PRIORITY - NEEDS TESTING

### UI/HUD
- [ ] Health bar updates correctly
- [ ] XP bar shows progress
- [ ] Cooldown icons fill correctly
- [ ] Damage numbers don't overlap text
- [ ] Boss name doesn't clip off-screen

### Visual Polish
- [ ] Boss flash effect looks good
- [ ] Death animations play correctly
- [ ] Projectile graphics display correctly
- [ ] Arrow rotation follows aim

### Edge Cases
- [ ] Player death triggers defeat screen
- [ ] Boss defeat triggers victory screen
- [ ] Pausing works correctly
- [ ] Returning to title works
- [ ] Restarting resets everything

---

## 🐛 BUGS TO INVESTIGATE

### Known Issues
- [ ] Player can get stuck in walls during dodge
  - **Reproduce:** Dodge into corner at specific angle
  - **Severity:** Medium
- [ ] Boss sometimes goes slightly off-screen
  - **Reproduce:** Charge attack near edge
  - **Severity:** Low
- [ ] Projectile collision edge cases
  - **Reproduce:** Fire rapidly while moving
  - **Severity:** Low
- [ ] Mayfly spawn frequency too high/low?
  - **Reproduce:** Play full Phase 1.5 transition
  - **Severity:** Low - needs tuning

### Suspected Issues (Unverified)
- [ ] Does player dodge grant iframes against ALL attacks?
- [ ] Can player damage boss during phase transitions?
- [ ] Do damage numbers stack correctly at high attack speed?
- [ ] Does boss name reveal work if damaged during animation?

---

## 📊 TEST COVERAGE SUMMARY

| Area | Coverage | Status |
|------|----------|--------|
| Player Movement | 100% | ✅ Complete |
| Player Combat | 80% | ⚠️ Needs balance testing |
| Boss Phase 1 | 100% | ✅ Complete |
| Boss Phase 1.5 | 90% | ⚠️ Ghost logic needs retest |
| Boss Phase 2 WANDER | 90% | ⚠️ Minor checks needed |
| Boss Phase 2 CHARGE | 80% | ⚠️ Balance testing needed |
| Boss Phase 2 SPIT | 0% | ❌ Not implemented |
| Boss Phase 2 SLASH | 0% | ❌ Not implemented |
| Boss Phase 3 | 0% | ❌ Not implemented |
| Phase Transitions | 50% | ⚠️ Partial testing |
| UI/HUD | 95% | ✅ Mostly complete |
| Victory/Defeat | 0% | ❌ Not implemented |

---

## 🎯 TESTING WORK ORDER

### TODAY (Dec 4)
1. Retest Boss Phase 2 WANDER + CHARGE after any code changes
2. Test ghost spawning logic (Phase 1.5)
3. Verify player dodge timing vs boss attacks

### AFTER PHASE 2 SPIT/SLASH IMPLEMENTATION
1. Test new attacks individually
2. Test attack rotation (all 4 attacks)
3. Full playthrough Phase 1 → Phase 2

### AFTER PHASE 3 IMPLEMENTATION
1. Test Phase 3 attacks
2. Test full boss fight (Phase 1 → 2 → 3)
3. Verify phase transitions

### AFTER VICTORY/DEFEAT SCREENS
1. Test player death
2. Test boss defeat
3. Test restart/retry flow

### BEFORE SUBMISSION
1. Full playthrough with all 4 weapons
2. Balance pass (difficulty, timing)
3. Bug hunting session
4. Performance check

---

## 🧾 TEST CHECKLIST (Quick Reference)

Copy this to track a full playthrough:

```
[ ] Game launches
[ ] Title screen appears
[ ] Character select works
[ ] Player spawns correctly
[ ] Player can move in all directions
[ ] Player can dodge
[ ] All 4 weapons fire
[ ] Bow shoots arrows
[ ] Sword slashes
[ ] Wand shoots magic
[ ] Halberd thrusts

[ ] Boss Phase 1 spawns
[ ] Boss health bar appears
[ ] Boss name reveals
[ ] Boss attacks player
[ ] Player can damage boss
[ ] Damage numbers show
[ ] Boss flashes on hit
[ ] Boss Phase 1 defeated

[ ] Cocoon appears (Phase 1.5)
[ ] Mayflies/ghosts spawn
[ ] Hearts drop
[ ] Hearts can be picked up
[ ] Cocoon hatches (Phase 2)

[ ] Spider boss appears
[ ] Boss walks around (WANDER)
[ ] Boss charges player
[ ] Boss spits projectiles
[ ] Boss swipes claws
[ ] Player can damage Phase 2
[ ] Boss Phase 2 defeated

[ ] Cocoon appears (Phase 2.5)
[ ] Mayflies/ghosts spawn
[ ] Cocoon hatches (Phase 3)

[ ] Flying boss appears
[ ] Boss hovers
[ ] Boss dive attacks
[ ] Boss wing gust
[ ] Boss shoots projectiles
[ ] Player can damage Phase 3
[ ] Boss Phase 3 defeated

[ ] Victory screen shows
[ ] Stats displayed
[ ] Can return to title
[ ] Can restart game
```

---

## 📝 NOTES FOR USER

**Add your test results/bugs here:**

- [ ] (Bugs you've found)
- [ ] (Balance concerns)
- [ ] (Things that feel off)
- [ ] (Features that need tuning)
