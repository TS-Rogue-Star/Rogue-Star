/obj/machinery/power/deck_relay //This bridges powernets betwen Z levels
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
	/// Powernet channels list
	var/datum/powernet/powernet1
	var/datum/powernet/powernet2
	var/datum/powernet/powernet3
	var/list/powernets

/obj/machinery/power/deck_relay/Initialize(mapload)
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(find_and_connect)), 30)
	addtimer(CALLBACK(src, PROC_REF(refresh)), 50) //Wait a bit so we can find the one below, then get powering

/obj/machinery/power/deck_relay/process()
	if(!anchored)
		icon_state = "cablerelay-off"
		if(connectionup) //Lose connections
			connectionup.connectiondown = null
		if(connectiondown)
			connectiondown.connectionup = null
		return
	refresh() //Sometimes the powernets get lost, so we need to keep checking.
	if(!powernets)
		icon_state = "cablerelay-off"
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

	if(!connectiondown || QDELETED(connectiondown) || !connectionup || QDELETED(connectionup))
		icon_state = "cablerelay-off"
		find_and_connect()

/obj/machinery/power/deck_relay/hides_under_flooring()
	return TRUE

///Handles re-acquiring + merging powernets found by find_and_connect()
/obj/machinery/power/deck_relay/proc/refresh()
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
	else if(powernet && MZ.powernet)
		var/obj/structure/cable/C = merge_from.get_cable_node(CABLE_LAYER_4)
		var/obj/structure/cable/XR = merge_to.get_cable_node(CABLE_LAYER_4)
		if(C && XR)
			merge_powernets(XR.powernet,C.powernet)

///Locates relays that are above and below this object
/obj/machinery/power/deck_relay/proc/find_and_connect()
	var/turf/T = get_turf(src)
	if(!T || !istype(T))
		return FALSE
	connectiondown = null //in case we're re-establishing
	connectionup = null
	var/obj/structure/cable/C = T.get_cable_node() //check if we have a node cable on the machine turf.
	if(C && C.powernet)
		if(C.cable_layer == CABLE_LAYER_1)
			C.powernet.add_relays_together(src, CABLE_LAYER_1)
			powernet1 = C.powernet
		else if(C.cable_layer == CABLE_LAYER_2)
			C.powernet.add_relays_together(src, CABLE_LAYER_2)
			powernet2 = C.powernet
		else if(C.cable_layer == CABLE_LAYER_3)
			C.powernet.add_relays_together(src, CABLE_LAYER_3)
			powernet3 = C.powernet
		else if(C.cable_layer == CABLE_LAYER_4)
			C.powernet.add_relays_together(src, CABLE_LAYER_4)
			powernet = C.powernet
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
