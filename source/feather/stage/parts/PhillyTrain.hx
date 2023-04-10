package feather.stage.parts;

import feather.state.PlayState;
import flixel.system.FlxSound;

class PhillyTrain extends FlxSprite {
	public var sound:FlxSound;

	public function new():Void {
		super(FlxG.width + 200, 360);

		loadGraphic(Paths.image('backgrounds/philly/train'));
		sound = new FlxSound().loadEmbedded(AssetHandler.getAsset('images/backgrounds/philly/sounds/train_passes', SOUND));
		FlxG.sound.list.add(sound);
	}

	public var cycle:Int = 8;
	public var moving:Bool = false;
	public var finishing:Bool = false;

	public function startMovement():Void {
		moving = true;
		sound.play(true);
		updateMovement();
	}

	public function updateMovement():Void {
		if (sound.time >= 5700) {
			moving = true;

			if (PlayState.self.crowd != null)
				PlayState.self.crowd.playAnim('hairBlow');
		}

		if (moving) {
			x -= 400;

			if (x < -2000 && !finishing) {
				x = -1150;
				cycle -= 1;

				if (cycle <= 0)
					finishing = true;
			}

			if (x < -4000 && finishing)
				resetPosition();
		}
	}

	function resetPosition():Void {
		if (PlayState.self.crowd != null)
			PlayState.self.crowd.playAnim('hairFall');

		cycle = 8;
		x = FlxG.width + 200;
		moving = finishing = false;
	}
}
