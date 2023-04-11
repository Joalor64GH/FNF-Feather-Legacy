package test;

import feather.Paths;
import feather.core.handlers.HaxeUIGroup;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.ui.FlxUIState;

class HaxeUIState extends FlxUIState {
	var uiGroup:HaxeUIGroup;
	var stateBG:FlxSprite;

	override function create():Void {
		generateBackground();
		super.create();
	}

	function generateBackground():Void {
		stateBG = new FlxSprite().loadGraphic(Paths.image('menus/shared/menuDesat'));
		stateBG.setGraphicSize(Std.int(stateBG.width * 1.1));
		stateBG.updateHitbox();
		stateBG.screenCenter();
		stateBG.scrollFactor.set(0, 0);
		add(stateBG);
	}
}
