import mobile.funkin.backend.utils.StorageUtil;
import sys.FileSystem;

function new() NativeAPI.showMessageBox("", Sys.getCwd() + "\n" + StorageUtil.getStorageDirectory() + "\n" + StorageUtil.getExternalStorageDirectory() + "\n" + FileSystem.exists(StorageUtil.getStorageDirectory()));

//
function update(elapsed:Float)
	if (FlxG.keys.justPressed.F5) FlxG.resetState();