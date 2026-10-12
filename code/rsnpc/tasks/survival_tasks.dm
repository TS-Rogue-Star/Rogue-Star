GLOBAL_LIST_INIT(npc_danger_ranges, list(
	/obj/fire = 2,
	/obj/effect/temporary_effect/shuttle_landing = 1,
	/obj/singularity/energy_ball = 8,
))

/proc/npc_danger_range(atom/A)
	for(var/kind in GLOB.npc_danger_ranges)
		if(istype(A, kind))
			return GLOB.npc_danger_ranges[kind]
	return 0

/proc/npc_clear_of(list/dangers, turf/T)
	for(var/atom/A as anything in dangers)
		if(get_z(A) == T.z && get_dist(A, T) <= npc_danger_range(A))
			return FALSE
	return TRUE

/proc/npc_safe_spot(mob/living/who, list/dangers, turf/T)
	return npc_safe_tile(who, T) && npc_clear_of(dangers, T)

/datum/ai_holder/complex_npc/proc/dangers_in_sight()
	. = list()
	for(var/atom/A as anything in look())
		if(npc_danger_range(A))
			. += A

/datum/ai_holder/complex_npc/proc/internals_check()
	var/mob/living/carbon/human/H = holder
	if(!istype(H) || !H.internal || !npc_air_breathable(get_turf(H), H) || istype(H.wear_suit, /obj/item/clothing/suit/space) && istype(H.head, /obj/item/clothing/head/helmet/space))
		return
	if(H.toggle_internals_hud())
		NPC_TRACE(src, NPC_TRACE_TASK, "internals off; the air is good")

/datum/npc_task/internals
	name = "use internals"
	tier = NPC_TIER_SURVIVAL

/datum/npc_task/internals/can_start(datum/ai_holder/complex_npc/ai_mind)
	var/mob/living/carbon/human/H = ai_mind.holder
	return istype(H) && !H.internal && isturf(H.loc) && !npc_air_breathable(H.loc, H)

/datum/npc_task/internals/value(datum/ai_holder/complex_npc/ai_mind)
	return 200

/datum/npc_task/internals/goal(datum/ai_holder/complex_npc/ai_mind)
	return list(NPC_FACT_INTERNALS)

/datum/npc_task/get_out_of_danger
	name = "get out of danger"
	tier = NPC_TIER_SURVIVAL

/datum/npc_task/get_out_of_danger/can_start(datum/ai_holder/complex_npc/ai_mind)
	return isturf(ai_mind.holder.loc) && !ai_mind.fact_true(NPC_FACT_SAFE)

/datum/npc_task/get_out_of_danger/value(datum/ai_holder/complex_npc/ai_mind)
	return 100

/datum/npc_task/get_out_of_danger/goal(datum/ai_holder/complex_npc/ai_mind)
	return list(NPC_FACT_SAFE)

/datum/npc_action/internals_on
	name = "turn on internals"

/datum/npc_action/internals_on/variants(datum/ai_holder/complex_npc/ai_mind, fact)
	if(fact != NPC_FACT_INTERNALS)
		return list()
	return list(copy(null, 1, list(NPC_FACT_HAVE(/obj/item/weapon/tank), NPC_FACT_MASKED), list(NPC_FACT_INTERNALS)))

/datum/npc_action/internals_on/run_action(datum/ai_holder/complex_npc/ai_mind)
	var/mob/living/carbon/H = ai_mind.holder
	if(H.internal)
		return NPC_DONE
	if(!H.checkClickCooldown())
		return NPC_RUNNING
	H.toggle_internals_hud()
	H.setClickCooldown(DEFAULT_QUICK_COOLDOWN)
	if(!H.internal)
		why = "internals didn't turn on"
		return NPC_CANT_DO
	NPC_TRACE(ai_mind, NPC_TRACE_TASK, "internals on")
	return NPC_DONE

/datum/npc_action/put_on_mask
	name = "put on a mask"

/datum/npc_action/put_on_mask/variants(datum/ai_holder/complex_npc/ai_mind, fact)
	if(fact != NPC_FACT_MASKED)
		return list()
	return list(copy(null, 1, list(NPC_FACT_HAVE(/obj/item/clothing/mask/breath)), list(NPC_FACT_MASKED)))

/datum/npc_action/put_on_mask/run_action(datum/ai_holder/complex_npc/ai_mind)
	var/mob/living/carbon/human/H = ai_mind.holder
	if(ai_mind.fact_true(NPC_FACT_MASKED))
		return NPC_DONE
	if(H.wear_mask)
		why = "already wearing [H.wear_mask]"
		return NPC_CANT_DO
	var/obj/item/I = ai_mind.held_item(/obj/item/clothing/mask/breath)
	if(!I)
		why = "no mask in hand"
		return NPC_NOT_THERE
	if(!H.checkClickCooldown())
		return NPC_RUNNING
	if(H.get_active_hand() != I)
		H.swap_hand()
	H.quick_equip()
	H.setClickCooldown(DEFAULT_QUICK_COOLDOWN)
	if(H.wear_mask != I)
		why = "couldn't put [I] on"
		return NPC_CANT_DO
	return NPC_DONE

/datum/npc_action/seen_safe_spot
	name = "go to a safe spot I can see"

/datum/npc_action/seen_safe_spot/variants(datum/ai_holder/complex_npc/ai_mind, fact)
	if(fact != NPC_FACT_SAFE)
		return list()
	var/turf/here = get_turf(ai_mind.holder)
	var/list/dangers = ai_mind.dangers_in_sight()
	var/turf/best
	for(var/turf/T as anything in ai_mind.turfs_in_sight)
		if(T == here || !T.npc_room || !npc_can_stand(T) || ai_mind.crossed_off(npc_place_key(T)) || !npc_safe_spot(ai_mind.holder, dangers, T))
			continue
		if(!best || get_dist(here, T) < get_dist(here, best))
			best = T
	if(!best)
		return list()
	return list(copy(best, 1 + get_dist(here, best) / 10, null, list(fact)))
