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

#if sys
import sys.FileSystem;
#end
import haxe.io.Path;

/**
 * A storage class for mobile.
 * @base author Karim Akra and Homura Akemi (HomuHomu833)
 */
class StorageUtil
{
	#if sys
	public inline static function getStorageDirectory():String
		return #if FOR_MOD_DEBUGER Path.addTrailingSlash(getOriginStorageDirectory() + "I_AM_EVERYTHING") #else getOriginStorageDirectory() #end;
	
	private static function getOriginStorageDirectory():String
		return #if FOR_MOD_DEBUGER #if android haxe.io.Path.addTrailingSlash(AndroidContext.getExternalFilesDir()) #elseif ios lime.system.System.documentsDirectory #else Sys.getCwd() #end #else #if (android || ios) lime.system.System.applicationStorageDirectory #else Sys.getCwd() #end #end;
	
	public static function checkStorageDirectory() {
		try {
			final storageD:String = getStorageDirectory();
			if(!FileSystem.exists(storageD)) {
				FileSystem.createDirectory(storageD);
			}
		} catch(e:Dynamic) {
			//...不太清楚要不要冲
		}
	}

	#if android
	// always force path due to haxe
	//懒得改了......
	public inline static function getExternalStorageDirectory():String
		return #if FOR_MOD_DEBUGER '/sdcard/.WB\'s Crisis/' #else getStorageDirectory() #end;

	public static function requestPermissions():Void
	{
		if (AndroidVersion.SDK_INT >= AndroidVersionCode.TIRAMISU)
			AndroidPermissions.requestPermissions(['READ_MEDIA_IMAGES', 'READ_MEDIA_VIDEO', 'READ_MEDIA_AUDIO', 'READ_MEDIA_VISUAL_USER_SELECTED']);
		else
			AndroidPermissions.requestPermissions(['READ_EXTERNAL_STORAGE', 'WRITE_EXTERNAL_STORAGE']);

		if (!AndroidEnvironment.isExternalStorageManager())
			AndroidSettings.requestSetting('MANAGE_APP_ALL_FILES_ACCESS_PERMISSION');

		Sys.println(AndroidPermissions.getGrantedPermissions());

		try
		{
			if (!FileSystem.exists(StorageUtil.getStorageDirectory()))
				FileSystem.createDirectory(StorageUtil.getStorageDirectory());
		}
		catch (e:Dynamic)
		{
			NativeAPI.showMessageBox('Error!', 'Please create directory to\n' + StorageUtil.getStorageDirectory() + '\nPress OK to close the game');
			lime.system.System.exit(1);
		}
	}
	#end
	#end
}