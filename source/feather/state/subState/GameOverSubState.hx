package feather.state.subState;

import feather.core.music.Conductor;
import feather.gameObjs.Character;

typedef GameOverStruct = {
	var name:String;
	var musicTune:String;
	var confirmSound:String;
	var deathSound:String;
	var tuneBPM:Float;
}

class GameOverSubState extends MusicBeatSubState {
	public var char:Character;
	public var params:GameOverStruct =
		{
			name: "bf-dead",
			musicTune: "gameOver",
			confirmSound: "gameOverEnd",
			deathSound: "fnf_loss_sfx",
			tuneBPM: 100
		};

	public function new(x:Float, y:Float):Void {
		super();

		Conductor.changeBPM(params.tuneBPM);

		/*
			char = new Character(x, y + PlayState.self.player.height).loadChar(params.name);
			char.playAnim("firstDeath");
			add(char);
		 */
	}

	public override function update(elapsed:Float):Void {
		super.update(elapsed);

		if (FlxG.sound.music != null && FlxG.sound.music.playing)
			Conductor.songPosition = FlxG.sound.music.time;

		/*
			if (controls.justPressed("accept"))
			{
				endSequence();
			}
		 */

		if (controls.justPressed("back"))
			FlxG.switchState(new feather.state.menus.FreeplayMenu());
	}

	public override function onBeat():Void {
		super.onBeat();
	}
}
