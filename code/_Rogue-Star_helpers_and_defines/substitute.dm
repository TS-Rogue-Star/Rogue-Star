//RS FILE
var/global/list/got_sounds = list()

/proc/get_sound(path_string)
	to_world("get_sound: [path_string]")
	var/oursound = got_sounds[path_string]
	to_world("cache result: [oursound]")
	if(oursound)
		to_world(SPAN_NOTICE("got [oursound] from cache, returning result"))
		return oursound
	to_world("No sound cached")
	if (fexists(path_string))
		to_world("File exists: [path_string]")
		got_sounds[path_string] = file(path_string)
		to_world(SPAN_OCCULT("Added [got_sounds[path_string]] to cache and will return it as a result"))
		return got_sounds[path_string]
	else
		to_world(SPAN_DANGER("File does not exist, returning placeholder"))
		return file("sound/rogue-star/placeholder_yap.mp3")

/*
/proc/get_icon(path_string)
	if (fexists(path_string))
		return file(path_string)
	else
		return file("icons/rogue-star/placeholder.dmi")
*/
