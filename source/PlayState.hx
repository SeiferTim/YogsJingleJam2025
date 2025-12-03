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
	var boss:BossPhase01Larva;
	var cameraTarget:FlxObject;

	var introState:IntroState = FADE_IN;
	var introTimer:Float = 0;
	var fadeOverlay:FlxSprite;
	var eggSprite:FlxSprite;
	var playerActive:Bool = false;

	override public function create()
	{
		super.create();
		Actions.init();

		map = new FlxTilemap();
		map.loadMapFromCSV("assets/maps/base.csv", "assets/images/lofi_environment.png", 8, 8, FlxTilemapAutoTiling.OFF, 0, 0);
		add(map);

		FlxG.worldBounds.set(8, 8, map.width - 16, map.height - 16);

		// Create projectile groups (but don't add yet - add after player/boss for proper layering)
		projectiles = new FlxTypedGroup<Projectile>();
		bossProjectiles = new FlxTypedGroup<Projectile>();

		eggSprite = new FlxSprite(0, 0);
		eggSprite.loadGraphic("assets/images/boss-phase-00-egg.png", true, 256, 144);
		eggSprite.animation.frameIndex = 0;
		eggSprite.visible = false;
		add(eggSprite);

		player = new Player((map.width / 2) - 4, map.height - 32, projectiles);
		player.active = false;
		add(player);

		// Boss spawns at center of egg sprite
		var bossSpawnX = eggSprite.x + eggSprite.width / 2;
		var bossSpawnY = eggSprite.y + eggSprite.height / 2;
		boss = new BossPhase01Larva(bossSpawnX, bossSpawnY, null, bossProjectiles);
		boss.visible = true; // Always visible, but starts at alpha 0
		boss.active = false;
		boss.currentHealth = 0;
		add(boss); // Add projectiles AFTER player and boss so they render on top
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
		if (!playerActive)
		{
			updateIntroSequence(elapsed);
		}
		else
		{
			checkProjectileCollisions();
			checkBossCollisions();
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
				var targetY = map.height - 80;

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