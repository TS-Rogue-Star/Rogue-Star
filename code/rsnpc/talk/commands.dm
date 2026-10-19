GLOBAL_LIST_INIT(npc_commands, npc_make_commands())

/proc/npc_make_commands()
	. = list()
	for(var/command_type in subtypesof(/datum/npc_command))
		var/datum/npc_command/C = command_type
		if(initial(C.say))
			. += new command_type

/datum/npc_command
	var/say
	var/clean_say
	var/radio = FALSE
	var/repeat = 10 SECONDS
	var/friendly = FALSE
	var/obedience
	var/list/trusted = list()

/datum/npc_command/New()
	..()
	clean_say = npc_clean_line(say)

/datum/npc_command/proc/heard(datum/ai_holder/rsnpc/ai_mind, mob/living/speaker, rest, via)
	if(via && !radio)
		NPC_TRACE(ai_mind, NPC_TRACE_TALK, "ignored \"[say]\" from [speaker]; heard over radio, and command can't be made over radio")
		return
	if(!applies(ai_mind))
		NPC_TRACE(ai_mind, NPC_TRACE_TALK, "ignored \"[say]\" from [speaker]; nothing to do")
		return
	var/key = "said:[say]:\ref[speaker]"
	if(ai_mind.noted(key))
		NPC_TRACE(ai_mind, NPC_TRACE_TALK, "ignored \"[say]\" from [speaker]; repeated too soon")
		return
	ai_mind.note(key, speaker.name, repeat)
	if(friendly && !ai_mind.friendly_to(speaker))
		NPC_TRACE(ai_mind, NPC_TRACE_TALK, "brushed off \"[say]\" from [speaker]; don't like them")
		ai_mind.say_line("say_brush_off", list("name" = speaker.name), via)
		return
	if(!isnull(obedience) && !ai_mind.will_obey(speaker, src, via))
		return
	NPC_TRACE(ai_mind, NPC_TRACE_TALK, "heard \"[say]\" from [speaker][via ? " over radio" : ""]")
	run_command(ai_mind, speaker, rest, via)

/datum/npc_command/proc/applies(datum/ai_holder/rsnpc/ai_mind)
	return TRUE

/datum/npc_command/proc/run_command(datum/ai_holder/rsnpc/ai_mind, mob/living/speaker, rest, via)
	return

/datum/ai_holder/rsnpc/proc/hear_command(mob/living/speaker, line, via)
	var/rest = npc_after_name(line, holder, null, TRUE)
	if(isnull(rest))
		return FALSE
	var/datum/npc_command/best
	for(var/datum/npc_command/C as anything in GLOB.npc_commands)
		if(length(C.say) > length(best?.say) && npc_starts_with_clean(rest, C.clean_say))
			best = C
	if(!best)
		NPC_TRACE(src, NPC_TRACE_TALK, "[speaker] spoke in command format, but I don't understand \"[rest]\"")
		return FALSE
	best.heard(src, speaker, npc_words_after_clean(rest, best.clean_say), via)
	return TRUE

/datum/ai_holder/rsnpc/proc/will_obey(mob/living/M, datum/npc_command/C, via)
	var/group = "refuse_threat"
	var/why = "they're dangerous"
	if(danger_of(M) < NPC_DANGEROUS)
		var/total = obedience_total(M, C)
		if(total >= C.obedience)
			return TRUE
		group = opinion_of(M) <= npc_psetting("opinion_disliked_at") ? "refuse_dislike" : "refuse_esteem"
		why = "obedience [total] of [C.obedience]"
	NPC_TRACE(src, NPC_TRACE_TALK, "refused \"[C.say]\" from [M]; [why]")
	say_line(group, list("name" = M.name), via)
	return FALSE

/datum/ai_holder/rsnpc/proc/obedience_total(mob/living/M, datum/npc_command/C)
	. = round(npc_psetting("obedience_base") + opinion_of(M) * npc_psetting("obedience_opinion_weight") + rank_bonus(M))
	if(npc_manifest_job(M) in C.trusted)
		. += npc_psetting("obedience_trusted_job")

/datum/ai_holder/rsnpc/proc/rank_bonus(mob/living/M)
	var/title = npc_manifest_job(M)
	var/datum/job/their_job = title ? SSjob.get_job(title) : null
	if(!their_job || !length(their_job.departments_managed))
		return 0
	var/my_title = npc_job_of(holder)
	var/datum/job/my_job = my_title ? SSjob.get_job(my_title) : null
	if(my_job && length(my_job.departments & their_job.departments_managed))
		return npc_psetting("obedience_department_head")
	return npc_psetting("obedience_other_head")
