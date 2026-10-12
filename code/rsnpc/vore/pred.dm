/datum/npc_prey
	var/key
	var/name
	var/forced = FALSE
	var/digest_invited = FALSE
	var/order = 0
	var/order_at = 0
	var/asked_digest_at = 0
	var/warned_at = 0
	var/digest_answered = FALSE
	var/refused_digest = FALSE
	var/hunger = 0
	var/died = FALSE

/datum/ai_holder/complex_npc/proc/pred_hunger()
	return clamp(1 - holder.nutrition / (2800 * npc_psetting("pred_capacity")), 0, 1)

/datum/ai_holder/complex_npc/proc/digest_line()
	return npc_psetting("pred_digest_line")

/datum/ai_holder/complex_npc/proc/threat_of(mob/living/M)
	if(!npc_menace(M))
		return -1
	. = 0
	if(fight_or_flight(M) == NPC_FLIGHT)
		. += 0.5
	if(npc_armed(M, TRUE))
		. += 0.25
	. += 0.5 * min(1, danger_of(M) / 40)

/datum/ai_holder/complex_npc/proc/turned_down()
	. = 0
	for(var/key in notes.Copy())
		if(findtext(key, "turned_down:") != 1)
			continue
		var/at = noted(key)
		if(at)
			. += 0.2 * max(0, 1 - (world.time - at) / (15 MINUTES))

/datum/ai_holder/complex_npc/proc/people_inside()
	. = list()
	for(var/obj/belly/B as anything in holder.vore_organs)
		for(var/mob/living/L in B)
			. += L

/datum/ai_holder/complex_npc/proc/room_for(mob/living/M)
	return length(people_inside()) + 1 <= npc_psetting("pred_capacity")

/datum/ai_holder/complex_npc/proc/digesting_any()
	for(var/obj/belly/B as anything in holder.vore_organs)
		if(B.digest_mode == DM_DIGEST && (locate(/mob/living) in B))
			return TRUE
	return FALSE

/datum/ai_holder/complex_npc/proc/force_score(mob/living/M)
	return pred_hunger() * npc_psetting("pred_hunger_motive") - opinion_of(M) / 100 * npc_psetting("pred_feelings_motive") - threat_of(M) * npc_psetting("pred_threat_motive")

/datum/ai_holder/complex_npc/proc/ask_score(mob/living/M)
	return pred_hunger() * npc_psetting("pred_hunger_motive") + opinion_of(M) / 100 * npc_psetting("pred_feelings_motive") - threat_of(M) * npc_psetting("pred_threat_motive") - turned_down()

/datum/ai_holder/complex_npc/proc/may_force(mob/living/M)
	return npc_vore_allowed(holder, M, TRUE) && isturf(M.loc)

/datum/ai_holder/complex_npc/proc/may_ask(mob/living/M)
	return npc_vore_allowed(holder, M, FALSE) && isturf(M.loc) && M.stat == CONSCIOUS && !digesting_any()

/datum/ai_holder/complex_npc/proc/pred_scan()
	if(!has_personality("pred") || world.time < pred_scanned_at + 4 SECONDS || !isturf(holder.loc) || task?.tier > NPC_TIER_SOCIAL)
		return
	pred_scanned_at = world.time
	for(var/datum/npc_assignment/A as anything in assignments)
		if(A.uses_legs)
			return
	var/mob/living/best
	var/best_over
	var/best_mode
	for(var/mob/living/M in look())
		if(!can_notice(M) || noted("pred_tried:[npc_person_key(M)]") || !room_for(M))
			continue
		var/mode
		var/over
		if(may_force(M) && force_score(M) >= npc_psetting("pred_force_line"))
			mode = "force"
			over = force_score(M) - npc_psetting("pred_force_line")
		else if(may_ask(M) && ask_score(M) >= npc_psetting("pred_ask_line"))
			mode = "ask"
			over = ask_score(M) - npc_psetting("pred_ask_line")
		if(!mode)
			continue
		over -= 0.02 * get_dist(holder, M)
		if(!best || over > best_over)
			best = M
			best_over = over
			best_mode = mode
	if(best)
		start_eating(best, best_mode)

/datum/ai_holder/complex_npc/proc/start_eating(mob/living/M, mode)
	var/datum/npc_assignment/eat_prey/A = new(M, null, 2 MINUTES)
	A.name = "eat [M]"
	A.mode = mode
	note("pred_tried:[npc_person_key(M)]", M.name, 10 MINUTES)
	start_assignment(A, mode == "force" ? "pred_force" : null)

/datum/npc_assignment/eat_prey
	name = "eat"
	uses_legs = TRUE
	var/mode
	var/digest = FALSE
	var/asked_at = 0
	var/grab_tries = 0
	var/slips = 0
	var/had_grab = FALSE
	var/tightened = FALSE

/datum/npc_assignment/eat_prey/blanks()
	return list("name" = asker_name)

/datum/npc_assignment/eat_prey/goal(datum/ai_holder/complex_npc/ai_mind)
	var/mob/living/M = asker?.resolve()
	if(!M)
		return list()
	if(mode == "ask")
		return asked_at ? list() : list(NPC_FACT_NEAR(M))
	return list(NPC_FACT_EATEN(M))

/datum/npc_assignment/eat_prey/check(datum/ai_holder/complex_npc/ai_mind)
	var/mob/living/M = asker?.resolve()
	if(M && (M in ai_mind.people_inside()))
		return
	if(!M || M.stat == DEAD || !(M in ai_mind.look()))
		ai_mind.end_assignment(src, "lost them")
		return
	if(mode == "force" && npc_armed(M, TRUE) && ai_mind.danger_of(M) >= NPC_WARY)
		give_up(ai_mind, "they're armed and dangerous")
		return
	if(mode == "ask" && !asked_at && ai_mind.fact_true(NPC_FACT_NEAR(M)))
		asked_at = world.time
		ai_mind.note_vore_question(M, ai_mind.holder, FALSE)
		ai_mind.say_line("pred_ask", blanks())
	if(mode == "ask" && asked_at && world.time > asked_at + 45 SECONDS)
		ai_mind.note("turned_down:[asker_key]", world.time, 15 MINUTES)
		ai_mind.end_assignment(src, "no answer", "pred_no_answer")
		return
	..()

/datum/npc_assignment/eat_prey/proc/give_up(datum/ai_holder/complex_npc/ai_mind, why)
	ai_mind.end_assignment(src, why, "pred_give_up")

/datum/npc_task/eat_prey
	name = "eat someone"
	tier = NPC_TIER_SOCIAL
	assignment_type = /datum/npc_assignment/eat_prey

/datum/npc_task/eat_prey/value(datum/ai_holder/complex_npc/ai_mind)
	return 100

/datum/ai_holder/complex_npc/proc/eat_prey_answer(mob/living/speaker, yes)
	var/datum/npc_assignment/eat_prey/A = assignment(/datum/npc_assignment/eat_prey)
	if(!A || A.mode != "ask" || !A.asked_at || A.asker?.resolve() != speaker)
		return FALSE
	if(!yes)
		note("turned_down:[A.asker_key]", world.time, 15 MINUTES)
		end_assignment(A, "[speaker] said no", "pred_heard_no")
		return TRUE
	A.mode = "agreed"
	say_line("pred_heard_yes", list("name" = speaker.name))
	if(task?.assignment_type == A.type)
		clear_plan()
	return TRUE

/datum/npc_action/swallow
	name = "swallow"
	var/mob/living/prey
	var/swallowing_until = 0
	var/old_intent

/datum/npc_action/swallow/variants(datum/ai_holder/complex_npc/ai_mind, fact)
	if(findtext(fact, "eaten:") != 1)
		return list()
	var/mob/living/M = locate(copytext(fact, 7))
	if(!istype(M))
		return list()
	var/datum/npc_action/swallow/A = copy(M, 1, null, list(fact))
	A.prey = M
	A.name = "eat [M]"
	return list(A)

/datum/npc_action/swallow/run_action(datum/ai_holder/complex_npc/ai_mind)
	var/mob/living/carbon/human/H = ai_mind.holder
	var/datum/npc_assignment/eat_prey/A = ai_mind.assignment(/datum/npc_assignment/eat_prey)
	if(ai_mind.fact_true(gives[1]))
		return NPC_DONE
	if(!A)
		why = "no longer eating them"
		return NPC_CANT_DO
	if(world.time < swallowing_until || !H.checkClickCooldown())
		return NPC_RUNNING
	var/obj/item/weapon/grab/G
	for(var/obj/item/weapon/grab/held_grab in list(H.l_hand, H.r_hand))
		if(held_grab.affecting == prey)
			G = held_grab
	if(!prey.Adjacent(H))
		if(ai_mind.destination != prey)
			ai_mind.go_to(prey)
		return NPC_RUNNING
	if(isnull(old_intent))
		old_intent = H.a_intent
	if(isrobot(prey))
		H.a_intent = I_HELP
		swallowing_until = world.time + 15 SECONDS
		INVOKE_ASYNC(prey, TYPE_PROC_REF(/mob/living, feed_grabbed_to_self), H, prey)
		return NPC_RUNNING
	if(!G)
		if(A.had_grab)
			A.had_grab = FALSE
			if(++A.slips >= 3)
				A.give_up(ai_mind, "they slipped away three times")
				return NPC_RUNNING
			ai_mind.say_line("pred_regrab", list("name" = prey.name))
		if(++A.grab_tries > 6)
			A.give_up(ai_mind, "couldn't get a grip on them")
			return NPC_RUNNING
		if(H.get_active_hand())
			H.swap_hand()
		if(H.get_active_hand())
			if(!ai_mind.free_hand())
				why = "my hands are full"
				return NPC_NOT_YET
			return NPC_RUNNING
		H.a_intent = I_GRAB
		H.IAttack(prey)
		return NPC_RUNNING
	A.had_grab = TRUE
	if(G.state < GRAB_AGGRESSIVE || (A.mode == "force" && G.state < GRAB_NECK))
		if(G.state == GRAB_AGGRESSIVE && !A.tightened)
			A.tightened = TRUE
			ai_mind.say_line("pred_tighten", list("name" = prey.name))
		G.attack_self()
		return NPC_RUNNING
	H.a_intent = I_HELP
	swallowing_until = world.time + 15 SECONDS
	NPC_TRACE(ai_mind, NPC_TRACE_TASK, "swallowing [prey]")
	INVOKE_ASYNC(H, TYPE_PROC_REF(/atom, attackby), G, H)
	return NPC_RUNNING

/datum/npc_action/swallow/clean_up(datum/ai_holder/complex_npc/ai_mind)
	var/mob/living/H = ai_mind.holder
	for(var/obj/item/weapon/grab/G in list(H.l_hand, H.r_hand))
		if(G.affecting == prey)
			qdel(G)
	if(!isnull(old_intent))
		H.a_intent = old_intent
		old_intent = null
