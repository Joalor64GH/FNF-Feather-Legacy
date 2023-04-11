package feather.state.menus;

import feather.core.Highscore;
import feather.core.music.ChartLoader;
import feather.core.music.Levels;
import feather.gameObjs.ui.Alphabet;
import feather.gameObjs.ui.HealthIcon;
import feather.state.PlayState.PlayStateStruct;
import feather.state.editors.ChartEditor;
import flixel.effects.FlxFlicker;
import flixel.text.FlxText;
import sys.FileSystem;
#if target.threaded
import sys.thread.Thread;
#end

class FreeplayMenu extends MenuBase {
	static var lastSelection:Int = -1;

	var bg:FlxSprite;
	var curDifficulty:Int = 1;

	var songList:Array<ListableSong> = [];
	var iconList:Array<HealthIcon> = [];

	// ui objects
	var scoreBG:FlxSprite;
	var scoreText:FlxText;
	var infoText:FlxText;

	// highscore variables
	var scoreLerp:Float = 0;
	var gottenScore:Int = 0;

	#if target.threaded
	public var mutex:sys.thread.Mutex;
	#end

	public override function create():Void {
		super.create();

		#if target.threaded
		mutex = new sys.thread.Mutex();
		#end

		#if DISCORD_ENABLED
		DiscordHandler.updateInfo('In the Menus', 'FREEPLAY MENU');
		#end

		// get week songs and add them
		for (i in 0...Levels.GAME_LEVELS.length) {
			var week:GameWeek = Levels.GAME_LEVELS[i];
			for (i in 0...week.songs.length)
				if (!songList.contains(week.songs[i]))
					songList.push(week.songs[i]);
		}

		for (folder in FileSystem.readDirectory(AssetHandler.getPath("data/songs", true))) {
			var path:String = 'data/songs/${folder}/freeplay';
			if (FileSystem.exists(AssetHandler.getPath(path, YAML))) {
				var data:ListableSong = cast yaml.Yaml.parse(AssetHandler.getAsset(path, YAML, true), yaml.Parser.options().useObjects());
				data.color = FlxColor.fromString(Std.string(data.color));
				if (!songList.contains(data))
					songList.push(data);
			}
		}

		#if MODDING_ENABLED
		for (i in 0...feather.core.data.ModHandler.activeMods.length) {
			var modName:String = feather.core.data.ModHandler.activeMods[i].folder;
			if (FileSystem.exists(feather.core.data.ModHandler.getFromMod(modName, 'data/songs'))) {
				for (modFolder in FileSystem.readDirectory(feather.core.data.ModHandler.getFromMod(modName, 'data/songs'))) {
					var path:String = 'data/songs/${modFolder}/freeplay';
					if (FileSystem.exists(feather.core.data.ModHandler.getFromMod(modName, path, YAML))) {
						var data:ListableSong = cast yaml.Yaml.parse(sys.io.File.getContent(feather.core.data.ModHandler.getFromMod(modName, path, YAML)),
							yaml.Parser.options().useObjects());
						data.color = FlxColor.fromString(Std.string(data.color));
						if (!songList.contains(data))
							songList.push(data);
					}
				}
			}
		}
		#end

		bg = new FlxSprite().loadGraphic(Paths.image('menus/shared/menuDesat'));
		bg.color = 0xFFFFFFFF;
		bg.screenCenter();
		add(bg);

		optionsGroup = new AlphabetGroup();
		for (i in 0...songList.length) {
			var newSong:Alphabet = new Alphabet(0, (60 * i), songList[i].name);
			newSong.menuItem = true;
			newSong.groupIndex = i;
			optionsGroup.add(newSong);

			var songIcon:HealthIcon = new HealthIcon(songList[i].enemy);
			songIcon.canBounce = false;
			songIcon.sprTracker = newSong;
			songIcon.ID = i;

			iconList.push(songIcon);
			add(songIcon);
		}
		add(optionsGroup);

		// create ui
		scoreText = new FlxText(0, 5, 0, "", 32);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);

		infoText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		scoreBG = new FlxSprite(scoreText.x - 6).makeGraphic(1, 66, 0x99000000);
		infoText.font = scoreText.font;

		add(scoreBG);
		add(scoreText);
		add(infoText);

		if (lastSelection > 0 && lastSelection < songList.length) {
			curSelection = lastSelection;
			// reset
			lastSelection = -1;
		}

		updateSelection();
		updateDifficulty();
	}

	public override function update(elapsed:Float):Void {
		super.update(elapsed);

		scoreLerp = FlxMath.lerp(scoreLerp, gottenScore, 0.4);
		scoreText.text = "PERSONAL BEST:" + Math.round(scoreLerp);

		updateScorePosition();

		if (controls.justPressed("accept")) {
			var parameters:PlayStateStruct =
				{
					songName: Utils.removeForbidden(songList[curSelection].name),
					difficulty: Levels.DEFAULT_DIFFICULTIES[curDifficulty],
					gamemode: FREEPLAY
				};

			if (FlxG.sound.music != null)
				FlxG.sound.music.stop();
			playbackActive = false;

			if (FlxG.keys.pressed.SHIFT)
				MusicBeatState.switchState(new ChartEditor(parameters));
			else {
				FlxG.sound.play(Paths.sound("confirmMenu"));
				FlxFlicker.flicker(optionsGroup.members[curSelection], 0.5, true, false,
					(flick:FlxFlicker) -> MusicBeatState.switchState(new PlayState(parameters)));
			}
		}

		if (controls.anyJustPressed(["left", "right"]))
			updateDifficulty(controls.justPressed("left") ? -1 : 1);

		if (controls.justPressed("back")) {
			if (!FlxG.keys.pressed.SHIFT) {
				if (FlxG.sound.music != null)
					FlxG.sound.music.stop();
			}
			playbackActive = false;

			FlxG.sound.play(Paths.sound("cancelMenu"));
			MusicBeatState.switchState(new MainMenu());
		}
	}

	public var colorTween:FlxTween;

	public override function updateSelection(newSelection:Int = 0):Void {
		super.updateSelection(newSelection);

		if (colorTween != null)
			colorTween.cancel();

		colorTween = FlxTween.color(bg, 0.8, bg.color, songList[curSelection].color);

		if (!chagingConst)
			updateSongPlayback();

		for (i in 0...iconList.length) {
			iconList[i].alpha = 0.6;
			if (iconList[i].ID == curSelection)
				iconList[i].alpha = 1;
		}

		gottenScore = Highscore.getScore(Utils.removeForbidden(songList[curSelection].name), Levels.DEFAULT_DIFFICULTIES[curDifficulty]);
		lastSelection = curSelection;
	}

	public function updateDifficulty(newDifficulty:Int = 0):Void {
		curDifficulty = FlxMath.wrap(curDifficulty + newDifficulty, 0, Levels.DEFAULT_DIFFICULTIES.length - 1);
		FlxG.sound.play(Paths.sound('scrollMenu'));

		gottenScore = Highscore.getScore(Utils.removeForbidden(songList[curSelection].name), Levels.DEFAULT_DIFFICULTIES[curDifficulty]);
		updateInfoText();
	}

	function updateScorePosition():Void {
		scoreText.x = FlxG.width - scoreText.width - 6;
		scoreBG.scale.x = FlxG.width - scoreText.x + 6;
		scoreBG.x = FlxG.width - scoreBG.scale.x / 2;

		infoText.x = Std.int(scoreBG.x + scoreBG.width / 2);
		infoText.x -= (infoText.width / 2);
	}

	function updateInfoText():Void {
		var diffText:String = Levels.DEFAULT_DIFFICULTIES[curDifficulty].toUpperCase();

		if (infoText != null)
			infoText.text = '< ${diffText} >';
	}

	var playbackActive:Bool = true;
	var playbackThread:Thread;

	function updateSongPlayback():Void {
		#if target.threaded // you won't be able to hear a different song if you can't use threads
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		playbackThread = Thread.create(function():Void {
			while (playbackActive) {
				var curThread:Null<Int> = Thread.readMessage(false);
				if (curThread != null) {
					if (curThread == curSelection && playbackActive) {
						mutex.acquire();
						FlxG.sound.playMusic(Paths.inst(Utils.removeForbidden(songList[curSelection].name)));
						// FlxG.sound.music.fadeIn(0.8);
						mutex.release();
					}
				}
			}
		});

		playbackThread.sendMessage(curSelection);
		#end
	}
}
