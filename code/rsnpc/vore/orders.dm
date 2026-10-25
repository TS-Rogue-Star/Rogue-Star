/datum/ai_holder/rsnpc/proc/prey_named(rest)
	var/list/found = list()
	for(var/mob/living/L as anything in people_inside())
		if(rest in npc_name_forms(L))
			found += L
	return length(found) == 1 ? found[1] : null

/datum/ai_holder/rsnpc/proc/order_weight(mob/living/M)
	return danger_of(M) < NPC_DANGEROUS ? max(0, opinion_of(M)) / 100 * npc_psetting("pred_feelings_motive") : 0

/datum/npc_command/vore_order
	repeat = 10 SECONDS

/datum/npc_command/vore_order/proc/from_inside(datum/ai_holder/rsnpc/ai_mind, mob/living/speaker)
	var/obj/belly/B = speaker.loc
	return istype(B) && B.owner == ai_mind.holder

/datum/npc_command/vore_order/release
	say = "release"

/datum/npc_command/vore_order/release/run_command(datum/ai_holder/rsnpc/ai_mind, mob/living/speaker, rest, via)
	ai_mind.belly_order(speaker, rest, src, "release")

/datum/npc_command/vore_order/hold
	say = "hold"

/datum/npc_command/vore_order/hold/run_command(datum/ai_holder/rsnpc/ai_mind, mob/living/speaker, rest, via)
	ai_mind.belly_order(speaker, rest, src, "hold")

/datum/npc_command/vore_order/digest
	say = "digest"

/datum/npc_command/vore_order/digest/run_command(datum/ai_holder/rsnpc/ai_mind, mob/living/speaker, rest, via)
	ai_mind.belly_order(speaker, rest, src, "digest")

/datum/ai_holder/rsnpc/proc/belly_order(mob/living/speaker, rest, datum/npc_command/vore_order/C, kind)
	if(C.from_inside(src, speaker))
		return
	var/mob/living/L = prey_named(rest)
	if(!L || !prey_inside[npc_person_key(L)])
		say_line("pred_order_nobody", list("name" = speaker.name))
		return
	stomach_request(kind, L, speaker, C)

/datum/npc_command/vore_order/eat
	say = "eat"

/datum/npc_command/vore_order/eat/run_command(datum/ai_holder/rsnpc/ai_mind, mob/living/speaker, rest, via)
	if(from_inside(ai_mind, speaker))
		return
	var/mob/living/target
	for(var/mob/living/M in ai_mind.look())
		if(ai_mind.can_notice(M) && (rest in npc_name_forms(M)))
			target = M
			break
	var/list/blanks = list("name" = speaker.name)
	if(!target)
		ai_mind.say_line("pred_eat_nobody", blanks)
		return
	var/push = ai_mind.order_weight(speaker)
	var/forceable = ai_mind.may_force(target)
	var/mode = ai_mind.eat_mode(target, push)
	if(!npc_vore_allowed(ai_mind.holder, target, FALSE) || (target.stat != CONSCIOUS && !forceable))
		ai_mind.say_line("pred_invite_cant", blanks)
		return
	if(!ai_mind.room_for(target))
		ai_mind.say_line("pred_invite_full", blanks)
		return
	if(!mode)
		NPC_TRACE(ai_mind, NPC_TRACE_TALK, "refused \"[say]\" from [speaker]; not pushed enough to eat [target]")
		ai_mind.say_line("pred_order_no", blanks)
		return
	blanks["other"] = target.name
	ai_mind.say_now("pred_eat_yes", blanks)
	ai_mind.start_eating(target, mode, push, speaker)
