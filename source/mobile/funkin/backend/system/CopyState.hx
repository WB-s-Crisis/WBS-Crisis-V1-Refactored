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

package mobile.funkin.backend.system;

#if mobile
import lime.utils.Assets as LimeAssets;
import openfl.utils.Assets as OpenFLAssets;
import flixel.text.FlxText;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import openfl.utils.ByteArray;
import haxe.io.Path;
import funkin.backend.utils.NativeAPI;
import funkin.extra.PsychBar;
import lime.system.ThreadPool;

#if sys
import sys.io.File;
import sys.FileSystem;
#end

using StringTools;

/**
 * ...
 * @base author: Karim Akra
 */
class CopyState extends funkin.backend.MusicBeatState
{
	private static final textFilesExtensions:Array<String> = ['ini', 'txt', 'xml', 'hxs', 'hx', 'lua', 'json', 'frag', 'vert'];
	public static final IGNORE_FOLDER_FILE_NAME:String = "CopyState-Ignore.txt";
	private static var directoriesToIgnore:Array<String> = [];
	private static var curContent:Unused = {
		curLoop: -1,
		curText: "",
		curColor: 0
	};
	public static var locatedFiles:Array<String> = [];
	//删除额外的文件以及目录
	public static var vmFiles:Array<String> = [];
	public static var maxLoopTimes:Int = 0;
	public static var oneshot:Bool = false;

	public var loadingImage:FlxSprite;
	public var loadingBar:PsychBar;
	public var loadedText:FlxText;
	public var thread:ThreadPool;

	var failedFilesStack:Array<String> = [];
	var failedFiles:Array<String> = [];
	var shouldCopy:Bool = false;
	var canUpdate:Bool = true;
	var loopTimes:Int = 0;

	public function new() {
		super(false);
	}

	override function create()
	{
		//locatedFiles = [];
		//maxLoopTimes = 0;
		//checkExistingFiles();
		if (maxLoopTimes <= 0)
		{
			FlxG.resetGame();
			return;
		}

		shouldCopy = true;

		add(new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, 0xffcaff4d));

		loadingImage = new FlxSprite(0, 0, Paths.image('menus/funkay'));
		loadingImage.setGraphicSize(0, FlxG.height);
		loadingImage.updateHitbox();
		loadingImage.screenCenter();
		add(loadingImage);

		loadingBar = new PsychBar(0, FlxG.height - 26, FlxG.width, 26, () -> lerp(loadingBar.percent / 100, loopTimes / maxLoopTimes, Math.exp(-FlxG.elapsed * 75)), 0, 1);
		loadingBar.setColors(0xffff16d2, 0xff004d3d);
		add(loadingBar);

		loadedText = new FlxText(0, loadingBar.y, FlxG.width, '', 16);
		loadedText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, LEFT);
		loadedText.setBorderStyle(OUTLINE, 0xFF4D0000, 1.25);
		loadedText.y -= loadedText.height;
		add(loadedText);

		thread = new ThreadPool(0, CoolUtil.getCPUThreadsCount());

		thread.onProgress.add(function(bean) {
			for(field in Reflect.fields(curContent)) {
				switch(field) {
					case "curLoop": Reflect.setProperty(curContent, field, bean.l);
					case "curText": Reflect.setProperty(curContent, field, bean.t);
					case "curColor": Reflect.setProperty(curContent, field, bean.c);
					default:
				}
			}
		});

		thread.doWork.add(function(poop)
		{
			for (file in locatedFiles)
			{
				thread.sendProgress({l: loopTimes, t: 'Copying file...["$file"]', c: 0xFFFFFFFF});
				loopTimes++;
				copyAsset(file);
			}
		});
		thread.doWork.add(function(_) {
			for(file in vmFiles) {
				thread.sendProgress({l: loopTimes, t: 'Deleting Additional file...["$file"]', c: 0xFFFF6D6D});
				loopTimes++;

				deleteExistFile(file);
			}
			
			if(!FileSystem.exists(".version")) File.saveContent(".version", lime.app.Application.current.meta.get("version").trim());
		});

		new FlxTimer().start(0.314, (tmr) ->
		{
			thread.queue({});
		});

		super.create();
	}

	override function update(elapsed:Float)
	{
		if (shouldCopy)
		{
			if(canUpdate && executableContent()) updateLoadedText('[${curContent.curLoop}/$maxLoopTimes]...${curContent.curText}', curContent.curColor);

			if (loopTimes >= maxLoopTimes && loadingBar.percent > 99 && canUpdate)
			{
				if (failedFiles.length > 0)
				{
					NativeAPI.showMessageBox('Failed To Copy ${failedFiles.length} File.', failedFiles.join('\n'), MSG_ERROR);
					final folder:String = #if android StorageUtil.getExternalStorageDirectory() + #else Sys.getCwd() + #end 'logs/';
					if (!FileSystem.exists(folder))
						FileSystem.createDirectory(folder);
					File.saveContent(folder + Date.now().toString().replace(' ', '-').replace(':', "'") + '-CopyState' + '.txt', failedFilesStack.join('\n'));
				}

				updateLoadedText("Completed!", FlxColor.YELLOW);

				final sound = FlxG.sound.play(Paths.sound('menu/confirm'));
				sound.onComplete = () ->
				{
					directoriesToIgnore = [];
					locatedFiles = [];
					vmFiles = [];
					maxLoopTimes = 0;
					for(field in Reflect.fields(curContent)) {
						switch(field) {
							case "curLoop": Reflect.setProperty(curContent, field, -1);
							case "curText": Reflect.setProperty(curContent, field, "");
							case "curColor": Reflect.setProperty(curContent, field, 0);
							default:
						}
					}
					oneshot = true;

					FlxG.resetGame();
				};
				FlxTween.tween(FlxG.camera, {alpha: 0}, sound.length / 1000 - 314, {startDelay: 0.314});

				canUpdate = false;
			}
		}
		super.update(elapsed);
	}

	public function copyAsset(file:String)
	{
		var directory = Path.directory(file);
		if (!FileSystem.exists(directory))
			FileSystem.createDirectory(directory);
		try
		{
			if (OpenFLAssets.exists(getFile(file)))
			{
				if (textFilesExtensions.contains(Path.extension(file)))
					createContentFromInternal(file);
				else
				{
					var path:String = file;
					#if android
					if (file.startsWith('mods/'))
						path = StorageUtil.getExternalStorageDirectory() + file;
					#end

					File.saveBytes(path, getFileBytes(getFile(file)));
				}
			}
			else
			{
				failedFiles.push(getFile(file) + " (File Dosen't Exist)");
				failedFilesStack.push('Asset ${getFile(file)} does not exist.');
			}
		}
		catch (e:haxe.Exception)
		{
			failedFiles.push('${getFile(file)} (${e.message})');
			failedFilesStack.push('${getFile(file)} (${e.stack})');
		}
	}
	
	public function deleteExistFile(file:String) {
		if(FileSystem.exists(file)) {
			try {
				if(FileSystem.isDirectory(file)) {
					FileSystem.deleteDirectory(file);
				}else {
					final directory = Path.directory(file);
					FileSystem.deleteFile(file);
					//检测若是空目录则清除
					if(FileSystem.readDirectory(directory).length == 0) {
						FileSystem.deleteDirectory(directory);
					}
				}
			} catch(e:haxe.Exception) {
				//没那个打算
			}
		}
	}

	public function createContentFromInternal(file:String)
	{
		var fileName = Path.withoutDirectory(file);
		var directory = Path.directory(file);
		#if android
		if (fileName.startsWith('mods/'))
			directory = StorageUtil.getExternalStorageDirectory() + directory;
		#end
		try
		{
			var fileData:String = OpenFLAssets.getText(getFile(file));
			if (fileData == null)
				fileData = '';
			if (!FileSystem.exists(directory))
				FileSystem.createDirectory(directory);

			File.saveContent(Path.join([directory, fileName]), fileData);
		}
		catch (e:haxe.Exception)
		{
			failedFiles.push('${getFile(file)} (${e.message})');
			failedFilesStack.push('${getFile(file)} (${e.stack})');
		}
	}
	
	private var prevColor:FlxColor = FlxColor.WHITE;
	private function updateLoadedText(content:String, color:FlxColor = FlxColor.WHITE) {
		try {
			if(prevColor != color) {
				loadedText.color = color;
				prevColor = color;
			}
			loadedText.text = content;
			loadedText.y = loadingBar.y - loadedText.height;
		} catch(e:haxe.Exception) {
			failedFiles.push('Update Text Error (${e.message})');
			failedFilesStack.push('Update Text Error (${e.stack})');
		}
	}

	public static function getFileBytes(file:String):ByteArray
	{
		switch (Path.extension(file).toLowerCase())
		{
			case 'otf' | 'ttf':
				return ByteArray.fromFile(file);
			default:
				return OpenFLAssets.getBytes(file);
		}
	}

	public static function getFile(file:String):String
	{
		if (OpenFLAssets.exists(file))
			return file;

		@:privateAccess
		for (library in LimeAssets.libraries.keys())
		{
			if (OpenFLAssets.exists('$library:$file') && library != 'default')
				return '$library:$file';
		}

		return file;
	}

	public static function checkExistingFiles():Bool
	{
		locatedFiles = Paths.assetsTree.list(null);

		vmFiles = CoolUtil.safeGetAllFiles(Sys.getCwd(), false, true).filter((file) -> (!locatedFiles.contains(file) && (file.startsWith("assets/") || file.startsWith("mods/"))));

		// removes unwanted assets
		locatedFiles = locatedFiles.filter((file) -> {
			if(OpenFLAssets.exists(getFile(file))) {
				if(FileSystem.exists(file) #if android || (file.startsWith("mods/") && FileSystem.exists(StorageUtil.getExternalStorageDirectory() + file)) #end) return (file.startsWith("assets") || file.startsWith("mods")) && (getFileBytes(getFile(file)).length != #if android (file.startsWith("mods/") && FileSystem.exists(StorageUtil.getExternalStorageDirectory() + file) ? File.getBytes(StorageUtil.getExternalStorageDirectory() + file).length : File.getBytes(file).length) #else File.getBytes(file).length #end);
				else return (file.startsWith("assets/") || file.startsWith("mods/"));
			}else return false;
		});

		var filesToRemove:Array<String> = [];

		for (file in locatedFiles)
		{
			if (filesToRemove.contains(file))
				continue;

			if (file.endsWith(IGNORE_FOLDER_FILE_NAME) && !directoriesToIgnore.contains(Path.directory(file)))
				directoriesToIgnore.push(Path.directory(file));

			if (directoriesToIgnore.length > 0)
			{
				for (directory in directoriesToIgnore)
				{
					if (file.startsWith(directory))
						filesToRemove.push(file);
				}
			}
		}

		locatedFiles = locatedFiles.filter(file -> !filesToRemove.contains(file));
		maxLoopTimes = locatedFiles.length + vmFiles.length;
		//lime.app.Application.current.window.alert(Std.string(vmFiles));

		return (maxLoopTimes <= 0);
	}

	private static inline function executableContent():Bool
		return curContent.curLoop > -1 && curContent.curText != "" && curContent.curColor != 0;
}

typedef Unused = {
	var curLoop:Int;
	var curText:String;
	var curColor:Int;
}
#end