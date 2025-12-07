package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

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

	// Boss logic helper (handles health, damage, movement)
	var logic:BossLogic;

	// IBoss interface properties
	public var maxHealth:Float;
	public var currentHealth:Float;
	public var bossName:String = "Reth'kira, the Tooth which Cuts the Veil";

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
	var chargeMaxDistance:Float = 80; // Stop after traveling this far

	// Spit attack variables
	var spitShotsFired:Int = 0;
	var spitMaxShots:Int = 3;
	var spitShotDelay:Float = 0.5;
	var spitShotTimer:Float = 0;

	// Plasma attack variables
	var plasmasFired:Int = 0;
	var plasmaMaxShots:Int = 3;
	var plasmaFireDelay:Float = 0.1;
	var plasmaFireTimer:Float = 0;
	var plasmaChargeTimer:Float = 0;
	var plasmaChargeDuration:Float = 1.0;
	var plasmaAngles:Array<Float> = [45, -45, 0]; // Degrees

	// Slash attack variables
	var slashArmRaised:Bool = false;
	var slashUseLeftArm:Bool = false;
	var slashPauseTimer:Float = 0;
	var slashMoveDuration:Float = 0.5;

	// Time Pulse variables
	var timePulseRocksToSpawn:Int = 0;
	var timePulseRocksSpawned:Int = 0;
	var timePulseRocksFired:Int = 0;
	var timePulseRocks:Array<FlxSprite> = [];
	var timePulseRockSpawnTimer:Float = 0;
	var timePulseRockSpawnDelay:Float = 0.2;
	var timePulseFullscreenEffect:FlxSprite = null;
	var timePulsePlayerSlowActive:Bool = false;

	// References
	var spitProjectiles:FlxTypedGroup<Projectile>;
	var plasmas:FlxTypedGroup<Plasma>;
	var player:Player;

	// Callback for spawning rocks (PlayState will handle adding them to scene)
	public var onSpawnRock:FlxSprite->Void = null;
	public var onSpawnFullscreenEffect:FlxSprite->Void = null;

	// Reference point for all parts (center of thorax)
	var centerX:Float = 0;
	var centerY:Float = 0;

	// Ground level - where leg tips touch (used for shadow positioning)
	var groundLevel:Float = 0;

	public function new(X:Float, Y:Float, Target:Player, ?SpitProjectiles:FlxTypedGroup<Projectile>, ?Plasmas:FlxTypedGroup<Plasma>)
	{
		super(X, Y);

		// Initialize boss logic (300 HP, 1 second damage cooldown)
		logic = new BossLogic(300, 1000);
		maxHealth = logic.maxHealth;
		currentHealth = logic.currentHealth;

		player = Target;
		spitProjectiles = SpitProjectiles;
		plasmas = Plasmas;

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

		// Update boss logic (damage cooldowns)
		logic.update();

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
			case SPIT_ATTACKING:
				updateSpitAttack(elapsed);

			case PLASMA_CHARGING:
				updatePlasmaCharging(elapsed);

			case PLASMA_FIRING:
				updatePlasmaFiring(elapsed);

			case SLASH_MOVE_TO_TOP:
				updateSlashMoveToTop(elapsed);

			case SLASH_RAISE_ARM:
				updateSlashRaiseArm(elapsed);

			case SLASH_STRIKE:
				updateSlashStrike(elapsed);

			case TIMEPULSE_SETUP:
				updateTimePulseSetup(elapsed);

			case TIMEPULSE_LEVITATE:
				updateTimePulseLevitate(elapsed);

			case TIMEPULSE_FIRE:
				updateTimePulseFire(elapsed);

			case TIMEPULSE_CLEANUP:
				updateTimePulseCleanup(elapsed);
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

		// Full walk cycle duration
		var progress = (walkCycleTimer % walkCycleDuration) / walkCycleDuration;

		// Pair 1: left-fore + right-back (bob 0.0 - 0.5)
		// Pair 2: right-fore + left-back (bob 0.5 - 1.0)

		var pair1Bob = 0.0;
		var pair2Bob = 0.0;

		// Pair 1 rises and falls in first half
		if (progress < 0.25)
		{
			// Rising
			pair1Bob = FlxMath.lerp(0, 2, progress / 0.25);
		}
		else if (progress < 0.5)
		{
			// Falling
			pair1Bob = FlxMath.lerp(2, 0, (progress - 0.25) / 0.25);
		}

		// Pair 2 rises and falls in second half
		if (progress >= 0.5 && progress < 0.75)
		{
			// Rising
			pair2Bob = FlxMath.lerp(0, 2, (progress - 0.5) / 0.25);
		}
		else if (progress >= 0.75)
		{
			// Falling
			pair2Bob = FlxMath.lerp(2, 0, (progress - 0.75) / 0.25);
		}

		// Apply leg bobs (offset.y negative raises them)
		leftForeLeg.offset.y = -pair1Bob;
		rightBackLeg.offset.y = -pair1Bob;
		rightForeLeg.offset.y = -pair2Bob;
		leftBackLeg.offset.y = -pair2Bob;

		// Thorax bobs with average of both leg pairs
		var thoraxBob = (pair1Bob + pair2Bob) / 2;
		var baseAbdomenOffset = partOffsets.get(abdomen);
		var baseThoraxOffset = partOffsets.get(thorax);
		var baseHeadOffset = partOffsets.get(head);

		if (baseAbdomenOffset != null)
		{
			var visualOffset = baseAbdomenOffset.y - groundLevel;
			abdomen.offset.y = -(visualOffset - thoraxBob);
		}

		if (baseThoraxOffset != null)
		{
			var visualOffset = baseThoraxOffset.y - groundLevel;
			thorax.offset.y = -(visualOffset - thoraxBob);
		}

		// Head bobs with thorax +/- 2px extra
		if (baseHeadOffset != null)
		{
			var visualOffset = baseHeadOffset.y - groundLevel;
			var headExtraBob = Math.sin(progress * Math.PI * 2) * 2;
			head.offset.y = -(visualOffset - thoraxBob - headExtraBob);
		}

		// Arms bob with thorax
		var baseLeftArmUpperOffset = partOffsets.get(leftArmUpper);
		var baseRightArmUpperOffset = partOffsets.get(rightArmUpper);
		var baseLeftArmClawOffset = partOffsets.get(leftArmClaw);
		var baseRightArmClawOffset = partOffsets.get(rightArmClaw);

		if (baseLeftArmUpperOffset != null)
		{
			var visualOffset = baseLeftArmUpperOffset.y - groundLevel;
			leftArmUpper.offset.y = -(visualOffset - thoraxBob);
		}
		if (baseRightArmUpperOffset != null)
		{
			var visualOffset = baseRightArmUpperOffset.y - groundLevel;
			rightArmUpper.offset.y = -(visualOffset - thoraxBob);
		}
		if (baseLeftArmClawOffset != null)
		{
			var visualOffset = baseLeftArmClawOffset.y - groundLevel;
			leftArmClaw.offset.y = -(visualOffset - thoraxBob);
		}
		if (baseRightArmClawOffset != null)
		{
			var visualOffset = baseRightArmClawOffset.y - groundLevel;
			rightArmClaw.offset.y = -(visualOffset - thoraxBob);
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
		// Stop walking before choosing attack
		resetLegsToGround();

		// Choose random attack
		var choice = FlxG.random.int(0, 4); // 5 attacks: CHARGE, SPIT, PLASMA, SLASH, TIMEPULSE
		
		switch (choice)
		{
			case 0:
				startChargeAttack();
			case 1:
				startSpitAttack();
			case 2:
				startPlasmaAttack();
			case 3:
				startSlashAttack();
			case 4:
				startTimePulseAttack();
			default:
				// Fallback to wander
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

	// ========== SPIT ATTACK ==========
	function startSpitAttack():Void
	{
		attackState = SPIT_ATTACKING;
		spitShotsFired = 0;
		spitShotTimer = 0;

		// Open mouth/pincers
		if (mouth != null)
			mouth.animation.play("open");
		if (pincers != null)
			pincers.animation.play("open");

		trace("Boss starting spit attack (3 shots)!");
	}

	function updateSpitAttack(elapsed:Float):Void
	{
		spitShotTimer += elapsed;

		if (spitShotTimer >= spitShotDelay && spitShotsFired < spitMaxShots)
		{
			fireSpitShot();
			spitShotsFired++;
			spitShotTimer = 0;
		}

		// After all shots fired, close mouth and return to wander
		if (spitShotsFired >= spitMaxShots)
		{
			if (mouth != null)
				mouth.animation.play("closed");
			if (pincers != null)
				pincers.animation.play("closed");

			attackState = WANDER;
			attackTimer = nextAttackCooldown;
			pickNewWanderTarget();
			trace("Spit attack complete!");
		}
	}

	function fireSpitShot():Void
	{
		if (spitProjectiles == null || player == null)
			return;

		// Fire towards player from head position
		var headCenterX = head.x + head.width / 2;
		var headCenterY = head.y + head.height / 2;

		var dx = player.x - headCenterX;
		var dy = player.y - headCenterY;
		var angle = Math.atan2(dy, dx);

		var projectile:Projectile = spitProjectiles.getFirstAvailable(Projectile);
		if (projectile == null)
		{
			projectile = new Projectile();
			spitProjectiles.add(projectile);
		}

		projectile.reset(headCenterX, headCenterY);
		projectile.damage = 0.7;
		projectile.loadGraphic("assets/images/spit.png");

		var speed:Float = 150;
		projectile.velocity.set(Math.cos(angle) * speed, Math.sin(angle) * speed);

		trace("Fired spit shot " + (spitShotsFired + 1) + "/" + spitMaxShots);
	}

	// ========== PLASMA ATTACK ==========
	function startPlasmaAttack():Void
	{
		attackState = PLASMA_CHARGING;
		plasmasFired = 0;
		plasmaChargeTimer = 0;

		// Open mouth/pincers
		if (mouth != null)
			mouth.animation.play("open");
		if (pincers != null)
			pincers.animation.play("open");

		trace("Boss charging plasma attack!");
	}

	function updatePlasmaCharging(elapsed:Float):Void
	{
		plasmaChargeTimer += elapsed;

		// Charge up
		if (plasmaChargeTimer >= plasmaChargeDuration)
		{
			attackState = PLASMA_FIRING;
			plasmaFireTimer = 0;
			trace("FIRING PLASMAS!");
		}
	}

	function updatePlasmaFiring(elapsed:Float):Void
	{
		plasmaFireTimer += elapsed;

		// Fire staggered plasma shots
		if (plasmaFireTimer >= plasmaFireDelay && plasmasFired < plasmaMaxShots)
		{
			firePlasmaShot(plasmaAngles[plasmasFired]);
			plasmasFired++;
			plasmaFireTimer = 0;
		}

		// After all plasmas fired, close mouth and return to wander
		if (plasmasFired >= plasmaMaxShots)
		{
			if (mouth != null)
				mouth.animation.play("closed");
			if (pincers != null)
				pincers.animation.play("closed");

			attackState = WANDER;
			attackTimer = nextAttackCooldown;
			pickNewWanderTarget();
			trace("Plasma attack complete!");
		}
	}

	function firePlasmaShot(angleDegrees:Float):Void
	{
		if (plasmas == null || player == null)
			return;

		// Fire from head position at specified angle offset
		var headCenterX = head.x + head.width / 2;
		var headCenterY = head.y + head.height / 2;

		var plasma:Plasma = plasmas.recycle(Plasma);
		if (plasma == null)
		{
			plasma = new Plasma();
			plasmas.add(plasma);
		}

		// Spawn plasma and launch towards player (it will home)
		plasma.spawn(headCenterX, headCenterY, player);

		// Optionally add angle offset to initial velocity for spread
		if (angleDegrees != 0)
		{
			var angleRad = angleDegrees * Math.PI / 180;
			var currentSpeed = Math.sqrt(plasma.velocity.x * plasma.velocity.x + plasma.velocity.y * plasma.velocity.y);
			var currentAngle = Math.atan2(plasma.velocity.y, plasma.velocity.x);
			var newAngle = currentAngle + angleRad;
			var newVelX = Math.cos(newAngle) * currentSpeed;
			var newVelY = Math.sin(newAngle) * currentSpeed;
			plasma.velocity.set(newVelX, newVelY);
		}

		trace("Fired plasma at " + angleDegrees + " degrees offset");
	}

	// ========== SLASH ATTACK ==========
	function startSlashAttack():Void
	{
		attackState = SLASH_MOVE_TO_TOP;
		attackTimer = slashMoveDuration;
		slashArmRaised = false;
		slashUseLeftArm = FlxG.random.bool(); // Randomly pick which arm

		// Target: top center of arena
		wanderTargetX = (FlxG.worldBounds.left + FlxG.worldBounds.right) / 2;
		wanderTargetY = FlxG.worldBounds.top + 40;

		trace("Boss starting slash attack with " + (slashUseLeftArm ? "left" : "right") + " arm!");
	}

	function updateSlashMoveToTop(elapsed:Float):Void
	{
		// Move to top center
		var dx = wanderTargetX - x;
		var dy = wanderTargetY - y;
		var dist = Math.sqrt(dx * dx + dy * dy);

		if (dist < 5 || attackTimer <= 0)
		{
			// Reached position
			attackState = SLASH_RAISE_ARM;
			slashPauseTimer = 0.1;

			// Raise the chosen arm (flip vertically)
			var armToRaise = slashUseLeftArm ? leftArmClaw : rightArmClaw;
			if (armToRaise != null)
			{
				armToRaise.flipY = true;
				slashArmRaised = true;
			}

			trace("Arm raised!");
		}
		else
		{
			// Keep moving
			var angle = Math.atan2(dy, dx);
			x += Math.cos(angle) * wanderSpeed * elapsed;
			y += Math.sin(angle) * wanderSpeed * elapsed;
			updateWalkingAnimation(elapsed);
		}
	}

	function updateSlashRaiseArm(elapsed:Float):Void
	{
		slashPauseTimer -= elapsed;

		if (slashPauseTimer <= 0)
		{
			attackState = SLASH_STRIKE;
			slashPauseTimer = 0;

			// Lower arm
			var armToLower = slashUseLeftArm ? leftArmClaw : rightArmClaw;
			if (armToLower != null)
			{
				armToLower.flipY = false;
			}

			// Fire air blast
			fireSlashBlast();

			trace("SLASH!");
		}
	}

	function updateSlashStrike(elapsed:Float):Void
	{
		// Wait a moment then return to wander
		if (attackTimer <= 0.3)
		{
			attackState = WANDER;
			attackTimer = nextAttackCooldown;
			pickNewWanderTarget();
		}
	}

	function fireSlashBlast():Void
	{
		if (spitProjectiles == null || player == null)
			return;

		// Fire from the arm that slashed
		var armSource = slashUseLeftArm ? leftArmClaw : rightArmClaw;
		var sourceX = armSource.x + armSource.width / 2;
		var sourceY = armSource.y + armSource.height;

		// Angle towards player, clamped to max 60 degrees from vertical
		var dx = player.x - sourceX;
		var dy = player.y - sourceY;
		var targetAngle = Math.atan2(dy, dx);

		// Vertical is PI/2 (90 degrees), clamp to +/- 60 degrees
		var verticalAngle = Math.PI / 2;
		var maxOffset = Math.PI / 3; // 60 degrees in radians

		var finalAngle = FlxMath.bound(targetAngle, verticalAngle - maxOffset, verticalAngle + maxOffset);

		var projectile:Projectile = spitProjectiles.getFirstAvailable(Projectile);
		if (projectile == null)
		{
			projectile = new Projectile();
			spitProjectiles.add(projectile);
		}

		projectile.reset(sourceX, sourceY);
		projectile.damage = 1.0;
		projectile.loadGraphic("assets/images/air-slash.png"); // You'll need to create this
		projectile.velocity.set(Math.cos(finalAngle) * 200, Math.sin(finalAngle) * 200);

		trace("Fired slash blast!");
	}

	// ========== TIME PULSE ATTACK ==========
	function startTimePulseAttack():Void
	{
		attackState = TIMEPULSE_SETUP;
		timePulseRocksToSpawn = FlxG.random.int(4, 8);
		timePulseRocksSpawned = 0;
		timePulseRocksFired = 0;
		timePulseRocks = [];
		timePulseRockSpawnTimer = 0;

		// Create fullscreen effect
		if (timePulseFullscreenEffect == null)
		{
			timePulseFullscreenEffect = new FlxSprite();
			timePulseFullscreenEffect.makeGraphic(FlxG.width, FlxG.height, 0x20800080); // Purple glow at 12.5% opacity
			timePulseFullscreenEffect.scrollFactor.set(0, 0); // Fixed to camera
			timePulseFullscreenEffect.alpha = 0;

			// Add fullscreen effect to PlayState via callback
			if (onSpawnFullscreenEffect != null)
			{
				onSpawnFullscreenEffect(timePulseFullscreenEffect);
			}
		}

		// Fade in effect
		FlxTween.tween(timePulseFullscreenEffect, {alpha: 1}, 0.5);

		// Slow player
		timePulsePlayerSlowActive = true;
		if (player != null)
		{
			player.moveSpeed *= 0.5;
		}

		trace("Boss starting Time Pulse! Spawning " + timePulseRocksToSpawn + " rocks");
	}

	function updateTimePulseSetup(elapsed:Float):Void
	{
		// Transition to levitate state
		attackState = TIMEPULSE_LEVITATE;
		timePulseRockSpawnTimer = 0;
	}

	function updateTimePulseLevitate(elapsed:Float):Void
	{
		timePulseRockSpawnTimer += elapsed;

		// Spawn rocks periodically
		if (timePulseRockSpawnTimer >= timePulseRockSpawnDelay && timePulseRocksSpawned < timePulseRocksToSpawn)
		{
			spawnFloatingRock();
			timePulseRocksSpawned++;
			timePulseRockSpawnTimer = 0;
		}

		// After all rocks spawned, wait 0.2s then start firing
		if (timePulseRocksSpawned >= timePulseRocksToSpawn)
		{
			attackTimer -= elapsed;
			if (attackTimer <= -0.2)
			{
				attackState = TIMEPULSE_FIRE;
				timePulseRockSpawnTimer = 0;
			}
		}
	}

	function updateTimePulseFire(elapsed:Float):Void
	{
		timePulseRockSpawnTimer += elapsed;

		// Fire rocks one by one
		if (timePulseRockSpawnTimer >= 0.15 && timePulseRocksFired < timePulseRocks.length)
		{
			fireFloatingRock(timePulseRocks[timePulseRocksFired]);
			timePulseRocksFired++;
			timePulseRockSpawnTimer = 0;
		}

		// After all rocks fired, clean up
		if (timePulseRocksFired >= timePulseRocks.length)
		{
			attackState = TIMEPULSE_CLEANUP;
			attackTimer = 0.5;
		}
	}

	function updateTimePulseCleanup(elapsed:Float):Void
	{
		attackTimer -= elapsed;

		if (attackTimer <= 0)
		{
			// Fade out fullscreen effect
			if (timePulseFullscreenEffect != null)
			{
				FlxTween.tween(timePulseFullscreenEffect, {alpha: 0}, 0.5, {
					onComplete: function(_)
					{
						timePulseFullscreenEffect.kill();
					}
				});
			}

			// Restore player speed
			if (timePulsePlayerSlowActive && player != null)
			{
				player.moveSpeed *= 2; // Restore from 0.5x
				timePulsePlayerSlowActive = false;
			}

			// Return to wander
			attackState = WANDER;
			attackTimer = nextAttackCooldown;
			pickNewWanderTarget();
			trace("Time Pulse complete!");
		}
	}

	function spawnFloatingRock():Void
	{
		// Spawn rock at random position (not on player)
		var rockX:Float = 0;
		var rockY:Float = 0;
		var validPosition = false;

		while (!validPosition)
		{
			rockX = FlxG.random.float(FlxG.worldBounds.left + 20, FlxG.worldBounds.right - 20);
			rockY = FlxG.random.float(FlxG.worldBounds.top + 20, FlxG.worldBounds.bottom - 20);

			// Check distance from player
			if (player != null)
			{
				var dx = rockX - player.x;
				var dy = rockY - player.y;
				var dist = Math.sqrt(dx * dx + dy * dy);

				if (dist > 40)
				{
					validPosition = true;
				}
			}
			else
			{
				validPosition = true;
			}
		}

		// Create rock sprite (use a simple graphic for now)
		var rock = new FlxSprite(rockX, rockY);
		rock.makeGraphic(8, 8, FlxColor.GRAY);
		rock.offset.y = 0; // Start at ground level

		// Add rock to PlayState via callback
		if (onSpawnRock != null)
		{
			onSpawnRock(rock);
		}

		// Tween rock upward
		FlxTween.tween(rock.offset, {y: -16}, 0.5, {
			onComplete: function(_)
			{
				// Start spinning
				FlxTween.angle(rock, 0, 360, 1.0, {type: LOOPING});
			}
		});

		timePulseRocks.push(rock);
		trace("Spawned floating rock at " + rockX + ", " + rockY);
	}

	function fireFloatingRock(rock:FlxSprite):Void
	{
		if (rock == null || player == null)
			return;

		// Aim at player's current position
		var dx = player.x - rock.x;
		var dy = player.y - rock.y;
		var angle = Math.atan2(dy, dx);

		// Launch rock towards player
		rock.velocity.set(Math.cos(angle) * 200, Math.sin(angle) * 200);

		trace("Fired rock!");

		// TODO: Handle rock collision with player/walls in PlayState
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

	public function takeDamage(damage:Float, ?damageInstanceId:String):Void
	{
		if (!isActive)
			return;

		// Delegate to BossLogic - handles cooldown check and damage application
		if (!logic.takeDamage(damage, damageInstanceId))
		{
			return; // Still on cooldown for this specific instance
		}

		// Sync health from logic to interface properties
		currentHealth = logic.currentHealth;

		// Flash effect on visible body parts
		head.color = FlxColor.RED;
		thorax.color = FlxColor.RED;
		abdomen.color = FlxColor.RED;
		// FlxG.sound.play("assets/sounds/hit.wav", 0.5);

		// Reset color after 0.1 seconds
		new FlxTimer().start(0.1, function(_)
		{
			head.color = FlxColor.WHITE;
			thorax.color = FlxColor.WHITE;
			abdomen.color = FlxColor.WHITE;
		});

		if (logic.isDead())
		{
			onDefeated();
		}
	}

	function onDefeated():Void
	{
		isActive = false;
		alive = false;
		// NOTE: Keep exists = true so PlayState can detect death and trigger phase 3
		// PlayState will handle cleanup and phase changes
		trace("Phase 2 boss defeated!");
	}

	public function die():Void
	{
		alive = false;
		// NOTE: Keep exists = true for phase transition detection
	}

	public function checkOverlap(sprite:FlxSprite, useRotatedCollision:Bool = false, usePixelPerfect:Bool = false):Bool
	{
		// Check collision with all body parts (not legs, they're cosmetic)
		var bodyParts = [abdomen, thorax, head, leftArmUpper, rightArmUpper, leftArmClaw, rightArmClaw];

		for (part in bodyParts)
		{
			if (part == null || !part.exists || !part.alive)
				continue;

			// First check: AABB or rotated collision
			var basicOverlap = false;
			if (useRotatedCollision && Std.isOfType(sprite, RotatedSprite))
			{
				// Use RotatedSprite's overlaps method for rotated collision
				basicOverlap = cast(sprite, RotatedSprite).overlaps(part);
			}
			else
			{
				// Standard AABB check
				basicOverlap = sprite.overlaps(part);
			}

			// Second check: pixel-perfect if requested
			if (basicOverlap)
			{
				if (usePixelPerfect)
				{
					if (FlxG.pixelPerfectOverlap(sprite, part))
						return true;
				}
				else
				{
					return true;
				}
			}
		}

		return false;
	}

	public function moveTo(targetX:Float, targetY:Float, speed:Float, elapsed:Float):Void
	{
		// Delegate to BossLogic for movement calculation
		var pos = logic.moveTowards(x, y, targetX, targetY, speed, elapsed);
		x = pos.newX;
		y = pos.newY;

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
	SPIT_ATTACKING;
	PLASMA_CHARGING;
	PLASMA_FIRING;
	SLASH_MOVE_TO_TOP;
	SLASH_RAISE_ARM;
	SLASH_STRIKE;
	TIMEPULSE_SETUP;
	TIMEPULSE_LEVITATE;
	TIMEPULSE_FIRE;
	TIMEPULSE_CLEANUP;
}
