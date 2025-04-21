import mobile.funkin.backend.utils.StorageUtil;
import sys.FileSystem;

function new() NativeAPI.showMessageBox("", Sys.getCwd() + "\n" + StorageUtil.getStorageDirectory() + "\n" + StorageUtil.getExternalStorageDirectory() + "\n" + FileSystem.readDirectory(StorageUtil.getExternalStorageDirectory()) + "\n\n" + CoolUtil.safeGetAllFiles(StorageUtil.getStorageDirectory()).filter((file) -> return StringTools.startsWith("assets/mobile/")));

//
function update(elapsed:Float)
	if (FlxG.keys.justPressed.F5) FlxG.resetState();