package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;

/**
 * Ghost - Previous player character that comes back as an enemy
 * 
 * - Uses saved CharacterData (weapon, stats, level)
 * - Appears as semi-transparent (alpha 0.8)
 * - Simple AI: move toward player but keep distance, shoot on cooldown
 * - Drops XP orb on death
 * - Has shadow like player
 */
class Ghost extends FlxSprite
{
	public var shadow:Shadow;
	public var characterData:CharacterData;

	// Health based on character data
	public var maxHP:Int;
	public var currentHP:Int;

	// Combat stats from character data
	var attackDamage:Float;
	var moveSpeed:Float;
	var attackCooldown:Float;

	// AI behavior
	var baseSpeed:Float = 40;
	var optimalDistance:Float = 64; // Try to stay this far from player
	var attackTimer:Float = 0;
	var longAttackCooldown:Float = 3.0; // Longer cooldown than player

	// Facing direction for aiming
	var facingAngle:Float = 0;

	// Reference to player for AI
	var player:Player;
	var projectiles:FlxTypedGroup<Projectile>;

	// Base arrow speed for firing
	var arrowSpeed:Float = 200;

	public function new(X:Float, Y:Float, Data:CharacterData, Player:Player, Projectiles:FlxTypedGroup<Projectile>)
	{
		super(X, Y);

		characterData = Data;
		player = Player;
		projectiles = Projectiles;

		// Copy stats from character data
		maxHP = characterData.maxHP;
		currentHP = maxHP;
		attackDamage = characterData.attackDamage;
		moveSpeed = characterData.moveSpeed;
		attackCooldown = characterData.attackCooldown * longAttackCooldown; // Much longer cooldown

		// Load player sprite (same as player)
		loadGraphic("assets/images/players.png", true, 8, 8);
		animation.frameIndex = 0;

		// Semi-transparent ghostly appearance
		alpha = 0.8;

		// TODO: Apply grayscale shader for ghostly effect
		// For now, just tint slightly blue/gray
		color = 0xBBBBDD;
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (!alive || player == null)
			return;

		// Update AI
		updateAI(elapsed);

		// Update attack timer
		if (attackTimer > 0)
			attackTimer -= elapsed;
	}

	function updateAI(elapsed:Float):Void
	{
		// Calculate distance to player
		var dx = player.x - x;
		var dy = player.y - y;
		var distToPlayer = Math.sqrt(dx * dx + dy * dy);

		// Calculate facing angle toward player
		facingAngle = Math.atan2(dy, dx);

		// Movement AI: maintain optimal distance
		if (distToPlayer > optimalDistance + 16)
		{
			// Too far, move closer
			velocity.x = Math.cos(facingAngle) * baseSpeed * moveSpeed;
			velocity.y = Math.sin(facingAngle) * baseSpeed * moveSpeed;
		}
		else if (distToPlayer < optimalDistance - 16)
		{
			// Too close, back away
			velocity.x = -Math.cos(facingAngle) * baseSpeed * moveSpeed;
			velocity.y = -Math.sin(facingAngle) * baseSpeed * moveSpeed;
		}
		else
		{
			// In optimal range, slow down
			velocity.x *= 0.8;
			velocity.y *= 0.8;
		}

		// Constrain to world bounds
		if (x < FlxG.worldBounds.left + 8)
			x = FlxG.worldBounds.left + 8;
		if (x + width > FlxG.worldBounds.right - 8)
			x = FlxG.worldBounds.right - 8;
		if (y < FlxG.worldBounds.top + 8)
			y = FlxG.worldBounds.top + 8;
		if (y + height > FlxG.worldBounds.bottom - 8)
			y = FlxG.worldBounds.bottom - 8;

		// Attack on cooldown if in range
		if (attackTimer <= 0 && distToPlayer < 128)
		{
			tryAttack();
		}
	}

	function tryAttack():Void
	{
		// Fire a simple projectile toward player based on weapon type
		// TODO: Different projectile types per weapon (for now all use arrows)
		var arrow = new Projectile();
		arrow.loadRotatedGraphic("assets/images/arrow.png", 32, -1, false, true);
		arrow.antialiasing = false;

		// Position at ghost center
		arrow.reset(x + width / 2 - arrow.width / 2, y + height / 2 - arrow.height / 2);
		arrow.damage = attackDamage;
		arrow.angle = facingAngle * (180 / Math.PI); // Convert radians to degrees

		// Set velocity toward player
		arrow.velocity.x = Math.cos(facingAngle) * arrowSpeed;
		arrow.velocity.y = Math.sin(facingAngle) * arrowSpeed;

		projectiles.add(arrow);

		// Reset cooldown
		attackTimer = attackCooldown;
	}

	public function takeDamage(damage:Float):Void
	{
		currentHP -= Std.int(damage);
		if (currentHP < 0)
			currentHP = 0;

		// Flash effect
		color = FlxColor.RED;
		haxe.Timer.delay(function()
		{
			color = 0xBBBBDD; // Return to ghostly tint
		}, 100);

		if (currentHP <= 0)
		{
			onDeath();
		}
	}

	function onDeath():Void
	{
		// TODO: Spawn XP orb at shadow position
		// Will be handled by PlayState

		// Kill ghost
		kill();
	}

	override function kill():Void
	{
		super.kill();

		if (shadow != null)
		{
			shadow.kill();
		}
	}

	override function destroy():Void
	{
		player = null;
		projectiles = null;
		characterData = null;

		super.destroy();
	}
}
