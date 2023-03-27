package game.states;

import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.group.FlxGroup.FlxTypedGroup;
import game.gameplay.Character;
import game.gameplay.Highscore;
import game.gameplay.NoteHandler.BabyGroup;
import game.gameplay.NoteHandler.Note;
import game.gameplay.stage.*;
import game.states.MusicBeatState;
import game.states.editors.*;
import game.states.subStates.*;
import game.ui.GameplayUI;
import game.ui.RatingPopup;
import rhythm.Conductor;
import rhythm.chart.ChartDefs.ChartFormat;
import rhythm.chart.ChartEvents;
import rhythm.chart.ChartLoader;

using StringTools;

enum GameplayMode
{
	STORY_MODE;
	FREEPLAY;
	CHARTING;
}

typedef PlayStateStruct =
{
	var songName:String;
	var difficulty:String;
	var ?gamemode:GameplayMode;
	var ?startTime:Float;
}

/**
 * the Gameplay State, here's where most "song playing and rhythm game stuff" will actually happen
 */
class PlayState extends MusicBeatState
{
	public static var self:PlayState;

	public var constructor:PlayStateStruct;

	// Song
	public var song:ChartFormat;
	public var music:MusicPlayback;

	public var songName:String = 'test';
	public var difficulty:String = 'normal';

	// Gameplay
	public var lines:FlxTypedGroup<BabyGroup>;

	public var playerNotes:BabyGroup;
	public var opponentNotes:BabyGroup;

	public var playerStrumline:Int = 1;

	public var gameUI:GameplayUI;
	public var ratingUI:RatingPopup;
	public var currentStat:Highscore;

	// Cameras
	public var camGame:FlxCamera;
	public var camHUD:FlxCamera;

	public var camFollow:FlxObject;

	// Objects
	public var gameStage:BaseStage = null;

	public var player:Character;
	public var opponent:Character;
	public var crowd:Character;

	public function new(constructor:PlayStateStruct):Void
	{
		super();

		Utils.killMusic([FlxG.sound.music]);

		self = this;

		if (constructor != null)
		{
			this.constructor = constructor;

			if (constructor.songName != null)
			{
				if (constructor.difficulty == null)
					constructor.difficulty = 'normal';

				song = ChartLoader.loadSong(constructor.songName, constructor.difficulty);
			}

			if (constructor.gamemode == null)
				constructor.gamemode = FREEPLAY;
		}
	}

	public override function create():Void
	{
		super.create();

		music = new MusicPlayback(constructor.songName, constructor.difficulty);

		camGame = new FlxCamera();
		FlxG.cameras.reset(camGame);

		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD, false);

		FlxG.cameras.setDefaultDrawTarget(camGame, true);

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);

		camGame.follow(camFollow, LOCKON, 0.04);
		camGame.focusOn(camFollow.getPosition());

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		persistentUpdate = true;
		persistentDraw = true;

		// initialize gameplay modules
		currentStat = new Highscore();
		ratingUI = new RatingPopup();

		// create the stage
		gameStage = switch (song.metadata.stage)
		{
			/*
				case 'tank', 'military-zone': new military-zone();
				case 'schoolEvil', 'school-glitch': new SchoolGlitch();
				case 'school': new School();
				case 'mallEvil', 'red-mall': new RedMall();
				case 'mall': new Mall();
				case 'highway', 'limo': new Highway();
				case 'philly', 'philly-city': new PhillyCity();
			 */
			case 'spooky', 'haunted-house': new HauntedHouse();
			default: new Stage();
		}
		add(gameStage);

		camGame.zoom = gameStage.cameraZoom;
		camHUD.zoom = gameStage.hudZoom;

		// characters
		crowd = new Character(400, 130).loadChar("gf");
		opponent = new Character(100, 100).loadChar("dad");
		player = new Character(770, 450).loadChar("bf", true);

		add(crowd);
		add(opponent);
		add(player);

		camFollow.setPosition(opponent.getGraphicMidpoint().x, opponent.getGraphicMidpoint().y);

		// ui
		gameUI = new GameplayUI();
		addOnHUD(gameUI);

		lines = new FlxTypedGroup<BabyGroup>();
		addOnHUD(lines);

		opponentNotes = new BabyGroup(FlxG.width / 5 - FlxG.width / 7, FlxG.height - 150, true, opponent);
		lines.add(opponentNotes);

		playerNotes = new BabyGroup(FlxG.width / 3 + FlxG.width / 4, FlxG.height - 150, false, player);
		lines.add(playerNotes);

		controls.onKeyPressed.add(onKeyPress);
		controls.onKeyReleased.add(onKeyRelease);

		songCutscene();
	}

	public var inCutscene:Bool = true;

	public function songCutscene():Void
	{
		Conductor.songPosition = Conductor.beatCrochet * 16;
		startCountdown();
	}

	var showCountdown:Bool = true;
	var startedCountdown:Bool = false;

	public inline function startCountdown():Void
	{
		inCutscene = false;
		startedCountdown = true;

		if (!showCountdown)
		{
			Conductor.songPosition = -5;
			return startSong();
		}

		Conductor.songPosition = -(Conductor.beatCrochet * 5);

		gameStage.onCountdownStart();

		var countdownSprites:Array<String> = ['prepare', 'ready', 'set', 'go'];
		var countdownSounds:Array<String> = ['intro3', 'intro2', 'intro1', 'introGo'];

		for (graphic in countdownSprites)
			countdownGraphics.push(FtrAssets.getUIAsset('${graphic}'));

		for (sound in countdownSounds)
			countdownNoises.push(AssetHandler.getAsset('sounds/game/${sound}', SOUND));

		for (strum in lines)
		{
			for (i in 0...strum.babyArrows.members.length)
			{
				var startY:Float = strum.babyArrows.members[i].y;
				strum.babyArrows.members[i].alpha = 0;
				strum.babyArrows.members[i].y -= 32;

				FlxTween.tween(strum.babyArrows.members[i], {y: startY, alpha: 0.8}, (Conductor.beatCrochet * 4) / 1000,
					{ease: FlxEase.circOut, startDelay: (Conductor.beatCrochet / 1000) + ((Conductor.stepCrochet / 1000) * i)});
			}
		}

		countdown();
	}

	var countdownGraphics:Array<flixel.graphics.FlxGraphic> = [];
	var countdownNoises:Array<openfl.media.Sound> = [];

	var countdownPosition:Int = 0;
	var countdownTween:FlxTween;

	public function countdown():Void
	{
		var countdownSprite = new FlxSprite();
		countdownSprite.cameras = [camHUD];
		countdownSprite.alpha = 0;
		add(countdownSprite);

		new FlxTimer().start(Conductor.beatCrochet / 1000, (tmr:FlxTimer) ->
		{
			gameStage.onCountdownTick(countdownPosition);
			charactersDance(countdownPosition);

			if (countdownGraphics[countdownPosition] != null)
				countdownSprite.loadGraphic(countdownGraphics[countdownPosition]);
			countdownSprite.screenCenter();
			countdownSprite.alpha = 1;

			if (countdownTween != null)
				countdownTween.cancel();

			countdownTween = FlxTween.tween(countdownSprite, {alpha: 0}, 0.6, {
				onComplete: (twn:FlxTween) ->
				{
					if (tmr.loopsLeft == 0) // die
						countdownSprite.destroy();
				},
				ease: FlxEase.sineOut
			});

			if (countdownNoises[countdownPosition] != null)
				FlxG.sound.play(countdownNoises[countdownPosition]);

			countdownPosition++;
		}, 4);
	}

	var startingSong:Bool = true;

	public function startSong():Void
	{
		startingSong = false;
		gameStage.onSongStart();
		music.play(endSong);
	}

	var endingSong:Bool = false;

	public function endSong():Void
	{
		endingSong = true;
		gameStage.onSongEnd();
		music.cease();

		switch (constructor.gamemode)
		{
			case STORY_MODE:
			// placeholder
			case FREEPLAY:
				FlxG.switchState(new game.states.menus.FreeplayMenu());
			case CHARTING:
				FlxG.switchState(new game.states.editors.ChartEditor(constructor));
		}
	}

	var paused:Bool = false;
	var canPause:Bool = true;

	public override function update(elapsed:Float):Void
	{
		if (startingSong)
		{
			if (startedCountdown && !paused)
			{
				Conductor.songPosition += FlxG.elapsed * 1000;
				if (Conductor.songPosition >= 0)
					startSong();
			}
		}
		else
			Conductor.songPosition = music.inst.time;

		super.update(elapsed);

		if (canPause && controls.justPressed("pause"))
		{
			persistentUpdate = false;
			persistentDraw = true;
			paused = true;

			FlxTween.globalManager.forEach((twn:FlxTween) ->
			{
				if (twn != null && twn.active)
					twn.active = false;
			});

			FlxTimer.globalManager.forEach((tmr:FlxTimer) ->
			{
				if (tmr != null && tmr.active)
					tmr.active = false;
			});

			var pauseSubState = new PauseSubState();
			pauseSubState.camera = camHUD;
			openSubState(pauseSubState);
		}

		if (FlxG.keys.justPressed.SEVEN)
			FlxG.switchState(new ChartEditor({songName: constructor.songName, difficulty: constructor.difficulty}));

		if (song != null && !paused)
		{
			spawnNotes();
			parseEvents(ChartLoader.eventList);
			moveCamera();

			for (strum in lines)
			{
				if (strum == null)
					return;

				strum.noteSprites.forEachAlive(function(note:Note):Void
				{
					note.speed = Math.abs(song.metadata.speed);

					if (strum.cpuControlled)
					{
						if (!note.wasGoodHit && note.step <= Conductor.songPosition)
							goodNoteHit(note, strum);
					}
					else if (!playerNotes.cpuControlled) // sustain note inputs
					{
						if (notesPressed[note.index] && (note.isSustain && note.canHit && note.strumline == playerStrumline))
							goodNoteHit(note, playerNotes);
					}

					var killRangeReached:Bool = (note.downscroll ? note.y > FlxG.height : note.y < -note.height);
					if (killRangeReached || (note.isSustain && note.wasGoodHit && note.step <= Conductor.songPosition - note.hitboxEarly))
					{
						if (killRangeReached && note.strumline == playerStrumline && !note.ignorable)
							noteMiss(note.index, strum);

						killNote(note, strum);
					}
				});
			}
		}
	}

	public override function openSubState(SubState:flixel.FlxSubState):Void
	{
		if (paused)
			music.pause();

		super.openSubState(SubState);
	}

	public override function closeSubState():Void
	{
		if (paused)
		{
			music.resyncVocals();

			FlxTween.globalManager.forEach((twn:FlxTween) ->
			{
				if (twn != null && !twn.active)
					twn.active = true;
			});

			FlxTimer.globalManager.forEach((tmr:FlxTimer) ->
			{
				if (tmr != null && !tmr.active)
					tmr.active = true;
			});

			paused = false;
		}
		super.closeSubState();
	}

	public override function beatHit():Void
	{
		super.beatHit();

		charactersDance(curBeat);
		gameStage.onBeat(curBeat);

		// gameStage.onEventDispatch(event, args);
	}

	public override function stepHit():Void
	{
		super.stepHit();

		gameStage.onStep(curStep);
		music.resyncFunction();
	}

	public override function secHit():Void
	{
		super.secHit();
		gameStage.onSec(curSec);
	}

	public function charactersDance(curBeat:Int):Void
	{
		for (strum in lines)
		{
			if (curBeat % strum.character.headSpeed == 0)
				if (!strum.character.isSinging() && !strum.character.isMissing() && !strum.character.stunned)
					strum.character.dance();
		}

		if (crowd != null)
		{
			if (curBeat % crowd.headSpeed == 0)
				if (!crowd.isSinging() && !crowd.isMissing() && !crowd.stunned)
					crowd.dance();
		}
	}

	public function parseEvents(list:Array<EventLine>, stepDelay:Float = 0):Void
	{
		if (list != null && list.length > 0)
		{
			var event:EventLine = list[curSec];

			if (event != null)
				if ((event.type == Stepper && event.step >= Conductor.songPosition - stepDelay) || event.type != Stepper)
					eventTrigger(event);

			// list.shift();
		}
	}

	public function eventTrigger(event:EventLine):Void
	{
		switch (event.name)
		{
			default:
		}
	}

	public function moveCamera():Void
	{
		var char:Character = opponent;

		if (song.sections[curSec] != null)
		{
			if (song.sections[curSec].camPoint == 2 && crowd != null)
				char = crowd;
			else
				char = (song.sections[curSec].camPoint == 1) ? player : opponent;

			if (camFollow.x != char.getMidpoint().x - 100)
				camFollow.setPosition(char.getMidpoint().x - 100 + char.cameraOffset[0], char.getMidpoint().y - 100 + char.cameraOffset[1]);
		}
	}

	public function spawnNotes():Void
	{
		while (ChartLoader.noteList[0] != null && ChartLoader.noteList[0].step - Conductor.songPosition < 2000)
		{
			var note = ChartLoader.noteList[0];

			var type:String = 'default';
			if (note.type != null)
				type = note.type;

			// "but if the default strumline is 0 why didn't you export the number in the first place?"
			// less characters on the json file, that's all
			if (note.strumline == null || note.strumline < 0)
				note.strumline = 0;

			var strum:BabyGroup = lines.members[note.strumline];

			var newNote:Note = new Note(note.step, note.index, false, type);
			newNote.sustainTime = note.sustainTime;
			newNote.strumline = note.strumline;

			strum.noteSprites.add(newNote);

			if (note.sustainTime > 0)
			{
				for (noteSustain in 0...Math.floor(note.sustainTime / Conductor.stepCrochet))
				{
					var sustainStep:Float = note.step + (Conductor.stepCrochet * Math.floor(noteSustain)) + Conductor.stepCrochet;
					var newSustain:Note = new Note(sustainStep, note.index, true, type, strum.noteSprites.members[strum.noteSprites.members.length - 1]);
					newSustain.strumline = note.strumline;

					strum.noteSprites.add(newSustain);
				}
			}

			ChartLoader.noteList.shift();
		}
	}

	public function killNote(note:Note, strum:BabyGroup):Void
	{
		if (note == null)
			return;

		note.kill();
		note.destroy();
		strum.noteSprites.remove(note, true);
	}

	public function goodNoteHit(note:Note, strum:BabyGroup):Void
	{
		if (!note.wasGoodHit)
		{
			note.wasGoodHit = true;
			strum.playAnim('confirm', note.index, true);

			var animName:String = 'sing${strum.directions[note.index].toUpperCase()}${strum.character.suffix}';
			if (song.sections[curSec] != null && song.sections[curSec].animation != null)
			{
				// suffix check
				if (song.sections[curSec].animation.startsWith('-'))
					strum.character.suffix = song.sections[curSec].animation;
				else
					animName = song.sections[curSec].animation;
			}

			strum.character.playAnim(animName, true);
			strum.character.holdTimer = 0;

			var rating:String = 'sick';
			if (!note.isSustain)
			{
				if (!strum.cpuControlled)
				{
					currentStat.notesHit++;
					if (currentStat.combo < 0)
						currentStat.combo = 0;
					currentStat.combo++;

					rating = currentStat.judgeNote(note.step);
					currentStat.gottenRatings.set(rating, currentStat.gottenRatings.get(rating) + 1);
					ratingUI.popRating(rating);

					/*
						if (rating == 'sick' || note.doSplash)
							strum.doSplash(note.index);
					 */

					gameUI.updateScore();
				}

				killNote(note, strum);
			}
		}
	}

	public var notesPressed:Array<Bool> = [];

	public function onKeyPress(key:Int, action:String):Void
	{
		if (playerNotes.cpuControlled || paused || !startedCountdown)
			return;

		if (action != null && playerNotes.directions.contains(action))
		{
			var index:Int = playerNotes.directions.indexOf(action);
			notesPressed[index] = true;

			var dumbNotes:Array<Note> = [];
			var possibleNotes:Array<Note> = [];

			playerNotes.noteSprites.forEachAlive(function(note:Note):Void
			{
				if (note.canHit && note.strumline == playerStrumline && !note.wasGoodHit && !note.isSustain)
				{
					if (note.index == index)
						possibleNotes.push(note);
				}
			});
			possibleNotes.sort((a:Note, b:Note) -> Std.int(a.step - b.step));

			if (possibleNotes.length > 0)
			{
				var canBeHit:Bool = true;
				for (note in possibleNotes)
				{
					for (dumbNote in dumbNotes)
					{
						// "dumb" notes are doubles
						if (Math.abs(note.step - dumbNote.step) < 10)
							killNote(dumbNote, playerNotes);
						else
							canBeHit = false;
					}

					if (canBeHit)
					{
						goodNoteHit(note, playerNotes);
						dumbNotes.push(note);
					}
				}
			}
			else
			{
				// if (theSilly)
				// noteMiss(index, playerNotes);
			}

			if (!playerNotes.currentAnim('confirm', playerNotes.directions.indexOf(action)))
				playerNotes.playAnim('pressed', playerNotes.directions.indexOf(action));
		}
	}

	public function noteMiss(direction:Int = 0, ?strum:BabyGroup):Void
	{
		if (currentStat.combo < 0)
			currentStat.combo = 0;
		else
		{
			if (currentStat.combo > 1)
				currentStat.breaks++;

			// miss combo numbers
			currentStat.combo--;
		}

		currentStat.misses++;
		FlxG.sound.play(AssetHandler.getAsset('sounds/game/miss' + FlxG.random.int(1, 3), SOUND), FlxG.random.float(0.3, 0.6));

		var animName:String = 'sing${strum.directions[direction].toUpperCase()}miss${strum.character.suffix}';
		if (song.sections[curSec] != null && song.sections[curSec].animation != null)
		{
			// suffix check
			if (song.sections[curSec].animation.startsWith('-'))
				strum.character.suffix = song.sections[curSec].animation;
			else
				animName = song.sections[curSec].animation + 'miss';
		}
		strum.character.playAnim(animName, true);

		currentStat.updateRatings(4);
		ratingUI.popRating('miss');
		gameUI.updateScore();
	}

	public function onKeyRelease(key:Int, action:String):Void
	{
		if (playerNotes.cpuControlled || paused || !startedCountdown)
			return;

		if (action != null && playerNotes.directions.contains(action))
		{
			var index:Int = playerNotes.directions.indexOf(action);
			notesPressed[index] = false;

			playerNotes.playAnim('static', playerNotes.directions.indexOf(action));

			if (player.holdTimer > Conductor.stepCrochet * player.singDuration * 0.001 && !notesPressed.contains(true))
				if (player.isSinging() && !player.isMissing())
					player.dance();
		}
	}

	public function addOnHUD(object:flixel.FlxBasic):Void
	{
		object.camera = camHUD;
		add(object);
	}

	public override function destroy():Void
	{
		controls.onKeyPressed.remove(onKeyPress);
		controls.onKeyReleased.remove(onKeyRelease);

		super.destroy();
	}
}
