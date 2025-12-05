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
class Ghost extends FlxSprite
{
	public var shadow:Shadow;
	public var characterData:CharacterData;
	public var currentHealth:Float = 10;
	public var weapon:Weapon; // The ghost's weapon instance

	// AI
	var player:Player;
	var projectiles:FlxTypedGroup<Projectile>;
	var baseSpeed:Float = 40;
	var optimalDistance:Float = 64;
	var attackTimer:Float = 0;
	var attackCooldown:Float = 3.0;

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
	}

	public function spawn(Data:CharacterData, Player:Player, Projectiles:FlxTypedGroup<Projectile>):Void
	{
		characterData = Data;
		player = Player;
		projectiles = Projectiles;

		// Convert hearts to HP: 10 HP per heart (maxHP is number of hearts)
		currentHealth = Data.maxHP * 10;
		animation.frameIndex = Data.spriteFrame;
		attackCooldown = 3.0 / (1.0 + Data.moveSpeed * 0.5);

		// Create weapon instance based on character's weapon type
		weapon = switch (Data.weaponType)
		{
			case BOW: new Arrow(this, Projectiles);
			case SWORD: new Sword(this, Projectiles);
			case WAND: new Wand(this, Projectiles);
			case HALBERD: new Halberd(this, Projectiles);
		}

		// Adjust optimal distance based on weapon type
		optimalDistance = switch (Data.weaponType)
		{
			case BOW | WAND: 64; // Ranged weapons keep distance
			case SWORD | HALBERD: 16; // Melee weapons get close
		}

		// Spawn above arena midpoint
		var arenaHeight = FlxG.worldBounds.height;
		var upperArea = FlxG.worldBounds.top + (arenaHeight * 0.4);
		var spawnX = FlxG.random.float(FlxG.worldBounds.left + 16, FlxG.worldBounds.right - 24);
		var spawnY = FlxG.random.float(FlxG.worldBounds.top + 16, upperArea);

		reset(spawnX, spawnY);

		if (shadow == null)
		{
			shadow = new Shadow(this, 1.2, 0.25, 0, height / 2);
			PlayState.current.shadowLayer.add(shadow);
		}
		else
		{
			shadow.revive();
		}

		// Fade in animation
		alpha = 0;
		FlxTween.tween(this, {alpha: 0.8}, 0.5, {ease: FlxEase.quadOut});
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (player == null || !player.alive)
			return;

		if (weapon != null)
			weapon.update(elapsed);

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

		// Maintain optimal distance
		if (dist > optimalDistance + 16)
		{
			velocity.set(Math.cos(facingAngle) * baseSpeed * characterData.moveSpeed, Math.sin(facingAngle) * baseSpeed * characterData.moveSpeed);
		}
		else if (dist < optimalDistance - 16)
		{
			velocity.set(-Math.cos(facingAngle) * baseSpeed * characterData.moveSpeed, -Math.sin(facingAngle) * baseSpeed * characterData.moveSpeed);
		}
		else
		{
			velocity.x *= 0.8;
			velocity.y *= 0.8;
		}

		// Constrain to bounds
		x = Math.max(FlxG.worldBounds.left + 8, Math.min(FlxG.worldBounds.right - width - 8, x));
		y = Math.max(FlxG.worldBounds.top + 8, Math.min(FlxG.worldBounds.bottom - height - 8, y));

		// Attack using weapon
		if (attackTimer <= 0 && dist < 128)
		{
			useWeapon();
			attackTimer = attackCooldown;
		}
	}

	function useWeapon():Void
	{
		if (weapon == null)
			return;

		// For ranged weapons (bow/wand): start charge and immediately release
		if (Std.isOfType(weapon, Arrow) || Std.isOfType(weapon, Wand))
		{
			weapon.startCharge();
			weapon.releaseCharge();
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

	public function takeDamage(damage:Float):Void
	{
		currentHealth -= damage;
		
		// Flash effect
		FlxTween.cancelTweensOf(this, ["color"]);
		color = FlxColor.RED;
		FlxTween.tween(this, {color: 0xBBBBDD}, 0.1);

		if (currentHealth <= 0)
		{
			// TODO: Spawn XP orb in PlayState
			kill();
		}
	}

	override function kill():Void
	{
		// Trigger death callback FIRST (spawns soul orb)
		if (onDeath != null)
			onDeath(this);

		// Switch to death frame (living frame + 8)
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
			trace("Death frame not found for ghost, using fallback");
			actuallyKill();
		}
	}

	function actuallyKill():Void
	{
		super.kill();
		FlxTween.cancelTweensOf(this);

		if (shadow != null)
			shadow.kill();
	}
}
