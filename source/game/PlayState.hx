package game;

import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.group.FlxGroup.FlxTypedGroup;
import game.editors.*;
import game.gameplay.*;
import game.gameplay.Highscore.Rating;
import game.stage.*;
import game.subStates.*;
import game.system.charting.ChartDefs;
import game.system.charting.ChartLoader;
import game.system.Conductor;
import game.ui.GameplayUI;
import game.ui.RatingPopup;

enum GameplayMode {
	STORY_MODE;
	FREEPLAY;
	CHARTING;
}

enum GameplayEvent {
	#if SCRIPTING_ENABLED
	CustomEvent(name:String, args:Array<Dynamic>, script:String);
	#end
	PlayCharacterAnim(char:String, animation:String);
	ChangeCharacter(char:String, newChar:String);
	ChangeCameraPosition(section:ChartSection);
	ChangeZoomBeat(newBeat:Int);
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
	public var songMetadata:ChartMeta;

	public var music:MusicPlayback;

	public var songName:String = 'test';
	public var difficulty:String = 'normal';

	// Gameplay
	public var localNoteStorage:Array<Note> = [];

	// stores unique notetypes
	private var uniqueNoteStorage:Array<String> = [];

	public var noteFields:FlxTypedGroup<Notefield>;

	public var playerStrumline:Int = 1;
	public var playerNotefield(get, never):Notefield;

	@:keep inline function get_playerNotefield():Notefield
		return noteFields.members[playerStrumline];

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
					songMetadata = ChartLoader.songMetadata;
				}
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

		ChartLoader.fillUnspawnList();

		for (i in ChartLoader.unspawnNoteList)
			if (!uniqueNoteStorage.contains(i.type))
				uniqueNoteStorage.push(i.type);

		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camOver = new FlxCamera();

		camHUD.bgColor = FlxColor.TRANSPARENT;
		camOver.bgColor = FlxColor.TRANSPARENT;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camOver, false);

		FlxG.cameras.setDefaultDrawTarget(camGame, true);
		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		persistentUpdate = persistentDraw = true;

		#if SCRIPTING_ENABLED
		// parse haxe scripts that exist within the folders
		for (i in AssetHandler.getExtensionsFor(SCRIPT)) {
			if (sys.FileSystem.exists(AssetHandler.getPath("data/scripts"))) {
				for (script in sys.FileSystem.readDirectory(AssetHandler.getPath("data/scripts")))
					if (script.endsWith(i))
						globals.push(new ScriptHandler(AssetHandler.getAsset('data/scripts/${script}', SCRIPT)));
			}

			for (songScript in sys.FileSystem.readDirectory(AssetHandler.getPath('data/songs/${songMetadata.name}')))
				if (songScript.endsWith(i))
					globals.push(new ScriptHandler(AssetHandler.getAsset('data/songs/${songMetadata.name}/${songScript}', SCRIPT)));
		}
		#end

		callFn("create", [false]);

		setVar("curBeat", curBeat);
		setVar("curStep", curStep);
		setVar("curSec", curSec);

		// create the stage
		gameStage = switch (songMetadata.stage) {
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
			case 'stage': new Stage();
			default: new BaseStage(songMetadata.stage);
		}
		add(gameStage);

		camGame.zoom = gameStage.cameraZoom;
		camHUD.zoom = gameStage.hudZoom;

		// characters
		if (gameStage.displayCrowd)
			crowd = new Character(400 + gameStage.crowdOffset.x, 130 + gameStage.crowdOffset.y).loadChar(songMetadata.characters[2]);

		opponent = new Character(100 + gameStage.opponentOffset.x, 100 + gameStage.opponentOffset.y).loadChar(songMetadata.characters[1]);
		player = new Character(770 + gameStage.playerOffset.x, 450 + gameStage.playerOffset.y).loadChar(songMetadata.characters[0], true);

		if (crowd != null) {
			if (songMetadata.characters[1] == songMetadata.characters[2]) {
				crowd.visible = false;
				opponent.setPosition(crowd.x, crowd.y);
			}
			add(crowd);
		}

		add(opponent);
		add(player);

		if (gameStage.camPosition.x == Math.NEGATIVE_INFINITY)
			gameStage.camPosition.x = Math.floor(opponent.getMidpoint().x + FlxG.width / 4);
		if (gameStage.camPosition.y == Math.NEGATIVE_INFINITY)
			gameStage.camPosition.y = Math.floor(opponent.getGraphicMidpoint().y - FlxG.height / 2);

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollow.setPosition(gameStage.camPosition.x, gameStage.camPosition.y);
		camGame.follow(camFollow, LOCKON, 0.04);
		camGame.focusOn(camFollow.getPosition());

		fireEvents(ChangeCameraPosition(song.sections[0]));

		// ui
		gameUI = new GameplayUI();
		addOnHUD(gameUI);

		noteFields = new FlxTypedGroup<Notefield>();
		addOnHUD(noteFields);

		ratingUI = new RatingPopup();

		for (i in 0...2) {
			var isPlayer:Bool = i == playerStrumline;
			var spacing:Float = 160 * 0.7;

			var strumInitDist:Float = FlxG.width / 10;
			var strumDistance:Float = FlxG.width / 2 * i;
			if (isPlayer && Settings.get("centerScroll")) {
				strumInitDist = FlxG.width / 4;
				strumDistance = 115;
			}

			var xPos:Float = (strumInitDist) + strumDistance;
			var yPos:Float = Settings.get("scrollType") == "DOWN" ? FlxG.height - 150 : 60;
			var character:Character = switch (i) {
				case 1: player;
				default: opponent;
			};

			if (i == 0)
				xPos -= 60;

			var newField:Notefield = new Notefield(xPos, yPos, character, spacing);
			newField.cpuControlled = !isPlayer;
			if (Settings.get("centerScroll"))
				newField.visible = isPlayer;
			newField.ID = i;
			noteFields.add(newField);
		}

		// preload notes
		for (i in ChartLoader.unspawnNoteList) {
			i.mustHit = i.strumline == playerStrumline;
			localNoteStorage.push(i);
		}

		for (type in uniqueNoteStorage)
			noteFields.members[0].doSplash(0, type, true);

		controls.onKeyPressed.add(onKeyPress);
		controls.onKeyReleased.add(onKeyRelease);

		callFn("create", [true]);

		#if SCRIPTING_ENABLED
		if (gameStage.bgScript != null) {
			gameStage.bgScript.call('createPost', []);
			gameStage.bgScript.set('player', player);
			gameStage.bgScript.set('opponent', opponent);
			gameStage.bgScript.set('crowd', crowd);
		}
		#end

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

		for (strum in noteFields) {
			for (i in 0...strum.receptorObjects.members.length) {
				var startY:Float = strum.receptorObjects.members[i].y;
				strum.receptorObjects.members[i].alpha = 0;
				strum.receptorObjects.members[i].y -= 32;

				FlxTween.tween(strum.receptorObjects.members[i], {y: startY, alpha: 1}, (Conductor.beatCrochet * 4) / 1000,
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

		if (song != null) {
			while (localNoteStorage.length > 0) {
				var unspawnNote:Note = localNoteStorage[0];
				var strum:Notefield = noteFields.members[unspawnNote.strumline];
				if (unspawnNote.step - Conductor.songPosition > 2000)
					break;

				if (strum != null)
					strum.add(unspawnNote);

				localNoteStorage.splice(localNoteStorage.indexOf(unspawnNote), 1);
			}

			if (!paused) {
				bumpCamera(elapsed);

				if (currentStat.health <= 0 && !playerNotefield.cpuControlled) {
					music.cease();
					player.stunned = true;
					paused = true;

					persistentUpdate = persistentDraw = false;
					openSubState(new GameOverSubState(player.getGraphicMidpoint().x, player.getGraphicMidpoint().y));
				}

				for (strum in noteFields) {
					strum.noteObjects.forEachAlive(function(note:Note):Void {
						note.speed = Math.abs(song.speed);

						if (strum.cpuControlled) {
							if (!note.wasGoodHit && note.step <= Conductor.songPosition)
								goodNoteHit(note, strum);
						} // sustain note inputs
						else if (!playerNotefield.cpuControlled) {
							if (notesPressed[note.index] && (note.isSustain && note.canHit && note.mustHit))
								goodNoteHit(note, playerNotefield);
						}

						var rangeReached:Bool = note.downscroll ? note.arrow.y > FlxG.height : note.arrow.y < -note.arrow.height;
						var sustainHit:Bool = note.isSustain && note.wasGoodHit && note.step <= Conductor.songPosition - note.hitboxEarly;

						if (Conductor.songPosition > note.killDelay + note.step) {
							if (rangeReached || sustainHit) {
								if (rangeReached && !note.wasGoodHit && !note.ignorable && !note.isMine)
									if (note.mustHit)
										noteMiss(note.index, strum);

								strum.remove(note, true);
							}
						}
					});
				}

				if (player != null
					&& player.holdTimer > Conductor.stepCrochet * player.singDuration * 0.001
					&& !notesPressed.contains(true))
					if (player.isSinging() && !player.isMissing())
						player.dance();
			}
		}

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
			playerNotefield.cpuControlled = !playerNotefield.cpuControlled;
			gameUI.cpuText.visible = playerNotefield.cpuControlled;
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

		callFn("update", [elapsed, true]);
	}

	var charColumn:Map<String, Map<String, Character>> = [];

	public function preloadEvents(event:GameplayEvent):Void {
		switch (event) {
			case ChangeCharacter(name, newChar):
				// preventing lagspikes rq
				charColumn.set(name, new Map<String, Character>());
				charColumn.get(name).set(newChar, new Character().loadChar(newChar));
			default:
		}
	}

	public function fireEvents(event:GameplayEvent):Void {
		switch (event) {
			case ChangeCharacter(name, newChar):
				switch (name) {
					case 'bf', 'boyfriend', 'player':
						player.loadChar(charColumn.get(name).get(newChar).name);
					case 'gf', 'girlfriend', 'crowd':
						crowd.loadChar(charColumn.get(name).get(newChar).name);
					case 'dad', 'player2', 'opponent':
						opponent.loadChar(charColumn.get(name).get(newChar).name);
				}

			case ChangeCameraPosition(section):
				if (section != null) {
					var char:Character = opponent;

					if (section.camPoint == 2 && crowd != null)
						char = crowd;
					else
						char = (section.camPoint == 1) ? player : opponent;
					if (camFollow.x != char.getMidpoint().x - 100)
						camFollow.setPosition(char.getMidpoint().x - 100 + char.cameraOffset[0], char.getMidpoint().y - 100 + char.cameraOffset[1]);
				}

			default:
		}

		gameStage.onEventDispatch(event);
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

		try fireEvents(ChangeCameraPosition(song.sections[curSec])) catch (e:haxe.Exception)
			trace('failed to parse camera event at section ${curSec}');
	}

	public function charactersDance(curBeat:Int):Void {
		for (strum in noteFields) {
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

	public function goodNoteHit(note:Note, strum:Notefield):Void {
		if (!note.wasGoodHit) {
			note.wasGoodHit = true;
			strum.playAnim('confirm', note.index, true);

			callFn("goodNoteHit", [note.step, note.index, note.type, note.strumline, strum]);

			var animName:String = 'sing${Notefield.directions[note.index].toUpperCase()}${strum.character.suffix}';
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
					ratingUI.popCombo();

					if (rating == SICK && note.doSplash)
						strum.doSplash(note.index, note.type);
					if (currentStat.breakRating == rating)
						noteMiss(note.index, strum, false);

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
		if (playerNotefield == null || playerNotefield.cpuControlled || paused || !startedCountdown)
			return;

		if (action != null && Notefield.directions.contains(action)) {
			var index:Int = Notefield.directions.indexOf(action);
			notesPressed[index] = true;

			var dumbNotes:Array<Note> = [];
			var possibleNotes:Array<Note> = [];

			playerNotefield.noteObjects.forEachAlive(function(note:Note):Void {
				if (note.canHit && note.mustHit && !note.wasGoodHit) {
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
							playerNotefield.remove(dumbNote, true);
						else
							canBeHit = false;
					}

					if (canBeHit) {
						goodNoteHit(note, playerNotefield);
						dumbNotes.push(note);
					}
				}
			} else {
				if (!Settings.get("ghostTapping"))
					noteMiss(index, playerNotefield);
			}

			if (!playerNotefield.currentAnim('confirm', Notefield.directions.indexOf(action)))
				playerNotefield.playAnim('pressed', Notefield.directions.indexOf(action));
		}
	}

	public function noteMiss(direction:Int = 0, ?strum:Notefield, ?showMiss:Bool = true):Void {
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

		var animName:String = 'sing${Notefield.directions[direction].toUpperCase()}miss${strum.character.suffix}';
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
		if (playerNotefield == null || playerNotefield.cpuControlled || paused || !startedCountdown)
			return;

		if (action != null && Notefield.directions.contains(action)) {
			var index:Int = Notefield.directions.indexOf(action);
			notesPressed[index] = false;
			playerNotefield.playAnim('static', Notefield.directions.indexOf(action));
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
