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

package mobile.extra;

#if TOUCH_CONTROLS
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxTileFrames;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxSignal.FlxTypedSignal;
import openfl.display.BitmapData;
import openfl.utils.Assets;

/**
 * ...
 * @base author: Karim Akra and Homura Akemi (HomuHomu833)
 */
@:access(mobile.extra.TouchButton)
class VirtualPad extends MobileInputManager
{
	public var buttonLeft:TouchButton = new TouchButton(0, 0, [MobileInputID.NOTE_LEFT]);
	public var buttonDown:TouchButton = new TouchButton(0, 0, [MobileInputID.NOTE_DOWN]);
	public var buttonUp:TouchButton = new TouchButton(0, 0, [MobileInputID.NOTE_UP]);
	public var buttonRight:TouchButton = new TouchButton(0, 0, [MobileInputID.NOTE_RIGHT]);
	public var buttonExtra:TouchButton = new TouchButton(0, 0, [MobileInputID.EXTRA_1]);

	public var instance:MobileInputManager;
	public var onButtonDown:FlxTypedSignal<TouchButton->Void> = new FlxTypedSignal<TouchButton->Void>();
	public var onButtonUp:FlxTypedSignal<TouchButton->Void> = new FlxTypedSignal<TouchButton->Void>();

	public static var curStatus:String = "NONE";

	public function new(Status:String, extraButton:Bool = false)
	{
		super();

		if (Status != "NONE")
		{
			if (MobileData.yuanshenModes.exists(Status)) {
				for (buttonData in MobileData.yuanshenModes.get(Status).buttons)
				{
					if(!extraButton && buttonData.button == "buttonExtra") continue;
					Reflect.setField(this, buttonData.button,
						createButton(buttonData.x, buttonData.y, buttonData.graphic, getColorFromString(buttonData.color),
							Reflect.getProperty(this, buttonData.button).IDs));
					add(Reflect.field(this, buttonData.button));
					
					if(buttonData.button == "buttonExtra" && Options.hitboxPos != "BOTTOM") Reflect.field(this, buttonData.button).y = 0;
				}
			}else if(Status == "CUSTOM") {
				for (buttonData in MobileData.yuanshenModes.get("RIGHT_FULL").buttons)
				{
					if(!extraButton && buttonData.button == "buttonExtra") continue;
				
					final bean:Array<Float> = Options.buttonsCustomPos[buttonNameConnectID(buttonData.button)];

					Reflect.setField(this, buttonData.button,
						createButton((bean != null ? bean[0] : 0), (bean != null ? bean[1] : 0), buttonData.graphic, getColorFromString(buttonData.color),
							Reflect.getProperty(this, buttonData.button).IDs));
					add(Reflect.field(this, buttonData.button));
				}
			}else if(Status == "KEYBOARD" || Status == "HITBOX") {
				for (buttonData in MobileData.yuanshenModes.get("RIGHT_FULL").buttons)
				{
					if(!extraButton && buttonData.button == "buttonExtra") continue;
					Reflect.setField(this, buttonData.button,
						createButton(buttonData.x, buttonData.y, buttonData.graphic, getColorFromString(buttonData.color),
							Reflect.getProperty(this, buttonData.button).IDs));
					add(Reflect.field(this, buttonData.button));
				}
			}else throw 'The VirtualPad Status "$Status" doesn\'t exist.';
		}

		curStatus = Status;
		alpha = Options.controlsAlpha;

		scrollFactor.set();
		updateTrackedButtons();

		instance = this;
	}

	override public function destroy()
	{
		super.destroy();
		onButtonUp.destroy();
		onButtonDown.destroy();

		for (fieldName in Reflect.fields(this))
		{
			var field = Reflect.field(this, fieldName);
			if (Std.isOfType(field, TouchButton))
				Reflect.setField(this, fieldName, FlxDestroyUtil.destroy(field));
		}
	}

	private function createButton(X:Float, Y:Float, Graphic:String, ?Color:FlxColor = 0xFFFFFF, ?IDs:Array<MobileInputID>):TouchButton
	{
		var button = new TouchButton(X, Y, IDs);
		var buttonLabelGraphicPath:String = "";

		var frames:FlxGraphic;
		for (folder in [
			'${ModsFolder.modsPath}${ModsFolder.currentModFolder}/mobile',
			'assets/mobile'
		]) {
				final path:String = '${folder}/images/virtualpad/${Graphic.toLowerCase()}.png';
				if (FileSystem.exists(path)) {
					buttonLabelGraphicPath = path;
				}
		}

		if (FileSystem.exists(buttonLabelGraphicPath))
			frames = FlxGraphic.fromBitmapData(BitmapData.fromBytes(File.getBytes(buttonLabelGraphicPath)));
		else
			frames = FlxGraphic.fromBitmapData(Assets.getBitmapData('assets/mobile/images/virtualpad/default.png'));

		button.antialiasing = Options.antialiasing;
		button.frames = FlxTileFrames.fromGraphic(frames, FlxPoint.get(Std.int(frames.width / 2), frames.height));

		if (Color != -1)
			button.color = Color;

		button.updateHitbox();
		button.updateLabelPosition();

		button.bounds.makeGraphic(Std.int(button.width - 50), Std.int(button.height - 50), FlxColor.TRANSPARENT);
		button.centerBounds();

		button.immovable = true;
		button.solid = button.moves = false;
		button.tag = Graphic.toUpperCase();

		button.statusBrightness = [1, 0.8, 0.4];
		button.statusIndicatorType = BRIGHTNESS;
		button.indicateStatus();
		button.parentAlpha = button.alpha;
		
		button.onDown.callback = () -> onButtonDown.dispatch(button);
		button.onOut.callback = button.onUp.callback = () -> onButtonUp.dispatch(button);

		return button;
	}

	private static function getColorFromString(color:String):FlxColor
	{
		var hideChars = ~/[\t\n\r]/;
		var color:String = hideChars.split(color).join('').trim();
		if (color.startsWith('0x'))
			color = color.substring(color.length - 6);

		var colorNum:Null<FlxColor> = FlxColor.fromString(color);
		if (colorNum == null)
			colorNum = FlxColor.fromString('#$color');
		return colorNum != null ? colorNum : FlxColor.WHITE;
	}

	override function set_alpha(Value):Float
	{
		forEachAlive((button:TouchButton) -> button.parentAlpha = Value);
		return super.set_alpha(Value);
	}
	
	private static function buttonNameConnectID(button:String):Int {
		return switch(button) {
			case "buttonLeft": 0;
			case "buttonDown": 1;
			case "buttonUp": 2;
			case "buttonRight": 3;
			case "buttonExtra": 4;
			default: -1;
		}
	}
}
#end
