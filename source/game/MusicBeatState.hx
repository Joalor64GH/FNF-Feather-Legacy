package game;

import core.Controls;
import flixel.addons.ui.FlxUIState;
import rhythm.BeatManager;
import rhythm.Conductor;

class MusicBeatState extends FlxUIState
{
	public var controls(get, never):Controls;

	function get_controls():Controls
		return Controls.self;

	public var beatContainer:BeatManager = new BeatManager();

	public var curBeat(get, never):Int;
	public var curSec(get, never):Int;
	public var curStep(get, never):Int;

	function get_curBeat():Int
		return beatContainer.beat;

	function get_curSec():Int
		return beatContainer.sec;

	function get_curStep():Int
		return beatContainer.step;

	var tempStep:Int = -1;

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		beatContainer.update(elapsed);
		if (curStep > tempStep)
		{
			tempStep = curStep;
			stepHit();
		}
		if (curStep % 4 == 0)
			beatHit();
		if (curBeat % 4 == 0)
			secHit();
	}

	public function beatHit():Void {}

	public function stepHit():Void {}

	public function secHit():Void {}
}
