/proc/npc_radius_find(turf/start, steps, list/access, datum/callback/found)
	var/list/queue = list(start)
	var/list/from = list()
	var/list/depth = list()
	from[start] = start
	depth[start] = 0
	var/i = 0
	while(i < length(queue))
		var/turf/T = queue[++i]
		if(T != start && found.Invoke(T))
			var/list/tiles = list()
			while(T != start)
				tiles.Insert(1, T)
				T = from[T]
			return tiles
		if(depth[T] >= steps)
			continue
		for(var/dir in GLOB.cardinal)
			var/turf/N = get_step(T, dir)
			if(!N || from[N] || npc_stairs_other_end(N) || !npc_can_step(T, N, access))
				continue
			from[N] = T
			depth[N] = depth[T] + 1
			queue += N
	return null

/proc/npc_safe_tile(mob/living/who, turf/T)
	return !npc_step_danger(T, who)

/datum/ai_holder/rsnpc/proc/reflex_in_control()
	var/obj/belly/B = holder.loc
	if(istype(B))
		return "inside [B.owner]"
	if(world.time < panic_until)
		return "panicking"
	if(threat)
		return "[threat_mode == NPC_FIGHT ? "fighting" : "fleeing"] [threat.resolve()]"
	if(escaping)
		return "danger reflex"
	if(holder.on_fire)
		return "putting out fire"
	if(istype(holder.loc, /obj/structure/closet))
		return "climbing out of [holder.loc]"
	return null

/datum/ai_holder/rsnpc/proc/fire_tick()
	if(!holder.on_fire || escaping || npc_fixed_danger(get_turf(holder)))
		return FALSE
	if(world.time > self_extinguished_at + 4 SECONDS)
		self_extinguished_at = world.time
		clear_task()
		NPC_TRACE(src, NPC_TRACE_WALK, "on fire; putting myself out")
		INVOKE_ASYNC(src, PROC_REF(start_resist))
	return TRUE

/datum/ai_holder/rsnpc/proc/locker_tick()
	if(!istype(holder.loc, /obj/structure/closet))
		return FALSE
	var/obj/structure/closet/secure_closet/S = holder.loc
	if(world.time > locker_escape_tried_at + (istype(S) && S.locked ? 2.5 MINUTES : 5 SECONDS))
		locker_escape_tried_at = world.time
		clear_task()
		NPC_TRACE(src, NPC_TRACE_WALK, "stuck in [holder.loc]; trying to get out")
		INVOKE_ASYNC(src, PROC_REF(start_resist))
	return TRUE

/datum/ai_holder/rsnpc/proc/start_resist()
	holder.resist()

/datum/ai_holder/rsnpc/proc/reflex()
	if(escaping || !isturf(holder.loc) || world.time < escape_retry)
		return FALSE
	var/turf/T = get_turf(holder)
	if(!npc_step_danger(T, holder))
		return FALSE
	var/list/way = npc_radius_find(T, 30, holder.GetAccess(), CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(npc_safe_tile), holder))
	if(!way)
		escape_retry = world.time + 5 SECONDS
		NPC_TRACE(src, NPC_TRACE_WALK, "endangered in [get_area(T)], no safe loc within 30 steps")
		return FALSE
	clear_task()
	escaping = TRUE
	path = way
	path_search = null
	route = null
	NPC_TRACE(src, NPC_TRACE_WALK, "endangered in [get_area(T)], going a safe loc [length(way)] steps away")
	return TRUE
