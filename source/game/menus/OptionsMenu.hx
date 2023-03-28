package game.menus;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import game.subStates.MusicBeatSubState;

class OptionsMenu extends MusicBeatSubState
{
	public var pageBG:FlxSprite;
	public var pageGroup:FlxTypedGroup<FlxText>;

	public function new():Void
	{
		super();

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menus/menuBGBlue'));
		bg.screenCenter(XY);
		bg.scrollFactor.set();
		add(bg);

		pageBG = new FlxSprite().makeGraphic(Std.int(FlxG.width / 1.3), Std.int(FlxG.height / 1.1), FlxColor.BLACK);
		pageBG.screenCenter(XY);
		pageBG.alpha = 0.8;
		add(pageBG);

		// FlxTween.tween(pageBG, {alpha: 0.8}, 1);

		pageGroup = new FlxTypedGroup<FlxText>();
		add(pageGroup);
	}

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (controls.justPressed("back"))
			FlxG.switchState(new game.menus.MainMenu());
	}
}
