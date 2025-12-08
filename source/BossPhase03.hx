package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.tile.FlxTilemap;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

/**
 * Phase 3 Boss - Final form with wings, flying, multiple attacks
 */
class BossPhase03 extends FlxGroup implements IBoss
{
	// Body parts
	public var torso:FlxSprite;
	public var head:FlxSprite;
	public var abdomen:FlxSprite;
	public var leftWingFore:FlxSprite;
	public var leftWingBack:FlxSprite;
	public var rightWingFore:FlxSprite;
	public var rightWingBack:FlxSprite;
	public var leftLegFore:FlxSprite;
	public var leftLegBack:FlxSprite;
	public var rightLegFore:FlxSprite;
	public var rightLegBack:FlxSprite;

	public var shadows:Array<Shadow> = [];

	// IBoss interface properties
	public var maxHealth:Float;
	public var currentHealth:Float;
	public var bossName:String = "The Goddess Ruun-skei’ra, the End of Time Incarnate";

	var moveSpeed:Float = 30;

	public var isActive:Bool = false;

	// Attack state machine
	public var attackState:AttackState3 = WANDER;

	var attackTimer:Float = 0;
	var nextAttackCooldown:Float = 2.0;

	// Flying height
	var flyingHeight:Float = 24; // 24px above normal using offset.y

	// Wander variables
	var wanderTargetX:Float = 0;
	var wanderTargetY:Float = 0;
	var wanderSpeed:Float = 30;
	var wanderPickNewTargetTimer:Float = 0;

	// Wing animation
	var wingFlapTimer:Float = 0;
	var wingFlapDuration:Float = 0.3;
	var wingFrame:Int = 0; // 0 or 1

	// Leg animation
	var legMoveTimer:Float = 0;

	// Spit attack
	var spitShotsFired:Int = 0;
	var spitMaxShots:Int = 8; // Longer stream
	var spitShotDelay:Float = 0.15;
	var spitShotTimer:Float = 0;
	var spitTargetAngle:Float = 0; // Can change direction

	// Plasma attack
	var plasmasFired:Int = 0;
	var plasmasToFire:Int = 3; // All 3 at once
	var plasmaChargeTime:Float = 1.5;
	var plasmaFireDelay:Float = 0.1;

	// Time attack
	var timePulseRocks:Array<FlxSprite> = [];
	var timePulseTimer:Float = 0;
	var timePulseDuration:Float = 4.0; // Lasts longer
	var timePulseRockCount:Int = 20; // More rocks

	// References
	var player:Player;
	var projectiles:FlxTypedGroup<Projectile>;
	var plasmas:FlxTypedGroup<Plasma>;
	var tilemap:FlxTilemap;

	// Callbacks
	public var onSpawnRock:FlxSprite->Void;
	public var onSpawnFullscreenEffect:FlxSprite->Void;

	public function new(X:Float, Y:Float, Player:Player, Projectiles:FlxTypedGroup<Projectile>, Plasmas:FlxTypedGroup<Plasma>, Tilemap:FlxTilemap)
	{
		super();

		player = Player;
		projectiles = Projectiles;
		plasmas = Plasmas;
		tilemap = Tilemap;

		maxHealth = 120; // Tough final boss
		currentHealth = maxHealth;

		// Load all body parts
		// Load from JSON to get positions
		var json = haxe.Json.parse(openfl.Assets.getText("assets/images/boss-phase-03-full.json"));
		var frames = json.frames;

		// Create torso (main body)
		torso = new FlxSprite(X, Y);
		torso.loadGraphic("assets/images/boss-phase-03-torso.png");
		add(torso);

		// Create head
		head = new FlxSprite();
		head.loadGraphic("assets/images/boss-phase-03-head.png");
		positionPart(head, frames, "boss-phase-03-head.png");
		add(head);

		// Create abdomen
		abdomen = new FlxSprite();
		abdomen.loadGraphic("assets/images/boss-phase-03-abdomen.png");
		positionPart(abdomen, frames, "boss-phase-03-abdomen.png");
		add(abdomen);

		// Create wings (2 frames each - folded/spread)
		leftWingFore = new FlxSprite();
		leftWingFore.loadGraphic("assets/images/boss-phase-03-left-wing-fore.png", true, 32, 32); // Adjust size
		leftWingFore.animation.add("flap", [0, 1], 0, false);
		positionPart(leftWingFore, frames, "boss-phase-03-left-wing-fore.png");
		add(leftWingFore);

		leftWingBack = new FlxSprite();
		leftWingBack.loadGraphic("assets/images/boss-phase-03-left-wing-back.png", true, 32, 32);
		leftWingBack.animation.add("flap", [0, 1], 0, false);
		positionPart(leftWingBack, frames, "boss-phase-03-left-wing-back.png");
		add(leftWingBack);

		rightWingFore = new FlxSprite();
		rightWingFore.loadGraphic("assets/images/boss-phase-03-right-wing-fore.png", true, 32, 32);
		rightWingFore.animation.add("flap", [0, 1], 0, false);
		positionPart(rightWingFore, frames, "boss-phase-03-right-wing-fore.png");
		add(rightWingFore);

		rightWingBack = new FlxSprite();
		rightWingBack.loadGraphic("assets/images/boss-phase-03-right-wing-back.png", true, 32, 32);
		rightWingBack.animation.add("flap", [0, 1], 0, false);
		positionPart(rightWingBack, frames, "boss-phase-03-right-wing-back.png");
		add(rightWingBack);

		// Create legs
		leftLegFore = new FlxSprite();
		leftLegFore.loadGraphic("assets/images/boss-phase-03-left-leg-fore.png");
		positionPart(leftLegFore, frames, "boss-phase-03-left-leg-fore.png");
		add(leftLegFore);

		leftLegBack = new FlxSprite();
		leftLegBack.loadGraphic("assets/images/boss-phase-03-left-leg-back.png");
		positionPart(leftLegBack, frames, "boss-phase-03-left-leg-back.png");
		add(leftLegBack);

		rightLegFore = new FlxSprite();
		rightLegFore.loadGraphic("assets/images/boss-phase-03-right-leg-fore.png");
		positionPart(rightLegFore, frames, "boss-phase-03-right-leg-fore.png");
		add(rightLegFore);

		rightLegBack = new FlxSprite();
		rightLegBack.loadGraphic("assets/images/boss-phase-03-right-leg-back.png");
		positionPart(rightLegBack, frames, "boss-phase-03-right-leg-back.png");
		add(rightLegBack);

		// Set flying height on all parts
		applyFlyingHeight();
	}

	function positionPart(part:FlxSprite, frames:Dynamic, filename:String):Void
	{
		// Find frame data for this part
		for (frame in cast(frames, Array<Dynamic>))
		{
			if (frame.filename == filename)
			{
				var frameData:Dynamic = frame.frame;
				part.x = torso.x + frameData.x;
				part.y = torso.y + frameData.y;
				return;
			}
		}
	}

	function applyFlyingHeight():Void
	{
		// Use offset.y to make boss appear to fly
		torso.offset.y = -flyingHeight;
		head.offset.y = -flyingHeight;
		abdomen.offset.y = -flyingHeight;
		leftWingFore.offset.y = -flyingHeight;
		leftWingBack.offset.y = -flyingHeight;
		rightWingFore.offset.y = -flyingHeight;
		rightWingBack.offset.y = -flyingHeight;
		leftLegFore.offset.y = -flyingHeight;
		leftLegBack.offset.y = -flyingHeight;
		rightLegFore.offset.y = -flyingHeight;
		rightLegBack.offset.y = -flyingHeight;
	}

	public function createShadows(shadowLayer:ShadowLayer):Void
	{
		// Boss flies, so shadows need to be at ground level (not following offset.y)
		var torsoShadow = new Shadow(torso, "bossSegment", 0, 4);
		torsoShadow.groundY = torso.y + torso.height / 2; // Lock to ground
		shadows.push(shadowLayer.add(torsoShadow));

		var headShadow = new Shadow(head, "bossSegment", 0, 4);
		headShadow.groundY = head.y + head.height / 2;
		shadows.push(shadowLayer.add(headShadow));

		var abdomenShadow = new Shadow(abdomen, "bossSegment", 0, 4);
		abdomenShadow.groundY = abdomen.y + abdomen.height / 2;
		shadows.push(shadowLayer.add(abdomenShadow));
	}

	function updateShadowGroundPositions():Void
	{
		// Keep shadows at ground level as boss moves
		if (shadows.length >= 3)
		{
			shadows[0].groundY = torso.y + torso.height / 2;
			shadows[1].groundY = head.y + head.height / 2;
			shadows[2].groundY = abdomen.y + abdomen.height / 2;
		}
	}

	public function activate():Void
	{
		isActive = true;
		pickNewWanderTarget();
	}

	public function abortCurrentAttack():Void
	{
		// Cancel all ongoing attack effects when boss dies
		isActive = false;

		// Kill all flying rocks
		for (rock in timePulseRocks)
		{
			if (rock != null && rock.alive)
				rock.kill();
		}
		timePulseRocks = [];
	}

	public function takeDamage(damage:Float, ?damageInstanceId:String):Void
	{
		if (!isActive)
			return;

		currentHealth -= damage;
		if (currentHealth < 0)
			currentHealth = 0;

		// Flash white on all visible parts
		forEachOfType(FlxSprite, function(spr:FlxSprite)
		{
			if (spr != null && spr.visible)
			{
				FlxTween.color(spr, 0.1, FlxColor.WHITE, spr.color, {type: FlxTweenType.ONESHOT});
			}
		});
	}

	public function die():Void
	{
		isActive = false;
		visible = false;
	}

	public function moveTo(x:Float, y:Float, speed:Float, elapsed:Float):Void
	{
		var dx = x - torso.x;
		var dy = y - torso.y;
		var dist = Math.sqrt(dx * dx + dy * dy);

		if (dist > 1)
		{
			var angle = Math.atan2(dy, dx);
			torso.x += Math.cos(angle) * speed * elapsed;
			torso.y += Math.sin(angle) * speed * elapsed;
			updatePartPositions();
		}
	}

	public function checkOverlap(sprite:FlxSprite, useRotatedCollision:Bool = false, usePixelPerfect:Bool = false):Bool
	{
		// Check collision with main body parts
		if (torso.overlaps(sprite) || head.overlaps(sprite) || abdomen.overlaps(sprite))
			return true;

		// Check wings
		if (leftWingFore.overlaps(sprite) || leftWingBack.overlaps(sprite))
			return true;
		if (rightWingFore.overlaps(sprite) || rightWingBack.overlaps(sprite))
			return true;

		return false;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		// Always update animations and shadows (even during cinematics)
		animateWings(elapsed);
		animateLegs(elapsed);
		updateShadowGroundPositions();

		if (!isActive)
			return; // Update attack state machine
		updateAttackStateMachine(elapsed);
	}

	function animateWings(elapsed:Float):Void
	{
		wingFlapTimer += elapsed;
		if (wingFlapTimer >= wingFlapDuration)
		{
			wingFlapTimer = 0;
			wingFrame = 1 - wingFrame; // Toggle between 0 and 1

			leftWingFore.animation.frameIndex = wingFrame;
			leftWingBack.animation.frameIndex = wingFrame;
			rightWingFore.animation.frameIndex = wingFrame;
			rightWingBack.animation.frameIndex = wingFrame;
		}
	}

	function animateLegs(elapsed:Float):Void
	{
		legMoveTimer += elapsed;
		if (legMoveTimer >= 1.5)
		{
			legMoveTimer = 0;

			// Randomly pick a leg to move
			var leg = [leftLegFore, leftLegBack, rightLegFore, rightLegBack][FlxG.random.int(0, 3)];

			// Move up/out then down/in
			FlxTween.tween(leg.offset, {y: leg.offset.y - 4}, 0.2, {
				ease: FlxEase.quadOut,
				onComplete: function(_)
				{
					FlxTween.tween(leg.offset, {y: -flyingHeight}, 0.2, {ease: FlxEase.quadIn});
				}
			});
		}
	}

	function updateAttackStateMachine(elapsed:Float):Void
	{
		attackTimer += elapsed;

		switch (attackState)
		{
			case WANDER:
				updateWander(elapsed);
				if (attackTimer >= nextAttackCooldown)
				{
					chooseNextAttack();
				}

			case SPIT_ATTACKING:
				updateSpitAttack(elapsed);

			case PLASMA_CHARGING:
				// Just wait for charge time
				if (attackTimer >= plasmaChargeTime)
				{
					attackState = PLASMA_FIRING;
					attackTimer = 0;
				}

			case PLASMA_FIRING:
				updatePlasmaFiring(elapsed);

			case TIMEPULSE_SETUP:
				// TODO: Implement time attack
				attackState = WANDER;
				attackTimer = 0;

			default:
				// Other states not implemented
				attackState = WANDER;
				attackTimer = 0;
		}
	}

	function updateWander(elapsed:Float):Void
	{
		// Move toward wander target
		var dx = wanderTargetX - torso.x;
		var dy = wanderTargetY - torso.y;
		var dist = Math.sqrt(dx * dx + dy * dy);

		if (dist > 5)
		{
			var angle = Math.atan2(dy, dx);
			torso.x += Math.cos(angle) * wanderSpeed * elapsed;
			torso.y += Math.sin(angle) * wanderSpeed * elapsed;
			updatePartPositions();
		}
		else
		{
			pickNewWanderTarget();
		}
	}

	function pickNewWanderTarget():Void
	{
		// Pick random position in arena
		wanderTargetX = FlxG.random.float(40, tilemap.width - 40);
		wanderTargetY = FlxG.random.float(40, tilemap.height - 40);
	}

	function updatePartPositions():Void
	{
		// Update all part positions relative to torso
		// This is simplified - in reality you'd use the JSON offsets
		head.x = torso.x;
		head.y = torso.y - 16;
		abdomen.x = torso.x;
		abdomen.y = torso.y + 16;
		// etc...
	}

	function chooseNextAttack():Void
	{
		var attacks = [SPIT_ATTACKING, PLASMA_CHARGING, TIMEPULSE_SETUP];
		attackState = attacks[FlxG.random.int(0, attacks.length - 1)];
		attackTimer = 0;

		switch (attackState)
		{
			case SPIT_ATTACKING:
				spitShotsFired = 0;
				var angle = Math.atan2(player.y - torso.y, player.x - torso.x);
				spitTargetAngle = angle * (180 / Math.PI); // Convert to degrees
			case PLASMA_CHARGING:
				plasmasFired = 0;
			// TODO: Show charge effect on antenna/gem
			case TIMEPULSE_SETUP:
				// TODO: Implement
			default:
		}
	}

	function updateSpitAttack(elapsed:Float):Void
	{
		spitShotTimer += elapsed;
		if (spitShotTimer >= spitShotDelay && spitShotsFired < spitMaxShots)
		{
			spitShotTimer = 0;
			spitShotsFired++;

			// Fire projectile
			var proj:Projectile = projectiles.recycle(Projectile);
			if (proj == null)
			{
				proj = new Projectile();
				projectiles.add(proj);
			}

			proj.reset(head.x + head.width / 2, head.y + head.height / 2);
			proj.damage = 1.0;
			proj.loadGraphic("assets/images/spit.png");

			var angleRad = spitTargetAngle * (Math.PI / 180);
			proj.velocity.set(Math.cos(angleRad) * 150, Math.sin(angleRad) * 150);

			// Slightly adjust angle toward player for tracking
			var toPlayerAngle = Math.atan2(player.y - torso.y, player.x - torso.x) * (180 / Math.PI);
			spitTargetAngle += (toPlayerAngle - spitTargetAngle) * 0.1;
		}

		if (spitShotsFired >= spitMaxShots)
		{
			attackState = WANDER;
			attackTimer = 0;
		}
	}

	function updatePlasmaFiring(elapsed:Float):Void
	{
		if (plasmasFired < plasmasToFire)
		{
			plasmasFired++;

			// Fire from antenna or gem position
			var plasma:Plasma = plasmas.recycle(Plasma);
			if (plasma == null)
			{
				plasma = new Plasma();
				plasmas.add(plasma);
			}
			plasma.spawn(head.x + head.width / 2, head.y, player);
		}
		if (plasmasFired >= plasmasToFire)
		{
			attackState = WANDER;
			attackTimer = 0;
		}
	}
}

enum AttackState3
{
	WANDER;
	SPIT_ATTACKING;
	PLASMA_CHARGING;
	PLASMA_FIRING;
	TIMEPULSE_SETUP;
	TIMEPULSE_CHARGE;
	TIMEPULSE_LEVITATE;
	TIMEPULSE_FIRE;
	TIMEPULSE_CLEANUP;
}
