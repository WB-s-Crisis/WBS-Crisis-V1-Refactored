import mobile.funkin.backend.utils.StorageUtil;

function new() NativeAPI.showMessageBox("", Sys.getCWD() + "\n" + StorageUtil.getStorageDirectory());

//
function update(elapsed:Float)
	if (FlxG.keys.justPressed.F5) FlxG.resetState();