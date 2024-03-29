package feather.gameObjs;

import feather.core.FNFSprite;
import feather.core.music.Conductor;
import flixel.graphics.frames.FlxAtlasFrames;

enum DanceType {
	QUICK;
	NORMAL;
}

typedef CharacterFormat = {
	var image:String;
	var flipX:Null<Bool>;
	var size:Null<Float>;
	var animations:Array<FNFAnimation>;
	var singDuration:Null<Float>;
	var characterOffset:Array<Float>;
	var cameraOffset:Array<Float>;
}

/**
 * Prototype dev comment: this took me longer than it should.
 * Beta dev comment: https://youtu.be/hIB8iAEGzYU?t=17
 */
class Character extends FNFSprite {
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
	public var danceProperties = {windyHair: false};

	public var icon:String = null;

	public var holdTimer:Float = 0;

	public var singDuration:Float = 4;

	public var characterOffset:Array<Float> = [0, 0];
	public var cameraOffset:Array<Float> = [0, 0];

	public function new(x:Float = 0, y:Float = 0):Void {
		super(x, y);
	}

	public function loadChar(_name:String = "bf", _isPlayer:Bool = false):Character {
		name = _name;
		isPlayer = _isPlayer;

		antialiasing = UserSettings.get("antialiasing") && !name.endsWith("-pixel");

		if (icon == null)
			icon = name;

		switch (name) {
			case "__chop": // I hate this.
				frames = getFrames("chop");

				addAnim("danceLeft", "idleanim", [0, 0], 24, false, [0, 1, 2, 3, 4, 5, 6, 7]);
				addAnim("danceRight", "idleanim", [0, 0], 24, false, [8, 9, 10, 11, 12, 13, 14, 15]);

				addAnim("singLEFT", "leftanim", [10, 2]);
				addAnim("singDOWN", "downanim", [-50, -5]);
				addAnim("singUP", "upanim", [-26, 20]);
				addAnim("singRIGHT", "rightanim", [-40, 0]);

				characterOffset = [-100, 220];
				cameraOffset = [250, 20];

			case "face":
				frames = getFrames("face");

				addAnim("idle", "Idle", isPlayer ? [0, -10] : [0, -350]);
				addAnim("singLEFT", isPlayer ? "Right" : "Left", isPlayer ? [33, -6] : [22, -353]);
				addAnim("singDOWN", "Down", isPlayer ? [-48, -31] : [17, -375]);
				addAnim("singUP", "Up", isPlayer ? [-45, 11] : [8, -334]);
				addAnim("singRIGHT", isPlayer ? "Left" : "Right", isPlayer ? [-61, -14] : [50, -348]);

				if (!isPlayer)
					cameraOffset = [180, 300];

				flipX = isPlayer;

			default:
				if (sys.FileSystem.exists(AssetHandler.getPath('images/characters/${name}/${name}', YAML))) {
					var file:CharacterFormat = cast yaml.Yaml.parse(AssetHandler.getAsset('images/characters/${name}/${name}', YAML),
						yaml.Parser.options().useObjects());
					if (file != null) {
						if (file.image != null)
							frames = getFrames(file.image);
						else
							frames = getFrames(name);

						// todo: per-player animations
						for (anim in file.animations)
							addAnim(anim.name, anim.prefix, anim.animOffsets, anim.framerate, anim.looped, anim.indices, anim.flipX, anim.flipY);

						if (file.flipX != null)
							flipX = file.flipX;
						if (file.characterOffset != null)
							characterOffset = file.characterOffset;
						if (file.cameraOffset != null)
							cameraOffset = file.cameraOffset;
						if (file.singDuration != null)
							singDuration = file.singDuration;

						if (file.size != null) {
							setGraphicSize(Std.int(width * file.size));
							resizeOffsets(file.size);
						}
					}
				} else
					loadChar("face", isPlayer);
		}

		x += characterOffset[0];
		y += characterOffset[1];

		declareDanceStyle();
		dance();

		return this;
	}

	public override function update(elapsed:Float):Void {
		super.update(elapsed);

		if (animation.curAnim != null) {
			if (isSinging())
				holdTimer += elapsed;

			if (!isPlayer) {
				if (holdTimer >= Conductor.stepCrochet * singDuration * 0.001) {
					dance();
					holdTimer = 0;
				}
			}

			if (danceProperties.windyHair) {
				// looping hair anims after idle finished
				if (animation.getByName("idleHair") != null)
					if (!animation.curAnim.name.startsWith('sing') && animation.curAnim.finished)
						animation.play('idleHair');

				if (animation.curAnim.name == 'hairFall' && animation.curAnim.finished)
					playAnim('danceRight');
			}

			if (isMissing() && animation.finished)
				dance();
		}
	}

	var danced:Bool = false;

	public function dance(forced:Bool = false, ?startFrame:Int = 0):Void {
		switch (danceStyle) {
			case QUICK:
				if (animation.curAnim != null && !animation.curAnim.name.startsWith('hair'))
					danced = !danced;

				var direction:String = (danced ? 'Right' : 'Left');
				playAnim('dance${direction}${suffix}', forced, false, startFrame);
			default:
				playAnim('idle${suffix}', forced, false, startFrame);
		}
	}

	public function getFrames(sheetName:String):FlxAtlasFrames {
		var type:AssetType = XML;
		var sheetPath:String = 'images/characters/${name}/${sheetName}';

		if (sys.FileSystem.exists(AssetHandler.getPath(sheetPath, TXT)))
			type = TXT;
		else if (sys.FileSystem.exists(AssetHandler.getPath(sheetPath, JSON)))
			type = JSON_ATLAS;

		return AssetHandler.getAsset(sheetPath, type);
	}

	// Animation Helpers
	public function isSinging():Bool
		return animation.curAnim != null && animation.curAnim.name.startsWith("sing");

	public function isMissing():Bool
		return animation.curAnim != null && animation.curAnim.name.endsWith("miss");

	public function declareDanceStyle():Void {
		if (animation.getByName('danceLeft${suffix}') != null && animation.getByName('danceRight${suffix}') != null) {
			danceStyle = QUICK;
			headSpeed = 1;
		}
	}
}
