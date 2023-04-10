package feather.state;

import flixel.addons.ui.FlxUIState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;

class CrashState extends FlxUIState {
	var textGroup:FlxTypedGroup<FlxText>;
	var lastState:Class<Dynamic> = null;

	var _error:String;
	var _catch:String;

	var uncaughtErrorStrings:Array<String> = [
		"UNCAUGHT ERROR",
		"You died", // @sayofthelor
		"HELP WHERE AM I", // @WizardMantis441
		"TROLLED (OOPS)", // @WizardMantis441
		"FUCK", // FUCK, @sayofthelor
		"NO SEMICOLON?", // @WizardMantis441
		"DUG STRAIGHT DOWN", // @sayofthelor
		"Never gonna give you up", // @DaisyDotHX
		"GAVE YOU UP LOLOL", // @WizardMantis441
		"gonna let you down, gonna run around, and desert you", // @DaisyDotHX
		"THIS GOES OFF SCREEN THIS GOES OFF SCREEN THIS GOES OFF SCREEN THIS GOES OFF SCREEN penis", // @WizardMantis441
	];

	public function new(error:String, ?caught:String, ?lastState:Class<Dynamic>):Void {
		super();

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		_error = error;
		_catch = caught;
		this.lastState = lastState;
	}

	public override function create():Void {
		super.create();

		var leText:String = uncaughtErrorStrings[FlxG.random.int(0, uncaughtErrorStrings.length - 1)];

		if (leText == 'You died') {
			var redGradient:FlxSprite = flixel.util.FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [0xFF000000, 0xFFFF0000]);
			redGradient.alpha = 0.6;
			add(redGradient);
		}

		textGroup = new FlxTypedGroup<FlxText>();
		add(textGroup);

		var errorText:FlxText = new FlxText(0, 25, 0, '- ${leText} -', 96);
		errorText.color = 0xFFBDBDBD;
		textGroup.add(errorText);

		if (_catch != null) {
			var errorCatch:FlxText = new FlxText(0, errorText.y + errorText.height, FlxG.width, '[${_catch}]', 32);
			errorCatch.color = 0xFFBDBDBD;
			textGroup.add(errorCatch);
		}

		var errorInfo:FlxText = new FlxText(0, errorText.y + errorText.height + 100, 0, _error, 32);
		errorInfo.color = 0xFFAAAAAA;
		textGroup.add(errorInfo);

		var bindsText:FlxText = new FlxText(0, 0, 0, '[SPACE] = go to GitHub | [ESCAPE] = go Back to the Main Menu ', 32);
		bindsText.color = 0xFFFFEE80;
		bindsText.y = FlxG.height - bindsText.height - 10;
		textGroup.add(bindsText);

		var finalText:String = '';
		if (_error != 'FORCED CRASH') {
			finalText += 'Log saved at "${Main.CustomGame.logSavePath}"\n';
			finalText += 'Consider taking a Screenshot and reporting this error';
			finalText += '\nThank you for your Patience';
		} else
			finalText = 'This is a forced crash\nyou may wanna simply ignore it and move on.';

		var thxText:FlxText = new FlxText(0, bindsText.y - bindsText.height - 55, 0, finalText, 32);
		textGroup.add(thxText);

		for (text in textGroup) {
			text.setFormat(AssetHandler.getAsset('data/fonts/vcr', FONT), text.size);
			text.alignment = CENTER;
			text.screenCenter(X);
		}
	}

	public override function update(elapsed:Float):Void {
		super.update(elapsed);

		if (FlxG.keys.justPressed.SPACE)
			Utils.openURL('https://github.com/BeastlyGabi/FNF-Feather');
		if (FlxG.keys.justPressed.ESCAPE) {
			// force switching
			@:privateAccess {
				FlxG.game._requestedState = new feather.state.menus.MainMenu();
				FlxG.game.switchState();
			}
		}
	}
}
