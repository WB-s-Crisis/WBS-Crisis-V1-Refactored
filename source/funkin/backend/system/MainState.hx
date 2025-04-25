package funkin.backend.system;

#if MOD_SUPPORT
import sys.FileSystem;
#end
import funkin.backend.assets.ModsFolder;
import funkin.menus.TitleState;
import funkin.menus.BetaWarningState;
import funkin.backend.chart.EventsData;
import flixel.FlxState;
#if mobile
import mobile.funkin.backend.system.CopyState;
import sys.Http;
#end

/**
 * Simple state used for loading the game
 */
class MainState extends FlxState {
	public static var initiated:Bool = false;
	public static var initiatedGIT(default, null):Bool = false;
	public static var betaWarningShown:Bool = false;
	public override function create() {
		super.create();
		#if mobile
		funkin.backend.system.Main.instance.framerateSprite.setScale();
		#end
		if (!initiated)
		{
			Main.loadGameSettings();
			#if mobile
			switchUrlGit();
			if(!initiatedGIT || !FileSystem.exists(".version")) if(!CopyState.oneshot) if (!CopyState.checkExistingFiles())
			{
				FlxG.switchState(new CopyState());
				return;
			}
			initiatedGIT = false;
			#if FOR_MOD_DEBUGER
			if(!Reflect.hasField(FlxG.save.data, "debugFW")) Reflect.setField(FlxG.save.data, "debugFW", false);
			if(!FlxG.save.data.debugFW) {
				funkin.backend.utils.NativeAPI.showMessageBox("注意事项!!", "\t你们这群BYD编程听好了，你们现在所使用的版本是处于\"DEBUG\"状态，不然你们也不可能会看到这条弹窗...\n\t总之，这条弹窗只会跳出来一次提醒，所以一定要看完！\n\t⒈此\"DEBUG\"状态可允许你们通过你们手机的外部储存目录下的一个目录（.WB's Crisis）来装载模组或修改其他东西之类的。\n\t⒉此CNE版本非同于原本的CNE，我做出了一定的修改，这个得谨慎理清。\n\t⒊若在使用过程中有什么问题出现，或者需要我实现什么东西的话，我尽量完成或者解决。\n\t⒋由于对CopyState做出了一定的修改，所以在手机开局加载会有一点慢（你们也见识到了），主要是为了更好侦测所需依赖游戏文件的完整性（即检查字节、检查多出来的目录或者文件等），如果以后有机会，我可能会进行优化。\n\t⒌老样子，这里为了方便兼容我们原本mod包，该有的都有，而且最重要的就是这个版本是由牢大版（打赢复活赛）CNE改的，有一部分脚本函数需要遵循牢大版（例如addVirtualPad改成了addTouchPad等等）。\n\t⒍还是老样子，支持修改按键，也因此原本的\"addHitbox\"函数改成了\"addGamepad\"，记得鉴别！");
				
				FlxG.save.data.debugFW = true;
				FlxG.save.flush();
			}
			#end
			#end
			#if TOUCH_CONTROLS
			mobile.funkin.backend.utils.MobileData.init();
			#end
		}
		initiated = true;

		#if sys
		CoolUtil.deleteFolder('.temp/'); // delete temp folder
		#end
		Options.save();

		FlxG.bitmap.reset();
		FlxG.sound.destroy(true);

		Paths.assetsTree.reset();

		#if MOD_SUPPORT
		var _lowPriorityAddons:Array<String> = [];
		var _highPriorityAddons:Array<String> = [];
		var _noPriorityAddons:Array<String> = [];
		if (FileSystem.exists(ModsFolder.addonsPath) && FileSystem.isDirectory(ModsFolder.addonsPath)) {
			for(i=>addon in [for(dir in FileSystem.readDirectory(ModsFolder.addonsPath)) if (FileSystem.isDirectory('${ModsFolder.addonsPath}$dir')) dir]) {
				if (addon.startsWith("[LOW]")) _lowPriorityAddons.insert(0, addon);
				else if (addon.startsWith("[HIGH]")) _highPriorityAddons.insert(0, addon);
				else _noPriorityAddons.insert(0, addon);
			}
			for (addon in _lowPriorityAddons)
				Paths.assetsTree.addLibrary(ModsFolder.loadModLib('${ModsFolder.addonsPath}$addon', StringTools.ltrim(addon.substr("[LOW]".length))));
		}
		if (ModsFolder.currentModFolder != null)
			Paths.assetsTree.addLibrary(ModsFolder.loadModLib('${ModsFolder.modsPath}${ModsFolder.currentModFolder}', ModsFolder.currentModFolder));

		if (FileSystem.exists(ModsFolder.addonsPath) && FileSystem.isDirectory(ModsFolder.addonsPath)){
			for (addon in _noPriorityAddons) Paths.assetsTree.addLibrary(ModsFolder.loadModLib('${ModsFolder.addonsPath}$addon', addon));
			for (addon in _highPriorityAddons) Paths.assetsTree.addLibrary(ModsFolder.loadModLib('${ModsFolder.addonsPath}$addon', StringTools.ltrim(addon.substr("[HIGH]".length))));
		}
		#end

		MusicBeatTransition.script = "";
		Main.refreshAssets();
		ModsFolder.onModSwitch.dispatch(ModsFolder.currentModFolder);
		DiscordUtil.init();
		EventsData.reloadEvents();
		TitleState.initialized = false;

		if (betaWarningShown)
			FlxG.switchState(new TitleState());
		else {
			FlxG.switchState(new BetaWarningState());
			betaWarningShown = true;
		}

		CoolUtil.safeAddAttributes('./.temp/', NativeAPI.FileAttribute.HIDDEN);
	}
	
	private function switchUrlGit():Bool {
		#if mobile
		var gitContent:String = "";
		initiatedGIT = false;
		//国内git源
		var giteeHttp:Http = new Http("https://gitee.com/vapiremox/wb-s-crisis_data/raw/master/.version");
		giteeHttp.onError = (error) -> {
			initiatedGIT = false:
			#if FOR_MOD_DEBUGER
			lime.app.Application.current.window.alert(error, "Gitee Error!!");
			#end
		};
		giteeHttp.onData = (data:String) -> {
			gitContent = data.trim();
			#if FOR_MOD_DEBUGER
			lime.app.Application.current.window.alert(data, "version");
			#end
		};
		initiatedGIT = true;
		giteeHttp.request();

		if(initiatedGIT && (gitContent != null && gitContent != "")) return initiatedGIT = gitContent == lime.app.Application.current.meta.["version"];

		//国外git源
		githubHttp:Http = new Http("https://raw.githubusercontent.com/VapireMox/WB-S-Crisis_DATA/refs/heads/main/.version");
		githubHttp.onError = (error) -> {
			initiatedGIT = false:
			#if FOR_MOD_DEBUGER
			lime.app.Application.current.window.alert(error, "Github Error!!");
			#end
		};
		githubHttp.onData = (data:String) -> {
			gitContent = data.trim();
			#if FOR_MOD_DEBUGER
			lime.app.Application.current.window.alert(data, "version");
			#end
		};
		initiatedGIT = true;
		githubHttp.request();
		
		if(initiatedGIT && (gitContent != null && gitContent != "")) return initiatedGIT = gitContent == lime.app.Application.current.meta.["version"];
		return false;
		#end
	}
}