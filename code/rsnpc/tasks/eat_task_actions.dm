/datum/npc_action/fetch
	name = "fetch"
	var/from
	var/obj/item/thing
	var/exact_item = FALSE
	var/obj/place
	var/phase = 0
	var/was_locked = FALSE
	var/opened_it = FALSE
	var/vend_until = 0

/datum/npc_action/fetch/variants(datum/ai_holder/rsnpc/ai_mind, fact)
	if(findtext(fact, "holding:") == 1)
		var/obj/item/I = locate(copytext(fact, 9))
		if(!istype(I) || QDELETED(I) || !(I in ai_mind.holder.get_contents()))
			return list()
		var/datum/npc_action/fetch/A = copy(null, 2, null, list(fact))
		A.want = I.type
		A.from = NPC_SOURCE_HELD
		A.thing = I
		A.exact_item = TRUE
		A.name = "fetch [I]"
		A.key = "[A.key]:\ref[I]"
		return list(A)
	if(findtext(fact, "have:") != 1)
		return list()
	var/kind = text2path(copytext(fact, 6))
	if(!kind)
		return list()
	var/datum/npc_source/S = ai_mind.npc_search(kind, CALLBACK(src, PROC_REF(not_crossed_off), ai_mind, kind))
	if(!S)
		return list()
	var/cost = 2 + S.cost / 10
	if(S.from == NPC_SOURCE_KEPT)
		cost += 3
	var/datum/npc_action/fetch/A = copy(S.from == NPC_SOURCE_HELD ? null : S.place, cost, null, list(fact))
	A.want = kind
	A.from = S.from
	A.thing = S.thing
	var/obj/item/K = kind
	A.name = "fetch [initial(K.name)]"
	A.key = "[A.key]:[kind]"
	return list(A)

/datum/npc_action/fetch/proc/not_crossed_off(datum/ai_holder/rsnpc/ai_mind, want, kind, turf/place, atom/thing)
	return npc_worth_taking(want, kind, thing) && !ai_mind.crossed_off("act:[type]@\ref[place]:[want]")

/datum/npc_action/fetch/arrive(datum/ai_holder/rsnpc/ai_mind)
	if(from != NPC_SOURCE_KEPT)
		return TRUE
	var/turf/T = target
	for(var/obj/O in T)
		if(istype(O, /obj/structure/closet) || istype(O, /obj/machinery/vending) || istype(O, /obj/item/weapon/storage))
			place = O
			return TRUE
	why = "the cupboard is gone"
	return FALSE

/datum/npc_action/fetch/run_action(datum/ai_holder/rsnpc/ai_mind)
	if(exact_item && (QDELETED(thing) || !(thing in ai_mind.holder.get_contents())))
		why = "it's not there any more"
		return NPC_NOT_THERE
	if(exact_item ? ai_mind.holder.item_is_in_hands(thing) : ai_mind.held_item(want))
		return NPC_DONE
	if(!ai_mind.holder.checkClickCooldown())
		return NPC_RUNNING
	if(istype(place, /obj/structure/closet))
		return from_closet(ai_mind)
	if(istype(place, /obj/machinery/vending))
		return from_vendor(ai_mind)
	var/obj/item/I = thing
	if(QDELETED(I) || !istype(I, want) || (from != NPC_SOURCE_HELD && get_turf(I) != get_turf(target)))
		I = npc_find_at(get_turf(target), want)
	if(!I)
		why = "it's not there any more"
		return NPC_NOT_THERE
	if(from == NPC_SOURCE_HELD && !ai_mind.in_reach(I) && isitem(I.loc) && ai_mind.in_reach(I.loc))
		var/obj/item/box = I.loc
		if(!ai_mind.holder.item_is_in_hands(box) && !ai_mind.take(box))
			why = "couldn't get [box] out"
			return NPC_NOT_YET
		return NPC_RUNNING
	if(!ai_mind.take(I))
		why = "couldn't take [I]"
		return NPC_NOT_YET
	return NPC_DONE

/datum/npc_action/fetch/proc/from_closet(datum/ai_holder/rsnpc/ai_mind)
	var/obj/structure/closet/C = place
	var/obj/structure/closet/secure_closet/S = C
	switch(phase)
		if(0)
			phase = 1
			if(!C.opened && istype(S) && S.locked)
				was_locked = TRUE
				ai_mind.use_hand(C)
				if(S.locked)
					why = "it's locked"
					return NPC_CANT_DO
			return NPC_RUNNING
		if(1)
			phase = 2
			if(!C.opened)
				ai_mind.use_hand(C)
				if(!C.opened)
					why = "it won't open"
					return NPC_CANT_DO
				opened_it = TRUE
			return NPC_RUNNING
	var/obj/item/I = npc_find_at(get_turf(C), want)
	if(!I)
		why = "none in [C]"
		ai_mind.look()
		return NPC_NOT_THERE
	if(!ai_mind.take(I))
		why = "couldn't take [I]"
		return NPC_NOT_YET
	return NPC_DONE

/datum/npc_action/fetch/proc/from_vendor(datum/ai_holder/rsnpc/ai_mind)
	var/obj/machinery/vending/V = place
	if(vend_until)
		var/obj/item/I = locate(want) in get_turf(V)
		if(I)
			return ai_mind.take(I) ? NPC_DONE : NPC_NOT_YET
		if(world.time > vend_until)
			why = "nothing came out"
			return NPC_NOT_YET
		return NPC_RUNNING
	for(var/datum/stored_item/vending_product/R as anything in V.product_records)
		if(R.category != CAT_NORMAL || !R.amount || !ispath(R.item_path, want))
			continue
		var/old_usr = usr
		usr = ai_mind.holder
		var/bought = V.purchase(R, ai_mind.holder)
		usr = old_usr
		ai_mind.holder.setClickCooldown(DEFAULT_QUICK_COOLDOWN)
		if(!bought)
			why = "couldn't buy it"
			return NPC_CANT_DO
		vend_until = world.time + V.vend_delay + 5 SECONDS
		return NPC_RUNNING
	why = "none in [V]"
	return NPC_NOT_THERE

/datum/npc_action/fetch/clean_up(datum/ai_holder/rsnpc/ai_mind)
	var/obj/structure/closet/C = place
	if(!istype(C) || !opened_it || !C.opened || !C.Adjacent(ai_mind.holder) || get_turf(C) == get_turf(ai_mind.holder))
		return
	C.close()
	if(was_locked && istype(C, /obj/structure/closet/secure_closet))
		var/obj/structure/closet/secure_closet/S = C
		S.togglelock(ai_mind.holder)
	opened_it = FALSE

/datum/npc_action/eat
	name = "eat"
	var/bites = 0

/datum/npc_action/eat/variants(datum/ai_holder/rsnpc/ai_mind, fact)
	if(fact != NPC_FACT_FED)
		return list()
	return list(copy(null, 1, list(NPC_FACT_HAVE(/obj/item/weapon/reagent_containers/food/snacks), NPC_FACT_MOUTH_FREE), list(NPC_FACT_FED)))

/datum/npc_action/eat/run_action(datum/ai_holder/rsnpc/ai_mind)
	var/mob/living/carbon/human/H = ai_mind.holder
	if(ai_mind.need_pressure(NPC_NEED_HUNGER) <= 0)
		return NPC_DONE
	var/obj/item/weapon/reagent_containers/food/snacks/F = ai_mind.held_item(/obj/item/weapon/reagent_containers/food/snacks)
	if(!F)
		if(bites)
			return NPC_DONE
		why = "nothing to eat"
		return NPC_NOT_THERE
	if(!H.checkClickCooldown())
		return NPC_RUNNING
	if(istype(H) && H.check_mouth_coverage())
		why = "mouth covered"
		return NPC_CANT_DO
	var/old_usr = usr
	usr = H
	if(F.package || F.canned)
		F.attack_self(H)
	else
		F.attack(H, H)
		bites++
	usr = old_usr
	return NPC_RUNNING

/datum/npc_action/uncover_mouth
	name = "uncover my mouth"

/datum/npc_action/uncover_mouth/variants(datum/ai_holder/rsnpc/ai_mind, fact)
	var/mob/living/carbon/human/H = ai_mind.holder
	var/turf/T = get_turf(H)
	if(fact != NPC_FACT_MOUTH_FREE || !istype(H) || !T || npc_air_bad(T, H))
		return list()
	return list(copy(null, 1, null, list(fact)))

/datum/npc_action/uncover_mouth/run_action(datum/ai_holder/rsnpc/ai_mind)
	var/mob/living/carbon/human/H = ai_mind.holder
	var/obj/item/I = H.check_mouth_coverage()
	if(!I)
		return NPC_DONE
	var/turf/T = get_turf(H)
	if(!T || npc_air_bad(T, H))
		why = "the air here is bad"
		return NPC_CANT_DO
	if(!H.checkClickCooldown())
		return NPC_RUNNING
	if(!H.item_is_in_hands(I) && !ai_mind.take_off(I))
		why = "couldn't take off [I]"
		return NPC_NOT_YET
	NPC_TRACE(ai_mind, NPC_TRACE_HANDS, "took off [I]")
	ai_mind.put_away(I)
	return NPC_RUNNING

/datum/npc_action/drink
	name = "drink"
	var/sips = 0

/datum/npc_action/drink/variants(datum/ai_holder/rsnpc/ai_mind, fact)
	if(fact != NPC_FACT_DRANK)
		return list()
	return list(copy(null, 1, list(NPC_FACT_HAVE(/obj/item/weapon/reagent_containers/food/drinks), NPC_FACT_MOUTH_FREE), list(NPC_FACT_DRANK)))

/datum/npc_action/drink/run_action(datum/ai_holder/rsnpc/ai_mind)
	var/mob/living/carbon/human/H = ai_mind.holder
	var/obj/item/weapon/reagent_containers/food/drinks/D = ai_mind.held_item(/obj/item/weapon/reagent_containers/food/drinks)
	if(sips >= 3 || (sips && (!D || !D.reagents?.total_volume)))
		ai_mind.note("drank", "[D || "a drink"]", 5 MINUTES)
		var/datum/npc_need/N = ai_mind.needs[NPC_NEED_REST]
		N?.add(10)
		return NPC_DONE
	if(!D)
		why = "nothing to drink"
		return NPC_NOT_THERE
	if(!D.reagents?.total_volume)
		why = "[D] is empty"
		return NPC_CANT_DO
	if(!H.checkClickCooldown())
		return NPC_RUNNING
	if(istype(H) && H.check_mouth_coverage())
		why = "mouth covered"
		return NPC_CANT_DO
	var/old_usr = usr
	usr = H
	if(!D.is_open_container())
		D.attack_self(H)
	else
		D.attack(H, H)
		sips++
	usr = old_usr
	return NPC_RUNNING
