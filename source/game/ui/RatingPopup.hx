package game.ui;

import core.FNFSprite;
import game.gameplay.Highscore;
import game.states.PlayState;
import rhythm.Conductor;

class RatingPopup
{
	final game:PlayState = PlayState.self;

	public function new():Void
	{
		popRating('sick', true);
	}

	public function popRating(name:String, preload:Bool = false):Void
	{
		var rating:FNFSprite = new FNFSprite(0, 0);
		rating.frames = FtrAssets.getUIAsset('ratingSheet', XML);

		for (i in 0...Highscore.RATINGS[0].length)
			rating.addAnim(Highscore.RATINGS[0][i], Highscore.RATINGS[0][i]);

		rating.alpha = preload ? 0.000001 : 1;
		rating.screenCenter();
		rating.setGraphicSize(Std.int(rating.width * 0.7));
		rating.updateHitbox();
		rating.playAnim(name);
		rating.acceleration.y = 550;
		rating.velocity.y -= FlxG.random.int(140, 175);
		rating.velocity.x -= FlxG.random.int(0, 10);
		FlxG.state.add(rating);

		FlxTween.tween(rating, {alpha: 0}, Conductor.beatCrochet / 1000, {
			onComplete: (twn:FlxTween) -> rating.destroy(),
			startDelay: ((Conductor.beatCrochet + Conductor.stepCrochet * 2) / 1000)
		});
	}
}
