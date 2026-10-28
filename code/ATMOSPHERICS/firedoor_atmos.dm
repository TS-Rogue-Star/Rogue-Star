/////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star October 2026: Airlock and Fire Safety Processing //
/////////////////////////////////////////////////////////////////////////////////////

/datum/room_atmos_subscription/firedoor
	var/list/neighbor_turfs
	var/list/neighbor_air

/datum/room_atmos_subscription/firedoor/clear_sources()
	for(var/turf/T as anything in neighbor_turfs)
		UnregisterSignal(T, list(COMSIG_TURF_ATMOS_CHANGED, COMSIG_PARENT_QDELETING))
	neighbor_turfs = null
	for(var/datum/gas_mixture/G as anything in neighbor_air)
		LAZYREMOVE(G.room_atmos_dependents, src)
		UnregisterSignal(G, COMSIG_PARENT_QDELETING)
	neighbor_air = null
	return ..()

/datum/room_atmos_subscription/firedoor/proc/bind_neighbors(turf/center)
	if(environment_turf == center && neighbor_turfs)
		return
	clear_sources()
	var/list/new_turfs = list()
	var/list/new_air = list()
	for(var/direction in cardinal)
		var/turf/T = get_step(center, direction)
		if(!T)
			continue
		new_turfs += T
		if(istype(T, /turf/simulated))
			var/datum/gas_mixture/G = T.return_air()
			if(G)
				new_air |= G
	bind(center, null, null)
	neighbor_turfs = new_turfs
	neighbor_air = new_air
	for(var/turf/T as anything in neighbor_turfs)
		RegisterSignal(T, list(COMSIG_TURF_ATMOS_CHANGED, COMSIG_PARENT_QDELETING), PROC_REF(invalidate))
	for(var/datum/gas_mixture/G as anything in neighbor_air)
		LAZYADD(G.room_atmos_dependents, src)
		RegisterSignal(G, COMSIG_PARENT_QDELETING, PROC_REF(invalidate))
