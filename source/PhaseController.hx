package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

typedef PhaseStep = {
	var duration:Float;
	var ?onStart:Void->Void;
	var ?onUpdate:(Float, Float)->Void; // elapsed, progress (0-1)
	var ?onComplete:Void->Void;
}

class PhaseController extends FlxTypedGroup<FlxObject>
{
	var currentPhase:Int = 0;
	var currentStep:Int = 0;
	var stepTimer:Float = 0;
	var phases:Array<Array<PhaseStep>>;
	var isActive:Bool = false;
	
	public var onPhaseComplete:Int->Void;
	public var onAllPhasesComplete:Void->Void;
	
	public function new()
	{
		super();
		phases = [];
	}
	
	public function addPhase(steps:Array<PhaseStep>):Void
	{
		phases.push(steps);
	}
	
	public function startPhase(phaseIndex:Int):Void
	{
		if (phaseIndex >= phases.length)
			return;
			
		currentPhase = phaseIndex;
		currentStep = 0;
		stepTimer = 0;
		isActive = true;
		
		executeStepStart();
	}
	
	override function update(elapsed:Float):Void
	{
		super.update(elapsed);
		
		if (!isActive || phases.length == 0)
			return;
			
		var phase = phases[currentPhase];
		if (currentStep >= phase.length)
			return;
			
		var step = phase[currentStep];
		stepTimer += elapsed;
		
		var progress = step.duration > 0 ? Math.min(stepTimer / step.duration, 1.0) : 1.0;
		
		if (step.onUpdate != null)
			step.onUpdate(elapsed, progress);
			
		if (stepTimer >= step.duration)
		{
			if (step.onComplete != null)
				step.onComplete();
				
			currentStep++;
			stepTimer = 0;
			
			if (currentStep >= phase.length)
			{
				isActive = false;
				if (onPhaseComplete != null)
					onPhaseComplete(currentPhase);
					
				if (currentPhase >= phases.length - 1)
				{
					if (onAllPhasesComplete != null)
						onAllPhasesComplete();
				}
			}
			else
			{
				executeStepStart();
			}
		}
	}
	
	function executeStepStart():Void
	{
		var phase = phases[currentPhase];
		if (currentStep < phase.length)
		{
			var step = phase[currentStep];
			if (step.onStart != null)
				step.onStart();
		}
	}
	
	public function skipToNextPhase():Void
	{
		if (currentPhase < phases.length - 1)
		{
			startPhase(currentPhase + 1);
		}
	}
}
