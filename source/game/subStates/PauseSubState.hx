package game.subStates;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import game.MusicBeatState.MusicBeatSubState;
import game.system.Levels;
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
					MusicBeatState.switchState(new PlayState(oldConstructor));
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
							MusicBeatState.switchState(new game.menus.FreeplayMenu());
					}
				}
			}
		]
	};

	var activeList:Array<{name:String, callback:Void->Void}>;

	var pauseTexts:FlxTypedGroup<FlxText>;

	public function new():Void
	{
		super();

		options.main[2].callback = function():Void
		{
			var optionsSubState = new game.menus.OptionsMenu(true);
			optionsSubState.camera = this.camera;
			openSubState(optionsSubState);
		}

		if (Levels.DEFAULT_DIFFICULTIES.length > 1)
		{
			options.difficulties = [];

			for (i in 0...Levels.DEFAULT_DIFFICULTIES.length)
			{
				options.difficulties.push({
					name: Levels.DEFAULT_DIFFICULTIES[i].toUpperCase(),
					callback: function():Void
					{
						var oldConstructor = PlayState.self.constructor;
						MusicBeatState.switchState(new PlayState({
							songName: oldConstructor.songName,
							difficulty: Levels.DEFAULT_DIFFICULTIES[i],
							gamemode: oldConstructor.gamemode
						}));
					}
				});
			}

			options.difficulties.push({name: "BACK", callback: function():Void loadList(options.main)});
			options.main.insert(2, {name: "Difficulty", callback: function():Void loadList(options.difficulties)});
		}

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
		bg.alpha = 0;
		add(bg);

		pauseTexts = new FlxTypedGroup<FlxText>();
		add(pauseTexts);

		optionsGroup = new AlphabetGroup();
		add(optionsGroup);

		var textContents:Array<String> = [
			'-----------------',
			'Song: ${PlayState.self.song.name}',
			'Difficulty: ${PlayState.self.constructor.difficulty.toUpperCase()}',
			'-----------------',
		];

		for (i in 0...textContents.length)
		{
			var txt:FlxText = new FlxText(0, 0, 0, textContents[i]);
			txt.setFormat(AssetHandler.getAsset('data/fonts/vcr', FONT), 32, 0xFFFFFFFF, RIGHT, OUTLINE, 0xFF000000);
			txt.x = FlxG.width - txt.width - 5;
			pauseTexts.add(txt);

			txt.alpha = 0;
			FlxTween.tween(txt, {y: (26 * i) + 5, alpha: 1}, 0.6, {ease: FlxEase.circOut, startDelay: (0.3 * i)});
		}

		FlxTween.tween(bg, {alpha: 0.6}, 0.8, {ease: FlxEase.cubeOut});

		loadList(options.main);
	}

	public function loadList(list:Dynamic):Void
	{
		activeList = list;

		if (optionsGroup.length > 0)
			optionsGroup.clear();

		for (i in 0...activeList.length)
		{
			var entry:Alphabet = new Alphabet(0, (70 * i) + 30, activeList[i].name, false);
			entry.menuItem = true;
			entry.groupIndex = i;
			optionsGroup.add(entry);
		}

		curSelection = 0;
		updateSelection();
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
