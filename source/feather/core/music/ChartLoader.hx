package feather.core.music;

import feather.core.music.Conductor;
import feather.gameObjs.Note;
import feather.state.PlayState.GameplayEvent;
import flixel.system.FlxSound;
import flixel.util.FlxSort;
import openfl.media.Sound;

typedef ChartFormat = {
	var speed:Float;
	var sections:Array<ChartSection>;
}

typedef ChartMeta = {
	var name:String;
	var characters:Array<String>;
	var origin:String;
	var uiStyle:String;
	var ?stage:String; // defaults to "stage"
	var bpm:Float;
}

typedef ChartNote = {
	var step:Float;
	var index:Int;
	var ?strumline:Int; // defaults to 0 (enemy)
	var ?sustainTime:Float;
	var ?type:String;
}

typedef ChartSection = {
	var camPoint:Int;
	var notes:Array<ChartNote>;
	var ?animation:String; // e.g: "singLEFT-alt"
	var ?length:Int; // in steps
	var ?bpm:Float;
}

typedef FNFSong = {
	var song:String;
	var notes:Array<FNFSection>;
	var events:Array<Dynamic>;
	var bpm:Float;
	var speed:Float;

	var player1:String;
	var player2:String;
	var gfVersion:String;
	var stage:String;
}

typedef FNFSection = {
	var sectionNotes:Array<Dynamic>;
	var sectionBeats:Float;
	var lengthInSteps:Int;
	var mustHitSection:Bool;
	var gfSection:Bool;
	var bpm:Float;
	var changeBPM:Bool;
	var altAnim:Bool;
}

/**
 * Class for parsing and loading song charts
 */
class ChartLoader {
	public static var songMetadata:ChartMeta;
	public static var rawNoteList:Array<ChartNote> = [];
	public static var unspawnNoteList:Array<Note> = [];

	public static function loadSong(songName:String, difficulty:String = ''):ChartFormat {
		var loadedData:ChartFormat = loadChart(songName, difficulty);
		if (loadedData != null)
			fillRawList(loadedData);

		if (songMetadata != null)
			Conductor.changeBPM(songMetadata.bpm);
		if (loadedData.sections != null)
			Conductor.getBPMChanges(loadedData);

		return loadedData;
	}

	public static function loadChart(songName:String, difficulty:String = 'normal'):ChartFormat {
		var tempSong:ChartFormat = null;
		var tempMeta:ChartMeta = null;
		var parsedType:String = 'FEATHER';
		songName = songName.toLowerCase();

		difficulty = '-${difficulty}';
		if (!sys.FileSystem.exists(AssetHandler.getPath('data/songs/${songName}/${songName}${difficulty}', JSON)))
			difficulty = '';

		var fnfSong:FNFSong = cast tjson.TJSON.parse(AssetHandler.getAsset('data/songs/${songName}/${songName}${difficulty}', JSON)).song;

		if (fnfSong != null && fnfSong.notes != null) {
			parsedType = 'FNF LEGACY/HYBRID';

			if (getSongMetadata(songName, difficulty) != null)
				tempMeta = getSongMetadata(songName, difficulty);
			else {
				tempMeta =
					{
						name: fnfSong.song,
						characters: [
							fnfSong.player1,
							fnfSong.player2,
							(fnfSong.gfVersion != null)
							? fnfSong.gfVersion : getCrowdVersion(fnfSong.stage)
						],
						uiStyle: 'default',
						origin: parsedType,
						stage: fnfSong.stage,
						bpm: fnfSong.bpm
					};
			}
			tempSong = {sections: [], speed: fnfSong.speed};

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
		} else {
			// feather format
			tempSong = cast tjson.TJSON.parse(AssetHandler.getAsset('data/songs/${songName}/${songName}${difficulty}', JSON));
			tempMeta = getSongMetadata(songName, difficulty);
		}

		if (tempMeta != null) {
			if (tempMeta.stage == null)
				tempMeta.stage = getStageVersion(tempMeta.name);
			if (tempMeta.characters[3] == null)
				tempMeta.characters[3] = getCrowdVersion(tempMeta.stage);

			songMetadata = tempMeta;
		} else {
			songMetadata =
				{
					name: songName,
					origin: "ENGINE FALLBACK HANDLER",
					stage: "stage",
					uiStyle: "default",
					characters: ["face", "face", "face"],
					bpm: 100
				};
		}

		return tempSong;
	}

	public static function getSongMetadata(songName:String, difficulty:String):ChartMeta {
		if (!sys.FileSystem.exists(AssetHandler.getPath('data/songs/${songName}/meta${difficulty}', JSON)))
			difficulty = '';

		if (sys.FileSystem.exists(AssetHandler.getPath('data/songs/${songName}/meta${difficulty}', JSON)))
			return cast tjson.TJSON.parse(AssetHandler.getAsset('data/songs/${songName}/meta${difficulty}', JSON));

		return null;
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
			spawnedNote.downscroll = UserSettings.get("scrollType") == "DOWN";
			spawnedNote.strumline = note.strumline;
			unspawnNoteList.push(spawnedNote);

			if (note.sustainTime > 0) {
				var prevNote:Note = unspawnNoteList[unspawnNoteList.length - 1];

				for (noteSustain in 0...Math.floor(note.sustainTime / Conductor.stepCrochet)) {
					var sustainStep:Float = note.step + (Conductor.stepCrochet * Math.floor(noteSustain)) + Conductor.stepCrochet;
					var spawnedSustain:Note = new Note(sustainStep, note.index, note.sustainTime, type, prevNote);
					spawnedSustain.downscroll = UserSettings.get("scrollType") == "DOWN";
					spawnedSustain.strumline = note.strumline;
					if (note.sustainTime == noteSustain - 1)
						spawnedSustain.isEnd = true;
					unspawnNoteList.insert(0, spawnedSustain);
					prevNote = spawnedSustain;
				}
			}
		}
		unspawnNoteList.sort(function(a:Note, b:Note) return FlxSort.byValues(FlxSort.ASCENDING, a.stepTime, b.stepTime));
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
		if (Math.abs(inst.time - (Conductor.songPosition)) >= 5
			|| (vocals != null && Math.abs(vocals.time - (Conductor.songPosition)) >= 5)) {
			resyncVocals();
		}
	}
}
