package feather.state.editors;

import feather.gameObjs.Character;
import flixel.FlxObject;
import flixel.group.FlxGroup;
import flixel.text.FlxText;

class CharacterEditor extends MusicBeatState {
	public var character:Character;

	public var cameraObject:FlxObject;
	public var textGroup:FlxTypedGroup<FlxText>;

	public var characterName:String;
	public var isPlayer:Bool;

	public function new(characterName:String, isPlayer:Bool = false):Void {
		super();

		this.characterName = characterName;
		this.isPlayer = isPlayer;
	}

	public override function create():Void {
		super.create();

		add(new feather.stage.Stage());
		character = new Character().loadChar(characterName, isPlayer);
		add(character);

		cameraObject = new FlxObject(0, 0, 1, 1);
		cameraObject.screenCenter();
		FlxG.camera.follow(cameraObject);
	}

	public override function update(elapsed:Float):Void {
		super.update(elapsed);

		if (FlxG.keys.justPressed.ESCAPE)
			FlxG.switchState(new feather.state.menus.MainMenu());

		if (FlxG.keys.justPressed.Q || FlxG.keys.justPressed.E) {
			var mult:Float = FlxG.keys.justPressed.Q ? -0.25 : 0.25;
			FlxG.camera.zoom += mult;

			if (FlxG.camera.zoom > 3)
				FlxG.camera.zoom = 3;
			if (FlxG.camera.zoom < 0.5)
				FlxG.camera.zoom = 0.5;
		}

		var cameraControlsArray:Array<Bool> = [
			FlxG.keys.pressed.J, // LEFT
			FlxG.keys.pressed.K, // DOWN
			FlxG.keys.pressed.I, // UP
			FlxG.keys.pressed.L // RIGHT
		];

		if (cameraControlsArray.contains(true)) {
			for (i in 0...cameraControlsArray.length) {
				cameraObject.velocity.x += switch (i) {
					case 0: 90;
					case 3: -90;
					default: 0;
				}

				cameraObject.velocity.y += switch (i) {
					case 1: -90;
					case 2: 90;
					default: 0;
				}
			}
		}
	}
}
