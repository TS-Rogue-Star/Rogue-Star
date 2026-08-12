//RS FILE
var/global/list/got_sounds = list()

/proc/get_sound(path_string)
	var/oursound = got_sounds[path_string]
	if(oursound)
		return oursound
	if(fexists(path_string))
		got_sounds[path_string] = file(path_string)
		return got_sounds[path_string]
	else
		return 'sound/rogue-star/placeholder_yap.mp3'

/*
/proc/get_icon(path_string)
	if (fexists(path_string))
		return file(path_string)
	else
		return file("icons/rogue-star/placeholder.dmi")
*/
