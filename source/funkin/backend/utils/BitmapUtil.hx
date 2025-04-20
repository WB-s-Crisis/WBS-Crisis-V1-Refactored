package funkin.backend.utils;

import openfl.display.BitmapData;
import openfl.geom.Matrix;
import flixel.util.FlxColor;

class BitmapUtil {
	/**
	 * Returns the most present color in a Bitmap.
	 * @param bmap Bitmap
	 * @return FlxColor Color that is the most present.
	 */
	public static function getMostPresentColor(bmap:BitmapData):FlxColor {
		// map containing all the colors and the number of times they've been assigned.
		var colorMap:Map<FlxColor, Float> = [];
		var color:FlxColor = 0;
		var fixedColor:FlxColor = 0;

		for(y in 0...bmap.height) {
			for(x in 0...bmap.width) {
				color = bmap.getPixel32(x, y);
				fixedColor = 0xFF000000 + (color % 0x1000000);
				if (!colorMap.exists(fixedColor))
					colorMap[fixedColor] = 0;
				colorMap[fixedColor] += color.alphaFloat;
			}
		}

		var mostPresentColor:FlxColor = 0;
		var mostPresentColorCount:Float = -1;
		for(c=>n in colorMap) {
			if (n > mostPresentColorCount) {
				mostPresentColorCount = n;
				mostPresentColor = c;
			}
		}
		return mostPresentColor;
	}
	/**
	 * Returns the most present saturated color in a Bitmap.
	 * @param bmap Bitmap
	 * @return FlxColor Color that is the most present.
	 */
	public static function getMostPresentSaturatedColor(bmap:BitmapData):FlxColor {
		// map containing all the colors and the number of times they've been assigned.
		var colorMap:Map<FlxColor, Float> = [];
		var color:FlxColor = 0;
		var fixedColor:FlxColor = 0;

		for(y in 0...bmap.height) {
			for(x in 0...bmap.width) {
				color = bmap.getPixel32(x, y);
				fixedColor = 0xFF000000 + (color % 0x1000000);
				if (!colorMap.exists(fixedColor))
					colorMap[fixedColor] = 0;
				colorMap[fixedColor] += color.alphaFloat * 0.33 + (0.67 * (color.saturation * (2 * (color.lightness > 0.5 ? 0.5 - (color.lightness) : color.lightness))));
			}
		}

		var mostPresentColor:FlxColor = 0;
		var mostPresentColorCount:Float = -1;
		for(c=>n in colorMap) {
			if (n > mostPresentColorCount) {
				mostPresentColorCount = n;
				mostPresentColor = c;
			}
		}
		return mostPresentColor;
	}
	
	public static function getGameScreenBitmapData(ms:Float = 0.075):BitmapData {
		if(ms < 0.075) ms = 0.075;
		var screenShot = new BitmapData(FlxG.width, FlxG.height, true, 0x00000000);

		function switchP() {
			var matrix = new Matrix();
			matrix.translate(-FlxG.game.x, -FlxG.game.y);
			matrix.scale(1/FlxG.scaleMode.scale.x, 1/FlxG.scaleMode.scale.y);

			screenShot.draw(BitmapData.fromImage(FlxG.stage.window.readPixels()), matrix);
		}

		if(!Options.fpsCounter) {
			switchP();
		}else {
			Main.instance.framerateSprite.alpha = 0;
			new FlxTimer().start(ms, (tmr) -> {
				switchP();
				Main.instance.framerateSprite.alpha = 1;
			});
		}

		return screenShot;
	}
}