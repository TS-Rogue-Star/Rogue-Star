/datum/ai_holder/complex_npc/proc/look()
	if(looked_at && world.time < looked_at + 1 SECOND)
		return in_sight
	looked_at = world.time
	in_sight = list()
	turfs_in_sight = list()
	var/turf/here = get_turf(holder)
	if(!here)
		return in_sight
	turfs_in_sight[here] = TRUE
	if(holder.is_blind())
		remember_sights()
		return in_sight
	var/list/things = list()
	for(var/atom/A in hear(7, here))
		var/turf/T = A
		if(istype(T))
			if(get_dist(here, T) <= holder.see_in_dark || T.get_lumcount() > LIGHTING_SOFT_THRESHOLD)
				turfs_in_sight[T] = TRUE
		else if(A != holder)
			things += A
	for(var/atom/movable/A as anything in things)
		if(turfs_in_sight[A.loc])
			in_sight += A
	remember_sights()
	for(var/turf/T as anything in turfs_in_sight)
		danger_seen -= T
		var/bad = npc_air_bad(T, holder)
		if(bad != npc_built_air_bad(T, holder))
			air_seen[T] = bad
		else
			air_seen -= T
	for(var/atom/A as anything in in_sight)
		for(var/turf/T as anything in npc_machine_danger_tiles(A))
			danger_seen[T] = TRUE
	form_opinions()
	return in_sight

/datum/ai_holder/complex_npc/proc/sees(atom/movable/A)
	if(A in look())
		return TRUE
	looked_at = 0
	return A in look()
