package game.gameplay;

import core.FNFSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import game.system.music.Conductor;

enum DanceType
{
	QUICK;
	NORMAL;
}

/**
 * Prototype dev comment: this took me longer than it should.
 * Beta dev comment: https://youtu.be/hIB8iAEGzYU?t=17
 */
class Character extends FNFSprite
{
	public var name:String = "bf";

	public var isPlayer:Bool = false;
	public var stunned:Bool = false;

	/**
	 * Suffix for the character's animations
	 * e.g: `-alt`
	 */
	public var suffix:String = '';

	/**
		Head bop speed, measured in song beats
	 */
	public var headSpeed:Int = 2;

	/**
	 * Defines a Character's Dance Style
	 * "QUICK" means it will dance every beat or so
	 */
	public var danceStyle:DanceType = NORMAL;

	/**
	 * Defines Character Dance Properties
	 *
	 * for instance: windyHair makes it so week 4's characters play an animation named
	 * `idleHair` once their idle animation finishes
	 */
	public var danceProperties = {
		windyHair: false,
	};

	public var holdTimer:Float = 0;

	public var singDuration:Float = 4;

	public var cameraOffset:Array<Float> = [0, 0];

	public function new(x:Float = 0, y:Float = 0):Void
	{
		super(x, y);
	}

	public function loadChar(name:String = "bf", isPlayer:Bool = false):Character
	{
		this.name = name;
		antialiasing = true;

		switch (name)
		{
			case "bf":
				frames = getFrames("BOYFRIEND");

				addAnim("idle", "BF idle dance", [5, 0]);
				addAnim("hey", "BF HEY!!", [7, 5]);
				addAnim("scared", "BF idle shaking", [4, 1]);

				// sing poses
				addAnim("singLEFT", "BF NOTE LEFT0", [4, -7]);
				addAnim("singDOWN", "BF NOTE DOWN0", [-22, -51]);
				addAnim("singUP", "BF NOTE UP0", [-47, 28]);
				addAnim("singRIGHT", "BF NOTE RIGHT0", [-48, -5]);

				// miss poses
				addAnim("singLEFTmiss", "BF NOTE LEFT MISS", [4, 19]);
				addAnim("singDOWNmiss", "BF NOTE DOWN MISS", [-22, -21]);
				addAnim("singUPmiss", "BF NOTE UP MISS", [-43, 28]);
				addAnim("singRIGHTmiss", "BF NOTE RIGHT MISS", [-42, 23]);

			case "bf-dead":
				frames = getFrames("bf-dead");

				addAnim("firstDeath", "BF dies", [-10, 0]);
				addAnim("deathLoop", "BF Dead Loop", [-10, 0]);
				addAnim("deathConfirm", "BF Dead confirm", [-10, 0]);

			case "gf":
				frames = getFrames("GF_assets");

				addAnim("danceLeft", "GF Dancing Beat", [0, -9], 24, false, [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]);
				addAnim("danceRight", "GF Dancing Beat", [0, -9], 24, false, [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29]);
				addAnim("hairBlow", "GF Dancing Beat Hair blowing", [0, 0], 24, false, [0, 1, 2, 3]);
				addAnim("hairFall", "GF Dancing Beat Hair Landing", [0, 0], 24, false, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]);
				addAnim("sad", "gf sad", [-2, -2], 24, false, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]);

				addAnim("scared", "GF FEAR", [-2, 17]);
				addAnim("cheer", "GF Cheer");

				addAnim("singLEFT", "GF left note", [0, -19]);
				addAnim("singDOWN", "GF Down Note", [0, -20]);
				addAnim("singUP", "GF Up Note", [0, 4]);
				addAnim("singRIGHT", "GF Right Note", [0, -20]);

				danceProperties.windyHair = true;

			case "dad":
				frames = getFrames("DADDY_DEAREST");

				addAnim("idle", "Dad idle dance");
				addAnim("singLEFT", "Dad Sing Note LEFT", [-10, 10]);
				addAnim("singDOWN", "Dad Sing Note DOWN", [0, -30]);
				addAnim("singUP", "Dad Sing Note UP", [-6, 50]);
				addAnim("singRIGHT", "Dad Sing Note RIGHT", [0, 27]);

				cameraOffset = [250, 20];
				singDuration = 6.1;

			default:
				frames = AssetHandler.getAsset('images/characters/face/face', XML);

				addAnim("idle", "Idle", isPlayer ? [0, -10] : [0, -350]);
				addAnim("singLEFT", isPlayer ? "Right" : "Left", isPlayer ? [33, -6] : [22, -353]);
				addAnim("singDOWN", "Down", isPlayer ? [-48, -31] : [17, -375]);
				addAnim("singUP", "Up", isPlayer ? [-45, 11] : [8, -334]);
				addAnim("singRIGHT", isPlayer ? "Left" : "Right", isPlayer ? [-61, -14] : [50, -348]);

				if (!isPlayer)
					cameraOffset = [180, 300];

				flipX = isPlayer;
		}

		checkQuickDancer();
		dance();

		return this;
	}

	public override function update(elapsed:Float):Void
	{
		if (!nullAnims())
		{
			if (isSinging())
				holdTimer += elapsed;

			if (!isPlayer)
			{
				if (holdTimer >= Conductor.stepCrochet * singDuration * 0.001)
				{
					dance();
					holdTimer = 0;
				}
			}
		}

		if (danceProperties.windyHair)
		{
			// looping hair anims after idle finished
			if (animation.getByName("idleHair") != null)
				if (!animation.curAnim.name.startsWith('sing') && animation.curAnim.finished)
					playAnim('idleHair');

			if (animation.curAnim.name == 'hairFall' && animation.curAnim.finished)
				playAnim('danceRight');
		}

		if (isMissing() && animation.finished)
			dance();

		super.update(elapsed);
	}

	var danced:Bool = true;

	public function dance(forced:Bool = false, ?startFrame:Int = 0):Void
	{
		var animName:String = 'idle${suffix}';

		if (danceStyle == QUICK && animation.curAnim != null && !animation.curAnim.name.startsWith('hair'))
			danced = !danced;

		var direction:String = (danced ? 'Right' : 'Left');

		animName = switch (danceStyle)
		{
			case QUICK: 'dance${direction}${suffix}';
			case NORMAL: 'idle${suffix}';
		}

		playAnim(animName, forced, false, startFrame);
	}

	public function getFrames(sheetName:String):FlxAtlasFrames
	{
		return AssetHandler.getAsset('images/characters/${name}/${sheetName}', XML);
	}

	// Animation Helpers
	public function isSinging():Bool
		return !nullAnims() && animation.curAnim.name.startsWith("sing");

	public function isMissing():Bool
		return !nullAnims() && animation.curAnim.name.endsWith("miss");

	function checkQuickDancer():Void
	{
		if (animation.getByName('danceLeft${suffix}') != null && animation.getByName('danceRight${suffix}') != null)
		{
			danceStyle = QUICK;
			headSpeed = 1;
		}
	}
}
