package funkin.backend.scripting.addons;

import funkin.backend.scripting.ScriptPack;
import funkin.backend.scripting.Script;
import funkin.backend.scripting.HScript;
import flixel.util.FlxDestroyUtil;
import funkin.backend.assets.ModsFolder;
import lime.app.Application;
import haxe.io.Path;
import funkin.backend.system.Logs;

/**
 * 这依托你爱看吗？
 */
class AddonsManager {
	private static var addonsScripts:ScriptPack;
	private static var _cacheScripts:Map<String, HScript>;
	
	public static function init() {
		addonsScripts = new ScriptPack("addons");
		_cacheScripts = new Map();
		#if MOD_SUPPORT
		ModsFolder.onModSwitch.add(onModSwitch);
		#end
	}
	
	public static function importScriptAddons(addonsPath:String, sb:HScript) {
		if(addonsScripts == null) return;
		
		var split:Array<String> = addonsPath.split(".");
	
		if(split.length <= 0) {
			_errorHandler("
### 傻逼 ###
* e......
* 敢问阁下一句？
* 请重新检查一下你是否开挂了......
			");
			return;
		}
	
		if(Paths.getFolderDirectories("").contains("addons")) {
			if(split.length < 2) {
				var sd:Array<String> = Paths.getFolderDirectories("addons");
				var sc:Array<String> = Paths.getFolderContent("addons");
				var scWithoutExtension = [];
			
				for(nb in sc) {
					var gengNb = Path.withoutExtension(nb);
					scWithoutExtension.push(gengNb);
				}
			
				if(scWithoutExtension.contains(split[0])) {
					var script = null;
					if(!_cacheScripts.exists(split[0])) {
							script = Script.create(Paths.script(rawPath));
							if(script is HScript) {
								var hscript = cast(script, HScript);
								hscript.load();
								
								if(hscript.lastThrow != null) return;

								_cacheScripts.set(split[0], hscript);
								addonsScripts.add(hscript);
							}else {
								_errorHandler("
### 在尝试编译脚本时发生错误 ###
* 我猜你该不会导入的是其他格式的东东吧？
* 真是一条杂鱼呢～
* ......
								");
								return;
							}
					}else {
						script = _cacheScripts.get(split[0]);
					}

					if(script is HScript) {
						if(cast(script, HScript).interp.customClasses.exists(split[0])) {
							sb.set(split[0], cast(script, HScript).interp.customClasses.get(split[0]));
						}else {
							_errorHandler("
### 在尝试导入\"" + split[0] + "\"时发生错误!!!! ###
* 你的\"importAddons\"参数只导入了了文件
* 你还需要导入指定的类
* ......
* 亦或是你可以尝试使用\"*\"符号来导入该脚本的所有类
							");
						}
					}
				
					return;
				}
			
				if(sd.contains(split[0])) {
					_errorHandler("
### 在尝试导入\"" + split[0] + "\"时发生错误!!!! ###
* 你不能只导入目录，你需要指定一份确切的脚本文件
					");
					
					return;
				}
				
				_errorHandler("
### 在尝试导入\"" + split[0] + "\"时发生错误!!!! ###
* \"addons\"根目录下不存在此文件亦或是目录 --[\"" + split[0] + "\"]
* 请选择已存在的文件或目录
* 如果输错了那就再去输一次
* ......
				");
			}else {
				var isLockingFile:Bool = false;
				var curPath = "addons";
				var _cachePath = "";
				for(i=>sp in split) {
					var sd:Array<String> = Paths.getFolderDirectories(curPath);
					var sc:Array<String> = Paths.getFolderContent(curPath);
					var scWithoutExtension = [];
			
					for(nb in sc) {
						var gengNb = Path.withoutExtension(nb);
						scWithoutExtension.push(gengNb);
					}
				
					if(isLockingFile) {
						var rawPath = curPath;
					
						var script = null;
						if(!_cacheScripts.exists(_cachePath)) {
							script = Script.create(Paths.script(rawPath));
							if(script is HScript) {
								var hscript = cast(script, HScript);
								hscript.load();
								
								if(hscript.lastThrow != null) return;

								_cacheScripts.set(_cachePath, hscript);
								addonsScripts.add(hscript);
							}else {
								_errorHandler("
### 在尝试编译脚本时发生错误 ###
* 我猜你该不会导入的是其他格式的东东吧？
* 真是一条杂鱼呢～
* ......
								");
								return;
							}
						}else {
							script = _cacheScripts.get(_cachePath);
						}
					
						if(split.length - 1 - i > 1) {
							_errorHandler("
### 在尝试......等等？？哥们，你在玩我吗？？？ ###
* 你能让这条错误出现，只能说明......
* 你是一个连字都不可能多识几个的傻瓜
* ......
* 顺带提醒你可不能导入已选定好的类里的东西
* 本人只负责导入，不干别的活儿
* ......
							");
						}else {
							if(script is HScript)
							if(cast(script, HScript).interp.customClasses.exists(sp)) {
								sb.set(sp, cast(script, HScript).interp.customClasses.get(sp));
							}else if(sp == "*") {
								for(k=>c in cast(script, HScript).interp.customClasses) {
									sb.set(k, c);
								}
							}else {
								_errorHandler("
### 在尝试导入\"" + _cachePath + "." + sp + "\"时发生错误!!!! ###
* 在该脚本[\"" + rawPath + "." + script.extension + "\"]中不存在此类[\"" + sp + "\"]
* 建议导入目前此脚本已存在的类
* ......
* 如果你还是这么一意孤行下去的话......
* ......
* 你的系统可不会给你好结果的......
* ......
								");
							}
						}
					
						break;
					}
				
					if(scWithoutExtension.contains(sp)) {
						isLockingFile = true;
						curPath += (StringTools.endsWith(curPath, "/") ? "" : "/") + sp;
						_cachePath += (i < 1 ? "" : ".") + sp;
					
						if(i == split.length - 1) {
							var rawPath = curPath;
							
							var script = null;
							if(!_cacheScripts.exists(_cachePath)) {
								script = Script.create(Paths.script(rawPath));
								if(script is HScript) {
									final hscript = cast(script, HScript);
									hscript.load();
									
									if(hscript.lastThrow != null) return;
								
									_cacheScripts.set(cachePath, hscript);
									addonsScripts.add(hscript);
								}else {
									_errorHandler("
### 在尝试编译脚本时发生错误 ###
* 我猜你该不会导入的是其他格式的东东吧？
* 真是一条杂鱼呢～
* ......
									");
									return;
								}
							}else {
								script = _cacheScripts.get(_cachePath);
							}

							if(script is HScript) {
								if(cast(script, HScript).interp.customClasses.exists(sp)) {
									sb.set(sp, cast(script, HScript).interp.customClasses.get(sp));
								}else {
									_errorHandler("
### 在尝试导入\"" + _cachePath + "\"时发生错误!!!! ###
* 你的\"importAddons\"参数只导入了脚本文件 --[\"" + rawPath + "." + script.extension + "\"]
* 或者说是没有与脚本文件名重名的类
* 你还需要导入指定的类
* ......
* 亦或是你可以尝试使用\"*\"符号来导入该脚本的所有类
									");
								}
							}
						
							break;
						}
					
						continue;
					}
				
					if(sd.contains(sp) && !isLockingFile) {
						curPath += (StringTools.endsWith(curPath, "/") ? "" : "/") + sp;
						_cachePath += (i < 1 ? "" : ".") + sp;
					
						if(i == split.length - 1) {
							_errorHandler("
### 在尝试导入\"" + _cachePath + "\"时发生错误
* 你的\"importAddons\"参数中只导入了目录 --[\"" + curPath + "\"]
* 建议你先选择好这个目录的文件
* ......
							");
						
							break;
						}
					
						continue;
					}
				
					_errorHandler("
### 在尝试导入\"" + sp + "\"时发生错误!!!! ###
* \"addons\"根目录下不存在此文件亦或是目录 --[\"" + sp + "\"]
* 请选择已存在的文件或目录......
* 如果输错了那就再去输一次
* ......
					");
				//break;
				}
			}
		}else {
			_errorHandler("
### 在尝试导入......导入个锤子!!!! ###
* 你" + #if desktop "那GP硬盘塞不下了" #elseif mobile "手机空间装不下了吗" #end + "吗?!!!
* 一个目录都开不了!
* 你就是个废物!!
* 啥也不是!!!
* 杂鱼一个!!!!
* 滚去你的傻逼模组开\"addons\"目录!!!!!
* 否则别来找我!!!!!!
			");
		}
	}
	
	private static function onModSwitch(idk:String) {
		if(addonsScripts.scripts.length > 0) {
			addonsScripts.scripts.clear();
		}
		
		if(_cacheScripts != null) {
			_cacheScripts.clear();
		}
	}
	
	private static function _errorHandler(content:String) {
		funkin.backend.utils.NativeAPI.showMessageBOX("Addons Script 错误！", content);
	}
}
