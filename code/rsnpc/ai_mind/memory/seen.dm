GLOBAL_LIST_INIT(npc_public_rest_places, list("bar", "cafe", "cafeteria"))
GLOBAL_LIST_EMPTY(npc_known_places)
GLOBAL_VAR_INIT(npc_known_places_ready, FALSE)

/datum/npc_seen
	var/kind
	var/turf/place
	var/amount = 1
	var/seen_at = 0
	var/list/holds
	var/kept = FALSE

/datum/ai_holder/rsnpc/proc/remember_sights()
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
		var/obj/structure/closet/C = A
		if(isnull(S.holds) || close && (!istype(C) || C.opened))
			S.holds = npc_supplies_of(A, close)
	while(length(seen) > 500)
		forget_one()

/datum/ai_holder/rsnpc/proc/forget_one()
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

/datum/ai_holder/rsnpc/proc/forget_place(turf/T, kind)
	var/list/gone = list()
	for(var/key in seen)
		var/datum/npc_seen/S = seen[key]
		if(S.place == T && (!kind || ispath(S.kind, kind)))
			gone += key
	seen -= gone

/datum/ai_holder/rsnpc/proc/learn_workplace()
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
		place_kinds |= C.type

/proc/npc_in_public_rest_place(obj/O)
	var/area/A = get_area(O)
	var/name = lowertext("[A?.name]")
	for(var/word in GLOB.npc_public_rest_places)
		if(findtext(name, word))
			return TRUE
	return FALSE

/hook/roundstart/proc/map_npc_known_places()
	spawn(0)
		var/datum/npc_role/R = new
		for(var/kind in R.known_kinds)
			GLOB.npc_known_places[kind] = list()
		for(var/obj/O in world)
			if(isturf(O.loc) && (O.z in npc_levels()))
				for(var/kind in R.known_kinds)
					if(istype(O, kind) && (!istype(O, /obj/structure/bed/chair) || npc_in_public_rest_place(O)))
						GLOB.npc_known_places[kind] += list(list(O.type, O.loc, istype(O, /obj/item/weapon/storage) ? npc_contents_kinds(O) : npc_supplies_of(O)))
			CHECK_TICK
		GLOB.npc_known_places_ready = TRUE
	return TRUE

/datum/ai_holder/rsnpc/proc/learn_known_places()
	if(known_places_learned || !GLOB.npc_known_places_ready)
		return
	known_places_learned = TRUE
	for(var/kind in role.known_kinds)
		place_kinds |= kind
		for(var/list/entry as anything in GLOB.npc_known_places[kind])
			var/datum/npc_seen/S = new
			S.kind = entry[1]
			S.place = entry[2]
			S.holds = entry[3]
			S.kept = TRUE
			S.seen_at = world.time
			seen[npc_thing_key(S.kind, S.place)] = S
