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

	startspot()

/obj/effect/overmap/visitable/ship/snowglobe/proc/startspot()

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

/obj/effect/overmap/visitable/ship/snowglobe/Destroy()
	log_and_message_admins("Somthing tried to destroy the [src]. It will instead sent to a new starting location.")

	startspot()

/obj/effect/overmap/visitable/ship/examine(mob/user, infix, suffix)
	. = ..()
	if(!isliving(user))
		return
	var/list/potential_targets = get_people_in_ship()
	var/list/ourlist = list()
	var/list/grablist = list()
	for(var/mob/player in potential_targets)
		if(!isliving(player))
			continue
		if(!player.client)
			continue
		var/area/ourarea = get_area(player)
		if(!ourarea.emotes_from_beyond)
			continue
		if(!player.client.is_preference_enabled(/datum/client_preference/emotes_from_beyond))
			continue
		if(ourarea.grab_zone)
			grablist |= player
		else
			ourlist |= player
	if(ourlist.len)
		. += "You can see something moving inside. It looks like: "
		for(var/mob/living/l in ourlist)
			. += "[l]"
		. += "and they would probably be able to see you too!"
	if(grablist.len)
		. += "You can also see these lingering in an area where you could grab them:"
		for(var/mob/living/l in grablist)
			. += "[l]"

/area/redgate/structure/powered/grab_zone
	name = "platform"
	grab_zone = TRUE

/obj/effect/overmap/visitable/ship/attack_hand(mob/living/user)
	if(!(user.pickup_pref && user.pickup_active))
		return ..()
	var/list/possible_targets = list()
	var/list/potential_targets = get_people_in_ship()

	for(var/mob/living/player in potential_targets)
		if(player == user)
			continue
		if(!(isliving(player) && player.client))
			continue
		if(!(player.resizable && player.pickup_pref))
			continue
		var/area/ourarea = get_area(player)
		if(!ourarea.grab_zone)
			continue
		possible_targets |= player

	if(!possible_targets.len)
		return ..()
	user.visible_message("<span class='warning'>\The [user] reaches for \the [src]...</span>","<span class='notice'>You look closer at \the [src]...</span>")
	var/mob/living/that_one = tgui_input_list(user, "Select someone to grab:", "GRAB!", possible_targets)
	if(!that_one)
		return ..()
	to_chat(that_one, "<span class='danger'>\The [user]'s hand reaches toward you!!!</span>")
	if(!do_after(user, 3 SECONDS, src))
		return ..()
	if(!istype(get_area(that_one.loc),/area/redgate/structure/powered/grab_zone))
		to_chat(user, "<span class='warning'>\The [that_one] got away...</span>")
		to_chat(that_one, "<span class='notice'>You got away!</span>")
		return
	var/prev_size = that_one.size_multiplier
	that_one.resize(RESIZE_TINY, ignore_prefs = TRUE)
	if(!that_one.attempt_to_scoop(user, ignore_size = TRUE))
		that_one.resize(prev_size, ignore_prefs = TRUE)
		return ..()

/area/redgate/structure/powered/no_efb
	emotes_from_beyond = FALSE
