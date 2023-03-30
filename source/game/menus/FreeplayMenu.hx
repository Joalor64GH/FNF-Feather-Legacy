package game.menus;

import flixel.text.FlxText;
import game.gameplay.Highscore;
import game.system.Levels;
import game.system.charting.ChartLoader;
import game.ui.Alphabet;
import game.ui.HealthIcon;
#if sys
import flixel.system.FlxSound;
import game.system.music.Conductor;
import sys.thread.Mutex;
import sys.thread.Thread;
#end

class FreeplayMenu extends MenuBase
{
	static var lastSelection:Int = -1;

	var iconList:Array<HealthIcon> = [];

	var bg:FlxSprite;
	var curDifficulty:Int = 1;
	var songList:Array<ListableSong> = [];

	// ui objects
	var scoreBG:FlxSprite;
	var scoreText:FlxText;
	var infoText:FlxText;

	// highscore variables
	var scoreLerp:Float = 0;
	var gottenScore:Int = 0;

	#if sys
	public var mutex:Mutex;
	public var inst:FlxSound = new FlxSound();
	#end

	public override function create():Void
	{
		super.create();

		#if sys
		mutex = new Mutex();
		#end

		// get week songs and add them
		for (i in 0...Levels.GAME_LEVELS.length)
		{
			var week:GameWeek = Levels.GAME_LEVELS[i];
			for (i in 0...week.songs.length)
			{
				if (week.songs[i].color == null)
					week.songs[i].color = 0xFFFFFFFF;
				songList.push(week.songs[i]);
			}
		}

		songList.push({name: 'test', opponent: 'bf', color: 0xFFFFFFFF});

		bg = new FlxSprite().loadGraphic(Paths.image('menus/shared/menuDesat'));
		bg.color = 0xFFFFFFFF;
		bg.screenCenter();
		add(bg);

		optionsGroup = new AlphabetGroup();
		for (i in 0...songList.length)
		{
			var newSong:Alphabet = new Alphabet(0, (60 * i), songList[i].name);
			newSong.menuItem = true;
			newSong.groupIndex = i;
			optionsGroup.add(newSong);

			var songIcon:HealthIcon = new HealthIcon("bf");
			songIcon.sprTracker = newSong;
			songIcon.ID = i;

			iconList.push(songIcon);
			add(songIcon);
		}
		add(optionsGroup);

		// create ui
		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
		scoreBG = new FlxSprite(scoreText.x - 6).makeGraphic(1, 66, 0x99000000);

		infoText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		infoText.font = scoreText.font;

		add(scoreBG);
		add(scoreText);
		add(infoText);

		if (lastSelection > 0 && lastSelection < songList.length)
		{
			curSelection = lastSelection;
			// reset
			lastSelection = -1;
		}

		updateSelection();
		updateDifficulty();
	}

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		scoreLerp = FlxMath.lerp(scoreLerp, gottenScore, 0.4);
		scoreText.text = "PERSONAL BEST:" + Math.round(scoreLerp);

		updateScorePosition();

		if (controls.justPressed("accept"))
		{
			if (FlxG.sound.music != null)
				FlxG.sound.music.stop();

			FlxG.switchState(new PlayState({
				songName: Utils.removeForbidden(songList[curSelection].name),
				difficulty: Levels.DEFAULT_DIFFICULTIES[curDifficulty],
				gamemode: FREEPLAY
			}));
		}

		if (controls.anyJustPressed(["left", "right"]))
			updateDifficulty(controls.justPressed("left") ? -1 : 1);

		if (controls.justPressed("back"))
		{
			if (FlxG.sound.music != null)
				FlxG.sound.music.stop();

			FlxG.sound.play(Paths.sound("cancelMenu"));
			FlxG.switchState(new MainMenu());
		}
	}

	public var colorTween:FlxTween;

	public override function updateSelection(newSelection:Int = 0):Void
	{
		super.updateSelection(newSelection);

		if (colorTween != null)
			colorTween.cancel();

		colorTween = FlxTween.color(bg, 0.8, bg.color, songList[curSelection].color);

		if (!chagingConst)
			updateSongPlayback();

		for (i in 0...iconList.length)
		{
			iconList[i].alpha = 0.6;
			if (iconList[i].ID == curSelection)
				iconList[i].alpha = 1;
		}

		gottenScore = Highscore.getScore(Utils.removeForbidden(songList[curSelection].name), Levels.DEFAULT_DIFFICULTIES[curDifficulty]);
		lastSelection = curSelection;
	}

	public function updateDifficulty(newDifficulty:Int = 0):Void
	{
		curDifficulty = FlxMath.wrap(curDifficulty + newDifficulty, 0, Levels.DEFAULT_DIFFICULTIES.length - 1);
		FlxG.sound.play(Paths.sound('scrollMenu'));

		gottenScore = Highscore.getScore(Utils.removeForbidden(songList[curSelection].name), Levels.DEFAULT_DIFFICULTIES[curDifficulty]);
		updateInfoText();
	}

	function updateSongPlayback():Void
	{
		#if sys
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		Thread.create(function():Void
		{
			mutex.acquire();
			FlxG.sound.playMusic(Paths.inst(Utils.removeForbidden(songList[curSelection].name)));
			FlxG.sound.music.fadeIn(0.8);
			mutex.release();
		});
		#end
	}

	function updateScorePosition():Void
	{
		scoreText.x = FlxG.width - scoreText.width - 6;
		scoreBG.scale.x = FlxG.width - scoreText.x + 6;
		scoreBG.x = FlxG.width - scoreBG.scale.x / 2;

		infoText.x = Std.int(scoreBG.x + scoreBG.width / 2);
		infoText.x -= (infoText.width / 2);
	}

	function updateInfoText():Void
	{
		var diffText:String = Levels.DEFAULT_DIFFICULTIES[curDifficulty].toUpperCase();

		if (infoText != null)
			infoText.text = '< ${diffText} >';
	}
}
