package;

import core.Controls;
import core.FPS;
import core.assets.CacheHandler;
import flixel.FlxGame;
import haxe.CallStack;
import haxe.Exception;
import openfl.display.Sprite;

using StringTools;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

class Main extends Sprite
{
	public static var self:Main;

	public var fpsCounter:FPS;

	public function new():Void
	{
		super();

		self = this;
		Controls.self = new Controls();

		var baseGame:CustomGame = new CustomGame(1280, 720, game.menus.MainMenu, 60, 60, true, false);
		addChild(baseGame);

		fpsCounter = new FPS();
		addChild(fpsCounter);

		FlxG.autoPause = false;
		FlxG.fixedTimestep = true;
		FlxG.mouse.useSystemCursor = true;
		FlxG.mouse.visible = false;

		FlxG.signals.preStateSwitch.add(function():Void
		{
			CacheHandler.purgeStored();
			// @:privateAccess CacheHandler._purgeUnused();
		});
	}
}

class CustomGame extends FlxGame
{
	public static var logSavePath:String = 'logs/FF-' + Date.now().toString().replace(' ', '-').replace(':', "'") + '.txt';

	override function create(_):Void
	{
		try
			super.create(_)
		catch (e:Exception)
			return onError(e);
	}

	override function onFocus(_):Void
	{
		try
			super.onFocus(_)
		catch (e:Exception)
			return onError(e);
	}

	override function onFocusLost(_):Void
	{
		try
			super.onFocusLost(_)
		catch (e:Exception)
			return onError(e);
	}

	override function onEnterFrame(_):Void
	{
		try
			super.onEnterFrame(_)
		catch (e:Exception)
			return onError(e);
	}

	override function update():Void
	{
		try
			super.update()
		catch (e:Exception)
			return onError(e);
	}

	override function draw():Void
	{
		try
			super.draw()
		catch (e:Exception)
			return onError(e);
	}

	public function onError(e:Exception):Void
	{
		var caughtErrors:Array<String> = [];

		for (item in CallStack.exceptionStack(true))
		{
			switch (item)
			{
				case CFunction:
					caughtErrors.push('Non-Haxe (C) Function');
				case Module(moduleName):
					caughtErrors.push('Module (${moduleName})');
				case FilePos(s, file, line, column):
					caughtErrors.push('${file} (line ${line})');
				case Method(className, method):
					caughtErrors.push('${className} (method ${method})');
				case LocalFunction(name):
					caughtErrors.push('Local Function (${name})');
			}

			#if sys
			Sys.println(item);
			#end
		}

		final msg:String = caughtErrors.join('\n');

		#if sys
		try
		{
			if (!FileSystem.exists('logs'))
				FileSystem.createDirectory('logs');

			File.saveContent(logSavePath,
				'[Error Stack]\n-----------\n${msg}\n-----------\n[Caught: ${e.message}]\n-----------\nConsider reporting this error to our Gamebanana: https://gamebanana.com/mods/412233\n');
		}
		catch (e:Dynamic)
			Sys.println('Error!\nCouldn\'t save crash log\nCaught: ${e}');
		#end

		return FlxG.switchState(new core.CrashState(msg, e.message, Type.getClass(FlxG.state)));
	}
}
