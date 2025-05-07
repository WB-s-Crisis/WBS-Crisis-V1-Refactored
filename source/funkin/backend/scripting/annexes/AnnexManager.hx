package funkin.backend.scripting.annexes;

import funkin.backend.assets.ModsFolder;
import haxe.io.Path;
import sys.FileSystem;

@:allow(funkin.backend.scripting.annexes.Annex)
final class AnnexManager {
	public static var annexes(default, null):Array<Annex>;
	private static var directorPath(default, null):String;

	private static inline var yourDadPath:String = "source/";

	private static var retrievalExtensions:Array<String> = ["hx", "hxs", "hsc", "hscript"];

	public static function init() {
		annexes = new Array<Annex>();
		ModsFolder.onModSwitch.add(onModSwitch);

		Annex.parser.allowMetadata = Annex.parser.allowTypes = Annex.parser.allowJSON = true;
	}

	private static function onModSwitch(mod:String) {
		annexes.clear();
		directorPath = (mod == null ? 'assets/${yourDadPath}' : '${ModsFolder.modsPath}${mod}/${yourDadPath}');

		retrieval();
	}

	private static function retrieval() {
		if(annexes == null || directorPath == null) return;
		if(!FileSystem.exists(directorPath)) return;

		//获取根目录的
		var rootFeat = FileSystem.readDirectory(directorPath).filter((file) -> !FileSystem.isDirectory(directorPath + file) && retrievalExtensions.contains(Path.extension(file)));
		if(rootFeat.length > 0) registerAnnex(null, rootFeat);

		final localPackage:Array<String> = getAllSubdirectories(directorPath);
		for(locate in localPackage) {
			final pack = locate.replace("/", ".");
			final meedFeat = FileSystem.readDirectory(directorPath + locate).filter((file) -> !FileSystem.isDirectory(Path.addTrailingSlash(directorPath + locate) + file) && retrievalExtensions.contains(Path.extension(file)));
			if(meedFeat.length > 0)
				registerAnnex(pack, meedFeat);
		}
	}

	private static function registerAnnex(pack:Null<String>, filesName:Array<String>, ?cwdPath:String):Null<Annex> {
		if(annexes == null || directorPath == null) return null;

		var annex:Annex = new Annex(pack, filesName, cwdPath);
		annex.execute();
		annexes.push(annex);

		return annex;
	}

	private static function getAllSubdirectories(path:String):Array<String> {
		var subdirs = [];

		path = Path.addTrailingSlash(path);
		function scanDir(currentPath:String) {
			for (sb in FileSystem.readDirectory(currentPath)) {
				var fullPath = Path.addTrailingSlash(currentPath) + sb;
				if (FileSystem.isDirectory(fullPath)) {
					subdirs.push(fullPath.substr(path.length));
					scanDir(fullPath);
				}
			}
		}

		scanDir(path);
		return subdirs;
	}
}