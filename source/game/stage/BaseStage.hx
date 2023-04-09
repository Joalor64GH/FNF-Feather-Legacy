package game.stage;

import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import game.PlayState;

/*
 * Extensible Class for handling the game's backgrounds, the so called "Stages"
**/
class BaseStage extends FlxGroup {
	/**
	 * Helper variable, gives access to `PlayState`
	 */
	final game:PlayState = PlayState.self;

	/**
	 * Helper variable that defines the default path for stages
	 *
	 * defaults to `images/backgrounds`
	 */
	public var pathBase:String = "images/backgrounds";

	/**
	 * Defines the in-game camera zoom
	 */
	public var cameraZoom:Float = 1.0;

	/**
	 *	Defines the in-game hud zoom
	 */
	public var hudZoom:Float = 1.0;

	/**
	 * Defines the in-game camera speed
	 */
	public var cameraSpeed:Float = 1.0;

	/**
	 * Defines whether or not the crowd should appear on Stage
	 */
	public var displayCrowd:Bool = true;

	#if SCRIPTING_ENABLED
	/**
	 * a Stage Script, usually ran (or tried to) when loading a stage that doesn't exist
	 */
	public var bgScript:ScriptHandler = null;
	#end

	public var playerOffset:FlxPoint = new FlxPoint(0, 0);
	public var enemyOffset:FlxPoint = new FlxPoint(0, 0);
	public var crowdOffset:FlxPoint = new FlxPoint(0, 0);

	public var camPosition:FlxPoint = new FlxPoint(Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY);

	/**
	 * Use this to create your stage objects
	 * remember to always call `super();`
	 */
	public function new(?curStage:String):Void {
		super();

		#if SCRIPTING_ENABLED
		var newBase:String = '${pathBase}/${curStage}';
		if (sys.FileSystem.exists(AssetHandler.getPath('${newBase}/${curStage}', SCRIPT))) {
			var localPath:String = AssetHandler.getPath('${newBase}');
			bgScript = new ScriptHandler(AssetHandler.getAsset('${newBase}/${curStage}', SCRIPT), localPath);
			bgScript.set('stage', this);
			bgScript.set('remove', remove);
			bgScript.set('add', add);

			bgScript.call('create', []);
		}
		#end
	}

	/**
	 * Helper function for getting a stage's object, uses `pathBase`
	 * @param objName             the path for the object
	 * @param objType             the type of the object, e.g: IMAGE, XML, TXT, SOUND...
	 * @return Dynamic
	 */
	public function getObject(objName:String, objType:AssetType = IMAGE):Dynamic {
		return AssetHandler.getAsset('${pathBase}/${objName}', objType);
	}

	/**
	 * Use this to create and manage events that will run every frame
	 * remember to always call `super.update(elapsed);`
	 */
	public override function update(elapsed:Float):Void {
		super.update(elapsed);

		#if SCRIPTING_ENABLED
		if (bgScript != null)
			bgScript.call('update', [elapsed]);
		#end
	}

	/**
	 * Called whenever the Countdown begins
	 */
	public function onCountdownStart():Void {
		#if SCRIPTING_ENABLED
		if (bgScript != null)
			bgScript.call('onCountdownStart', []);
		#end
	}

	/**
	 * Called whenever the Countdown is ticking
	 */
	public function onCountdownTick(position:Int):Void {
		#if SCRIPTING_ENABLED
		if (bgScript != null)
			bgScript.call('onCountdownTick', [position]);
		#end
	}

	/**
	 * Called whenever the Song starts
	 */
	public function onSongStart():Void {
		#if SCRIPTING_ENABLED
		if (bgScript != null)
			bgScript.call('onSongStart', []);
		#end
	}

	/**
	 * Called whenever the song ends
	 */
	public function onSongEnd():Void {
		#if SCRIPTING_ENABLED
		if (bgScript != null)
			bgScript.call('onSongEnd', []);
		#end
	}

	/**
	 * Called whenever a event is activated
	 */
	public function onEventDispatch(event:game.PlayState.GameplayEvent):Void {
		#if SCRIPTING_ENABLED
		if (bgScript != null)
			bgScript.call('onEventDispatch', [event]);
		#end
	}

	/**
	 * Called when pausing the game
	**/
	public function onPauseDispatch(paused:Bool):Void {
		#if SCRIPTING_ENABLED
		if (bgScript != null)
			bgScript.call('onPauseDispatch', [paused]);
		#end
	}

	/**
	 * Called whenever a beat is hit
	 */
	public function onBeat(curBeat:Int):Void {
		#if SCRIPTING_ENABLED
		if (bgScript != null)
			bgScript.call('onBeat', [curBeat]);
		#end
	}

	/**
	 * Called whenever a step is reached
	 */
	public function onStep(curStep:Int):Void {
		#if SCRIPTING_ENABLED
		if (bgScript != null)
			bgScript.call('onStep', [curStep]);
		#end
	}

	/**
	 * Called whenever a section is reached
	 */
	public function onSec(curSec:Int):Void {
		#if SCRIPTING_ENABLED
		if (bgScript != null)
			bgScript.call('onSec', [curSec]);
		#end
	}
}
