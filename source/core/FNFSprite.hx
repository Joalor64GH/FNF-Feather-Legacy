package core;

typedef FNFAnimation =
{
	var name:String;
	var prefix:String;
	var ?animOffsets:Array<Float>;
	var ?fps:Int;
	var ?looped:Bool;
	var ?indices:Array<Int>;
}

interface ISpriteOffset
{
	public var offsets:Map<String, Array<Float>>;
	public function addOffset(anim:String, ?newOffset:Array<Float>):Void;
}

class FNFSprite extends FlxSprite implements ISpriteOffset
{
	public var offsets:Map<String, Array<Float>> = new Map<String, Array<Float>>();

	public function addOffset(anim:String, ?newOffset:Array<Float>):Void
	{
		if (newOffset.length < 1)
			newOffset[1] = 0;

		offsets[anim] = newOffset;
	}

	public function new(x:Float = 0, y:Float = 0):Void
	{
		super(x, y);
	}

	public override function loadGraphic(image:String, animated:Bool = false, width:Int = 0, height:Int = 0, unique:Bool = false, ?key:String)
	{
		return super.loadGraphic(AssetHandler.getAsset(image, IMAGE), animated, width, height, unique, key);
	}

	public function addAnim(name:String, prefix:String, ?animOffsets:Array<Float>, fps:Int = 24, looped:Bool = false, ?indices:Array<Int>):Void
	{
		if (indices != null && indices.length > 0)
			animation.addByIndices(name, prefix, indices, '', fps, looped);
		else
			animation.addByPrefix(name, prefix, fps, looped);

		if (!offsets.exists(name) && animOffsets != null)
			addOffset(name, animOffsets);
	}

	public function playAnim(name:String, force:Bool = false, reversed:Bool = false, frame = 0):Void
	{
		animation.play(name, force, reversed, frame);

		if (offsets.exists(name))
			offset.set(offsets[name][0], offsets[name][1]);
	}

	public function playingAnims():Bool
		return animation != null && animation.curAnim != null;
}
