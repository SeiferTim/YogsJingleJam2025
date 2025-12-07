package;

import CharacterData.WeaponType;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxAngle;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

class Player extends FlxSprite
{
	// Stats
	public var maxHP:Int = 3;
	public var currentHP:Int = 3;
	public var attackDamage:Float = 1.0;
	public var moveSpeed:Float = 1.0;
	public var luck:Float = 1.0;
	public var level:Int = 1;

	// Combat
	public var weapon:Weapon;
	public var facingAngle:Float = 0;
	public var lastMovementAngle:Float = 0; // Track movement direction for dodge
	public var isInvincible:Bool = false;
	
	// Dodge
	public var dodgeTimer:Float = 0;
	public var dodgeCooldown:Float = 2.0;

	// Spin bounce state
	public var spinBounceActive:Bool = false;
	public var spinBounceTimer:Float = 0;
	public var spinBounceDuration:Float = 0.15; // How long to override input after bounce
	public var spinBounceVelocityX:Float = 0;
	public var spinBounceVelocityY:Float = 0;

	// Visual
	public var shadow:Shadow;
	public var dizzySprite:FlxSprite; // Spinning dizzy indicator
	
	// Internal
	var baseSpeed:Float = 40;
	var projectiles:FlxTypedGroup<Projectile>;
	public var reticle:FlxSprite; // Public so PlayState can hide during cinematics
	var reticleDistance:Float = 12;
	var wasShootPressed:Bool = false;
	var invincibilityTimer:Float = 0;
	var invincibilityDuration:Float = 0.8; // Increased back up - was too short

	public var isDodging:Bool = false; // Public so collision checks can see it
	var dodgeDuration:Float = 0.2;
	var dodgeDistance:Float = 32;
	var dodgeTweens:Array<FlxTween> = [];

	// Dizzy state (after sword spin)
	public var isDizzy:Bool = false;

	var dizzyTimer:Float = 0;
	var dizzyDuration:Float = 0;
	var dizzyFlipCounter:Int = 0; // Counter for flipping sprite during dizzy

	// Knockback system
	var isKnockedBack:Bool = false;
	var knockbackTimer:Float = 0;
	var knockbackDuration:Float = 0.3; // Reduced from 0.8s - much shorter push
	var knockbackFreezeDuration:Float = 0.15; // Reduced from 0.2s - faster recovery
	var knockbackTween:FlxTween = null;

	public function new(X:Float, Y:Float, Projectiles:FlxTypedGroup<Projectile>)
	{
		super(X, Y);
		projectiles = Projectiles;

		loadGraphic("assets/images/players.png", true, 8, 8);
		animation.frameIndex = 0;
		antialiasing = false;
		centerOrigin();
		solid = true;

		weapon = new Arrow(this, projectiles);
		
		reticle = new FlxSprite();
		reticle.makeGraphic(3, 3, FlxColor.WHITE);
		reticle.offset.set(1, 1);
		reticle.visible = false; // Start hidden until player is active
		// Dizzy sprite - 8x8 spinning indicator
		dizzySprite = new FlxSprite();
		dizzySprite.loadGraphic("assets/images/dizzy.png");
		dizzySprite.visible = false;
	}

	public function getCritChance():Float
	{
		return 5.0 * luck; // Base 5% per 1.0 luck
	}

	public function rollCrit():Bool
	{
		return FlxG.random.bool(getCritChance());
	}

	public function setWeapon(weaponType:CharacterData.WeaponType):Void
	{
		weapon = switch (weaponType)
		{
			case BOW: new Arrow(this, projectiles);
			case SWORD: new Sword(this, projectiles);
			case WAND: new Wand(this, projectiles);
			case HALBERD: new Halberd(this, projectiles);
		}
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		updateTimers(elapsed);
		updateInvincibility(elapsed);
		weapon.update(elapsed);

		if (isDodging)
			updateDodge(elapsed);
		else
			updateNormal(elapsed);

		constrainToWorldBounds();
		updateReticle();
	}

	function updateTimers(elapsed:Float):Void
	{
		if (dodgeTimer > 0)
			dodgeTimer -= elapsed;
	}

	function updateInvincibility(elapsed:Float):Void
	{
		if (invincibilityTimer > 0)
		{
			invincibilityTimer -= elapsed;
			alpha = invincibilityTimer <= 0 ? 1.0 : 0.5 + Math.sin(invincibilityTimer * 20) * 0.5;
			if (invincibilityTimer <= 0)
				isInvincible = false;
		}
		// Handle dizzy state (post-spin)
		if (isDizzy)
		{
			dizzyTimer -= elapsed;

			// Flip sprite every 4th frame for dizzy effect
			dizzyFlipCounter++;
			if (dizzyFlipCounter % 4 == 0)
			{
				flipX = !flipX;
			}

			// Rotate dizzy sprite CCW continuously
			dizzySprite.angle -= 360 * elapsed; // 360 degrees per second CCW (faster)
			dizzySprite.visible = true;
			dizzySprite.x = x + width / 2 - dizzySprite.width / 2;
			dizzySprite.y = y - 10;

			if (dizzyTimer <= 0)
			{
				isDizzy = false;
				dizzyTimer = 0;
				dizzyFlipCounter = 0;
				dizzySprite.visible = false;
			}
		}
		else
		{
			dizzySprite.visible = false;
		}
		
		// Handle knockback timer
		if (knockbackTimer > 0)
		{
			knockbackTimer -= elapsed;
			if (knockbackTimer <= 0)
			{
				isKnockedBack = false;
				knockbackTimer = 0;
			}
		}
		// Handle spin bounce timer
		if (spinBounceActive)
		{
			spinBounceTimer -= elapsed;
			if (spinBounceTimer <= 0)
			{
				spinBounceActive = false;
				spinBounceTimer = 0;
			}
		}
	}

	function updateNormal(elapsed:Float):Void
	{
		// Block all input during knockback or dizzy
		if (isKnockedBack || isDizzy)
		{
			velocity.set(0, 0); // Ensure no movement
			return;
		}
		
		handleMovement();
		handleAiming();
		handleShooting();
		handleDodge();
	}

	function handleMovement():Void
	{
		// Don't handle movement input during spin - sword manages velocity
		if (Std.isOfType(weapon, Sword))
		{
			var sword:Sword = cast weapon;
			if (sword.isSpinActive())
			{
				return; // Sword.update() handles velocity during spin
			}
		}
		
		var moveX = Actions.leftStick.x != 0 ? Actions.leftStick.x : (Actions.right.triggered ? 1 : (Actions.left.triggered ? -1 : 0));
		var moveY = Actions.leftStick.y != 0 ? Actions.leftStick.y : (Actions.down.triggered ? 1 : (Actions.up.triggered ? -1 : 0));

		if (moveX != 0 || moveY != 0)
		{
			var angle = Math.atan2(moveY, moveX);
			lastMovementAngle = angle; // Store for dodge direction
			
			var speedMultiplier = 1.0;
			
			// Slow down while charging
			if (weapon.isCharging)
			{
				speedMultiplier = 0.5;
			}
			// Speed up while spinning (sword only)
			else if (Std.isOfType(weapon, Sword))
			{
				var sword:Sword = cast weapon;
				if (sword.isSpinActive())
				{
					speedMultiplier = 1.5;
				}
			}
			
			velocity.set(Math.cos(angle) * baseSpeed * moveSpeed * speedMultiplier, Math.sin(angle) * baseSpeed * moveSpeed * speedMultiplier);
		}
		else
		{
			velocity.set(0, 0);
		}
	}

	function handleAiming():Void
	{
		facingAngle = (Actions.rightStick.x != 0 || Actions.rightStick.y != 0) ? Math.atan2(Actions.rightStick.y,
			Actions.rightStick.x) : FlxAngle.angleBetweenMouse(this, false);

		var degrees = facingAngle * FlxAngle.TO_DEG;
		flipX = (degrees < -45 || degrees > 135);
	}

	function handleShooting():Void
	{
		// Can't attack if already attacking or dodge rolling
		var isAttacking = false;
		if (Std.isOfType(weapon, Sword))
		{
			var sword:Sword = cast weapon;
			isAttacking = sword.isSpinActive() || (sword.getSlashHitbox().exists && sword.getSlashHitbox().alpha > 0);
		}
		else if (Std.isOfType(weapon, Halberd))
		{
			var halberd:Halberd = cast weapon;
			isAttacking = halberd.isJabActive();
		}

		if (isDodging || isAttacking)
			return;
		
		if (Actions.shoot.triggered && !wasShootPressed)
		{
			// JUSTPRESSED - All weapons: tap on press, then start charging
			weapon.tap();
			weapon.startCharge();
			wasShootPressed = true;
		}
		else if (!Actions.shoot.triggered && wasShootPressed)
		{
			// JUSTRELEASED - fire charge attack if held long enough
			weapon.releaseCharge();
			wasShootPressed = false;
		}
		// Update weapon's pressed state for charge accumulation
		// This needs to happen every frame while button is held
		if (wasShootPressed)
		{
			// Button is currently held - weapon will accumulate charge in update()
			// (isPressed is already true from startCharge call)
		}
	}

	function handleDodge():Void
	{
		// Can't dodge while charging, attacking, or already dodging
		var isAttacking = false;
		if (Std.isOfType(weapon, Sword))
		{
			var sword:Sword = cast weapon;
			isAttacking = sword.isSpinActive() || (sword.getSlashHitbox().exists && sword.getSlashHitbox().alpha > 0);
		}
		else if (Std.isOfType(weapon, Halberd))
		{
			var halberd:Halberd = cast weapon;
			isAttacking = halberd.isJabActive();
		}

		if (weapon.isCharging || isAttacking || isDodging)
			return;
		
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

		// Use last movement direction instead of facing direction
		var dodgeAngle = lastMovementAngle;
		var speed = dodgeDistance / dodgeDuration;
		velocity.set(Math.cos(dodgeAngle) * speed, Math.sin(dodgeAngle) * speed);

		// Dodge roll animation - use movement angle for rotation direction
		var rotationAmount = (dodgeAngle * FlxAngle.TO_DEG < 0) ? -360 : 360;
		
		dodgeTweens.push(FlxTween.tween(offset, {y: -2.5}, dodgeDuration / 2, {
			ease: FlxEase.quadOut,
			onComplete: (_) -> FlxTween.tween(offset, {y: 0}, dodgeDuration / 2, {ease: FlxEase.quadIn})
		}));
		
		dodgeTweens.push(FlxTween.tween(this, {angle: angle + rotationAmount}, dodgeDuration, {ease: FlxEase.linear}));
	}

	function updateDodge(elapsed:Float):Void
	{
		dodgeDuration -= elapsed;
		if (dodgeDuration <= 0)
		{
			endDodge();
		}
	}

	function endDodge():Void
	{
		isDodging = false;
		isInvincible = false;
		dodgeDuration = 0.2;
		velocity.set(0, 0);
		offset.y = 0;
		angle = 0;
		
		for (tween in dodgeTweens)
		{
			if (tween != null)
				tween.cancel();
		}
		dodgeTweens = [];
	}

	public function startDizzy(duration:Float):Void
	{
		isDizzy = true;
		dizzyTimer = duration;
		dizzyFlipCounter = 0;
		velocity.set(0, 0);
	}

	public function applySpinBounce(bounceVelX:Float, bounceVelY:Float):Void
	{
		spinBounceActive = true;
		spinBounceTimer = spinBounceDuration;
		spinBounceVelocityX = bounceVelX;
		spinBounceVelocityY = bounceVelY;
		velocity.set(bounceVelX, bounceVelY);
	}

	function updateReticle():Void
	{
		reticle.x = x + (width / 2) - (reticle.width / 2) + Math.cos(facingAngle) * reticleDistance;
		reticle.y = y + (height / 2) - (reticle.height / 2) + Math.sin(facingAngle) * reticleDistance;
	}

	function constrainToWorldBounds():Void
	{
		var hitX = false;
		var hitY = false;

		if (x < FlxG.worldBounds.left)
		{
			x = FlxG.worldBounds.left;
			hitX = true;
		}
		else if (x + width > FlxG.worldBounds.right)
		{
			x = FlxG.worldBounds.right - width;
			hitX = true;
		}

		if (y < FlxG.worldBounds.top)
		{
			y = FlxG.worldBounds.top;
			hitY = true;
		}
		else if (y + height > FlxG.worldBounds.bottom)
		{
			y = FlxG.worldBounds.bottom - height;
			hitY = true;
		}

		if (isDodging)
		{
			if (hitX)
				velocity.x = 0;
			if (hitY)
				velocity.y = 0;
		}
		else if (weapon != null && Std.isOfType(weapon, Sword))
		{
			// Bounce off walls when spin attacking (reflect velocity)
			var sword:Sword = cast weapon;
			if (sword.isSpinActive())
			{
				var currentSpeed = Math.sqrt(velocity.x * velocity.x + velocity.y * velocity.y);
				if (hitX)
				{
					// Reflect X velocity, keep Y
					var newVelX = -velocity.x;
					var newVelY = velocity.y;
					applySpinBounce(newVelX, newVelY);
				}
				if (hitY)
				{
					// Reflect Y velocity, keep X
					var newVelX = velocity.x;
					var newVelY = -velocity.y;
					applySpinBounce(newVelX, newVelY);
				}
			}
		}
	}

	public function takeDamage(damage:Float, ?sourceX:Float, ?sourceY:Float):Void
	{
		if (isInvincible || isKnockedBack)
			return;

		currentHP = Std.int(Math.max(0, currentHP - 1));
		isInvincible = true;
		invincibilityTimer = invincibilityDuration;

		// Calculate knockback direction
		if (sourceX != null && sourceY != null)
		{
			var dirX = x + width / 2 - sourceX;
			var dirY = y + height / 2 - sourceY;
			var length = Math.sqrt(dirX * dirX + dirY * dirY);

			if (length > 0)
			{
				dirX /= length;
				dirY /= length;
			}
			else
			{
				// Default to pushing down if source is at exact same position
				dirX = 0;
				dirY = 1;
			}

			// Apply knockback
			applyKnockback(dirX, dirY);
		}

		if (currentHP <= 0)
			onDeath();
	}

	function applyKnockback(dirX:Float, dirY:Float):Void
	{
		// Cancel any ongoing charge
		if (weapon != null)
			weapon.cancelCharge();

		// Stop movement
		velocity.set(0, 0);

		// Set knockback state
		isKnockedBack = true;
		knockbackTimer = knockbackDuration + knockbackFreezeDuration;

		// Cancel any existing knockback tween
		if (knockbackTween != null)
		{
			knockbackTween.cancel();
			knockbackTween = null;
		}

		// Push player away
		var knockbackDistance = 20; // 16-24px range, set to 20px
		var targetX = x + dirX * knockbackDistance;
		var targetY = y + dirY * knockbackDistance;

		// Clamp to playable area
		targetX = Math.max(0, Math.min(FlxG.width - width, targetX));
		targetY = Math.max(0, Math.min(FlxG.height - height, targetY));

		knockbackTween = FlxTween.tween(this, {x: targetX, y: targetY}, knockbackDuration, {
			ease: flixel.tweens.FlxEase.quadOut,
			onComplete: function(_)
			{
				knockbackTween = null;
			}
		});
	}
	function onDeath():Void
	{
		// Immediately stop all movement and actions
		velocity.set(0, 0);
		active = false; // Disable update logic (movement, shooting, etc.)
		reticle.visible = false; // Hide reticle

		// Switch to death frame (current frame + 8)
		var livingFrame = animation.frameIndex;
		var deathFrame = livingFrame + 8;

		// Switch to death frame if it exists
		if (deathFrame < 16)
		{
			animation.frameIndex = deathFrame;
		}
		// Tell PlayState to handle the death screen (fade to black + show substate)
		if (PlayState.current != null)
		{
			PlayState.current.onPlayerDeath();
		}
	}

	function switchToGameOver(livingFrame:Int):Void
	{
		// Determine weapon type from current weapon
		var weaponType:WeaponType = BOW;
		if (Std.isOfType(weapon, Sword))
			weaponType = SWORD;
		else if (Std.isOfType(weapon, Wand))
			weaponType = WAND;
		else if (Std.isOfType(weapon, Halberd))
			weaponType = HALBERD;

		// Detect current phase from PlayState
		var currentPhase:Int = 0; // Default to 0
		if (PlayState.current != null)
		{
			switch (PlayState.current.gameState)
			{
				case INTRO | PHASE_0_5_GHOSTS:
					currentPhase = 0; // Dies in Phase 0/0.5 → appears in Phase 0.5 (next run)
				case PHASE_1_ACTIVE | PHASE_1_DEATH:
					currentPhase = 1; // Dies in Phase 1 → appears in Phase 1.5
				case PHASE_1_5_ACTIVE:
					currentPhase = 1; // Dies in Phase 1.5 → appears in Phase 1.5 (same wave, next run)
				case PHASE_2_HATCH | PHASE_2_ACTIVE | PHASE_2_DEATH:
					currentPhase = 2; // Dies in Phase 2 → appears in Phase 2.5
				case PHASE_2_5_ACTIVE:
					currentPhase = 2; // Dies in Phase 2.5 → appears in Phase 2.5 (same wave, next run)
				default:
					currentPhase = 0;
			}
		}
		// Save character data for ghost spawning (use livingFrame, not current frame which is death frame!)
		var characterData = new CharacterData("Ghost", weaponType, SPEED, DAMAGE, livingFrame);
		characterData.maxHP = maxHP;
		characterData.attackDamage = attackDamage;
		characterData.moveSpeed = moveSpeed;
		characterData.luck = luck;
		characterData.weaponType = weaponType;
		characterData.deathPhase = currentPhase;

		GameData.addDeadCharacter(characterData);

		trace("Player died in phase " + currentPhase + " with weapon " + weaponType);

		// Return to character select
		FlxG.switchState(() -> new CharacterSelectState());
	}

	public function knockback(fromX:Float, fromY:Float, force:Float):Void
	{
		var angle = Math.atan2(y + height / 2 - fromY, x + width / 2 - fromX);
		velocity.set(Math.cos(angle) * force, Math.sin(angle) * force);
	}

	override function draw():Void
	{
		super.draw();
		if (reticle.visible)
			reticle.draw();
	}
	public function levelUp(Levels:Int):Void
	{
		level += Levels;
		attackDamage += 0.1 * Levels;
		moveSpeed += 0.1 * Levels;
		luck += 0.1 * Levels;
		maxHP = 3 + Std.int((level - 3) / 3);
		currentHP = maxHP;
		FlxG.camera.flash(FlxColor.WHITE, 0.15);
	}
}
