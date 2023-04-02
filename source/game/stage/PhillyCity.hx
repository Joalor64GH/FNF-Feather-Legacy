package game.stage;

import flixel.FlxSprite;
import flixel.group.FlxGroup;
import game.shaders.BuildingShaders;
import game.stage.objects.PhillyTrain;
import game.system.Conductor;

/**
 * Week 3: Pico, Philly, Blammed
 */
class PhillyCity extends BaseStage {
	public var phillyTrain:PhillyTrain;

	public var phillyLight:FlxSprite;
	public var lightShader:BuildingShaders;
	public var lightColors:Array<Int> = [0xFF31A2FD, 0xFF31FD8C, 0xFFFB33F5, 0xFFFD4531, 0xFFFBA633];

	public function new():Void {
		super();

		cameraZoom = 1.08;

		playerOffset.set(140, 0);
		opponentOffset.set(120, 0);
		crowdOffset.set(130, 0);

		lightShader = new BuildingShaders();

		var phillyBG:FlxSprite = new FlxSprite(-100).loadGraphic(getObject('philly/sky'));
		phillyBG.scrollFactor.set(0.1, 0.1);
		add(phillyBG);

		var phillyCity:FlxSprite = new FlxSprite(-10).loadGraphic(getObject('philly/city'));
		phillyCity.scrollFactor.set(0.3, 0.3);
		phillyCity.setGraphicSize(Std.int(phillyCity.width * 0.85));
		phillyCity.updateHitbox();
		add(phillyCity);

		phillyLight = new FlxSprite(phillyCity.x).loadGraphic(getObject('philly/win'));
		phillyLight.scrollFactor.set(0.3, 0.3);
		phillyLight.antialiasing = Settings.get("antialiasing");
		phillyLight.shader = lightShader.shader;
		phillyLight.visible = false;
		phillyLight.setGraphicSize(Std.int(phillyLight.width * 0.85));
		phillyLight.updateHitbox();
		add(phillyLight);

		var behindStreet:FlxSprite = new FlxSprite(-40, 50).loadGraphic(getObject('philly/behindTrain'));
		add(behindStreet);

		phillyTrain = new PhillyTrain();
		add(phillyTrain);

		var phillyStreet:FlxSprite = new FlxSprite(-40, behindStreet.y).loadGraphic(getObject('philly/street'));
		add(phillyStreet);

		// set antialiasing
		forEachOfType(FlxSprite, function(sprite:FlxSprite):Void sprite.antialiasing = Settings.get("antialiasing"));
	}

	var trainFrameTime:Float = 0;
	var trainCooldown:Int = 0;

	public override function update(elapsed:Float):Void {
		super.update(elapsed);

		if (phillyTrain.moving) {
			trainFrameTime += elapsed;

			if (trainFrameTime >= 1 / 24) {
				phillyTrain.updateMovement();
				trainFrameTime = 0;
			}
		}

		lightShader.update((Conductor.beatCrochet / 1000) * elapsed * 1.5);
	}

	var currentLightID:Int = -1;

	public override function onBeat(curBeat:Int):Void {
		if (!phillyTrain.moving)
			trainCooldown += 1;

		if (curBeat % 4 == 0) {
			lightShader.reset();
			phillyLight.visible = false;
			currentLightID = FlxG.random.int(0, lightColors.length - 1);
			phillyLight.color = lightColors[currentLightID];
			phillyLight.visible = true;
		}

		if (curBeat % 8 == 4 && FlxG.random.bool(30) && !phillyTrain.moving && trainCooldown > 8) {
			trainCooldown = FlxG.random.int(-4, 0);
			phillyTrain.startMovement();
		}
	}

	// kinda stupid fix for the sound playing on the pause menu
	public override function onPauseDispatch(paused:Bool):Void {
		if (phillyTrain.sound != null) {
			if (paused && phillyTrain.sound.playing)
				phillyTrain.sound.pause();
			else if (!phillyTrain.sound.playing)
				phillyTrain.sound.play();
		}
	}

	public override function onSongEnd():Void {
		if (phillyTrain.sound != null && phillyTrain.sound.playing)
			phillyTrain.sound.stop();
	}
}
