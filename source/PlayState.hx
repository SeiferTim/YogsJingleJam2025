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
	var hearts:FlxTypedGroup<HeartPickup>;

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
	var gameState:GameState = INTRO;
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
		hearts = new FlxTypedGroup<HeartPickup>(10);

		add(hearts);
		

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
			player.attackCooldown = selectedCharacter.attackCooldown;

			// Set the character sprite frame from the selected character
			player.animation.frameIndex = selectedCharacter.spriteFrame;

			// Set the weapon based on character's weapon type
			player.setWeapon(selectedCharacter.weaponType);
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
			case FADE_IN:

			case SCROLL_TO_EGG:
				if (introTimer > 0.8)
				{
					// Move camera target to egg - slower, more deliberate
					FlxTween.tween(cameraTarget, {y: eggSprite.y + eggSprite.height / 2}, 2.0, {
						ease: FlxEase.quadInOut,
						onComplete: function(t:FlxTween)
						{
							introState = EGG_PAUSE_1;
							introTimer = 0;
						}
					});
					introState = SCROLLING;
				}

			case SCROLLING:

			case EGG_PAUSE_1:
				if (introTimer > 0.4)
				{
					introState = EGG_CRACK_1;
					introTimer = 0;
				}

			case EGG_CRACK_1:
				eggSprite.animation.frameIndex = 1;
				if (introTimer > 0.05)
				{
					introState = EGG_PAUSE_2;
					introTimer = 0;
				}

			case EGG_PAUSE_2:
				if (introTimer > 0.4)
				{
					introState = EGG_CRACK_2;
					introTimer = 0;
				}

			case EGG_CRACK_2:
				eggSprite.animation.frameIndex = 2;
				if (introTimer > 0.05)
				{
					introState = EGG_PAUSE_3;
					introTimer = 0;
				}

			case EGG_PAUSE_3:
				if (introTimer > 0.4)
				{
					introState = EGG_CRACK_REST;
					introTimer = 0;
				}

			case EGG_CRACK_REST:
				if (introTimer < 0.3)
				{
					var frameProgress = introTimer / 0.3;
					eggSprite.animation.frameIndex = 2 + Math.floor(frameProgress * 3);
				}
				else if (eggSprite.animation.frameIndex < 4)
				{
					eggSprite.animation.frameIndex = 4;
				}

				if (introTimer > 0.5)
				{
					introState = EGG_PAUSE_4;
					introTimer = 0;
				}

			case EGG_PAUSE_4:
				if (introTimer > 0.3)
				{
					boss.active = true;
					introState = BOSS_FADE_IN;
					introTimer = 0;
				}

			case BOSS_FADE_IN:
				var progress = Math.min(introTimer / 1.5, 1.0);
				boss.fadeIn(progress);

				if (progress >= 1.0)
				{
					introState = BOSS_UNFURL;
					introTimer = 0;
				}

			case BOSS_UNFURL:
				var progress = Math.min(introTimer / 1.5, 1.0);
				boss.unfurl(progress);

				var headPos = boss.getHeadPosition();
				cameraTarget.x = headPos.x;
				cameraTarget.y = headPos.y;

				if (progress >= 1.0)
				{
					introState = BOSS_DESCEND;
					introTimer = 0;
				}

			case BOSS_DESCEND:
				var targetX = map.width / 2;
				var targetY = map.height - 64; // Changed from 80 to 64 (16px lower)

				boss.moveTo(targetX, targetY, 40, elapsed);

				var headPos = boss.getHeadPosition();
				cameraTarget.x = headPos.x;
				cameraTarget.y = headPos.y;

				if (boss.isAtPosition(targetX, targetY))
				{
					introState = HEALTH_BAR_APPEAR;
					introTimer = 0;
				}

			case HEALTH_BAR_APPEAR:
				if (introTimer < 0.5)
				{
					hud.setAlpha(introTimer / 0.5);
				}
				else
				{
					hud.setAlpha(1);
				}

				if (introTimer > 0.05 && !hud.visible)
				{
					hud.visible = true;
				}

				if (introTimer > 0.8)
				{
					introState = HEALTH_BAR_PAUSE;
					introTimer = 0;
				}

			case HEALTH_BAR_PAUSE:
				if (introTimer > 0.4)
				{
					introState = HEALTH_BAR_FILL;
					introTimer = 0;
					boss.currentHealth = 0;
					// Start revealing boss name as health bar fills
					hud.revealBossName();
				}

			case HEALTH_BAR_FILL:
				if (introTimer < 1.0)
				{
					boss.currentHealth = FlxMath.lerp(0, boss.maxHealth, introTimer / 1.0);
				}
				else if (boss.currentHealth < boss.maxHealth)
				{
					boss.currentHealth = boss.maxHealth;
				}

				if (introTimer > 1.2)
				{
					introState = BOSS_ROAR;
					introTimer = 0;
				}

			case BOSS_ROAR:
				if (introTimer < 0.05)
				{
					boss.roar();
					FlxG.camera.shake(0.02, 0.4);
				}

				// Fade egg during roar
				if (introTimer < 0.8)
				{
					eggSprite.alpha = 1.0 - (introTimer / 0.8);
				}
				else if (eggSprite.visible)
				{
					eggSprite.visible = false;
				}

				if (introTimer > 1.0)
				{
					boss.closeRoar();
				}

				if (introTimer > 1.5)
				{
					// Quick pan back to player
					FlxTween.tween(cameraTarget, {x: player.x, y: player.y}, 0.5, {
						ease: FlxEase.quadInOut,
						onComplete: function(t:FlxTween)
						{
							introState = COMPLETE;
							startBattle();
						}
					});
					introState = SCROLL_TO_PLAYER;
				}

			case SCROLL_TO_PLAYER:

			case COMPLETE:
		}
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
			var hitbox = sword.getSlashHitbox();

			if (hitbox.exists && hitbox.alpha > 0)
			{
				// Check vs boss segments
				if (boss != null && boss.alive && boss.visible)
				{
					FlxG.overlap(hitbox, boss, function(h:FlxSprite, b:FlxSprite)
					{
						boss.takeDamage(sword.baseDamage * player.attackDamage);
					});
				}

				// Check vs mayflies
				FlxG.overlap(hitbox, mayflies, function(h:FlxSprite, m:Mayfly)
				{
					m.takeDamage(sword.baseDamage * player.attackDamage);
				});
			}
		}
		else if (Std.isOfType(player.weapon, Halberd))
		{
			var halberd:Halberd = cast player.weapon;
			var hitbox = halberd.getJabHitbox();

			if (halberd.isJabActive() && hitbox.exists)
			{
				// Check vs boss segments
				if (boss != null && boss.alive && boss.visible)
				{
					FlxG.overlap(hitbox, boss, function(h:FlxSprite, b:FlxSprite)
					{
						boss.takeDamage(halberd.baseDamage * player.attackDamage);
					});
				}
				// Check vs mayflies
				FlxG.overlap(hitbox, mayflies, function(h:FlxSprite, m:Mayfly)
				{
					m.takeDamage(halberd.baseDamage * player.attackDamage);
				});
			}
		}
	}

	function checkBossCollisions():Void
	{
		if (!boss.alive || !boss.visible)
			return;

		// FlxG.overlap can handle groups directly
		FlxG.overlap(projectiles, boss, arrowHitBossSegment);
		FlxG.overlap(player, boss, playerHitBossSegment);
		FlxG.overlap(player, bossProjectiles, playerHitProjectile);
	}

	function arrowHitBossSegment(arrow:Projectile, segment:FlxSprite):Void
	{
		if (arrow.isStuck)
			return;

		boss.takeDamage(arrow.damage);
		if (Std.isOfType(arrow, Wand.FireballProjectile))
		{
			var fireball:Wand.FireballProjectile = cast arrow;
			boss.applyBurn(fireball.burnDuration, fireball.burnDamagePerSecond);
		}
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

		// Sequence: pan(1s) → roar(1.5s) → crawl up(2.5s) → align with cocoon → fade cocoon(1.5s) → pan back to player

		// Position where cocoon will appear
		var cocoonCenterX = map.width / 2;
		var cocoonCenterY = 60; // Near top of screen

		// Calculate where boss head should be (aligned with bottom of cocoon)
		var bossTargetY = cocoonCenterY + (cocoonSprite.height / 2); // Bottom of cocoon

		if (transitionTimer > 1.0 && transitionTimer < 2.5)
		{
			// Roar animation (trigger once at 1 second mark)
			if (transitionTimer - elapsed <= 1.0)
			{
				trace("Boss roaring...");
				boss.roar(); // Opens mouth and pincers

				// Screen shake
				FlxG.camera.shake(0.01, 1.0);
			}
		}
		else if (transitionTimer > 2.5 && transitionTimer < 5.0)
		{
			// Smoothly crawl upward to align with cocoon bottom
			boss.moveTo(cocoonCenterX, bossTargetY, 40, elapsed);

			// Track boss head with camera during movement
			var headPos = boss.getHeadPosition();
			cameraTarget.x = headPos.x;
			cameraTarget.y = headPos.y;
		}
		else if (transitionTimer > 5.0 && transitionTimer < 6.5)
		{
			// Make sure boss is at final position
			boss.headX = cocoonCenterX;
			boss.headY = bossTargetY;

			// Keep camera on boss head
			cameraTarget.x = boss.headX;
			cameraTarget.y = boss.headY;

			// Fade in cocoon over boss (aligned so boss head is at cocoon bottom)
			if (cocoonSprite.alpha == 0)
			{
				trace("Spawning cocoon...");
				cocoonSprite.x = cocoonCenterX - cocoonSprite.width / 2;
				cocoonSprite.y = cocoonCenterY - cocoonSprite.height / 2;
				cocoonSprite.visible = true;

				// Create shadow for cocoon
				var cocoonShadow = new Shadow(cocoonSprite, 1.2, 1.0, 0, 4, true);
				shadowLayer.add(cocoonShadow);

				// Hide health bar
				hud.setBossHealthVisible(false);
			}
			var fadeProgress = (transitionTimer - 5.0) / 1.5;
			cocoonSprite.alpha = fadeProgress;

			// Fade out boss segments
			var bossAlpha = 1.0 - fadeProgress;
			boss.forEach(function(spr:FlxSprite)
			{
				if (spr != null)
					spr.alpha = bossAlpha;
			});

			// Fade out shadows too and kill them when fully transparent
			for (shadow in boss.shadows)
			{
				if (shadow != null && shadow.exists)
				{
					shadow.alpha = bossAlpha;
					if (bossAlpha <= 0)
						shadow.kill();
				}
			}
		}
		else if (transitionTimer > 6.5 && transitionTimer < 7.5)
		{
			// Remove boss
			if (boss.visible)
			{
				boss.visible = false;
				boss.die();
			}

			// Pan camera back to player
			if (transitionTimer - elapsed <= 6.5)
			{
				trace("Panning camera back to player...");
				FlxTween.tween(cameraTarget, {
					x: player.x + player.width / 2,
					y: player.y + player.height / 2
				}, 1.0, {ease: FlxEase.quadInOut});
			}
		}
		else if (transitionTimer > 7.5)
		{
			// Switch camera back to following player
			FlxG.camera.follow(player, LOCKON);

			// Start Phase 1.5
			startPhase1_5();
		}
	}

	function startPhase1_5():Void
	{
		trace("Starting Phase 1.5 - Cocoon intermission");
		gameState = PHASE_1_5_ACTIVE;
		transitionTimer = 0;

		// Pan camera back to player using cameraTarget
		FlxTween.tween(cameraTarget, {
			x: player.x,
			y: player.y
		}, 1.0, {
			ease: FlxEase.quadInOut,
			onComplete: function(t:FlxTween)
			{
				// Reactivate player
				player.active = true;
			}
		});

		// TODO: Spawn Phase 2 ghosts here (if any saved)
		// For now, just wait 30 seconds
	}

	function updatePhase1_5(elapsed:Float):Void
	{
		transitionTimer += elapsed;

		// TODO: Check if all ghosts defeated
		// For now, just wait 30 seconds

		if (transitionTimer > 30.0)
		{
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
		var activeMayflies = mayflies.countLiving();

		var spawnRate = activeMayflies == 0 ? 1.0 : 3.0;

		if (mayflySpawnTimer < spawnRate)
		{
			mayflySpawnTimer += elapsed;
		}
		else if (activeMayflies < 4)
		{
			// Slight random variance to spawn timer
			mayflySpawnTimer += FlxG.random.float(0, 0.5);
			var mayfly:Mayfly = mayflies.getFirstAvailable();
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
}

enum GameState
{
	INTRO;
	PHASE_1_ACTIVE;
	PHASE_1_DEATH;
	PHASE_1_5_ACTIVE;
	PHASE_2_HATCH;
	PHASE_2_ACTIVE;
	// TODO: Add more phases
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