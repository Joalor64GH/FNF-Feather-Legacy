package game;

import core.Controls;
import flixel.FlxSubState;
import flixel.addons.ui.FlxUIState;
import game.system.music.BeatManager;

class MusicBeatState extends FlxUIState implements IMusicFunctions
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

		if (!TransitionState.skipNextTransIn)
			transIn = TransitionState.defaultTransIn;
		if (!TransitionState.skipNextTransOut)
			transOut = TransitionState.defaultTransOut;
	}

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (game.system.music.Conductor.songPosition >= 0)
		{
			beatContainer.update(elapsed);
			FlxG.watch.add(game.system.music.Conductor, "songPosition", "Song Pos:");
			FlxG.watch.add(beatContainer, "beat", "Song Beat:");
			FlxG.watch.add(beatContainer, "step", "Song Step:");
			FlxG.watch.add(beatContainer, "sec", "Song Section:");
		}
	}

	public static function switchState(newState:flixel.FlxState, ?assetStack:Array<String>, ?assetType:AssetType = IMAGE):Void
	{
		if (assetStack == null || assetStack.length < 1)
			FlxG.switchState(newState);
		else
		{
			for (i in assetStack)
				AssetHandler.preload(i, assetType);
			FlxG.switchState(newState);
		}
	}

	public function beatHit():Void
	{
		// receive beats here
	}

	public function stepHit():Void
	{
		// receive steps here
	}

	public function secHit():Void
	{
		// receive sections here
	}
}

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
