package game.subStates;

import flixel.math.FlxMath;
import game.ui.Alphabet;

class PauseSubState extends MusicBeatSubState
{
	var curSelection:Int = 0;
	var optionsGroup:AlphabetGroup;

	var options:Dynamic = {
		main: [
			{name: "Resume", callback: function():Void FlxG.state.subState.close()},
			{
				name: "Restart",
				callback: function():Void
				{
					var oldConstructor = PlayState.self.constructor;
					FlxG.switchState(new PlayState(oldConstructor));
				}
			},
			{name: "Options", callback: null},
			{
				name: "Exit",
				callback: function():Void
				{
					switch (PlayState.self.constructor.gamemode)
					{
						case STORY_MODE:
						default:
							FlxG.switchState(new game.menus.FreeplayMenu());
					}
				}
			}
		]
	};

	var activeList:Array<{name:String, callback:Void->Void}>;

	public function new():Void
	{
		super();

		activeList = options.main;

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
		bg.alpha = 0;
		add(bg);

		optionsGroup = new AlphabetGroup();
		add(optionsGroup);

		FlxTween.tween(bg, {alpha: 0.8}, 0.6, {ease: FlxEase.cubeOut});

		loadList();
		updateSelection();
	}

	public function loadList():Void
	{
		if (optionsGroup.length > 0)
			optionsGroup.clear();

		for (i in 0...activeList.length)
		{
			var entry:Alphabet = new Alphabet(0, (70 * i) + 30, activeList[i].name, false);
			entry.menuItem = true;
			entry.groupIndex = i;
			optionsGroup.add(entry);
		}
	}

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (controls.anyJustPressed(["up", "down"]))
			updateSelection(controls.justPressed("up") ? -1 : 1);

		if (controls.justPressed("accept"))
			if (activeList[curSelection].callback != null)
				activeList[curSelection].callback();
	}

	public function updateSelection(newSelection:Int = 0):Void
	{
		if (activeList != null && activeList.length > 0)
			curSelection = FlxMath.wrap(curSelection + newSelection, 0, activeList.length - 1);

		FlxG.sound.play(Paths.sound('scrollMenu'));

		var ascendingIndex:Int = 0;
		for (letter in optionsGroup)
		{
			letter.groupIndex = ascendingIndex - curSelection;
			letter.alpha = 0.6;
			if (letter.groupIndex == 0)
				letter.alpha = 1;
			++ascendingIndex;
		}
	}
}