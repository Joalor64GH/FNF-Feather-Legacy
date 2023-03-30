package game.subStates;

import core.Controls;
import flixel.FlxSubState;
import game.system.music.BeatManager;

class MusicBeatSubState extends FlxSubState implements IMusicFunctions
{
	public var controls(get, never):Controls;

	function get_controls():Controls
		return Controls.self;

	public var beatContainer:BeatManager;

	public var curBeat(get, never):Int;
	public var curSec(get, never):Int;
	public var curStep(get, never):Int;

	function get_curBeat():Int
		return beatContainer.beat;

	function get_curSec():Int
		return beatContainer.sec;

	function get_curStep():Int
		return beatContainer.step;

	public function new():Void
	{
		super();
		beatContainer = new BeatManager(this);
	}

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (game.system.music.Conductor.songPosition >= 0)
			beatContainer.update(elapsed);
	}

	public function beatHit():Void {}

	public function stepHit():Void {}

	public function secHit():Void {}
}
