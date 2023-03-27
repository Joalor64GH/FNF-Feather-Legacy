package core;

import flixel.addons.ui.FlxUIState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;

class CrashState extends FlxUIState
{
	private var textGroup:FlxTypedGroup<FlxText>;
	private var lastState:Class<Dynamic> = null;

	public function new(error:String, ?caught:String, ?lastState:Class<Dynamic>):Void
	{
		super();

		this.lastState = lastState;

		textGroup = new FlxTypedGroup<FlxText>();
		add(textGroup);

		var errorText:FlxText = new FlxText(0, 25, 0, '- UNCAUGHT ERROR -', 96);
		errorText.color = 0xFFBDBDBD;
		textGroup.add(errorText);

		if (caught != null)
		{
			var errorCatch:FlxText = new FlxText(0, errorText.y + errorText.height, Math.floor(errorText.width + 25), '[${caught}]', 32);
			errorCatch.color = 0xFFBDBDBD;
			textGroup.add(errorCatch);
		}

		var errorInfo:FlxText = new FlxText(0, errorText.y + errorText.height + 100, 0, error, 32);
		errorInfo.color = 0xFFAAAAAA;
		textGroup.add(errorInfo);

		var bindsText:FlxText = new FlxText(0, 0, 0, '[SPACE] = go to GitHub | [ESCAPE] = go Back to the Main Menu ', 32);
		bindsText.color = 0xFFFFEE80;
		bindsText.y = FlxG.height - bindsText.height - 10;
		textGroup.add(bindsText);

		var finalText:String = '';
		#if sys
		finalText += 'Log saved at "${Main.CustomGame.logSavePath}"\n';
		#end
		finalText += 'Consider taking a Screenshot and reporting this error';
		finalText += '\nThank you for your Patience';

		var thxText:FlxText = new FlxText(0, bindsText.y - bindsText.height - 55, 0, finalText, 32);
		textGroup.add(thxText);

		for (text in textGroup)
		{
			text.setFormat(AssetHandler.getAsset('data/fonts/vcr', FONT), text.size);
			text.alignment = CENTER;
			text.screenCenter(X);
		}
	}

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		// if (FlxG.keys.justPressed.SPACE)
		//	openURL('https://github.com/BeastlyGabi/FNF-Feather');
		if (FlxG.keys.justPressed.ESCAPE)
			FlxG.switchState(Type.createInstance(game.menus.MainMenu, []));
	}
}
