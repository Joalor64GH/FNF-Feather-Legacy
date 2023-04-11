package feather.state;

import feather.core.Controls;
import feather.core.data.Handlers.CacheHandler;
import feather.core.music.Conductor;
import flixel.addons.ui.FlxUIState;

class MusicBeatState extends FlxUIState implements IBeatState {
	public var globals:Array<ScriptHandler> = [];

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

	public function setVar(varString:String, varLue:Dynamic):Void {
		#if SCRIPTING_ENABLED
		if (globals.length > 0)
			for (i in 0...globals.length)
				globals[i].set(varString, varLue);
		#end
	}

	public function callFn(fn:String, parameters:Array<Dynamic>):Void {
		#if SCRIPTING_ENABLED
		if (globals.length > 0)
			for (i in 0...globals.length)
				globals[i].call(fn, parameters);
		#end
	}

	public function new():Void {
		super();

		beatContainer = new Conductor(this);

		if (!TransitionState.skipNextTransIn)
			transIn = TransitionState.defaultTransIn;
		if (!TransitionState.skipNextTransOut)
			transOut = TransitionState.defaultTransOut;
	}

	public override function update(elapsed:Float):Void {
		super.update(elapsed);

		if (Conductor.songPosition >= 0) {
			beatContainer.update(elapsed);
			FlxG.watch.add(Conductor, "songPosition", "Song Pos:");
			FlxG.watch.add(this, "curBeat", "Song Beat:");
			FlxG.watch.add(this, "curStep", "Song Step:");
			FlxG.watch.add(this, "curSec", "Song Section:");
		}
	}

	public static function switchState(newState:flixel.FlxState):Void {
		// if (!Std.isOfType(MusicBeatState, feather.state.PlayState))
		CacheHandler.purge([UNUSED_IMAGES, CACHED_SOUNDS]);

		if (newState == FlxG.state)
			FlxG.resetState();
		else
			FlxG.switchState(newState);
	}

	public function onBeat(curBeat:Int):Void {
		// receive beats here
	}

	public function onStep(curStep:Int):Void {
		// receive steps here
	}

	public function onSec(curSec:Int):Void {
		// receive sections here
	}
}
