package game;

import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.group.FlxGroup.FlxTypedGroup;
import game.editors.*;
import game.gameplay.*;
import game.gameplay.Highscore.Rating;
import game.stage.*;
import game.subStates.*;
import game.system.charting.ChartDefs.ChartFormat;
import game.system.charting.ChartEvents;
import game.system.charting.ChartLoader;
import game.system.Conductor;
import game.ui.GameplayUI;
import game.ui.RatingPopup;

enum GameplayMode {
	STORY_MODE;
	FREEPLAY;
	CHARTING;
}

typedef PlayStateStruct = {
	var ?songName:String;
	var ?difficulty:String;
	var ?songData:ChartFormat;
	var ?gamemode:GameplayMode;
	var ?startTime:Float;
}

/**
 * the Gameplay State, here's where most "song playing and rhythm game stuff" will actually happen
 */
class PlayState extends MusicBeatState {
	public static var self:PlayState;

	public var constructor:PlayStateStruct;

	// Song
	public var song:ChartFormat;
	public var music:MusicPlayback;

	public var songName:String = 'test';
	public var difficulty:String = 'normal';

	// Gameplay
	public var lines:FlxTypedGroup<NoteGroup>;

	public var playerStrumline:Int = 1;
	public var playerStrums(get, never):NoteGroup;

	@:keep inline function get_playerStrums():NoteGroup
		return lines.members[playerStrumline];

	public var gameUI:GameplayUI;
	public var ratingUI:RatingPopup;
	public var currentStat:Highscore;

	// Cameras
	public var camGame:FlxCamera;
	public var camHUD:FlxCamera;
	public var camOver:FlxCamera;

	public var camFollow:FlxObject;

	// Objects
	public var gameStage:BaseStage = null;

	public var player:Character;
	public var opponent:Character;
	public var crowd:Character;

	public function new(?constructor:PlayStateStruct):Void {
		super();

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		self = this;

		if (constructor != null) {
			this.constructor = constructor;

			if (constructor.songName != null) {
				if (constructor.difficulty == null)
					constructor.difficulty = 'normal';

				if (song == null) {
					if (constructor.songData != null)
						song = constructor.songData;
					else
						song = ChartLoader.loadSong(constructor.songName, constructor.difficulty);
				}

				if (song.metadata.strumlines == 1)
					playerStrumline = 0;
			}

			if (constructor.gamemode == null)
				constructor.gamemode = FREEPLAY;
		}
	}

	public override function create():Void {
		super.create();

		// initialize modules
		currentStat = new Highscore();
		music = new MusicPlayback(constructor.songName, constructor.difficulty);

		camGame = new FlxCamera();
		FlxG.cameras.reset(camGame);

		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD, false);

		camOver = new FlxCamera();
		camOver.bgColor.alpha = 0;
		FlxG.cameras.add(camOver, false);

		FlxG.cameras.setDefaultDrawTarget(camGame, true);
		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);

		persistentUpdate = persistentDraw = true;

		// parse haxe scripts that exist within the folders
		for (i in AssetHandler.getExtensionsFor(SCRIPT)) {
			if (sys.FileSystem.exists(AssetHandler.getPath("data/scripts"))) {
				for (script in sys.FileSystem.readDirectory(AssetHandler.getPath("data/scripts")))
					if (script != null && script.contains('.') && script.endsWith(i))
						globals.push(new ScriptHandler(AssetHandler.getAsset('data/scripts/${script}')));
			}

			for (songScript in sys.FileSystem.readDirectory(AssetHandler.getPath('data/songs/${song.name}')))
				if (songScript != null && songScript.contains('.') && songScript.endsWith(i))
					globals.push(new ScriptHandler(AssetHandler.getAsset('data/songs/${song.name}/${songScript}')));
		}

		callFn("create", [false]);

		setVar("curBeat", curBeat);
		setVar("curStep", curStep);
		setVar("curSec", curSec);

		// create the stage
		gameStage = switch (song.metadata.stage) {
			/*
				case 'military-zone': new military-zone();
				case 'school-glitch': new SchoolGlitch();
				case 'school': new School();
				case 'red-mall': new RedMall();
				case 'mall': new Mall();
				case 'highway': new Highway();
			 */
			case 'philly-city': new PhillyCity();
			case 'haunted-house': new HauntedHouse();
			default: new Stage();
		}
		add(gameStage);

		camGame.zoom = gameStage.cameraZoom;
		camHUD.zoom = gameStage.hudZoom;

		// characters
		if (gameStage.displayCrowd)
			crowd = new Character(400 + gameStage.crowdOffset.x, 130 + gameStage.crowdOffset.y).loadChar(song.metadata.crowd);

		opponent = new Character(100 + gameStage.opponentOffset.x, 100 + gameStage.opponentOffset.y).loadChar(song.metadata.opponent);
		player = new Character(770 + gameStage.playerOffset.x, 450 + gameStage.playerOffset.y).loadChar(song.metadata.player, true);

		if (crowd != null) {
			if (song.metadata.opponent == song.metadata.crowd) {
				crowd.visible = false;
				opponent.setPosition(crowd.x, crowd.y);
			}
			add(crowd);
		}

		add(opponent);
		add(player);

		camFollow.setPosition(Math.floor(opponent.getMidpoint().x + FlxG.width / 4), Math.floor(opponent.getGraphicMidpoint().y - FlxG.height / 2));

		camGame.follow(camFollow, LOCKON, 0.04);
		camGame.focusOn(camFollow.getPosition());

		moveCamera();

		// ui
		gameUI = new GameplayUI();
		addOnHUD(gameUI);

		lines = new FlxTypedGroup<NoteGroup>();
		addOnHUD(lines);

		ratingUI = new RatingPopup();

		for (i in 0...song.metadata.strumlines) {
			var isPlayer:Bool = i == playerStrumline;
			var spacing:Float = 160 * 0.7;

			var strumInitDist:Float = FlxG.width / 10;
			var strumDistance:Float = FlxG.width / 2 * i;
			if (song.metadata.strumlines == 1 || isPlayer && Settings.get("centerScroll")) {
				strumInitDist = FlxG.width / 4;
				strumDistance = 115;
			}

			var xPos:Float = (strumInitDist) + strumDistance;
			var yPos:Float = Settings.get("scrollType") == "DOWN" ? FlxG.height - 150 : 60;
			var character:Character = switch (i) {
				case 1: player;
				default: opponent;
			};

			if (i == 0 && song.metadata.strumlines > 1)
				xPos -= 60;

			var newStrumline:NoteGroup = new NoteGroup(xPos, yPos, character, spacing);
			newStrumline.cpuControlled = !isPlayer;
			if (Settings.get("centerScroll"))
				newStrumline.visible = isPlayer;
			lines.add(newStrumline);
		}

		controls.onKeyPressed.add(onKeyPress);
		controls.onKeyReleased.add(onKeyRelease);

		callFn("create", [true]);

		songCutscene();

		TransitionState.nextStateCamera = camOver;
	}

	public var inCutscene:Bool = true;

	public function songCutscene():Void {
		Conductor.songPosition = Conductor.beatCrochet * 16;
		startCountdown();
	}

	var showCountdown:Bool = true;
	var startedCountdown:Bool = false;

	public inline function startCountdown():Void {
		inCutscene = false;
		startedCountdown = true;

		if (!showCountdown) {
			Conductor.songPosition = -5;
			return startSong();
		}

		Conductor.songPosition = -(Conductor.beatCrochet * 5);

		gameStage.onCountdownStart();

		var countdownSprites:Array<String> = ['prepare', 'ready', 'set', 'go'];
		var countdownSounds:Array<String> = ['intro3', 'intro2', 'intro1', 'introGo'];

		for (graphic in countdownSprites)
			countdownGraphics.push(Utils.getUIAsset('${graphic}'));

		for (sound in countdownSounds)
			countdownNoises.push(AssetHandler.getAsset('sounds/game/${sound}', SOUND));

		for (strum in lines) {
			for (i in 0...strum.babyArrows.members.length) {
				var startY:Float = strum.babyArrows.members[i].y;
				strum.babyArrows.members[i].alpha = 0;
				strum.babyArrows.members[i].y -= 32;

				FlxTween.tween(strum.babyArrows.members[i], {y: startY, alpha: 1}, (Conductor.beatCrochet * 4) / 1000,
					{ease: FlxEase.circOut, startDelay: (Conductor.beatCrochet / 1000) + ((Conductor.stepCrochet / 1000) * i)});
			}
		}

		countdown();
	}

	var countdownGraphics:Array<flixel.graphics.FlxGraphic> = [];
	var countdownNoises:Array<openfl.media.Sound> = [];

	var countdownPosition:Int = 0;
	var countdownTween:FlxTween;

	public function countdown():Void {
		var countdownSprite = new FlxSprite();
		countdownSprite.cameras = [camHUD];
		countdownSprite.alpha = 0;
		add(countdownSprite);

		new FlxTimer().start(Conductor.beatCrochet / 1000, (tmr:FlxTimer) -> {
			gameStage.onCountdownTick(countdownPosition);
			charactersDance(countdownPosition);

			if (countdownGraphics[countdownPosition] != null)
				countdownSprite.loadGraphic(countdownGraphics[countdownPosition]);
			countdownSprite.screenCenter();
			countdownSprite.alpha = 1;

			if (countdownTween != null)
				countdownTween.cancel();

			countdownTween = FlxTween.tween(countdownSprite, {alpha: 0}, 0.6, {
				onComplete: (twn:FlxTween) -> {
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

	public function startSong():Void {
		startingSong = false;
		gameStage.onSongStart();
		music.play(endSong);
	}

	var endingSong:Bool = false;

	public function endSong():Void {
		endingSong = true;
		gameStage.onSongEnd();
		music.cease();

		switch (constructor.gamemode) {
			case STORY_MODE:
			// placeholder
			case FREEPLAY:
				Highscore.saveScore(Utils.removeForbidden(constructor.songName), constructor.difficulty, currentStat.score);
				FlxG.switchState(new game.menus.FreeplayMenu());
			case CHARTING:
				FlxG.switchState(new game.editors.ChartEditor(constructor));
		}
	}

	var paused:Bool = false;

	public var canPause:Bool = true;

	public override function update(elapsed:Float):Void {
		callFn("update", [elapsed, false]);

		if (startingSong) {
			if (startedCountdown && !paused) {
				Conductor.songPosition += FlxG.elapsed * 1000;
				if (Conductor.songPosition >= 0)
					startSong();
			}
		} else
			Conductor.songPosition = music.inst.time;

		super.update(elapsed);

		if (canPause && controls.justPressed("pause")) {
			persistentUpdate = false;
			persistentDraw = true;
			paused = true;

			gameStage.onPauseDispatch(true);

			FlxTween.globalManager.forEach((twn:FlxTween) -> {
				if (twn != null && twn.active)
					twn.active = false;
			});

			FlxTimer.globalManager.forEach((tmr:FlxTimer) -> {
				if (tmr != null && tmr.active)
					tmr.active = false;
			});

			var pauseSubState = new PauseSubState();
			pauseSubState.camera = camOver;
			openSubState(pauseSubState);
		}

		if (FlxG.keys.justPressed.SIX) {
			playerStrums.cpuControlled = !playerStrums.cpuControlled;
			gameUI.cpuText.visible = playerStrums.cpuControlled;
		}

		if (FlxG.keys.justPressed.SEVEN) {
			music.cease();
			FlxG.switchState(new ChartEditor({songName: constructor.songName, difficulty: constructor.difficulty}));
		}

		#if debug
		if (FlxG.keys.justPressed.EIGHT) {
			music.cease();

			var shift:Bool = FlxG.keys.pressed.SHIFT;
			var alt:Bool = FlxG.keys.pressed.ALT;

			var char:Character = shift && alt ? crowd : shift ? player : opponent;
			FlxG.switchState(new CharacterEditor(char.name, char.isPlayer));
		}
		#end

		if (song != null && !paused) {
			spawnNotes();
			parseEvents(ChartLoader.eventList);
			bumpCamera(elapsed);

			if (currentStat.health <= 0 && !playerStrums.cpuControlled) {
				music.cease();
				player.stunned = true;
				paused = true;

				persistentUpdate = persistentDraw = false;
				openSubState(new GameOverSubState(player.getGraphicMidpoint().x, player.getGraphicMidpoint().y));
			}

			for (strum in lines) {
				if (strum == null)
					return;

				strum.noteSprites.forEachAlive(function(note:Note):Void {
					note.speed = Math.abs(song.metadata.speed);

					if (strum.cpuControlled) {
						if (!note.wasGoodHit && note.step <= Conductor.songPosition)
							goodNoteHit(note, strum);
					} else if (!playerStrums.cpuControlled) // sustain note inputs
					{
						if (notesPressed[note.index] && (note.isSustain && note.canHit && note.strumline == playerStrumline))
							goodNoteHit(note, playerStrums);
					}

					var rangeReached:Bool = note.downscroll ? note.y > FlxG.height : note.y < -note.height;
					var sustainHit:Bool = note.isSustain && note.wasGoodHit && note.step <= Conductor.songPosition - note.hitboxEarly;

					if (Conductor.songPosition > note.killDelay + note.step) {
						if (rangeReached || sustainHit) {
							if (rangeReached && !note.wasGoodHit && !note.ignorable && !note.isMine)
								if (note.strumline == playerStrumline)
									noteMiss(note.index, strum);

							strum.remove(note, true);
						}
					}
				});
			}
		}

		callFn("update", [elapsed, true]);
	}

	public override function openSubState(SubState:flixel.FlxSubState):Void {
		if (paused)
			music.pause();

		super.openSubState(SubState);
	}

	public override function closeSubState():Void {
		if (paused) {
			if (!startingSong)
				music.resyncVocals();

			FlxTween.globalManager.forEach((twn:FlxTween) -> {
				if (twn != null && !twn.active)
					twn.active = true;
			});

			FlxTimer.globalManager.forEach((tmr:FlxTimer) -> {
				if (tmr != null && !tmr.active)
					tmr.active = true;
			});

			paused = false;
			gameStage.onPauseDispatch(false);
		}
		super.closeSubState();
	}

	public var zoomBeat:Int = 4;

	public override function onBeat():Void {
		super.onBeat();

		callFn("beatHit", [curBeat]);
		charactersDance(curBeat);
		gameStage.onBeat(curBeat);
		gameUI.onBeat(curBeat);

		if (camZooming) {
			if (camGame.zoom < 0.35 && curBeat % zoomBeat == 0) {
				camGame.zoom += 0.025;
				camHUD.zoom += 0.015;
			}
		}
	}

	public override function onStep():Void {
		super.onStep();

		callFn("stepHit", [curStep]);
		gameStage.onStep(curStep);
		music.resyncFunction();
	}

	public override function onSec():Void {
		super.onSec();

		callFn("secHit", [curSec]);
		gameStage.onSec(curSec);
		moveCamera();
	}

	public function charactersDance(curBeat:Int):Void {
		for (strum in lines) {
			if (strum.character != null && curBeat % strum.character.headSpeed == 0)
				if (!strum.character.isSinging() && !strum.character.isMissing() && !strum.character.stunned)
					strum.character.dance();
		}

		if (crowd != null && curBeat % crowd.headSpeed == 0)
			if (!crowd.isSinging() && !crowd.stunned)
				crowd.dance();
	}

	public var camZooming:Bool = true;

	public function bumpCamera(elapsed:Float):Void {
		// beat zooms
		if (camZooming) {
			// base game way
			var lerpValue:Float = 1 - (elapsed * 0.875);
			camGame.zoom = FlxMath.lerp(0, gameStage.cameraZoom, lerpValue);
			camHUD.zoom = FlxMath.lerp(0, gameStage.hudZoom, lerpValue);
		}
	}

	public function moveCamera():Void {
		var char:Character = opponent;

		if (song.sections[curSec] != null) {
			if (song.sections[curSec].camPoint == 2 && crowd != null)
				char = crowd;
			else
				char = (song.sections[curSec].camPoint == 1) ? player : opponent;

			if (camFollow.x != char.getMidpoint().x - 100)
				camFollow.setPosition(char.getMidpoint().x - 100 + char.cameraOffset[0], char.getMidpoint().y - 100 + char.cameraOffset[1]);
		}
	}

	public function spawnNotes():Void {
		while (ChartLoader.noteList[0] != null && ChartLoader.noteList[0].step - Conductor.songPosition < 2000) {
			var note = ChartLoader.noteList[0];
			if (note.strumline == null || note.strumline < 0)
				note.strumline = 0;

			var strum:NoteGroup = lines.members[note.strumline];

			var type:String = 'default';
			if (note.type != null)
				type = note.type;

			if (strum != null) {
				var newNote:Note = new Note(note.step, note.index, false, type);
				newNote.sustainTime = note.sustainTime;
				newNote.strumline = note.strumline;
				newNote.downscroll = Settings.get("scrollType") == "DOWN";
				strum.add(newNote);

				if (note.sustainTime > 0) {
					var prevNote:Note = strum.noteSprites.members[strum.noteSprites.members.length - 1];

					for (noteSustain in 0...Math.floor(note.sustainTime / Conductor.stepCrochet)) {
						var sustainStep:Float = note.step + (Conductor.stepCrochet * Math.floor(noteSustain)) + Conductor.stepCrochet;
						var newSustain:Note = new Note(sustainStep, note.index, true, type, prevNote);

						newSustain.downscroll = Settings.get("scrollType") == "DOWN";
						newSustain.strumline = note.strumline;
						if (note.sustainTime == noteSustain - 1)
							newSustain.isEnd = true;

						newSustain.addTypedPos(strum.noteSprites, strum.noteSprites.members.indexOf(newNote));
						prevNote = newSustain;
					}
				}
			}

			ChartLoader.noteList.shift();
		}
	}

	public function parseEvents(list:Array<EventLine>, stepDelay:Float = 0):Void {
		if (list.length > 0) {
			while (list[curSec] != null) {
				var event:EventLine = list[curSec];

				if (event != null)
					if ((event.type == Stepper && event.step >= Conductor.songPosition - stepDelay) || event.type != Stepper)
						eventTrigger(event);

				list.splice(list.indexOf(list[0]), 1);
			}
		}
	}

	public function eventTrigger(event:EventLine):Void {
		switch (event.name) {}
		// gameStage.onEventDispatch(event, args);
	}

	public function goodNoteHit(note:Note, strum:NoteGroup):Void {
		if (!note.wasGoodHit) {
			note.wasGoodHit = true;
			strum.playAnim('confirm', note.index, true);

			callFn("goodNoteHit", [note.step, note.index, note.type, note.strumline, strum]);

			var animName:String = 'sing${NoteGroup.directions[note.index].toUpperCase()}${strum.character.suffix}';
			if (song.sections[curSec] != null && song.sections[curSec].animation != null) {
				// suffix check
				if (song.sections[curSec].animation.startsWith('-'))
					strum.character.suffix = song.sections[curSec].animation;
				else
					animName = song.sections[curSec].animation;
			}

			if (music.vocals != null && music.vocals.playing)
				music.vocals.volume = 1;

			strum.character.playAnim(animName, true);
			strum.character.holdTimer = 0;

			if (!strum.cpuControlled) {
				var rating:String = SICK;
				if (!note.isSustain) {
					currentStat.notesHit++;
					if (currentStat.combo < 0)
						currentStat.combo = 0;
					currentStat.combo++;

					rating = currentStat.judgeNote(note.step);
					currentStat.gottenRatings.set(rating, currentStat.gottenRatings.get(rating) + 1);

					ratingUI.popRating(rating);
					if (rating == SICK && note.doSplash)
						strum.doSplash(note.index, note.type);

					gameUI.updateScore();
				}
				currentStat.updateHealth(Highscore.RATINGS[0].indexOf(rating), note.isSustain);
			}

			if (!note.isSustain)
				strum.remove(note, true);
		}
	}

	public var notesPressed:Array<Bool> = [];

	public function onKeyPress(key:Int, action:String):Void {
		if (playerStrums == null || playerStrums.cpuControlled || paused || !startedCountdown)
			return;

		if (action != null && NoteGroup.directions.contains(action)) {
			var index:Int = NoteGroup.directions.indexOf(action);
			notesPressed[index] = true;

			var dumbNotes:Array<Note> = [];
			var possibleNotes:Array<Note> = [];

			playerStrums.noteSprites.forEachAlive(function(note:Note):Void {
				if (note.canHit && note.strumline == playerStrumline && !note.wasGoodHit) {
					if (note.index == index)
						possibleNotes.push(note);
				}
			});
			possibleNotes.sort((a:Note, b:Note) -> flixel.util.FlxSort.byValues(flixel.util.FlxSort.ASCENDING, a.step, b.step));

			if (possibleNotes.length > 0) {
				var canBeHit:Bool = true;
				for (note in possibleNotes) {
					for (dumbNote in dumbNotes) {
						// "dumb" notes are doubles
						if (Math.abs(note.step - dumbNote.step) < 10)
							playerStrums.remove(dumbNote, true);
						else
							canBeHit = false;
					}

					if (canBeHit) {
						goodNoteHit(note, playerStrums);
						dumbNotes.push(note);
					}
				}
			} else {
				if (!Settings.get("ghostTapping"))
					noteMiss(index, playerStrums);
			}

			if (!playerStrums.currentAnim('confirm', NoteGroup.directions.indexOf(action)))
				playerStrums.playAnim('pressed', NoteGroup.directions.indexOf(action));
		}
	}

	public function noteMiss(direction:Int = 0, ?strum:NoteGroup, ?showMiss:Bool = true):Void {
		if (currentStat.combo < 0)
			currentStat.combo = 0;
		else {
			if (currentStat.combo > 1)
				currentStat.breaks++;

			// miss combo numbers
			currentStat.combo--;
		}

		callFn("noteMiss", [direction, strum, showMiss]);

		if (music.vocals != null && music.vocals.playing)
			music.vocals.volume = 0;

		currentStat.misses++;
		FlxG.sound.play(AssetHandler.getAsset('sounds/game/miss' + FlxG.random.int(1, 3), SOUND), FlxG.random.float(0.3, 0.6));

		var animName:String = 'sing${NoteGroup.directions[direction].toUpperCase()}miss${strum.character.suffix}';
		if (song.sections[curSec] != null && song.sections[curSec].animation != null) {
			// suffix check
			if (song.sections[curSec].animation.startsWith('-'))
				strum.character.suffix = song.sections[curSec].animation;
			else
				animName = song.sections[curSec].animation + 'miss';
		}
		strum.character.playAnim(animName, true);

		if (showMiss)
			ratingUI.popRating('miss');

		currentStat.updateHealth(4);
		currentStat.updateRatings(4);
		gameUI.updateScore(true);
	}

	public function onKeyRelease(key:Int, action:String):Void {
		if (playerStrums == null || playerStrums.cpuControlled || paused || !startedCountdown)
			return;

		if (action != null && NoteGroup.directions.contains(action)) {
			var index:Int = NoteGroup.directions.indexOf(action);
			notesPressed[index] = false;

			playerStrums.playAnim('static', NoteGroup.directions.indexOf(action));

			if (player != null && player.holdTimer > Conductor.stepCrochet * player.singDuration * 0.001 && !notesPressed.contains(true))
				if (player.isSinging() && !player.isMissing())
					player.dance();
		}
	}

	public function addOnHUD(object:flixel.FlxBasic):Void {
		object.camera = camHUD;
		add(object);
	}

	public override function destroy():Void {
		controls.onKeyPressed.remove(onKeyPress);
		controls.onKeyReleased.remove(onKeyRelease);

		super.destroy();
	}
}
