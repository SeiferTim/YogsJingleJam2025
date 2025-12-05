# 💻 CODE TO DO - Yogscast Jingle Jam 2025

**Last Updated:** December 4, 2025

---

## ✅ COMPLETED

### Core Systems
- [x] Player movement, dodging, aiming
- [x] 4 Weapon types (Bow, Sword, Wand, Halberd)
- [x] Character selection with random stats
- [x] XP/Leveling system
- [x] Boss Phase 1 (Larva) - Full implementation
- [x] Boss Phase 1.5 (Cocoon transition + mayfly spawns)
- [x] Boss Phase 2 base class (body parts, positioning)
- [x] Boss Phase 2 WANDER mode (walking animation with alternating legs)
- [x] Boss Phase 2 CHARGE attack (telegraph → dash → recovery)
- [x] Mayfly enemy (flies in from off-screen, drops hearts)
- [x] Heart pickup system
- [x] Boss health bar with boss name reveal
- [x] Damage numbers on boss health bar
- [x] HUD system

---

## 🔥 CRITICAL PATH (Phase 2 Completion)

### 1. Boss Phase 2 - SPIT Attack
**Priority:** HIGHEST | **Estimated Time:** 30 minutes

- [ ] Copy Phase 1 projectile spawning logic
- [ ] Spawn from `mouth` sprite position
- [ ] Aim toward player
- [ ] Add to attack rotation (spit → charge → wander)
- [ ] Test damage and projectile speed

**Code Location:** `BossPhase02.hx` - add `attackSpit()` method

---

### 2. Boss Phase 2 - SLASH/SWIPE Attack
**Priority:** HIGH | **Estimated Time:** 1-2 hours

**Design Questions:**
- [ ] One claw or both claws?
- [ ] Arc sweep or forward jab?
- [ ] Hitbox shape (rectangle, circle, arc)?

**Implementation (No Art):**
1. Choose claw (left/right, alternating or random)
2. Tween claw forward 15px over 0.3s
3. Create hitbox in front of claw
4. Check player overlap
5. Deal damage + knockback
6. Tween claw back

**Code Location:** `BossPhase02.hx` - add `attackClawSwipe()` method

---

### 3. Boss Phase 2 - Attack State Machine
**Priority:** MEDIUM | **Estimated Time:** 1 hour

- [ ] Rotate through attacks: WANDER → SPIT → CHARGE → CLAW → repeat
- [ ] Adjust attack frequencies/cooldowns
- [ ] Add health-based behavior changes (enrage at low HP?)
- [ ] Balance attack patterns for difficulty

**Code Location:** `BossPhase02.hx` - enhance existing state machine

---

## 🟡 HIGH PRIORITY (Phase 3)

### 4. Boss Phase 3 Implementation
**Priority:** HIGH (after Phase 2 complete) | **Estimated Time:** 6-8 hours

**Requires:** Phase 3 art assets

- [ ] Create `BossPhase03.hx` class
- [ ] Implement flight/hover movement AI
- [ ] Wing flutter idle animation
- [ ] Dive bomb attack (fast downward strike)
- [ ] Wing gust attack (shockwave/projectiles)
- [ ] Air-to-ground projectile rain
- [ ] Health management, defeat condition
- [ ] Phase 2.5 → Phase 3 transition

---

### 5. Phase Transition System
**Priority:** MEDIUM | **Estimated Time:** 2-3 hours

- [ ] Phase 1 death → Phase 1.5 cocoon
- [ ] Phase 1.5: Spawn ghosts (if any saved) OR mayflies for healing
- [ ] Phase 1.5 → Phase 2 transition
- [ ] Phase 2 death → Phase 2.5 cocoon
- [ ] Phase 2.5: Spawn ghosts OR mayflies
- [ ] Phase 2.5 → Phase 3 transition

---

## 🔵 MEDIUM PRIORITY (Game Loop)

### 6. Victory/Defeat Screens
**Priority:** MEDIUM | **Estimated Time:** 2-3 hours

- [ ] Victory screen when Phase 3 defeated
  - Show stats: time, damage dealt, level reached
  - "Return to Title" button
- [ ] Defeat screen when player dies
  - Show stats
  - "Retry" option (same character or new)
- [ ] Proper state transitions

---

### 7. Main Menu / Title Screen
**Priority:** MEDIUM | **Estimated Time:** 1-2 hours

**Requires:** Title screen art (optional)

- [ ] Create `TitleState.hx`
- [ ] Display game logo/title
- [ ] "Press Enter to Start" prompt
- [ ] Transition to character select
- [ ] Background music integration

---

### 8. Pause Menu
**Priority:** LOW | **Estimated Time:** 1 hour

- [ ] Pause with ESC or P key
- [ ] Resume, Restart, Quit options
- [ ] Pause game logic and audio

---

## 🟢 LOW PRIORITY (Polish)

### 9. Sound Effects & Music
**Priority:** LOW (functional game first) | **Estimated Time:** 2-4 hours

**Needs:** Audio assets from collaborator

- [ ] Player attack SFX (per weapon type)
- [ ] Enemy hit SFX
- [ ] Player hit/death SFX
- [ ] Boss attack SFX
- [ ] Level up SFX
- [ ] Pickup SFX (hearts, orbs)
- [ ] Background music (title, battle, victory)
- [ ] Audio volume controls

---

### 10. Weapon Balancing
**Priority:** LOW | **Estimated Time:** 1-2 hours

- [ ] Tune damage values per weapon
- [ ] Adjust cooldowns
- [ ] Balance range vs damage
- [ ] Test charge attacks
- [ ] Adjust player dodge cooldown vs boss attack frequency

---

### 11. Visual Effects & Polish
**Priority:** LOW | **Estimated Time:** 2-3 hours

- [ ] Camera shake on hits
- [ ] Screen flash on critical moments
- [ ] Particle effects for attacks
- [ ] Better death animations
- [ ] Level-up visual effect
- [ ] Boss telegraph effects

---

### 12. Minor Enemies Expansion
**Priority:** LOW | **Estimated Time:** 2-3 hours

- [ ] Improve mayfly behavior (better pathing)
- [ ] Spider mites (crawl from edges, contact damage)
- [ ] Spawn timers and difficulty scaling
- [ ] Variety in enemy spawns per phase

---

## 🐛 KNOWN BUGS / ISSUES

### Gameplay
- [ ] Player can get stuck in walls during dodge
- [ ] Boss sometimes goes slightly off-screen
- [ ] Projectile collision edge cases
- [ ] Mayfly spawn frequency tuning

### Code Quality (Post-Jam)
- [ ] PlayState intro sequence (could use cinematic system - see notes)
- [ ] Boss attack methods could use state pattern
- [ ] Magic numbers should be named constants
- [ ] Consider file organization (bosses/, ui/, etc.)

---

## 📊 TIME ESTIMATES TO COMPLETION

| Task | Time |
|------|------|
| Phase 2 SPIT + SLASH | 2-3 hours |
| Phase 2 Attack Rotation | 1 hour |
| Phase 3 Full Implementation | 6-8 hours |
| Phase Transitions | 2-3 hours |
| Victory/Defeat Screens | 2-3 hours |
| Title Screen | 1-2 hours |
| Sound/Music Integration | 2-4 hours |
| Balance & Polish | 3-4 hours |
| **TOTAL** | **~20-30 hours** |

---

## 🎯 SUGGESTED WORK ORDER

### TODAY (Dec 4)
1. Implement Phase 2 SPIT attack (30 min)
2. Design & implement SLASH attack (1-2 hrs)
3. Refine Phase 2 attack rotation (1 hr)

### TOMORROW (Dec 5)
1. Start Phase 3 implementation (requires art)
2. Build phase transition system
3. Create victory/defeat screens

### DAY 3 (Dec 6)
1. Complete Phase 3
2. Add title screen
3. Start polish pass

### DAY 4 (Dec 7)
1. Sound/music integration
2. Balance pass
3. Bug fixes

### DEADLINE (Dec 8)
1. Final testing
2. Build & submit

---

## ❓ OPEN QUESTIONS

1. **Phase 3 flight pattern:** Stay airborne or land sometimes?
2. **Charge attack:** Go through walls or bounce off?
3. **Claw swipe:** One hit or combo (left then right)?
4. **Victory reward:** Just congrats or unlock something?
5. **Difficulty:** Fixed or scales with player level?
6. **Save system:** Save progress or always start from beginning?

---

## 📝 NOTES FOR USER

**Add your priorities/notes here:**

- [ ] (Your code requests go here)
- [ ] (Any specific features you want)
- [ ] (Bugs you've noticed)
- [ ] (Balance concerns)
