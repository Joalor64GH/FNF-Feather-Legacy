package game.editors;

import game.PlayState;
import game.gameplay.NoteHandler;
import haxe.Json;
import rhythm.chart.ChartDefs.ChartFormat;
import rhythm.chart.ChartLoader;

/**
 * State for Editing and Exporting new Charts
 */
class ChartEditor extends MusicBeatState
{
	private var const:PlayStateStruct;

	public var _song:ChartFormat;

	public var renderedNotes:NoteGroup;
	public var renderedHolds:NoteGroup;

	public function new(const:PlayStateStruct):Void
	{
		super();

		this.const = const;

		_song = ChartLoader.loadChart(const.songName, const.difficulty);
	}

	public override function create():Void
	{
		super.create();
	}

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.ESCAPE)
			FlxG.switchState(new PlayState({songName: const.songName, difficulty: const.difficulty, gamemode: CHARTING}));
	}

	public function exportChart():Void
	{
		var json = {
			"song": _song
		};

		var data:String = Json.stringify(json, '\t');
		Utils.saveData('${_song.name.toLowerCase()}.json', data);
	}
}
