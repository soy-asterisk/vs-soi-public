package funkin.menus.credits;

import funkin.options.type.PortraitOption;

class CreditsVsSoi extends funkin.options.OptionsScreen {
	public override function new()
	{
		super("vs Soi Mod", "vs Soi Mod authors");
		add(new PortraitOption(
			"soy asterisk","Coding, composition, animation, Soi author",
			function(){CoolUtil.openURL("https://twitter.com/soy_asterisk");},
			FlxG.bitmap.add(Paths.image('credits/soy asterisk'))
		));
	}
}