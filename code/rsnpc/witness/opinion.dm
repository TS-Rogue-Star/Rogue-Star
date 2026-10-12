/datum/npc_person
	var/key
	var/name
	var/opinion = 0
	var/danger = 0
	var/danger_at = 0
	var/touched_at = 0
	var/list/touches = list()
	var/gun_seen_at = 0
	var/seen_at = 0
	var/turf/seen_turf

/datum/npc_person/proc/danger_now()
	if(danger >= NPC_DANGEROUS)
		return danger
	return max(0, danger - (world.time - danger_at) / (1 MINUTE) * 4)

/proc/npc_person_key(who)
	if(istext(who))
		return who
	var/mob/M = who
	return M?.name

/proc/npc_is_person(mob/M)
	return ishuman(M) || issilicon(M)

/proc/npc_armed(mob/living/M, heavy)
	for(var/obj/item/I in list(M.l_hand, M.r_hand))
		if(istype(I, /obj/item/weapon/gun) || (heavy && I.force >= 15))
			return TRUE
	return FALSE

/datum/ai_holder/complex_npc/proc/person(who)
	var/key = npc_person_key(who)
	if(!key)
		return null
	var/datum/npc_person/P = opinions[key]
	if(!P)
		P = new
		P.key = key
		P.name = key
		opinions[key] = P
	return P

/datum/ai_holder/complex_npc/proc/opinion_of(M)
	var/datum/npc_person/P = opinions[npc_person_key(M)]
	return P ? P.opinion : 0

/datum/ai_holder/complex_npc/proc/danger_of(M)
	var/datum/npc_person/P = opinions[npc_person_key(M)]
	return P ? P.danger_now() : 0

/datum/ai_holder/complex_npc/proc/friendly_to(mob/M)
	return opinion_of(M) >= npc_psetting("social_floor")

/datum/ai_holder/complex_npc/proc/change_opinion(M, amount, why)
	var/datum/npc_person/P = person(M)
	if(!P || !amount)
		return
	if(amount < 0)
		amount *= npc_psetting("opinion_loss_scale")
	var/old = P.opinion
	if(!set_opinion(P, old + amount, why) || !(M in look()))
		return
	var/liked = npc_psetting("opinion_liked_at")
	var/disliked = npc_psetting("opinion_disliked_at")
	if(old < liked && P.opinion >= liked)
		say_line("opinion_liked", list("name" = P.name))
	else if(old > disliked && P.opinion <= disliked)
		say_line("opinion_disliked", list("name" = P.name))

/datum/ai_holder/complex_npc/proc/set_opinion(datum/npc_person/P, value, why)
	var/old = P.opinion
	P.opinion = clamp(value, -100, 100)
	if(P.opinion == old)
		return FALSE
	NPC_TRACE(src, NPC_TRACE_WITNESS, "opinion of [P.key] [round(old)] -> [round(P.opinion)]; [why]")
	return TRUE

/datum/ai_holder/complex_npc/proc/add_danger(M, amount, why)
	var/datum/npc_person/P = person(M)
	if(!P || amount <= 0)
		return FALSE
	return set_danger(P, P.danger_now() + amount, why)

/datum/ai_holder/complex_npc/proc/set_danger(datum/npc_person/P, value, why)
	var/old = P.danger_now()
	P.danger = max(0, value)
	P.danger_at = world.time
	NPC_TRACE(src, NPC_TRACE_WITNESS, "danger of [P.key] [round(old)] -> [round(P.danger)]; [why]")
	return old < NPC_DANGEROUS && P.danger >= NPC_DANGEROUS

/datum/ai_holder/complex_npc/proc/opinion_label(datum/npc_person/P)
	if(P.opinion >= npc_psetting("opinion_liked_at"))
		return "liked"
	if(P.opinion <= npc_psetting("opinion_disliked_at"))
		return "disliked"
	return "neutral"

/proc/npc_danger_label(danger)
	if(danger >= NPC_DANGEROUS)
		return "dangerous, indefinitely"
	if(danger >= NPC_WARY)
		return "wary"
	if(danger > 0)
		return "sus"
	return ""

/datum/ai_holder/complex_npc/proc/health_share()
	return clamp(holder.health / holder.getMaxHealth(), 0, 1)

/datum/ai_holder/complex_npc/proc/form_opinions()
	for(var/mob/living/M in in_sight)
		if(!npc_is_person(M))
			continue
		var/datum/npc_person/P = person(M)
		if(!P)
			continue
		P.seen_at = world.time
		P.seen_turf = get_turf(M)
		if(M.stat == DEAD)
			saw_body(M)
			continue
		if(npc_armed(M) && !SSjob.is_job_in_department(npc_job_of(M), DEPARTMENT_SECURITY) && world.time > P.gun_seen_at + 30 SECONDS && P.danger_now() < NPC_WARY)
			P.gun_seen_at = world.time
			add_danger(M, 2, "carrying a gun in the open")
