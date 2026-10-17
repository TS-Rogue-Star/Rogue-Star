/datum/npc_promise
	var/kind
	var/datum/npc_task/task
	var/datum/weakref/asked
	var/channel
	var/datum/weakref/who
	var/who_name
	var/state = NPC_PROMISE_ASKED
	var/until
	var/why

/datum/ai_holder/rsnpc/proc/open_promises(kind)
	. = list()
	for(var/datum/npc_promise/P as anything in promises)
		if(!kind || npc_kind_is(kind, P.kind))
			. += P

/datum/ai_holder/rsnpc/proc/end_promise(datum/npc_promise/P, state, why)
	P.state = state
	P.why = why
	promises -= P
	NPC_TRACE(src, NPC_TRACE_TALK, "ask for [npc_kind_name(P.kind)] ended; [why]")
	if(state == NPC_PROMISE_KEPT)
		change_opinion(P.who?.resolve(), npc_psetting("delivered"), "kept their promise")
	if(state == NPC_PROMISE_BROKEN)
		change_opinion(P.who?.resolve(), -npc_psetting("failed_to_deliver"), "broke their promise")
	if(state == NPC_PROMISE_BROKEN || state == NPC_PROMISE_REFUSED || state == NPC_PROMISE_LAPSED)
		var/mob/living/M = P.who?.resolve() || P.asked?.resolve()
		cross_off(P.channel ? "ask:radio:[P.kind]" : "ask:\ref[M]", 5 MINUTES, why)

/datum/ai_holder/rsnpc/proc/check_promises()
	for(var/datum/npc_promise/P as anything in open_promises())
		if(P.kind == "treatment" && fact_true(NPC_FACT_TREATED))
			end_promise(P, P.who ? NPC_PROMISE_KEPT : NPC_PROMISE_DROPPED, P.who ? "[P.who_name] treated me" : "got better")
		else if(!P.task || !P.task.can_start(src))
			end_promise(P, NPC_PROMISE_DROPPED, "no longer needed")
		else if(world.time > P.until)
			if(P.state == NPC_PROMISE_ASKED)
				end_promise(P, NPC_PROMISE_LAPSED, "no answer")
			else
				end_promise(P, NPC_PROMISE_BROKEN, "[P.who_name] never came")

/datum/ai_holder/rsnpc/proc/hear_answer(mob/living/speaker, line, via)
	var/rest = npc_after_name(line, holder, null, TRUE)
	if(isnull(rest))
		rest = line
	var/yes = npc_starts_with(rest, NPC_ANSWER_YES)
	if(!yes && !npc_starts_with(rest, NPC_ANSWER_NO))
		return FALSE
	for(var/datum/npc_promise/P as anything in open_promises())
		if(P.state != NPC_PROMISE_ASKED || !may_answer(P, speaker))
			continue
		if(!yes)
			end_promise(P, NPC_PROMISE_REFUSED, "[speaker] said no")
			return TRUE
		P.state = NPC_PROMISE_AGREED
		P.who = WEAKREF(speaker)
		P.who_name = speaker.name
		P.until = world.time + 5 MINUTES
		NPC_TRACE(src, NPC_TRACE_TALK, "[speaker] promised to fuilfill my request")
		return TRUE
	return eat_prey_answer(speaker, yes) || digest_answer(speaker, yes)

/datum/ai_holder/rsnpc/proc/may_answer(datum/npc_promise/P, mob/living/speaker)
	var/mob/living/M = P.asked?.resolve()
	if(M)
		return speaker == M
	return npc_can_supply(npc_manifest_job(speaker), P.kind)

/datum/ai_holder/rsnpc/proc/received(mob/living/giver, obj/item/I)
	for(var/datum/npc_promise/P as anything in open_promises())
		if(!ispath(P.kind) || !istype(I, P.kind))
			continue
		if(P.who?.resolve() == giver)
			end_promise(P, NPC_PROMISE_KEPT, "[giver] brought it")
		else
			end_promise(P, NPC_PROMISE_DROPPED, "got it from [giver]")
