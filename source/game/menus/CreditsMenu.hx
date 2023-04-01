package game.menus;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.addons.display.FlxBackdrop;
import game.system.Conductor;

typedef PersonInfo = {
	var ?socialURL:String;
	var ?description:String;
	var ?backgroundColor:FlxColor;
	var profession:String;
}

class CreditsMenu extends MusicBeatState {
	static var curSelection:Int = 0;

	public var cards:FlxSpriteGroup;
	public var listArray:Array<String> = ['ONE', 'TWO', 'THREE', 'FOUR'];
	public var people:Array<PersonInfo> = [];

	public override function create():Void {
		super.create();

		var background:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menus/shared/menuDesat'));
		background.screenCenter(XY);
		add(background);

		var backdrop:FlxBackdrop = new FlxBackdrop(Paths.image('menus/shared/menuGrid'), XY, 0, 0);
		backdrop.centerOverlay(background, XY);
		backdrop.alpha = 0.6;
		add(backdrop);

		cards = new FlxSpriteGroup();
		cards.screenCenter(XY);
		add(cards);

		cards.add(new FlxSprite().makeGraphic(50, 50, 0xFFFFFFFF));
	}

	public override function update(elapsed:Float):Void {
		super.update(elapsed);

		if (controls.justPressed("accept")) {}

		if (controls.justPressed("back"))
			FlxG.switchState(new MainMenu());
	}

	public function updateSelection(newSelection:Int = 0):Void {
		if (cards.members != null && cards.members.length > 0)
			curSelection = FlxMath.wrap(curSelection + newSelection, 0, cards.members.length);

		var bs:Int = -1;
		for (card in cards) {
			card.ID = bs - curSelection;

			card.alpha = 0.6;
			if (card.ID == curSelection)
				card.alpha = 1;
			++bs;
		}
	}
}
