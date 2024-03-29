package feather.gameObjs.ui;

import feather.core.FNFSprite;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;

// for menus
typedef AlphabetGroup = FlxTypedGroup<Alphabet>;

/**
 * Welcome to hell
 */
class Alphabet extends FlxSpriteGroup {
	public var bold:Bool = false;
	public var menuItem:Bool = false;

	public var groupIndex:Float = 0;

	public var text(default, set):String;

	function set_text(newText:String):String {
		text = newText;
		loadLetters(bold, size);

		return newText;
	}

	public var size:Float = 1;

	override function set_color(color:Int):Int {
		for (object in this.members)
			if (Std.isOfType(object, Letter))
				cast(object, Letter).setColor(color);

		return super.set_color(color);
	}

	public function new(x:Float = 0, y:Float = 0, text:String, bold:Bool = false, size:Float = 1):Void {
		super(x, y);

		this.bold = bold;
		this.size = size;

		// load text
		this.text = text;
	}

	var textSpaces:Int = 0;
	var storedLetters:Array<Letter> = [];

	public function loadLetters(bold:Bool, size:Float = 1):Void {
		var offsetX:Float = 0;

		for (txt in text.split("")) {
			if (txt == " " || txt == "_")
				textSpaces++;

			var letter:Bool = Letter.chars.letters.indexOf(txt.toLowerCase()) != 1;
			var number:Bool = Letter.chars.numbers.indexOf(txt.toLowerCase()) != 1;
			var symbol:Bool = Letter.chars.symbols.indexOf(txt.toLowerCase()) != 1;

			if ((letter || number || symbol) && txt.toLowerCase() != ' ') {
				var lastLetter:Letter = storedLetters[storedLetters.length - 1];
				if (lastLetter != null)
					offsetX = lastLetter.x + lastLetter.width;

				if (textSpaces > 0)
					offsetX += 40 * textSpaces;
				textSpaces = 0;

				var newLetter:Letter = new Letter(offsetX, 0, !bold, size);
				if (symbol)
					newLetter.createSym(txt);
				if (number) {
					newLetter.addAnim(txt, txt, null, 24);
					newLetter.playAnim(txt);
					newLetter.updateHitbox();
				}
				newLetter.createSprite(txt);
				add(newLetter);

				storedLetters.push(newLetter);
			}
		}
	}

	/**
	 * I owe superpowers04 for this, she"s a real one thx!!!
	 */
	public inline function clearLetters():Void {
		var sprite:FlxSprite = null;
		if (this.members.length > 0) {
			while (this.members.length > 0) {
				sprite = remove(this.members[0], true);
				if (sprite != null)
					sprite.destroy();
			}
		}

		while (storedLetters.length > 0) {
			sprite = storedLetters.pop();
			if (sprite != null)
				sprite.destroy();
		}

		textSpaces = 0;
		storedLetters = [];
	}

	public override function update(elapsed:Float):Void {
		if (menuItem) {
			// TODO: make this accurate to the framerate
			var scrollX:Float = FlxMath.lerp(x, (groupIndex * 20) + 90, 0.10);
			var remappedY:Float = FlxMath.remapToRange(groupIndex, 0, 1, 0, 1.3);
			var scrollY:Float = FlxMath.lerp(y, (remappedY * 120) + (FlxG.height * 0.48), 0.16);

			x = scrollX;
			y = scrollY;
		}

		// auto inactivity to prevent memory usage spikes when loading multiple members
		for (i in 0...members.length)
			members[i].active = groupIndex > -5 || groupIndex < 5;

		super.update(elapsed);
	}
}

class Letter extends FNFSprite {
	public static var chars:Dynamic =
		{
			letters: "abcdefghijklmnopqrstuvwxyz",
			numbers: "0123456789",
			symbols: "!@#$%&*()[]{}'`´~^.,;:/|\\?<>+-_=<>"
		};

	public var bold:Bool = false;
	public var size(default, set):Float = 1;

	public var row:Int = 0;

	function set_size(newSize:Float):Float {
		scale.set(newSize, newSize);
		return size = newSize;
	}

	public function new(x:Float, y:Float, ?bold:Bool = false, ?size:Float = 1):Void {
		super(x, y);

		frames = AssetHandler.getAsset("images/ui/default/alphabet", XML);
		antialiasing = UserSettings.get("antialiasing");
		this.bold = bold;
		this.size = size;
	}

	public function setColor(color:FlxColor):Void {
		if (bold) {
			colorTransform.redMultiplier = color.redFloat;
			colorTransform.greenMultiplier = color.greenFloat;
			colorTransform.blueMultiplier = color.blueFloat;
		} else {
			colorTransform.redOffset = color.red;
			colorTransform.greenOffset = color.green;
			colorTransform.blueOffset = color.blue;
		}
	}

	public function createSprite(char:String):Void {
		var animName:String = '';
		animName = char + " lowercase";
		if (bold)
			animName = char.toUpperCase() + " bold";
		else if (char.toLowerCase() != char)
			animName = char + " capital";

		addAnim(char, animName, null, 24);
		playAnim(char);
		updateHitbox();

		if (!bold) {
			y = (110 - height);
			y += row * 60;
		}
	}

	public function createSym(char:String):Void {
		var animName:String = switch (char) {
			case "$": "dollarsign ";
			case "<": "lessThan";
			case ">": "greaterThan";
			case ",": "comma";
			case ".": "period";
			case '"': "apostraphie";
			case "?": "question mark";
			case "!": "exclamation point";
			case "#": "hashtag ";
			default: char;
		}

		addAnim(char, animName, null, 24);
		playAnim(char);
		updateHitbox();

		y += switch (char) {
			case ".": 50;
			case "-": 25;
			case ",": 35;
			default: 0;
		}
	}
}
