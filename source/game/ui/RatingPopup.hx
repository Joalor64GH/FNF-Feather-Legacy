package game.ui;

import core.FNFSprite;
import flixel.group.FlxGroup;
import game.gameplay.Highscore;
import game.system.Conductor;

class RatingPopup {
	public var ratingGroup:FlxTypedGroup<FNFSprite>;
	public var numberGroup:FlxTypedGroup<FNFSprite>;

	public function new():Void {
		ratingGroup = new FlxTypedGroup<FNFSprite>();
		numberGroup = new FlxTypedGroup<FNFSprite>();

		popRating('sick', true);
	}

	public function popRating(name:String, preload:Bool = false):Void {
		var rating:FNFSprite = ratingGroup.recycle(FNFSprite, function():FNFSprite {
			var sprite:FNFSprite = new FNFSprite(0, 0);

			sprite.frames = Utils.getUIAsset('ratingSheet', XML);
			for (i in 0...Highscore.RATINGS[0].length)
				sprite.addAnim(Highscore.RATINGS[0][i], Highscore.RATINGS[0][i]);

			return sprite;
		});

		rating.alpha = preload ? 0.000001 : 1;
		rating.depth = -Conductor.songPosition;
		rating.playAnim(name);

		rating.antialiasing = Settings.get("antialiasing");
		rating.screenCenter();

		rating.setGraphicSize(Std.int(rating.frameWidth * 0.7));
		// rating.updateHitbox();

		if (preload)
			FlxG.state.add(ratingGroup);

		rating.acceleration.y = 550;
		rating.velocity.y = -FlxG.random.int(140, 175);
		rating.velocity.x = -FlxG.random.int(0, 10);

		FlxTween.tween(rating, {alpha: 0}, Conductor.beatCrochet / 1000, {
			onComplete: (twn:FlxTween) -> rating.kill(),
			startDelay: ((Conductor.beatCrochet + Conductor.stepCrochet * 2) / 1000)
		});

		ratingGroup.sort((Order:Int, a:FNFSprite, b:FNFSprite) -> return a.depth > b.depth ? -Order : Order, flixel.util.FlxSort.DESCENDING);
	}

	public function popCombo(preload:Bool = false):Void {
		var split:Array<String> = Std.string(PlayState.self.currentStat.combo).split("");
		for (i in 0...split.length) {
			var numScore:FNFSprite = numberGroup.recycle(FNFSprite, function():FNFSprite {
				var combo:FNFSprite = new FNFSprite();
				return combo;
			});

			numScore.depth = -Conductor.songPosition;
			numScore.alpha = preload ? 0.000001 : 1;
			numScore.antialiasing = Settings.get("antialiasing");
			numScore.scale.set(1, 1);

			if (preload)
				FlxG.state.add(numberGroup);
		}

		numberGroup.sort((Order:Int, a:FNFSprite, b:FNFSprite) -> return a.depth > b.depth ? -Order : Order, flixel.util.FlxSort.DESCENDING);
	}
}
