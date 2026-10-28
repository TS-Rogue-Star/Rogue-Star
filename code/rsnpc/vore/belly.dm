/datum/ai_holder/proc/prey_struggled(mob/living/L)
	return

/datum/ai_holder/rsnpc/prey_struggled(mob/living/L)
	if(agreed(L, holder, FALSE) || agreed(L, holder, TRUE))
		change_opinion(L, -1, "struggled after agreeing")
	if(!noted("struggle_answer"))
		note("struggle_answer", L.name, 30 SECONDS)
		say_line("pred_answer_struggle", list("name" = L.name))

/datum/ai_holder/rsnpc/proc/prey_weight(mob/living/L, datum/npc_prey/record)
	. = -opinion_of(L) / 100 * npc_psetting("pred_feelings_motive")
	if(agreed(L, holder, TRUE))
		. += 1
	if(record.forced)
		. += 0.5

/datum/ai_holder/rsnpc/proc/weight_alone(mob/living/L, datum/npc_prey/record)
	. = record.hunger * npc_psetting("pred_hunger_motive") - opinion_of(L) / 100 * npc_psetting("pred_feelings_motive") + record.order
	if(record.forced)
		. += 0.5
	if(agreed(L, holder, FALSE) && !agreed(L, holder, TRUE))
		. -= 0.5

/datum/ai_holder/rsnpc/proc/keep_wish(mob/living/L, datum/npc_prey/record)
	return weight_alone(L, record) - npc_psetting("pred_release_margin") - digest_line()

/datum/ai_holder/rsnpc/proc/belly_hunger(obj/belly/B, mob/living/except)
	. = 0
	for(var/mob/living/L in B)
		var/datum/npc_prey/record = prey_inside[npc_person_key(L)]
		if(record && L != except)
			. = max(., record.hunger)

/datum/ai_holder/rsnpc/proc/belly_sum(obj/belly/B)
	. = belly_hunger(B) * npc_psetting("pred_hunger_motive")
	for(var/mob/living/L in B)
		var/datum/npc_prey/record = prey_inside[npc_person_key(L)]
		if(record)
			. += prey_weight(L, record)

/datum/ai_holder/rsnpc/proc/prey_digested(mob/living/L)
	NPC_TRACE(src, NPC_TRACE_TASK, "digested [L]")
	note("digested:[npc_person_key(L)]", "[L.name], in [get_area(holder)], [round(world.time / (1 MINUTE))] minutes into the shift", 8 HOURS)
	say_line("pred_digested", list("name" = L.name))

/datum/ai_holder/rsnpc/proc/check_bellies()
	var/list/inside = people_inside()
	var/list/keys = list()
	for(var/mob/living/L as anything in inside)
		keys += npc_person_key(L)
		if(!prey_inside[npc_person_key(L)])
			prey_arrived(L)
	for(var/key in prey_inside.Copy())
		if(!(key in keys))
			prey_inside -= key

/datum/ai_holder/rsnpc/proc/prey_arrived(mob/living/L)
	var/datum/npc_prey/record = new
	record.key = npc_person_key(L)
	record.name = L.name
	record.hunger = pred_hunger()
	var/datum/npc_assignment/eat_prey/A = assignment(/datum/npc_assignment/eat_prey)
	if(A?.asker?.resolve() == L)
		record.forced = A.mode == "force"
		record.digest_invited = A.digest
		end_assignment(A, "swallowed them")
	prey_inside[record.key] = record
	NPC_TRACE(src, NPC_TRACE_TASK, "[L] is inside me")
	if(L.stat == DEAD)
		return
	var/datum/weakref/fed = noted("fed_by")
	var/mob/living/feeder = fed?.resolve()
	if(feeder && feeder != L && weight_alone(L, record) > 0)
		change_opinion(feeder, 10, "fed me [L]")
		say_line("pred_thank_feeder", list("name" = feeder.name, "other" = L.name))
	var/group = "pred_arrived"
	if(agreed(L, holder, FALSE) || agreed(L, holder, TRUE))
		group = "pred_swallowed_agreed"
	else if(record.forced)
		group = "pred_swallowed_other"
	say_line(group, list("name" = L.name))
	var/obj/belly/B = L.loc
	if(record.digest_invited && istype(B) && length(people_inside()) == 1)
		record.order = 1
		record.order_at = world.time
		NPC_TRACE(src, NPC_TRACE_TASK, "will digest [L]; they asked for it")

/datum/ai_holder/rsnpc/proc/decide_belly(obj/belly/B)
	if(!(B.digest_mode in list(DM_HOLD, DM_DIGEST)))
		return
	var/list/living = list()
	var/order = 0
	var/order_at = 0
	var/mob/living/heaviest
	var/heaviest_weight
	for(var/mob/living/L in B)
		var/datum/npc_prey/record = prey_inside[npc_person_key(L)]
		if(!record)
			continue
		if(L.stat != DEAD)
			living += L
		if(record.order && record.order_at > order_at)
			order = record.order
			order_at = record.order_at
		var/weight = prey_weight(L, record)
		if(!heaviest || weight > heaviest_weight)
			heaviest = L
			heaviest_weight = weight
	if(!length(living))
		return
	var/sum = belly_sum(B)
	var/line = digest_line()
	var/digest = belly_wants_digest(B)
	if(digest && B.digest_mode != DM_DIGEST)
		if(!order && !ready_to_digest(B, living))
			return
		B.digest_mode = DM_DIGEST
		var/group = "pred_to_digest_hungry"
		if(order)
			group = "pred_to_digest_ordered"
		else if(agreed(heaviest, holder, TRUE))
			group = "pred_to_digest_agreed"
		else if(heaviest_weight > belly_hunger(B) * npc_psetting("pred_hunger_motive"))
			group = "pred_to_digest_cold"
		NPC_TRACE(src, NPC_TRACE_TASK, "set my [B] to digest; weight [round(sum, 0.01)] against [line]")
		if(heaviest.stat != DEAD)
			say_line(group, list("name" = heaviest.name))
	else if(!digest && B.digest_mode == DM_DIGEST)
		B.digest_mode = DM_HOLD
		NPC_TRACE(src, NPC_TRACE_TASK, "set my [B] to hold; weight [round(sum, 0.01)] against [line]")
		var/mob/living/L = living[1]
		say_line("pred_to_hold", list("name" = L.name))

/datum/ai_holder/rsnpc/proc/would_digest_others(obj/belly/B, mob/living/L)
	var/others = FALSE
	var/sum = belly_hunger(B, L) * npc_psetting("pred_hunger_motive")
	for(var/mob/living/O in B)
		var/datum/npc_prey/record = prey_inside[npc_person_key(O)]
		if(O == L || !record)
			continue
		others = TRUE
		sum += prey_weight(O, record)
	return others && sum >= digest_line()

/datum/ai_holder/rsnpc/proc/ready_to_digest(obj/belly/B, list/living)
	. = TRUE
	var/offer_line = npc_psetting("pred_offer_line")
	for(var/mob/living/L as anything in living)
		var/datum/npc_prey/record = prey_inside[npc_person_key(L)]
		if(record.refused_digest)
			if(would_digest_others(B, L))
				record.refused_digest = FALSE
				refused_digestion(L, record)
			else
				. = FALSE
			continue
		if(record.digest_answered || agreed(L, holder, TRUE))
			continue
		if(agreed(L, holder, FALSE))
			if(!record.asked_digest_at)
				record.asked_digest_at = world.time
				note_vore_question(L, holder, TRUE)
				say_line("pred_ask_digest", list("name" = L.name))
				. = FALSE
			else if(world.time < record.asked_digest_at + 45 SECONDS)
				. = FALSE
			else
				refused_digestion(L, record)
				if(record.refused_digest)
					. = FALSE
			continue
		var/own = record.hunger * npc_psetting("pred_hunger_motive") - opinion_of(L) / 100 * npc_psetting("pred_feelings_motive") + (record.forced ? 0.5 : 0)
		if(!record.warned_at && own <= offer_line)
			record.warned_at = world.time
			say_line("pred_offer_out", list("name" = L.name))
			. = FALSE
		else if(record.warned_at && world.time < record.warned_at + 20 SECONDS)
			. = FALSE

/datum/ai_holder/rsnpc/proc/refused_digestion(mob/living/L, datum/npc_prey/record)
	record.digest_answered = TRUE
	var/obj/belly/B = L.loc
	if(!istype(B) || !would_digest_others(B, L))
		record.refused_digest = TRUE
		NPC_TRACE(src, NPC_TRACE_TASK, "keeping [L] held; they refused digestion")
		return
	var/weight = record.hunger * npc_psetting("pred_hunger_motive") - opinion_of(L) / 100 * npc_psetting("pred_feelings_motive") - 0.5
	if(weight < digest_line())
		release_prey(L, "pred_digest_declined", "they won't be digested")
		return
	NPC_TRACE(src, NPC_TRACE_TASK, "digesting [L] anyway; they said no")

/datum/ai_holder/rsnpc/proc/digest_answer(mob/living/speaker, yes)
	var/datum/npc_prey/record = prey_inside[npc_person_key(speaker)]
	if(!record || !record.asked_digest_at || record.digest_answered)
		return FALSE
	if(yes)
		record.digest_answered = TRUE
		NPC_TRACE(src, NPC_TRACE_TASK, "[speaker] agreed to be digested")
	else
		stomach_request("no", speaker, speaker)
	return TRUE

/datum/ai_holder/rsnpc/proc/release_prey(mob/living/L, group, why)
	var/obj/belly/B = L.loc
	if(!istype(B) || B.owner != holder)
		return
	B.release_specific_contents(L)
	prey_inside -= npc_person_key(L)
	NPC_TRACE(src, NPC_TRACE_TASK, "let [L] out; [why]")
	if(group)
		say_line(group, list("name" = L.name))

/datum/ai_holder/rsnpc/proc/hear_from_inside(mob/living/speaker, line, via)
	var/obj/belly/B = speaker.loc
	if(via || !istype(B) || B.owner != holder)
		return FALSE
	var/datum/npc_prey/record = prey_inside[npc_person_key(speaker)]
	if(!record)
		return FALSE
	if(npc_has_words(line, "please") && !noted("plea:[record.key]"))
		note("plea:[record.key]", speaker.name, 10 SECONDS)
		change_opinion(speaker, 2, "said please")
		if(!noted("plea_answer"))
			note("plea_answer", speaker.name, 30 SECONDS)
			say_line("pred_answer_plea", list("name" = speaker.name))
	if(!npc_has_words(line, "let me out") || noted("refused_out:[record.key]"))
		return TRUE
	stomach_request("out", speaker, speaker)
	return TRUE

/datum/ai_holder/rsnpc/proc/belly_wants_digest(obj/belly/B)
	if(!(B.digest_mode in list(DM_HOLD, DM_DIGEST)))
		return null
	var/living = FALSE
	var/order = 0
	var/order_at = 0
	for(var/mob/living/L in B)
		var/datum/npc_prey/record = prey_inside[npc_person_key(L)]
		if(!record)
			continue
		if(L.stat != DEAD)
			living = TRUE
		if(record.order && record.order_at > order_at)
			order = record.order
			order_at = record.order_at
	if(!living)
		return null
	return belly_sum(B) + order >= (B.digest_mode == DM_DIGEST ? digest_line() - 0.2 : digest_line())

/datum/ai_holder/rsnpc/proc/belly_due(obj/belly/B)
	var/wants = belly_wants_digest(B)
	if(isnull(wants) || wants == (B.digest_mode == DM_DIGEST))
		return FALSE
	if(!wants)
		return TRUE
	for(var/mob/living/L in B)
		var/datum/npc_prey/record = prey_inside[npc_person_key(L)]
		if(!record || L.stat == DEAD || record.order > 0)
			continue
		if(record.refused_digest && !would_digest_others(B, L))
			return FALSE
		if(record.asked_digest_at && !record.digest_answered && world.time < record.asked_digest_at + 45 SECONDS)
			return FALSE
		if(record.warned_at && world.time < record.warned_at + 20 SECONDS)
			return FALSE
	return TRUE

/datum/ai_holder/rsnpc/proc/bellies_due()
	for(var/obj/belly/B as anything in holder.vore_organs)
		if(belly_due(B))
			return TRUE
	return FALSE

/datum/npc_task/handle_stomach
	name = "handle my stomach"
	tier = NPC_TIER_FULFILLMENT

/datum/npc_task/handle_stomach/can_start(datum/ai_holder/rsnpc/ai_mind)
	return ai_mind.bellies_due()

/datum/npc_task/handle_stomach/value(datum/ai_holder/rsnpc/ai_mind)
	return 60

/datum/npc_task/handle_stomach/goal(datum/ai_holder/rsnpc/ai_mind)
	return list(NPC_FACT_STOMACH_HANDLED)

/datum/npc_action/handle_stomach
	name = "handle my stomach"

/datum/npc_action/handle_stomach/variants(datum/ai_holder/rsnpc/ai_mind, fact)
	if(fact != NPC_FACT_STOMACH_HANDLED)
		return list()
	return list(copy(null, 1, null, list(fact)))

/datum/npc_action/handle_stomach/run_action(datum/ai_holder/rsnpc/ai_mind)
	for(var/obj/belly/B as anything in ai_mind.holder.vore_organs)
		if(ai_mind.belly_due(B))
			ai_mind.decide_belly(B)
	return NPC_DONE

/datum/npc_assignment/respond_stomach
	weight = 30
	name = "respond to my stomach"
	var/list/requests = list()

/datum/npc_assignment/respond_stomach/goal(datum/ai_holder/rsnpc/ai_mind)
	return list(NPC_FACT_RESPONDED(src))

/datum/npc_assignment/respond_stomach/check(datum/ai_holder/rsnpc/ai_mind)
	if(!length(requests))
		ai_mind.end_assignment(src, "responded")
		return
	..()

/datum/ai_holder/rsnpc/proc/stomach_request(kind, mob/living/prey, mob/living/speaker, datum/npc_command/command)
	var/datum/npc_assignment/respond_stomach/A = assignment(/datum/npc_assignment/respond_stomach)
	if(!A)
		A = new(speaker, null, 1 MINUTE)
		start_assignment(A)
	A.requests += list(list(kind, WEAKREF(prey), WEAKREF(speaker), command))
	NPC_TRACE(src, NPC_TRACE_TASK, "[speaker] wants [kind] for [prey]")

/datum/npc_task/respond_stomach
	name = "respond to my stomach"
	tier = NPC_TIER_NEEDS
	assignment_type = /datum/npc_assignment/respond_stomach

/datum/npc_task/respond_stomach/value(datum/ai_holder/rsnpc/ai_mind)
	return 150

/datum/npc_action/respond_stomach
	name = "respond to my stomach"

/datum/npc_action/respond_stomach/variants(datum/ai_holder/rsnpc/ai_mind, fact)
	if(findtext(fact, "responded:") != 1)
		return list()
	return list(copy(null, 1, null, list(fact)))

/datum/npc_action/respond_stomach/run_action(datum/ai_holder/rsnpc/ai_mind)
	var/datum/npc_assignment/respond_stomach/A = ai_mind.assignment(/datum/npc_assignment/respond_stomach)
	if(!A)
		return NPC_DONE
	var/list/todo = A.requests.Copy()
	A.requests.Cut()
	for(var/list/R as anything in todo)
		var/datum/weakref/prey = R[2]
		var/datum/weakref/speaker = R[3]
		ai_mind.respond_stomach(R[1], prey?.resolve(), speaker?.resolve(), R[4])
	return NPC_DONE

/datum/ai_holder/rsnpc/proc/respond_stomach(kind, mob/living/L, mob/living/speaker, datum/npc_command/C)
	var/datum/npc_prey/record = L && prey_inside[npc_person_key(L)]
	var/obj/belly/B = L?.loc
	if(!record || !istype(B) || B.owner != holder)
		if(speaker && speaker != L)
			say_line("pred_order_nobody", list("name" = speaker.name))
		return
	switch(kind)
		if("out")
			if(record.asked_digest_at && !record.digest_answered)
				refused_digestion(L, record)
				if(L.loc != B)
					return
			if(noted("refused_out:[record.key]"))
				return
			if(keep_wish(L, record) < 0)
				release_prey(L, "pred_release_asked", "they asked")
				return
			note("refused_out:[record.key]", L.name, 20 SECONDS)
			say_line("pred_refuse", list("name" = L.name))
		if("no")
			if(record.asked_digest_at && !record.digest_answered)
				refused_digestion(L, record)
		if("release")
			if(keep_wish(L, record) - order_weight(speaker) >= 0)
				NPC_TRACE(src, NPC_TRACE_TALK, "refused \"[C.say]\" from [speaker]; I want to keep [L]")
				say_line("pred_order_no", list("name" = speaker.name))
				return
			say_line("pred_release_yes", list("name" = speaker.name, "other" = L.name))
			release_prey(L, L.stat == DEAD ? null : "pred_release_asked", "[speaker] told me to")
		if("hold", "digest")
			var/order = kind == "digest" ? 1 : -1
			if(order > 0 && !npc_vore_allowed(holder, L, TRUE))
				say_line("pred_invite_cant", list("name" = speaker.name))
				return
			var/weight = order * order_weight(speaker)
			if((belly_sum(B) + weight >= digest_line()) != (order > 0))
				NPC_TRACE(src, NPC_TRACE_TALK, "refused \"[C.say]\" from [speaker]; not pushed enough")
				say_line("pred_order_no", list("name" = speaker.name))
				return
			record.order = weight
			record.order_at = world.time
			say_line(order > 0 ? "pred_digest_yes" : "pred_hold_yes", list("name" = speaker.name, "other" = L.name))
			decide_belly(B)
