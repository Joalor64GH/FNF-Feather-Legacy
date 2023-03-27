package game.states.menus;

import game.ui.Alphabet;
import rhythm.LevelManager;
import rhythm.chart.ChartLoader;

using StringTools;

class FreeplayMenu extends MenuBase
{
	var currentDifficulty:Int = 0;

	public var songList:Array<ListableSong> = [];

	public override function create():Void
	{
		super.create();

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menus/menuBGBlue'));
		bg.screenCenter();
		add(bg);

		optionsGroup = new AlphabetGroup();
		add(optionsGroup);

		// get week songs and add them
		for (i in 0...LevelManager.gameWeeks.length)
		{
			var week:GameWeek = LevelManager.gameWeeks[i];
			for (i in 0...week.songs.length)
				songList.push(week.songs[i]);
		}

		songList.push({name: 'test', opponent: 'bf'});

		for (i in 0...songList.length)
		{
			var newSong:Alphabet = new Alphabet(0, (60 * i), songList[i].name);
			newSong.menuItem = true;
			newSong.groupIndex = i;
			optionsGroup.add(newSong);
		}

		updateSelection();
		updateDifficulty();
	}

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (controls.justPressed("accept"))
		{
			ChartLoader.tempLoad(songList[curSelection].name.replace('.', ''));
			var name:String = ChartLoader.getSongRawName(songList[curSelection].name);
			FlxG.switchState(new PlayState({songName: name, difficulty: LevelManager.defaultDiffs[currentDifficulty], gamemode: FREEPLAY}));
		}

		if (controls.anyJustPressed(["left", "right"]))
			updateDifficulty(controls.justPressed("left") ? -1 : 1);

		if (controls.justPressed("back"))
			FlxG.switchState(new MainMenu());
	}

	function updateDifficulty(newDifficulty:Int = 0):Void
	{
		currentDifficulty = FlxMath.wrap(currentDifficulty + newDifficulty, 0, LevelManager.defaultDiffs.length - 1);
		trace(LevelManager.defaultDiffs[currentDifficulty]);
	}
}
