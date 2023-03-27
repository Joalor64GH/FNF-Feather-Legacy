package game.ui;

import core.FNFSprite;

class HealthIcon extends FNFSprite
{
	public var char:String = 'bf';
	public var isPlayer:Bool = false;

	public function new(char:String = 'bf', isPlayer:Bool = false):Void
	{
		super();
	}
}
