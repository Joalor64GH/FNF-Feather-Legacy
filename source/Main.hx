package;

import core.Controls;
import core.FPS;
import core.assets.CacheHandler;
import flixel.FlxGame;
import flixel.addons.transition.TransitionData;
import flixel.math.FlxPoint;
import haxe.CallStack;
import haxe.Exception;
import openfl.display.Sprite;
import sys.FileSystem;
import sys.io.File;

typedef VersionScheme = {
	var number:String;

	/**
	 * - Nightly: Experimental, WIP, recommended for testers
	 * - Unstable: Experimental, bleeding-edge, WIP
	 */
	var branch:String;
}

class Main extends Sprite {
	public static var self:Main;

	// don't set "branch" as null, set it to "" instead!!!
	public static var featherVer:VersionScheme = {number: "1.0.0", branch: "UNSTABLE"};
	public static var fnfVer:VersionScheme = {number: "0.2.8", branch: "DEMO"};

	public var fpsCounter:FPS;

	public function new():Void {
		super();

		self = this;

		var baseGame:CustomGame = new CustomGame(1280, 720, game.menus.MainMenu, 60, 60, true, false);
		addChild(baseGame);

		fpsCounter = new FPS(10, 5, FlxColor.WHITE);
		addChild(fpsCounter);

		CacheHandler.gcEnable();
		Controls.self = new Controls();
		game.system.Settings.load();

		TransitionState.defaultTransIn = new TransitionData(FADE, FlxColor.BLACK, 0.8, new FlxPoint(0, -1));
		TransitionState.defaultTransOut = new TransitionData(FADE, FlxColor.BLACK, 0.5, new FlxPoint(0, 1));

		FlxG.autoPause = false;
		FlxG.fixedTimestep = true;
		FlxG.mouse.useSystemCursor = true;
		FlxG.mouse.visible = false;

		FlxG.signals.preStateSwitch.add(function():Void {
			CacheHandler.purge(true);
		});

		openfl.Lib.current.stage.application.onExit.add(function(code:Int):Void {
			Controls.destroy();
		});
	}
}

class CustomGame extends FlxGame {
	public static var logSavePath:String = 'logs/FF-${Date.now().toString().replace(' ', '-').replace(':', "'")}.txt';

	override function create(_):Void {
		try super.create(_) catch (e:Exception)
			return onError(e);
	}

	override function onFocus(_):Void {
		try super.onFocus(_) catch (e:Exception)
			return onError(e);
	}

	override function onFocusLost(_):Void {
		try super.onFocusLost(_) catch (e:Exception)
			return onError(e);
	}

	override function onEnterFrame(_):Void {
		try super.onEnterFrame(_) catch (e:Exception)
			return onError(e);
	}

	override function update():Void {
		try super.update() catch (e:Exception)
			return onError(e);
	}

	override function draw():Void {
		try super.draw() catch (e:Exception)
			return onError(e);
	}

	public function onError(e:Exception):Void {
		var caughtErrors:Array<String> = [];

		for (item in CallStack.exceptionStack(true)) {
			switch (item) {
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

			Sys.println(item);
		}

		final msg:String = caughtErrors.join('\n');

		try {
			if (!FileSystem.exists('logs'))
				FileSystem.createDirectory('logs');

			File.saveContent(logSavePath,
				'[Error Stack]\n-----------\n${msg}\n-----------\n[Caught: ${e.message}]\n-----------\nConsider reporting this error to our GitHub Page: https://github.com/BeastlyGabi/FNF-Feather\n');
		} catch (e:Dynamic)
			Sys.println('Error!\nCouldn\'t save crash log\nCaught: ${e}');

		return FlxG.switchState(new core.CrashState(msg, e.message, Type.getClass(FlxG.state)));
	}
}
