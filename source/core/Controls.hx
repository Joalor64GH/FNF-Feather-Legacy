package core;

import flixel.input.keyboard.FlxKey;
import flixel.util.FlxSignal.FlxTypedSignal;
import openfl.events.KeyboardEvent;

typedef KeyMap = Map<String, Array<FlxKey>>;
typedef KeyCall = (Int, String) -> Void; // for convenience

class Controls {
	public static final defaultKeys:KeyMap = [
		"left" => [D, LEFT],
		"down" => [F, DOWN],
		"up" => [J, UP],
		"right" => [K, RIGHT],
		"accept" => [ENTER, SPACE],
		"back" => [ESCAPE, BACKSPACE],
		"pause" => [ENTER, ESCAPE],
		"reset" => [R, NONE],
		"cheat" => [SEVEN, EIGHT]
	];

	public var actions(default, null):KeyMap;

	public var onKeyPressed(default, null):FlxTypedSignal<KeyCall> = new FlxTypedSignal<KeyCall>();
	public var onKeyReleased(default, null):FlxTypedSignal<KeyCall> = new FlxTypedSignal<KeyCall>();

	var keysHeld:Array<Int> = [];

	public function justPressed(action:String):Bool {
		var keys:Array<FlxKey> = actions.get(action);
		for (key in keys)
			if (FlxG.keys.checkStatus(key, JUST_PRESSED))
				return true;

		return false;
	}

	public function anyJustPressed(actionArray:Array<String>):Bool {
		for (action in actionArray) {
			var keys:Array<FlxKey> = actions.get(action);
			for (key in keys)
				if (FlxG.keys.checkStatus(key, JUST_PRESSED))
					return true;
		}

		return false;
	}

	public function pressed(action:String):Bool {
		var keys:Array<FlxKey> = actions.get(action);
		for (key in keys)
			if (FlxG.keys.checkStatus(key, PRESSED))
				return true;

		return false;
	}

	public function anyPressed(actionArray:Array<String>):Bool {
		for (action in actionArray) {
			var keys:Array<FlxKey> = actions.get(action);
			for (key in keys)
				if (FlxG.keys.checkStatus(key, PRESSED))
					return true;
		}

		return false;
	}

	public function justReleased(action:String):Bool {
		var keys:Array<FlxKey> = actions.get(action);
		for (key in keys)
			if (FlxG.keys.checkStatus(key, JUST_RELEASED))
				return true;

		return false;
	}

	public function anyJustReleased(actionArray:Array<String>):Bool {
		for (action in actionArray) {
			var keys:Array<FlxKey> = actions.get(action);
			for (key in keys)
				if (FlxG.keys.checkStatus(key, JUST_RELEASED))
					return true;
		}

		return false;
	}

	public function getActionFromKey(key:Int):String {
		for (id => action in actions)
			if (action != null && action.contains(key))
				return id;

		return null;
	}

	function onKeyDown(evt:KeyboardEvent):Void {
		if (FlxG.keys.enabled && (FlxG.state.active || FlxG.state.persistentUpdate) && !keysHeld.contains(evt.keyCode)) {
			keysHeld.push(evt.keyCode);
			onKeyPressed.dispatch(evt.keyCode, getActionFromKey(evt.keyCode));
		}
	}

	function onKeyUp(evt:KeyboardEvent):Void {
		if (FlxG.keys.enabled && (FlxG.state.active || FlxG.state.persistentUpdate) && keysHeld.contains(evt.keyCode)) {
			keysHeld.remove(evt.keyCode);
			onKeyReleased.dispatch(evt.keyCode, getActionFromKey(evt.keyCode));
		}
	}

	// <=========== INITIALIZERS ===========> //
	public static var self:Controls;

	public function new():Void {
		actions = defaultKeys.copy();
		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
	}

	public static function destroy():Void {
		self.actions = null;
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, self.onKeyDown);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, self.onKeyUp);
	}
}
