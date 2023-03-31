package core.assets;

import openfl.Assets;
import openfl.media.Sound;

/**
 * Class that contains various functions for handling UI elements
 * and providing custom instances for those elements, such as UI Skins
 */
class FtrAssets {
	public static function getUIAsset(asset:String, type:AssetType = IMAGE, skin:String = 'default'):Dynamic {
		var path:String = AssetHandler.getPath('images/ui/${skin}/${asset}', type);
		if (!Assets.exists(path))
			skin = 'default';

		return AssetHandler.getAsset('images/ui/${skin}/${asset}', type);
	}

	public static function getUISound(sound:String, skin:String = 'default'):Sound {
		var path:String = AssetHandler.getPath('sounds/${skin}/${sound}', SOUND);
		if (!Assets.exists(path))
			skin = 'default';

		return AssetHandler.getAsset('sounds/${skin}/${sound}', SOUND);
	}
}
