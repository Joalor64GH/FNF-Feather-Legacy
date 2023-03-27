package game.system;

interface IMusicSync
{
	public function onBeat():Void;
	public function onStep():Void;
	public function onSec():Void;
}
