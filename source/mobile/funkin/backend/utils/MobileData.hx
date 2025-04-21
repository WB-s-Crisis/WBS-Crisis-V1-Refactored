/*
 * Copyright (C) 2025 Mobile Porting Team
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

package mobile.funkin.backend.utils;

#if TOUCH_CONTROLS
import haxe.ds.Map;
import haxe.Json;
import haxe.io.Path;
import openfl.utils.Assets;
import flixel.util.FlxSave;

/**
 * ...
 * @base author: Karim Akra
 */
class MobileData
{
	public static var actionModes:Map<String, TouchButtonsData> = new Map();
	public static var dpadModes:Map<String, TouchButtonsData> = new Map();
	
	public static var yuanshenModes:Map<String, TouchButtonsData> = new Map();

	public static var save:FlxSave;

	public static function init()
	{
		save = new FlxSave();
		save.bind('MobileControls', #if sys 'YoshiCrafter29/CodenameEngine' #else 'CodenameEngine' #end);

		for (folder in [
			'${ModsFolder.modsPath}${ModsFolder.currentModFolder}/mobile',
			Paths.getPath('mobile')
		])
			if (FileSystem.exists(folder) && FileSystem.isDirectory(folder))
			{
				setMap('$folder/DPadModes', dpadModes);
				setMap('$folder/ActionModes', actionModes);
			}
		
		startYuanshen(yuanshenModes);
	}

	public static function setMap(folder:String, map:Map<String, TouchButtonsData>)
	{
		for (file in FileSystem.readDirectory(folder))
		{
			if (Path.extension(file) == 'json')
			{
				file = Path.join([folder, Path.withoutDirectory(file)]);
				var str = File.getContent(file);
				var json:TouchButtonsData = cast Json.parse(str);
				var mapKey:String = Path.withoutDirectory(Path.withoutExtension(file));
				map.set(mapKey, json);
			}
		}
	}
	
	private static function startYuanshen(map:Map<String, TouchButtonsData>):Map<String, TouchButtonsData> {
				map.set("LEFT_FULL", cast {
					buttons: [
						{
							button: "buttonLeft",
							graphic: "left",
							x: 0,
							y: FlxG.height - 246,
							color: "0xFFFF00FF"
						},
						{
							button: "buttonDown",
							graphic: "down",
							x: 105,
							y: FlxG.height - 131,
							color: "0xFF00FFFF"
						},
						{
							button: "buttonUp",
							graphic: "up",
							x: 105,
							y: FlxG.height - 356,
							color: "0xFF00FF00"
						},
						{
							button: "buttonRight",
							graphic: "right",
							x: 207,
							y: FlxG.height - 246,
							color: "0xFFFF0000"
						},
						{
							button: "buttonExtra",
							graphic: "default",
							x: FlxG.width - 132,
							y: FlxG.height - 131,
							color: "0xFFFFCB00"
						}
					]
				});
				map.set("RIGHT_FULL", cast {
					buttons: [
						{
							button: "buttonLeft",
							graphic: "left",
							x: FlxG.width - 384,
							y: FlxG.height - 305,
							color: "0xFFFF00FF"
						},
						{
							button: "buttonDown",
							graphic: "down",
							x: FlxG.width - 258,
							y: FlxG.height - 197,
							color: "0xFF00FFFF"
						},
						{
							button: "buttonUp",
							graphic: "up",
							x: FlxG.width - 258,
							y: FlxG.height - 404,
							color: "0xFF00FF00"
						},
						{
							button: "buttonRight",
							graphic: "right",
							x: FlxG.width - 132,
							y: FlxG.height - 305,
							color: "0xFFFF0000"
						},
						{
							button: "buttonExtra",
							graphic: "default",
							x: 0,
							y: FlxG.height - 131,
							color: "0xFFFFCB00"
						}
					]
				});
			
			return map;
	}
}

typedef TouchButtonsData =
{
	buttons:Array<ButtonsData>
}

typedef ButtonsData =
{
	button:String, // what TouchButton should be used, must be a valid TouchButton var from TouchPad as a string.
	graphic:String, // the graphic of the button, usually can be located in the TouchPad xml .
	x:Float, // the button's X position on screen.
	y:Float, // the button's Y position on screen.
	color:String // the button color, default color is white.
}
#end
