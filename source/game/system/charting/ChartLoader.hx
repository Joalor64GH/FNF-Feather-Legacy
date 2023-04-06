package game.system.charting;

import flixel.system.FlxSound;
import flixel.util.FlxSort;
import game.gameplay.Note;
import game.system.charting.ChartDefs;
import game.system.charting.ChartEvents;
import game.system.Conductor;
import openfl.media.Sound;

/**
 * Class for parsing and loading song charts
 */
class ChartLoader {
	public static var rawNoteList:Array<ChartNote> = [];
	public static var unspawnNoteList:Array<Note> = [];
	public static var unspawnEventList:Array<EventLine> = [];

	public static function loadSong(songName:String, difficulty:String = ''):ChartFormat {
		var loadedData:ChartFormat = loadChart(songName, difficulty);
		if (loadedData != null)
			fillRawList(loadedData);

		if (loadedData.metadata != null)
			Conductor.changeBPM(loadedData.metadata.bpm);
		if (loadedData.sections != null)
			Conductor.getBPMChanges(loadedData);

		return loadedData;
	}

	public static function loadChart(songName:String, difficulty:String = 'normal'):ChartFormat {
		var tempSong:ChartFormat = null;
		var parsedType:String = 'Feather';

		songName = songName.toLowerCase();

		difficulty = '-${difficulty}';
		if (!sys.FileSystem.exists(AssetHandler.getPath('data/songs/${songName}/${songName}${difficulty}', JSON)))
			difficulty = '';

		var jsonPath:String = AssetHandler.getAsset('data/songs/${songName}/${songName}${difficulty}', JSON);
		var fnfSong:FNFSong = cast tjson.TJSON.parse(jsonPath).song;

		if (fnfSong != null && fnfSong.notes != null) {
			parsedType = 'FNF LEGACY/HYBRID';

			tempSong =
				{
					name: fnfSong.song,
					metadata:
						{
							player: fnfSong.player1,
							opponent: fnfSong.player2,
							crowd: fnfSong.gfVersion,
							stage: fnfSong.stage,
							speed: fnfSong.speed,
							bpm: fnfSong.bpm
						},
					sections: [],
					generatedFrom: parsedType,
				};

			for (i in 0...fnfSong.notes.length) {
				var convertedBeats:Float = fnfSong.notes[i].sectionBeats;
				tempSong.sections.push({
					notes: [],
					camPoint: fnfSong.notes[i].mustHitSection ? 1 : fnfSong.notes[i].gfSection ? 2 : 0,
					length: fnfSong.notes[i].lengthInSteps
				});

				// notes
				for (note in fnfSong.notes[i].sectionNotes) {
					var stepTime:Float = note[0];
					var noteIndex:Int = Std.int(note[1] % 4);
					var noteType:String = "default";
					var noteSustain:Float = note[2];

					var shouldHit:Bool = fnfSong.notes[i].mustHitSection;

					if (note[3] != null && Std.isOfType(note[3], String)) {
						noteType = switch (note[3]) {
							case "Hurt Note": "mine";
							default: "default";
						}
					}

					if (note[1] > 3)
						shouldHit = !fnfSong.notes[i].mustHitSection;

					var chartNote:ChartNote = {step: stepTime, index: noteIndex, sustainTime: noteSustain};

					if (shouldHit)
						chartNote.strumline = 1;
					if (noteType != 'default')
						chartNote.type = noteType;

					tempSong.sections[i].notes.push(chartNote);
				}

				// change bpm events
				/*
					if (fnfSong.notes[i].changeBPM)
					{
						tempSong.sections[i].bpm = fnfSong.notes[i].bpm;
					}
				 */

				// psych engine events
				if (fnfSong.events != null) {
					for (event in fnfSong.events) {}
				}
			}
		} else // parse as feather format
			tempSong = cast tjson.TJSON.parse(jsonPath);

		if (tempSong.metadata.stage == null)
			tempSong.metadata.stage = getStageVersion(tempSong.name);
		if (tempSong.metadata.crowd == null)
			tempSong.metadata.crowd = getCrowdVersion(tempSong.metadata.stage);

		return tempSong;
	}

	public static function fillRawList(chart:ChartFormat):Void {
		rawNoteList = [];

		for (i in 0...chart.sections.length)
			for (j in 0...chart.sections[i].notes.length)
				rawNoteList.push(chart.sections[i].notes[j]);
	}

	public static function fillUnspawnList():Void {
		unspawnNoteList = [];
		for (i in 0...rawNoteList.length) {
			var note = rawNoteList[i];
			if (note.strumline == null || note.strumline < 0)
				note.strumline = 0;

			var type:String = 'default';
			if (note.type != null)
				type = note.type;

			var spawnedNote:Note = new Note(note.step, note.index, 0, type);
			spawnedNote.downscroll = Settings.get("scrollType") == "DOWN";
			spawnedNote.sustainTime = note.sustainTime;
			spawnedNote.strumline = note.strumline;
			unspawnNoteList.push(spawnedNote);

			if (note.sustainTime > 0) {
				var prevNote:Note = unspawnNoteList[unspawnNoteList.length - 1];

				for (noteSustain in 0...Math.floor(note.sustainTime / Conductor.stepCrochet)) {
					var sustainStep:Float = note.step + (Conductor.stepCrochet * Math.floor(noteSustain)) + Conductor.stepCrochet;
					var spawnedSustain:Note = new Note(sustainStep, note.index, note.sustainTime, type, prevNote);
					spawnedSustain.downscroll = Settings.get("scrollType") == "DOWN";
					spawnedSustain.strumline = note.strumline;
					if (note.sustainTime == noteSustain - 1)
						spawnedSustain.isEnd = true;
					unspawnNoteList.insert(0, spawnedSustain);
					prevNote = spawnedSustain;
				}
			}
		}
		unspawnNoteList.sort(function(a:Note, b:Note) return FlxSort.byValues(FlxSort.ASCENDING, a.step, b.step));
		trace('Song Total Notes: ${unspawnNoteList.length}');
	}

	public static function getStageVersion(song:String):String {
		// yikes, retrocompatibility
		return switch (song.toLowerCase()) {
			case 'ugh', 'guns', 'stress': 'military-zone';
			case 'thorns': 'school-glitch';
			case 'senpai', 'roses': 'school';
			case 'winter-horrorland': 'red-mall';
			case 'cocoa', 'eggnog': 'mall';
			case 'satin-panties', 'high', 'milf': 'highway';
			case 'pico', 'philly', 'blammed': 'philly-city';
			case 'spookeez', 'south', 'mounster': 'haunted-house';
			default: 'stage';
		}
	}

	public static function getCrowdVersion(stage:String):String {
		return switch (stage.toLowerCase()) {
			case 'tank', 'military-zone': 'gf-tankmen';
			case 'school', 'schoolEvil', 'school-glitch': 'gf-pixel';
			case 'mall', 'mallEvil', 'red-mall': 'gf-christmas';
			case 'highway', 'limo': 'gf-car';
			default: 'gf';
		}
	}
}

/**
 * Class with helpers to manage Music Playback
 */
class MusicPlayback {
	public var inst:FlxSound;
	public var vocals:FlxSound;

	public var songName:String;

	public function new(songName:String, diff:String):Void {
		songName = songName.toLowerCase();
		this.songName = songName;

		inst = new FlxSound().loadEmbedded(getSoundFile("Inst"));
		FlxG.sound.list.add(inst);

		if (sys.FileSystem.exists(AssetHandler.getPath('data/songs/${songName}/Voices', SOUND))) {
			vocals = new FlxSound().loadEmbedded(getSoundFile('Voices'));
			FlxG.sound.list.add(vocals);
		}
	}

	private function getSoundFile(name:String):Sound
		return AssetHandler.getAsset('data/songs/${songName}/${name}', SOUND);

	public function play(?completeFunc:Void->Void):Void {
		inst.play();
		if (completeFunc != null)
			inst.onComplete = completeFunc;

		if (vocals != null)
			vocals.play();
	}

	public function pause():Void {
		inst.pause();
		if (vocals != null)
			vocals.pause();
	}

	public function cease():Void {
		var toKill:Array<FlxSound> = [inst];
		if (vocals != null)
			toKill.push(vocals);
		Utils.killMusic(toKill);
	}

	public function resyncVocals():Void {
		if (vocals != null)
			vocals.pause();
		inst.play();

		Conductor.songPosition = inst.time;
		if (vocals != null) {
			vocals.time = Conductor.songPosition;
			vocals.play();
		}
	}

	public function resyncFunction():Void {
		if (Math.abs(inst.time - (Conductor.songPosition)) > 20
			|| (vocals != null && Math.abs(vocals.time - (Conductor.songPosition)) > 20)) {
			resyncVocals();
		}
	}
}
