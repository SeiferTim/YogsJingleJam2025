package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

/**
 * Ghost - Previous player character, pooled like Mayfly
 * Spawns with fade-in animation at random position above arena midpoint
 * Uses the same weapon they died with
 */
class Ghost extends GameEntity
{
	// Static spawn counter for animation stagger - resets at phase start
	private static var spawnCounter:Int = 0;

	public static function resetSpawnCounter():Void
	{
		spawnCounter = 0;
	}
	
	public static function getSpawnCounter():Int
	{
		return spawnCounter;
	}

	public static function incrementSpawnCounter():Void
	{
		spawnCounter++;
	}
	
	public var characterData:CharacterData;

	// AI
	var player:Player;
	var projectiles:FlxTypedGroup<Projectile>;
	var baseSpeed:Float = 40;
	var optimalDistance:Float = 64;
	var attackTimer:Float = 0;
	var attackCooldown:Float = 3.0;
	var spawnProtectionTimer:Float = 0; // Grace period before ghost can attack

	public var facingAngle:Float = 0;

	// Callback for when ghost is killed (used to spawn spirit orb)
	public var onDeath:Ghost->Void;

	public function new()
	{
		super();
		loadGraphic("assets/images/players.png", true, 8, 8);
		animation.frameIndex = 0;
		antialiasing = false;
		alpha = 0;
		color = 0xBBBBDD; // Ghostly tint
		kill();
		Sound.playSound("ghost_defeat");
	}

	public function spawn(Data:CharacterData, Player:Player, Projectiles:FlxTypedGroup<Projectile>, ?eggX:Float, ?eggY:Float):Void
	{
		characterData = Data;
		player = Player;
		projectiles = Projectiles;

		Sound.playSound("ghost_spawn");

		// Convert hearts to HP: 10 HP per heart (maxHP is number of hearts)
		currentHealth = Data.maxHP * 10;
		animation.frameIndex = Data.spriteFrame;

		// Base cooldown based on weapon type (wands fire slower)
		var baseCooldown = switch (Data.weaponType)
		{
			case WAND: 5.0; // Wands are slower
			case BOW: 3.0; // Normal speed
			case SWORD | HALBERD: 2.5; // Melee slightly faster
		}
		// Ghosts are slower than they were in life (nerf their speed stat by 50%)
		var nerfedSpeed = Data.moveSpeed * 0.5;
		attackCooldown = baseCooldown / (1.0 + nerfedSpeed * 0.5);

		// Create weapon instance based on character's weapon type
		weapon = createWeapon(Data.weaponType, Projectiles);

		// Adjust optimal distance based on weapon type
		optimalDistance = switch (Data.weaponType)
		{
			case BOW | WAND: 64; // Ranged weapons keep distance
			case SWORD | HALBERD: 16; // Melee weapons get close
		}

		// Spawn above arena midpoint, avoiding egg area if coordinates provided
		var arenaHeight = FlxG.worldBounds.height;
		var upperArea = FlxG.worldBounds.top + (arenaHeight * 0.4);
		var spawnX:Float;
		var spawnY:Float;
		var attempts = 0;
		var maxAttempts = 20;

		do
		{
			spawnX = FlxG.random.float(FlxG.worldBounds.left + 16, FlxG.worldBounds.right - 24);
			spawnY = FlxG.random.float(FlxG.worldBounds.top + 16, upperArea);
			attempts++;
		}
		while (eggX != null
				&& eggY != null
				&& Math.sqrt(Math.pow(spawnX - eggX, 2) + Math.pow(spawnY - eggY, 2)) < 64
				&& attempts < maxAttempts);

		reset(spawnX, spawnY);

		setupShadow("player"); // Ghosts use player shadow graphic

		// Ghost spawns behind the white ghost with semi-transparent appearance
		alpha = 0.9;

		// Use static counter for stagger (used by white ghost animation in PlayState)
		var staggerDelay = spawnCounter * 0.5;
		spawnCounter++; // Increment for next ghost

		// Set spawn protection: 2 seconds after white ghost animation completes
		spawnProtectionTimer = staggerDelay + 1.0 + 2.0;
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (player == null || !player.alive)
			return;

		if (weapon != null)
			weapon.update(elapsed);

		// Count down spawn protection timer
		if (spawnProtectionTimer > 0)
			spawnProtectionTimer -= elapsed;

		updateAI(elapsed);

		if (attackTimer > 0)
			attackTimer -= elapsed;
	}

	function updateAI(elapsed:Float):Void
	{
		var dx = player.x - x;
		var dy = player.y - y;
		var dist = Math.sqrt(dx * dx + dy * dy);

		facingAngle = Math.atan2(dy, dx);

		// Ghosts are slower/less agile than they were in life (50% speed nerf)
		var nerfedSpeed = characterData.moveSpeed * 0.5;

		// Maintain optimal distance
		if (dist > optimalDistance + 16)
		{
			velocity.set(Math.cos(facingAngle) * baseSpeed * nerfedSpeed, Math.sin(facingAngle) * baseSpeed * nerfedSpeed);
		}
		else if (dist < optimalDistance - 16)
		{
			velocity.set(-Math.cos(facingAngle) * baseSpeed * nerfedSpeed, -Math.sin(facingAngle) * baseSpeed * nerfedSpeed);
		}
		else
		{
			velocity.x *= 0.8;
			velocity.y *= 0.8;
		}

		// Constrain to bounds
		x = Math.max(FlxG.worldBounds.left + 8, Math.min(FlxG.worldBounds.right - width - 8, x));
		y = Math.max(FlxG.worldBounds.top + 8, Math.min(FlxG.worldBounds.bottom - height - 8, y));

		// Attack using weapon (only if spawn protection has expired)
		if (spawnProtectionTimer <= 0 && attackTimer <= 0 && dist < 128)
		{
			useWeapon();
			attackTimer = attackCooldown;
		}
	}

	function useWeapon():Void
	{
		if (weapon == null)
			return;

		// For ranged weapons (bow/wand): use tap for immediate fire
		if (Std.isOfType(weapon, Arrow) || Std.isOfType(weapon, Wand))
		{
			weapon.tap(); // Just tap instead of charge+release
		}
		// For melee weapons (sword/halberd): trigger attack
		else if (Std.isOfType(weapon, Sword))
		{
			var sword:Sword = cast weapon;
			sword.sweep();
		}
		else if (Std.isOfType(weapon, Halberd))
		{
			var halberd:Halberd = cast weapon;
			halberd.jab();
		}
	}

	override public function takeDamage(damage:Float, ?damageInstanceId:String):Void
	{
		// Don't take damage if already dead
		if (!alive)
			return;
			
		// Check cooldown using DamageTracker from base class
		if (!damageTracker.canTakeDamageFrom(damageInstanceId))
		{
			return; // Still on cooldown for this specific instance
		}
		
		currentHealth -= damage;
		
		// Flash effect
		FlxTween.cancelTweensOf(this, ["color"]);
		color = FlxColor.RED;
		FlxTween.tween(this, {color: 0xBBBBDD}, 0.1);
		// Record hit AFTER applying damage
		damageTracker.recordHit(damageInstanceId);

		if (currentHealth <= 0)
		{
			// TODO: Spawn XP orb in PlayState
			kill();
		}
	}

	override function kill():Void
	{
		// Stop movement immediately
		velocity.set(0, 0);
		active = false;
		alive = false; // Prevent further damage or orb spawns
	
		// Trigger death callback FIRST (spawns soul orb)
		if (onDeath != null)
			onDeath(this);

		// If characterData is null (e.g., during initialization), just kill immediately
		if (characterData == null)
		{
			super.kill(); // GameEntity handles shadow cleanup
			return;
		} // Switch to death frame (living frame + 8)
		var deathFrame = characterData.spriteFrame + 8;
		
		// Check if death frame exists (players.png should have 16 frames: 0-7 living, 8-15 dead)
		if (deathFrame < 16)
		{
			animation.frameIndex = deathFrame;
			
			// Fade out after showing death frame
			FlxTween.tween(this, {alpha: 0}, 0.5, {
				startDelay: 0.3, // Show death frame briefly
				onComplete: function(t:FlxTween)
				{
					actuallyKill();
				}
			});
		}
		else
		{
			// No death frame available, kill immediately
			actuallyKill();
		}
	}

	function actuallyKill():Void
	{
		FlxTween.cancelTweensOf(this);
		super.kill(); // GameEntity handles shadow cleanup
	}
}
