/datum/ai_holder/rsnpc/proc/note(key, value, time)
	notes[key] = list(value, world.time + time)

/datum/ai_holder/rsnpc/proc/noted(key)
	var/list/entry = notes[key]
	if(!entry)
		return null
	if(world.time > entry[2])
		notes -= key
		return null
	return entry[1]

/datum/ai_holder/rsnpc/proc/cross_off(key, time, why)
	if(noted("off:[key]"))
		return
	note("off:[key]", why, time)
	NPC_TRACE(src, NPC_TRACE_KNOW, "crossed off [key] for [time / 10]s: [why]")

/datum/ai_holder/rsnpc/proc/crossed_off(key)
	return noted("off:[key]")

/datum/ai_holder/rsnpc/proc/clean_notes()
	if(world.time < notes_cleaned + 1 MINUTE)
		return
	notes_cleaned = world.time
	var/list/old = list()
	for(var/key in notes)
		var/list/entry = notes[key]
		if(world.time > entry[2])
			old += key
	notes -= old

/proc/npc_place_key(turf/T)
	return "[T.x],[T.y],[T.z]"

/proc/npc_thing_key(kind, turf/T)
	return "[kind]@[T.x],[T.y],[T.z]"
