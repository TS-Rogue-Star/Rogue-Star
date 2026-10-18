/datum/ai_holder/rsnpc
	var/list/people_in_sight = list()
	var/people_looked_at = 0

/datum/ai_holder/rsnpc/proc/look_people()
	if(looked_at && world.time < looked_at + 1 SECOND)
		var/list/people = list()
		for(var/mob/living/M in in_sight)
			people += M
		return people
	if(people_looked_at && world.time < people_looked_at + 1 SECOND)
		return people_in_sight
	people_looked_at = world.time
	people_in_sight = list()
	var/turf/here = get_turf(holder)
	if(!here || holder.is_blind())
		return people_in_sight
	var/list/nearby = hear(7, here)
	var/list/visible_turfs = list()
	visible_turfs[here] = TRUE
	for(var/mob/living/M in nearby)
		if(M == holder || !isturf(M.loc) || M.invisibility > holder.see_invisible)
			continue
		var/turf/T = M.loc
		var/visible = visible_turfs[T]
		if(isnull(visible))
			visible = (T in nearby) && can_see_tile(here, T)
			visible_turfs[T] = visible
		if(visible)
			people_in_sight += M
	return people_in_sight

/datum/ai_holder/rsnpc/proc/can_see_tile(turf/here, turf/T)
	return get_dist(here, T) <= holder.see_in_dark || T.get_lumcount() > LIGHTING_SOFT_THRESHOLD

/datum/ai_holder/rsnpc/proc/look()
	if(looked_at && world.time < looked_at + 1 SECOND)
		return in_sight
	looked_at = world.time
	people_in_sight = null
	people_looked_at = 0
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
			if(can_see_tile(here, T))
				turfs_in_sight[T] = TRUE
		else if(A != holder)
			things += A
	for(var/atom/movable/A as anything in things)
		if(turfs_in_sight[A.loc] && A.invisibility <= holder.see_invisible)
			in_sight += A
	remember_sights()
	var/list/checked_air = list()
	for(var/turf/T as anything in turfs_in_sight)
		danger_seen -= T
		var/bad = npc_air_bad(T, holder, checked_air)
		if(bad != npc_built_air_bad(T, holder))
			air_seen[T] = bad
		else
			air_seen -= T
	for(var/atom/A as anything in in_sight)
		for(var/turf/T as anything in npc_machine_danger_tiles(A))
			danger_seen[T] = TRUE
	form_opinions()
	return in_sight

/datum/ai_holder/rsnpc/proc/sees(atom/movable/A)
	if(A in look())
		return TRUE
	looked_at = 0
	return A in look()
