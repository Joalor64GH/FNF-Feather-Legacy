package core;

import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.group.FlxGroup;
import flixel.system.FlxSound;
import flixel.input.keyboard.FlxKey;
import flixel.util.FlxAxes;
import flixel.util.FlxSave;
import game.system.Conductor;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.media.Sound;
import openfl.net.FileReference;

typedef TransitionState = flixel.addons.transition.FlxTransitionableState;

class Utils {
	/**
	 * Sets the volume keys to new ones, each parameter is optional, as setting them to null results in the default keys
	 * 
	 * @param keysUp        the Volume UP (+) Keys, e.g [FlxKey.NUMPADPLUS, FlxKey.PLUS]
	 * @param keysDown      the Volume DOWN (-) Keys, e.g [FlxKey.NUMPADMINUS, FlxKey.MINUS]
	 * @param keysMute      the Volume MUTE (silent) Keys, e.g [FlxKey.NUMPADZERO, FlxKey.ZERO]
	**/
	@:keep public static inline function setVolKeys(?keysUp:Array<FlxKey>, ?keysDown:Array<FlxKey>, ?keysMute:Array<FlxKey>):Void {
		if (keysUp == null)
			keysUp = [FlxKey.NUMPADPLUS, FlxKey.PLUS];
		if (keysDown == null)
			keysDown = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
		if (keysMute == null)
			keysMute = [FlxKey.NUMPADZERO, FlxKey.ZERO];

		FlxG.sound.muteKeys = keysMute;
		FlxG.sound.volumeDownKeys = keysDown;
		FlxG.sound.volumeUpKeys = keysUp;
	}

	/**
	 * Centers the specified object to the bounds of another object
	 *
	 * USAGE:
	 * ```haxe
	 * var myOverlay:FlxSprite = new FlxSprite(0, 150).makeGraphic(300, 500, 0xFF000000);
	 * myOverlay.screenCenter(X);
	 * add(myOverlay);
	 *
	 * var myObject:FlxObject = new FlxObject(0, 0, 1, 1);
	 * myObject.centerOverlay(myOverlay, X);
	 * add(myObject);
	 * ```
	 *
	 * @author SwickTheGreat
	 *
	 * @param object         the child object that should be centered
	 * @param base           the base object, used for the center calculations
	 * @param axes           in which axes should the child object be centered? (default: XY)
	 * @return               child object, now centered according to the base object
	 */
	@:keep public static inline function centerOverlay(object:FlxObject, base:FlxObject, axes:FlxAxes = XY):FlxObject {
		if (object == null || base == null)
			return object;
		if (axes.x)
			object.x = base.x + (base.width / 2) - (object.width / 2);
		if (axes.y)
			object.y = base.y + (base.height / 2) - (object.height / 2);
		return object;
	}

	/**
	 * Adds an object behind the specified group
	 *
	 * USAGE:
	 * ```haxe
	 * // this will add the object to the beginning position of the current state
	 * var exampleObject:FlxObject = new FlxObject(0, 0, 1, 1)
	 * exampleObject.addToPos(FlxG.state, 0);
	 * ```
	 *
	 * @param group              the group in which the object should get added
	 * @param index              the position of the object
	 */
	@:keep public static inline function addToPos(object:FlxBasic, group:FlxGroup, index:Int):FlxBasic {
		group.insert(index, object);
		return object;
	}

	/**
	 * Adds an object behind the specified typed group
	 *
	 * USAGE:
	 * ```haxe
	 * var objectGroup:FlxTypedGroup<FlxObject> = new FlxTypedGroup<FlxObject>();
	 * // this will add the object to the beginning position of the objectGroup
	 * var exampleObject:FlxObject = new FlxObject(0, 0, 1, 1)
	 * exampleObject.addTypedPos(objectGroup, 0);
	 * ```
	 *
	 * @param group              the group in which the object should get added
	 * @param index              the position of the object
	 */
	@:keep public static inline function addTypedPos(object:FlxBasic, group:FlxTypedGroup<Dynamic>, index:Int):FlxBasic {
		group.insert(index, object);
		return object;
	}

	/**
	 * Returns a folder for use with FlxG.save
	 * if on flixel 5.0.0 or greater, it will be formatted `COMPANY/EXECUTABLE_NAME/FOLDER`
	 * - so `BeastlyGhost/FunkinFeather/FOLDER` by default
	 *
	 * @param name          the new save name
	 * @param folder        the save's folder name
	 */
	@:keep public static inline function saveFolder(?folder:String):String {
		#if (flixel < "5.0.0")
		return folder;
		#else
		var folderResult:String = folder != null ? '/${folder}' : '';
		return @:privateAccess '${FlxG.stage.application.meta.get('company')}/${FlxSave.validate(FlxG.stage.application.meta.get('file'))}' + folderResult;
		#end
	}

	/**
	 * Launches the user's Web Browser with the specified URL
	 * @param url          the URL to open
	 */
	@:keep public static inline function openURL(url:String):Void {
		#if linux
		Sys.command('/usr/bin/xdg-open', [url]);
		#else
		FlxG.openURL(url);
		#end
	}

	/**
	 * Generates a Arrow Sprite for use with the game menus
	 * @param xPos        the X position for the created arrow
	 * @param yPos        the Y position for the created arrow
	 * @param dir         the arrow direction, may be left, or right
	 * @return FlxSprite
	 */
	@:keep public static inline function generateArrow(xPos:Float, yPos:Float, dir:String) {
		var newArrow = new FlxSprite(xPos, yPos);
		newArrow.frames = Paths.getSparrowAtlas('menus/shared/menu_arrows');
		newArrow.animation.addByPrefix('idle', "arrow " + dir);
		newArrow.animation.addByPrefix('press', "arrow push " + dir);
		newArrow.animation.play('idle');
		return newArrow;
	}

	/**
	 * Returns the specified asset, followed by its type while searching for the IMAGE ui skin folders
	 *
	 * @param asset                 the name of the asset (e.g: healthBar)
	 * @param type                  the type of the asset (e.g: IMAGE)
	 * @param skin                  the skin asset, defaults to `default`
	 */
	@:keep public static inline function getUIAsset(asset:String, type:AssetType = IMAGE, skin:String = 'default'):Dynamic {
		var path:String = AssetHandler.getPath('images/ui/${skin}/${asset}', type);
		if (!AssetHandler.exists(path))
			skin = 'default';

		return AssetHandler.getAsset('images/ui/${skin}/${asset}', type);
	}

	/**
	 * Behaves equal to `Utils.getUIAsset`, but for sounds instead
	 *
	 * @param asset                 the name of the sound
	 * @param skin                  the sound's skin asset, defaults to `default`
	 */
	@:keep public static inline function getUISound(sound:String, skin:String = 'default'):Sound {
		var path:String = AssetHandler.getPath('sounds/${skin}/${sound}', SOUND);
		if (!AssetHandler.exists(path))
			skin = 'default';

		return AssetHandler.getAsset('sounds/${skin}/${sound}', SOUND);
	}

	/**
	 * Updates the Framerate Capping based on the specified value
	 *
	 * @param newFramerate           the new Framerate Cap that the game should use
	 */
	@:keep public static inline function updateFramerateCap(newFramerate:Int):Void {
		if (newFramerate > FlxG.drawFramerate) {
			FlxG.updateFramerate = newFramerate;
			FlxG.drawFramerate = newFramerate;
		} else {
			FlxG.drawFramerate = newFramerate;
			FlxG.updateFramerate = newFramerate;
		}
	}

	/**
	 * Resets the menu music
	 * @param newMusic [OPTIONAL]         the music name on the files, defaults to "freakyMenu"
	 * @param fadeIn [OPTIONAL]           whether to fade in the music when it begins (defaults to false)]
	 */
	@:keep public static inline function resetMusic(newMusic:String = 'freakyMenu', fadeIn:Bool = false):Void {
		if (((FlxG.sound.music != null) && (!FlxG.sound.music.playing)) || (FlxG.sound.music == null)) {
			FlxG.sound.playMusic(Paths.music(newMusic), fadeIn ? 0 : 0.7);
			if (fadeIn)
				FlxG.sound.music.fadeIn(4, 0, 0.7);
			Conductor.changeBPM(102);
		}
	}

	/**
	 * Stops and Destroys all audio tracks that were specified
	 * @param audioTracks         array with sounds to destroy
	 */
	@:keep public static inline function killMusic(audioTracks:Array<FlxSound>):Void {
		for (i in 0...audioTracks.length) {
			audioTracks[i].stop();
			audioTracks[i].destroy();
		}
	}

	/**
	 * removes characters from the specified EReg on any string
	 * @param string           the string that we should remove the characters from
	 * @return String
	 */
	@:keep public static inline function removeForbidden(string:String):String {
		var invalidChars:EReg = ~/[~&\\;:<>#]/;
		var hideChars:EReg = ~/[.,'"%?!]/;

		return hideChars.split(invalidChars.split(string.replace(' ', '-')).join("-")).join("").toLowerCase();
	}

	static var _file:FileReference;

	@:keep public static inline function saveData(fileName:String, data:String):Void {
		if ((data != null) && (data.length > 0)) {
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data.trim(), '${fileName}');
		}
	}

	@:keep static inline function onSaveComplete(_):Void {
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Data saved.");
	}

	/**
	 * Called when the save file dialog is cancelled.
	 */
	@:keep static inline function onSaveCancel(_):Void {
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
	 * Called if there is an error while saving the given data.
	 */
	@:keep static inline function onSaveError(_):Void {
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("An error occurred while saving data");
	}
}
