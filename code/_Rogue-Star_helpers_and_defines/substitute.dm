//RS FILE
var/global/list/got_sounds = list()

/proc/get_sound(path_string)
	var/oursound = got_sounds[path_string]
	if(oursound)	//The sound is registered so we can just use it!
		return oursound
	if(fexists(path_string))	//No such sound registered, let's see if it exists!
		got_sounds[path_string] = file(path_string)	//It does, let's record it so we can just use it next time.
	else
		got_sounds[path_string] = file("sound/rogue-star/placeholder_yap.mp3")	//It doesn't exist, let's register the placeholder sound so it can act as a substitute for next time!

	return got_sounds[path_string]	//And either way return the sound we just registered~

/*
/proc/get_icon(path_string)
	if (fexists(path_string))
		return file(path_string)
	else
		return file("icons/rogue-star/placeholder.dmi")
*/
