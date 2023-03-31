package game.stage.objects;

import flixel.system.FlxSound;

class PhillyTrain extends FlxSprite {
	public var sound:FlxSound;

	public function new():Void {
		super(2000, 360);

		this.loadGraphic(Paths.image('images/backgrounds/philly/train'));
	}

	var trainCars:Int = 8;
	var trainFinishing:Bool = false;

	public function startMoving():Void {
		if (sound.time >= 4700) {
			active = true;

			if (PlayState.self.crowd != null)
				PlayState.self.crowd.playAnim('hairBlow');
		}

		if (active) {
			x -= 400;

			if (x < -2000 && !trainFinishing) {
				x = -1150;
				trainCars -= 1;

				if (trainCars <= 0)
					trainFinishing = true;
			}

			if (x < -4000 && trainFinishing)
				resetPosition();
		}
	}

	function resetPosition():Void {
		if (PlayState.self.crowd != null)
			PlayState.self.crowd.playAnim('hairFall');

		x = FlxG.width + 200;
		trainCars = 8;
		trainFinishing = false;
		active = false;
	}
}
