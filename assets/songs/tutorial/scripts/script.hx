var oldTarget = -1;
function postUpdate(){
	if(oldTarget!=curCameraTarget){
		if(curCameraTarget==0){
			tweenCamIn();
		}else{
			FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut});
		}
		oldTarget = curCameraTarget;
	}
}

function beatHit(curBeat){
	if (curBeat % 16 == 15 && curBeat > 16 && curBeat < 48)
	{
		boyfriend.playAnim('hey', true, "MISS");
		dad.playAnim('cheer', true, "MISS");
	}
}

function onNoteHit(e){
	e.enableCamZooming = false;
}

function tweenCamIn()
{
	FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut});
}