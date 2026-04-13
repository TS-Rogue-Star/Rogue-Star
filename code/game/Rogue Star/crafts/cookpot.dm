//RS FILE
//The cookpot is intended to be a very simple object that can intuitively work with existing heating methods.
//The hope is that this can allow one to process certain materials, or to cook simple but effective meals, such as soups, stews, and chili.
//Food cooked with this will ideally use a relatively small number of ingredients to make several portions.
//Rather than making specific foods, foods made with the cooking pot will probably just be a reagent slurry that you drink or eat from a bowl with a spoon.
//Tastes randomly of the ingredients that went into it, decently filling, made to fill you up, not fancy.

/obj/item/cookpot	//We're having stew tonight
	name = "cooking pot"
	desc = "A sturdy pot made for cooking in!"
	icon = 'icons/rogue-star/obj.dmi'
	icon_state = "pot"
	persist_storable = FALSE
	center_of_mass = list("x" = 19,"y" = 8)
	var/atom/cooksource

	var/top_heat = TRUE

/obj/item/cookpot/Initialize()
	. = ..()
	reagents = new/datum/reagents(600,src)

/obj/item/cookpot/examine(mob/user)
	. = ..()
	if(cooksource)
		. += SPAN_NOTICE("It is being heated by \the [cooksource].")
	if(contents.len == 0)
		if(reagents.total_volume == 0)
			. += SPAN_NOTICE("It is empty.")
			return

	else if(contents.len == 1)
		for(var/thing in src.contents)
			. += SPAN_NOTICE("You can see \the <span class='green'>[thing]</span> inside.")
	else
		var/msg = "You can see "
		var/iteration = 0
		for(var/thing in src.contents)
			iteration ++
			if(iteration == contents.len)
				msg += "and \the <span class='green'>[thing]</span> inside."
			else
				msg += "\the <span class='green'>[thing]</span>, "
		. += SPAN_NOTICE(msg)

	if(reagents.total_volume > 0)
		var/percent_full = round((reagents.total_volume / reagents.maximum_volume) * 100,1)
		if(user.skill_check(SKILL_COOKING))
			. += SPAN_OCCULT("It is [percent_full]% full.")
		else
			var/howmuch = ""
			switch(percent_full)
				if(100)
					howmuch = "full"
				if(90 to 99)
					howmuch = "almost full"
				if(61 to 89)
					howmuch = "over half full"
				if(40 to 60)
					howmuch = "around half full"
				if(26 to 39)
					howmuch = "over a quarter full"
				else
					howmuch = "almost empty"

			. += SPAN_OCCULT("It appears to be [howmuch].")
		var/liquid_percent = 0
		var/reagent_msg = "It seems to contain "
		var/iteration = 0
		var/hits = 0
		for(var/datum/reagent/thing in reagents.reagent_list)
			iteration ++
			if(thing.reagent_state == LIQUID)
				liquid_percent += thing.volume
			//RE-ENABLE THIS BEFORE YOU PR
//			if(!(istype(thing,/datum/reagent/drink) || istype(thing,/datum/reagent/nutriment)))
//				continue
			hits ++
			var/round_num = round(thing.volume,1)
			if(iteration == reagents.reagent_list.len)
				if(hits > 1)
					reagent_msg += "and [SPAN_OCCULT(round_num)] units of [SPAN_OCCULT(thing.name)]."
				else
					reagent_msg += "[SPAN_OCCULT(round_num)] units of [SPAN_OCCULT(thing.name)]."
			else
				reagent_msg += "[SPAN_OCCULT(round_num)] units of [SPAN_OCCULT(thing.name)], "

		if(iteration > 0)
			liquid_percent = round((liquid_percent / reagents.total_volume) * 100,1)
			if(user.skill_check(SKILL_COOKING))
				if(hits > 0)
					. += SPAN_NOTICE(reagent_msg)
				. += SPAN_NOTICE("It is comprised of [SPAN_OCCULT("[liquid_percent]%")] liquid.")
			else
				liquid_percent += rand(-10,10)
				switch(liquid_percent)
					if(100 to 110)
						. += SPAN_NOTICE("It seems like it's only liquid...")
					if(51 to 110)
						. += SPAN_OCCULT("It's mostly liquid.")
					if(35 to 50)
						. += SPAN_OCCULT("It's pretty runny.")
					if(16 to 34)
						. += SPAN_OCCULT("It moves freely.")
					if(5 to 15)
						. += SPAN_OCCULT("It seems sticky.")
					if(1 to 5)
						. += SPAN_OCCULT("It seems very sticky.")
					else
						. += SPAN_DANGER("It seems rather dry.")

/obj/item/cookpot/proc/functional()
	if(!isturf(src.loc))	//If we're not on the ground then we're not cooking!
		unregister_cooksource()
		return FALSE
	if(cooksource)	//We have a cooksource, but we need to be on the same turf as it to work
		if(loc == cooksource.loc)
			if(is_cooksource_working())
				return TRUE
		unregister_cooksource()	//We have a cooksource but we're not on the same tile so our cooksource is no longer valid!
	var/turf/T = get_turf(src)
	for(var/thing in T.contents)	//Let's check the turf to see if we can find a cooksource
		if(is_cooksource_working(thing))
			register_cooksource(thing)
			break

	if(cooksource)
		return TRUE
	return FALSE

/obj/item/cookpot/proc/is_cooksource_working(var/atom/cooker)
	if(!cooker)
		if(!cooksource)
			return FALSE
		cooker = cooksource
	if(istype(cooker,/obj/structure/bonfire))
		var/obj/structure/bonfire/B = cooker
		if(B.burning)
			return TRUE
	if(istype(cooker,/obj/machinery/appliance/cooker/grill))
		var/obj/machinery/appliance/cooker/grill/G = cooker
		if(!G.stat)
			return TRUE
	return FALSE

/obj/item/cookpot/proc/cook()
	if(dehydrate())
		new /obj/particle_emitter/smelly(src.loc)
		process_reagents()
	else
		burn()

	var/atom/A
	if(contents.len > 0)
		A = pick(contents)
		if(A)
			if(istype(A,/obj/item/weapon/reagent_containers))
				A.reagents.trans_to_obj(src,temp_based_reagent_calc())
				if(A.reagents.total_volume == 0)
					qdel(A)
					new /obj/particle_emitter/smelly(src.loc)

			if(istype(A,/obj/item/weapon/bone) || istype(A,/obj/item/weapon/digestion_remains/organic))
				broth(A)

/obj/item/cookpot/proc/dehydrate()
	var/datum/reagent/water/W = reagents.get_reagent("water")
	if(W?.volume > 0)
		reagents.remove_reagent("water",1)
		return TRUE
	var/datum/reagent/nutriment/broth/B = reagents.get_reagent("broth")
	if(B?.volume > 0)
		reagents.remove_reagent("broth",0.1)
		return TRUE
	return FALSE

/obj/item/cookpot/proc/burn()
	var/datum/reagents/R = new /datum/reagents()
	var/howmuch = 1
	if(high_heat())
		howmuch = 5
	howmuch = reagents.trans_to_holder(R,howmuch)
	reagents.add_reagent("slop",howmuch * 0.1)

/obj/item/cookpot/proc/broth(var/obj/item/bone)
	var/datum/reagent/water/W = reagents.get_reagent("water")
	if(!W)
		return
	var/howmuch = W.volume
	if(howmuch > 20)
		howmuch = 20
	reagents.remove_reagent("water",howmuch)
	reagents.add_reagent("broth",howmuch / 4)
	playsound(src,pick(list('sound/effects/bubbles.ogg','sound/effects/bubbles2.ogg')),50,1)
	if(bone)
		if(istype(bone,/obj/item/weapon/digestion_remains/organic))
			var/datum/reagent/B = reagents.get_reagent("broth")
			B.player_sourced = TRUE
		if(isnull(bone.health))
			if(istype(bone,/obj/item/weapon/bone))
				bone.health = -10
			else
				bone.health = 0
		else
			bone.health += rand(0,1)
			if(prob(bone.health))
				playsound(src, "fracture", 50, 1)
				qdel(bone)
				new /obj/particle_emitter/smelly(src.loc)
				reagents.add_reagent("calcium",rand(1,2))

/obj/item/cookpot/proc/process_reagents()
	for(var/datum/reagent/R in reagents.reagent_list)
		R.cookpot_interact()

/obj/item/cookpot/proc/high_heat()
	#warn REPLACE THE high_heat PROC
	return top_heat

/obj/item/cookpot/proc/register_cooksource(var/atom/oursource)
	if(cooksource)
		unregister_cooksource()
	cooksource = oursource
	RegisterSignal(cooksource, COMSIG_PARENT_QDELETING, PROC_REF(unregister_cooksource))
	START_PROCESSING(SSobj,src)

/obj/item/cookpot/proc/unregister_cooksource()
	if(cooksource)
		UnregisterSignal(cooksource, COMSIG_PARENT_QDELETING)
		cooksource = null

/obj/item/cookpot/proc/temp_based_reagent_calc()
	#warn REPLACE THE temp_based_reagent_calc PROC BEFORE YOU PR THIS DUMBASS
	return 50

/obj/item/cookpot/Destroy()
	unregister_cooksource()
	. = ..()

/obj/item/cookpot/process()
	if(!functional())
		STOP_PROCESSING(SSobj,src)
		return
	cook()

/obj/item/cookpot/attackby(obj/item/weapon/W, mob/user)
	if(istype(W,/obj/item/fat) || istype(W,/obj/item/weapon/reagent_containers/food/snacks) || istype(W,/obj/item/weapon/bone) || istype(W,/obj/item/weapon/digestion_remains/organic))
		if(contents.len >= 6)
			to_chat(user,SPAN_DANGER("It's too full just now, wait for whatever is inside to cook down, or remove things from it first."))
			return
		user.remove_from_mob(W)
		W.forceMove(src)
		user.visible_message(SPAN_NOTICE("\The [user] adds \the [W] to \the [src]."),SPAN_NOTICE("You add \the [W] to \the [src]."),runemessage = "plonk")
		return
	if(istype(W,/obj/item/weapon/reagent_containers))
		var/obj/item/weapon/reagent_containers/R = W
		var/howmuch = "some"
		if(R.reagents.total_volume == 0)	//If the container is empty, then you are probably trying to collect some yummers!!!
			if(reagents.total_volume == 0)
				to_chat(user,SPAN_DANGER("\The [src] is empty..."))
				return
			if(user.skill_check(SKILL_COOKING))
				if(reagents.total_volume < R.reagents.maximum_volume)
					howmuch = reagents.total_volume
				else
					howmuch = R.reagents.maximum_volume
				howmuch = "[howmuch] units"
			user.visible_message(SPAN_NOTICE("\The [user] fills \the [R] from \the [src]."),SPAN_NOTICE("You fill your [R] with [howmuch] of \the [src]'s contents."),runemessage = "gloop")
			reagents.trans_to_obj(R,R.reagents.maximum_volume)
			return
		//If the container is not empty, then we will pour its contents into the pot!!! Don't poison my stew please...
		if(reagents.total_volume >= reagents.maximum_volume)
			to_chat(user,SPAN_DANGER("It's too full just now, wait for whatever is inside to cook down, or remove things from it first."))
			return
		if(user.skill_check(SKILL_COOKING))
			if(R.reagents.total_volume < R.amount_per_transfer_from_this)
				howmuch = R.reagents.total_volume
			else
				howmuch = R.amount_per_transfer_from_this
			howmuch = "[howmuch] units"
		R.reagents.trans_to_obj(src,R.amount_per_transfer_from_this)
		user.visible_message(SPAN_NOTICE("\The [user] pours something from \the [R] into \the [src]."),SPAN_NOTICE("You pour [howmuch] from \the [R] into \the [src]."),runemessage = "gloop")

	if(istype(W,/obj/item/weapon/holder/micro))
		var/obj/item/weapon/holder/micro/M = W
		#warn FIGURE OUT WHAT TO DO WITH MICRO HOLDERS

/obj/item/cookpot/resolve_attackby(atom/A, mob/user, attack_modifier, click_parameters)
	. = ..()

	if(istype(A,/obj/machinery/appliance/cooker/grill) || istype(A,/obj/structure/bonfire))
		user.remove_from_mob(src)
		forceMove(A.loc)
		auto_align(src, click_parameters)
		functional()

/datum/cookpot_meal
	var/list/flavors = list()
	var/nutriment_total = 0

/datum/reagent/nutriment/broth
	name = "broth"
	id = "broth"
	taste_description = "savory broth"
	description = "A broth of water infused with some kind of meat, sometimes formed by boiling animal bones in your cooking!"
	reagent_state = LIQUID
	color = "#e0a15977"

	glass_name = "broth"
	glass_desc = "It's like soup but without anything in it!"
	cup_name = "broth"
	cup_desc = "A steaming cup of savory goodness!"

	nutriment_factor = 5

/datum/reagent/carbon/slop
	id = "slop"
	taste_description = "bitter"
	description = "The bitter, charred remains of something... "
	color = "#222222ff"
	taste_mult = 10

/datum/reagent
	var/player_sourced = FALSE	//If this reagent is made from or out of any part of any player's body. If true then maybe some preferences can happen

/datum/reagent/proc/cookpot_interact()
	return

/datum/reagent/carbon/cookpot_interact()
	for(var/datum/reagent/R in holder.reagent_list)
		if(istype(R,/datum/reagent/carbon))
			continue
		if(istype(R,/datum/reagent/nutriment) || istype(R,/datum/reagent/drink))
			continue
		holder.remove_reagent(R.id,5)
		break
	holder.remove_reagent(src.id,rand(0,1))
