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

/datum/ai_holder/rsnpc/proc/npc_search(want, datum/callback/accept, range = 90)
	var/turf/here = get_turf(holder)
	if(!here)
		return null
	var/obj/item/deep
	for(var/obj/item/I in holder.get_contents())
		if(!istype(I, want) || (accept && !accept.Invoke(I.type, here, I)))
			continue
		if(in_reach(I))
			return new /datum/npc_source(I.type, here, I, NPC_SOURCE_HELD, 0)
		deep = deep || I
	if(deep)
		return new /datum/npc_source(deep.type, here, deep, NPC_SOURCE_HELD, 1)
	var/list/near = list()
	var/list/holders = list()
	for(var/atom/movable/A as anything in look())
		if(!isturf(A.loc))
			continue
		if(istype(A, want))
			if(usable_source(A.type, A.loc, A, accept))
				near += A
		else
			var/datum/npc_seen/S = seen[npc_thing_key(A.type, A.loc)]
			if(npc_holds(S ? S.holds : npc_supplies_of(A, A.Adjacent(holder)), want) && usable_source(A.type, A.loc, null, accept))
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

/datum/ai_holder/rsnpc/proc/usable_source(kind, turf/place, atom/thing, datum/callback/accept)
	if(crossed_off(npc_thing_key(kind, place)) || crossed_off(npc_place_key(place)))
		return FALSE
	return !accept || accept.Invoke(kind, place, thing)

/datum/ai_holder/rsnpc/proc/reach_cost(turf/T)
	var/turf/here = get_turf(holder)
	var/datum/npc_room/from = npc_room_of(here)
	if(!from || !T)
		return null
	if(from != reach_from || world.time > reach_at + 5 SECONDS)
		var/list/R = GLOB.npc_rooms.reach(from, here, holder.GetAccess(), src)
		reach_from = from
		reach_at = world.time
		reach_costs = R[1]
		reach_entries = R[2]
	for(var/datum/npc_room/room as anything in npc_rooms_of(T))
		if(isnull(reach_costs[room]))
			continue
		var/turf/E = reach_entries[room]
		var/c = reach_costs[room] + abs(E.x - T.x) + abs(E.y - T.y)
		if(isnull(.) || c < .)
			. = c

/datum/ai_holder/rsnpc/proc/nearest_source(list/options, from)
	var/best
	var/best_cost
	for(var/option in options)
		var/turf/T
		if(istype(option, /datum/npc_seen))
			var/datum/npc_seen/S = option
			T = S.place
		else
			var/atom/movable/A = option
			T = A.loc
		var/cost = reach_cost(T)
		if(isnull(cost) || (!isnull(best_cost) && cost >= best_cost))
			continue
		best = option
		best_cost = cost
	if(!best)
		return null
	if(istype(best, /datum/npc_seen))
		var/datum/npc_seen/S = best
		return new /datum/npc_source(S.kind, S.place, null, from, best_cost)
	var/atom/movable/A = best
	return new /datum/npc_source(A.type, A.loc, A, from, best_cost)
