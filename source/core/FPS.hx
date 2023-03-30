package core;

import flixel.FlxG;
import flixel.util.FlxStringUtil;
import haxe.Timer;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.system.System;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.ui.Keyboard;

/**
	Debug Info class for displaying Framerate and Memory information on screen,
	based on this tutorial https://keyreal-code.github.io/haxecoder-tutorials/17_displaying_fps_and_memory_usage_using_openfl.html
**/
class FPS extends TextField
{
	public var times:Array<Float> = [];

	public var curFPS:Float = 0;
	public var curMEM:Float = 0;

	private final textBorder:BorderField;

	/**
	 * Creates a new instance of the FPS Counter
	 * if allowed, may also have a instance of `BorderField`, which is a outline subclass
	 * along with it
	 * @param useOutline whether to enable the fps outline border
	**/
	public function new(x:Float = 10, y:Float = 5, color:Int = -1, ?useOutline:Bool = true):Void
	{
		super();

		this.x = x;
		this.y = y;

		autoSize = LEFT;
		selectable = false;
		visible = true;

		defaultTextFormat = new TextFormat(Paths.font('vcr'), 16, color);
		text = "";

		width = FlxG.width;

		if (useOutline)
		{
			textBorder = new BorderField(this, 1.5, 0xFF000000);
			textBorder.addChildren();
		}

		addEventListener(Event.ENTER_FRAME, update);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, debugKeys);
	}

	public var separator:String = ' | ';

	public function update(_:Event):Void
	{
		var now:Float = Timer.stamp();
		times.push(now);
		while (times[0] < now - 1)
			times.shift();

		curFPS = times.length;
		if (curFPS > FlxG.updateFramerate)
			curFPS = FlxG.updateFramerate;

		text = "";
		if (visible)
		{
			text += '[FPS: ${curFPS}';
			#if cpp
			curMEM = System.totalMemory;
			text += separator + 'MEMORY: ${FlxStringUtil.formatBytes(curMEM)}';
			text += ']\n';

			text += '[STATE: ${Type.getClassName(Type.getClass(FlxG.state))}';
			text += separator + 'OBJECTS: ${FlxG.state.members.length}';
			#end

			text += ']\n';
		}
	}

	public function debugKeys(e:KeyboardEvent):Void
	{
		switch (e.keyCode)
		{
			case Keyboard.F3:
				visible = !visible;
		}
	}
}

/**
 * Code originally from sayofthelor's Lore Engine
 * https://github.com/sayofthelor/lore-engine
 *
 * changed for ease of use and more reliability
 */
class BorderField extends TextField
{
	public var parentField:TextField;
	public var children:Array<TextField> = [];

	public var size:Float = 1.5;

	/**
	 * Creates a new instance of a Border for a parent `TextField`
	 * @param parentField              the attached field to this border
	 * @param size [OPTIONAL]          the border's size, defaults to 2
	 * @param borderColor [OPTIONAL]   the border's color, defaults to black
	 */
	public function new(parentField:TextField, size:Float = 1.5, borderColor:Int = 0):Void
	{
		super();

		this.parentField = parentField;
		this.size = size;

		for (i in 0...8)
		{
			children.push(new TextField());

			copyParent(children[i]);
			children[i].textColor = borderColor;
		}

		addEventListener(Event.ENTER_FRAME, update);
	}

	public function update(_:Event):Void
	{
		if (parentField != null)
		{
			this.x = parentField.x;
			this.y = parentField.y;

			for (i in 0...children.length)
			{
				var border:TextField = children[i];
				border.text = parentField.text;
				border.visible = parentField.visible;

				if ([0, 4, 6].contains(i))
					border.x = this.x - size;
				else if ([1, 2, 4, 7].contains(i))
					border.x = this.x + size;
				else
					border.x = this.x;

				if ([0, 1, 2].contains(i))
					border.y = this.y - size;
				else if ([5, 6, 7].contains(i))
					border.y = this.y + size;
				else
					border.y = this.y;
			}
		}
	}

	public function copyParent(field:TextField):Void
	{
		if (parentField != null)
		{
			field.x = parentField.x;
			field.y = parentField.y;

			field.autoSize = parentField.autoSize;
			field.selectable = parentField.selectable;
			field.mouseEnabled = parentField.mouseEnabled;
			field.visible = parentField.visible;

			field.defaultTextFormat = parentField.defaultTextFormat;
			field.width = parentField.width;
			field.height = parentField.height;
		}
	}

	/**
	 * Adds the created border instances below the parent field on `Main.hx`
	 */
	public function addChildren():Void
	{
		for (i in 0...children.length)
			Main.self.addChild(children[i]);
	}

	/**
	 * Removes all the created border instances below the parent field on `Main.hx`
	 */
	public function killChildren():Void
	{
		for (i in 0...children.length)
			Main.self.removeChild(children[i]);
	}
}
