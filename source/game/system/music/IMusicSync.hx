package game.system.music;

interface IMusicSync
{
	public function onBeat():Void;
	public function onStep():Void;
	public function onSec():Void;
}
