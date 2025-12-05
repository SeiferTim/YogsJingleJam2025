package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxAngle;
import flixel.math.FlxPoint;
import flixel.math.FlxVelocity;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

class Player extends FlxSprite
{
	public var maxHP:Int = 3;
	public var currentHP:Int = 3;
	public var attackDamage:Float = 1.0;
	public var moveSpeed:Float = 1.0;
	public var attackCooldown:Float = 1.0;

	var baseSpeed:Float = 40;

	public var dodgeTimer:Float = 0;
	public var dodgeCooldown:Float = 2.0;

	var dodgeDuration:Float = 0.2;
	var dodgeDistance:Float = 32;
	var isDodging:Bool = false;
	// Dodge animation tweens
	var dodgeJumpTween:FlxTween;
	var dodgeRotateTween:FlxTween;

	public var isInvincible:Bool = false;

	var invincibilityTimer:Float = 0;
	var invincibilityDuration:Float = 1.0;

	public var facingAngle:Float = 0;

	var reticle:FlxSprite;
	var reticleDistance:Float = 12;

	public var weapon:Weapon;

	var projectiles:FlxTypedGroup<Projectile>;
	var wasShootPressed:Bool = false;

	public var shadow:Shadow;

	public function new(X:Float, Y:Float, Projectiles:FlxTypedGroup<Projectile>)
	{
		super(X, Y);

		projectiles = Projectiles;

		loadGraphic("assets/images/players.png", true, 8, 8);
		animation.frameIndex = 0;
		antialiasing = false;

		centerOrigin();

		solid = true;

		weapon = new Arrow(this, projectiles); // Default weapon

		reticle = new FlxSprite();
		reticle.makeGraphic(3, 3, FlxColor.WHITE);
		reticle.offset.set(1, 1);
	}

	public function setWeapon(weaponType:CharacterData.WeaponType):Void
	{
		// Set weapon based on type
		switch (weaponType)
		{
			case BOW:
				weapon = new Arrow(this, projectiles);
			case SWORD:
				weapon = new Sword(this, projectiles);
			case WAND:
				weapon = new Wand(this, projectiles);
			case HALBERD:
				weapon = new Halberd(this, projectiles);
		}
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (dodgeTimer > 0)
			dodgeTimer -= elapsed;

		if (invincibilityTimer > 0)
		{
			invincibilityTimer -= elapsed;
			if (invincibilityTimer <= 0)
			{
				isInvincible = false;
				alpha = 1.0;
			}
			else
			{
				alpha = 0.5 + Math.sin(invincibilityTimer * 20) * 0.5;
			}
		}

		weapon.update(elapsed);

		if (isDodging)
		{
			updateDodge(elapsed);
		}
		else
		{
			handleMovement(elapsed);
			handleAiming();
			handleShooting(elapsed);
			handleDodge();
		}

		constrainToWorldBounds();
		updateReticle();
	}

	function handleMovement(elapsed:Float):Void
	{
		var moveX:Float = 0;
		var moveY:Float = 0;

		if (Actions.leftStick.x != 0 || Actions.leftStick.y != 0)
		{
			moveX = Actions.leftStick.x;
			moveY = Actions.leftStick.y;
		}
		else
		{
			if (Actions.left.triggered)
				moveX = -1;
			if (Actions.right.triggered)
				moveX = 1;
			if (Actions.up.triggered)
				moveY = -1;
			if (Actions.down.triggered)
				moveY = 1;
		}

		if (moveX != 0 || moveY != 0)
		{
			var speed = baseSpeed * moveSpeed;
			var angle = Math.atan2(moveY, moveX);
			velocity.set(Math.cos(angle) * speed, Math.sin(angle) * speed);
		}
		else
		{
			velocity.set(0, 0);
		}
	}

	function handleAiming():Void
	{
		if (Actions.rightStick.x != 0 || Actions.rightStick.y != 0)
		{
			facingAngle = Math.atan2(Actions.rightStick.y, Actions.rightStick.x);
		}
		else
		{
			facingAngle = FlxAngle.angleBetweenMouse(this, false);
		}

		var degrees = facingAngle * FlxAngle.TO_DEG;
		flipX = (degrees < -45 || degrees > 135);
	}

	function handleShooting(elapsed:Float):Void
	{
		if (Actions.shoot.triggered && !wasShootPressed)
		{
			weapon.startCharge();
			wasShootPressed = true;
		}
		else if (!Actions.shoot.triggered && wasShootPressed)
		{
			weapon.releaseCharge();
			wasShootPressed = false;
		}
	}

	function handleDodge():Void
	{
		if (Actions.dodge.triggered && dodgeTimer <= 0)
		{
			startDodge();
			dodgeTimer = dodgeCooldown;
		}
	}

	function startDodge():Void
	{
		isDodging = true;
		isInvincible = true;

		var targetX = x + Math.cos(facingAngle) * dodgeDistance;
		var targetY = y + Math.sin(facingAngle) * dodgeDistance;

		targetX = Math.max(FlxG.worldBounds.left, Math.min(FlxG.worldBounds.right - width, targetX));
		targetY = Math.max(FlxG.worldBounds.top, Math.min(FlxG.worldBounds.bottom - height, targetY));

		var speed = dodgeDistance / dodgeDuration;
		velocity.x = Math.cos(facingAngle) * speed;
		velocity.y = Math.sin(facingAngle) * speed;
		// Dodge roll animation: jump up and rotate
		// Determine rotation direction based on facing angle
		// Right (0 to 90, -90 to 0): positive rotation
		// Left (90 to 180, -180 to -90): negative rotation
		var rotationAmount:Float = 360;

		// Normalize facing angle to -180 to 180
		var normalizedAngle = facingAngle * (180 / Math.PI);
		while (normalizedAngle > 180)
			normalizedAngle -= 360;
		while (normalizedAngle < -180)
			normalizedAngle += 360;

		// If facing left (-180 to 0), rotate counter-clockwise (negative)
		if (normalizedAngle < 0)
		{
			rotationAmount = -360;
		}

		// Tween offset.y up 2-3px (makes sprite appear to jump)
		var jumpHeight = -2.5; // Negative because y increases downward
		dodgeJumpTween = FlxTween.tween(offset, {y: jumpHeight}, dodgeDuration / 2, {
			ease: FlxEase.quadOut,
			onComplete: function(t:FlxTween)
			{
				// Come back down
				FlxTween.tween(offset, {y: 0}, dodgeDuration / 2, {ease: FlxEase.quadIn});
			}
		});

		// Rotate sprite full revolution
		dodgeRotateTween = FlxTween.tween(this, {angle: angle + rotationAmount}, dodgeDuration, {
			ease: FlxEase.linear
		});
	}

	function updateDodge(elapsed:Float):Void
	{
		dodgeDuration -= elapsed;
		if (dodgeDuration <= 0)
		{
			isDodging = false;
			isInvincible = false;
			dodgeDuration = 0.2;
			velocity.set(0, 0);
			// Reset visual state
			offset.y = 0;
			angle = 0;

			// Cancel any remaining tweens
			if (dodgeJumpTween != null)
			{
				dodgeJumpTween.cancel();
				dodgeJumpTween = null;
			}
			if (dodgeRotateTween != null)
			{
				dodgeRotateTween.cancel();
				dodgeRotateTween = null;
			}
		}
	}

	function updateReticle():Void
	{
		reticle.x = x + (width / 2) - (reticle.width / 2) + Math.cos(facingAngle) * reticleDistance;
		reticle.y = y + (height / 2) - (reticle.height / 2) + Math.sin(facingAngle) * reticleDistance;
	}

	function constrainToWorldBounds():Void
	{
		var hitLeft = false;
		var hitRight = false;
		var hitTop = false;
		var hitBottom = false;

		if (x < FlxG.worldBounds.left)
		{
			x = FlxG.worldBounds.left;
			hitLeft = true;
		}
		if (x + width > FlxG.worldBounds.right)
		{
			x = FlxG.worldBounds.right - width;
			hitRight = true;
		}
		if (y < FlxG.worldBounds.top)
		{
			y = FlxG.worldBounds.top;
			hitTop = true;
		}
		if (y + height > FlxG.worldBounds.bottom)
		{
			y = FlxG.worldBounds.bottom - height;
			hitBottom = true;
		}

		if (isDodging)
		{
			if (hitLeft || hitRight)
				velocity.x = 0;
			if (hitTop || hitBottom)
				velocity.y = 0;
		}
	}

	public function takeDamage(damage:Float):Void
	{
		if (isInvincible)
			return;

		currentHP -= 1;
		if (currentHP < 0)
			currentHP = 0;

		isInvincible = true;
		invincibilityTimer = invincibilityDuration;

		if (currentHP <= 0)
		{
			kill();
		}
	}

	public function knockback(fromX:Float, fromY:Float, force:Float):Void
	{
		var angle = Math.atan2(y + height / 2 - fromY, x + width / 2 - fromX);
		velocity.x = Math.cos(angle) * force;
		velocity.y = Math.sin(angle) * force;
	}

	override function draw():Void
	{
		super.draw();
		reticle.draw();
	}
}
