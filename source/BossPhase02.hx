package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.tile.FlxTilemap;
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
	var wanderStuckTimer:Float = 0; // Track if we're stuck trying to reach target
	var wanderStuckThreshold:Float = 3.0; // If stuck for 3 seconds, pick new target
	
	// Walking animation variables
	var walkCycleTimer:Float = 0;
	var walkCycleDuration:Float = 0.4; // Time for complete walk cycle
	var currentWalkPhase:Int = 0; // 0 = left-fore + right-back raised, 1 = right-fore + left-back raised
	
	// Idle bobbing animation
	var idleBobTimer:Float = 0;
	var idleBobDuration:Float = 2.0; // Complete bob cycle
	var idleBobAmount:Float = 1.5; // How many pixels to bob
	
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
	var chargeMaxDistance:Float = 150; // Increased from 80 - longer, more threatening charge

	// Spit attack variables
	var spitShotsFired:Int = 0;
	var spitMaxShots:Int = 3;
	var spitShotDelay:Float = 0.8; // Increased delay between spit shots
	var spitShotTimer:Float = 0;

	// Plasma attack variables
	var plasmasFired:Int = 0;
	var plasmaMaxShots:Int = 3;
	var plasmaFireDelay:Float = 0.5; // Increased from 0.1 - more delay between plasma shots
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
	var timePulseCurrentRock:FlxSprite = null; // Track current rock being animated
	var timePulseRockSpawnTimer:Float = 0;
	var timePulseRockSpawnDelay:Float = 1.5; // Longer delay between rocks
	var timePulseFullscreenEffect:FlxSprite = null;
	var timePulsePlayerSlowActive:Bool = false;
	var timePulseOriginalPlayerSpeed:Float = 1.0; // Store original speed for proper restoration

	// References
	var spitProjectiles:FlxTypedGroup<Projectile>;
	var plasmas:FlxTypedGroup<Plasma>;
	var player:Player;
	var tilemap:FlxTilemap; // Reference to the tilemap for ripping up rocks

	// Callback for spawning rocks (PlayState will handle adding them to scene)
	public var onSpawnRock:FlxSprite->Void = null;
	public var onSpawnFullscreenEffect:FlxSprite->Void = null;

	// Reference point for all parts (center of thorax)
	var centerX:Float = 0;
	var centerY:Float = 0;

	// Ground level - where leg tips touch (used for shadow positioning)
	var groundLevel:Float = 0;

	public function new(X:Float, Y:Float, Target:Player, ?SpitProjectiles:FlxTypedGroup<Projectile>, ?Plasmas:FlxTypedGroup<Plasma>, ?Tilemap:FlxTilemap)
	{
		super(X, Y);

		// Initialize boss logic (300 HP, 1 second damage cooldown)
		logic = new BossLogic(300, 1000);
		maxHealth = logic.maxHealth;
		currentHealth = logic.currentHealth;

		player = Target;
		spitProjectiles = SpitProjectiles;
		plasmas = Plasmas;
		tilemap = Tilemap;

		shadows = [];

		// Create an invisible sprite as the main reference point (60x68 canvas)
		makeGraphic(60, 68, FlxColor.TRANSPARENT);
		// DON'T center origin - we want x,y to be top-left
		// centerOrigin();

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

		// Head (top front) - updated position from JSON: x=13, y=6
		head = createPart("assets/images/boss-phase-02-head.png", 13, 6);

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
			// Reset any offset
			part.offset.set(0, 0);
			part.setGraphicSize(Std.int(part.frameWidth), Std.int(part.frameHeight));
			part.updateHitbox();
		}
		else
		{
			// All other parts: we want hitbox where sprite is VISUALLY, not where y is set
			// So we position the part at the VISUAL location, not at ground level
			part.x = originX + offset.x;
			part.y = originY + offset.y; // Position at actual visual location

			// No offset needed since position is already correct
			part.offset.set(0, 0);
			part.setGraphicSize(Std.int(part.frameWidth), Std.int(part.frameHeight));
			part.updateHitbox();
		}
	}

	public function createShadows(shadowLayer:ShadowLayer):Void
	{
		// Create shadows for all body parts
		// For raised parts, shadows need to know where ground level is
		var abdomenShadow = new Shadow(abdomen, "bossSegment", 0, 4);
		abdomenShadow.groundY = y + groundLevel; // Set shadow to ground level
		shadowLayer.add(abdomenShadow);
		shadows.push(abdomenShadow);

		var thoraxShadow = new Shadow(thorax, "bossSegment", 0, 4);
		thoraxShadow.groundY = y + groundLevel;
		shadowLayer.add(thoraxShadow);
		shadows.push(thoraxShadow);

		var headShadow = new Shadow(head, "bossSegment", 0, 4);
		headShadow.groundY = y + groundLevel;
		shadowLayer.add(headShadow);
		shadows.push(headShadow);

		// Legs touch ground, so their shadows follow them normally
		var leftForeLegShadow = new Shadow(leftForeLeg, "bossSegment", 0, 4);
		shadowLayer.add(leftForeLegShadow);
		shadows.push(leftForeLegShadow);

		var rightForeLegShadow = new Shadow(rightForeLeg, "bossSegment", 0, 4);
		shadowLayer.add(rightForeLegShadow);
		shadows.push(rightForeLegShadow);

		var leftBackLegShadow = new Shadow(leftBackLeg, "bossSegment", 0, 4);
		shadowLayer.add(leftBackLegShadow);
		shadows.push(leftBackLegShadow);

		var rightBackLegShadow = new Shadow(rightBackLeg, "bossSegment", 0, 4);
		shadowLayer.add(rightBackLegShadow);
		shadows.push(rightBackLegShadow);
	}

	function updateShadowGroundPositions():Void
	{
		// Update ground Y for raised body part shadows (not legs)
		var groundYPos = y + groundLevel;

		if (shadows.length >= 3)
		{
			shadows[0].groundY = groundYPos; // abdomen
			shadows[1].groundY = groundYPos; // thorax
			shadows[2].groundY = groundYPos; // head
		}
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		// Always update part positions and shadows (even during cinematics)
		updatePartPositions();
		updateShadowGroundPositions();

		if (!isActive)
			return;

		// Update boss logic (damage cooldowns)
		logic.update();

		// Update attack state machine
		updateAttackState(elapsed);
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

			case TIMEPULSE_CHARGE:
				updateTimePulseCharge(elapsed);

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
			wanderStuckTimer = 0; // Reset stuck timer when picking new target
		}

		// Move toward wander target
		var dx = wanderTargetX - x;
		var dy = wanderTargetY - y;
		var dist = Math.sqrt(dx * dx + dy * dy);

		if (dist > 5)
		{
			dx /= dist;
			dy /= dist;

			var oldX = x;
			var oldY = y;
			
			x += dx * wanderSpeed * elapsed;
			y += dy * wanderSpeed * elapsed;

			// Check if we actually moved (not stuck against bounds or obstacle)
			var actualDist = Math.sqrt((x - oldX) * (x - oldX) + (y - oldY) * (y - oldY));
			if (actualDist < wanderSpeed * elapsed * 0.5) // Moved less than half expected distance
			{
				wanderStuckTimer += elapsed;
				if (wanderStuckTimer >= wanderStuckThreshold)
				{
					// Stuck for too long, pick new target
					pickNewWanderTarget();
					wanderStuckTimer = 0;
				}
			}
			else
			{
				wanderStuckTimer = 0; // Making progress, reset stuck timer
			}

			// Update walking animation
			updateWalkingAnimation(elapsed);
		}
		else
		{
			// Reached target - idle bobbing animation
			idleBobTimer += elapsed;
			var bobProgress = (idleBobTimer % idleBobDuration) / idleBobDuration;
			var bobOffset = Math.sin(bobProgress * Math.PI * 2) * idleBobAmount;

			// Apply gentle bob to body parts (not legs)
			if (thorax != null)
				thorax.offset.y = thorax.offset.y + bobOffset;
			if (abdomen != null)
				abdomen.offset.y = abdomen.offset.y + bobOffset;
			if (head != null)
				head.offset.y = head.offset.y + bobOffset;
			if (leftArmUpper != null)
				leftArmUpper.offset.y = leftArmUpper.offset.y + bobOffset;
			if (rightArmUpper != null)
				rightArmUpper.offset.y = rightArmUpper.offset.y + bobOffset;
			if (leftArmClaw != null)
				leftArmClaw.offset.y = leftArmClaw.offset.y + bobOffset;
			if (rightArmClaw != null)
				rightArmClaw.offset.y = rightArmClaw.offset.y + bobOffset;

			// Pick new target after a moment
			pickNewWanderTarget();
			// Reset legs to ground
			resetLegsToGround();
			wanderStuckTimer = 0;
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
		}
	}

	function fireSpitShot():Void
	{
		if (spitProjectiles == null || player == null)
			return;

		// Fire from mouth position (not head center)
		var mouthCenterX = mouth.x + mouth.width / 2;
		var mouthCenterY = mouth.y + mouth.height / 2;

		var dx = player.x - mouthCenterX;
		var dy = player.y - mouthCenterY;
		var angle = Math.atan2(dy, dx);

		var projectile:Projectile = spitProjectiles.getFirstAvailable(Projectile);
		if (projectile == null)
		{
			projectile = new Projectile();
			spitProjectiles.add(projectile);
		}

		projectile.reset(mouthCenterX, mouthCenterY);
		projectile.damage = 1.0; // All boss damage is 1 heart
		projectile.loadGraphic("assets/images/spit.png");

		var speed:Float = 150;
		projectile.velocity.set(Math.cos(angle) * speed, Math.sin(angle) * speed);
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
	}

	function updatePlasmaCharging(elapsed:Float):Void
	{
		plasmaChargeTimer += elapsed;

		// Charge up
		if (plasmaChargeTimer >= plasmaChargeDuration)
		{
			attackState = PLASMA_FIRING;
			plasmaFireTimer = 0;
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
	}

	// ========== SLASH ATTACK ==========
	function startSlashAttack():Void
	{
		// Skip move-to-top, just slash from current position
		attackState = SLASH_RAISE_ARM;
		slashPauseTimer = 0.5; // Pause before striking
		slashArmRaised = false;
		slashUseLeftArm = FlxG.random.bool(); // Randomly pick which arm

		// Stop and raise the chosen arm (flip vertically)
		resetLegsToGround();
		var armToRaise = slashUseLeftArm ? leftArmClaw : rightArmClaw;
		if (armToRaise != null)
		{
			armToRaise.flipY = true;
			slashArmRaised = true;
		}
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

		// Boss moves to center of arena
		wanderTargetX = (FlxG.worldBounds.left + FlxG.worldBounds.right) / 2 - width / 2;
		wanderTargetY = (FlxG.worldBounds.top + FlxG.worldBounds.bottom) / 2 - height / 2;

		trace("Boss starting Time Pulse! Spawning " + timePulseRocksToSpawn + " rocks");
	}

	function updateTimePulseSetup(elapsed:Float):Void
	{
		// Move to center
		var dx = wanderTargetX - x;
		var dy = wanderTargetY - y;
		var dist = Math.sqrt(dx * dx + dy * dy);

		if (dist > 5)
		{
			dx /= dist;
			dy /= dist;
			x += dx * wanderSpeed * elapsed;
			y += dy * wanderSpeed * elapsed;
			updateWalkingAnimation(elapsed);
		}
		else
		{
			// Reached center, stop and start the attack
			resetLegsToGround();
			attackState = TIMEPULSE_CHARGE;
			attackTimer = 0.66; // Wait 0.66 seconds with antenna glowing
			
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
			// Start fading in purple immediately
			FlxTween.tween(timePulseFullscreenEffect, {alpha: 1}, 0.66);
		}
	}

	function updateTimePulseCharge(elapsed:Float):Void
	{
		attackTimer -= elapsed;

		// Wait 0.66 seconds with antenna glowing and screen turning purple
		if (attackTimer <= 0)
		{
			// Slow player after charge
			if (player != null && !timePulsePlayerSlowActive)
			{
				timePulseOriginalPlayerSpeed = player.moveSpeed;
				player.moveSpeed *= 0.5;
				timePulsePlayerSlowActive = true;
			}
			
			// Transition to levitate state
			attackState = TIMEPULSE_LEVITATE;
			timePulseRockSpawnTimer = 0;
		}
	}

	function updateTimePulseLevitate(elapsed:Float):Void
	{
		timePulseRockSpawnTimer += elapsed;

		// Spawn rocks periodically (only within visible screen bounds)
		if (timePulseRockSpawnTimer >= timePulseRockSpawnDelay && timePulseRocksSpawned < timePulseRocksToSpawn)
		{
			spawnFloatingRock();
			timePulseRocksSpawned++;
			timePulseRockSpawnTimer = 0;
		}

		// After all rocks spawned, wait 1s then start firing
		if (timePulseRocksSpawned >= timePulseRocksToSpawn)
		{
			attackTimer -= elapsed;
			if (attackTimer <= -1.0)
			{
				attackState = TIMEPULSE_FIRE;
				timePulseRockSpawnTimer = 0;
			}
		}
	}

	function updateTimePulseFire(elapsed:Float):Void
	{
		// Firing is now handled per-rock in animateRock callback
		// Just check if all rocks are done
		if (timePulseRocksFired >= timePulseRocksToSpawn)
		{
			attackState = TIMEPULSE_CLEANUP;
			attackTimer = 1.0; // Wait 1 second after last rock
		}
	}

	function updateTimePulseCleanup(elapsed:Float):Void
	{
		attackTimer -= elapsed;

		if (attackTimer <= 0)
		{
			// Gradually fade out fullscreen effect (slower fade)
			if (timePulseFullscreenEffect != null)
			{
				FlxTween.tween(timePulseFullscreenEffect, {alpha: 0}, 1.5, {
					onComplete: function(_)
					{
						timePulseFullscreenEffect.kill();
					}
				});
			}

			// Restore player speed properly using stored original value
			if (timePulsePlayerSlowActive && player != null)
			{
				player.moveSpeed = timePulseOriginalPlayerSpeed;
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
		if (tilemap == null)
		{
			trace("Warning: No tilemap reference for rock spawning!");
			return;
		}

		// Get camera bounds to ensure rocks spawn on screen (use 8x8 tile size)
		var camLeft = Std.int((FlxG.camera.scroll.x + 20) / 8) * 8;
		var camRight = Std.int((FlxG.camera.scroll.x + FlxG.width - 20) / 8) * 8;
		var camTop = Std.int((FlxG.camera.scroll.y + 20) / 8) * 8;
		var camBottom = Std.int((FlxG.camera.scroll.y + FlxG.height - 20) / 8) * 8;

		// Try to find a valid tile to rip up
		var validTile = false;
		var tileX:Int = 0;
		var tileY:Int = 0;
		var tileFrame:Int = 0;
		var attempts = 0;
		var maxAttempts = 50; // Prevent infinite loop

		while (!validTile && attempts < maxAttempts)
		{
			attempts++;

			// Pick a random position in camera bounds
			var worldX = FlxG.random.float(camLeft, camRight);
			var worldY = FlxG.random.float(camTop, camBottom);

			// Convert to tile coordinates (8x8 tiles)
			tileX = Std.int(worldX / 8);
			tileY = Std.int(worldY / 8);

			// Check if tile is in bounds
			if (tileX < 0 || tileY < 0 || tileX >= tilemap.widthInTiles || tileY >= tilemap.heightInTiles)
				continue;

			// Get the tile at this position
			var tile = tilemap.getTileIndex(tileX, tileY);

			// Only rip up solid tiles (not empty, not frame 96 which is the gap)
			if (tile > 0 && tile != 96)
			{
				// Check distance from player (not too close)
				if (player != null)
				{
					var dx = (tileX * 8) - player.x;
					var dy = (tileY * 8) - player.y;
					var dist = Math.sqrt(dx * dx + dy * dy);

					if (dist > 40)
					{
						validTile = true;
						tileFrame = tile;
					}
				}
				else
				{
					validTile = true;
					tileFrame = tile;
				}
			}
		}

		// If we couldn't find a valid tile, fall back to a random gray square
		if (!validTile)
		{
			trace("Could not find valid tile to rip up, using fallback");
			var rockX = FlxG.random.float(camLeft, camRight);
			var rockY = FlxG.random.float(camTop, camBottom);

			var rock = new FlxSprite(rockX, rockY);
			rock.makeGraphic(8, 8, FlxColor.GRAY);
			rock.offset.y = 0;
			rock.ID = 1;

			if (onSpawnRock != null)
				onSpawnRock(rock);
			animateRock(rock);
			timePulseRocks.push(rock);
			return;
		}

		// Create rock sprite at the tile position with the same graphic from lofi-environment.png
		var rockX = tileX * 8;
		var rockY = tileY * 8;

		var rock = new FlxSprite(rockX, rockY);
		// Load the lofi-environment tileset (8x8 tiles)
		rock.loadGraphic("assets/images/lofi_environment.png", true, 8, 8);
		rock.animation.frameIndex = tileFrame;

		// Add tile shadow underneath (8x8 to match tile size)
		var shadow = new FlxSprite(rockX, rockY);
		shadow.loadGraphic("assets/images/tile-shadow.png");
		shadow.alpha = 0.5;
		shadow.ID = -1; // Mark as shadow so we can identify it

		if (onSpawnRock != null)
		{
			onSpawnRock(shadow); // Add shadow first (underneath)
			onSpawnRock(rock); // Add rock on top
		}
		rock.offset.y = 0;
		rock.ID = 1; // 1.0 damage (1 heart)

		// Replace the tile with frame 96 (gap in the ground)
		tilemap.setTileIndex(tileX, tileY, 96);

		animateRock(rock);
		// DON'T animate shadow - it should stay on ground!
		timePulseRocks.push(rock);
		timePulseRocks.push(shadow); // Track shadow too
	}

	function animateRock(rock:FlxSprite):Void
	{
		// Rock starts at ground level, rises UP off the ground
		rock.offset.y = 0;

		// Mark this as the current rock
		timePulseCurrentRock = rock;

		// Rise UP over 0.5 seconds
		FlxTween.tween(rock.offset, {y: -16}, 0.5, {
			ease: FlxEase.quadOut,
			onComplete: function(_)
			{
				// After rise, spin slowly and wait random time
				if (rock.ID != -1) // Only spin the rock, not the shadow
				{
					// Start slow spin
					FlxTween.angle(rock, 0, 360, 1.5, {type: LOOPING});

					// Wait longer time (1.0 - 2.0s) then fire - gives player time to react
					var waitTime = 1.0 + Math.random() * 1.0;
					new FlxTimer().start(waitTime, function(_)
					{
						fireFloatingRock(rock);
					});
				}
			}
		});
	}

	function fireFloatingRock(rock:FlxSprite):Void
	{
		if (rock == null || player == null)
			return;

		// Cancel any ongoing angle tweens
		FlxTween.cancelTweensOf(rock, ["angle"]);

		// Aim at player's current position
		var dx = player.x - rock.x;
		var dy = player.y - rock.y;
		var angle = Math.atan2(dy, dx);

		// Start slow and accelerate to max speed (gives player reaction time)
		var maxSpeed = 180; // Reduced from 250 - more dodge-able
		var accelTime = 0.3; // Takes 0.3 seconds to reach max speed

		// Use FlxTween to accelerate velocity
		var targetVelX = Math.cos(angle) * maxSpeed;
		var targetVelY = Math.sin(angle) * maxSpeed;

		rock.velocity.set(Math.cos(angle) * 50, Math.sin(angle) * 50); // Start slow
		FlxTween.tween(rock.velocity, {x: targetVelX, y: targetVelY}, accelTime, {
			ease: FlxEase.quadIn
		});

		// Spin faster as it accelerates
		FlxTween.angle(rock, rock.angle, rock.angle + 720, accelTime, {ease: FlxEase.quadIn});

		// Mark this rock as fired
		timePulseRocksFired++;
		timePulseCurrentRock = null;
		
		// Spawn next rock if more to go
		if (timePulseRocksSpawned < timePulseRocksToSpawn)
		{
			spawnFloatingRock();
			timePulseRocksSpawned++;
		}
		else if (timePulseRocksFired >= timePulseRocksToSpawn)
		{
			// All rocks fired, transition to cleanup
			attackState = TIMEPULSE_CLEANUP;
			attackTimer = 1.0;
		}

		// NOTE: PlayState must check rock collisions with:
		// 1. Player - deal rock.ID damage (1.0) and kill rock
		// 2. WorldBounds - kill rock (pop like a bubble)
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
		// Clean up Time Pulse if active
		if (timePulsePlayerSlowActive && player != null)
		{
			player.moveSpeed = timePulseOriginalPlayerSpeed;
			timePulsePlayerSlowActive = false;
		}
		
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

	public function abortCurrentAttack():Void
	{
		// Cancel all ongoing attack effects when boss dies
		isActive = false;

		// Cancel time pulse effects
		if (timePulseFullscreenEffect != null)
		{
			timePulseFullscreenEffect.kill();
			timePulseFullscreenEffect = null;
		}

		// Restore player speed
		if (timePulsePlayerSlowActive && player != null)
		{
			player.moveSpeed = timePulseOriginalPlayerSpeed;
			timePulsePlayerSlowActive = false;
		}

		// Kill all flying rocks
		for (rock in timePulseRocks)
		{
			if (rock != null && rock.alive)
				rock.kill();
		}
		timePulseRocks = [];
	}

	public function roar():Void
	{
		// Open mouth and pincers for roar
		if (mouth != null)
			mouth.animation.play("open");
		if (pincers != null)
			pincers.animation.play("open");

		// Play roar sound
		FlxG.sound.play("assets/sounds/boss_roar.ogg", 0.8);
	}

	public function closeRoar():Void
	{
		// Close mouth and pincers
		if (mouth != null)
			mouth.animation.play("closed");
		if (pincers != null)
			pincers.animation.play("closed");
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
	TIMEPULSE_CHARGE;
	TIMEPULSE_LEVITATE;
	TIMEPULSE_FIRE;
	TIMEPULSE_CLEANUP;
}
