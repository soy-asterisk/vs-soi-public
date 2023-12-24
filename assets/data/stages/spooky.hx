import flixel.graphics.frames.FlxFramesCollection;
public var lightningStrike:Bool = true;
public var lightningStrikeBeat:Int = 0;
public var lightningOffset:Int = 8;
public var thunderSFXamount:Int = 2;
var bg;
var frames;
function create() {
	for(i in 1...thunderSFXamount+1)
		FlxG.sound.load(Paths.sound('thunder_' + Std.string(i)));

	makeBG();

	bg.playAnim('idle');
}
public function lightningStrikeShit():Void
{
	FlxG.sound.play(Paths.soundRandom('thunder_', 1, thunderSFXamount));
	if(!Options.lowMemoryMode){
		bg.playAnim('lightning');
	}else{
		FlxTween.num(1,0,30/24,null,function(num){
			bg.colorTransform.redOffset = num*127;
			bg.colorTransform.greenOffset = num*127;
			bg.colorTransform.blueOffset = num*127;
		});
	}

	lightningStrikeBeat = curBeat;
	lightningOffset = FlxG.random.int(8, 24);

	boyfriend.playAnim('scared', true, "MISS"); // MISS so that they dont get indefinitely looped
	gf.playAnim('scared', true, "MISS");
}

function beatHit(curBeat) {
	if (lightningStrike && FlxG.random.bool(10) && curBeat > lightningStrikeBeat + lightningOffset)
	{
		lightningStrikeShit();
	}
}

function makeBG(){
	bg = new FunkinSprite();
	if(!Options.lowMemoryMode){
		frames = new FlxFramesCollection();
		for(i in 0...30){
			var p = Paths.image("stages/spooky/lightning"+CoolUtil.addZeros(i+1,4));
			var f = FlxG.bitmap.add(p).imageFrame;
			f.parent.useCount++;
			for(frame in f.frames){
				frames.frames.push(frame);
			}
			f.parent.bitmap.getTexture(FlxG.stage.context3D);
		}
		bg.frames = frames;
		bg.animation.add("idle",[29],24,true);
		bg.animation.add("lightning",CoolUtil.numberArray(30),24,false);
		bg.animation.play("idle",true);
	}else{
		bg.frames = Paths.getFrames("stages/spooky/lightning0030");
	}
	bg.setPosition(-200,-100);
	bg.scale.set(1.05,1.05);
	bg.updateHitbox();
	bg.antialiasing = true;
	insert(0,bg);
}

function destroy(){
	if(frames!=null){
		for(f in frames.frames){
			f.parent.useCount--;
		}
	}
}