package feather.gameObjs.ui;

import feather.core.FNFSprite;
import feather.core.Highscore;
import feather.core.music.Conductor;
import feather.state.PlayState;
import flixel.group.FlxGroup;

class RatingPopup {
	public var ratingGroup:FlxTypedGroup<FNFSprite>;
	public var numberGroup:FlxTypedGroup<FNFSprite>;

	public function new():Void {
		ratingGroup = new FlxTypedGroup<FNFSprite>();
		numberGroup = new FlxTypedGroup<FNFSprite>();

		popRating('sick', true);
		popCombo(true);
	}

	var ratingLast:FNFSprite;

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

		rating.antialiasing = UserSettings.get("antialiasing");
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
		ratingLast = rating;
		ratingGroup.sort((Order:Int, a:FNFSprite, b:FNFSprite) -> return a.depth > b.depth ? -Order : Order, flixel.util.FlxSort.DESCENDING);
	}

	public function popCombo(preload:Bool = false):Void {
		var combo:Int = PlayState.self.currentStat.combo;
		var scoreSeparated:Array<Int> = [];

		while (combo != 0) {
			scoreSeparated.push(combo % 10);
			combo = Std.int(combo / 10);
		}
		while (scoreSeparated.length < 3)
			scoreSeparated.push(0);

		/*
			for (i in 0...scoreSeparated.length) {
				var numScore:FNFSprite = numberGroup.recycle(FNFSprite, function():FNFSprite {
					var combo:FNFSprite = new FNFSprite(0, 0);
					combo.loadGraphic(Utils.getUIAsset('comboNumbers', IMAGE), true, 110, 131);
					for (i in 0...10)
						combo.animation.add('${i}', [i]);
					return combo;
				});

				numScore.depth = -Conductor.songPosition;
				numScore.alpha = preload ? 0.000001 : 1;
				numScore.antialiasing = UserSettings.get("antialiasing");
				numScore.screenCenter();
				numScore.x = ratingLast.x - (35 * i);
				numScore.playAnim('${scoreSeparated[i]}');

				numScore.setGraphicSize(Std.int(numScore.frameWidth * 0.5));
				// numScore.updateHitbox();

				numScore.acceleration.y = FlxG.random.int(200, 300);
				numScore.velocity.y -= FlxG.random.int(140, 160);
				numScore.velocity.x = FlxG.random.float(-5, 5);

				FlxTween.tween(numScore, {alpha: 0}, (Conductor.stepCrochet * 2) / 1000, {
					onComplete: (twn:FlxTween) -> numScore.kill(),
					startDelay: (Conductor.beatCrochet) / 1000
				});
			}
		 */

		if (preload)
			FlxG.state.add(numberGroup);

		numberGroup.sort((Order:Int, a:FNFSprite, b:FNFSprite) -> return a.depth > b.depth ? -Order : Order, flixel.util.FlxSort.DESCENDING);
	}
}
