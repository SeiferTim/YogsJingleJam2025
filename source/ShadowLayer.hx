package;

import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;
import openfl.display.BitmapData;

/**
 * A custom rendering layer that draws all shadows to a single bitmap at reduced opacity.
 * This prevents overlapping shadows from compounding darkness.
 */
class ShadowLayer extends FlxSprite
{
	public var shadows:FlxTypedGroup<Shadow>;
	private var shadowBitmap:BitmapData;
	private var shadowOpacity:Float = 0.7;

	public function new(Width:Int, Height:Int, ?Opacity:Float = 0.7)
	{
		super(0, 0);
		
		shadowOpacity = Opacity;
		shadows = new FlxTypedGroup<Shadow>();
		
		// Create bitmap to render shadows onto
		shadowBitmap = new BitmapData(Width, Height, true, FlxColor.TRANSPARENT);
		pixels = shadowBitmap;
		
		alpha = shadowOpacity;
		
		// Don't move with camera - we'll handle positioning
		scrollFactor.set(1, 1);
	}

	public function add(shadow:Shadow):Shadow
	{
		return shadows.add(shadow);
	}

	override function draw():Void
	{
		// Clear the bitmap each frame
		shadowBitmap.fillRect(shadowBitmap.rect, FlxColor.TRANSPARENT);
		
		// Draw each shadow onto our bitmap (they'll be at full opacity on the bitmap)
		shadows.forEach(function(shadow:Shadow)
		{
			if (shadow != null && shadow.exists && shadow.visible && shadow.alpha > 0)
			{
				// Draw the shadow's pixels onto our bitmap at its position
				var shadowX = Std.int(shadow.x - x);
				var shadowY = Std.int(shadow.y - y);
				
				shadowBitmap.copyPixels(
					shadow.pixels,
					shadow.pixels.rect,
					new openfl.geom.Point(shadowX, shadowY),
					null,
					null,
					true // Use alpha
				);
			}
		});
		
		// Now draw the entire bitmap at reduced opacity
		super.draw();
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);
		shadows.update(elapsed);
	}

	override function destroy():Void
	{
		if (shadowBitmap != null)
		{
			shadowBitmap.dispose();
			shadowBitmap = null;
		}
		
		if (shadows != null)
		{
			shadows.destroy();
			shadows = null;
		}
		
		super.destroy();
	}
}
