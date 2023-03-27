package core;

import flixel.system.FlxSound;
import game.system.Conductor;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.net.FileReference;

class Utils
{
	/**
	 * Generates a Arrow Sprite for use with the game menus
	 * @param xPos the X position for the created arrow
	 * @param yPos the Y position for the created arrow
	 * @param dir the arrow direction, may be left, or right
	 * @return FlxSprite
	**/
	@:keep public static inline function generateArrow(xPos:Float, yPos:Float, dir:String)
	{
		var newArrow = new FlxSprite(xPos, yPos);
		newArrow.frames = Paths.getSparrowAtlas('menus/shared/menu_arrows');
		newArrow.animation.addByPrefix('idle', "arrow " + dir);
		newArrow.animation.addByPrefix('press', "arrow push " + dir);
		newArrow.animation.play('idle');
		return newArrow;
	}

	/**
	 * Resets the menu music
	 * @param newMusic [OPTIONAL] the music name on the files, defaults to "freakyMenu"
	 * @param fadeIn [OPTIONAL] whether to fade in the music when it begins (defaults to false)]
	**/
	@:keep public static inline function resetMusic(newMusic:String = 'freakyMenu', fadeIn:Bool = false):Void
	{
		if (((FlxG.sound.music != null) && (!FlxG.sound.music.playing)) || (FlxG.sound.music == null))
		{
			FlxG.sound.playMusic(Paths.music(newMusic), fadeIn ? 0 : 0.7);
			if (fadeIn)
				FlxG.sound.music.fadeIn(4, 0, 0.7);
			Conductor.changeBPM(102);
		}
	}

	/**
	 * Stops and Destroys all audio tracks that were specified
	 * @param audioTracks array with sounds to destroy
	 */
	@:keep public static inline function killMusic(audioTracks:Array<FlxSound>):Void
	{
		for (i in 0...audioTracks.length)
		{
			audioTracks[i].stop();
			audioTracks[i].destroy();
		}
	}

	/**
	 * removes characters from the specified EReg on any string
	 * @param string the string that we should remove the characters from
	 * @return String
	 */
	@:keep public static inline function removeForbidden(string:String):String
	{
		var invalidChars:EReg = ~/[~&\\;:<>#]/;
		var hideChars:EReg = ~/[.,'"%?!]/;

		return hideChars.split(invalidChars.split(string.replace(' ', '-')).join("-")).join("").toLowerCase();
	}

	static var _file:FileReference;

	@:keep public static inline function saveData(fileName:String, data:String):Void
	{
		if ((data != null) && (data.length > 0))
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data.trim(), '${fileName}');
		}
	}

	@:keep static inline function onSaveComplete(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Data saved.");
	}

	/**
	 * Called when the save file dialog is cancelled.
	 */
	@:keep static inline function onSaveCancel(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
	 * Called if there is an error while saving the given data.
	 */
	@:keep static inline function onSaveError(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("An error occurred while saving data");
	}
}
