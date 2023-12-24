package funkin.menus;

class ClickToStartState extends MusicBeatState{
	public override function create(){
		super.create();
		var c2sAlphabet = new Alphabet(0, 0, "CLICK TO START", true);
		c2sAlphabet.screenCenter(X);
		add(c2sAlphabet);

		
		var off = Std.int((FlxG.height - (c2sAlphabet.height)) / 2);
		c2sAlphabet.y += off;
	}

	public override function update(elapsed:Float){
		super.update(elapsed);
		for (touch in FlxG.touches.list){
			if (touch.justPressed){
				goToTitle();
				//TODO:タッチモード有効化など
				return;
			}
		}
		if(FlxG.mouse.justPressed){
			goToTitle();
		}
	}

	private function goToTitle() {
		MusicBeatState.skipTransIn = MusicBeatState.skipTransOut = true;
		FlxG.switchState(new TitleState());
	}
}