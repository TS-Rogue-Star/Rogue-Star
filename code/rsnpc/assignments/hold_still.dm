/datum/npc_command/hold_still
	say = "hold still"
	obedience = 15
	trusted = list("Medical Doctor", "Chief Medical Officer", "Paramedic", "Security Officer", "Warden", "Head of Security")

/datum/npc_command/hold_still/applies(datum/ai_holder/complex_npc/ai_mind)
	return !ai_mind.assignment(/datum/npc_assignment/hold_still)

/datum/npc_command/hold_still/run_command(datum/ai_holder/complex_npc/ai_mind, mob/living/speaker, rest, via)
	ai_mind.start_assignment(new /datum/npc_assignment/hold_still(speaker, null, ai_mind.npc_psetting("hold_still_minutes") MINUTES), "hold_still_agreed")

/datum/npc_command/stop_holding_still
	say = "stop holding still"

/datum/npc_command/stop_holding_still/applies(datum/ai_holder/complex_npc/ai_mind)
	return !!ai_mind.assignment(/datum/npc_assignment/hold_still)

/datum/npc_command/stop_holding_still/run_command(datum/ai_holder/complex_npc/ai_mind, mob/living/speaker, rest, via)
	ai_mind.end_assignment(ai_mind.assignment(/datum/npc_assignment/hold_still), "[speaker] released me from holding still", "hold_still_released", speaker)

/datum/npc_assignment/hold_still
	name = "hold still"
	uses_legs = TRUE
	time_up_line = "hold_still_done"

/datum/npc_assignment/hold_still/check(datum/ai_holder/complex_npc/ai_mind)
	if(ai_mind.holder.stat != CONSCIOUS)
		ai_mind.end_assignment(src, "knocked out")
		return
	if(!isturf(ai_mind.holder.loc))
		ai_mind.end_assignment(src, "got eaten")
		return
	if(ai_mind.threat || ai_mind.escaping || world.time < ai_mind.panic_until || ai_mind.task?.tier > NPC_TIER_SOCIAL)
		ai_mind.end_assignment(src, "had to move", "hold_still_broken")
		return
	..()

/datum/npc_task/hold_still
	name = "hold still"
	tier = NPC_TIER_SOCIAL
	assignment_type = /datum/npc_assignment/hold_still

/datum/npc_task/hold_still/value(datum/ai_holder/complex_npc/ai_mind)
	return 100

/datum/ai_holder/complex_npc/proc/holds_still_for(key)
	var/datum/npc_assignment/hold_still/A = assignment(/datum/npc_assignment/hold_still)
	return A && A.asker_key == key

/datum/ai_holder/complex_npc/proc/hear_hold_still(mob/living/speaker, line, via)
	if(via)
		return
	for(var/mob/living/M in look())
		if(M == speaker || !npc_is_person(M))
			continue
		var/rest = npc_after_name(line, M)
		if(isnull(rest))
			continue
		var/key = "told_hold_still:[npc_person_key(M)]:[npc_person_key(speaker)]"
		if(npc_starts_with(rest, "stop holding still"))
			notes -= key
		else if(npc_starts_with(rest, "hold still"))
			note(key, speaker.name, npc_psetting("hold_still_minutes") MINUTES)
		return
