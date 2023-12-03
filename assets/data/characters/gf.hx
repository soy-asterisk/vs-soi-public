function onPlayAnim(e){
	if(e.animName=="singLEFT")
		danced = false;
	else if(e.animName=="singRIGHT")
		danced = true;
	if(e.animName=="singUP" || e.animName=="singDOWN")
		danced = !danced;
}