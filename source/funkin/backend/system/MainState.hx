package funkin.backend.system;

#if MOD_SUPPORT
import sys.FileSystem;
#end
import funkin.backend.assets.ModsFolder;
import funkin.menus.TitleState;
import funkin.menus.BetaWarningState;
import funkin.backend.chart.EventsData;
import flixel.FlxState;
#if web
import funkin.menus.ClickToStartState;
#end

/**
 * Simple state used for loading the game
 */
class MainState extends FlxState {
	public static var initiated:Bool = false;
	public static var betaWarningShown:Bool = false;
	public override function create() {
		super.create();
		if (!initiated)
			Main.loadGameSettings();
		initiated = true;

		#if sys
		CoolUtil.deleteFolder('./.temp/'); // delete temp folder
		#end
		Options.save();

		FlxG.bitmap.reset();
		FlxG.sound.destroy(true);

		Paths.assetsTree.reset();

		#if MOD_SUPPORT
		if (ModsFolder.currentModFolder != null)
			Paths.assetsTree.addLibrary(ModsFolder.loadModLib('${ModsFolder.modsPath}${ModsFolder.currentModFolder}'));

		if (FileSystem.exists(ModsFolder.addonsPath) && FileSystem.isDirectory(ModsFolder.addonsPath))
			for(addon in [for(dir in FileSystem.readDirectory(ModsFolder.addonsPath)) if (FileSystem.isDirectory('${ModsFolder.addonsPath}$dir')) dir])
				Paths.assetsTree.addLibrary(ModsFolder.loadModLib('${ModsFolder.addonsPath}$addon'));
		#end

		Main.refreshAssets();
		ModsFolder.onModSwitch.dispatch(ModsFolder.currentModFolder);
		DiscordUtil.reloadJsonData();
		EventsData.reloadEvents();
		TitleState.initialized = false;

		if (betaWarningShown)
			FlxG.switchState(new TitleState());
		else {
			#if web
			FlxG.switchState(new ClickToStartState());
			#else
			FlxG.switchState(new TitleState());
			#end
			betaWarningShown = true;
		}

		#if sys
		sys.FileSystem.createDirectory('./.temp/');
		#if windows
		funkin.backend.utils.native.Windows.setTempAttribute();
		#end
		#end
	}
}