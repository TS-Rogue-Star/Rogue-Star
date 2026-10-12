/datum/npc_seen
	var/kind
	var/turf/place
	var/amount = 1
	var/seen_at = 0
	var/list/holds
	var/kept = FALSE

/datum/ai_holder/complex_npc/proc/remember_sights()
	var/list/found = list()
	var/list/counts = list()
	for(var/atom/movable/A as anything in in_sight)
		if(!isturf(A.loc) || !(isitem(A) || is_type_in_list(A, place_kinds)))
			continue
		var/key = npc_thing_key(A.type, A.loc)
		found[key] = A
		counts[key] += 1
	var/list/gone = list()
	for(var/key in seen)
		var/datum/npc_seen/S = seen[key]
		if(turfs_in_sight[S.place] && !found[key])
			gone += key
	seen -= gone
	for(var/key in found)
		var/atom/movable/A = found[key]
		var/datum/npc_seen/S = seen[key]
		if(!S)
			S = new
			S.kind = A.type
			S.place = A.loc
			seen[key] = S
		S.amount = counts[key]
		S.seen_at = world.time
		var/close = A.Adjacent(holder)
		if(close || isnull(S.holds))
			S.holds = npc_supplies_of(A, close)
	while(length(seen) > 500)
		forget_one()

/datum/ai_holder/complex_npc/proc/forget_one()
	var/list/by_kind = list()
	for(var/key in seen)
		var/datum/npc_seen/S = seen[key]
		if(!S.kept)
			by_kind[S.kind] += 1
	var/most
	for(var/kind in by_kind)
		if(!most || by_kind[kind] > by_kind[most])
			most = kind
	var/oldest
	var/oldest_at
	for(var/key in seen)
		var/datum/npc_seen/S = seen[key]
		if(S.kind == most && !S.kept && (!oldest || S.seen_at < oldest_at))
			oldest = key
			oldest_at = S.seen_at
	if(!oldest)
		oldest = seen[1]
	seen -= oldest

/datum/ai_holder/complex_npc/proc/forget_place(turf/T, kind)
	var/list/gone = list()
	for(var/key in seen)
		var/datum/npc_seen/S = seen[key]
		if(S.place == T && (!kind || ispath(S.kind, kind)))
			gone += key
	seen -= gone

/datum/ai_holder/complex_npc/proc/learn_workplace()
	if(!workplace)
		return
	for(var/obj/structure/closet/C in workplace)
		var/datum/npc_seen/S = new
		S.kind = C.type
		S.place = get_turf(C)
		S.holds = C.npc_start_supplies
		S.kept = TRUE
		S.seen_at = world.time
		seen[npc_thing_key(C.type, S.place)] = S
