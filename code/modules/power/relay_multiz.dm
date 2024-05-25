///This bridges powernets betwen Z levels
/obj/machinery/power/deck_relay
	name = "Multi-deck power adapter"
	desc = "A huge bundle of double insulated cabling which seems to run up into the ceiling."
	icon = 'icons/obj/cables/structures.dmi'
	icon_state = "cablerelay-off"
	layer = WIRES_LAYER
	cable_layer = CABLE_LAYER_1|CABLE_LAYER_2|CABLE_LAYER_3|CABLE_LAYER_4
	var/obj/machinery/power/deck_relay/connectionup
	var/obj/machinery/power/deck_relay/connectiondown
	anchored = TRUE
	density = FALSE
	can_change_cable_layer = FALSE
	/// Powernet channels list
	var/datum/powernet/powernet1
	var/datum/powernet/powernet2
	var/datum/powernet/powernet3
	var/datum/powernet/powernet4
	var/list/powernets = list()

/obj/machinery/power/deck_relay/Initialize(mapload)
	. = ..()
	to_world_log("[name] has initialized")
	addtimer(CALLBACK(src, PROC_REF(find_and_connect)), 30)
	addtimer(CALLBACK(src, PROC_REF(refresh)), 50) //Wait a bit so we can find the one below, then get powering

//don't override our layering for this, since we omni-connect.
/obj/machinery/power/deck_relay/adapt_to_cable_layer()
	cable_layer = CABLE_LAYER_1|CABLE_LAYER_2|CABLE_LAYER_3|CABLE_LAYER_4
	return

/obj/machinery/power/deck_relay/Destroy()
	. = ..()
	if(connectionup) //Lose connections
		connectionup.connectiondown = null
	if(connectiondown)
		connectiondown.connectionup = null
	if(powernet1)
		powernet1 = null
	if(powernet2)
		powernet2 = null
	if(powernet3)
		powernet3 = null
	if(powernet4)
		powernet4 = null
	powernets.Cut()
	return TRUE

/obj/machinery/power/deck_relay/process()
	if(!anchored)
		icon_state = "cablerelay-off"
		if(connectionup) //Lose connections
			connectionup.connectiondown = null
		if(connectiondown)
			connectiondown.connectionup = null
		if(powernet1)
			powernet1 = null
		if(powernet2)
			powernet2 = null
		if(powernet3)
			powernet3 = null
		if(powernet4)
			powernet4 = null
		powernets.Cut()
		return
	refresh() //Sometimes the powernets get lost, so we need to keep checking.
	if(!powernets)
		icon_state = "cablerelay-off"

	if(!connectiondown || QDELETED(connectiondown) || !connectionup || QDELETED(connectionup))
		icon_state = "cablerelay-off"
		find_and_connect()

	for(var/datum/powernet/connections in powernets)
		var/missingnet = 0
		if(connections && (connections.avail > 0))
			continue
		else if(connections && (connections.avail <= 0))
			missingnet++
		else if(!connections)
			missingnet++
		else if(missingnet == 4)
			icon_state = "cablerelay-off"
		else
			icon_state = "cablerelay-on"

/obj/machinery/power/deck_relay/hides_under_flooring()
	return TRUE

///Handles re-acquiring + merging powernets found by find_and_connect()
/obj/machinery/power/deck_relay/proc/refresh()
	to_world_log("[name] has called refresh()")
	if(connectiondown)
		connectiondown.merge(src)
	if(connectionup)
		connectionup.merge(src)

/obj/machinery/power/deck_relay/proc/merge(var/obj/machinery/power/deck_relay/MZ)
	if(!MZ)
		return
	var/turf/merge_from = get_turf(MZ)
	var/turf/merge_to = get_turf(src)
	//Let's try to match up each other's powernets, without just mixing willy-nilly.
	if(powernet1 && MZ.powernet1)
		var/obj/structure/cable/C = merge_from.get_cable_node(CABLE_LAYER_1)
		var/obj/structure/cable/XR = merge_to.get_cable_node(CABLE_LAYER_1)
		if(C && XR)
			merge_powernets(XR.powernet,C.powernet)
	else if(powernet2 && MZ.powernet2)
		var/obj/structure/cable/C = merge_from.get_cable_node(CABLE_LAYER_2)
		var/obj/structure/cable/XR = merge_to.get_cable_node(CABLE_LAYER_2)
		if(C && XR)
			merge_powernets(XR.powernet,C.powernet)
	else if(powernet3 && MZ.powernet3)
		var/obj/structure/cable/C = merge_from.get_cable_node(CABLE_LAYER_3)
		var/obj/structure/cable/XR = merge_to.get_cable_node(CABLE_LAYER_3)
		if(C && XR)
			merge_powernets(XR.powernet,C.powernet)
	else if(powernet4 && MZ.powernet4)
		var/obj/structure/cable/C = merge_from.get_cable_node(CABLE_LAYER_4)
		var/obj/structure/cable/XR = merge_to.get_cable_node(CABLE_LAYER_4)
		if(C && XR)
			merge_powernets(XR.powernet,C.powernet)

///Locates relays that are above and below this object
/obj/machinery/power/deck_relay/proc/find_and_connect()
	to_world_log("[name] find_and_connect() called")
	var/turf/T = get_turf(src)
	if(!T || !istype(T))
		return FALSE
	connectiondown = null //in case we're re-establishing
	connectionup = null
	powernets.Cut()
	//Find our local cable nodes first
	var/obj/structure/cable/C
	for(C in T.contents)
		if(!C)
			return
		var/list/foundcables = list()
		foundcables |= C
		for(C in foundcables)
			C = T.get_cable_node() //check if we have a node cable on the machine turf.
			if(!C)
				continue
			var/list/foundnodes = list()
			foundnodes |= C
			to_world_log("[name] has found [C] in [foundnodes]")
			powernet = null	//because apparently I can't have nice things.
			if(C && C.powernet)
				to_world_log("[C] has a powernet, it's [C.powernet] on layer [C.cable_layer]")
				switch(C.cable_layer)
					if(CABLE_LAYER_1)
						if(powernet1)
							continue //we've already checked here, try the next one.
						powernet1 = C.powernet
						powernet = null
						C.powernet.add_relays_together(src, C.powernet, CABLE_LAYER_1)
						powernets |= powernet1
						return

					if(CABLE_LAYER_2)
						if(powernet2)
							return
						powernet2 = C.powernet
						powernet = null
						C.powernet.add_relays_together(src, C.powernet, CABLE_LAYER_2)
						powernets |= powernet2
						return

					if(CABLE_LAYER_3)
						if(powernet3)
							return
						powernet3 = C.powernet
						powernet = null
						C.powernet.add_relays_together(src, C.powernet, CABLE_LAYER_3)
						powernets |= powernet3
						return

					if(CABLE_LAYER_4)
						if(powernet4)
							return
						powernet4 = C.powernet
						powernet = null
						C.powernet.add_relays_together(src, C.powernet, CABLE_LAYER_4)
						powernets |= powernet4
						return
					else
						return
			else
				return

	for(var/direction in list(DOWN, UP))
		var/turf/TD = get_zstep(src, direction)
		if(!TD) continue
		var/obj/machinery/power/deck_relay/MZ = locate(/obj/machinery/power/deck_relay, TD)
		if(!MZ) continue
		if(direction == DOWN && (src.z in using_map.below_blocked_levels)) continue
		if(direction == UP && (MZ.z in using_map.below_blocked_levels)) continue
		if(direction == UP)
			connectionup = MZ
		if(direction == DOWN)
			connectiondown = MZ

	if(connectiondown || connectionup)
		icon_state = "cablerelay-on"
	return TRUE

/obj/machinery/power/deck_relay/examine(mob/user)
	. = ..()
	. += span_notice("[connectionup ? "Detected" : "Undetected"] hub UP.")
	. += span_notice("[connectiondown ? "Detected" : "Undetected"] hub DOWN.")
	if(powernet1)
		. += span_notice("The [LOWER_TEXT(GLOB.cable_layer_to_name["[CABLE_LAYER_1]"])] is connected.")
	if(powernet2)
		. += span_notice("The [LOWER_TEXT(GLOB.cable_layer_to_name["[CABLE_LAYER_2]"])] is connected.")
	if(powernet3)
		. += span_notice("The [LOWER_TEXT(GLOB.cable_layer_to_name["[CABLE_LAYER_3]"])] is connected.")
	if(powernet4)
		. += span_notice("The [LOWER_TEXT(GLOB.cable_layer_to_name["[CABLE_LAYER_4]"])] is connected.")

/obj/machinery/power/deck_relay/CtrlClick(mob/living/user)
	to_chat(user, span_warning("You push the reset button."))
	addtimer(CALLBACK(src, PROC_REF(find_and_connect)), 30, TIMER_UNIQUE)
	addtimer(CALLBACK(src, PROC_REF(refresh)), 50, TIMER_UNIQUE)

/obj/machinery/power/deck_relay/attackby(obj/item/O, mob/user)
	if(default_unfasten_wrench(user, O, 40))
		process()	//this'll clear the info
		return FALSE
	. = ..()
