/datum/npc_source
	var/kind
	var/turf/place
	var/atom/thing
	var/from
	var/cost = 0

/datum/npc_source/New(kind, turf/place, atom/thing, from, cost)
	src.kind = kind
	src.place = place
	src.thing = thing
	src.from = from
	src.cost = cost

/datum/ai_holder/complex_npc/proc/npc_search(want, datum/callback/accept, range = 90)
	var/turf/here = get_turf(holder)
	if(!here)
		return null
	for(var/obj/item/I in holder.get_contents())
		if(istype(I, want) && (!accept || accept.Invoke(I.type, here, I)))
			return new /datum/npc_source(I.type, here, I, NPC_SOURCE_HELD, 0)
	var/list/near = list()
	var/list/holders = list()
	for(var/atom/movable/A as anything in look())
		if(!isturf(A.loc))
			continue
		if(istype(A, want))
			if(usable_source(A.type, A.loc, A, accept))
				near += A
		else if(npc_holds(npc_supplies_of(A, A.Adjacent(holder)), want) && usable_source(A.type, A.loc, null, accept))
			holders += A
	var/datum/npc_source/L = nearest_source(near, NPC_SOURCE_IN_SIGHT) || nearest_source(holders, NPC_SOURCE_KEPT)
	if(L)
		return L
	var/list/remembered = list()
	var/list/kept = list()
	for(var/key in seen)
		var/datum/npc_seen/S = seen[key]
		if(turfs_in_sight[S.place] || (S.place.z == here.z && get_dist(here, S.place) > range))
			continue
		if(ispath(S.kind, want))
			if(usable_source(S.kind, S.place, null, accept))
				remembered += S
		else if(npc_holds(S.holds, want) && usable_source(S.kind, S.place, null, accept))
			kept += S
	return nearest_source(remembered, NPC_SOURCE_SEEN) || nearest_source(kept, NPC_SOURCE_KEPT)

/datum/ai_holder/complex_npc/proc/usable_source(kind, turf/place, atom/thing, datum/callback/accept)
	if(crossed_off(npc_thing_key(kind, place)) || crossed_off(npc_place_key(place)))
		return FALSE
	return !accept || accept.Invoke(kind, place, thing)

/datum/ai_holder/complex_npc/proc/nearest_source(list/options, from)
	var/turf/here = get_turf(holder)
	var/list/by_distance = list()
	for(var/option in options)
		var/turf/T = get_turf(option)
		if(istype(option, /datum/npc_seen))
			var/datum/npc_seen/S = option
			T = S.place
		by_distance[option] = get_dist(here, T) + abs(here.z - T.z) * 20
	sortTim(by_distance, GLOBAL_PROC_REF(cmp_numeric_asc), TRUE)
	var/list/access = holder.GetAccess()
	var/checked = 0
	for(var/option in by_distance)
		if(++checked > 3)
			break
		var/kind
		var/turf/T
		var/atom/thing
		if(istype(option, /datum/npc_seen))
			var/datum/npc_seen/S = option
			kind = S.kind
			T = S.place
		else
			var/atom/movable/A = option
			kind = A.type
			T = A.loc
			thing = A
		var/cost = GLOB.npc_rooms.route_length(here, T, access, src)
		if(isnull(cost))
			continue
		return new /datum/npc_source(kind, T, thing, from, cost)
	return null
