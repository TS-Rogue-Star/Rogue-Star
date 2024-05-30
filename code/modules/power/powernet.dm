/datum/powernet
	var/number					// unique id
	var/list/cables = list()	// all cables & junctions
	var/list/nodes = list()		// all APCs & sources

	var/load = 0				// the current load on the powernet, increased by each machine at processing
	var/newavail = 0			// what available power was gathered last tick, then becomes...
	var/avail = 0				//...the current available power in the powernet
	var/viewavail = 0			// the available power as it appears on the power console (gradually updated)
	var/viewload = 0			// the load as it appears on the power console (gradually updated)
	var/netexcess = 0			// excess power on the powernet (typically avail-load)
	var/delayedload = 0			// load applied to powernet between power ticks.
	var/problem = FALSE			// power events or something


/datum/powernet/New()
	START_PROCESSING_POWERNET(src)
	..()

/datum/powernet/Destroy()
	for(var/obj/structure/cable/C in cables)
		cables -= C
		C.powernet = null
	for(var/obj/machinery/power/M in nodes)
		nodes -= M
		M.powernet = null

	STOP_PROCESSING_POWERNET(src)
	. = ..()

/datum/powernet/proc/is_empty()
	return !cables.len && !nodes.len

/datum/powernet/proc/draw_power(var/amount)
	var/draw = between(0, amount, avail - load)
	load += draw
	return draw

// Triggers warning for certain amount of ticks
/datum/powernet/proc/trigger_warning(var/duration_ticks = 20)
	problem = max(duration_ticks, problem)

//remove a cable from the current powernet
//if the powernet is then empty, delete it
//Warning : this proc DON'T check if the cable exists
/datum/powernet/proc/remove_cable(obj/structure/cable/C)
	cables -= C
	C.powernet = null
	if(is_empty())
		qdel(src)

//add a cable to the current powernet
//Warning : this proc DON'T check if the cable exists
/datum/powernet/proc/add_cable(obj/structure/cable/C)
	if(C.powernet)
		if(C.powernet == src)
			return
		else
			C.powernet.remove_cable(C)
	C.powernet = src
	cables +=C

//remove a power machine from the current powernet
//if the powernet is then empty, delete it
//Warning : this proc DON'T check if the machine exists
/datum/powernet/proc/remove_machine(obj/machinery/power/M)
	nodes -=M
	M.powernet = null
	if(is_empty())
		qdel(src)

//add a power machine to the current powernet
//Warning : this proc DON'T check if the machine exists
/datum/powernet/proc/add_machine(obj/machinery/power/M)
	if(M.powernet)
		if(M.powernet == src)
			return
		else
			M.disconnect_from_network()
	M.powernet = src
	nodes[M] = M

//snowflake handling for multi-z's powernet 'channels'
// when they actually work anyway. Really just need to get that list...
/*
/datum/powernet/proc/add_relays_together(obj/machinery/power/deck_relay/connector, datum/powernet/PN, cable_layer = CABLE_LAYER_ALL)
	if(!istype(connector) || !istype(PN))
		stack_trace("add_relays_together doesn't like [connector] or [PN]")
		return
	if(!connector)
		stack_trace("add_relays_together doesn't have a connector!")
		return
	if(!PN)
		stack_trace("add_relays_together doesn't have a powernet!")
		return

	if(cable_layer == CABLE_LAYER_1)
		if(connector.powernet1)
			if(connector.powernet1 == PN)
				return
			else
				connector.disconnect_from_network()
		connector.powernet1 = PN
		nodes[connector] = connector
	else if(cable_layer == CABLE_LAYER_2)
		if(connector.powernet2)
			if(connector.powernet2 == PN)
				return
			else
				connector.disconnect_from_network()
		connector.powernet2 = PN
		nodes[connector] = connector
	else if(cable_layer == CABLE_LAYER_3)
		if(connector.powernet3)
			if(connector.powernet3 == PN)
				return
			else
				connector.disconnect_from_network()
		connector.powernet3 = PN
		nodes[connector] = connector
	else if(cable_layer == CABLE_LAYER_4)
		if(connector.powernet4)
			if(connector.powernet4 == PN)
				return
			else
				connector.disconnect_from_network()
		connector.powernet4 = PN
		nodes[connector] = connector
	else
		return FALSE */

//handles the power changes in the powernet
//called every ticks by the powernet controller
/datum/powernet/proc/reset()
	//see if there's a surplus of power remaining in the powernet and stores unused power in the SMES
	netexcess = avail - load

	if(netexcess > 100 && nodes && nodes.len)		// if there was excess power last cycle
		for(var/obj/machinery/power/smes/S in nodes)	// find the SMESes in the network
			S.restore()				// and restore some of the power that was used

	// update power consoles
	viewavail = round(0.8 * viewavail + 0.2 * avail)
	viewload = round(0.8 * viewload + 0.2 * load)

	// reset the powernet
	load = delayedload
	delayedload = 0
	avail = newavail
	newavail = 0

/datum/powernet/proc/get_electrocute_damage()
	//1kW = 5
	//10kW = 24
	//100kW = 45
	//250kW = 53
	//1MW = 66
	//10MW = 88
	//100MW = 110
	//1GW = 132
	if(avail >= 1 KILOWATTS)
		var/damage = log(1.1,avail)
		damage = damage - (log(1.1,damage)*1.5)
		return round(damage)
	else
		return FALSE
