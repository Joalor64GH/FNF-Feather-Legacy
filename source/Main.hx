package;

import feather.core.Controls;
import feather.core.FPS;
import feather.core.Utils.TransitionState;
import feather.core.handlers.CacheHandler;
import flixel.FlxGame;
import flixel.addons.transition.TransitionData;
import flixel.math.FlxPoint;
import flixel.system.FlxVersion;
import openfl.display.Sprite;
import sys.FileSystem;
import sys.io.File;

typedef BaseGameObject = #if CRASH_HANDLER_ENABLED CustomGame #else FlxGame #end;

class Main extends Sprite {
	public static final logSavePath:String = 'logs/FF-${Date.now().toString().replace(' ', '-').replace(':', "'")}.txt';

	public static var self:Main;

	// don't set "branch" as null, set it to "" instead!!!
	public static var featherVer:FlxVersion = new FlxVersion(1, 0, 0, true);
	public static var fnfVer:FlxVersion = new FlxVersion(0, 2, 8, false);

	public var fpsCounter:FPS;

	public function new():Void {
		super();

		self = this;

		var baseGame:BaseGameObject = new BaseGameObject(1280, 720, feather.state.WarningState, 60, 60, true, false);
		addChild(baseGame);

		fpsCounter = new FPS(/*10, 5, FlxColor.WHITE*/);
		addChild(fpsCounter);

		TransitionState.defaultTransIn = new TransitionData(FADE, FlxColor.BLACK, 0.8, new FlxPoint(0, -1));
		TransitionState.defaultTransOut = new TransitionData(FADE, FlxColor.BLACK, 0.5, new FlxPoint(0, 1));

		CacheHandler.gcEnable();
		Controls.self = new Controls();
		feather.core.handlers.UserSettings.load();

		FlxG.autoPause = false;
		FlxG.fixedTimestep = true;
		FlxG.mouse.useSystemCursor = true;
		FlxG.mouse.visible = false;

		FlxG.signals.preStateSwitch.add(function():Void {
			CacheHandler.purge([STORED_IMAGES, UNUSED_IMAGES, CACHED_SOUNDS]);
		});

		openfl.Lib.current.stage.application.onExit.add(function(code:Int):Void {
			Controls.destroy();
		});
	}
}

class CustomGame extends FlxGame {
	override function create(_):Void {
		try super.create(_) catch (e:haxe.Exception)
			return onError(e);
	}

	override function onFocus(_):Void {
		try super.onFocus(_) catch (e:haxe.Exception)
			return onError(e);
	}

	override function onFocusLost(_):Void {
		try super.onFocusLost(_) catch (e:haxe.Exception)
			return onError(e);
	}

	override function onEnterFrame(_):Void {
		try super.onEnterFrame(_) catch (e:haxe.Exception)
			return onError(e);
	}

	override function update():Void {
		try super.update() catch (e:haxe.Exception)
			return onError(e);
	}

	override function draw():Void {
		try super.draw() catch (e:haxe.Exception)
			return onError(e);
	}

	public function onError(e:haxe.Exception):Void {
		var caughtErrors:Array<String> = [];

		for (item in haxe.CallStack.exceptionStack(true)) {
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

			File.saveContent(Main.logSavePath,
				'[Error Stack]\n-----------\n${msg}\n-----------\n[Caught: ${e.message}]\n-----------\nConsider reporting this error to our GitHub Page: https://github.com/BeastlyGabi/FNF-Feather\n');
		} catch (e:Dynamic)
			Sys.println('Error!\nCouldn\'t save crash log\nCaught: ${e}');

		@:privateAccess {
			FlxG.game._requestedState = new feather.state.CrashState(msg, e.message, Type.getClass(FlxG.state));
			FlxG.game.switchState();
		}
	}
}
