///////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star October 2026: Piped Gas Flow and Telemetry //
///////////////////////////////////////////////////////////////////////////////

//
// Vent Pipe - Unpowered vent
//
/obj/machinery/atmospherics/pipe/vent
	processing_on_demand = TRUE // RS Add: Piped Gas Flow and Telemetry (Lira, October 2026)
	icon = 'icons/obj/atmospherics/pipe_vent.dmi'
	icon_state = "intact"

	name = "Vent"
	desc = "A large air vent"

	level = 1

	volume = 250

	dir = SOUTH
	initialize_directions = SOUTH
	pipe_flags = PIPING_DEFAULT_LAYER_ONLY
	construction_type = /obj/item/pipe/directional
	pipe_state = "passive_vent"

	var/build_killswitch = 1

/obj/machinery/atmospherics/pipe/vent/init_dir()
	initialize_directions = dir

/obj/machinery/atmospherics/pipe/vent/high_volume
	name = "Larger vent"
	volume = 1000

// RS Edit: Piped Gas Flow and Telemetry (Lira, October 2026)
/obj/machinery/atmospherics/pipe/vent/process()
	if(!parent)
		if(build_killswitch <= 0)
			. = PROCESS_KILL
		else
			build_killswitch--
		..()
		if(!parent)
			return piped_atmos_sleep()
		return
	var/turf/T = get_turf(src)
	var/datum/gas_mixture/environment = T?.return_air()
	if(piped_atmos_equal(environment))
		return piped_atmos_sleep(T, environment)
	parent.mingle_with_turf(loc, volume)

/obj/machinery/atmospherics/pipe/vent/Destroy()
	if(node1)
		node1.disconnect(src)
		node1 = null

	. = ..()

/obj/machinery/atmospherics/pipe/vent/pipeline_expansion()
	return list(node1)

/obj/machinery/atmospherics/pipe/vent/update_icon()
	if(node1)
		icon_state = "intact"

		set_dir(get_dir(src, node1))

	else
		icon_state = "exposed"

/obj/machinery/atmospherics/pipe/vent/atmos_init()
	piped_atmos_invalidate() // RS Add: Piped Gas Flow and Telemetry (Lira, October 2026)
	var/connect_direction = dir

	for(var/obj/machinery/atmospherics/target in get_step(src,connect_direction))
		if (can_be_node(target, 1))
			node1 = target
			break

	update_icon()

/obj/machinery/atmospherics/pipe/vent/disconnect(obj/machinery/atmospherics/reference)
	piped_atmos_invalidate() // RS Add: Piped Gas Flow and Telemetry (Lira, October 2026)
	if(reference == node1)
		if(istype(node1, /obj/machinery/atmospherics/pipe))
			qdel(parent)
		node1 = null

	update_icon()

	return null

/obj/machinery/atmospherics/pipe/vent/hide(var/i) //to make the little pipe section invisible, the icon changes.
	if(node1)
		icon_state = "[i == 1 && istype(loc, /turf/simulated) ? "h" : "" ]intact"
		set_dir(get_dir(src, node1))
	else
		icon_state = "exposed"
