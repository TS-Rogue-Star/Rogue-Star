/datum/ai_holder/complex_npc/proc/way_out()
	var/datum/npc_room/here = npc_room_of(holder)
	if(!here)
		return null
	var/list/access = holder.GetAccess()
	for(var/datum/npc_link/L as anything in here.links)
		if(!noted("closed:\ref[L]") && L.navigable_by(access))
			return L
	return null

/datum/ai_holder/complex_npc/proc/check_shut_in()
	var/datum/npc_room/here = npc_room_of(holder)
	if(shut_in_room)
		if(here != shut_in_room)
			NPC_TRACE(src, NPC_TRACE_TASK, "got out of [shut_in_room.area]")
			shut_in_room = null
			shut_in_checks = 0
			return
		if(way_out())
			if(!noted("let_out"))
				note("let_out", "[here.area]", 30 SECONDS)
				say_line("narrate_let_out", list("place" = "[here.area]"))
			return
		if(!noted("asked_out"))
			note("asked_out", "[here.area]", 3 MINUTES)
			say_line("request_passage", list("place" = "[here.area]", "thing" = npc_door_name(here)), PUB_FREQ)
		return
	if(world.time < shut_in_checked_at + 30 SECONDS)
		return
	shut_in_checked_at = world.time
	if(!here || !length(here.links) || way_out())
		shut_in_checks = 0
		return
	if(++shut_in_checks < 2)
		return
	shut_in_room = here
	NPC_TRACE(src, NPC_TRACE_TASK, "shut in [here.area]; no way out")

/proc/npc_door_name(datum/npc_room/R)
	for(var/datum/npc_link/L as anything in R.links)
		for(var/turf/T as anything in L.tiles)
			var/obj/machinery/door/D = locate() in T
			if(D)
				return D.name
	return "door"

/datum/npc_task/get_out
	name = "leave the room"
	tier = NPC_TIER_NEEDS

/datum/npc_task/get_out/can_start(datum/ai_holder/complex_npc/ai_mind)
	return ai_mind.shut_in_room && ai_mind.way_out()

/datum/npc_task/get_out/value(datum/ai_holder/complex_npc/ai_mind)
	return 100

/datum/npc_task/get_out/goal(datum/ai_holder/complex_npc/ai_mind)
	var/datum/npc_link/L = ai_mind.way_out()
	return L ? list(NPC_FACT_IN(L.into.area)) : list()
