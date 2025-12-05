package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;

/**
 * Boss Phase 2 - Upright bug form with legs and arms
 * 
 * Body structure (from JSON reference - sourceSize 60x68):
 * - Abdomen (bottom rear)
 * - Thorax (main body center)
 * - Head (top front)
 * - 4 Legs (2 fore, 2 back)
 * - 2 Arms with claws
 * - Mouth + Pincers (for attacks)
 */
class BossPhase02 extends FlxSprite implements IBoss
{
	// Body parts - public so PlayState can check collisions
	public var abdomen:FlxSprite;
	public var thorax:FlxSprite;
	public var head:FlxSprite;

	public var leftForeLeg:FlxSprite;
	public var rightForeLeg:FlxSprite;
	public var leftBackLeg:FlxSprite;
	public var rightBackLeg:FlxSprite;

	public var leftArmUpper:FlxSprite;
	public var rightArmUpper:FlxSprite;
	public var leftArmClaw:FlxSprite;
	public var rightArmClaw:FlxSprite;

	public var mouth:FlxSprite;
	public var pincers:FlxSprite;

	// Shadows for each part
	var shadows:Array<Shadow>;

	// Stats (IBoss interface)
	public var maxHealth:Float = 300;
	public var currentHealth:Float = 300;
	public var bossName:String = "Reth'kira, the Sundering Edge which Cuts the Veil";

	var moveSpeed:Float = 20;
	public var isActive:Bool = false;

	// Attack state machine
	public var attackState:AttackState = WANDER;
	var attackTimer:Float = 0;
	var nextAttackCooldown:Float = 2.0; // Time before choosing next attack
	
	// Wander variables
	var wanderTargetX:Float = 0;
	var wanderTargetY:Float = 0;
	var wanderSpeed:Float = 25; // Slightly faster than Phase 1
	var wanderPickNewTargetTimer:Float = 0;
	
	// Walking animation variables
	var walkCycleTimer:Float = 0;
	var walkCycleDuration:Float = 0.4; // Time for complete walk cycle
	var currentWalkPhase:Int = 0; // 0 = left-fore + right-back raised, 1 = right-fore + left-back raised
	
	// Charge attack variables
	var chargeTelegraphDuration:Float = 0.8; // Shorter, 4 bounces
	var chargeDuration:Float = 0.6; // How long to charge
	var chargeRecoveryDuration:Float = 0.5;
	var chargeBounces:Int = 4;
	var currentBounce:Int = 0;
	var bounceTimer:Float = 0;
	var bounceDuration:Float = 0.2; // Time for one bounce (down + up)
	var bounceAmount:Float = 3.0; // How many pixels to bounce
	var chargeTargetX:Float = 0;
	var chargeTargetY:Float = 0;
	var chargeSpeed:Float = 0;
	var chargeStartX:Float = 0;
	var chargeStartY:Float = 0;
	var chargeMaxDistance:Float = 80; // Stop after traveling this far	// Reference point for all parts (center of thorax)
	var centerX:Float = 0;
	var centerY:Float = 0;

	// Ground level - where leg tips touch (used for shadow positioning)
	var groundLevel:Float = 0;

	public function new(X:Float, Y:Float)
	{
		super(X, Y);

		shadows = [];

		// Create an invisible sprite as the main reference point (60x68 canvas)
		makeGraphic(60, 68, FlxColor.TRANSPARENT);
		// DON'T center origin - we want x,y to be top-left
		// centerOrigin();

		trace("BossPhase02 created at: " + X + ", " + Y);
		trace("Boss canvas: " + width + "x" + height);

		// Create all body parts using individual PNG files
		// Position them based on JSON spriteSourceSize (x, y) coordinates

		// Initialize the partOffsets map
		partOffsets = new Map<FlxSprite, FlxPoint>();

		// Back legs (render first, behind everything)
		leftBackLeg = createPart("assets/images/boss-phase-02-left-back-leg.png", 3, 7);
		rightBackLeg = createPart("assets/images/boss-phase-02-right-back-leg.png", 44, 7);

		// Abdomen (bottom rear)
		abdomen = createPart("assets/images/boss-phase-02-abdomen.png", 24, 23);

		// Fore legs
		leftForeLeg = createPart("assets/images/boss-phase-02-left-fore-leg.png", 3, 16);
		rightForeLeg = createPart("assets/images/boss-phase-02-right-fore-leg.png", 41, 16);

		// Thorax (main body)
		thorax = createPart("assets/images/boss-phase-02-thorax.png", 15, 1);

		// Arms
		leftArmUpper = createPart("assets/images/boss-phase-02-left-arm-upper.png", 14, 28);
		rightArmUpper = createPart("assets/images/boss-phase-02-right-arm-upper.png", 32, 28);

		leftArmClaw = createPart("assets/images/boss-phase-02-left-arm-claw.png", 6, 25);
		rightArmClaw = createPart("assets/images/boss-phase-02-right-arm-claw.png", 42, 25);

		// Head (top front)
		head = createPart("assets/images/boss-phase-02-head.png", 20, 16);

		// Mouth and pincers (reuse Phase 1 graphics, animated with 2 frames)
		mouth = new FlxSprite();
		mouth.loadGraphic("assets/images/boss-phase-01-larva-mouth.png", true, 6, 9);
		mouth.animation.add("closed", [0], 1, false);
		mouth.animation.add("open", [1], 1, false);
		mouth.animation.play("closed");
		mouth.visible = true; // Make visible by default
		partOffsets.set(mouth, FlxPoint.get(27, 27));

		pincers = new FlxSprite();
		pincers.loadGraphic("assets/images/boss-phase-01-larva-pincers.png", true, 26, 13);
		pincers.animation.add("closed", [0], 1, false);
		pincers.animation.add("open", [1], 1, false);
		pincers.animation.play("closed");
		pincers.visible = true; // Make visible by default
		partOffsets.set(pincers, FlxPoint.get(17, 29));
		// Calculate ground level from fore legs (they're positioned lower than back legs)
		// Fore legs are at offsetY=16 with height of approximately 16-20px
		// So ground is around offsetY + legHeight
		calculateGroundLevel();

		updatePartPositions();
	}

	/**
	 * Calculate ground level based on leg positions
	 * Only legs touch the ground - everything else floats above
	 */
	function calculateGroundLevel():Void
	{
		// Fore legs reach the ground (they're the longest)
		// Ground = leg's offsetY + leg's height
		var foreLegOffset = partOffsets.get(leftForeLeg);
		groundLevel = foreLegOffset.y + leftForeLeg.height;

		trace("Ground level calculated at: "
			+ groundLevel
			+ " (foreLeg offsetY="
			+ foreLegOffset.y
			+ " + height="
			+ leftForeLeg.height
			+ ")");
	}

	// Store offsets separately so we don't overwrite FlxSprite's offset system
	var partOffsets:Map<FlxSprite, FlxPoint>;

	/**
	 * Create a body part sprite at the given offset from the reference canvas
	 */
	function createPart(path:String, offsetX:Float, offsetY:Float):FlxSprite
	{
		var part = new FlxSprite();
		part.loadGraphic(path);

		// Store the offset separately (don't use FlxSprite's offset field)
		if (partOffsets == null)
			partOffsets = new Map<FlxSprite, FlxPoint>();

		partOffsets.set(part, FlxPoint.get(offsetX, offsetY));

		return part;
	}

	/**
	 * Update all part positions based on main sprite position
	 */
	function updatePartPositions():Void
	{
		// Update center point
		centerX = x + width / 2;
		centerY = y + height / 2;

		// Position all parts relative to the canvas origin (top-left of 60x68 area)
		var originX = x;
		var originY = y;

		// Each part uses its stored offset to position correctly
		positionPart(leftBackLeg, originX, originY);
		positionPart(rightBackLeg, originX, originY);
		positionPart(abdomen, originX, originY);
		positionPart(leftForeLeg, originX, originY);
		positionPart(rightForeLeg, originX, originY);
		positionPart(thorax, originX, originY);
		positionPart(leftArmUpper, originX, originY);
		positionPart(rightArmUpper, originX, originY);
		positionPart(leftArmClaw, originX, originY);
		positionPart(rightArmClaw, originX, originY);
		positionPart(head, originX, originY);
		positionPart(mouth, originX, originY);
		positionPart(pincers, originX, originY);
	}

	function positionPart(part:FlxSprite, originX:Float, originY:Float):Void
	{
		// Get the stored offset for this part
		var offset = partOffsets.get(part);
		if (offset == null)
		{
			// For parts that don't have stored offsets
			part.x = originX;
			part.y = originY;
			return;
		}

		// Check if this is a leg (legs touch the ground, others float)
		var isLeg = (part == leftForeLeg || part == rightForeLeg || part == leftBackLeg || part == rightBackLeg);

		if (isLeg)
		{
			// Legs: position normally using stored offset
			// Their feet touch the ground
			part.x = originX + offset.x;
			part.y = originY + offset.y;
		}
		else
		{
			// All other parts: position at ground level, use offset.y to raise them
			part.x = originX + offset.x;

			// Position y at ground level (for shadow)
			part.y = originY + groundLevel;

			// Calculate how much to raise this part visually
			// visualOffset = where it SHOULD appear - where ground is
			var visualOffset = offset.y - groundLevel;
			part.offset.y = -visualOffset; // Negative because offset.y shifts the drawn position DOWN

			// Store this for easy access during animations
			if (part == thorax)
				trace("Thorax: ground y=" + part.y + ", visual offset.y=" + part.offset.y + " (raises it " + visualOffset + "px)");
		}
	}

	public function createShadows(shadowLayer:ShadowLayer):Void
	{
		// Create shadows for main body parts
		// Body parts: 1.2x width, 0.8x height, anchor center + 4px down
		var abdomenShadow = new Shadow(abdomen, 1.2, 0.8, 0, 4);
		shadowLayer.add(abdomenShadow);
		shadows.push(abdomenShadow);

		var thoraxShadow = new Shadow(thorax, 1.2, 0.8, 0, 4);
		shadowLayer.add(thoraxShadow);
		shadows.push(thoraxShadow);

		var headShadow = new Shadow(head, 1.2, 0.8, 0, 4);
		shadowLayer.add(headShadow);
		shadows.push(headShadow);

		// Legs: thinner shadows 1.0x width, 0.5x height
		var leftForeLegShadow = new Shadow(leftForeLeg, 1.0, 0.5, 0, 4);
		shadowLayer.add(leftForeLegShadow);
		shadows.push(leftForeLegShadow);

		var rightForeLegShadow = new Shadow(rightForeLeg, 1.0, 0.5, 0, 4);
		shadowLayer.add(rightForeLegShadow);
		shadows.push(rightForeLegShadow);

		var leftBackLegShadow = new Shadow(leftBackLeg, 1.0, 0.5, 0, 4);
		shadowLayer.add(leftBackLegShadow);
		shadows.push(leftBackLegShadow);

		var rightBackLegShadow = new Shadow(rightBackLeg, 1.0, 0.5, 0, 4);
		shadowLayer.add(rightBackLegShadow);
		shadows.push(rightBackLegShadow);
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (!isActive)
			return;

		// Update attack state machine
		updateAttackState(elapsed);

		updatePartPositions();
	}

	function updateAttackState(elapsed:Float):Void
	{
		attackTimer -= elapsed;

		switch (attackState)
		{
			case WANDER:
				updateWander(elapsed);

			case CHARGE_TELEGRAPH:
				updateChargeTelegraph(elapsed);

			case CHARGE_ATTACKING:
				updateChargeAttack(elapsed);

			case CHARGE_RECOVERY:
				updateChargeRecovery(elapsed);
		}
	}

	function updateWander(elapsed:Float):Void
	{
		// Pick new wander target periodically
		wanderPickNewTargetTimer -= elapsed;
		if (wanderPickNewTargetTimer <= 0)
		{
			pickNewWanderTarget();
			wanderPickNewTargetTimer = FlxG.random.float(2.0, 4.0);
		}

		// Move toward wander target
		var dx = wanderTargetX - x;
		var dy = wanderTargetY - y;
		var dist = Math.sqrt(dx * dx + dy * dy);

		if (dist > 5)
		{
			dx /= dist;
			dy /= dist;

			x += dx * wanderSpeed * elapsed;
			y += dy * wanderSpeed * elapsed;

			// Update walking animation
			updateWalkingAnimation(elapsed);
		}
		else
		{
			// Reached target, pick new one
			pickNewWanderTarget();
			// Reset legs to ground
			resetLegsToGround();
		}

		// Constrain to world bounds
		constrainToWorldBounds();

		// After wandering for a bit, choose an attack
		if (attackTimer <= 0)
		{
			chooseNextAttack();
		}
	}

	function pickNewWanderTarget():Void
	{
		// Pick random position within arena
		wanderTargetX = FlxG.random.float(FlxG.worldBounds.left + 40, FlxG.worldBounds.right - 80);
		wanderTargetY = FlxG.random.float(FlxG.worldBounds.top + 40, FlxG.worldBounds.bottom - 80);
	}

	function updateWalkingAnimation(elapsed:Float):Void
	{
		walkCycleTimer += elapsed;

		if (walkCycleTimer >= walkCycleDuration / 2)
		{
			// Switch which legs are raised
			walkCycleTimer = 0;
			currentWalkPhase = 1 - currentWalkPhase; // Toggle between 0 and 1
		}

		// Apply leg offsets based on current phase
		if (currentWalkPhase == 0)
		{
			// Raise left-fore + right-back
			leftForeLeg.offset.y = -2;
			rightBackLeg.offset.y = -2;
			// Lower right-fore + left-back
			rightForeLeg.offset.y = 0;
			leftBackLeg.offset.y = 0;
		}
		else
		{
			// Raise right-fore + left-back
			rightForeLeg.offset.y = -2;
			leftBackLeg.offset.y = -2;
			// Lower left-fore + right-back
			leftForeLeg.offset.y = 0;
			rightBackLeg.offset.y = 0;
		}
	}

	function resetLegsToGround():Void
	{
		leftForeLeg.offset.y = 0;
		rightForeLeg.offset.y = 0;
		leftBackLeg.offset.y = 0;
		rightBackLeg.offset.y = 0;
	}

	function constrainToWorldBounds():Void
	{
		if (x < FlxG.worldBounds.left + 8)
			x = FlxG.worldBounds.left + 8;
		if (x + width > FlxG.worldBounds.right - 8)
			x = FlxG.worldBounds.right - width - 8;
		if (y < FlxG.worldBounds.top + 8)
			y = FlxG.worldBounds.top + 8;
		if (y + height > FlxG.worldBounds.bottom - 8)
			y = FlxG.worldBounds.bottom - height - 8;
	}

	function chooseNextAttack():Void
	{
		// For now, just alternate between charge and wander
		// TODO: Add SPIT and SLASH
		var choice = FlxG.random.int(0, 1);

		if (choice == 0)
		{
			startChargeAttack();
		}
		else
		{
			// Wander more
			attackState = WANDER;
			attackTimer = FlxG.random.float(2.0, 4.0);
		}
	}

	function startChargeAttack():Void
	{
		attackState = CHARGE_TELEGRAPH;
		attackTimer = chargeTelegraphDuration;
		currentBounce = 0;
		bounceTimer = 0;
		
		// Reset legs to ground during telegraph
		resetLegsToGround();
		
		trace("Boss starting charge telegraph!");
	}

	function updateChargeTelegraph(elapsed:Float):Void
	{
		// Bounce animation: body parts bob up and down
		bounceTimer += elapsed;
		
		// Calculate bounce offset using sine wave
		// Each complete bounce takes bounceDuration seconds
		var bounceProgress = (bounceTimer % bounceDuration) / bounceDuration;
		var bounceOffset = Math.sin(bounceProgress * Math.PI * 2) * bounceAmount;
		
		// Apply bounce to all non-leg parts (they already have offset.y set)
		// We add the bounce offset to their existing offset
		applyBounceToBodyParts(bounceOffset);
		
		// Track how many bounces we've done
		if (bounceTimer >= bounceDuration && bounceTimer - elapsed < bounceDuration)
		{
			currentBounce++;
			trace("Bounce " + currentBounce + "/" + chargeBounces);
		}

		// After telegraph duration, start the actual charge
		if (attackTimer <= 0)
		{
			// Get player position from PlayState
			var playState = cast(FlxG.state, PlayState);
			if (playState != null && playState.player != null)
			{
				chargeTargetX = playState.player.x;
				chargeTargetY = playState.player.y;
			}
			
			// Record starting position
			chargeStartX = x;
			chargeStartY = y;
			
			attackState = CHARGE_ATTACKING;
			attackTimer = chargeDuration;
			chargeSpeed = wanderSpeed * 2; // 2x wander speed
			
			// Reset bounce offset
			applyBounceToBodyParts(0);
			
			trace("Boss charging at player!");
		}
	}

	function updateChargeAttack(elapsed:Float):Void
	{
		// Calculate direction toward target
		var dx = chargeTargetX - x;
		var dy = chargeTargetY - y;
		var angle = Math.atan2(dy, dx);
		
		// Move toward target
		var moveX = Math.cos(angle) * chargeSpeed * elapsed;
		var moveY = Math.sin(angle) * chargeSpeed * elapsed;
		
		x += moveX;
		y += moveY;
		
		// Check if hit wall
		var hitWall = false;
		if (x < FlxG.worldBounds.left + 8 || x + width > FlxG.worldBounds.right - 8 ||
			y < FlxG.worldBounds.top + 8 || y + height > FlxG.worldBounds.bottom - 8)
		{
			hitWall = true;
		}
		
		// Check distance traveled
		var distTraveled = Math.sqrt((x - chargeStartX) * (x - chargeStartX) + (y - chargeStartY) * (y - chargeStartY));
		
		// Stop if: time expired, hit wall, or traveled max distance
		if (attackTimer <= 0 || hitWall || distTraveled >= chargeMaxDistance)
		{
			// Constrain to bounds
			constrainToWorldBounds();
			
			attackState = CHARGE_RECOVERY;
			attackTimer = chargeRecoveryDuration;
			
			if (hitWall)
				trace("Boss charge hit wall!");
			else if (distTraveled >= chargeMaxDistance)
				trace("Boss charge traveled max distance!");
			else
				trace("Boss charge complete, recovering...");
		}
	}

	function updateChargeRecovery(elapsed:Float):Void
	{
		// Just wait, no movement
		if (attackTimer <= 0)
		{
			attackState = WANDER;
			attackTimer = nextAttackCooldown;
			pickNewWanderTarget();
			trace("Boss resuming wander");
		}
	}

	function applyBounceToBodyParts(bounceOffset:Float):Void
	{
		// Apply bounce to all elevated parts (not legs)
		// They already have their base offset.y set in positionPart()
		// We just modify it temporarily for the bounce
		
		// Get the base offset for each part (stored during initialization)
		var parts = [abdomen, thorax, head, leftArmUpper, rightArmUpper, leftArmClaw, rightArmClaw, mouth, pincers];
		
		for (part in parts)
		{
			var baseOffset = partOffsets.get(part);
			if (baseOffset != null)
			{
				// Recalculate the visual offset with bounce added
				var visualOffset = baseOffset.y - groundLevel;
				part.offset.y = -(visualOffset - bounceOffset); // Negative because offset.y shifts down
			}
		}
	}

	override function draw():Void
	{
		// Don't draw the invisible main sprite
		// Draw all parts in correct order (back to front)

		leftBackLeg.draw();
		rightBackLeg.draw();
		leftForeLeg.draw();
		rightForeLeg.draw();
		abdomen.draw();
		thorax.draw();
		leftArmUpper.draw();
		rightArmUpper.draw();
		leftArmClaw.draw();
		rightArmClaw.draw();
		head.draw();
		mouth.draw();
		pincers.draw();
	}

	override function kill():Void
	{
		super.kill();

		// Kill all parts
		abdomen.kill();
		thorax.kill();
		head.kill();
		leftForeLeg.kill();
		rightForeLeg.kill();
		leftBackLeg.kill();
		rightBackLeg.kill();
		leftArmUpper.kill();
		rightArmUpper.kill();
		leftArmClaw.kill();
		rightArmClaw.kill();
		mouth.kill();
		pincers.kill();
	}

	public function takeDamage(damage:Float):Void
	{
		if (!isActive)
			return;

		currentHealth -= damage;
		if (currentHealth < 0)
			currentHealth = 0;

		// Flash effect on visible body parts
		head.color = FlxColor.RED;
		thorax.color = FlxColor.RED;
		abdomen.color = FlxColor.RED;
		// FlxG.sound.play("assets/sounds/hit.wav", 0.5);

		// Reset color after a moment
		haxe.Timer.delay(function()
		{
			head.color = FlxColor.WHITE;
			thorax.color = FlxColor.WHITE;
			abdomen.color = FlxColor.WHITE;
		}, 100);

		if (currentHealth <= 0)
		{
			onDefeated();
		}
	}

	function onDefeated():Void
	{
		isActive = false;
		// TODO: Trigger phase 2 death sequence
		trace("Phase 2 boss defeated!");
	}

	public function die():Void
	{
		kill();
	}

	public function moveTo(targetX:Float, targetY:Float, speed:Float, elapsed:Float):Void
	{
		// Simple lerp movement
		var lerpSpeed = speed * elapsed;
		x += (targetX - x) * lerpSpeed;
		y += (targetY - y) * lerpSpeed;

		updatePartPositions();
	}

	public function activate():Void
	{
		isActive = true;
		visible = true;
		
		// Start in WANDER mode
		attackState = WANDER;
		attackTimer = 3.0; // Wander for 3 seconds before first attack
		pickNewWanderTarget();
		wanderPickNewTargetTimer = 2.0;
	}

	public function getHealthPercent():Float
	{
		return currentHealth / maxHealth;
	}

	override function destroy():Void
	{
		abdomen.destroy();
		thorax.destroy();
		head.destroy();
		leftForeLeg.destroy();
		rightForeLeg.destroy();
		leftBackLeg.destroy();
		rightBackLeg.destroy();
		leftArmUpper.destroy();
		rightArmUpper.destroy();
		leftArmClaw.destroy();
		rightArmClaw.destroy();
		mouth.destroy();
		pincers.destroy();

		shadows = null;

		super.destroy();
	}
}

enum AttackState
{
	WANDER;
	CHARGE_TELEGRAPH;
	CHARGE_ATTACKING;
	CHARGE_RECOVERY;
}
