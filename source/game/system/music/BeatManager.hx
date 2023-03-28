package game.system.music;

import game.system.music.Conductor.ChangeBPMEvent;

/**
 * Manages Updates for song variables, Beats, Steps, and Sections
 */
class BeatManager implements IMusicSync
{
	public var step:Int = 0;
	public var beat:Int = 0;
	public var sec:Int = 0;

	public function new():Void {}

	public function update(elapsed:Float):Void
	{
		updateStepPosition();
		updateSectionPosition();
		updateBeatPosition();

		FlxG.watch.add(Conductor, "songPosition");
		FlxG.watch.add(this, "beat");
		FlxG.watch.add(this, "step");
		FlxG.watch.add(this, "sec");
	}

	var stepTemp:Int = -1;

	public function updateStepPosition():Void
	{
		var registeredEvent:ChangeBPMEvent = {
			step: 0,
			time: 0,
			bpm: 0
		};

		for (event in 0...Conductor.bpmChanges.length)
			if (Conductor.songPosition >= Conductor.bpmChanges[event].time)
				registeredEvent = Conductor.bpmChanges[event];

		step = registeredEvent.step + Math.floor((Conductor.songPosition - registeredEvent.time) / Conductor.stepCrochet);

		if (step > stepTemp)
		{
			stepTemp = step;
			onStep();
		}
	}

	public function updateBeatPosition():Void
	{
		beat = Math.floor(step / 4);
	}

	public function updateSectionPosition():Void
	{
		sec = Math.floor(beat / 4);
	}

	public function onBeat():Void
	{
		if (beat % 4 == 0)
			onSec();
	}

	public function onStep():Void
	{
		if (step % 4 == 0)
			onBeat();
	}

	public function onSec():Void
	{
		// receive sections here
	}
}
