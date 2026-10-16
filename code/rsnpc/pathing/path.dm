/datum/npc_path
	var/mob/living/who
	var/turf/start
	var/list/targets
	var/datum/npc_room/target_room
	var/turf/aim
	var/list/access
	var/list/skip
	var/list/rooms
	var/avoid_danger = FALSE
	var/list/people = list()
	var/person_cost
	var/datum/npc_heap/open = new
	var/list/from = list()
	var/list/cost = list()
	var/list/closed = list()
	var/tries = 0
	var/max_tries = 8000
	var/state = NPC_PATH_SEARCHING
	var/list/tiles
	var/skipped = FALSE
	var/danger = FALSE
	var/airless = FALSE

/datum/npc_path/New(mob/living/who, turf/start, list/targets, datum/npc_room/target_room, turf/aim, list/access, list/skip, list/rooms)
	src.who = who
	src.start = start
	src.targets = targets
	src.target_room = target_room
	src.aim = aim
	src.access = access
	src.skip = skip
	src.rooms = rooms
	avoid_danger = who && !npc_step_danger(start, who)
	person_cost = npc_setting("path_person_cost")
	var/datum/ai_holder/rsnpc/ai_mind = who && npc_ai_mind(who)
	for(var/mob/living/L in ai_mind?.in_sight)
		if(L != who && get_dist(L, start) <= npc_setting("path_person_range"))
			people[get_turf(L)] = TRUE
	cost[start] = 0
	open.add(start, guess(start), guess(start))

/datum/npc_path/proc/guess(turf/T)
	if(!aim)
		return 0
	return abs(T.x - aim.x) + abs(T.y - aim.y)

/datum/npc_path/proc/is_target(turf/T)
	if(targets && targets[T])
		return TRUE
	return target_room && T.npc_room == target_room

/datum/npc_path/proc/advance(budget)
	while(state == NPC_PATH_SEARCHING && budget-- > 0)
		var/turf/T = open.take()
		if(!T)
			state = (skipped || danger) ? NPC_PATH_NOT_YET : NPC_PATH_NO_WAY
			break
		if(closed[T])
			continue
		closed[T] = TRUE
		if(is_target(T))
			make_path(T)
			state = NPC_PATH_FOUND
			break
		if(++tries > max_tries)
			state = NPC_PATH_NOT_YET
			break
		if(T != start && npc_stairs_other_end(T))
			continue
		for(var/dir in GLOB.cardinal)
			var/turf/N = get_step(T, dir)
			if(!N || closed[N])
				continue
			if(rooms && N.npc_room && !rooms[N.npc_room] && !(targets && targets[N]))
				continue
			if(skip && skip[N])
				skipped = TRUE
				continue
			if(!npc_can_step(T, N, access))
				continue
			if(avoid_danger && npc_step_danger(N, who))
				danger = TRUE
				if(!npc_air_known_safe(N, who))
					airless = TRUE
				continue
			var/c = cost[T] + 1 + (people[N] ? person_cost : 0)
			if(!isnull(cost[N]) && cost[N] <= c)
				continue
			cost[N] = c
			from[N] = T
			var/h = guess(N)
			open.add(N, c + h, h)
	return state

/datum/npc_path/proc/make_path(turf/T)
	tiles = list()
	var/limit = tries + 1
	while(T && T != start && limit-- > 0)
		tiles.Insert(1, T)
		T = from[T]
