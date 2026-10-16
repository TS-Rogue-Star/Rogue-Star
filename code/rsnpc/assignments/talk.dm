/datum/npc_command/hello
	say = "hello"
	repeat = 20 SECONDS
	friendly = TRUE

/datum/npc_command/hello/run_command(datum/ai_holder/rsnpc/ai_mind, mob/living/speaker, rest, via)
	var/datum/npc_assignment/talk/T = ai_mind.assignment(/datum/npc_assignment/talk)
	var/list/blanks = list("name" = speaker.name)
	if(T?.asker?.resolve() == speaker)
		NPC_TRACE(ai_mind, NPC_TRACE_TALK, "already talking with [speaker]")
		return
	if(T)
		NPC_TRACE(ai_mind, NPC_TRACE_TALK, "can't talk with [speaker]; talking with [T.asker_name]")
		blanks["other"] = T.asker_name
		ai_mind.say_line("talk_busy_talking", blanks)
		return
	if(ai_mind.danger_of(speaker) >= NPC_WARY)
		NPC_TRACE(ai_mind, NPC_TRACE_TALK, "rejected to converse [speaker]; they're dangerous")
		ai_mind.say_line("say_brush_off", blanks)
		return
	if(ai_mind.too_busy_to_talk())
		NPC_TRACE(ai_mind, NPC_TRACE_TALK, "can't talk with [speaker]; busy")
		ai_mind.say_line("talk_busy", blanks)
		return
	ai_mind.start_talk(speaker, FALSE)

/datum/ai_holder/rsnpc/proc/too_busy_to_talk()
	if(threat || escaping || world.time < panic_until || length(open_promises()) || task?.level(src) > NPC_TIER_SOCIAL || task?.must_finish(src))
		return TRUE
	for(var/datum/npc_assignment/A as anything in assignments)
		if(A.needs_legs(src))
			return TRUE
	return FALSE

/datum/ai_holder/rsnpc/proc/would_talk_to(mob/living/M)
	if(!can_notice(M) || M.stat != CONSCIOUS || !friendly_to(M) || danger_of(M) >= NPC_WARY || noted("talked:[npc_person_key(M)]"))
		return FALSE
	var/datum/ai_holder/rsnpc/other = npc_ai_mind(M)
	return !other?.assignment(/datum/npc_assignment/talk)

/datum/ai_holder/rsnpc/proc/talk_partner()
	var/mob/living/best
	for(var/mob/living/M in look())
		if(would_talk_to(M) && (!best || get_dist(holder, M) < get_dist(holder, best)))
			best = M
	return best

/datum/ai_holder/rsnpc/proc/start_talk(mob/living/M, greeting)
	var/datum/npc_assignment/talk/T = new(M, null, 150 SECONDS)
	T.waiting = greeting
	T.turn_at = world.time
	start_assignment(T, greeting ? "talk_hello" : "talk_hello_back")

/datum/ai_holder/rsnpc/proc/hear_talk(mob/living/speaker, line, via)
	var/datum/npc_assignment/talk/T = assignment(/datum/npc_assignment/talk)
	if(!T || via || T.started == world.time || T.asker?.resolve() != speaker)
		return FALSE
	var/rest = npc_after_name(line, holder, null, TRUE)
	if(isnull(rest))
		rest = line
	if(T.waiting)
		if(!npc_starts_with(rest, NPC_ANSWER_HELLO))
			end_assignment(T, "[speaker] didn't say hello back")
			return TRUE
		T.waiting = FALSE
		T.turn_at = world.time
		T.reply_at = world.time + 3 SECONDS
		NPC_TRACE(src, NPC_TRACE_TALK, "[speaker] said hello back")
		return TRUE
	if(npc_starts_with(rest, NPC_ANSWER_BYE) || npc_starts_with(rest, NPC_ANSWER_GOODBYE))
		T.finish(src, "[speaker] said goodbye", "talk_farewell_back")
		return TRUE
	T.turn_at = world.time
	T.reply_at = world.time + 3 SECONDS
	T.prompted = FALSE
	return TRUE

/datum/ai_holder/rsnpc/proc/remark(mob/living/M)
	var/datum/npc_event/E = memory_for(M)
	if(E && prob(50))
		tell_memory(E, M)
		return
	say_line("talk_small_talk", list("name" = M.name))

/datum/npc_assignment/talk
	name = "talk"
	uses_legs = TRUE
	var/waiting = FALSE
	var/remarks = 0
	var/turn_at = 0
	var/reply_at = 0
	var/prompted = FALSE

/datum/npc_assignment/talk/goal(datum/ai_holder/rsnpc/ai_mind)
	var/mob/living/M = asker?.resolve()
	return M ? list(NPC_FACT_NEAR(M)) : list()

/datum/npc_assignment/talk/check(datum/ai_holder/rsnpc/ai_mind)
	var/mob/living/me = ai_mind.holder
	var/mob/living/M = asker?.resolve()
	if(me.stat != CONSCIOUS)
		ai_mind.end_assignment(src, "knocked out")
		return
	if(!M || M.stat != CONSCIOUS || get_z(M) != get_z(me) || get_dist(M, me) > 7 || !(M in ai_mind.look()))
		ai_mind.end_assignment(src, "they left", waiting ? null : "talk_cut_short")
		return
	if(waiting)
		if(world.time > started + 10 SECONDS)
			ai_mind.end_assignment(src, "no hello back")
		return
	if(ai_mind.threat || ai_mind.escaping || world.time < ai_mind.panic_until || ai_mind.task?.level(ai_mind) > NPC_TIER_SOCIAL)
		ai_mind.end_assignment(src, "something came up", "talk_interrupted")
		return
	if(world.time > until || (reply_at && world.time >= reply_at && remarks >= ai_mind.npc_psetting("talk_remarks")))
		finish(ai_mind, "said goodbye", "talk_signoff")
		return
	if(reply_at && world.time >= reply_at)
		reply_at = 0
		remarks++
		ai_mind.remark(M)
		return
	if(world.time > turn_at + ai_mind.npc_psetting("talk_silence_seconds") SECONDS)
		if(prompted)
			ai_mind.end_assignment(src, "they went quiet", "talk_cut_short")
			return
		prompted = TRUE
		turn_at = world.time
		ai_mind.say_line("talk_prompt", blanks())

/datum/npc_assignment/talk/plan_failed(datum/ai_holder/rsnpc/ai_mind, why)
	NPC_TRACE(ai_mind, NPC_TRACE_TASK, "can't get closer to [asker_name], talking from here. [why]")

/datum/npc_assignment/talk/proc/finish(datum/ai_holder/rsnpc/ai_mind, why, group)
	ai_mind.change_opinion(asker?.resolve(), ai_mind.npc_psetting("talk_opinion"), "talked with me")
	ai_mind.end_assignment(src, why, group)

/datum/npc_assignment/talk/ended(datum/ai_holder/rsnpc/ai_mind)
	ai_mind.note("talked:[asker_key]", asker_name, ai_mind.npc_psetting("talk_again_minutes") MINUTES)
	ai_mind.note("talk_gap", asker_name, ai_mind.npc_psetting("talk_gap_seconds") SECONDS)
	ai_mind.note("said:hello:\ref[asker?.resolve()]", asker_name, 20 SECONDS)

/datum/npc_task/talk
	name = "talk"
	tier = NPC_TIER_SOCIAL
	assignment_type = /datum/npc_assignment/talk

/datum/npc_task/talk/value(datum/ai_holder/rsnpc/ai_mind)
	return 100

/datum/npc_task/start_talk
	name = "start a talk"
	tier = NPC_TIER_FULFILLMENT

/datum/npc_task/start_talk/can_start(datum/ai_holder/rsnpc/ai_mind)
	return !ai_mind.noted("talk_gap") && !ai_mind.assignment(/datum/npc_assignment/talk) && ai_mind.talk_partner()

/datum/npc_task/start_talk/value(datum/ai_holder/rsnpc/ai_mind)
	return 25

/datum/npc_task/start_talk/goal(datum/ai_holder/rsnpc/ai_mind)
	var/mob/living/M = ai_mind.talk_partner()
	return M ? list(NPC_FACT_GREETED(M)) : list()

/datum/npc_action/greet
	name = "say hello"
	var/mob/living/person

/datum/npc_action/greet/variants(datum/ai_holder/rsnpc/ai_mind, fact)
	if(findtext(fact, "greeted:") != 1)
		return list()
	var/mob/living/M = locate(copytext(fact, 9))
	if(!istype(M))
		return list()
	var/datum/npc_action/greet/A = copy(null, 1, null, list(fact))
	A.person = M
	A.name = "say hello to [M]"
	A.key = "[A.key]:\ref[M]"
	return list(A)

/datum/npc_action/greet/run_action(datum/ai_holder/rsnpc/ai_mind)
	if(QDELETED(person) || !(person in ai_mind.look()) || !ai_mind.would_talk_to(person))
		why = "they're not free to talk"
		return NPC_CANT_DO
	ai_mind.start_talk(person, TRUE)
	return NPC_DONE
