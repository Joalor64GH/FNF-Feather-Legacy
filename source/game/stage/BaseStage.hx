package game.stage;

import flixel.group.FlxGroup;
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
	public var cameraZoom:Float = 1.05;

	/**
	 *	Defines the in-game hud zoom
	 */
	public var hudZoom:Float = 1;

	/**
	 * Defines whether or not the crowd should appear on Stage
	 */
	public var displayCrowd:Bool = true;

	/**
	 * Use this to create your stage objects
	 * remember to always call `super();`
	 */
	public function new():Void {
		super();
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
	}

	/**
	 * Triggers whenever the Countdown begins
	 */
	public function onCountdownStart():Void {}

	/**
	 * Triggers whenever the Countdown is ticking
	 */
	public function onCountdownTick(position:Int):Void {}

	/**
	 * Triggers whenever the Song starts
	 */
	public function onSongStart():Void {}

	/**
	 * Triggers whenever the song ends
	 */
	public function onSongEnd():Void {}

	/**
	 * Triggers whenever a event is activated
	 */
	public function onEventDispatch(event:String, args:Array<Dynamic>):Void {}

	/**
	 * Triggers whenever a beat is hit
	 */
	public function onBeat(curBeat:Int):Void {}

	/**
	 * Triggers whenever a step is reached
	 */
	public function onStep(curStep:Int):Void {}

	/**
	 * Triggers whenever a section is reached
	 */
	public function onSec(curSec:Int):Void {}
}
