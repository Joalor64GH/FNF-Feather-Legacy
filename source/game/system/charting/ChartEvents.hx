package game.system.charting;

import game.PlayState;
import haxe.Json;
import openfl.Assets;

typedef EventLine =
{
	var name:String;
	var type:Int;
	var ?step:Float;
	var args:Array<Dynamic>;
	var ?color:FlxColor;
}

enum abstract EventType(Int) to Int
{
	var Stepper:EventType = 0xE0; // Function Event (trigger on a set step)
	var Section:EventType = 0xE1; // Section Event (trigger every section)
}

class ChartEvents
{
	static final game:PlayState = PlayState.self;

	public static function loadEventChart(songName:String, ?data:Array<EventLine>):Array<EventLine>
	{
		var tempEvents:Array<EventLine> = [];

		var eventsFolder:String = 'data/songs/chart/${songName.toLowerCase()}/events.json';

		if (AssetHandler.exists(AssetHandler.getPath(eventsFolder, JSON)))
		{
			var jsonPath:String = AssetHandler.getAsset(eventsFolder, JSON);

			tempEvents = cast Json.parse(jsonPath);
			trace(tempEvents);
		}

		return tempEvents;
	}
}