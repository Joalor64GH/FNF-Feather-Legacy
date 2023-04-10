package feather.core;

import flixel.FlxG;
import flixel.util.FlxStringUtil;
import haxe.Timer;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.system.System;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.ui.Keyboard;

class FPS extends Sprite {
	public var bg:Sprite;
	public var fps:FPSField;

	#if cpp
	public var mem:MemoryField;
	#end

	var childrenFields:Array<TextField> = [];

	public function new():Void {
		super();

		bg = new Sprite();
		bg.graphics.beginFill(0);
		bg.graphics.drawRect(0, 0, 1, 50);
		bg.graphics.endFill();
		bg.alpha = 0.5;
		addChild(bg);

		fps = new FPSField();
		addField(fps);

		#if cpp
		mem = new MemoryField();
		addField(mem);
		#end

		addEventListener(Event.ENTER_FRAME, function(_:Event):Void {
			var lastField:TextField = childrenFields[childrenFields.length - 1];
			bg.scaleX = lastField.x + lastField.width + 5;
			bg.scaleY = lastField.scaleY / 1.5;
		});

		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, function(e:KeyboardEvent):Void {
			switch (e.keyCode) {
				case Keyboard.F3:
					visible = !visible;
				case Keyboard.F7:
					#if debug
					// die
					@:privateAccess
					{
						FlxG.game._requestedState = new feather.state.CrashState('FORCED CRASH', 'Commited F7', Type.getClass(FlxG.state));
						FlxG.game.switchState();
					}
					#end
			}
		});
	}

	public function addField(field:TextField):Void {
		var lastField:TextField = childrenFields[childrenFields.length - 1];
		var yAdd:Float = 10;

		field.x = 5;
		field.autoSize = LEFT;
		field.selectable = false;
		field.defaultTextFormat = new TextFormat('_sans', 14, -1);

		if (lastField != null)
			field.y = lastField.y + lastField.height + yAdd;

		childrenFields.push(field);
		addChild(field);
	}
}

class FPSField extends TextField {
	public var times:Array<Float> = [];
	public var curFPS:Float = 0;

	public function new():Void {
		super();
		addEventListener(Event.ENTER_FRAME, update);
	}

	public function update(_:Event):Void {
		var now:Float = Timer.stamp();
		times.push(now);
		while (times[0] < now - 1)
			times.shift();

		curFPS = times.length;
		if (curFPS > FlxG.updateFramerate)
			curFPS = FlxG.updateFramerate;

		if (visible)
			text = 'FPS: ${curFPS}';
	}
}

class MemoryField extends TextField {
	public var curMEM:Float = 0;
	public var peakMEM:Float = 0;

	public function new():Void {
		super();
		addEventListener(Event.ENTER_FRAME, function(_:Event):Void {
			curMEM = System.totalMemory;
			if (curMEM > peakMEM)
				peakMEM = curMEM;

			if (visible)
				text = 'RAM: ${FlxStringUtil.formatBytes(curMEM).toLowerCase()} / ${FlxStringUtil.formatBytes(peakMEM).toLowerCase()}';
		});
	}
}
