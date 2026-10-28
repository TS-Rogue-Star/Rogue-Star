////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star October 2026: Portable Connector Processing //
////////////////////////////////////////////////////////////////////////////////

/obj/machinery/atmospherics/portables_connector
	icon = 'icons/atmos/connector.dmi'
	icon_state = "map_connector"

	name = "Connector Port"
	desc = "For connecting portables devices related to atmospherics control."

	dir = SOUTH
	initialize_directions = SOUTH
	construction_type = /obj/item/pipe/directional
	pipe_state = "connector"
	pipe_flags = PIPING_DEFAULT_LAYER_ONLY|PIPING_ONE_PER_TURF

	var/obj/machinery/portable_atmospherics/connected_device

	var/obj/machinery/atmospherics/node

	var/datum/pipe_network/network

	var/on = 0
	use_power = USE_POWER_OFF
	level = 1
	processing_on_demand = TRUE // RS Add: Portable Connector Processing (Lira, October 2026)

/obj/machinery/atmospherics/portables_connector/fuel
	icon_state = "map_connector-fuel"
	pipe_state = "connector-fuel"
	icon_connect_type = "-fuel"
	pipe_flags = PIPING_ONE_PER_TURF
	connect_types = CONNECT_TYPE_FUEL

/obj/machinery/atmospherics/portables_connector/aux
	icon_state = "map_connector-aux"
	pipe_state = "connector-aux"
	icon_connect_type = "-aux"
	pipe_flags = PIPING_ONE_PER_TURF
	connect_types = CONNECT_TYPE_AUX

/obj/machinery/atmospherics/portables_connector/init_dir()
	initialize_directions = dir

/obj/machinery/atmospherics/portables_connector/update_icon()
	icon_state = "connector"

/obj/machinery/atmospherics/portables_connector/update_underlays()
	if(..())
		underlays.Cut()
		var/turf/T = get_turf(src)
		if(!istype(T))
			return
		add_underlay(T, node, dir, node?.icon_connect_type)

/obj/machinery/atmospherics/portables_connector/hide(var/i)
	update_underlays()

// RS Edit: Portable Connector Processing (Lira, October 2026)
/obj/machinery/atmospherics/portables_connector/process()
	..()
	if(!connected_device)
		on = 0
	if(!on || !network)
		return room_atmos_sleep(TRUE)
	watch_room_atmos(null, null, network)
	var/datum/gas_mixture/connected_air = get_connected_air()
	if(connected_air && connected_air.temperature > PHORON_MINIMUM_BURN_TEMPERATURE)
		network.update = 1
	if(network.update)
		return 1
	return room_atmos_sleep()

// RS Add: Portable Connector Processing (Lira, October 2026)
/obj/machinery/atmospherics/portables_connector/wake_processing()
	if(!QDELETED(src) && on && connected_device && network)
		network.update = 1
	return ..()

// RS Add: Portable Connector Processing (Lira, October 2026)
/obj/machinery/atmospherics/portables_connector/vv_edit_var(var_name, new_value)
	. = ..()
	if(. && var_name == NAMEOF(src, on))
		wake_processing()

// RS Add: Portable Connector Processing (Lira, October 2026)
/obj/machinery/atmospherics/portables_connector/proc/get_connected_air()
	if(istype(connected_device, /obj/mecha))
		var/obj/mecha/M = connected_device
		return M.internal_tank?.air_contents
	return connected_device?.air_contents

// Housekeeping and pipe network stuff below
/obj/machinery/atmospherics/portables_connector/get_neighbor_nodes_for_init()
	return list(node)

/obj/machinery/atmospherics/portables_connector/network_expand(datum/pipe_network/new_network, obj/machinery/atmospherics/pipe/reference)
	if(reference == node)
		network = new_network
		room_atmos_subscription?.invalidate() // RS Add: Portable Connector Processing (Lira, October 2026)

	if(new_network.normal_members.Find(src))
		return 0

	new_network.normal_members += src

	return null

// RS Edit: Portable Connector Processing (Lira, October 2026)
/obj/machinery/atmospherics/portables_connector/Destroy()
	if(connected_device)
		connected_device.disconnect()

	. = ..()

	if(node)
		node.disconnect(src)
		qdel(network)

	node = null

/obj/machinery/atmospherics/portables_connector/atmos_init()
	room_atmos_subscription?.invalidate() // RS Add: Portable Connector Processing (Lira, October 2026)
	if(node)
		return

	var/node_connect = dir

	for(var/obj/machinery/atmospherics/target in get_step(src,node_connect))
		if(can_be_node(target, 1))
			node = target
			break

	update_icon()
	update_underlays()

/obj/machinery/atmospherics/portables_connector/build_network()
	if(!network && node)
		network = new /datum/pipe_network()
		network.normal_members += src
		network.build_network(node, src)


/obj/machinery/atmospherics/portables_connector/return_network(obj/machinery/atmospherics/reference)
	build_network()

	if(reference==node)
		return network

	if(reference==connected_device)
		return network

	return null

/obj/machinery/atmospherics/portables_connector/reassign_network(datum/pipe_network/old_network, datum/pipe_network/new_network)
	if(network == old_network)
		network = new_network
		room_atmos_subscription?.invalidate() // RS Add: Portable Connector Processing (Lira, October 2026)

	return 1

// RS Edit: Portable Connector Processing (Lira, October 2026)
/obj/machinery/atmospherics/portables_connector/return_network_air(datum/pipe_network/reference)
	var/list/results = list()

	var/datum/gas_mixture/connected_air = get_connected_air()
	if(connected_air)
		results += connected_air

	return results

/obj/machinery/atmospherics/portables_connector/disconnect(obj/machinery/atmospherics/reference)
	if(reference==node)
		qdel(network)
		node = null
		room_atmos_subscription?.invalidate() // RS Add: Portable Connector Processing (Lira, October 2026)

	update_underlays()

	return null


/obj/machinery/atmospherics/portables_connector/attackby(var/obj/item/weapon/W as obj, var/mob/user as mob)
	if (!W.is_wrench())
		return ..()
	if (connected_device)
		to_chat(user, "<span class='warning'>You cannot unwrench \the [src], dettach \the [connected_device] first.</span>")
		return 1
	if (locate(/obj/machinery/portable_atmospherics, src.loc))
		return 1
	if(!can_unwrench())
		to_chat(user, "<span class='warning'>You cannot unwrench \the [src], it too exerted due to internal pressure.</span>")
		add_fingerprint(user)
		return 1
	playsound(src, W.usesound, 50, 1)
	to_chat(user, "<span class='notice'>You begin to unfasten \the [src]...</span>")
	if (do_after(user, 40 * W.toolspeed))
		user.visible_message( \
			"<b>\The [user]</b> unfastens \the [src].", \
			"<span class='notice'>You have unfastened \the [src].</span>", \
			"You hear a ratchet.")
		deconstruct()
