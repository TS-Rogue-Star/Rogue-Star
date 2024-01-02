/obj/effect/overmap/visitable/ship/snowglobe
	name = "snowglobe"
	desc = "A pretty snowblobe with a tiny snowy environment inside!"
	scanner_desc = "A pretty snowblobe with a tiny snowy environment inside!"
	dir = NORTH
	icon = 'icons/obj/snowglobe_vr.dmi'
	icon_state = "smolsnowvillage"

	unknown_name = "snowglobe"
	unknown_state = "ship"
	known = TRUE

	vessel_mass = 1
	vessel_size = SHIP_SIZE_TINY
	max_speed = 0
	min_speed = 0

	plane = OBJ_PLANE

/obj/effect/overmap/visitable/ship/snowglobe/Initialize()
	. = ..()

	var/list/startspots = list()
	var/turf/simulated/startspot

	for(var/obj/structure/table/ourtable in world)	//Snowglobes should be on tables
		if(!istype(ourtable,/obj/structure/table))
			continue
		if(ourtable.z in using_map.station_levels)	//And on the station
			var/area/A = get_area(ourtable)
			if(A.flags & RAD_SHIELDED || A.flags & BLUE_SHIELDED)	//Not in the dorms or in maint
				continue

			startspots |= get_turf(ourtable)

	startspot = get_turf(pick(startspots))

	forceMove(startspot)
	log_and_message_admins("[src] placed itself at [x],[y],[z] - [src.loc]")

/obj/effect/overmap/visitable/ship/snowglobe/examine(mob/user, infix, suffix)
	. = ..()
	if(!isliving(user))
		return
	var/list/ourlist = list()
	for(var/mob/player in player_list)
		if(player.z in map_z)
			if(isliving(player))
				ourlist |= player
	if(ourlist.len)
		. += "You can see something moving inside. It looks like: "
		for(var/mob/living/l in ourlist)
			. += "[l], "
		. += "and they would probably be able to see you too!"
