package feather.core.music;

import feather.core.music.ChartDefs.ChartFormat;

typedef ChangeBPMEvent = {
	var step:Int;
	var time:Float;
	var bpm:Float;
}

interface IMusicFunctions {
	public function onBeat():Void;
	public function onStep():Void;
	public function onSec():Void;
}

class Conductor {
	public static var bpm:Float = 100.0;
	public static var beatCrochet:Float = ((60 / bpm) * 1000); // beats (in MS)
	public static var stepCrochet:Float = beatCrochet / 4; // steps (in MS)

	public static var safeZone:Float = ((10 / 60) * 1000);

	public static var songPosition:Float = 0.0;

	public static var bpmChanges:Array<ChangeBPMEvent> = [];

	public var boundContainer:IMusicFunctions;

	public var stepPos:Int = 0;
	public var beatPos:Int = 0;
	public var secPos:Int = 0;

	public function new(newContainer:IMusicFunctions):Void
		boundContainer = newContainer;

	public function update(elapsed:Float):Void {
		updateStepPosition();
		updateSectionPosition();
		updateBeatPosition();
	}

	public static function getBPMChanges(song:ChartFormat):Void {
		var currentBPM:Float = bpm;
		var currentStep:Int = 0;
		var currentTime:Float = 0.0;

		for (i in 0...song.sections.length) {
			var changeEvent:Bool = false;
			if (bpm != currentBPM) {
				changeEvent = true;

				currentBPM = song.sections[i].bpm;
				var createdEvent:ChangeBPMEvent =
					{
						step: currentStep,
						time: currentTime,
						bpm: currentBPM
					};
				bpmChanges.push(createdEvent);
			}

			var sectionLength:Int = song.sections[i].length;
			currentStep += sectionLength;
			currentTime += ((60 / currentBPM) * 1000 / 4) * sectionLength;
		}

		trace('new bpm changes pushed: ${bpmChanges}');
	}

	public static function changeBPM(newBpm:Float):Void {
		bpm = newBpm;

		beatCrochet = ((60 / bpm) * 1000);
		stepCrochet = beatCrochet / 4;
	}

	var stepTemp:Int = -1;
	var beatTemp:Int = -1;
	var secTemp:Int = -1;

	public function updateStepPosition():Void {
		var registeredEvent:ChangeBPMEvent = {step: 0, time: 0, bpm: 0};
		for (event in 0...Conductor.bpmChanges.length)
			if (Conductor.songPosition >= Conductor.bpmChanges[event].time)
				registeredEvent = Conductor.bpmChanges[event];

		stepPos = registeredEvent.step + Math.floor((Conductor.songPosition - registeredEvent.time) / Conductor.stepCrochet);

		if (stepTemp != stepPos) {
			if (stepPos > stepTemp)
				stepTemp = stepPos;
			boundContainer.onStep();
		}

		if (stepPos % 4 == 0 && beatPos > beatTemp) {
			beatTemp = beatPos;
			boundContainer.onBeat();
		}

		if (beatPos % 4 == 0 && secPos > secTemp) {
			secTemp = secPos;
			boundContainer.onSec();
		}
	}

	public function updateBeatPosition():Void
		beatPos = Math.floor(stepPos / 4);

	public function updateSectionPosition():Void
		secPos = Math.floor(beatPos / 4);
}
