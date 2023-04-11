package feather.core;

import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadButton;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;
import flixel.util.FlxSignal.FlxTypedSignal;
import openfl.events.KeyboardEvent;

typedef KeybindPreset = {
	var presets:Array<{name:String, keys:Map<String, Array<FlxKey>>, ?buttons:Map<String, Array<FlxGamepadInputID>>}>;
}

typedef KeyPresetFormat = {
	var keys:Array<FlxKey>;
	var ?buttons:Array<FlxGamepadInputID>;
}

typedef KeyCall = (Int, String) -> Void; // for convenience

class Controls {
	public static final defaultKeys:Map<String, KeyPresetFormat> = [
		"left" => {keys: [A, LEFT], buttons: [DPAD_LEFT, LEFT_STICK_DIGITAL_LEFT, LEFT_TRIGGER]},
		"down" => {keys: [S, DOWN], buttons: [DPAD_DOWN, LEFT_STICK_DIGITAL_DOWN, LEFT_SHOULDER]},
		"up" => {keys: [W, UP], buttons: [DPAD_UP, LEFT_STICK_DIGITAL_UP, RIGHT_SHOULDER]},
		"right" => {keys: [D, RIGHT], buttons: [DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT, RIGHT_TRIGGER]},
		"accept" => {keys: [ENTER, SPACE], buttons: #if switch [B, Y] #else [A, X] #end},
		"back" => {keys: [ESCAPE, BACKSPACE], buttons: #if switch [A] #else [B] #end},
		"pause" => {keys: [ENTER, ESCAPE], buttons: [START]},
		"reset" => {keys: [R, NONE], buttons: #if switch [X] #else [Y] #end},
		"cheat" => {keys: [SEVEN, EIGHT]}
	];

	public var actions(default, null):Map<String, KeyPresetFormat> = [];
	public var onKeyPressed(default, null):FlxTypedSignal<KeyCall> = new FlxTypedSignal<KeyCall>();
	public var onKeyReleased(default, null):FlxTypedSignal<KeyCall> = new FlxTypedSignal<KeyCall>();

	public var gamepadMode:Bool = false;

	var keysHeld:Array<Int> = [];

	public function justPressed(action:String):Bool {
		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		for (key in actions.get(action).keys)
			if (FlxG.keys.checkStatus(key, JUST_PRESSED))
				return true;
		if (gamepad != null && actions.get(action).buttons != null) {
			for (button in actions.get(action).buttons)
				if (gamepad.checkStatus(button, JUST_PRESSED)) {
					gamepadMode = true;
					return true;
				}
		}

		return false;
	}

	public function anyJustPressed(actionArray:Array<String>):Bool {
		for (action in actionArray) {
			var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

			for (key in actions.get(action).keys)
				if (FlxG.keys.checkStatus(key, JUST_PRESSED))
					return true;

			if (gamepad != null && actions.get(action).buttons != null) {
				for (button in actions.get(action).buttons)
					if (gamepad.checkStatus(button, JUST_PRESSED)) {
						gamepadMode = true;
						return true;
					}
			}
		}

		return false;
	}

	public function pressed(action:String):Bool {
		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		for (key in actions.get(action).keys)
			if (FlxG.keys.checkStatus(key, PRESSED))
				return true;

		if (gamepad != null && actions.get(action).buttons != null) {
			for (button in actions.get(action).buttons) {
				if (gamepad.checkStatus(button, PRESSED)) {
					gamepadMode = true;
					return true;
				}
			}
		}

		return false;
	}

	public function anyPressed(actionArray:Array<String>):Bool {
		for (action in actionArray) {
			var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

			for (key in actions.get(action).keys)
				if (FlxG.keys.checkStatus(key, PRESSED))
					return true;

			if (gamepad != null && actions.get(action).buttons != null) {
				for (button in actions.get(action).buttons) {
					if (gamepad.checkStatus(button, PRESSED)) {
						gamepadMode = true;
						return true;
					}
				}
			}
		}

		return false;
	}

	public function justReleased(action:String):Bool {
		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		for (key in actions.get(action).keys)
			if (FlxG.keys.checkStatus(key, JUST_RELEASED))
				return true;

		if (gamepad != null && actions.get(action).buttons != null) {
			for (button in actions.get(action).buttons)
				if (gamepad.checkStatus(button, JUST_RELEASED)) {
					gamepadMode = false;
					return true;
				}
		}

		return false;
	}

	public function anyJustReleased(actionArray:Array<String>):Bool {
		for (action in actionArray) {
			var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

			for (key in actions.get(action).keys)
				if (FlxG.keys.checkStatus(key, JUST_RELEASED))
					return true;
			if (gamepad != null && actions.get(action).buttons != null) {
				for (button in actions.get(action).buttons)
					if (gamepad.checkStatus(button, JUST_RELEASED)) {
						gamepadMode = false;
						return true;
					}
			}
		}

		return false;
	}

	public function getActionFromKey(key:Int):String {
		for (id => action in actions) {
			if (action != null) {
				var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

				for (i in 0...action.keys.length)
					if (action.keys.contains(key))
						return id;

				if (gamepad != null && action.buttons != null) {
					for (i in 0...action.buttons.length)
						if (action.buttons.contains(key))
							return id;
				}
			}
		}

		return null;
	}

	function updateGamepadEvents():Void {
		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;
		if (gamepad != null) {
			for (id => action in actions) {
				if (action.buttons != null) {
					for (key in action.buttons) {
						if (gamepad.checkStatus(key, JUST_PRESSED))
							onKeyPressed.dispatch(key, id);
						if (gamepad.checkStatus(key, JUST_RELEASED))
							onKeyReleased.dispatch(key, id);
					}
				}
			}
		}
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
		FlxG.signals.preUpdate.add(updateGamepadEvents);
	}

	public static function destroy():Void {
		self.actions = null;
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, self.onKeyDown);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, self.onKeyUp);
		FlxG.signals.preUpdate.remove(self.updateGamepadEvents);
	}
}
