package mobile.funkin.backend.system;

#if mobile
import flixel.ui.FlxButton;
import flixel.text.FlxText;
import flixel.addons.display.FlxBackdrop;
import flixel.group.FlxGroup;
import openfl.display.BitmapData;
import openfl.display.Shape;
import funkin.backend.system.Main;
import mobile.extra.VirtualPad;
import mobile.extra.Hitbox;
import flixel.FlxSubState;

/**
 * @author: GeXie(Vapire Mox)
 */
class ButtonSubState extends FlxSubState {
	public var camButton:FlxCamera;

	public var bg:FlxBackdrop;
	public var virtualPad:VirtualPad;
	public var hitbox:Hitbox;

	public var exitButton:FlxButton;
	public var saveButton:FlxButton;

	public var arrows:FlxTypedGroup<FlxSprite>;
	public var labelText:FlxText;

	public var debugText:FlxText;

	public static var displayOptions:Array<String> = ["Right", "Left", "Hitbox", "Custom", "Keyboard"];
	public static var realOptions:Array<String> = ["RIGHT_FULL", "LEFT_FULL", "HITBOX", "CUSTOM", "KEYBOARD"];
	public var curOptions:Int = realOptions.indexOf(Options.buttonsType);

	var canDo:Bool = false;

	var arrowsZhen:Array<Bool> = [false, false];
	var trackedCustomPressed:Array<Bool> = [false, false, false, false, false];
	var trackedCustomContent:Array<Dynamic> = [];

	var prevCustomPos:Array<Array<Float>>;

	public function new() {
		FlxG.state.persistentUpdate = false;
		FlxG.state.persistentDraw = true;
		prevCustomPos = getButtonCustomPos();
		
		super();
	}

	override function create() {
		camButton = new FlxCamera();
		camButton.bgColor = 0;
		FlxG.cameras.add(camButton);

		bg = new FlxBackdrop(createLgBackdrop(0xFF00FF00));
		bg.antialiasing = Options.antialiasing;
		bg.alpha = 0.35;
		bg.cameras = [camButton];
		add(bg);

		virtualPad = new VirtualPad(Options.buttonsType, true);
		virtualPad.forEach((button:TouchButton) -> {
			button.ID = virtualPad.members.indexOf(button);

			button.onDown.callback = function() {
				if(!trackedCustomPressed.contains(true) && realOptions[curOptions] == "CUSTOM") {
					trackedCustomPressed[button.ID] = true;
				trackedCustomContent.push({
						x: button.x,
						y: button.y
					});

					CoolUtil.playMenuSFX();
					debugText.visible = true;
					debugText.text = "(Cur Button: " + button.ID + ")\n(X: " + button.x + " | Y: " + button.y + ")";
					debugText.y = FlxG.height - debugText.height;
				}
			};
			button.onUp.callback = function() {
				if(trackedCustomPressed.contains(true) && realOptions[curOptions] == "CUSTOM") {
					trackedCustomPressed[button.ID] = false;
					trackedCustomContent.pop();

					var ok = prevCustomPos[button.ID];
					ok[0] = button.x;
					ok[1] = button.y;

					debugText.visible = false;
				}
			};
		});
		virtualPad.cameras = [camButton];
		add(virtualPad);

		hitbox = new Hitbox();
		hitbox.cameras = [camButton];
		add(hitbox);

		debugText = new FlxText(0, FlxG.height, FlxG.width, "bean");
		debugText.antialiasing = Options.antialiasing;
		debugText.setFormat(Paths.font("vcr.ttf"), 24, 0xFFFFFFFF, null, OUTLINE, 0xFF4D0000);
		debugText.borderSize *= 2;
		debugText.cameras = [camButton];
		add(debugText);

		labelText = new FlxText(150, 30, 0, "nothing", 16);
		labelText.setFormat(Paths.font("vcr.ttf"), 64, 0xFFFFFFFF, null, OUTLINE, 0xFF4D0000);
		labelText.antialiasing = Options.antialiasing;
		labelText.borderSize *= 2;
		labelText.cameras = [camButton];
		add(labelText);

		saveButton = new FlxButton(700, 30, "Save", saveCallback);
		saveButton.antialiasing = Options.antialiasing;
		saveButton.scale.set(3, 3);
		saveButton.updateHitbox();
		saveButton.color = 0xFF00FF00;

		saveButton.label.fieldWidth = saveButton.width;
		saveButton.label.setFormat(Paths.font("vcr.ttf"), 48, 0xFFFFFFFF, "center");
		saveButton.label.offset.y -= Math.abs(saveButton.height - saveButton.label.height) / 2;
		add(saveButton);

		exitButton = new FlxButton(988.48, 30, "Exit", exitCallback);
		exitButton.antialiasing = Options.antialiasing;
		exitButton.scale.set(3, 3);
		exitButton.updateHitbox();
		exitButton.color = 0xFFFF0000;

		exitButton.label.fieldWidth = exitButton.width;
		exitButton.label.setFormat(Paths.font("vcr.ttf"), 48, 0xFFFFFFFF, "center");
		exitButton.label.offset.y -= Math.abs(exitButton.height - exitButton.label.height) / 2;
		add(exitButton);

		arrows = new FlxTypedGroup<FlxSprite>(2);
		arrows.cameras = [camButton];
		add(arrows);
		makeArrows(arrows);

		camButton.alpha = 0;
		FlxTween.tween(camButton, {alpha: 1}, 0.35, {onComplete: (_) -> {
			canDo = true;
		}});
		FlxTween.tween(Main.instance.framerateSprite, {alpha: 0.1}, 0.35);
		selection(0, true);
		
		super.create();
	}

	override function update(elapsed:Float) {
		if(canDo) {
			bg.x += elapsed * 25;
			bg.y += elapsed * 25;
			if(realOptions[curOptions] == "CUSTOM") {
				for(touch in FlxG.touches.list) {
					var touchPos = touch.getScreenPosition(camButton);

					for(button in virtualPad.iterator()) {
						if(trackedCustomPressed[button.ID]) {
							button.setPosition(touchPos.x - (touch.justPressedPosition.x - trackedCustomContent[trackedCustomContent.length - 1].x), touchPos.y - (touch.justPressedPosition.y - trackedCustomContent[trackedCustomContent.length - 1].y));
							debugText.text = "(Cur Button: " + button.ID + ")\n(X: " + button.x + " | Y: " + button.y + ")";
							break;
						}
					}
				}
			}

			if(arrows != null && arrows.active) {
				arrows.forEach((obj:FlxSprite) -> {
					if(!obj.visible || !obj.active) return;

					if(
						FlxG.mouse.screenX >= obj.x && FlxG.mouse.screenX <= obj.x + obj.width
						&& FlxG.mouse.screenY >= obj.y && FlxG.mouse.screenY <= obj.y + obj.height
					) {
						if(FlxG.mouse.justPressed) {
							arrowsZhen[obj.ID % 2] = true;
							obj.animation.play("press");
						}

						if(FlxG.mouse.justReleased) {
							if(arrowsZhen[obj.ID % 2]) {
								obj.animation.play("static");
								selection((obj.ID % 2 == 0 ? -1 : 1));
								arrowsZhen[obj.ID % 2] = false;
							}
						}
					}else {
						if(arrowsZhen[obj.ID % 2]) {
							obj.animation.play("static");
							arrowsZhen[obj.ID % 2] = false;
						}
					}
				});
			}
		}

		super.update(elapsed);
	}

	function makeArrows(group:FlxTypedGroup<FlxSprite>) {
		final chosen = ["left", "right"];
		for(i in 0...group.maxSize) {
			var arrow:FlxSprite = new FlxSprite();
			arrow.antialiasing = Options.antialiasing;
			arrow.ID = i;
			arrow.frames = Paths.getFrames("menus/storymenu/assets");
			arrow.animation.addByPrefix("static", "arrow " + chosen[i % 2], 1, true);
			arrow.animation.addByPrefix("press", "arrow push " + chosen[i % 2], 1, true);
			arrow.animation.play("static");

			group.add(arrow);
		}
	}

	function selection(change:Int, choDefault:Bool = false) {
		curOptions += change;
		if(curOptions > realOptions.length - 1) curOptions = 0;
		if(curOptions < 0) curOptions = realOptions.length - 1;

		virtualPad.visible = false;
		hitbox.visible = false;

		switch(realOptions[curOptions]) {
			case "LEFT_FULL":
				virtualPad.visible = true;
				updateButtonsPos();
			case "RIGHT_FULL":
				virtualPad.visible = true;
				updateButtonsPos();
			case "HITBOX":
				hitbox.visible = true;
			case "CUSTOM":
				virtualPad.visible = true;
				updateButtonsPos();
			case "KEYBOARD":
		}

		labelText.text = displayOptions[(curOptions < 0 ? 0 : curOptions)];
		updateArrowsPos(arrows, !choDefault);
	}

	public function updateArrowsPos(group:FlxTypedGroup<FlxSprite>, tween:Bool = false) {
		if(labelText == null) return;
		if(!labelText.active) return;

		final sureTween:Bool = tween;
		final offset:Float = 25;
		var targetValueX:Float = 0;
		var targetValueY:Float = 0;
		group.forEach((obj) -> {
			targetValueY = labelText.y + (labelText.height - obj.height) / 2;
			switch(obj.ID) {
				case 0:
					targetValueX = labelText.x - obj.width - offset;
				case 1:
					targetValueX = labelText.x + labelText.width + offset;
				default: {}
			}

			if(!sureTween) obj.setPosition(targetValueX, targetValueY);
			else FlxTween.tween(obj, {x: targetValueX, y: targetValueY}, 0.1, {ease: FlxEase.quadInOut});
		});
	}

	public function updateButtonsPos() {
		if(virtualPad == null || !virtualPad.active) return;

		virtualPad.forEach((obj:TouchButton) -> {
			if(MobileData.yuanshenModes.get(realOptions[curOptions]) != null) {
				final list = MobileData.yuanshenModes.get(realOptions[curOptions]);
				obj.setPosition(list.buttons[obj.ID].x, list.buttons[obj.ID].y);
				if(obj.ID > 3 && Options.hitboxPos != "BOTTOM") obj.y = 0;
			}else if(realOptions[curOptions] == "CUSTOM") {
				obj.setPosition(prevCustomPos[obj.ID][0], prevCustomPos[obj.ID][1]);
			}
		});
	}

	static inline function getButtonCustomPos():Array<Array<Float>> {
		var result:Array<Array<Float>> = [];
		for(array in Options.buttonsCustomPos) {
			result.push(array.copy());
		}
		return result;
	}

	static function setButtonCustomPos(val:Array<Array<Float>>, tar:Array<Array<Float>>) {
		for(i in 0...tar.length) {
			tar[i] = val[i].copy();
		}
	}

	private function saveCallback() {
		Options.buttonsType = realOptions[curOptions];
		setButtonCustomPos(prevCustomPos, Options.buttonsCustomPos);
		Options.save();
	}

	private function exitCallback() {
		canDo = false;
		FlxTween.tween(camButton, {alpha: 0}, 0.35, {onComplete: (_) -> {
			FlxG.state.persistentUpdate = true;
			FlxG.state.persistentDraw = true;
			close();
		}});
		FlxTween.tween(Main.instance.framerateSprite, {alpha: 1}, 0.35);
	}

	static inline function createLgBackdrop(color:Int = 0xFFFFFFFF) {
		var bitmapData = new BitmapData(128, 128, true, 0x00000000);
		var drawShape = new Shape();

		var choose = [{x: 0, y: 0, color: color}, {x: Std.int(bitmapData.width / 2), y: 0, color: 0xFFFFFFFF}, {x: 0, y: Std.int(bitmapData.height / 2), color: 0xFFFFFFFF}, {x: Std.int(bitmapData.width / 2), y: Std.int(bitmapData.height / 2), color: color}];
		for(ch in choose) {
			drawShape.graphics.beginFill(ch.color);
			drawShape.graphics.drawRect(ch.x, ch.y, Std.int(bitmapData.width / 2), Std.int(bitmapData.height / 2));
			drawShape.graphics.endFill();
		}
		bitmapData.draw(drawShape);

		return bitmapData;
	}
}
#end