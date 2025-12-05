package;

import CharacterData.WeaponType;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.tile.FlxBaseTilemap.FlxTilemapAutoTiling;
import flixel.tile.FlxTilemap;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

class PlayState extends FlxState
{
	public static var current:PlayState;

	public var map:FlxTilemap;
	public var player:Player;
	var selectedCharacter:CharacterData; // Character selected in CharacterSelectState

	var projectiles:FlxTypedGroup<Projectile>;
	var bossProjectiles:FlxTypedGroup<Projectile>;
	var mayflies:FlxTypedGroup<Mayfly>;
	var ghosts:FlxTypedGroup<Ghost>;
	var hearts:FlxTypedGroup<HeartPickup>;
	var spiritOrbs:FlxTypedGroup<SpiritOrb>;

	public var hud:HUD;
	// Boss phases
	var boss:BossPhase01Larva;
	var boss2:BossPhase02;
	var currentBossPhase:Int = 1;
	
	var cameraTarget:FlxObject;

	// Mayfly spawning
	var mayflySpawnTimer:Float = 0;
	var mayflySpawnInterval:Float = 3.0; // Spawn attempt every 3 seconds

	public var shadowLayer:ShadowLayer;

	var introState:IntroState = FADE_IN;
	var introTimer:Float = 0;
	var fadeOverlay:FlxSprite;
	var eggSprite:FlxSprite;
	var cocoonSprite:FlxSprite;
	var playerActive:Bool = false;
	// Phase transition
	public var gameState:GameState = INTRO;
	var transitionTimer:Float = 0;

	public function new(?character:CharacterData)
	{
		super();
		current = this;
		selectedCharacter = character;
	}

	override public function create()
	{
		super.create();
		Actions.init();

		// Enable pixel-perfect rendering
		FlxG.camera.pixelPerfectRender = true;
		FlxG.camera.antialiasing = false;

		map = new FlxTilemap();
		map.loadMapFromCSV("assets/maps/base.csv", "assets/images/lofi_environment.png", 8, 8, FlxTilemapAutoTiling.OFF, 0, 0);
		add(map);

		FlxG.worldBounds.set(8, 8, map.width - 16, map.height - 16);
		// Shadow layer - renders above map but below entities
		// Creates a bitmap layer at 0.7 alpha so overlapping shadows don't compound
		shadowLayer = new ShadowLayer(Std.int(map.width), Std.int(map.height), 0.7);
		add(shadowLayer);

		// Create projectile groups (but don't add yet - add after player/boss for proper layering)
		projectiles = new FlxTypedGroup<Projectile>();
		bossProjectiles = new FlxTypedGroup<Projectile>();
		mayflies = new FlxTypedGroup<Mayfly>(5);
		ghosts = new FlxTypedGroup<Ghost>(10);
		hearts = new FlxTypedGroup<HeartPickup>(10);
		spiritOrbs = new FlxTypedGroup<SpiritOrb>(10);

		add(hearts);
		add(spiritOrbs);

		// Initialize spirit orb pool
		for (i in 0...spiritOrbs.maxSize)
		{
			spiritOrbs.add(new SpiritOrb());
		}
		

		eggSprite = new FlxSprite(0, 0);
		eggSprite.loadGraphic("assets/images/boss-phase-00-egg.png", true, 256, 144);
		eggSprite.animation.frameIndex = 0;
		eggSprite.visible = false;
		add(eggSprite);
		// Cocoon sprite (for phase transitions)
		cocoonSprite = new FlxSprite(0, 0);
		cocoonSprite.loadGraphic("assets/images/boss-phase-01-cocoon.png");
		cocoonSprite.visible = false;
		cocoonSprite.alpha = 0;
		add(cocoonSprite);

		player = new Player((map.width / 2) - 4, map.height - 32, projectiles);
		player.active = false;
		// Apply character stats if available
		if (selectedCharacter != null)
		{
			player.maxHP = selectedCharacter.maxHP;
			player.currentHP = selectedCharacter.maxHP;
			player.attackDamage = selectedCharacter.attackDamage;
			player.moveSpeed = selectedCharacter.moveSpeed;
			player.luck = selectedCharacter.luck;

			// Set the character sprite frame from the selected character
			player.animation.frameIndex = selectedCharacter.spriteFrame;

			// Set the weapon based on character's weapon type
			player.setWeapon(selectedCharacter.weaponType);
			// Add weapon hitboxes to scene (for melee weapons)
			if (Std.isOfType(player.weapon, Sword))
			{
				var sword:Sword = cast player.weapon;
				add(sword.getSlashHitbox());
				add(sword.getSpinHitbox());
			}
			else if (Std.isOfType(player.weapon, Halberd))
			{
				var halberd:Halberd = cast player.weapon;
				add(halberd.getJabHitbox());
			}
		}
		
		add(player);

		// Create player shadow
		// Width: 1.2x, Height: 0.25x, Anchor: center.x, y + height
		player.shadow = new Shadow(player, 1.2, 0.25, 0, player.height / 2);
		shadowLayer.add(player.shadow);

		// Boss spawns at center of egg sprite
		var bossSpawnX = eggSprite.x + eggSprite.width / 2;
		var bossSpawnY = eggSprite.y + eggSprite.height / 2;
		boss = new BossPhase01Larva(bossSpawnX, bossSpawnY, null, bossProjectiles);
		boss.visible = true; // Always visible, but starts at alpha 0
		boss.active = false;
		boss.currentHealth = 0;
		add(boss);

		// Create boss shadows for each segment
		boss.createShadows(shadowLayer);

		// Add mayflies and hearts before projectiles
		add(mayflies);
		add(ghosts);

		// Add projectiles AFTER player and boss so they render on top
		add(projectiles);
		add(bossProjectiles);
		// Create camera target for smooth camera control
		cameraTarget = new FlxObject(player.x, player.y, 1, 1);
		add(cameraTarget);

		FlxG.camera.follow(cameraTarget, LOCKON);
		FlxG.camera.setScrollBoundsRect(0, 0, map.width, map.height);
		hud = new HUD(player, boss);
		hud.visible = false;
		add(hud);
		fadeOverlay = new FlxSprite(0, 0);
		fadeOverlay.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		fadeOverlay.scrollFactor.set(0, 0);
		add(fadeOverlay);

		// No longer need to manually set camera scroll
		// FlxG.camera.scroll.set(player.x - FlxG.width / 2, player.y - FlxG.height / 2);

		startIntroSequence();
	}

	override public function update(elapsed:Float)
	{
		// DEBUG: Press T to test phase transition
		if (FlxG.keys.justPressed.T && gameState == PHASE_1_ACTIVE)
		{
			trace("DEBUG: Force Phase 1 death");
			boss.currentHealth = 0;
		}

		if (gameState == INTRO)
		{
			updateIntroSequence(elapsed);
		}
		else if (gameState == PHASE_0_5_GHOSTS)
		{
			// Phase 0.5: Staggered ghost spawning and fight BEFORE egg hatches
			updatePhase0_5Ghosts(elapsed);
			updateMayflySpawning(elapsed); // Allow healing during ghost fight
			checkProjectileCollisions();
			checkMeleeWeaponCollisions();
			checkGhostCollisions();
		}
		else if (gameState == PHASE_1_ACTIVE)
		{
			// Check if boss Phase 1 is defeated
			if (boss != null && boss.currentHealth <= 0 && boss.alive)
			{
				startPhase1DeathSequence();
			}
			
			// Update Mayfly spawning
			updateMayflySpawning(elapsed);
			
			checkProjectileCollisions();
			checkBossCollisions();
		}
		else if (gameState == PHASE_1_DEATH)
		{
			updatePhase1DeathSequence(elapsed);
		}
		else if (gameState == PHASE_1_5_ACTIVE)
		{
			updatePhase1_5(elapsed);
			// IMPORTANT: Spawn MORE mayflies during cocoon phase so player can heal!
			updateMayflySpawning(elapsed);
			
			checkProjectileCollisions();
			// No boss collisions during cocoon phase
		}
		else if (gameState == PHASE_2_5_ACTIVE)
		{
			updatePhase2_5(elapsed);
			// Allow healing and normal projectile checks while ghosts fight
			updateMayflySpawning(elapsed);
			checkProjectileCollisions();
			checkGhostCollisions();
		}
		else if (gameState == PHASE_2_ACTIVE)
		{
			// TODO: Check Phase 2 boss defeat
			// Update Mayfly spawning
			updateMayflySpawning(elapsed);
			
			checkProjectileCollisions();
			checkPhase2Collisions();
		}
		
		super.update(elapsed);
	}
	function startIntroSequence():Void
	{
		introState = FADE_IN;
		introTimer = 0;

		// Make egg visible BEFORE fade starts
		eggSprite.visible = true;

		FlxTween.tween(fadeOverlay, {alpha: 0}, 1.0, {
			ease: FlxEase.quadOut,
			onComplete: function(t:FlxTween)
			{
				introState = SCROLL_TO_EGG;
				introTimer = 0;
			}
		});
	}

	function updateIntroSequence(elapsed:Float):Void
	{
		introTimer += elapsed;

		switch (introState)
		{
			case FADE_IN: // FlxTween handles, just wait

			case SCROLL_TO_EGG:
				if (introTimer > 0.8)
				{
					FlxTween.tween(cameraTarget, {y: eggSprite.y + eggSprite.height / 2}, 2.0, {
						ease: FlxEase.quadInOut,
						onComplete: _ -> 
						{
							introState = EGG_PAUSE_1;
							introTimer = 0;
							// Check for ghosts BEFORE egg hatches
							checkForGhostsOrStartHatch();
						}
					});
					introState = SCROLLING;
				}

			case SCROLLING: // FlxTween handles

			case EGG_PAUSE_1:
				if (introTimer > 0.4)
					advanceIntro(EGG_CRACK_1);

			case EGG_CRACK_1:
				eggSprite.animation.frameIndex = 1;
				if (introTimer > 0.05)
					advanceIntro(EGG_PAUSE_2);

			case EGG_PAUSE_2:
				if (introTimer > 0.4)
					advanceIntro(EGG_CRACK_2);

			case EGG_CRACK_2:
				eggSprite.animation.frameIndex = 2;
				if (introTimer > 0.05)
					advanceIntro(EGG_PAUSE_3);

			case EGG_PAUSE_3:
				if (introTimer > 0.4)
					advanceIntro(EGG_CRACK_REST);

			case EGG_CRACK_REST:
				eggSprite.animation.frameIndex = introTimer < 0.3 ? 2 + Math.floor((introTimer / 0.3) * 3) : 4;
				if (introTimer > 0.5)
					advanceIntro(EGG_PAUSE_4);

			case EGG_PAUSE_4:
				if (introTimer > 0.3)
				{
					boss.active = true;
					advanceIntro(BOSS_FADE_IN);
				}

			case BOSS_FADE_IN:
				boss.fadeIn(Math.min(introTimer / 1.5, 1.0));
				if (introTimer >= 1.5)
					advanceIntro(BOSS_UNFURL);

			case BOSS_UNFURL:
				boss.unfurl(Math.min(introTimer / 1.5, 1.0));
				var headPos = boss.getHeadPosition();
				cameraTarget.setPosition(headPos.x, headPos.y);
				if (introTimer >= 1.5)
					advanceIntro(BOSS_DESCEND);

			case BOSS_DESCEND:
				boss.moveTo(map.width / 2, map.height - 64, 40, elapsed);
				var headPos = boss.getHeadPosition();
				cameraTarget.setPosition(headPos.x, headPos.y);
				if (boss.isAtPosition(map.width / 2, map.height - 64))
					advanceIntro(HEALTH_BAR_APPEAR);

			case HEALTH_BAR_APPEAR:
				if (!hud.visible && introTimer > 0.05)
					hud.visible = true;
				hud.setAlpha(Math.min(introTimer / 0.5, 1.0));
				if (introTimer > 0.8)
					advanceIntro(HEALTH_BAR_PAUSE);

			case HEALTH_BAR_PAUSE:
				if (introTimer > 0.4)
				{
					boss.currentHealth = 0;
					hud.revealBossName();
					advanceIntro(HEALTH_BAR_FILL);
				}

			case HEALTH_BAR_FILL:
				boss.currentHealth = introTimer < 1.0 ? FlxMath.lerp(0, boss.maxHealth, introTimer) : boss.maxHealth;
				if (introTimer > 1.2)
					advanceIntro(BOSS_ROAR);

			case BOSS_ROAR:
				if (introTimer < 0.05)
				{
					boss.roar();
					FlxG.camera.shake(0.02, 0.4);
				}
				if (introTimer < 0.8)
					eggSprite.alpha = 1.0 - (introTimer / 0.8);
				else if (eggSprite.visible)
					eggSprite.visible = false;

				if (introTimer > 1.0)
					boss.closeRoar();
				if (introTimer > 1.5)
				{
					FlxTween.tween(cameraTarget, {x: player.x, y: player.y}, 0.5, {
						ease: FlxEase.quadInOut,
						onComplete: _ ->
						{
							introState = COMPLETE;
							// Start the battle
							startBattle();
						}
					});
					introState = SCROLL_TO_PLAYER;
				}

			case SCROLL_TO_PLAYER: // FlxTween handles

			case COMPLETE:
		}
	}

	inline function advanceIntro(nextState:IntroState):Void
	{
		introState = nextState;
		introTimer = 0;
	}

	function checkForGhostsOrStartHatch():Void
	{
		// Filter ghosts: only spawn those who died in Phase 0 or Phase 1
		var allGhosts = GameData.getDeadCharacters();
		var phase0And1Ghosts = allGhosts.filter(function(char:CharacterData)
		{
			return char.deathPhase <= 1; // Phase 0 or Phase 1 deaths
		});

		if (phase0And1Ghosts.length > 0)
		{
			trace("Found " + phase0And1Ghosts.length + " Phase 0/1 ghosts - starting Phase 0.5");
			startPhase0_5Ghosts(phase0And1Ghosts);
		}
		else
		{
			trace("No Phase 0/1 ghosts - continuing with egg hatch");
			// Continue with the intro (egg will hatch)
			// Don't need to do anything - intro will continue naturally
		}
	}

	var ghostSpawnQueue:Array<CharacterData> = [];
	var ghostSpawnTimer:Float = 0;
	var ghostSpawnInterval:Float = 0.5; // Spawn one ghost every 0.5 seconds
	var ghostsSpawningComplete:Bool = false; // Track when all ghosts have spawned
	var waitingForLastOrbPickup:Bool = false; // Track when waiting for player to collect final orb
	var lastOrbCollected:Bool = false; // Track when last orb is collected

	function startPhase0_5Ghosts(ghostsToSpawn:Array<CharacterData>):Void
	{
		gameState = PHASE_0_5_GHOSTS;
		player.active = false; // Player can't move during ghost spawning
		ghostsSpawningComplete = false;
		waitingForLastOrbPickup = false;
		lastOrbCollected = false;

		// Queue up ghosts for staggered spawning
		ghostSpawnQueue = ghostsToSpawn.copy();
		ghostSpawnTimer = 0;

		trace("Phase 0.5: Spawning " + ghostSpawnQueue.length + " ghosts...");
	}

	function updatePhase0_5Ghosts(elapsed:Float):Void
	{
		// Staggered ghost spawning
		if (ghostSpawnQueue.length > 0)
		{
			ghostSpawnTimer += elapsed;
			if (ghostSpawnTimer >= ghostSpawnInterval)
			{
				ghostSpawnTimer = 0;
				var charData = ghostSpawnQueue.shift();
				spawnSingleGhost(charData);
				trace("Spawned ghost: " + charData.name);
			}
			return; // Don't check for victory yet
		}
		
		// All ghosts spawned - if player not active yet, pan to player and start fight
		if (!ghostsSpawningComplete)
		{
			ghostsSpawningComplete = true;
			trace("All ghosts spawned - panning to player");
			FlxTween.tween(cameraTarget, {x: player.x, y: player.y}, 1.0, {
				ease: FlxEase.quadInOut,
				onComplete: function(t:FlxTween)
				{
					FlxG.camera.follow(player, LOCKON);
					player.active = true;
					// Activate all ghosts now that camera is on player
					ghosts.forEachAlive(function(ghost:Ghost)
					{
						ghost.active = true;
					});
					trace("Phase 0.5 fight started!");
				}
			});
			return;
		}
		
		// If waiting for last orb pickup, check if it's been collected
		if (waitingForLastOrbPickup && lastOrbCollected)
		{
			trace("Last orb collected - ending Phase 0.5");
			endPhase0_5Ghosts();
			return;
		}
		
		// Count how many ghosts are still alive
		var aliveCount:Int = 0;
		ghosts.forEachAlive(function(ghost:Ghost)
		{
			aliveCount++;
		});

		// If all ghosts are dead and player is active, wait for orb pickup
		if (aliveCount == 0 && player.active && !waitingForLastOrbPickup)
		{
			trace("All Phase 0.5 ghosts defeated! Waiting for orb pickup...");
			waitingForLastOrbPickup = true;
		}
	}

	function endPhase0_5Ghosts():Void
	{
		// Stop player control
		player.active = false;
		player.velocity.set(0, 0);

		// Wait 1 second after level up
		var timer = new haxe.Timer(1000);
		timer.run = function()
		{
			timer.stop();

			// Move player back to starting position using their speed stat
			var startX = (map.width / 2) - 4;
			var startY = map.height - 32;
			var distance = Math.sqrt(Math.pow(startX - player.x, 2) + Math.pow(startY - player.y, 2));
			var moveTime = distance / (40 * player.moveSpeed); // Base speed 40 * moveSpeed stat

			FlxG.camera.follow(player, LOCKON);

			FlxTween.tween(player, {x: startX, y: startY}, moveTime, {
				ease: FlxEase.linear,
				onComplete: function(t:FlxTween)
				{
					// Wait 1 second at destination
					var pauseTimer = new haxe.Timer(1000);
					pauseTimer.run = function()
					{
						pauseTimer.stop();

						// Pan camera back to egg
						FlxTween.tween(cameraTarget, {
							x: eggSprite.x + eggSprite.width / 2,
							y: eggSprite.y + eggSprite.height / 2
						}, 1.0, {
							ease: FlxEase.quadInOut,
							onComplete: function(t:FlxTween)
							{
								trace("Ghosts defeated - continuing with egg hatch");
								// Continue intro from EGG_PAUSE_1 (egg will now hatch)
								gameState = INTRO;
								introState = EGG_PAUSE_1;
								introTimer = 0;
							}
						});
					};
				}
			});
		};
	}
	function spawnSingleGhost(charData:CharacterData):Void
	{
		var ghost:Ghost = ghosts.getFirstAvailable();
		if (ghost == null)
		{
			ghost = new Ghost();
			ghosts.add(ghost);
		}
		ghost.spawn(charData, player, bossProjectiles);

		// Make ghost inactive and face center until all are spawned
		ghost.active = false;
		var centerX = map.width / 2;
		var centerY = map.height / 2;
		ghost.facingAngle = Math.atan2(centerY - ghost.y, centerX - ghost.x);

		// Set death callback to spawn spirit orb at ghost's shadow position
		ghost.onDeath = function(g:Ghost)
		{
			var orbX = g.x + g.width / 2;
			var orbY = g.y + g.height; // At the bottom (where shadow is)
			spawnSpiritOrb(orbX, orbY);
		};

		// Add ghost weapon hitboxes to scene (for melee weapons)
		if (Std.isOfType(ghost.weapon, Sword))
		{
			var sword:Sword = cast ghost.weapon;
			add(sword.getSlashHitbox());
			add(sword.getSpinHitbox());
		}
		else if (Std.isOfType(ghost.weapon, Halberd))
		{
			var halberd:Halberd = cast ghost.weapon;
			add(halberd.getJabHitbox());
		}
	}
	function startEggHatching():Void
	{
		// Continue the intro sequence from EGG_PAUSE_1 (ready to crack the egg)
		gameState = INTRO;
		introState = EGG_PAUSE_1;
		introTimer = 0.0;

		trace("Egg hatching sequence started");
	}

	function startBattle():Void
	{
		playerActive = true;
		player.active = true;
		boss.active = true;
		boss.setReady();
		FlxG.camera.follow(player, LOCKON);
		// Set game state to Phase 1 active
		gameState = PHASE_1_ACTIVE;
		trace("Phase 1 battle started!");
	}

	function spawnSpiritOrb(X:Float, Y:Float):Void
	{
		var orb:SpiritOrb = spiritOrbs.getFirstAvailable();
		if (orb == null)
		{
			orb = new SpiritOrb();
			spiritOrbs.add(orb);
		}
		orb.spawn(X, Y, player);

		// Set callback for when orb is collected during Phase 0.5
		if (gameState == PHASE_0_5_GHOSTS)
		{
			orb.onCollect = function()
			{
				// Check if this was the last orb (no more ghosts alive)
				var aliveCount:Int = 0;
				ghosts.forEachAlive(function(ghost:Ghost)
				{
					aliveCount++;
				});

				if (aliveCount == 0 && waitingForLastOrbPickup)
				{
					lastOrbCollected = true;
				}
			};
		}

		trace("Spirit orb spawned at (" + X + ", " + Y + ")");
	}

	function spawnGhosts():Void
	{
		var deadChars = GameData.getDeadCharacters();
		trace("Spawning " + deadChars.length + " ghosts...");

		for (charData in deadChars)
		{
			var ghost:Ghost = ghosts.getFirstAvailable();
			if (ghost == null)
			{
				ghost = new Ghost();
				ghosts.add(ghost);
			}
			ghost.spawn(charData, player, bossProjectiles);

			// Add ghost weapon hitboxes to scene (for melee weapons)
			if (Std.isOfType(ghost.weapon, Sword))
			{
				var sword:Sword = cast ghost.weapon;
				add(sword.getSlashHitbox());
				add(sword.getSpinHitbox());
			}
			else if (Std.isOfType(ghost.weapon, Halberd))
			{
				var halberd:Halberd = cast ghost.weapon;
				add(halberd.getJabHitbox());
			}
		}
	}

	function checkProjectileCollisions():Void
	{
		projectiles.forEachAlive(function(proj:Projectile)
		{
			if (proj.isStuck)
				return;

			if (proj.x < FlxG.worldBounds.left
				|| proj.x + proj.width > FlxG.worldBounds.right
				|| proj.y < FlxG.worldBounds.top
				|| proj.y + proj.height > FlxG.worldBounds.bottom)
			{
				proj.stick();
			}
		});

		bossProjectiles.forEachAlive(function(proj:Projectile)
		{
			if (proj.x < FlxG.worldBounds.left
				|| proj.x + proj.width > FlxG.worldBounds.right
				|| proj.y < FlxG.worldBounds.top
				|| proj.y + proj.height > FlxG.worldBounds.bottom)
			{
				proj.kill();
			}
		});
		// Update homing projectiles with targets
		updateHomingProjectiles();

		// Check player projectiles vs Mayflies
		FlxG.overlap(projectiles, mayflies, arrowHitMayfly);

		// Check player picking up hearts
		FlxG.overlap(player, hearts, playerPickupHeart);

		// Check melee weapon collisions
		checkMeleeWeaponCollisions();
	}

	function updateHomingProjectiles():Void
	{
		projectiles.forEachAlive(function(proj:Projectile)
		{
			// Check if this is a magic ball projectile with homing
			if (Std.isOfType(proj, Wand.MagicBallProjectile))
			{
				var magicBall:Wand.MagicBallProjectile = cast proj;

				if (magicBall.isHoming && !magicBall.isStuck)
				{
					// Find nearest enemy target
					var nearestEnemy = findNearestEnemy(magicBall.x + magicBall.width / 2, magicBall.y + magicBall.height / 2);
					magicBall.targetEnemy = nearestEnemy;
				}
			}
		});
	}

	function findNearestEnemy(fromX:Float, fromY:Float):FlxSprite
	{
		var nearest:FlxSprite = null;
		var nearestDist:Float = Math.POSITIVE_INFINITY;

		// Check boss segments
		if (boss != null && boss.alive && boss.visible)
		{
			for (segment in boss.members)
			{
				if (segment != null && segment.alive)
				{
					var dx = (segment.x + segment.width / 2) - fromX;
					var dy = (segment.y + segment.height / 2) - fromY;
					var dist = dx * dx + dy * dy; // Use squared distance to avoid sqrt

					if (dist < nearestDist)
					{
						nearestDist = dist;
						nearest = segment;
					}
				}
			}
		}

		// Check mayflies
		mayflies.forEachAlive(function(mayfly:Mayfly)
		{
			var dx = (mayfly.x + mayfly.width / 2) - fromX;
			var dy = (mayfly.y + mayfly.height / 2) - fromY;
			var dist = dx * dx + dy * dy;

			if (dist < nearestDist)
			{
				nearestDist = dist;
				nearest = mayfly;
			}
		});

		return nearest;
	}

	function checkMeleeWeaponCollisions():Void
	{
		// Check if player is using a melee weapon
		if (Std.isOfType(player.weapon, Sword))
		{
			var sword:Sword = cast player.weapon;
			// Check spin attack first (has priority during spin)
			if (sword.isSpinActive())
			{
				var spinHitbox = sword.getSpinHitbox();
				if (spinHitbox.exists && spinHitbox.alpha > 0)
				{
					// Spin attack can hit multiple enemies per frame
					// Check vs boss segments
					if (boss != null && boss.alive && boss.visible)
					{
						FlxG.overlap(spinHitbox, boss, function(h:FlxSprite, b:FlxSprite)
						{
							boss.takeDamage(sword.baseDamage * player.attackDamage * 0.7); // Slightly reduced damage per hit
						});
					}

					// Check vs mayflies
					FlxG.overlap(spinHitbox, mayflies, function(h:FlxSprite, m:Mayfly)
					{
						m.takeDamage(sword.baseDamage * player.attackDamage * 0.7);
					});

					// Check vs ghosts
					FlxG.overlap(spinHitbox, ghosts, function(h:FlxSprite, g:Ghost)
					{
						g.takeDamage(sword.baseDamage * player.attackDamage * 0.7);
					});
				}
			}
			else
			{
				// Normal slash attack
				var hitbox = sword.getSlashHitbox();

				if (hitbox.exists && hitbox.alpha > 0 && sword.canDealDamage())
				{
					var hitSomething = false;

					// Check vs boss segments
					if (boss != null && boss.alive && boss.visible)
					{
						FlxG.overlap(hitbox, boss, function(h:FlxSprite, b:FlxSprite)
						{
							if (!hitSomething)
							{
								boss.takeDamage(sword.baseDamage * player.attackDamage);
								hitSomething = true;
							}
						});
					}

					// Check vs mayflies (only if didn't hit boss)
					if (!hitSomething)
					{
						FlxG.overlap(hitbox, mayflies, function(h:FlxSprite, m:Mayfly)
						{
							if (!hitSomething)
							{
								m.takeDamage(sword.baseDamage * player.attackDamage);
								hitSomething = true;
							}
						});
					}
					// Check vs ghosts (only if didn't hit anything else)
					if (!hitSomething)
					{
						FlxG.overlap(hitbox, ghosts, function(h:FlxSprite, g:Ghost)
						{
							if (!hitSomething)
							{
								g.takeDamage(sword.baseDamage * player.attackDamage);
								hitSomething = true;
							}
						});
					}
					// Mark that this swing has dealt damage
					if (hitSomething)
					{
						sword.markHit();
					}
				}
			}
		}
		else if (Std.isOfType(player.weapon, Halberd))
		{
			var halberd:Halberd = cast player.weapon;
			var hitbox = halberd.getJabHitbox();

			if (halberd.isJabActive() && hitbox.exists && halberd.canDealDamage())
			{
				var hitSomething = false;

				// Check vs boss segments
				if (boss != null && boss.alive && boss.visible)
				{
					FlxG.overlap(hitbox, boss, function(h:FlxSprite, b:FlxSprite)
					{
						if (!hitSomething)
						{
							boss.takeDamage(halberd.baseDamage * player.attackDamage);
							hitSomething = true;
						}
					});
				}
				// Check vs mayflies (only if didn't hit boss)
				if (!hitSomething)
				{
					FlxG.overlap(hitbox, mayflies, function(h:FlxSprite, m:Mayfly)
					{
						if (!hitSomething)
						{
							m.takeDamage(halberd.baseDamage * player.attackDamage);
							hitSomething = true;
						}
					});
				}
				// Check vs ghosts (only if didn't hit anything else)
				if (!hitSomething)
				{
					FlxG.overlap(hitbox, ghosts, function(h:FlxSprite, g:Ghost)
					{
						if (!hitSomething)
						{
							g.takeDamage(halberd.baseDamage * player.attackDamage);
							hitSomething = true;
						}
					});
				}
				// Mark that this jab has dealt damage
				if (hitSomething)
				{
					halberd.markHit();
				}
			}
		}
	}

	function checkGhostCollisions():Void
	{
		// Check player projectiles vs ghosts
		FlxG.overlap(projectiles, ghosts, projectileHitGhost);

		// Check ghost projectiles (they use bossProjectiles group) vs player
		FlxG.overlap(player, bossProjectiles, playerHitProjectile);

		// Check ghost melee weapon hitboxes vs player
		ghosts.forEachAlive(function(ghost:Ghost)
		{
			if (ghost.weapon == null)
				return;

			if (Std.isOfType(ghost.weapon, Sword))
			{
				var sword:Sword = cast ghost.weapon;

				// Check spin attack first
				if (sword.isSpinActive())
				{
					var spinHitbox = sword.getSpinHitbox();
					if (spinHitbox.exists && spinHitbox.alpha > 0)
					{
						FlxG.overlap(spinHitbox, player, function(h:FlxSprite, p:Player)
						{
							// Ghosts deal 0.7 damage per spin hit (reduced from 1.0)
							p.takeDamage(0.7);
						});
					}
				}
				else
				{
					// Normal slash attack
					var hitbox = sword.getSlashHitbox();
					if (hitbox.exists && hitbox.alpha > 0 && sword.canDealDamage())
					{
						FlxG.overlap(hitbox, player, function(h:FlxSprite, p:Player)
						{
							// Ghosts deal 1.0 damage (1 heart) per hit
							p.takeDamage(1.0);
							sword.markHit();
						});
					}
				}
			}
			else if (Std.isOfType(ghost.weapon, Halberd))
			{
				var halberd:Halberd = cast ghost.weapon;
				var hitbox = halberd.getJabHitbox();
				if (halberd.isJabActive() && hitbox.exists && halberd.canDealDamage())
				{
					FlxG.overlap(hitbox, player, function(h:FlxSprite, p:Player)
					{
						// Ghosts deal 1.0 damage (1 heart) per hit
						p.takeDamage(1.0);
						halberd.markHit();
					});
				}
			}
		});
	}

	function checkBossCollisions():Void
	{
		if (!boss.alive || !boss.visible)
			return;

		// FlxG.overlap can handle groups directly
		FlxG.overlap(projectiles, boss, arrowHitBossSegment);
		FlxG.overlap(player, boss, playerHitBossSegment);
		FlxG.overlap(player, bossProjectiles, playerHitProjectile);
		// Check ghosts vs player projectiles and melee
		FlxG.overlap(projectiles, ghosts, projectileHitGhost);

		// Check melee weapons vs ghosts
		if (Std.isOfType(player.weapon, Sword))
		{
			var sword:Sword = cast player.weapon;
			var hitbox = sword.getSlashHitbox();
			if (hitbox.exists && hitbox.alpha > 0)
			{
				FlxG.overlap(hitbox, ghosts, function(h:FlxSprite, g:Ghost)
				{
					g.takeDamage(sword.baseDamage * player.attackDamage);
				});
			}
		}
		else if (Std.isOfType(player.weapon, Halberd))
		{
			var halberd:Halberd = cast player.weapon;
			var hitbox = halberd.getJabHitbox();
			if (halberd.isJabActive() && hitbox.exists)
			{
				FlxG.overlap(hitbox, ghosts, function(h:FlxSprite, g:Ghost)
				{
					g.takeDamage(halberd.baseDamage * player.attackDamage);
				});
			}
		}
	}

	function projectileHitGhost(proj:Projectile, ghost:Ghost):Void
	{
		if (proj.isStuck || !ghost.alive)
			return;

		ghost.takeDamage(proj.damage);
		proj.kill();
	}

	function arrowHitBossSegment(arrow:Projectile, segment:FlxSprite):Void
	{
		if (arrow.isStuck)
			return;

		boss.takeDamage(arrow.damage);
		arrow.kill();
	}

	function playerHitBossSegment(player:Player, segment:FlxSprite):Void
	{
		player.knockback(boss.x + boss.width / 2, boss.y + boss.height / 2, 300);

		if (!player.isInvincible)
		{
			player.takeDamage(boss.contactDamage);
		}
	}

	function playerHitProjectile(player:Player, proj:Projectile):Void
	{
		if (!player.isInvincible)
		{
			player.takeDamage(proj.damage);
			player.knockback(proj.x, proj.y, 200);
		}
		proj.kill();
	}
	function arrowHitMayfly(proj:Projectile, mayfly:Mayfly):Void
	{
		if (proj.isStuck || !mayfly.alive)
			return;

		mayfly.takeDamage(proj.damage);

		proj.kill();
	}

	function playerPickupHeart(player:Player, heart:HeartPickup):Void
	{
		heart.collect(player);
	}
	
	// ===== PHASE TRANSITION SYSTEM =====

	function startPhase1DeathSequence():Void
	{
		trace("Phase 1 boss defeated! Starting death sequence...");
		gameState = PHASE_1_DEATH;
		transitionTimer = 0;

		// Stop player and boss
		player.active = false;
		player.velocity.set(0, 0);
		boss.active = false;

		// Initialize cameraTarget to player position
		cameraTarget.setPosition(player.x + player.width / 2, player.y + player.height / 2);

		// Switch camera to following cameraTarget for cinematics
		FlxG.camera.follow(cameraTarget, LOCKON);

		// Pan camera to boss head using cameraTarget (smooth transition)
		var headPos = boss.getHeadPosition();
		FlxTween.tween(cameraTarget, {
			x: headPos.x,
			y: headPos.y
		}, 1.0, {ease: FlxEase.quadInOut});
	}

	function updatePhase1DeathSequence(elapsed:Float):Void
	{
		transitionTimer += elapsed;

		var cocoonCenterX = map.width / 2;
		var cocoonCenterY = 60;
		var bossTargetY = cocoonCenterY + cocoonSprite.height / 2;

		// Sequence: pan(1s) → roar(1.5s) → crawl(2.5s) → cocoon fade(1.5s) → pan back(1s)
		if (transitionTimer > 1.0 && transitionTimer <= 2.5)
		{
			if (transitionTimer - elapsed <= 1.0)
			{
				boss.roar();
				FlxG.camera.shake(0.01, 1.0);
			}
		}
		else if (transitionTimer > 2.5 && transitionTimer <= 5.0)
		{
			boss.moveTo(cocoonCenterX, bossTargetY, 40, elapsed);
			var headPos = boss.getHeadPosition();
			cameraTarget.setPosition(headPos.x, headPos.y);
		}
		else if (transitionTimer > 5.0 && transitionTimer <= 6.5)
		{
			boss.headX = cocoonCenterX;
			boss.headY = bossTargetY;
			cameraTarget.setPosition(boss.headX, boss.headY);

			if (cocoonSprite.alpha == 0)
			{
				cocoonSprite.setPosition(cocoonCenterX - cocoonSprite.width / 2, cocoonCenterY - cocoonSprite.height / 2);
				cocoonSprite.visible = true;
				shadowLayer.add(new Shadow(cocoonSprite, 1.2, 1.0, 0, 4, true));
				hud.setBossHealthVisible(false);
			}

			var fadeProgress = (transitionTimer - 5.0) / 1.5;
			cocoonSprite.alpha = fadeProgress;
			var bossAlpha = 1.0 - fadeProgress;

			boss.forEach(spr -> if (spr != null) spr.alpha = bossAlpha);
			for (shadow in boss.shadows)
				if (shadow != null && shadow.exists)
				{
					shadow.alpha = bossAlpha;
					if (bossAlpha <= 0)
						shadow.kill();
				}
			}
		else if (transitionTimer > 6.5 && transitionTimer <= 7.5)
		{
			if (boss.visible)
			{
				boss.visible = false;
				boss.die();
				// Now explicitly cleanup the boss sprites
				boss.forEach(function(spr:FlxSprite)
				{
					if (spr != null)
						spr.kill();
				});
			}
			if (transitionTimer - elapsed <= 6.5)
				FlxTween.tween(cameraTarget, {x: player.x + player.width / 2, y: player.y + player.height / 2}, 1.0, {ease: FlxEase.quadInOut});
		}
		else if (transitionTimer > 7.5)
		{
			FlxG.camera.follow(player, LOCKON);
			startPhase1_5();
		}
	}

	function startPhase1_5():Void
	{
		trace("Starting Phase 1.5 - Cocoon intermission (ALWAYS 1 minute minimum)");
		gameState = PHASE_1_5_ACTIVE;
		transitionTimer = 0;

		// Move player back to starting position
		var startX = (map.width / 2) - 4;
		var startY = map.height - 32;
		player.x = startX;
		player.y = startY;
		player.velocity.set(0, 0);

		// Pan camera back to player
		FlxTween.tween(cameraTarget, {
			x: player.x,
			y: player.y
		}, 1.0, {
			ease: FlxEase.quadInOut,
			onComplete: function(t:FlxTween)
			{
				FlxG.camera.follow(player, LOCKON);
				player.active = true;
			}
		});

		// Filter ghosts: only spawn those who died in Phase 1.5 (1) or Phase 2 (2)
		var allGhosts = GameData.getDeadCharacters();
		var phase1_5And2Ghosts = allGhosts.filter(function(char:CharacterData)
		{
			return char.deathPhase >= 1 && char.deathPhase <= 2;
		});

		if (phase1_5And2Ghosts.length > 0)
		{
			trace("Phase 1.5: Spawning " + phase1_5And2Ghosts.length + " Phase 1.5/2 ghosts");
			// Spawn staggered
			ghostSpawnQueue = phase1_5And2Ghosts.copy();
			ghostSpawnTimer = 0;
		}
		else
		{
			trace("Phase 1.5: No ghosts - player can farm healing for 1 minute");
		}
	}

	function updatePhase1_5(elapsed:Float):Void
	{
		transitionTimer += elapsed;

		// Staggered ghost spawning (reuse Phase 0.5 logic)
		if (ghostSpawnQueue.length > 0)
		{
			ghostSpawnTimer += elapsed;
			if (ghostSpawnTimer >= ghostSpawnInterval)
			{
				ghostSpawnTimer = 0;
				var charData = ghostSpawnQueue.shift();
				spawnSingleGhost(charData);
				trace("Spawned Phase 1.5 ghost: " + charData.name);
			}
		}

		// Count alive ghosts
		var aliveCount:Int = 0;
		ghosts.forEachAlive(function(ghost:Ghost)
		{
			aliveCount++;
		});

		// Phase 1.5 ALWAYS lasts minimum 60 seconds
		// AND all ghosts must be defeated
		if (transitionTimer >= 60.0 && aliveCount == 0)
		{
			trace("Phase 1.5 complete (1 min + ghosts defeated) - starting Phase 2 hatch");
			startPhase2HatchSequence();
		}
	}

	function startPhase2HatchSequence():Void
	{
		trace("Boss hatching into Phase 2!");
		gameState = PHASE_2_HATCH;
		transitionTimer = 0;

		// Stop player
		player.active = false;
		player.velocity.set(0, 0);

		// Move player back to starting position
		var startX = (map.width / 2) - 4;
		var startY = map.height - 32;
		player.x = startX;
		player.y = startY;

		// Pan to cocoon using cameraTarget
		FlxTween.tween(cameraTarget, {
			x: cocoonSprite.x + cocoonSprite.width / 2,
			y: cocoonSprite.y + cocoonSprite.height / 2
		}, 1.0, {
			ease: FlxEase.quadInOut,
			onComplete: function(t:FlxTween)
			{
				// Fade out cocoon
				FlxTween.tween(cocoonSprite, {alpha: 0}, 1.0, {
					onComplete: function(t:FlxTween)
					{
						cocoonSprite.visible = false;
						spawnPhase2Boss();
					}
				});
			}
		});
	}

	function spawnPhase2Boss():Void
	{
		trace("Spawning Phase 2 boss!");

		// Create Phase 2 boss at cocoon position
		boss2 = new BossPhase02(cocoonSprite.x, cocoonSprite.y);
		boss2.alpha = 0;
		add(boss2);

		// Create shadows
		boss2.createShadows(shadowLayer);

		// Fade in
		FlxTween.tween(boss2, {alpha: 1}, 1.5, {
			onComplete: function(t:FlxTween)
			{
				// Activate Phase 2
				boss2.activate();
				gameState = PHASE_2_ACTIVE;

				// Tween camera back to player
				FlxTween.tween(cameraTarget, {x: player.x, y: player.y}, 1.0, {
					ease: FlxEase.quadInOut,
					onComplete: function(t:FlxTween)
					{
						// Reactivate player
						player.active = true;
						trace("Phase 2 active!");
					}
				});
			}
		});
	}

	function checkPhase2Collisions():Void
	{
		if (boss2 == null || !boss2.exists || !boss2.isActive)
			return;

		// Check player projectiles hitting boss body parts
		projectiles.forEachAlive(function(p:Projectile)
		{
			// Check collision with main body parts (thorax, head, abdomen)
			if (p.overlaps(boss2.thorax) || p.overlaps(boss2.head) || p.overlaps(boss2.abdomen))
			{
				boss2.takeDamage(player.attackDamage);
				p.kill();
			}
		});

		// Check boss hitting player (when charging)
		if (boss2.attackState == CHARGE_ATTACKING)
		{
			// Check if any body part hits player
			if (player.overlaps(boss2.thorax) || player.overlaps(boss2.head) || player.overlaps(boss2.abdomen))
			{
				player.takeDamage(1);
				player.knockback(boss2.x + boss2.width / 2, boss2.y + boss2.height / 2, 150);
			}
		}
	}

	function updateMayflySpawning(elapsed:Float):Void
	{
		mayflySpawnTimer += elapsed;
		
		var activeMayflies = mayflies.countLiving();
		var spawnRate = activeMayflies == 0 ? 1.0 : 3.0;

		if (mayflySpawnTimer >= spawnRate && activeMayflies < 4)
		{
			mayflySpawnTimer = FlxG.random.float(0, 0.5);

			var mayfly = mayflies.getFirstAvailable();
			if (mayfly == null)
			{
				mayfly = new Mayfly();
				mayflies.add(mayfly);
			}
			mayfly.spawn();
		}
	}

	public function spawnHeart(Pos:FlxPoint):Void
	{
		var heart:HeartPickup = hearts.getFirstAvailable();
		if (heart == null)
		{
			heart = new HeartPickup();
			hearts.add(heart);
		}
		heart.spawn(Pos);
	}
	function updatePhase2_5(elapsed:Float):Void
	{
		transitionTimer += elapsed;

		var aliveCount:Int = 0;
		ghosts.forEachAlive(function(ghost:Ghost)
		{
			aliveCount++;
		});

		if (aliveCount == 0)
		{
			trace("All Phase 2.5 ghosts defeated! Proceeding to Phase 2 hatch.");
			startPhase2HatchSequence();
			return;
		}

		// Safety timeout
		if (transitionTimer > 60.0)
		{
			trace("Phase 2.5 intermission timeout - forcing Phase 2 hatch");
			startPhase2HatchSequence();
		}
	}
}

enum GameState
{
	INTRO; // Phase 0: Fade in, pan to egg, pause - ends at egg pause
	PHASE_0_5_GHOSTS; // Phase 0.5: Ghost spawning/fighting (before egg hatches) - only if ghosts died in Phase 0/1
	PHASE_1_ACTIVE; // Phase 1: Egg hatches, boss emerges, fight until boss dies
	PHASE_1_DEATH; // Phase 1: Boss death sequence (moves up, cocoon forms)
	PHASE_1_5_ACTIVE; // Phase 1.5: ALWAYS happens - min 1 minute, ghosts if died in Phase 1.5/2
	PHASE_2_HATCH; // Phase 2: Boss emerges from cocoon
	PHASE_2_ACTIVE; // Phase 2: Boss fight
	PHASE_2_DEATH; // Phase 2 boss death
	PHASE_2_5_ACTIVE; // Phase 2.5: Husk intermission (if applicable)
	PHASE_3_HATCH; // Phase 3 boss emergence
	PHASE_3_ACTIVE; // Phase 3 boss fight
}

enum IntroState
{
	FADE_IN;
	SCROLL_TO_EGG;
	SCROLLING;
	EGG_PAUSE_1;
	EGG_CRACK_1;
	EGG_PAUSE_2;
	EGG_CRACK_2;
	EGG_PAUSE_3;
	EGG_CRACK_REST;
	EGG_PAUSE_4;
	BOSS_FADE_IN;
	BOSS_DESCEND;
	BOSS_UNFURL;
	HEALTH_BAR_APPEAR;
	HEALTH_BAR_PAUSE;
	HEALTH_BAR_FILL;
	BOSS_ROAR;
	SCROLL_TO_PLAYER;
	COMPLETE;
}