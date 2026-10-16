/proc/npc_arrived(mob/living/who, atom/target)
	if(isarea(target))
		var/turf/T = get_turf(who)
		return T?.npc_room?.area == target
	if(isturf(target) && npc_can_stand(target))
		return get_turf(who) == target
	return target.Adjacent(who)

/proc/npc_can_move(mob/living/L)
	if(!isturf(L.loc) || !L.canmove || L.buckled || length(L.pinned) || length(L.grabbed_by))
		return FALSE
	if(L.restrained() && L.pulledby)
		return FALSE
	return TRUE

/datum/ai_holder/rsnpc/proc/go_to(atom/target, turf/place)
	stop_walk()
	destination = target
	destination_turf = place || get_turf(target)
	walk_outcome_why = null
	walk_lost_target = FALSE
	walk_needs_suit = FALSE
	NPC_TRACE(src, NPC_TRACE_WALK, "walking to [target] from [get_area(holder)]")

/datum/ai_holder/rsnpc/proc/stop_walk()
	destination = null
	destination_turf = null
	still_at = null
	route = null
	path_search = null
	path = list()
	obstacles = list()
	button_wait_until = 0
	failed_steps = 0
	blocked_since = 0
	door_tried = null
	ladder_tried_at = 0

/datum/ai_holder/rsnpc/proc/end_walk(why)
	walk_outcome_why = why
	if(!why)
		NPC_TRACE(src, NPC_TRACE_WALK, "arrived at [destination]")
	else
		NPC_TRACE(src, NPC_TRACE_WALK, "can't get to [destination]: [why]")
	stop_walk()

/datum/ai_holder/rsnpc/proc/walk_aim()
	if(isarea(destination) || isturf(destination))
		return destination
	if(destination in look())
		destination_turf = get_turf(destination)
	return destination_turf

/datum/ai_holder/rsnpc/proc/next_link()
	return length(route) ? route[1] : null

/datum/ai_holder/rsnpc/proc/walk_tick()
	if(!escaping && !threat && busy_talking())
		return
	if(escaping)
		follow_path()
		if(!length(path))
			escaping = FALSE
			route = null
		return
	if(isturf(holder.loc) && (!destination || button_wait_until || world.time < walk_wait))
		if(!destination && length(path))
			follow_path()
			return
	if(!destination || world.time < walk_wait || !isturf(holder.loc))
		return
	var/atom/aim = walk_aim()
	if(!aim)
		end_walk("I don't know where it is")
		return
	if(aim == destination ? npc_arrived(holder, destination) : (destination in in_sight) && npc_arrived(holder, destination))
		end_walk()
		return
	if(aim != destination && !(destination in in_sight) && aim.z == holder.z && get_dist(holder, aim) <= 1)
		walk_lost_target = TRUE
		end_walk("it's not there any more")
		return
	var/turf/here = get_turf(holder)
	if(here != still_at || button_wait_until)
		still_at = here
		still_since = world.time
	else if(world.time > still_since + 1 MINUTE)
		still_since = world.time
		end_walk("I'm stuck at [get_area(here)]")
		return
	var/obj/machinery/door/between = npc_door_between(holder.loc, get_turf(aim))
	if(between && !(isturf(destination) && npc_can_stand(destination)))
		open_door(between)
		return
	if(!GLOB.npc_rooms.ready)
		return
	if(length(path))
		follow_path()
		return
	if(path_search)
		search_tick()
		return
	if(button_wait_until)
		press_tick()
		return
	next_hop()

/datum/ai_holder/rsnpc/proc/next_hop()
	var/datum/npc_room/here = npc_room_of(holder)
	var/list/target_rooms = npc_rooms_of(walk_aim())
	if(!here || !length(target_rooms))
		end_walk("it is not on the station map")
		return
	if(here in target_rooms)
		route = null
		if(isarea(destination))
			start_search(null, here, null)
			return
		var/list/targets = final_targets()
		if(!length(targets))
			end_walk("nowhere to stand next to it")
			return
		start_search(targets, null, get_turf(walk_aim()))
		return
	var/datum/npc_link/L = next_link()
	if(!L || L.from != here)
		route = GLOB.npc_rooms.route(here, target_rooms, get_turf(holder), holder.GetAccess(), FALSE, src)
		if(!route)
			if(GLOB.npc_rooms.can_reach(here, target_rooms, holder.GetAccess()))
				end_walk("the way is shut for now")
			else
				var/list/way = GLOB.npc_rooms.route(here, target_rooms, null, null, TRUE)
				end_walk(!way ? "nobody can get there" : (npc_route_shuttered(way) ? "the fire shutters are down" : "I don't have access"))
			return
		L = route[1]
	switch(L.kind)
		if(NPC_LINK_DOOR, NPC_LINK_OPEN)
			var/obj/machinery/C = button_needed(L)
			if(!C)
				start_search(null, L.into, L.tiles[1])
			else if(!air_past_safe(L))
				walk_needs_suit = TRUE
				end_walk("there's no air past the airlock")
			else if(C.Adjacent(holder))
				press_button(C, L)
				button_wait_until = world.time + 60 SECONDS
			else
				start_search(npc_tiles_by(C, here), null, get_turf(C))
		if(NPC_LINK_STAIRS)
			var/turf/T = L.tiles[1]
			if(get_turf(holder) == T)
				for(var/dir in GLOB.cardinal)
					var/turf/N = get_step(T, dir)
					if(N?.npc_room == here && npc_can_step(T, N, holder.GetAccess(), holder))
						path = list(N, T)
						return
			var/list/targets = list()
			targets[T] = TRUE
			start_search(targets, null, T)
		if(NPC_LINK_LADDER)
			var/turf/T = L.tiles[1]
			if(get_turf(holder) == T)
				climb(L)
				return
			ladder_tried_at = 0
			var/list/targets = list()
			targets[T] = TRUE
			start_search(targets, null, T)
		if(NPC_LINK_PORTAL)
			var/turf/T = L.tiles[1]
			if(get_dist(holder, T) == 1 && npc_room_of(holder) == here)
				enter_portal(L)
				return
			ladder_tried_at = 0
			var/list/targets = list()
			for(var/dir in GLOB.cardinal)
				var/turf/N = get_step(T, dir)
				if(N?.npc_room == here)
					targets[N] = TRUE
			start_search(targets, null, T)

/datum/ai_holder/rsnpc/proc/final_targets()
	var/turf/T = get_turf(walk_aim())
	var/atom/near = (destination in in_sight) ? destination : T
	. = list()
	if(isturf(destination) && npc_can_stand(T))
		.[T] = TRUE
		return
	var/list/access = holder.GetAccess()
	for(var/turf/N in range(1, T))
		if(!npc_can_stand(N))
			continue
		var/obj/machinery/door/D = npc_door_between(N, T)
		if(near.Adjacent(N) || D && npc_door_passable(D, access))
			.[N] = TRUE

/proc/npc_step_back(turf/here, turf/next, mob/living/who)
	for(var/dir in GLOB.cardinal)
		var/turf/N = get_step(here, dir)
		if(N && N != next && N.npc_room && N.npc_room != next.npc_room && !(locate(/mob/living) in N) && npc_can_step(here, N, who.GetAccess(), who))
			return N
	return null

/proc/npc_door_between(turf/A, turf/B)
	if(!A || !B || get_dist(A, B) != 1 || A.z != B.z)
		return null
	var/dir = get_dir(A, B)
	if(dir & (dir - 1))
		return null
	for(var/obj/machinery/door/D in A)
		if(D.density && (D.flags & ON_BORDER) && D.dir == dir)
			return D
	for(var/obj/machinery/door/D in B)
		if(D.density && (D.flags & ON_BORDER) && D.dir == GLOB.reverse_dir[dir])
			return D
	return null

/proc/npc_tiles_by(atom/A, datum/npc_room/R)
	. = list()
	for(var/turf/T in range(1, get_turf(A)))
		if(T.npc_room == R && npc_can_stand(T) && A.Adjacent(T))
			.[T] = TRUE

/datum/ai_holder/rsnpc/proc/button_needed(datum/npc_link/L)
	var/list/access = holder.GetAccess()
	for(var/turf/T as anything in L.tiles)
		for(var/obj/machinery/door/D in T)
			if(!npc_door_passable(D, access))
				return L.button_for(D, access)
	return null

/datum/ai_holder/rsnpc/proc/air_past_safe(datum/npc_link/L)
	if(suited())
		return TRUE
	for(var/turf/T as anything in L.tiles)
		for(var/dir in GLOB.cardinal)
			var/turf/N = get_step(T, dir)
			if(N?.npc_room == L.into && !npc_air_known_safe(N, holder))
				return FALSE
	return TRUE

/datum/ai_holder/rsnpc/proc/start_search(list/targets, datum/npc_room/target_room, turf/aim)
	var/list/rooms = list()
	var/turf/start = get_turf(holder)
	var/list/sides = list(npc_room_of(holder), target_room)
	if(!start.npc_room)
		for(var/dir in GLOB.cardinal)
			var/turf/N = get_step(start, dir)
			if(N?.npc_room)
				sides |= N.npc_room
	for(var/datum/npc_room/R as anything in sides)
		if(!R)
			continue
		rooms[R] = TRUE
		for(var/datum/npc_room/same as anything in GLOB.npc_rooms.area_rooms[R.area])
			rooms[same] = TRUE
	path_search = new(holder, start, targets, target_room, aim, holder.GetAccess(), obstacles, rooms)
	obstacles = list()
	search_tick()

/datum/ai_holder/rsnpc/proc/search_tick()
	switch(path_search.advance(400))
		if(NPC_PATH_FOUND)
			path = path_search.tiles
			path_search = null
			if(!length(path))
				var/datum/npc_link/L = next_link()
				if(++failed_steps > 3)
					if(L)
						failed_steps = 0
						close_link("I can't get through")
					else
						end_walk("I can't reach it from here")
					return
				path_done()
				if(next_link() != L)
					failed_steps = 0
				return
			failed_steps = 0
		if(NPC_PATH_NO_WAY)
			var/datum/npc_path/old = path_search
			path_search = null
			if(old.rooms)
				path_search = new(holder, old.start, old.targets, old.target_room, old.aim, old.access, old.skip, null)
				return
			if(next_link())
				close_link("no way through")
			else
				end_walk("I can't reach it from inside the room")
		if(NPC_PATH_NOT_YET)
			if(path_search.airless)
				walk_needs_suit = TRUE
			if(path_search.danger && !path_search.skipped && next_link())
				path_search = null
				close_link("danger in the way")
				return
			var/why = path_search.skipped ? "someone in the way" : (path_search.danger ? "danger in the way" : "too far to work out")
			path_search = null
			walk_wait = world.time + 5 SECONDS
			if(why != walk_outcome_why)
				walk_outcome_why = why
				NPC_TRACE(src, NPC_TRACE_WALK, "not yet: [why]")

/datum/ai_holder/rsnpc/proc/close_link(why)
	var/datum/npc_link/L = next_link()
	note("closed:\ref[L]", "[L.from.area] to [L.into.area]: [why]", 2 MINUTES)
	NPC_TRACE(src, NPC_TRACE_WALK, "way from [L.from.area] to [L.into.area] closed for 2 minutes: [why]")
	route = null
	button_wait_until = 0

/datum/ai_holder/rsnpc/proc/link_crossed()
	if(length(route))
		route.Cut(1, 2)

/datum/ai_holder/rsnpc/proc/path_done()
	path = list()
	var/datum/npc_link/L = next_link()
	if(!L)
		return
	switch(L.kind)
		if(NPC_LINK_DOOR, NPC_LINK_OPEN)
			if(npc_room_of(holder) == L.into)
				link_crossed()
		if(NPC_LINK_STAIRS, NPC_LINK_PORTAL)
			if(get_turf(holder) == L.far || npc_room_of(holder) == L.into)
				link_crossed()

/datum/ai_holder/rsnpc/proc/follow_path()
	var/turf/here = get_turf(holder)
	if(!length(path))
		path_done()
		return
	var/turf/next = path[1]
	if(here == next)
		path.Cut(1, 2)
		return
	if(!isturf(holder.loc) || here.z != next.z || get_dist(here, next) != 1)
		path = list()
		return
	if(!npc_can_move(holder) || !holder.checkMoveCooldown())
		return
	var/mob/living/danger_for = (escaping || npc_step_danger(here, holder)) ? null : holder
	if(!npc_can_step(here, next, holder.GetAccess(), danger_for))
		path = list()
		return
	if(open_by_hand(here, next))
		return
	for(var/mob/living/M in next)
		var/walking = world.time < M.l_move_time + 1 SECOND
		if(walking ? M.dir != get_dir(next, here) : !here.npc_room && npc_cycling_airlock_at(here))
			if(!blocked_since)
				blocked_since = world.time
			else if(world.time - blocked_since > 2 SECONDS)
				blocked_since = 0
				obstacles = list()
				obstacles[next] = TRUE
				path = list()
				var/turf/back = !here.npc_room && npc_cycling_airlock_at(here) && npc_step_back(here, next, holder)
				if(back)
					holder.IMove(back, FALSE)
					walk_wait = world.time + 10 SECONDS
					NPC_TRACE(src, NPC_TRACE_WALK, "[M] is in the way; stepping out of the airlock door so it can cycle")
			return
	var/turf/simulated/S = next
	holder.m_intent = (istype(S) && S.wet) ? "walk" : "run"
	holder.IMove(next, FALSE)
	var/turf/now = get_turf(holder)
	if(now == next)
		path.Cut(1, 2)
		blocked_since = 0
		door_tried = null
		failed_steps = 0
		if(!length(path))
			path_done()
		return
	if(now != here)
		path = list()
		var/datum/npc_link/L = next_link()
		if((L?.kind == NPC_LINK_STAIRS || L?.kind == NPC_LINK_PORTAL) && now == L.far)
			link_crossed()
		return
	if(locate(/mob/living) in next)
		if(!blocked_since)
			blocked_since = world.time
		else if(world.time - blocked_since > 2 SECONDS)
			blocked_since = 0
			obstacles = list()
			obstacles[next] = TRUE
			path = list()
		return
	var/obj/machinery/door/airlock/AL = locate() in next
	if(AL?.density && !AL.operating)
		if(door_tried != AL)
			door_tried = AL
			door_tried_at = world.time
			NPC_TRACE(src, NPC_TRACE_WALK, "walking into [AL] to open it")
		else if(world.time > door_tried_at + 2 SECONDS)
			door_tried = null
			end_walk("[AL] won't open")
		return
	if(++failed_steps > 12)
		failed_steps = 0
		path = list()

/datum/ai_holder/rsnpc/proc/open_by_hand(turf/here, turf/next)
	var/dir = get_dir(here, next)
	for(var/obj/machinery/door/D in here)
		if(D.density && (D.flags & ON_BORDER) && D.dir == dir)
			return open_door(D)
	for(var/obj/machinery/door/D in next)
		if(!D.density)
			continue
		if((D.flags & ON_BORDER) && D.dir != GLOB.reverse_dir[dir])
			continue
		if(istype(D, /obj/machinery/door/window) || istype(D, /obj/machinery/door/firedoor))
			return open_door(D)
	return FALSE

/datum/ai_holder/rsnpc/proc/open_door(obj/machinery/door/D)
	if(!can_act() || holder.restrained() || !holder.can_use_hands())
		return FALSE
	if(D.operating)
		return TRUE
	if(door_tried == D && world.time > door_tried_at + 2 SECONDS)
		door_tried = null
		end_walk("[D] won't open")
		return TRUE
	if(door_tried != D)
		door_tried = D
		door_tried_at = world.time
		NPC_TRACE(src, NPC_TRACE_WALK, "opening [D]")
	if(istype(D, /obj/machinery/door/firedoor))
		var/obj/machinery/door/firedoor/F = D
		F.toggle_for(holder)
	else
		use_hand(D)
	walk_wait = world.time + 1 SECOND
	return TRUE

/datum/ai_holder/rsnpc/proc/use_hand(atom/A)
	if(!can_act() || holder.restrained() || !holder.can_use_hands() || !A.Adjacent(holder) || !holder.checkClickCooldown())
		return FALSE
	var/old_usr = usr
	usr = holder
	A.attack_hand(holder)
	usr = old_usr
	holder.setClickCooldown(DEFAULT_QUICK_COOLDOWN)
	return TRUE

/datum/ai_holder/rsnpc/proc/press_tick()
	var/datum/npc_link/L = next_link()
	if(!L || !button_needed(L))
		button_wait_until = 0
		if(L)
			start_search(null, L.into, L.tiles[1])
		return
	if(world.time > button_wait_until)
		close_link("the airlock didn't cycle after a minute of pressing [button_needed(L)]")
		return
	var/obj/machinery/C = button_needed(L)
	if(!C.Adjacent(holder))
		button_wait_until = 0
		return
	if(world.time > button_pressed_at + 15 SECONDS)
		press_button(C, L)

/datum/ai_holder/rsnpc/proc/press_button(obj/machinery/C, datum/npc_link/L)
	var/obj/machinery/embedded_controller/radio/airlock/E = C
	if(istype(E))
		var/datum/embedded_program/airlock/P = E.program
		var/inside = FALSE
		for(var/turf/T as anything in L.tiles)
			for(var/obj/machinery/door/airlock/A in T)
				if(A.id_tag && A.id_tag == P?.tag_interior_door)
					inside = TRUE
		var/action = inside ? "cycle_int" : "cycle_ext"
		if(!(action in E.valid_actions))
			action = "[action]_door"
		if(!press(E, action))
			return
	else if(!use_hand(C))
		return
	button_pressed_at = world.time
	NPC_TRACE(src, NPC_TRACE_WALK, "pressed [C] to cycle into [L.into.area]")

/datum/ai_holder/rsnpc/proc/climb(datum/npc_link/L)
	if(!holder.may_climb_ladders(L.ladder))
		close_link("I can't climb ladders")
		return
	if(ladder_tried_at)
		ladder_tried_at = 0
		close_link("I couldn't climb [L.ladder]")
		return
	ladder_tried_at = world.time
	NPC_TRACE(src, NPC_TRACE_WALK, "climbing [L.ladder]")
	walk_wait = world.time + 3 SECONDS
	INVOKE_ASYNC(L.ladder, TYPE_PROC_REF(/obj/structure/ladder, climbLadder), holder, L.other)

/datum/ai_holder/rsnpc/proc/enter_portal(datum/npc_link/L)
	if(!holder.checkMoveCooldown())
		return
	if(ladder_tried_at)
		ladder_tried_at = 0
		close_link("I couldn't get through [L.portal]")
		return
	ladder_tried_at = world.time
	NPC_TRACE(src, NPC_TRACE_WALK, "going through [L.portal] to [L.into.area]")
	walk_wait = world.time + 2 SECONDS
	holder.IMove(L.tiles[1], FALSE)
