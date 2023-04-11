package feather.state;

import feather.gameObjs.ui.Alphabet;
import flixel.FlxG;
import flixel.addons.ui.FlxUIState;
import flixel.effects.FlxFlicker;
import flixel.text.FlxText;

class WarningState extends FlxUIState {
	var titleThingy:Alphabet;
	var textThingy:FlxText;

	var lockedMovement:Bool = true;

	override function create():Void {
		super.create();

		FlxG.mouse.visible = false;

		if (transIn != TransitionState.defaultTransIn) // set the transition, then play it
		{
			transIn = TransitionState.defaultTransIn;
			transOut = TransitionState.defaultTransOut;
			FlxG.resetState();
		}

		FlxG.camera.flash(0xFF000000, 0.8, function():Void lockedMovement = false);

		titleThingy = new Alphabet(0, 0, 'WARNING', false);
		titleThingy.screenCenter(XY).y -= 185;
		titleThingy.color = 0xFFFFFFFF;
		add(titleThingy);

		var warningText:String = 'This project is still in HUGE development phase\nand it\'s considered a PROTOTYPE';
		warningText += '\nBug reports and feature requests are appreciated,\nas our goal is to finish this project';
		warningText += '\nWith it containing all the essential features it needs.\n\nThank you for your patience.';
		warningText += '\n\nPress ENTER or ESCAPE to leave this screen\nand go back to the main menu.';

		textThingy = new FlxText(titleThingy.x - titleThingy.width, titleThingy.y + 110, FlxG.width, warningText);
		textThingy.setFormat(AssetHandler.getAsset('data/fonts/vcr', FONT), 32, 0xFFFFFFFF, CENTER, OUTLINE, 0xFF000000);
		textThingy.screenCenter(X);
		add(textThingy);
	}

	override function update(elapsed:Float):Void {
		super.update(elapsed);

		if (!lockedMovement)
			if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.ESCAPE)
				endWarningSequence(FlxG.keys.justPressed.ENTER);
	}

	function endWarningSequence(flickerText:Bool):Void {
		lockedMovement = true;
		if (!flickerText) {
			FlxG.sound.play(AssetHandler.getAsset('sounds/cancelMenu', SOUND));
			FlxG.camera.fade(0, 1, function():Void FlxG.switchState(new feather.state.menus.MainMenu()));
		} else {
			FlxG.sound.play(AssetHandler.getAsset('sounds/confirmMenu', SOUND));
			for (i in [titleThingy, textThingy])
				FlxFlicker.flicker(i, 1, 0.09, false, false, (flick:FlxFlicker) -> FlxG.switchState(new feather.state.menus.MainMenu()));
		}
	}
}
