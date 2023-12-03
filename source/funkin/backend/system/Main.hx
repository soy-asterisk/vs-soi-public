package funkin.backend.system;

import funkin.editors.SaveWarning;
import funkin.backend.assets.AssetsLibraryList;
import funkin.backend.system.framerate.SystemInfo;
import openfl.utils.AssetLibrary;
import openfl.utils.AssetCache;
import openfl.text.TextFormat;
import flixel.system.ui.FlxSoundTray;
import funkin.backend.utils.NativeAPI;
import funkin.menus.BetaWarningState;
import funkin.menus.TitleState;
import flixel.FlxGame;
import flixel.FlxState;
import openfl.Assets;
import openfl.Lib;
import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.events.Event;
import flixel.graphics.FlxGraphic;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.TransitionData;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import lime.app.Application;
import funkin.backend.system.modules.*;

#if ALLOW_MULTITHREADING
import sys.thread.Thread;
#end
#if sys
import sys.io.File;
#end
import funkin.backend.assets.ModsFolder;

class Main extends Sprite
{
	public static var instance:Main;

	public static var modToLoad:String = null;
	public static var forceGPUOnlyBitmapsOff:Bool = false;
	public static var noTerminalColor:Bool = false;

	public static var scaleMode:FunkinRatioScaleMode;
	#if !mobile
	public static var framerateSprite:funkin.backend.system.framerate.Framerate;
	#end

	var gameWidth:Int = 1280; // Width of the game in pixels (might be less / more in actual pixels).
	var gameHeight:Int = 720; // Height of the game in pixels (might be less / more in actual pixels).
	var skipSplash:Bool = true; // Whether to skip the flixel splash screen that appears in release mode.
	var startFullscreen:Bool = false; // Whether to start the game in fullscreen on desktop targets

	public static var vsSoiVersion = "1.0.0";
	
	public static var game:FunkinGame;

	public static var time:Int = 0;

	// You can pretty much ignore everything from here on - your code should go in your states.

	#if ALLOW_MULTITHREADING
	public static var gameThreads:Array<Thread> = [];
	#end

	public function new()
	{
		super();

		instance = this;

		CrashHandler.init();

		addChild(game = new FunkinGame(gameWidth, gameHeight, MainState, Options.framerate, Options.framerate, skipSplash, startFullscreen));

		#if (!mobile && !web)
		addChild(framerateSprite = new funkin.backend.system.framerate.Framerate());
		framerateSprite.scaleX = framerateSprite.scaleY = stage.window.scale;
		SystemInfo.init();
		#end
	}

	@:dox(hide)
	public static var audioDisconnected:Bool = false;

	public static var changeID:Int = 0;
	public static var pathBack = #if windows
			"../../../../"
		#elseif mac
			"../../../../../../../"
		#else
			""
		#end;
	public static var startedFromSource:Bool = #if TEST_BUILD true #else false #end;


	private static var __threadCycle:Int = 0;
	public static function execAsync(func:Void->Void) {
		#if ALLOW_MULTITHREADING
		var thread = gameThreads[(__threadCycle++) % gameThreads.length];
		thread.events.run(func);
		#else
		func();
		#end
	}

	private static function getTimer():Int {
		return time = Lib.getTimer();
	}

	public static function loadGameSettings() {
		WindowUtils.init();
		SaveWarning.init();
		MemoryUtil.init();
		@:privateAccess
		FlxG.game.getTimer = getTimer;
		#if ALLOW_MULTITHREADING
		for(i in 0...4)
			gameThreads.push(Thread.createWithEventLoop(function() {Thread.current().events.promise();}));
		#end
		FunkinCache.init();
		Paths.assetsTree = new AssetsLibraryList();

		#if UPDATE_CHECKING
		funkin.backend.system.updating.UpdateUtil.init();
		#end
		ShaderResizeFix.init();
		Logs.init();
		Paths.init();
		ModsFolder.init();
		DiscordUtil.init();
		#if GLOBAL_SCRIPT
		funkin.backend.scripting.GlobalScript.init();
		#end

		#if (sys && TEST_BUILD)
			trace("Used cne test / cne build. Switching into source assets.");
			#if MOD_SUPPORT
				ModsFolder.modsPath = './${pathBack}mods/';
			#end
			Paths.assetsTree.__defaultLibraries.push(ModsFolder.loadLibraryFromFolder('assets', './${pathBack}assets/', true));
		#elseif (USE_ADAPTED_ASSETS && MOD_SUPPORT)
			Paths.assetsTree.__defaultLibraries.push(ModsFolder.loadLibraryFromFolder('assets', './assets/', true));
		#end


		var lib = new AssetLibrary();
		@:privateAccess
		lib.__proxy = Paths.assetsTree;
		Assets.registerLibrary('default', lib);

		funkin.options.PlayerSettings.init();
		funkin.savedata.FunkinSave.init();
		Options.load();

		FlxG.fixedTimestep = false;

		FlxG.scaleMode = scaleMode = new FunkinRatioScaleMode();

		Conductor.init();
		AudioSwitchFix.init();
		EventManager.init();
		FlxG.signals.preStateSwitch.add(onStateSwitch);
		FlxG.signals.postStateSwitch.add(onStateSwitchPost);

		FlxG.mouse.useSystemCursor = true;

		#if MOD_SUPPORT
		ModsFolder.switchMod(modToLoad.getDefault(Options.lastLoadedMod));
		#end

		initTransition();
	}

	public static function refreshAssets() {
		FlxSoundTray.volumeChangeSFX = Paths.sound('menu/volume');
		FlxSoundTray.volumeUpChangeSFX = null;
		FlxSoundTray.volumeDownChangeSFX = null;

		if (FlxG.game.soundTray != null)
			FlxG.game.soundTray.text.setTextFormat(new TextFormat(Paths.font("vcr.ttf")));
	}

	public static function initTransition() {
		var diamond:FlxGraphic = FlxGraphic.fromClass(GraphicTransTileDiamond);
		diamond.persist = true;
		diamond.destroyOnNoUse = false;

		FlxTransitionableState.defaultTransIn = new TransitionData(FADE, 0xFF000000, 1, new FlxPoint(0, -1), {asset: diamond, width: 32, height: 32},
			new FlxRect(-200, -200, FlxG.width * 1.4, FlxG.height * 1.4));
		FlxTransitionableState.defaultTransOut = new TransitionData(FADE, 0xFF000000, 0.7, new FlxPoint(0, 1),
			{asset: diamond, width: 32, height: 32}, new FlxRect(-200, -200, FlxG.width * 1.4, FlxG.height * 1.4));
	}

	private static function onStateSwitch() {
		scaleMode.resetSize();
	}

	private static function onStateSwitchPost() {
		// manual asset clearing since base openfl one doesnt clear lime one
		// doesnt clear bitmaps since flixel fork does it auto

		@:privateAccess {
			// clear uint8 pools
			for(length=>pool in openfl.display3D.utils.UInt8Buff._pools) {
				for(b in pool.clear())
					b.destroy();
			}
			openfl.display3D.utils.UInt8Buff._pools.clear();
		}

		MemoryUtil.clearMajor();
	}
}
