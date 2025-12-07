package;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

/**
 * Manages camera control and cinematics.
 * Handles switching between player-locked camera and cinematic camera movements.
 */
class CinematicManager
{
	var camera:FlxCamera;
	var cameraTarget:FlxObject;
	var player:FlxSprite;

	public var isInCinematic(default, null):Bool = false;

	public function new(Camera:FlxCamera, CameraTarget:FlxObject, Player:FlxSprite)
	{
		camera = Camera;
		cameraTarget = CameraTarget;
		player = Player;
	}

	/**
	 * Start cinematic mode - camera follows cameraTarget, not player
	 */
	public function startCinematic():Void
	{
		isInCinematic = true;
		cameraTarget.setPosition(camera.scroll.x + camera.width / 2, camera.scroll.y + camera.height / 2);
		camera.follow(cameraTarget, LOCKON);
	}

	/**
	 * End cinematic mode - camera follows player
	 */
	public function endCinematic():Void
	{
		isInCinematic = false;
		camera.follow(player, LOCKON);
	}

	/**
	 * Pan camera to a position over time
	 */
	public function panTo(x:Float, y:Float, duration:Float, ?startDelay:Float = 0, ?onComplete:Void->Void):FlxTween
	{
		// Only call startCinematic if we're not already in cinematic mode
		// This preserves the current cameraTarget position
		if (!isInCinematic)
			startCinematic();

		return FlxTween.tween(cameraTarget, {x: x, y: y}, duration, {
			ease: FlxEase.sineInOut,
			startDelay: startDelay,
			onComplete: function(t:FlxTween)
			{
				if (onComplete != null)
					onComplete();
			}
		});
	}

	/**
	 * Pan camera to a sprite's center
	 */
	public function panToSprite(sprite:FlxSprite, duration:Float, ?startDelay:Float = 0, ?onComplete:Void->Void):FlxTween
	{
		return panTo(sprite.x + sprite.width / 2, sprite.y + sprite.height / 2, duration, startDelay, onComplete);
	}

	/**
	 * Follow a moving object with the camera (updates cameraTarget each frame)
	 */
	public function followObject(obj:FlxSprite, onUpdate:Float->Void):Void
	{
		if (!isInCinematic)
			startCinematic();

		// This should be called in update loop
		cameraTarget.setPosition(obj.x + obj.width / 2, obj.y + obj.height / 2);
	}

	/**
	 * Smoothly move camera with a tweened object
	 */
	public function followTween(obj:FlxSprite, targetX:Float, targetY:Float, duration:Float, ?startDelay:Float = 0, ?onComplete:Void->Void):FlxTween
	{
		if (!isInCinematic)
			startCinematic();

		return FlxTween.tween(obj, {x: targetX, y: targetY}, duration, {
			ease: FlxEase.linear,
			startDelay: startDelay,
			onUpdate: function(t:FlxTween)
			{
				cameraTarget.setPosition(obj.x + obj.width / 2, obj.y + obj.height / 2);
			},
			onComplete: function(t:FlxTween)
			{
				if (onComplete != null)
					onComplete();
			}
		});
	}
}
