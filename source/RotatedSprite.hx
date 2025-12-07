package;

import flixel.FlxSprite;
import flixel.math.FlxPoint;

/**
 * A FlxSprite that properly handles collision detection when rotated.
 * Overrides overlapsPoint to rotate the point into sprite-local space.
 */
class RotatedSprite extends FlxSprite
{
	/**
	 * Override overlapsPoint to handle rotation correctly.
	 * This rotates the test point into the sprite's local space before checking collision.
	 */
	override public function overlapsPoint(point:FlxPoint, inScreenSpace:Bool = false, ?camera:flixel.FlxCamera):Bool
	{
		if (!inScreenSpace)
		{
			// If sprite is rotated, transform the point into sprite's local coordinate system
			if (angle != 0)
			{
				// Get sprite center
				var centerX = x + width / 2;
				var centerY = y + height / 2;

				// Translate point to sprite's origin
				var localX = point.x - centerX;
				var localY = point.y - centerY;

				// Rotate point by negative angle (inverse rotation)
				var angleRad = -angle * Math.PI / 180;
				var cos = Math.cos(angleRad);
				var sin = Math.sin(angleRad);

				var rotatedX = localX * cos - localY * sin;
				var rotatedY = localX * sin + localY * cos;

				// Translate back and check if point is in sprite bounds
				rotatedX += centerX;
				rotatedY += centerY;

				// Check against sprite's axis-aligned bounds
				return (rotatedX >= x && rotatedX <= x + width && rotatedY >= y && rotatedY <= y + height);
			}
		}

		// If not rotated or in screen space, use default behavior
		return super.overlapsPoint(point, inScreenSpace, camera);
	}

	/**
	 * Override overlaps to check both sprites' corners and edge midpoints for better accuracy.
	 * This helps catch cases where edges intersect but corners don't.
	 */
	override public function overlaps(objectOrGroup:flixel.FlxBasic, inScreenSpace:Bool = false, ?camera:flixel.FlxCamera):Bool
	{
		if (Std.isOfType(objectOrGroup, FlxSprite))
		{
			var other:FlxSprite = cast objectOrGroup;

			// If this sprite is rotated, check if any of the other sprite's points are inside
			if (angle != 0)
			{
				// Check corners
				if (overlapsPoint(FlxPoint.get(other.x, other.y), inScreenSpace, camera))
					return true;
				if (overlapsPoint(FlxPoint.get(other.x + other.width, other.y), inScreenSpace, camera))
					return true;
				if (overlapsPoint(FlxPoint.get(other.x, other.y + other.height), inScreenSpace, camera))
					return true;
				if (overlapsPoint(FlxPoint.get(other.x + other.width, other.y + other.height), inScreenSpace, camera))
					return true;

				// Check edge midpoints for better accuracy
				if (overlapsPoint(FlxPoint.get(other.x + other.width / 2, other.y), inScreenSpace, camera))
					return true;
				if (overlapsPoint(FlxPoint.get(other.x + other.width / 2, other.y + other.height), inScreenSpace, camera))
					return true;
				if (overlapsPoint(FlxPoint.get(other.x, other.y + other.height / 2), inScreenSpace, camera))
					return true;
				if (overlapsPoint(FlxPoint.get(other.x + other.width, other.y + other.height / 2), inScreenSpace, camera))
					return true;

				// Also check center point
				if (overlapsPoint(FlxPoint.get(other.x + other.width / 2, other.y + other.height / 2), inScreenSpace, camera))
					return true;

				return false;
			}
		}

		// Fall back to default behavior if not rotated or not a sprite
		return super.overlaps(objectOrGroup, inScreenSpace, camera);
	}
}
