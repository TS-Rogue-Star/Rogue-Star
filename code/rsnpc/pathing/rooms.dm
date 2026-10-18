GLOBAL_DATUM_INIT(npc_rooms, /datum/npc_room_map, new)
GLOBAL_LIST(npc_levels)

/proc/npc_levels()
	if(GLOB.npc_levels)
		return GLOB.npc_levels
	var/list/levels = using_map.station_levels.Copy()
	var/list/joins = list()
	for(var/obj/effect/map_effect/portal/P in world)
		var/turf/from = get_turf(P)
		var/turf/into = P.counterpart?.get_focused_turf()
		if(from && into && from.z != into.z)
			joins += list(list(from.z, into.z))
	var/grew = TRUE
	while(grew)
		grew = FALSE
		for(var/list/join in joins)
			if((join[1] in levels) && !(join[2] in levels))
				levels += join[2]
				grew = TRUE
	GLOB.npc_levels = levels
	return levels

/hook/roundstart/proc/build_npc_rooms()
	spawn(0)
		GLOB.npc_rooms.build()
	return TRUE


/turf/var/tmp/datum/npc_room/npc_room

/datum/npc_room
	var/area/area
	var/z
	var/size = 0
	var/turf/middle
	var/list/links = list()

/datum/npc_link
	var/datum/npc_room/from
	var/datum/npc_room/into
	var/kind = NPC_LINK_DOOR
	var/list/tiles
	var/turf/far
	var/list/buttons
	var/obj/structure/ladder/ladder
	var/obj/structure/ladder/other
	var/obj/effect/map_effect/portal/portal

/datum/npc_link/proc/navigable_by(list/access, anyone = FALSE)
	if(!anyone && (kind == NPC_LINK_OPEN || kind == NPC_LINK_DOOR))
		for(var/turf/T as anything in tiles)
			if(npc_tape_blocks(T, access))
				return FALSE
	switch(kind)
		if(NPC_LINK_OPEN)
			return TRUE
		if(NPC_LINK_STAIRS)
			return !!npc_stairs_other_end(tiles[1])
		if(NPC_LINK_LADDER)
			return !QDELETED(ladder) && !QDELETED(other)
		if(NPC_LINK_PORTAL)
			return !QDELETED(portal) && portal.counterpart
	for(var/turf/T as anything in tiles)
		for(var/obj/machinery/door/D in T)
			if(npc_door_passable(D, access, anyone) || button_for(D, access, anyone))
				continue
			return FALSE
	return TRUE

/datum/npc_link/proc/button_for(obj/machinery/door/D, list/access, anyone = FALSE)
	if(istype(D, /obj/machinery/door/airlock))
		var/obj/machinery/door/airlock/A = D
		if(A.welded || !A.arePowerSystemsOn())
			return null
	for(var/obj/machinery/C as anything in buttons)
		if(QDELETED(C) || (C.stat & (BROKEN|NOPOWER)))
			continue
		if(!(D in GLOB.npc_rooms.button_doors[C]))
			continue
		if(anyone || C.check_access_list(access))
			return C
	return null

/datum/npc_room_map
	var/list/rooms = list()
	var/list/area_rooms = list()
	var/list/button_doors = list()
	var/list/button_rooms = list()
	var/list/cycling_doors = list()
	var/ready = FALSE
	var/building = FALSE
	var/dirty = FALSE
	var/last_build = 0
	var/changes = 0

/datum/npc_room_map/proc/build()
	if(building)
		dirty = TRUE
		return
	building = TRUE
	ready = FALSE
	dirty = FALSE
	last_build = world.time
	for(var/z in npc_levels())
		for(var/turf/T as anything in block(locate(1, 1, z), locate(world.maxx, world.maxy, z)))
			if(T.npc_room)
				T.npc_room = null
			CHECK_TICK
	for(var/datum/npc_room/R as anything in rooms)
		R.links.Cut()
	rooms = list()
	area_rooms = list()
	for(var/z in npc_levels())
		for(var/turf/T as anything in block(locate(1, 1, z), locate(world.maxx, world.maxy, z)))
			if(!T.npc_room && npc_room_tile(T))
				var/datum/npc_room/R = fill_room(T)
				rooms += R
				if(!area_rooms[R.area])
					area_rooms[R.area] = list()
				area_rooms[R.area] += R
			CHECK_TICK
	find_buttons()
	for(var/z in npc_levels())
		link_doors(z)
		link_touching(z)
	link_stairs()
	link_ladders()
	link_portals()
	changes++
	building = FALSE
	ready = TRUE
	log_world("NPC ROOMS: [length(rooms)] rooms on [length(npc_levels())] decks in [(world.time - last_build) / 10]s.")
	if(dirty)
		dirty = FALSE
		changed()

/datum/npc_room_map/proc/changed()
	if(dirty)
		return
	dirty = TRUE
	if(building)
		return
	addtimer(CALLBACK(src, PROC_REF(rebuild)), max(0, last_build + 10 SECONDS - world.time))

/datum/npc_room_map/proc/rebuild()
	dirty = FALSE
	spawn(0)
		build()

/datum/npc_room_map/proc/fill_room(turf/T)
	var/datum/npc_room/R = new
	R.area = T.loc
	R.z = T.z
	T.npc_room = R
	var/list/queue = list(T)
	var/sum_x = 0
	var/sum_y = 0
	var/i = 0
	while(i < length(queue))
		var/turf/Q = queue[++i]
		sum_x += Q.x
		sum_y += Q.y
		for(var/dir in GLOB.cardinal)
			var/turf/N = get_step(Q, dir)
			if(N && !N.npc_room && N.loc == R.area && npc_room_tile(N))
				N.npc_room = R
				queue += N
	R.size = length(queue)
	var/mid_x = sum_x / R.size
	var/mid_y = sum_y / R.size
	var/best
	for(var/turf/Q as anything in queue)
		var/d = abs(Q.x - mid_x) + abs(Q.y - mid_y)
		if(isnull(best) || d < best)
			best = d
			R.middle = Q
	return R

/datum/npc_room_map/proc/find_buttons()
	button_doors = list()
	button_rooms = list()
	cycling_doors = list()
	var/list/doors = list()
	var/list/controls = list()
	var/list/commands = list()
	for(var/obj/machinery/M in global.machines)
		var/tag
		if(istype(M, /obj/machinery/door/airlock))
			var/obj/machinery/door/airlock/A = M
			if(A.id_tag)
				LAZYADD(doors[A.id_tag], A)
			continue
		if(istype(M, /obj/machinery/access_button))
			var/obj/machinery/access_button/B = M
			tag = B.master_tag
			commands[M] = B.command
		else if(istype(M, /obj/machinery/airlock_sensor))
			var/obj/machinery/airlock_sensor/S = M
			tag = S.master_tag
			commands[M] = S.command
		if(tag)
			LAZYADD(controls[tag], M)
		CHECK_TICK
	for(var/obj/machinery/embedded_controller/radio/airlock/C in global.machines)
		var/datum/embedded_program/airlock/P = C.program
		if(!istype(P) || !C.id_tag)
			continue
		var/list/inner = doors[P.tag_interior_door] || list()
		var/list/outer = doors[P.tag_exterior_door] || list()
		for(var/obj/machinery/door/D as anything in inner + outer)
			cycling_doors[D] = TRUE
		LAZYADD(controls[C.id_tag], C)
		for(var/obj/machinery/M as anything in controls[C.id_tag])
			switch(commands[M])
				if("cycle_interior")
					button_doors[M] = inner
				if("cycle_exterior")
					button_doors[M] = outer
				else
					button_doors[M] = inner + outer
			var/list/from = list()
			for(var/turf/T in range(1, get_turf(M)))
				if(T.npc_room)
					from |= T.npc_room
			button_rooms[M] = from
		CHECK_TICK

/datum/npc_room_map/proc/link_doors(z)
	var/list/seen = list()
	for(var/turf/T as anything in block(locate(1, 1, z), locate(world.maxx, world.maxy, z)))
		if(seen[T] || !npc_door_tile(T))
			CHECK_TICK
			continue
		var/list/tiles = list(T)
		seen[T] = TRUE
		var/i = 0
		while(i < length(tiles))
			var/turf/Q = tiles[++i]
			for(var/dir in GLOB.cardinal)
				var/turf/N = get_step(Q, dir)
				if(N && !seen[N] && npc_door_tile(N))
					seen[N] = TRUE
					tiles += N
		var/list/touch = list()
		for(var/turf/Q as anything in tiles)
			for(var/dir in GLOB.cardinal)
				var/turf/N = get_step(Q, dir)
				if(N?.npc_room)
					touch |= N.npc_room
		for(var/datum/npc_room/A as anything in touch)
			for(var/datum/npc_room/B as anything in touch)
				if(A != B)
					add_link(A, B, NPC_LINK_DOOR, tiles)
		CHECK_TICK

/datum/npc_room_map/proc/link_touching(z)
	var/list/done = list()
	for(var/turf/T as anything in block(locate(1, 1, z), locate(world.maxx, world.maxy, z)))
		var/datum/npc_room/A = T.npc_room
		if(!A)
			CHECK_TICK
			continue
		for(var/dir in list(NORTH, EAST))
			var/turf/N = get_step(T, dir)
			var/datum/npc_room/B = N?.npc_room
			if(!B || B == A)
				continue
			var/list/doors = list()
			for(var/obj/machinery/door/D in T)
				if((D.flags & ON_BORDER) && D.dir == dir)
					doors += D
			for(var/obj/machinery/door/D in N)
				if((D.flags & ON_BORDER) && D.dir == GLOB.reverse_dir[dir])
					doors += D
			if(LinkBlockedWithAccess(T, N, null, doors))
				continue
			var/kind = length(doors) ? NPC_LINK_DOOR : NPC_LINK_OPEN
			var/key = "\ref[A] \ref[B] [kind]"
			if(done[key])
				continue
			done[key] = TRUE
			add_link(A, B, kind, list(N, T))
			add_link(B, A, kind, list(T, N))
		CHECK_TICK

/datum/npc_room_map/proc/link_stairs()
	for(var/obj/structure/stairs/bottom/B in world)
		if(!(B.z in npc_levels()) || !B.top || !B.check_integrity())
			continue
		var/turf/low = get_turf(B)
		var/turf/high = get_turf(B.top)
		var/list/lows = rooms_beside(low, get_turf(B.middle))
		var/list/highs = rooms_beside(high, GetAbove(low))
		for(var/datum/npc_room/A as anything in lows)
			for(var/datum/npc_room/H as anything in highs)
				add_link(A, H, NPC_LINK_STAIRS, list(low), high)
				add_link(H, A, NPC_LINK_STAIRS, list(high), low)
		CHECK_TICK

/datum/npc_room_map/proc/link_ladders()
	for(var/obj/structure/ladder/L in world)
		if(!L.target_up || !(L.z in npc_levels()))
			continue
		var/turf/low = get_turf(L)
		var/turf/high = get_turf(L.target_up)
		if(!low.npc_room || !high.npc_room)
			continue
		var/datum/npc_link/up = add_link(low.npc_room, high.npc_room, NPC_LINK_LADDER, list(low), high)
		up.ladder = L
		up.other = L.target_up
		var/datum/npc_link/down = add_link(high.npc_room, low.npc_room, NPC_LINK_LADDER, list(high), low)
		down.ladder = L.target_up
		down.other = L
		CHECK_TICK

/datum/npc_room_map/proc/link_portals()
	var/list/done = list()
	for(var/obj/effect/map_effect/portal/P in world)
		var/turf/T = get_turf(P)
		var/turf/far = P.counterpart?.get_focused_turf()
		if(!T || !far?.npc_room || !(T.z in npc_levels()))
			continue
		for(var/datum/npc_room/A as anything in rooms_beside(T))
			var/key = "\ref[A]>\ref[far.npc_room]"
			if(done[key])
				continue
			done[key] = TRUE
			var/datum/npc_link/L = add_link(A, far.npc_room, NPC_LINK_PORTAL, list(T), far)
			L.portal = P
		CHECK_TICK

/datum/npc_room_map/proc/add_link(datum/npc_room/A, datum/npc_room/B, kind, list/tiles, turf/far)
	var/datum/npc_link/L = new
	L.from = A
	L.into = B
	L.kind = kind
	L.tiles = tiles
	L.far = far
	if(kind == NPC_LINK_DOOR)
		for(var/obj/machinery/M as anything in button_doors)
			if(!(A in button_rooms[M]))
				continue
			for(var/turf/T as anything in tiles)
				for(var/obj/machinery/door/D in T)
					if(D in button_doors[M])
						LAZYDISTINCTADD(L.buttons, M)
	A.links += L
	return L

/datum/npc_room_map/proc/rooms_beside(turf/T, turf/skip)
	. = list()
	for(var/dir in GLOB.cardinal)
		var/turf/N = get_step(T, dir)
		if(N && N != skip && N.npc_room && (npc_can_step(T, N, null) || npc_can_step(N, T, null)))
			. |= N.npc_room

/datum/npc_room_map/proc/route(datum/npc_room/from, list/target_rooms, turf/start, list/access, anyone = FALSE, datum/ai_holder/rsnpc/ai_mind)
	if(!ready || !from)
		return null
	if(from in target_rooms)
		return list()
	var/datum/npc_heap/H = new
	var/list/best = list()
	var/list/via = list()
	var/list/at = list()
	var/list/done = list()
	best[from] = 0
	at[from] = start || from.middle
	H.add(from, 0, 0)
	while(!H.is_empty())
		var/datum/npc_room/R = H.take()
		if(done[R])
			continue
		done[R] = TRUE
		if(R in target_rooms)
			var/list/links = list()
			while(R != from)
				var/datum/npc_link/L = via[R]
				links.Insert(1, L)
				R = L.from
			return links
		for(var/datum/npc_link/L as anything in R.links)
			if(done[L.into] || ai_mind?.noted("closed:\ref[L]") || !L.navigable_by(access, anyone))
				continue
			var/turf/door = L.tiles[1]
			var/turf/here = at[R]
			var/c = best[R] + abs(here.x - door.x) + abs(here.y - door.y) + 1
			if(!isnull(best[L.into]) && best[L.into] <= c)
				continue
			best[L.into] = c
			via[L.into] = L
			at[L.into] = L.far || door
			H.add(L.into, c, 0)
	return null

/datum/npc_room_map/proc/reach(datum/npc_room/from, turf/start, list/access, datum/ai_holder/rsnpc/ai_mind)
	var/list/best = list()
	var/list/at = list()
	if(!ready || !from)
		return list(best, at)
	var/datum/npc_heap/H = new
	var/list/done = list()
	best[from] = 0
	at[from] = start || from.middle
	H.add(from, 0, 0)
	while(!H.is_empty())
		var/datum/npc_room/R = H.take()
		if(done[R])
			continue
		done[R] = TRUE
		for(var/datum/npc_link/L as anything in R.links)
			if(done[L.into] || ai_mind?.noted("closed:\ref[L]") || !L.navigable_by(access))
				continue
			var/turf/door = L.tiles[1]
			var/turf/here = at[R]
			var/c = best[R] + abs(here.x - door.x) + abs(here.y - door.y) + 1
			if(!isnull(best[L.into]) && best[L.into] <= c)
				continue
			best[L.into] = c
			at[L.into] = L.far || door
			H.add(L.into, c, 0)
	return list(best, at)

/datum/npc_room_map/proc/can_reach(datum/npc_room/from, list/target_rooms, list/access)
	return !isnull(route(from, target_rooms, null, access))

/datum/npc_room_map/proc/could_reach_with(datum/npc_room/from, list/target_rooms, list/access, list/extra)
	return !isnull(route(from, target_rooms, null, (access || list()) | extra))

/proc/npc_route_shuttered(list/links)
	for(var/datum/npc_link/L as anything in links)
		for(var/turf/T as anything in L.tiles)
			for(var/obj/machinery/door/firedoor/F in T)
				if(F.density && npc_firedoor_alarmed(F))
					return TRUE
	return FALSE

/proc/npc_cycling_airlock_at(turf/T)
	for(var/obj/machinery/door/airlock/D in T)
		if(GLOB.npc_rooms.cycling_doors[D])
			return D
	return null

/proc/npc_room_tile(turf/T)
	if(T.density || isopenspace(T))
		return FALSE
	for(var/obj/O in T)
		if(istype(O, /obj/machinery/door) && !(O.flags & ON_BORDER))
			return FALSE
		if(istype(O, /obj/structure/stairs) || istype(O, /obj/effect/map_effect/portal) || npc_walls_off(O))
			return FALSE
		if(istype(O, /obj/structure/window))
			var/obj/structure/window/W = O
			if(W.is_fulltile())
				return FALSE
	return TRUE

/proc/npc_door_tile(turf/T)
	if(T.density)
		return FALSE
	. = FALSE
	for(var/obj/O in T)
		if(istype(O, /obj/structure/window))
			var/obj/structure/window/W = O
			if(W.is_fulltile())
				return FALSE
		if(O.density && !istype(O, /obj/machinery/door) && !(O.flags & ON_BORDER))
			return FALSE
		if(istype(O, /obj/machinery/door) && !(O.flags & ON_BORDER))
			. = TRUE

/proc/npc_room_of(atom/A)
	var/turf/T = get_turf(A)
	if(!T)
		return null
	if(T.npc_room)
		return T.npc_room
	var/datum/npc_room/fallback
	for(var/dir in GLOB.cardinal)
		var/turf/N = get_step(T, dir)
		if(!N?.npc_room)
			continue
		if(npc_can_step(T, N, null))
			return N.npc_room
		fallback = fallback || N.npc_room
	return fallback

/proc/npc_rooms_of(atom/A)
	if(isarea(A))
		return GLOB.npc_rooms.area_rooms[A]
	var/turf/T = get_turf(A)
	if(!T)
		return null
	if(T.npc_room)
		return list(T.npc_room)
	. = list()
	for(var/dir in GLOB.cardinal)
		var/turf/N = get_step(T, dir)
		if(N?.npc_room)
			. |= N.npc_room

/proc/npc_turf_changed(turf/T)
	var/datum/npc_room_map/M = GLOB.npc_rooms
	if(!(M.ready || M.building) || !(T.z in npc_levels()))
		return
	var/datum/npc_room/R
	for(var/dir in GLOB.cardinal)
		var/turf/N = get_step(T, dir)
		if(!N?.npc_room)
			continue
		if(N.npc_room.area != T.loc)
			M.changed()
			continue
		if(R && R != N.npc_room)
			M.changed()
			return
		R = N.npc_room
	if(R && npc_room_tile(T))
		T.npc_room = R
		return
	if(R)
		M.changed()
