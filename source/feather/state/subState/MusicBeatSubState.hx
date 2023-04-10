package feather.state.subState;

import feather.core.Controls;
import feather.core.music.Conductor;
import flixel.FlxSubState;

class MusicBeatSubState extends FlxSubState implements IBeatState {
	public var controls(get, never):Controls;

	function get_controls():Controls
		return Controls.self;

	public var beatContainer:Conductor;

	public var curBeat(get, never):Int;
	public var curSec(get, never):Int;
	public var curStep(get, never):Int;

	function get_curBeat():Int
		return beatContainer.beatPos;

	function get_curSec():Int
		return beatContainer.secPos;

	function get_curStep():Int
		return beatContainer.stepPos;

	public function new():Void {
		super();
		beatContainer = new Conductor(this);
	}

	public override function update(elapsed:Float):Void {
		super.update(elapsed);

		if (Conductor.songPosition >= 0)
			beatContainer.update(elapsed);
	}

	public function onBeat(curBeat:Int):Void {}

	public function onStep(curStep:Int):Void {}

	public function onSec(curSec:Int):Void {}
}
