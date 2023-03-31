package game.system.music;

import game.system.music.Conductor.ChangeBPMEvent;

interface IMusicFunctions {
	public function beatHit():Void;
	public function stepHit():Void;
	public function secHit():Void;
}

/**
 * Manages Updates for song variables, Beats, Steps, and Sections
 */
class BeatManager {
	public var boundContainer:IMusicFunctions;

	public var step:Int = 0;
	public var beat:Int = 0;
	public var sec:Int = 0;

	public function new(newContainer:IMusicFunctions):Void
		boundContainer = newContainer;

	public function update(elapsed:Float):Void {
		updateStepPosition();
		updateSectionPosition();
		updateBeatPosition();
	}

	var stepTemp:Int = -1;

	public function updateStepPosition():Void {
		var registeredEvent:ChangeBPMEvent =
			{
				step: 0,
				time: 0,
				bpm: 0
			};

		for (event in 0...Conductor.bpmChanges.length)
			if (Conductor.songPosition >= Conductor.bpmChanges[event].time)
				registeredEvent = Conductor.bpmChanges[event];

		step = registeredEvent.step + Math.floor((Conductor.songPosition - registeredEvent.time) / Conductor.stepCrochet);

		if (stepTemp != step) {
			if (step > stepTemp)
				stepTemp = step;
			boundContainer.stepHit();
		}

		if (step % 4 == 0)
			boundContainer.beatHit();
		if (step % 16 == 0)
			boundContainer.secHit();
	}

	public function updateBeatPosition():Void
		beat = Math.floor(step / 4);

	public function updateSectionPosition():Void
		sec = Math.floor(step / 16);
}
