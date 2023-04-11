package feather.core;

typedef FNFAnimation = {
	var name:String;
	var prefix:String;
	var ?frames:Array<Int>;
	var ?animOffsets:Array<Float>;
	var ?indices:Array<Int>;
	var ?framerate:Int;
	var ?looped:Bool;
	var ?flipX:Bool;
	var ?flipY:Bool;
}

interface ISpriteOffset {
	public var offsets:Map<String, Array<Float>>;
	public function addOffset(anim:String, ?newOffset:Array<Float>):Void;
}

class FNFSprite extends FlxSprite implements ISpriteOffset {
	public var depth:Float = 0;

	public static function depthOrder(Order:Int, a:FNFSprite, b:FNFSprite):Int
		return a.depth > b.depth ? -Order : Order;

	public var offsets:Map<String, Array<Float>> = new Map<String, Array<Float>>();

	public function addOffset(anim:String, ?newOffset:Array<Float>):Void {
		if (newOffset.length < 1)
			newOffset[1] = 0;

		offsets[anim] = newOffset;
	}

	/*
	 * ...
	 * @author Yoshubs
	**/
	public function resizeOffsets(?newScale:Float):Void {
		if (newScale == null)
			newScale = scale.x;
		for (i in offsets.keys())
			offsets[i] = [offsets[i][0] * newScale, offsets[i][1] * newScale];
	}

	public function new(x:Float = 0, y:Float = 0):Void {
		super(x, y);
	}

	public override function loadGraphic(image:String, animated:Bool = false, width:Int = 0, height:Int = 0, unique:Bool = false, ?key:String):FNFSprite {
		loadGraphic(AssetHandler.getAsset(image, IMAGE), animated, width, height, unique, key);
		return this;
	}

	public function loadFrames(image:String, ?animations:Array<FNFAnimation>):FNFSprite {
		frames = AssetHandler.getAsset(image, XML);
		if (animations != null)
			for (i in animations)
				addAnim(i.name, i.prefix, i.animOffsets, i.framerate, i.looped, i.indices, i.flipX, i.flipY);
		return this;
	}

	public function copyFrom(copySprite:FNFSprite):FNFSprite {
		if (copySprite != null && copySprite.exists) {
			var animated:Bool = copySprite.frameWidth > 0 && copySprite.frameHeight > 0;

			if (copySprite.frames != null)
				frames = copySprite.frames;
			else
				loadGraphic(copySprite.graphic.key, animated, copySprite.frameWidth, copySprite.frameHeight);
			animation.copyFrom(copySprite.animation);
		}
		return this;
	}

	public function addAnim(name:String, prefix:String, ?animOffsets:Array<Float>, framerate:Int = 24, looped:Bool = false, ?indices:Array<Int>,
			?flipX:Bool = false, ?flipY:Bool = false):Void {
		if (indices != null && indices.length > 0)
			animation.addByIndices(name, prefix, indices, '', framerate, looped, flipX, flipY);
		else
			animation.addByPrefix(name, prefix, framerate, looped, flipX, flipY);

		if (!offsets.exists(name) && animOffsets != null)
			addOffset(name, animOffsets);
	}

	public function playAnim(name:String, force:Bool = false, reversed:Bool = false, frame = 0):Void {
		animation.play(name, force, reversed, frame);

		if (offsets.exists(name))
			offset.set(offsets[name][0], offsets[name][1]);
	}
}
