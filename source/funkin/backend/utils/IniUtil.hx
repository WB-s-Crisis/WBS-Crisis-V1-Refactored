package funkin.backend.utils;

//你需要一份这个
import hxIni.IniManager;


/**
 * DOESNT SUPPORT CATEGORIES YET!!
 */
@:allow(funkin.backend.utils.CoolUtil) class IniUtil {
	public static inline function parseAsset(assetPath:String, ?defaultVariables:Map<String, String>)
		return parseString(Assets.getText(assetPath), defaultVariables);

	/**
	 * 仅提供与CoolUtil
	 * @param data 歌曲信息
	 * @param defaultVariables def
	 */
	private static function parseString(data:String, ?defaultVariables:Map<String, String>):Map<String, String> {
		try {
			return parseStringFromGlobal(data);
		}catch(e:Dynamic) {
			trace("parse ini failed");
			return defaultVariables;
		}
	}

	public static function parseStringFromGlobal(data:String) {
		return parseStringFromCategories(data, "Global");
	}

	public static function parseStringFromCategories(data:String, categories:String = "Global") {
		var iniData = IniManager.loadFromString(data);

		if(!iniData.exists(categories)) {
			trace('not exists categories "$categories"');

			return null;
		}

		return iniData.get(categories);
	}
}