package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.tile.FlxBaseTilemap.FlxTilemapAutoTiling;
import flixel.tile.FlxTilemap;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

class PlayState extends FlxState
{
	var map:FlxTilemap;
	public var player:Player;

	var projectiles:FlxTypedGroup<Projectile>;
	var bossProjectiles:FlxTypedGroup<Projectile>;
	var hud:HUD;
	// Boss phases
	var boss:BossPhase01Larva;
	var boss2:BossPhase02;
	var currentBossPhase:Int = 1;
	
	var cameraTarget:FlxObject;

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

	override public function create()
	{
		super.create();
		Actions.init();

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
			checkProjectileCollisions();
			// No boss collisions during cocoon phase
		}
		else if (gameState == PHASE_2_ACTIVE)
		{
			// TODO: Check Phase 2 boss defeat
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
	}

	function checkBossCollisions():Void
	{
		if (!boss.alive || !boss.visible)
			return;

		for (segment in boss.members)
		{
			if (segment != null && segment.alive)
			{
				FlxG.overlap(projectiles, segment, arrowHitBossSegment);
				FlxG.overlap(player, segment, playerHitBossSegment);
			}
		}
		FlxG.overlap(player, bossProjectiles, playerHitProjectile);
	}

	function arrowHitBossSegment(arrow:Projectile, segment:FlxSprite):Void
	{
		if (arrow.isStuck)
			return;

		boss.takeDamage(arrow.damage);
		arrow.stick();
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

		// Pan camera to boss head (smooth transition)
		FlxTween.tween(FlxG.camera.scroll, {
			x: boss.headSegment.sprite.x - FlxG.width / 2 + boss.headSegment.sprite.width / 2,
			y: boss.headSegment.sprite.y - FlxG.height / 2 + boss.headSegment.sprite.height / 2
		}, 1.0, {ease: FlxEase.quadInOut});
	}

	function updatePhase1DeathSequence(elapsed:Float):Void
	{
		transitionTimer += elapsed;

		// Sequence: pan(1s) → roar(1.5s) → crawl up(2.5s) → fade cocoon(1.5s) → wait(0.5s)

		var targetX = map.width / 2;
		var targetY = 60; // Near top of screen

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
			// Smoothly crawl upward to center top using boss's moveTo
			boss.moveTo(targetX, targetY, 40, elapsed);
		}
		else if (transitionTimer > 5.0 && transitionTimer < 6.5)
		{
			// Make sure boss is at final position before spawning cocoon
			boss.headX = targetX;
			boss.headY = targetY;

			// Fade in cocoon over boss and hide health bar
			if (cocoonSprite.alpha == 0)
			{
				trace("Spawning cocoon...");
				cocoonSprite.x = boss.headX - cocoonSprite.width / 2;
				cocoonSprite.y = boss.headY - cocoonSprite.height / 2;
				cocoonSprite.visible = true;

				// Create shadow for cocoon using alpha channel
				// Width: 1.2x, Height: 1.0x, Anchor: center.x, center.y + 4
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
		else if (transitionTimer > 7.0)
		{
			// Hide boss, start Phase 1.5
			boss.visible = false;
			boss.die();

			startPhase1_5();
		}
	}

	function startPhase1_5():Void
	{
		trace("Starting Phase 1.5 - Cocoon intermission");
		gameState = PHASE_1_5_ACTIVE;
		transitionTimer = 0;

		// Pan camera back to player
		FlxTween.tween(FlxG.camera.scroll, {
			x: player.x - FlxG.width / 2 + player.width / 2,
			y: player.y - FlxG.height / 2 + player.height / 2
		}, 1.0, {
			ease: FlxEase.quadInOut,
			onComplete: function(t:FlxTween)
			{
				// Reactivate player
				player.active = true;
				FlxG.camera.follow(player, LOCKON, 1);
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

		// Pan to cocoon
		FlxTween.tween(FlxG.camera.scroll, {
			x: cocoonSprite.x + cocoonSprite.width / 2 - FlxG.width / 2,
			y: cocoonSprite.y + cocoonSprite.height / 2 - FlxG.height / 2
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

				// Reactivate player and camera
				player.active = true;
				FlxG.camera.follow(player, LOCKON, 1);

				trace("Phase 2 active!");
			}
		});
	}

	function checkPhase2Collisions():Void
	{
		// TODO: Implement Phase 2 collision detection
		// For now, just basic overlap with all parts
		if (boss2 != null && boss2.exists)
		{
			// TODO: Add proper collision for each body part
		}
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