package rhythm.chart;

import flixel.system.FlxSound;
import flixel.util.FlxSort;
import haxe.Json;
import openfl.Assets;
import openfl.media.Sound;
import openfl.net.FileReference;
import rhythm.chart.ChartDefs;
import rhythm.chart.ChartEvents;

using StringTools;

/**
 * Class for parsing and loading song charts
 */
class ChartLoader
{
	static var _file:FileReference;

	public static var noteList:Array<ChartNote> = [];
	public static var eventList:Array<EventLine> = [];

	public static function loadSong(songName:String, difficulty:String = ''):ChartFormat
	{
		noteList = [];
		eventList = [];

		var loadedData:ChartFormat = loadChart(songName, difficulty);

		if (loadedData != null)
		{
			for (i in 0...loadedData.sections.length)
				for (j in 0...loadedData.sections[i].notes.length)
					noteList.push(loadedData.sections[i].notes[j]);
		}

		if (loadedData.metadata != null)
			Conductor.changeBPM(loadedData.metadata.bpm);
		if (loadedData.sections != null)
			Conductor.getBPMChanges(loadedData);

		var sorteableLists:Array<Dynamic> = [noteList, eventList];
		for (i in sorteableLists)
			i.sort((a, b) -> FlxSort.byValues(FlxSort.ASCENDING, a.step, b.step));

		return loadedData;
	}

	public static function loadChart(songName:String, difficulty:String = 'normal'):ChartFormat
	{
		var tempSong:ChartFormat = null;
		var parsedType:String = 'Feather';

		songName = songName.toLowerCase();

		difficulty = '-${difficulty}';
		if (!Assets.exists(AssetHandler.getPath('data/songs/chart/${songName}/${songName}${difficulty}', JSON)))
			difficulty = '';

		var jsonPath:String = AssetHandler.getAsset('data/songs/chart/${songName}/${songName}${difficulty}', JSON);
		var fnfSong:FNFSong = cast Json.parse(jsonPath).song;

		if (fnfSong == null)
			tempSong = cast Json.parse(jsonPath);
		else
		{
			parsedType = 'FNF LEGACY/HYBRID';

			// retrocompatibility
			if (fnfSong.stage == null)
			{
				fnfSong.stage = switch (fnfSong.song)
				{
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

			if (fnfSong.gfVersion == null)
			{
				fnfSong.gfVersion = switch (fnfSong.stage)
				{
					case 'tank', 'military-zone': 'gf-tankmen';
					case 'school', 'schoolEvil', 'school-glitch': 'gf-pixel';
					case 'mall', 'mallEvil', 'red-mall': 'gf-christmas';
					case 'highway', 'limo': 'gf-car';
					default: 'gf';
				}
			}

			tempSong = {
				name: fnfSong.song,
				metadata: {
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

			for (i in 0...fnfSong.notes.length)
			{
				var convertedBeats:Float = fnfSong.notes[i].sectionBeats;
				tempSong.sections.push({
					notes: [],
					camPoint: fnfSong.notes[i].mustHitSection ? 1 : fnfSong.notes[i].gfSection ? 2 : 0,
					length: 16
				});

				// notes
				for (note in fnfSong.notes[i].sectionNotes)
				{
					var stepTime:Float = note[0];
					var noteIndex:Int = Std.int(note[1] % 4);
					var noteType:String = "default";
					var noteSustain:Float = note[2];

					var shouldHit:Bool = fnfSong.notes[i].mustHitSection;

					if (note[3] is String && note[3] != null)
					{
						noteType = switch (note[3])
						{
							case "Hurt Note": "mine";
							default: "default";
						}
					}

					if (note[1] > 3)
						shouldHit = !fnfSong.notes[i].mustHitSection;

					var chartNote:ChartNote = {
						step: stepTime,
						index: noteIndex,
						sustainTime: noteSustain
					};

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
				if (fnfSong.events != null)
				{
					for (event in fnfSong.events) {}
				}
			}
		}

		return tempSong;
	}
}

/**
 * Class with helpers to manage Music Playback
 */
class MusicPlayback
{
	public var inst:FlxSound;
	public var vocals:FlxSound;

	public var songName:String;

	public function new(songName:String, diff:String):Void
	{
		songName = songName.toLowerCase();
		this.songName = songName;

		inst = new FlxSound().loadEmbedded(getSoundFile("Inst"));
		FlxG.sound.list.add(inst);

		if (Assets.exists(AssetHandler.getPath('data/songs/audio/${songName}/Voices', SOUND)))
		{
			vocals = new FlxSound().loadEmbedded(getSoundFile('Voices'));
			FlxG.sound.list.add(vocals);
		}
	}

	private function getSoundFile(name:String):Sound
		return AssetHandler.getAsset('data/songs/audio/${songName}/${name}', SOUND);

	public function play(?completeFunc:Void->Void):Void
	{
		inst.play();
		if (completeFunc != null)
			inst.onComplete = completeFunc;

		if (vocals != null)
			vocals.play();
	}

	public function pause():Void
	{
		inst.pause();
		if (vocals != null)
			vocals.pause();
	}

	public function cease():Void
		Utils.killMusic([inst, vocals]);

	public function resyncVocals():Void
	{
		if (vocals != null)
			vocals.pause();
		inst.play();

		Conductor.songPosition = inst.time;
		if (vocals != null)
		{
			vocals.time = Conductor.songPosition;
			vocals.play();
		}
	}

	public function resyncFunction():Void
	{
		if (Math.abs(inst.time - (Conductor.songPosition)) > 20
			|| (vocals != null && Math.abs(vocals.time - (Conductor.songPosition)) > 20))
		{
			resyncVocals();
		}
	}
}
