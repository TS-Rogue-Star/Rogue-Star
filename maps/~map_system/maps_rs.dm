var/global/list/possible_station_maps = list(
	"Stellar Delight" = /datum/map/stellar_delight,
	"Rascal's Pass" = /datum/map/groundbase
)

/client/proc/map_swap()
	set name = "Map Swap"
	set category = "Fun"

	if(!check_rights(R_FUN)) return

	var/selection = tgui_input_list(src,"Pick a map! This selection will be what is loaded next round!","Map Swap",global.possible_station_maps)

	if(selection)
		to_world("The selection is [selection], we will pass [global.possible_station_maps[selection]] to be saved.")
		if(map_swap_save(global.possible_station_maps[selection]))
			log_and_message_admins("has selected [selection] to be loaded next round!")
		else
			to_chat(src, SPAN_WARNING("Map swap failed for some reason."))

/proc/map_swap_save(to_save)
//	if(!istype(to_save, /datum/map))
//		to_world("[to_save] is not the right type")
//		return FALSE

	if(fexists("data/map_selection.sav"))
		fdel("data/map_selection.sav")

	var/savefile/F = new /savefile("data/map_selection.sav")

	F["selected_map"] << to_save

	if(fexists("data/map_selection.sav")) return TRUE
	else
		to_world("We attempted to save, but the save file doesn't exist!")
		return FALSE

/hook/startup/proc/initialise_map_list()
	if(!fexists("data/map_selection.sav"))
		using_map = new /datum/map/stellar_delight
//	var/list/Lines = file2list("data/map_selection.sav")
	else
		log_and_message_admins(SPAN_DANGER("MAP_SELECTION.SAV EXISTS, ATTEMPTING TO LOAD FROM FILE"))
		var/savefile/F = new /savefile("data/map_selection.sav")
		var/ourmap
		F["selected_map"] >> ourmap
//		if(istype(ourmap,/datum/map))
		if(ourmap)
			log_and_message_admins(SPAN_DANGER("LOADED [ourmap] FROM FILE TO USE FOR MAP LOADING!"))
			using_map = new ourmap
		else
			log_and_message_admins(SPAN_DANGER("NO VALID MAP SELECTED, LOADING FROM DEFAULT"))
/*
	for(var/line in Lines)
		var/our_station = text2path(line)
		if(our_station)
			using_map = new our_station
			break
*/
	if(!using_map)
		using_map = new /datum/map/stellar_delight

	if(using_map)
		log_and_message_admins("[using_map.name] is our map")
	else
		log_and_message_admins("We somehow didn't get a map I donno what to tell you")

	for(var/type in subtypesof(/datum/map))
		var/datum/map/M
		if(type == using_map.type)
			M = using_map
			M.setup_map()
		else
			M = new type
		if(!M.path)
			log_debug("Map '[M]' does not have a defined path, not adding to map list!")
		else
			all_maps[M.path] = M
	return 1
