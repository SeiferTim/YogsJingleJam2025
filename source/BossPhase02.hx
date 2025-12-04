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
	// Body parts
	var abdomen:FlxSprite;
	var thorax:FlxSprite;
	var head:FlxSprite;

	var leftForeLeg:FlxSprite;
	var rightForeLeg:FlxSprite;
	var leftBackLeg:FlxSprite;
	var rightBackLeg:FlxSprite;

	var leftArmUpper:FlxSprite;
	var rightArmUpper:FlxSprite;
	var leftArmClaw:FlxSprite;
	var rightArmClaw:FlxSprite;

	var mouth:FlxSprite;
	var pincers:FlxSprite;

	// Shadows for each part
	var shadows:Array<Shadow>;

	// Stats (IBoss interface)
	public var maxHealth:Float = 300;
	public var currentHealth:Float = 300;

	var moveSpeed:Float = 20;
	var isActive:Bool = false;

	// Reference point for all parts (center of thorax)
	var centerX:Float = 0;
	var centerY:Float = 0;

	public function new(X:Float, Y:Float)
	{
		super(X, Y);

		shadows = [];

		// Create an invisible sprite as the main reference point
		makeGraphic(60, 68, FlxColor.TRANSPARENT);
		centerOrigin();

		// Store center point
		centerX = x + width / 2;
		centerY = y + height / 2;

		// Create all body parts based on JSON spriteSourceSize positions
		// These positions are relative to a 60x68 canvas

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
		mouth.visible = false;

		pincers = new FlxSprite();
		pincers.loadGraphic("assets/images/boss-phase-01-larva-pincers.png", true, 26, 13);
		pincers.animation.add("closed", [0], 1, false);
		pincers.animation.add("open", [1], 1, false);
		pincers.animation.play("closed");
		pincers.visible = false;

		// Store offsets for mouth and pincers
		partOffsets = new Map<FlxSprite, FlxPoint>();
		partOffsets.set(mouth, FlxPoint.get(27, 27));
		partOffsets.set(pincers, FlxPoint.get(17, 29));

		updatePartPositions();
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
			// For mouth and pincers which don't have stored offsets
			part.x = originX;
			part.y = originY;
			return;
		}

		// Position using the stored offset
		part.x = originX + offset.x;
		part.y = originY + offset.y;
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

		// Simple idle movement for testing
		// TODO: Add actual AI and attacks

		updatePartPositions();
	}

	override function draw():Void
	{
		// Don't draw the invisible main sprite
		// Draw all parts in correct order (back to front)

		leftBackLeg.draw();
		rightBackLeg.draw();
		abdomen.draw();
		leftForeLeg.draw();
		rightForeLeg.draw();
		thorax.draw();
		leftArmUpper.draw();
		rightArmUpper.draw();
		leftArmClaw.draw();
		rightArmClaw.draw();
		head.draw();

		if (mouth.visible)
			mouth.draw();
		if (pincers.visible)
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

		// Flash effect
		head.color = FlxColor.RED;
		thorax.color = FlxColor.RED;
		// FlxG.sound.play("assets/sounds/hit.wav", 0.5);

		// Reset color after a moment
		haxe.Timer.delay(function()
		{
			head.color = FlxColor.WHITE;
			thorax.color = FlxColor.WHITE;
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
