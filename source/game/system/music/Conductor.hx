package game.system.music;

import game.system.charting.ChartDefs.ChartFormat;

typedef ChangeBPMEvent = {
	var step:Int;
	var time:Float;
	var bpm:Float;
}

class Conductor {
	public static var bpm:Float = 100.0;
	public static var beatCrochet:Float = ((60 / bpm) * 1000); // beats (in MS)
	public static var stepCrochet:Float = beatCrochet / 4; // steps (in MS)

	public static var safeZone:Float = ((10 / 60) * 1000);

	public static var songPosition:Float = 0.0;

	public static var bpmChanges:Array<ChangeBPMEvent> = [];

	public static function getBPMChanges(song:ChartFormat):Void {
		var currentBPM:Float = song.metadata.bpm;
		var currentStep:Int = 0;
		var currentTime:Float = 0.0;

		for (i in 0...song.sections.length) {
			var changeEvent:Bool = false;
			if (song.metadata.bpm != currentBPM) {
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
}
