package game.editors;

import flixel.FlxObject;
import game.gameplay.Character;

class CharacterEditor extends MusicBeatState {
	public var character:Character;

	public var cameraObject:FlxObject;

	public var characterName:String;
	public var isPlayer:Bool;

	public function new(characterName:String, isPlayer:Bool = false):Void {
		super();

		this.characterName = characterName;
		this.isPlayer = isPlayer;
	}

	public override function create():Void {
		super.create();

		add(new game.stage.Stage());
		character = new Character().loadChar(characterName, isPlayer);
		add(character);

		cameraObject = new FlxObject(0, 0, 1, 1);
		FlxG.camera.follow(cameraObject);
	}

	public override function update(elapsed:Float):Void {
		super.update(elapsed);

		if (FlxG.keys.justPressed.ESCAPE)
			FlxG.switchState(new game.menus.MainMenu());

		var cameraControlsArray:Array<Bool> = [
			FlxG.keys.pressed.J,
			FlxG.keys.pressed.K,
			FlxG.keys.pressed.I,
			FlxG.keys.pressed.L
		];

		if (cameraControlsArray.contains(true)) {
			for (i in 0...cameraControlsArray.length) {
				cameraObject.x += switch (i) {
					case 0: 10;
					case 3: -10;
					default: 0;
				}

				cameraObject.y += switch (i) {
					case 1: -10;
					case 2: 10;
					default: 0;
				}
			}
		}
	}
}
