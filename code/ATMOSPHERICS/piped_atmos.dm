///////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star October 2026: Piped Gas Flow and Telemetry //
///////////////////////////////////////////////////////////////////////////////

var/global/list/piped_atmos_base_types = list(
	/obj/machinery/atmospherics,
	/obj/machinery/atmospherics/binary,
	/obj/machinery/atmospherics/trinary,
	/obj/machinery/atmospherics/unary,
	/obj/machinery/atmospherics/unary/engine,
	/obj/machinery/atmospherics/unary/engine/bigger,
	/obj/machinery/atmospherics/unary/engine/biggest,
	/obj/machinery/atmospherics/unary/engine/fancy_shuttle
)

/datum/room_atmos_subscription/piped
	var/list/sources = list()
	var/heartbeat_timer

/datum/room_atmos_subscription/piped/clear_sources()
	if(heartbeat_timer)
		deltimer(heartbeat_timer)
		heartbeat_timer = null
	for(var/datum/D as anything in sources)
		if(istype(D, /datum/gas_mixture))
			var/datum/gas_mixture/G = D
			LAZYREMOVE(G.room_atmos_dependents, src)
		else if(istype(D, /datum/pipe_network))
			var/datum/pipe_network/N = D
			LAZYREMOVE(N.room_atmos_dependents, src)
		UnregisterSignal(D, list(COMSIG_PARENT_QDELETING, COMSIG_TURF_ATMOS_CHANGED, COMSIG_PIPED_ATMOS_CHANGED, COMSIG_MOVABLE_MOVED, COMSIG_RADIO_NEW_LISTENER))
	sources.Cut()
	return ..()

/datum/room_atmos_subscription/piped/proc/bind_sources(list/new_sources)
	var/list/unique_sources = list()
	for(var/datum/D as anything in new_sources)
		if(!QDELETED(D))
			unique_sources |= D
	if(sources.len == unique_sources.len)
		var/unchanged = TRUE
		for(var/datum/D as anything in unique_sources)
			if(!(D in sources))
				unchanged = FALSE
				break
		if(unchanged)
			return
	clear_sources()
	sources = unique_sources
	for(var/datum/D as anything in sources)
		RegisterSignal(D, COMSIG_PARENT_QDELETING, PROC_REF(invalidate))
		if(istype(D, /datum/gas_mixture))
			var/datum/gas_mixture/G = D
			LAZYADD(G.room_atmos_dependents, src)
		else if(istype(D, /datum/pipe_network))
			var/datum/pipe_network/N = D
			LAZYADD(N.room_atmos_dependents, src)
		else if(isturf(D))
			RegisterSignal(D, COMSIG_TURF_ATMOS_CHANGED, PROC_REF(invalidate))
		else if(istype(D, /datum/radio_frequency))
			RegisterSignal(D, COMSIG_RADIO_NEW_LISTENER, PROC_REF(invalidate))
		else
			RegisterSignal(D, COMSIG_PIPED_ATMOS_CHANGED, PROC_REF(invalidate))
			if(ismovable(D))
				RegisterSignal(D, COMSIG_MOVABLE_MOVED, PROC_REF(invalidate))

/datum/room_atmos_subscription/piped/proc/report_after(delay)
	if(heartbeat_timer)
		deltimer(heartbeat_timer)
	heartbeat_timer = addtimer(CALLBACK(src, PROC_REF(heartbeat)), delay, TIMER_STOPPABLE)

/datum/room_atmos_subscription/piped/proc/heartbeat()
	heartbeat_timer = null
	machine?.wake_processing()

/obj/machinery/proc/watch_piped_atmos(list/sources)
	if(!istype(room_atmos_subscription, /datum/room_atmos_subscription/piped))
		QDEL_NULL(room_atmos_subscription)
		room_atmos_subscription = new /datum/room_atmos_subscription/piped(src)
	var/datum/room_atmos_subscription/piped/S = room_atmos_subscription
	S.bind_sources(sources)
	return S

/obj/machinery/atmospherics/Initialize()
	if(type in piped_atmos_base_types)
		processing_on_demand = TRUE
	return ..()

/obj/machinery/atmospherics/proc/piped_atmos_invalidate()
	room_atmos_subscription?.invalidate()
	SEND_SIGNAL(src, COMSIG_PIPED_ATMOS_CHANGED)

/obj/machinery/atmospherics/proc/piped_atmos_sources()
	return list(get_turf(src))

/obj/machinery/atmospherics/binary/piped_atmos_sources()
	return ..() + list(air1, air2, network1, network2)

/obj/machinery/atmospherics/binary/algae_farm/piped_atmos_sources()
	return ..() + list(internal)

/obj/machinery/atmospherics/trinary/piped_atmos_sources()
	return ..() + list(air1, air2, air3, network1, network2, network3)

/obj/machinery/atmospherics/unary/piped_atmos_sources()
	return ..() + list(air_contents, network)

/obj/machinery/atmospherics/omni/piped_atmos_sources()
	. = ..()
	for(var/datum/omni_port/P as anything in ports)
		. += list(P.air, P.network)

/obj/machinery/atmospherics/valve/piped_atmos_sources()
	return ..() + list(network_node1, network_node2)

/obj/machinery/atmospherics/pipe/piped_atmos_sources()
	return ..() + list(parent, parent?.air, parent?.network)

/obj/machinery/atmospherics/proc/piped_atmos_sleep_disabled()
	watch_piped_atmos(list(get_turf(src)))
	return PROCESS_KILL

/obj/machinery/atmospherics/proc/piped_atmos_sleep(turf/T, datum/gas_mixture/environment)
	var/list/sources = piped_atmos_sources()
	if(T)
		sources |= T
		if(istype(T, /turf/simulated))
			sources |= environment
	watch_piped_atmos(sources)
	return PROCESS_KILL

/obj/machinery/atmospherics/binary/dp_vent_pump/piped_atmos_sleep()
	var/turf/T = get_turf(src)
	return ..(T, T?.return_air())

/obj/machinery/atmospherics/unary/outlet_injector/piped_atmos_sleep()
	var/turf/T = get_turf(src)
	return ..(T, T?.return_air())

/obj/machinery/atmospherics/binary/vv_edit_var(var_name, new_value)
	. = ..()
	if(. && processing_on_demand && (var_name in list("air1", "air2", "internal")))
		network1?.update_network_gases()
		network2?.update_network_gases()
		piped_atmos_invalidate()

/obj/machinery/atmospherics/trinary/vv_edit_var(var_name, new_value)
	var/datum/gas_mixture/old_air
	if(var_name in list("air1", "air2"))
		old_air = vars[var_name]
	. = ..()
	if(. && processing_on_demand && (var_name in list("air1", "air2", "air3")))
		network1?.update_network_gases()
		network2?.update_network_gases()
		network3?.update_network_gases()
		if(old_air && istype(src, /obj/machinery/atmospherics/trinary/mixer))
			var/obj/machinery/atmospherics/trinary/mixer/M = src
			var/concentration = M.mixing_inputs[old_air]
			M.mixing_inputs -= old_air
			M.mixing_inputs[new_value] = concentration
		piped_atmos_invalidate()

/datum/omni_port/vv_edit_var(var_name, new_value)
	var/old_mode = mode
	. = ..()
	if(.)
		if(var_name in list("air", "network"))
			network?.update_network_gases()
		if(var_name in list("air", "concentration"))
			if(istype(master, /obj/machinery/atmospherics/omni/mixer))
				var/obj/machinery/atmospherics/omni/mixer/M = master
				M.rebuild_mixing_inputs()
			else if(var_name == "air" && istype(master, /obj/machinery/atmospherics/omni/atmos_filter))
				var/obj/machinery/atmospherics/omni/atmos_filter/F = master
				F.rebuild_filtering_list()
		if(var_name == "mode" && mode != old_mode)
			update = TRUE
			master?.update_ports()
		else if(var_name in list("dir", "node"))
			update = TRUE
			master?.update_port_icons()
			update = FALSE
		master?.piped_atmos_invalidate()

/obj/machinery/atmospherics/pipe/vent/proc/piped_atmos_equal(datum/gas_mixture/environment)
	var/datum/gas_mixture/G = parent?.air
	if(!G || !environment || G.volume <= 0 || environment.volume <= 0)
		return FALSE
	if(G.temperature > PHORON_MINIMUM_BURN_TEMPERATURE || environment.temperature > PHORON_MINIMUM_BURN_TEMPERATURE)
		return FALSE
	if((G.total_moles || environment.total_moles) && abs(G.temperature - environment.temperature) > 0.0001)
		return FALSE
	for(var/gas in G.gas | environment.gas)
		if(abs(G.gas[gas] / G.volume - environment.gas[gas] / environment.volume) > 0.0000001)
			return FALSE
	return TRUE

/obj/machinery/atmospherics/proc/piped_atmos_reacting()
	for(var/datum/pipe_network/N in piped_atmos_sources())
		if(N.update)
			for(var/datum/gas_mixture/G as anything in N.gases)
				if(G.temperature > PHORON_MINIMUM_BURN_TEMPERATURE)
					return TRUE
	return FALSE

/obj/machinery/meter/proc/piped_atmos_sources(datum/gas_mixture/environment, watch_gas = TRUE)
	var/list/sources = list(get_turf(src), target)
	if(istype(target, /obj/machinery/atmospherics/pipe))
		sources += target.parent
		if(watch_gas)
			sources += list(target.parent?.network, environment)
	else if(watch_gas && istype(target, /turf/simulated))
		sources += environment
	return sources
