package game.ui;

import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxMath;

class HealthIcon extends FlxSprite {
	public var sprTracker:FlxSprite;

	public var initialWidth:Float = 0;
	public var initialHeight:Float = 0;

	public var isPlayer:Bool = false;
	public var canBounce:Bool = true;

	public function new(char:String = "face", isPlayer:Bool = false, canBounce:Bool = true):Void {
		super();

		this.isPlayer = isPlayer;
		this.canBounce = canBounce;

		loadIcon(char);

		flipX = isPlayer;
		initialWidth = width;
		initialHeight = height;

		antialiasing = UserSettings.get("antialiasing") && !char.endsWith("-pixel");
		scrollFactor.set();
	}

	public function loadIcon(char:String = "face"):Void {
		var subString:String = char;
		if (char.contains('-'))
			subString = char.substring(0, char.indexOf('-'));

		if (!sys.FileSystem.exists(Paths.getPath('images/characters/${char}/icon', IMAGE)))
			char = "face";

		if (sys.FileSystem.exists(Paths.getPath('images/characters/${char}/icon', XML))) {
			frames = Paths.getSparrowAtlas('characters/${char}/icon');
			animation.addByPrefix("idle", "idle", 24, true);
			animation.addByPrefix("losing", "losing", 24, true);
			animation.addByPrefix("winning", "winning", 24, true);
		} else
			loadLegacyIcon(char);
	}

	function loadLegacyIcon(char:String = "face"):Void {
		var icon:FlxGraphic = Paths.image('characters/${char}/icon');

		var constWidth:Int = Std.int(icon.width / 150) - 1;
		constWidth = constWidth + 1;

		loadGraphic(icon); // get file size
		loadGraphic(icon, true, Std.int(icon.width / constWidth), icon.height);

		animation.add('idle', [for (i in 0...frames.frames.length) i], 0, false);
		animation.add('losing', [1], 0, false);
	}

	public dynamic function updateAnim(health:Float):Void {
		flipX = isPlayer;

		var nextAnim:String = health < 20 ? "losing" : "idle";
		if (animation.getByName(nextAnim) != null)
			animation.play(nextAnim);
	}

	override function update(elapsed:Float):Void {
		super.update(elapsed / 2);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 10, sprTracker.y - 30);

		if (canBounce) {
			scale.set(FlxMath.lerp(scale.x, 1, 0.25), FlxMath.lerp(scale.y, 1, 0.45));
			updateHitbox();
		}
	}

	public function onBeat(curBeat:Int):Void {
		scale.set(scale.x + 0.155, scale.y + 0.185);
	}
}
