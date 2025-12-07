package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;

class BossPhase01Larva extends FlxTypedGroup<FlxSprite> implements IBoss
{
	// Boss logic helper (handles health, damage, movement)
	var logic:BossLogic;

	// IBoss interface properties
	public var maxHealth:Float;
	public var currentHealth:Float;
	public var bossName:String = "Resh'Lar, She Who Molts the First Shell";
	public var contactDamage:Float = 1.0;
	public var width:Float = 40;
	public var height:Float = 40;

	// Burn effect tracking
	public var isBurning:Bool = false;
	public var burnTimer:Float = 0;
	public var burnDamagePerSecond:Float = 0;

	public var headSegment:BossSegment;
	var foreSegment:BossSegment;
	var backSegment:BossSegment;
	var lastSegment:BossSegment;
	var squishFactor:Float = 0;

	var mouth:FlxSprite;
	var pincers:FlxSprite;

	var mode:BossMode = IDLE;
	var modeTimer:Float = 0;
	var isReady:Bool = false;
	var lastAttackTime:Float = 0; // Track time since last attack
	var attackCooldown:Float = 3.0; // Minimum time between attacks (wander period)

	public var x(get, never):Float;
	public var y(get, never):Float;

	public var headX:Float;
	public var headY:Float;
	var baseX:Float;
	var baseY:Float;
	var targetX:Float;
	var targetY:Float;
	var moveSpeed:Float = 20;
	var wiggleTime:Float = 0;
	var wiggleAmplitude:Float = 5;
	var wiggleFrequency:Float = 5;

	var attackCallback:Void->Void;
	var spitProjectiles:FlxTypedGroup<Projectile>;
	var plasmas:FlxTypedGroup<Plasma>;
	var activePlasma:Plasma = null; // Track active plasma for attack completion
	var player:Player;

	var mouthOpen:Bool = false;
	var pincersOpen:Bool = false;
	var pincerWiggleTimer:Float = 0;
	var hasRoared:Bool = false;

	public var shadows:Array<Shadow>;

	public function new(X:Float, Y:Float, Target:Player, ?AttackCallback:Void->Void, ?SpitProjectiles:FlxTypedGroup<Projectile>, ?Plasmas:FlxTypedGroup<Plasma>)
	{
		super();

		// Initialize boss logic (1000 HP, 1 second damage cooldown)
		logic = new BossLogic(1000, 1000);
		maxHealth = logic.maxHealth;
		currentHealth = logic.currentHealth;

		headX = X;
		headY = Y;
		baseX = X;
		baseY = Y;
		targetX = X;
		targetY = Y;
		player = Target;
		attackCallback = AttackCallback;
		spitProjectiles = SpitProjectiles;
		plasmas = Plasmas;

		var lastSprite = new FlxSprite();
		lastSprite.loadGraphic(AssetPaths.boss_phase_01_larva_last_segment__png);
		lastSprite.alpha = 0;
		add(lastSprite);

		var backSprite = new FlxSprite();
		backSprite.loadGraphic(AssetPaths.boss_phase_01_larva_back_segment__png);
		backSprite.alpha = 0;
		add(backSprite);

		var foreSprite = new FlxSprite();
		foreSprite.loadGraphic(AssetPaths.boss_phase_01_larva_fore_segment__png);
		foreSprite.alpha = 0;
		add(foreSprite);

		var headSprite = new FlxSprite();
		headSprite.loadGraphic(AssetPaths.boss_phase_01_larva_head__png);
		headSprite.alpha = 0;
		add(headSprite);

		mouth = new FlxSprite();
		mouth.loadGraphic(AssetPaths.boss_phase_01_larva_mouth__png, true, 6, 9);
		mouth.animation.add("closed", [1]);
		mouth.animation.add("open", [0]);
		mouth.animation.play("closed");
		mouth.alpha = 0;
		add(mouth);

		pincers = new FlxSprite();
		pincers.loadGraphic(AssetPaths.boss_phase_01_larva_pincers__png, true, 26, 13);
		pincers.animation.add("closed", [1]);
		pincers.animation.add("open", [0]);
		pincers.animation.play("closed");
		pincers.alpha = 0;
		add(pincers);

		headSegment = new BossSegment(headSprite, 0, null);
		foreSegment = new BossSegment(foreSprite, 25, headSegment);
		backSegment = new BossSegment(backSprite, 45, foreSegment);
		lastSegment = new BossSegment(lastSprite, 60, backSegment);

		squishFactor = 0;
		// All segments start at the SAME position (squished together)
		lastSegment.setCenter(headX, headY);
		backSegment.setCenter(headX, headY);
		foreSegment.setCenter(headX, headY);
		headSegment.setCenter(headX, headY);

		// Initialize shadows array (will be populated from PlayState)
		shadows = [];

		updateMouthAndPincers();
		currentHealth = maxHealth;
	}

	function updateSegments():Void
	{
		headSegment.setCenter(headX, headY);
		foreSegment.setCenter(headX, headY - 20);
		backSegment.setCenter(headX, headY - 38);
		lastSegment.setCenter(headX, headY - 53);

		applyWiggle();
	}

	function applyWiggle():Void
	{
		var wiggle1 = Math.sin(wiggleTime + 0) * wiggleAmplitude;
		var wiggle2 = Math.sin(wiggleTime + 0.8) * wiggleAmplitude;
		var wiggle3 = Math.sin(wiggleTime + 1.6) * wiggleAmplitude;

		// Use Y offset for crawling motion, keep it subtle
		foreSegment.sprite.offset.y = wiggle1;
		backSegment.sprite.offset.y = wiggle2;
		lastSegment.sprite.offset.y = wiggle3;
	}

	function updateMouthAndPincers():Void
	{
		// Position at bottom of head - mouth is 6x9, pincers are 22x13
		// Just copy the head's offset so they move together!
		var headSpr = headSegment.sprite;
		mouth.x = headSpr.x + headSpr.width / 2 - mouth.width / 2;
		mouth.y = headSpr.y + headSpr.height - mouth.height;
		mouth.offset.y = headSpr.offset.y;
		pincers.x = headSpr.x + headSpr.width / 2 - pincers.width / 2;
		pincers.y = mouth.y + 1;
		pincers.offset.y = headSpr.offset.y;
	}

	function setMouthOpen(open:Bool):Void
	{
		if (mouthOpen == open)
			return;
		mouthOpen = open;
		mouth.animation.play(open ? "open" : "closed");
	}

	function setPincersOpen(open:Bool):Void
	{
		if (pincersOpen == open)
			return;
		pincersOpen = open;
		pincers.animation.play(open ? "open" : "closed");
	}

	public function fadeIn(progress:Float):Void
	{
		setMouthOpen(false);
		setPincersOpen(false);
		forEach(function(spr:FlxSprite)
		{
			spr.alpha = progress;
		});
	}

	public function unfurl(progress:Float):Void
	{
		squishFactor = progress;
		// Last segment stays at original spawn position (baseY)
		// All other segments move DOWN from there
		var lastY = baseY;

		headY = lastY + (53 * progress); // Head moves down 53px total

		// Move segments - lastSegment stays put, others move progressively down
		lastSegment.setCenter(headX, lastY);
		backSegment.setCenter(headX, lastY + (15 * progress)); // 15px down from last
		foreSegment.setCenter(headX, lastY + (33 * progress)); // 33px down from last (15+18)
		headSegment.setCenter(headX, lastY + (53 * progress)); // 53px down from last (15+18+20)
		
		if (progress >= 1.0)
		{
			baseY = headY;
		}

		updateMouthAndPincers();
	}

	public function getHeadPosition():FlxPoint
	{
		return headSegment.getCenter();
	}

	public function getMouthPosition():FlxPoint
	{
		// Mouth sprite is positioned relative to head
		if (mouth != null)
		{
			return FlxPoint.get(mouth.x + mouth.width / 2, mouth.y + mouth.height / 2);
		}
		// Fallback to head center
		return headSegment.getCenter();
	}

	public function moveTo(x:Float, y:Float, speed:Float, elapsed:Float):Void
	{
		wiggleTime += elapsed * wiggleFrequency;

		// Delegate to BossLogic for movement calculation
		var pos = logic.moveTowards(headX, headY, x, y, speed, elapsed);
		headX = pos.newX;
		headY = pos.newY;

		updateSegments();
		updateMouthAndPincers();
	}

	public function isAtPosition(x:Float, y:Float):Bool
	{
		var dx = x - headX;
		var dy = y - headY;
		return (dx * dx + dy * dy) < 100;
	}
	public function createShadows(shadowLayer:ShadowLayer):Void
	{
		// Create shadows for each segment
		// Width: 1.2x, Height: 1.0x, Anchor: center.x, center.y + 4

		var lastShadow = new Shadow(lastSegment.sprite, 1.05, 1.0, 0, 4);
		shadowLayer.add(lastShadow);
		shadows.push(lastShadow);

		var backShadow = new Shadow(backSegment.sprite, 1.1, 1.0, 0, 4);
		shadowLayer.add(backShadow);
		shadows.push(backShadow);

		var foreShadow = new Shadow(foreSegment.sprite, 1.1, 1.0, 0, 4);
		shadowLayer.add(foreShadow);
		shadows.push(foreShadow);

		var headShadow = new Shadow(headSegment.sprite, 0.8, 0.8, 0, 4);
		shadowLayer.add(headShadow);
		shadows.push(headShadow);
		// No shadows for mouth or pincers
	}

	public function setReady():Void
	{
		isReady = true;
		targetX = headX;
		targetY = headY;
		modeTimer = 0;
	}

	public function roar():Void
	{
		setMouthOpen(true);
		setPincersOpen(true);
		hasRoared = true;
	}

	public function closeRoar():Void
	{
		setMouthOpen(false);
		setPincersOpen(false);
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (!isReady)
		{
			return;
		}
		// Update boss logic (damage cooldowns)
		logic.update();
		
		// Apply burn damage
		if (isBurning)
		{
			burnTimer -= elapsed;
			takeDamage(burnDamagePerSecond * elapsed);

			if (burnTimer <= 0)
			{
				isBurning = false;
			}
		}

		modeTimer += elapsed;

		switch (mode)
		{
			case IDLE:
				updateIdle(elapsed);
				updateSegments();
				updateMouthAndPincers();
			case SLAM_ATTACK:
				updateSlamAttack(elapsed);
			case SPIT_ATTACK:
				updateSpitAttack(elapsed);
				updateSegments();
				updateMouthAndPincers();
			case PLASMA_ATTACK:
				updatePlasmaAttack(elapsed);
				updateSegments();
				updateMouthAndPincers();
		}
	}

	function updateIdle(elapsed:Float):Void
	{
		wiggleTime += elapsed * 3;
		lastAttackTime += elapsed; // Track time for cooldown
		
		// Mouth stays closed in idle
		setMouthOpen(false);

		// Pincers only wiggle after the initial roar
		if (hasRoared)
		{
			pincerWiggleTimer += elapsed;
			if (pincerWiggleTimer > FlxG.random.float(2.0, 4.0)) // Less frequent
			{
				setPincersOpen(!pincersOpen);
				pincerWiggleTimer = 0;
			}
		}
		else
		{
			setPincersOpen(false);
		}

		var dx = targetX - headX;
		var dy = targetY - headY;
		var distSq = dx * dx + dy * dy;

		if (distSq < 25)
		{
			pickNewWanderTarget();
		}
		else
		{
			var angle = Math.atan2(dy, dx);
			headX += Math.cos(angle) * moveSpeed * elapsed;
			headY += Math.sin(angle) * moveSpeed * elapsed;
		}

		// Only attack if cooldown has passed and plasma isn't active
		if (modeTimer > 5.0 && lastAttackTime >= attackCooldown && activePlasma == null)
		{
			modeTimer = 0;
			lastAttackTime = 0; // Reset cooldown
			var rand = FlxG.random.int(0, 2);
			if (rand == 0)
			{
				startSlamAttack();
			}
			else if (rand == 1)
			{
				startSpitAttack();
			}
			else
			{
				startPlasmaAttack();
			}
		}
	}

	function updateSlamAttack(elapsed:Float):Void
	{
		// Position segments at base location with NEW spacing
		headSegment.setCenter(headX, headY);
		foreSegment.setCenter(headX, headY - 20);
		backSegment.setCenter(headX, headY - 38);
		lastSegment.setCenter(headX, headY - 53);

		// Clear wiggle
		foreSegment.sprite.offset.y = 0;
		backSegment.sprite.offset.y = 0;
		lastSegment.sprite.offset.y = 0;
		
		if (modeTimer < 1.2)
		{
			// Raise up - segments rise in sequence to form S-shape
			// Each segment's center should align with the top of the segment below it
			setMouthOpen(true);
			setPincersOpen(true);

			var raiseProgress = modeTimer / 1.2;

			// Calculate target offsets for S-shape - MULTIPLY by 2 for more dramatic raise
			// lastSegment stays at y=0 (on ground)
			// backSegment center should be at lastSegment's top
			var backTarget = lastSegment.sprite.height / 2 * 2; // center of back at top of last
			// foreSegment center should be at backSegment's top
			var foreTarget = backTarget + backSegment.sprite.height / 2 * 2;
			// headSegment center should be at foreSegment's top
			var headTarget = foreTarget + foreSegment.sprite.height / 2 * 2;
			
			// Apply progressive animation
			headSegment.sprite.offset.y = headTarget * raiseProgress;
			
			// Fore starts rising when head has risen enough
			var foreThreshold = 0.33;
			if (raiseProgress > foreThreshold)
			{
				var foreProgress = (raiseProgress - foreThreshold) / (1 - foreThreshold);
				foreSegment.sprite.offset.y = foreTarget * foreProgress;
			}
			
			// Back starts rising after fore
			var backThreshold = 0.66;
			if (raiseProgress > backThreshold)
			{
				var backProgress = (raiseProgress - backThreshold) / (1 - backThreshold);
				backSegment.sprite.offset.y = backTarget * backProgress;
			}

			updateMouthAndPincers();
		}
		else if (modeTimer < 1.3)
		{
			// Slam down fast - all together
			setMouthOpen(true);
			setPincersOpen(true);

			var slamProgress = (modeTimer - 1.2) / 0.1;

			// Calculate same targets with 2x multiplier
			var backTarget = lastSegment.sprite.height / 2 * 2;
			var foreTarget = backTarget + backSegment.sprite.height / 2 * 2;
			var headTarget = foreTarget + foreSegment.sprite.height / 2 * 2;
			
			headSegment.sprite.offset.y = headTarget * (1 - slamProgress);
			foreSegment.sprite.offset.y = foreTarget * (1 - slamProgress);
			backSegment.sprite.offset.y = backTarget * (1 - slamProgress);

			updateMouthAndPincers();
		}
		else if (modeTimer < 1.35)
		{
			// Impact
			setMouthOpen(true);
			setPincersOpen(true);

			headSegment.sprite.offset.y = 0;
			foreSegment.sprite.offset.y = 0;
			backSegment.sprite.offset.y = 0;
			lastSegment.sprite.offset.y = 0;

			updateMouthAndPincers();

			if (attackCallback != null)
			{
				attackCallback();
				attackCallback = null;
			}
		}
		else if (modeTimer > 1.9)
		{
			// Done
			setMouthOpen(false);
			setPincersOpen(false);

			headSegment.sprite.offset.y = 0;
			foreSegment.sprite.offset.y = 0;
			backSegment.sprite.offset.y = 0;
			lastSegment.sprite.offset.y = 0;

			mode = IDLE;
			modeTimer = 0;
			pickNewWanderTarget();
		}
		else
		{
			// Recovery
			setMouthOpen(false);
			setPincersOpen(false);

			headSegment.sprite.offset.y = 0;
			foreSegment.sprite.offset.y = 0;
			backSegment.sprite.offset.y = 0;
			lastSegment.sprite.offset.y = 0;

			updateMouthAndPincers();
		}
	}

	function updateSpitAttack(elapsed:Float):Void
	{
		if (modeTimer < 0.3)
		{
			setMouthOpen(true);
			setPincersOpen(true);
		}
		else if (modeTimer < 0.8)
		{
			setMouthOpen(true);
			setPincersOpen(true);
			if (Std.int(modeTimer * 10) % 2 == 0 && spitProjectiles != null)
			{
				spitProjectile();
			}
		}
		else if (modeTimer < 1.1)
		{
			setMouthOpen(false);
			setPincersOpen(false);
		}
		else
		{
			setMouthOpen(false);
			setPincersOpen(false);
			mode = IDLE;
			modeTimer = 0;
		}
	}

	function spitProjectile():Void
	{
		var proj:Projectile = spitProjectiles.getFirstAvailable(Projectile);
		if (proj == null)
		{
			proj = new Projectile();
			spitProjectiles.add(proj);
		}

		var spawnX = mouth.x + mouth.origin.x;
		var spawnY = mouth.y + mouth.origin.y + mouth.height / 2;
		proj.reset(spawnX, spawnY);
		proj.damage = contactDamage;
		proj.loadGraphic("assets/images/spit.png");

		var targetX:Float = spawnX + 1;
		var targetY:Float = spawnY;
		if (Std.isOfType(FlxG.state, PlayState))
		{
			var ps:PlayState = cast FlxG.state;
			if (ps.player != null)
			{
				targetX = ps.player.x + ps.player.width / 2;
				targetY = ps.player.y + ps.player.height / 2;
			}
		}

		var angle = Math.atan2(targetY - spawnY, targetX - spawnX);
		var speed = 160;
		proj.velocity.x = Math.cos(angle) * speed;
		proj.velocity.y = Math.sin(angle) * speed;
		proj.acceleration.set(0, 0);
	}

	function startSlamAttack():Void
	{
		mode = SLAM_ATTACK;
		modeTimer = 0;
		attackCallback = function()
		{
			FlxG.camera.shake(0.015, 0.3);
			createShockwave();
		};
	}

	function createShockwave():Void
	{
		if (spitProjectiles == null)
			return;

		var numProjectiles = 80;
		var shockwaveSpeed = 120;
		var center = headSegment.getCenter();

		for (i in 0...numProjectiles)
		{
			var angle = (i / numProjectiles) * Math.PI * 2;
			var proj:Projectile = spitProjectiles.getFirstAvailable(Projectile);
			if (proj == null)
			{
				proj = new Projectile();
				spitProjectiles.add(proj);
			}
			proj.reset(center.x, center.y);
			proj.damage = contactDamage * 0.5;
			proj.loadGraphic("assets/images/shockwave.png");
			proj.velocity.x = Math.cos(angle) * shockwaveSpeed;
			proj.velocity.y = Math.sin(angle) * shockwaveSpeed;
			proj.acceleration.set(0, 0);
		}
		center.put();
	}

	function startSpitAttack():Void
	{
		mode = SPIT_ATTACK;
		modeTimer = 0;
	}

	function startPlasmaAttack():Void
	{
		mode = PLASMA_ATTACK;
		modeTimer = 0;
		// Open mouth and pincers at start
		setMouthOpen(true);
		setPincersOpen(true);
	}

	function updatePlasmaAttack(elapsed:Float):Void
	{
		// Phase 1: Stop and open mouth/pincers (0-0.8s)
		if (modeTimer < 0.8)
		{
			// Boss stops moving
			setMouthOpen(true);
			setPincersOpen(true);
			return;
		}
		// Phase 2: Charge plasma in mouth (0.8-2.0s)
		else if (modeTimer < 2.0)
		{
			// Keep mouth and pincers open during charge
			setMouthOpen(true);
			setPincersOpen(true);

			// Spawn charging plasma if not exists
			if (activePlasma == null && plasmas != null)
			{
				// Get mouth position
				var mouthPos = getMouthPosition();
				activePlasma = plasmas.recycle(Plasma);
				activePlasma.startCharging(mouthPos.x, mouthPos.y);
				mouthPos.put();
			}
			// Update plasma position to follow mouth
			if (activePlasma != null && activePlasma.isCharging)
			{
				var mouthPos = getMouthPosition();
				activePlasma.setPosition(mouthPos.x - activePlasma.width / 2, mouthPos.y - activePlasma.height / 2);
				mouthPos.put();
			}
			return;
		}
		// Phase 3: Head jerk up (2.0-2.15s)
		else if (modeTimer < 2.15)
		{
			// Keep mouth and pincers open during windup
			setMouthOpen(true);
			setPincersOpen(true);

			// Quick head bob up (positive offset moves visual up)
			headSegment.sprite.offset.y = 8;
			return;
		}
		// Phase 4: Fire plasma (2.15-2.3s)
		else if (modeTimer < 2.3)
		{
			// Keep mouth and pincers open during fire
			setMouthOpen(true);
			setPincersOpen(true);

			// Head snaps down (negative offset moves visual down)
			headSegment.sprite.offset.y = -4;

			// Fire plasma at 2.15s exactly
			if (modeTimer >= 2.15 && activePlasma != null && activePlasma.isCharging)
			{
				activePlasma.launch(player);
				activePlasma.onExplode = function(p:Plasma)
				{
					// When plasma explodes, clear reference
					activePlasma = null;
				};
			}
			return;
		}
		// Phase 5: Close mouth and return to idle (2.3s+)
		else
		{
			// Reset head offset
			headSegment.sprite.offset.y = 0;
			setMouthOpen(false);
			setPincersOpen(false);
			mode = IDLE;
			modeTimer = 0;
			pickNewWanderTarget();
		}
	}

	function pickNewWanderTarget():Void
	{
		var arenaCenterX = FlxG.worldBounds.width / 2;
		var arenaCenterY = FlxG.worldBounds.height / 2;
		targetX = arenaCenterX + FlxG.random.float(-40, 40);
		targetY = arenaCenterY + FlxG.random.float(-30, 30);
	}

	public function takeDamage(damage:Float, ?damageInstanceId:String):Void
	{
		// Delegate to BossLogic - handles cooldown check and damage application
		if (!logic.takeDamage(damage, damageInstanceId))
		{
			return; // Still on cooldown for this specific instance
		}
		
		// Sync health from logic to interface properties
		currentHealth = logic.currentHealth;
		
		// Notify health bar
		PlayState.current.hud.bossHealthBar.showDamage(damage);

		// Flash effect on all segments using FlxTween
		forEach(function(spr:FlxSprite)
		{
			if (spr != null)
			{
				spr.color = FlxColor.RED;
				FlxTween.color(spr, 0.1, FlxColor.RED, FlxColor.WHITE);
			}
		});

		if (logic.isDead())
			die();
	}
	public function applyBurn(duration:Float, damagePerSecond:Float):Void
	{
		isBurning = true;
		burnTimer = duration;
		burnDamagePerSecond = damagePerSecond;
	}

	public function die():Void
	{
		alive = false;
		// NOTE: Keep exists = true so PlayState can detect death and trigger phase transition
		// PlayState will handle cleanup and phase changes
	}

	public function checkOverlap(sprite:FlxSprite, useRotatedCollision:Bool = false, usePixelPerfect:Bool = false):Bool
	{
		// Iterate through all segments and check collision
		var hasOverlap = false;
		forEachAlive(function(segment:FlxSprite)
		{
			if (hasOverlap)
				return; // Already found a hit

			// First check: AABB or rotated collision
			var basicOverlap = false;
			if (useRotatedCollision && Std.isOfType(sprite, RotatedSprite))
			{
				// Use RotatedSprite's overlaps method for rotated collision
				basicOverlap = cast(sprite, RotatedSprite).overlaps(segment);
			}
			else
			{
				// Standard AABB check
				basicOverlap = sprite.overlaps(segment);
			}

			// Second check: pixel-perfect if requested
			if (basicOverlap)
			{
				if (usePixelPerfect)
				{
					hasOverlap = FlxG.pixelPerfectOverlap(sprite, segment);
				}
				else
				{
					hasOverlap = true;
				}
			}
		});

		return hasOverlap;
	}

	function get_x():Float
	{
		return headX;
	}

	function get_y():Float
	{
		return headY;
	}

	override function destroy():Void
	{
		headSegment.destroy();
		foreSegment.destroy();
		backSegment.destroy();
		lastSegment.destroy();
		super.destroy();
	}
}

enum BossMode
{
	IDLE;
	SLAM_ATTACK;
	SPIT_ATTACK;
	PLASMA_ATTACK;
}
