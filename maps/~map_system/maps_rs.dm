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
