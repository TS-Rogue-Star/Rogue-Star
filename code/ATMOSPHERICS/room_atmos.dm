/////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star October 2026: Room Atmosphere Processing //
/////////////////////////////////////////////////////////////////////////////

var/global/list/room_atmos_changed_mixtures = list()
var/global/list/room_atmos_changed_networks = list()

/datum/gas_mixture
	var/list/room_atmos_dependents
	var/room_atmos_queued = FALSE
	var/datum/pipe_network/room_atmos_network

/datum/gas_mixture/proc/room_atmos_changed()
	if(room_atmos_dependents && !room_atmos_queued)
		room_atmos_queued = TRUE
		room_atmos_changed_mixtures += src
	room_atmos_network?.room_atmos_changed()

/datum/gas_mixture/Destroy()
	room_atmos_changed_mixtures -= src
	room_atmos_queued = FALSE
	room_atmos_network = null
	. = ..()
	room_atmos_dependents = null

/datum/gas_mixture/vv_edit_var(var_name, new_value)
	if(var_name in list("room_atmos_dependents", "room_atmos_queued", "room_atmos_network"))
		return FALSE
	. = ..()
	if(.)
		room_atmos_changed()

/datum/pipe_network
	var/list/room_atmos_dependents
	var/room_atmos_queued = FALSE

/datum/pipe_network/proc/room_atmos_changed()
	if(room_atmos_dependents && !room_atmos_queued)
		room_atmos_queued = TRUE
		room_atmos_changed_networks += src
		for(var/datum/room_atmos_subscription/S as anything in room_atmos_dependents)
			if(istype(S.machine, /obj/machinery/atmospherics/portables_connector))
				update = TRUE
				break

/datum/pipe_network/vv_edit_var(var_name, new_value)
	if(var_name in list("room_atmos_dependents", "room_atmos_queued"))
		return FALSE
	. = ..()
	if(.)
		room_atmos_changed()

/proc/flush_room_atmos_wakes()
	if(!room_atmos_changed_mixtures.len && !room_atmos_changed_networks.len)
		return
	var/list/targets = list()
	for(var/datum/gas_mixture/G as anything in room_atmos_changed_mixtures)
		G.room_atmos_queued = FALSE
		for(var/datum/room_atmos_subscription/S as anything in G.room_atmos_dependents)
			targets |= S.machine
	room_atmos_changed_mixtures.Cut()
	for(var/datum/pipe_network/N as anything in room_atmos_changed_networks)
		N.room_atmos_queued = FALSE
		for(var/datum/room_atmos_subscription/S as anything in N.room_atmos_dependents)
			targets |= S.machine
	room_atmos_changed_networks.Cut()
	for(var/obj/machinery/M as anything in targets)
		M.wake_processing()

/turf/proc/room_atmos_changed()
	SEND_SIGNAL(src, COMSIG_TURF_ATMOS_CHANGED)

/datum/room_atmos_subscription
	var/obj/machinery/machine
	var/turf/environment_turf
	var/datum/gas_mixture/environment
	var/datum/pipe_network/network

/datum/room_atmos_subscription/New(obj/machinery/owner)
	machine = owner
	RegisterSignal(machine, list(COMSIG_MOVABLE_MOVED, COMSIG_ATOM_DIR_CHANGE), PROC_REF(invalidate))
	RegisterSignal(machine, COMSIG_PARENT_QDELETING, PROC_REF(owner_deleted))

/datum/room_atmos_subscription/proc/owner_deleted()
	SIGNAL_HANDLER
	qdel(src)

/datum/room_atmos_subscription/Destroy()
	clear_sources()
	if(machine)
		UnregisterSignal(machine, list(COMSIG_MOVABLE_MOVED, COMSIG_ATOM_DIR_CHANGE, COMSIG_PARENT_QDELETING))
		machine.room_atmos_subscription = null
	machine = null
	return ..()

/datum/room_atmos_subscription/proc/clear_sources()
	if(environment_turf)
		UnregisterSignal(environment_turf, list(COMSIG_TURF_ATMOS_CHANGED, COMSIG_PARENT_QDELETING))
		environment_turf = null
	if(environment)
		LAZYREMOVE(environment.room_atmos_dependents, src)
		UnregisterSignal(environment, COMSIG_PARENT_QDELETING)
		environment = null
	if(network)
		LAZYREMOVE(network.room_atmos_dependents, src)
		UnregisterSignal(network, COMSIG_PARENT_QDELETING)
		network = null

/datum/room_atmos_subscription/proc/invalidate()
	SIGNAL_HANDLER
	clear_sources()
	machine?.wake_processing()

/datum/room_atmos_subscription/proc/bind(turf/T, datum/gas_mixture/G, datum/pipe_network/N)
	if(QDELETED(N))
		N = null
	if(!istype(T, /turf/simulated))
		G = null
	if(T == environment_turf && G == environment && N == network)
		return
	clear_sources()
	environment_turf = T
	environment = G
	network = N
	if(T)
		RegisterSignal(T, list(COMSIG_TURF_ATMOS_CHANGED, COMSIG_PARENT_QDELETING), PROC_REF(invalidate))
	if(G)
		LAZYADD(G.room_atmos_dependents, src)
		RegisterSignal(G, COMSIG_PARENT_QDELETING, PROC_REF(invalidate))
	if(N)
		LAZYADD(N.room_atmos_dependents, src)
		RegisterSignal(N, COMSIG_PARENT_QDELETING, PROC_REF(invalidate))

/obj/machinery
	var/datum/room_atmos_subscription/room_atmos_subscription

/obj/machinery/proc/watch_room_atmos(turf/T, datum/gas_mixture/G, datum/pipe_network/N)
	if(!room_atmos_subscription)
		room_atmos_subscription = new(src)
	room_atmos_subscription.bind(T, G, N)

/obj/machinery/proc/room_atmos_sleep(clear_sources = FALSE)
	if(!room_atmos_subscription)
		room_atmos_subscription = new(src)
	if(clear_sources)
		room_atmos_subscription.bind(get_turf(src), null, null)
	return PROCESS_KILL

/obj/machinery/atmospherics/unary/vent_pump/proc/room_atmos_turf()
	return get_turf(src)

/obj/machinery/atmospherics/unary/vent_pump/high_volume/wall_mounted/room_atmos_turf()
	return get_step(src, reverse_dir[dir]) || ..()

/turf/vv_edit_var(var_name, new_value)
	. = ..()
	if(. && (var_name in list("air", "zone", "oxygen", "nitrogen", "carbon_dioxide", "phoron", "temperature")))
		room_atmos_changed()

/zone/vv_edit_var(var_name, new_value)
	. = ..()
	if(. && (var_name in list("air", "invalid")))
		for(var/turf/T as anything in contents)
			T.room_atmos_changed()

/obj/machinery/atmospherics/unary/update_use_power(new_use_power)
	. = ..()
	if(. && processing_on_demand)
		wake_processing()

/obj/machinery/atmospherics/unary/vv_edit_var(var_name, new_value)
	. = ..()
	if(. && processing_on_demand && var_name == "air_contents")
		network?.update_network_gases()
		room_atmos_subscription?.invalidate()
