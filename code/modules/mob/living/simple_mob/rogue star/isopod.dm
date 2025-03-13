/////ISOPODS ARE OUR FRIENDS WE LOVE ISOPODS!!!/////
//RS FILE

/mob/living/simple_mob/vore/isopod
	name = "space isopod"
	desc = "A kind of hard shelled crustacean with many legs and a cute appearance. Known for helping break down decaying matter, and generally being friendly little guys!"
	icon = 'icons/rogue-star/mob_64x32.dmi'
	icon_living = "isopod"
	icon_state = "isopod"

	faction = "neutral"

	health = 1
	maxHealth = 1

	pixel_x = -16
	default_pixel_x = -16

	var/rolled_up_countdown = 0

	ai_holder_type = /datum/ai_holder/simple_mob/isopod

///// VORE RELATED /////
	vore_active = 1

	swallowTime = 2 SECONDS
	vore_capacity = 2
	vore_bump_chance = 5
	vore_bump_emote	= "greedily homms at"
	vore_digest_chance = 0
	vore_absorb_chance = 0
	vore_escape_chance = 10
	vore_pounce_chance = 5
	vore_ignores_undigestable = 0
	vore_default_mode = DM_SELECT
	vore_icons = SA_ICON_LIVING
	vore_stomach_name = "stomach"
	vore_stomach_flavor = ""
	vore_default_contamination_flavor = "Wet"
	vore_default_contamination_color = "grey"
	vore_default_item_mode = IM_DIGEST

	devourable = TRUE
	digestable = FALSE

/mob/living/simple_mob/vore/isopod/Life()
	. = ..()
	rolled_up_countdown --
	if(!ckey)
		if(resting && rolled_up_countdown <= 0)
			lay_down()

/mob/living/simple_mob/vore/isopod/adjustBruteLoss(amount, include_robo)
	if(amount >= 0)
		roll_up()

/mob/living/simple_mob/vore/isopod/adjustFireLoss(amount, include_robo)
	if(amount >= 0)
		roll_up()

/mob/living/simple_mob/vore/isopod/adjustOxyLoss(amount)
	if(amount >= 0)
		roll_up()

/mob/living/simple_mob/vore/isopod/adjustCloneLoss(amount)
	if(amount >= 0)
		roll_up()

/mob/living/simple_mob/vore/isopod/adjustBrainLoss(amount)
	if(amount >= 0)
		roll_up()

/mob/living/simple_mob/vore/isopod/adjustToxLoss(amount)
	if(amount >= 0)
		roll_up()

/mob/living/simple_mob/vore/isopod/adjustHalLoss(amount)
	if(amount >= 0)
		roll_up()

/mob/living/simple_mob/vore/isopod/death()
	roll_up()

/mob/living/simple_mob/vore/isopod/gib()
	roll_up()

/mob/living/simple_mob/vore/isopod/ex_act(severity)
	roll_up()

/mob/living/simple_mob/vore/isopod/lay_down()
	if(rolled_up_countdown > 0)
		to_chat(src, SPAN_DANGER("You can't unroll yet... it's not safe..."))
		return
	. = ..()

/mob/living/simple_mob/vore/isopod/proc/roll_up()
	health = maxHealth
	lay_down()
	rolled_up_countdown = rand(10,50)

/datum/ai_holder/simple_mob/isopod
	hostile = TRUE // The majority of simplemobs are hostile.
	retaliate = FALSE
	cooperative = FALSE

	wander = TRUE
	returns_home = FALSE

	var/item_search_cooldown = 0

/datum/ai_holder/simple_mob/isopod/handle_stance_strategical()
	to_world("[holder] - handle_stance_strategical")
	if(holder.resting)	//We are rolled up so don't do it!
		return
	if(holder.vore_fullness >= holder.vore_capacity)	//We are full so let's vibe
		return

	. = ..()

/datum/ai_holder/simple_mob/isopod/list_targets()
	to_world("[holder] - list_targets")
	if(isbelly(holder.loc))
		to_world("[holder] - is in a belly")
		var/obj/belly/B = holder.loc
		for(var/thing in B.contents)
			if(isobj(thing))
				return thing
			else if(ismob(thing))
				if(thing == holder)
					continue
				. += thing
	else
		if(world.time >= item_search_cooldown)	//Let's not look for items too often
			to_world("[holder] - try to search for item")
			item_search_cooldown = world.time + 10 SECONDS
			for(var/obj/item/I in view(holder, vision_range))
				if(I.anchored)	//If it's too heavy to lift then we can't eat it
					continue
				if(!(istype(I, /obj/item/weapon/reagent_containers/food) || istype(I, /obj/item/trash)))	//We only want food or trash
					continue
				. += I	//You left it out so it is mine
		else
			to_world("[holder] - search for mob")
			. = ohearers(vision_range, holder)	//Add mob nearby
	return .

/datum/ai_holder/simple_mob/isopod/find_target(list/possible_targets, has_targets_list)
	to_world("[holder] - find_target")
	ai_log("find_target() : Entered.", AI_LOG_TRACE)

	possible_targets = list_targets()

	for(var/possible_target in possible_targets)
		if(can_attack(possible_target)) // Can we attack it?
			. += possible_target

	var/new_target = pick_target(.)
	give_target(new_target)
	return new_target

/datum/ai_holder/simple_mob/isopod/can_attack(atom/movable/the_target, vision_required)
	to_world("[holder] - is thinking about if they can attack [the_target]")
	if(isliving(the_target))
		to_world("[holder] - [the_target] is living!")
		var/mob/living/L = the_target
		if(L.ckey || L.mind || L.client)
			return FALSE
		if(L.stat != DEAD)
			return FALSE
		if(L.faction == holder.faction)
			return FALSE
		if(!(L.devourable && L.digestable && L.allowmobvore))
			return FALSE
		return TRUE
	if(istype(the_target, /obj/item/weapon/reagent_containers/food) || istype(the_target, /obj/item/trash))
		to_world("[holder] - [the_target] is an object!")
		return TRUE
	to_world("[holder] - [the_target] is not valid!")
	return FALSE
