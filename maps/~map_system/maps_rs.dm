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
		if(map_swap_save(global.possible_station_maps[selection]))
			log_and_message_admins("has selected [selection] to be loaded next round! If this happened on map swap day, the auto map swap system will not pick a different map today!")
		else
			to_chat(src, SPAN_WARNING("Map swap failed for some reason."))

/proc/map_swap_save(to_save)
	/////////////////////////////////////////////////////////////
	//>>>>>>>>>REMEMBER TO SANITIZE YOUR INPUT IDIOT<<<<<<<<<<<//
	/////////////////////////////////////////////////////////////
//	if(!istype(to_save, /datum/map))
//		to_world("[to_save] is not the right type")
//		return FALSE
	if(fexists("data/map_selection.sav"))
		fdel("data/map_selection.sav")

	var/savefile/F = new /savefile("data/map_selection.sav")

	F["selected_map"] << to_save
	F["last_swap_date"] << time2text(world.timeofday, "DD")	//Remember when we last swapped that way auto-swap won't override someone manually swapping it.

	if(fexists("data/map_selection.sav")) return TRUE
	else
		to_world("We attempted to save, but the save file doesn't exist!")
		return FALSE

/hook/startup/proc/initialise_map_list()
	if(!fexists("data/map_selection.sav"))
		using_map = new DEFAULT_MAP	//We don't have a save file yet, so let's just mape the default map object
		map_swap_save(DEFAULT_MAP)	//Save it so that we can start the auto-swap cycle
	else
		log_debug(SPAN_DANGER("MAP_SELECTION.SAV EXISTS, ATTEMPTING TO LOAD FROM FILE"))
		var/savefile/F = new /savefile("data/map_selection.sav")
		var/ourmap
		var/last_swap_date
		F["selected_map"] >> ourmap
		F["last_swap_date"] >> last_swap_date

//		if(istype(ourmap,/datum/map))	//Sanitize whatever path we got from the save file

		if(ourmap)
			log_debug(SPAN_DANGER("LOADED [ourmap] FROM FILE TO USE FOR MAP LOADING!"))
			var/auto_swap = auto_map_swap(ourmap, last_swap_date)
			if(auto_swap)
				map_swap_save(auto_swap)	//Save it so that it will remember next round
				using_map = new auto_swap	//Let's create the map object we got from auto_swap!
			else
				using_map = new ourmap		//Let's create the map object we got from the save file!
		else
			log_debug(SPAN_DANGER("NO VALID MAP SELECTED, LOADING FROM DEFAULT"))

	if(!using_map)
		using_map = new DEFAULT_MAP		//Something has gone wrong, let's try to make an emergency map object!

	if(using_map)
		log_debug("[using_map.name] was created successfully.")
	else
		error("initialise_map_list() failed to create a map object. No maps will load.")

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

/proc/auto_map_swap(var/map_input,var/last_auto)
	if(!(time2text(world.timeofday, "DDD") == "Sun" && text2num(time2text(world.timeofday, "hh")) >= 12))	//Let's swap the map on sunday after noon!
		return FALSE
	if(time2text(world.timeofday, "DD") == last_auto)	//Let's only swap it automatically one time though!
		return FALSE
	switch(map_input)
		if(/datum/map/stellar_delight)
			log_debug("Auto map swap has triggered! [SPAN_WARNING("Loading Rascal's Pass!")]")
			return /datum/map/groundbase
		if(/datum/map/groundbase)
			log_debug("Auto map swap has triggered! [SPAN_WARNING("Loading Stellar Delight!")]")
			return /datum/map/stellar_delight
		else
			log_debug("Auto map swap has triggered! Invalid input, defaulting to Stellar Delight!")
			return /datum/map/stellar_delight
