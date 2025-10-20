///////////////////// Mob Living ///////////////////// //RS Add || Chomp Port
/mob/living
	var/list/vore_organs_reagents = list()	//Reagent datums in vore bellies in a mob
	var/receive_reagents = FALSE			//Pref for people to avoid others transfering reagents into them.
	var/give_reagents = FALSE				//Pref for people to avoid others taking reagents from them.
	var/vore_footstep_volume = 0			//Variable volume for a mob, updated every 5 steps where a footstep hasnt occurred.
	var/vore_footstep_chance = 0
	var/vore_footstep_volume_cooldown = 0	//goes up each time a step isnt heard, and will proc update of list of viable bellies to determine the most filled and loudest one to base audio on.

/mob/living/proc/check_vorefootstep(var/m_intent, var/turf/T)
	if(vore_footstep_volume_cooldown++ >= 5) //updating the 'dominating' belly, the one that has most liquid and is loudest.
		choose_vorefootstep()
		vore_footstep_volume_cooldown = 0

	if(!vore_footstep_volume || !vore_footstep_chance)	//Checking if there is actual sound if we run the proc
		return

	if(prob(vore_footstep_chance))	//Peform the check, lets see if we trigger a sound
		handle_vorefootstep(m_intent, T)


//Proc to choose the belly that has most liquid in it and is currently dominant for audio
/mob/living/proc/choose_vorefootstep()
	vore_organs_reagents = list()
	var/highest_vol = 0

	for(var/obj/belly/B in vore_organs)
		var/total_volume = B.reagents.total_volume
		vore_organs_reagents += total_volume

		if(B.vorefootsteps_sounds == TRUE && highest_vol < total_volume)
			highest_vol = total_volume

	if(highest_vol < 20)	//For now the volume will be off if less than 20 units of reagent are in vorebellies
		vore_footstep_volume = 0
		vore_footstep_chance = 0
	else					//Volume will start at least at 20 so theres more initial sound
		vore_footstep_volume = 20 + highest_vol * 4/5
		vore_footstep_chance = highest_vol/4

/mob/living/proc/vore_check_reagents()
	set name = "Check Belly Liquid (Vore)"
	set category = "Abilities"
	set desc = "Check the amount of liquid in your belly."

	var/obj/belly/RTB = input("Choose which vore belly to check") as null|anything in src.vore_organs
	if(!RTB)
		return FALSE

	to_chat(src, "<span class='notice'>[RTB] has [RTB.reagents.total_volume] units of liquid.</span>")

//
// Returns examine messages for how much reagents are in bellies
//
/mob/living/proc/examine_reagent_bellies()
	if(!show_pudge()) //Some clothing or equipment can hide this. Reagent inflation is not very different in this aspect.
		return ""

	var/message = ""
	for (var/belly in vore_organs)
		var/obj/belly/B = belly

		var/fill_percentage = B.reagents.maximum_volume > 0 ? B.reagents.total_volume / B.reagents.maximum_volume : 0

		if(0 <= fill_percentage && fill_percentage <= 0.2 && B.show_fullness_messages)
			message += B.get_reagent_examine_msg1()
		if(0.2 < fill_percentage && fill_percentage <= 0.4 && B.show_fullness_messages)
			message += B.get_reagent_examine_msg2()
		if(0.4 < fill_percentage && fill_percentage <= 0.6 && B.show_fullness_messages)
			message += B.get_reagent_examine_msg3()
		if(0.6 < fill_percentage && fill_percentage <= 0.8 && B.show_fullness_messages)
			message += B.get_reagent_examine_msg4()
		if(0.8 < fill_percentage && fill_percentage <= 1 && B.show_fullness_messages)
			message += B.get_reagent_examine_msg5()

	return message

/mob/proc/update_fullness(var/returning = FALSE)
	if(!returning)
		if(updating_fullness)
			return
		updating_fullness = TRUE
		spawn(2)
		updating_fullness = FALSE
		src.update_fullness(TRUE)
		return
	var/list/new_fullness = list()
	vore_fullness = 0
	for(var/belly_class in vore_icon_bellies)
		new_fullness[belly_class] = 0
	for(var/obj/belly/B as anything in vore_organs)
		if(DM_FLAG_VORESPRITE_BELLY & B.vore_sprite_flags)
			new_fullness[B.belly_sprite_to_affect] += B.GetFullnessFromBelly()
		/* //RS Removal - We don't have article voresprites
		if(istype(src, /mob/living/carbon/human) && DM_FLAG_VORESPRITE_ARTICLE & B.vore_sprite_flags)
			if(!new_fullness[B.undergarment_chosen])
				new_fullness[B.undergarment_chosen] = 1
			new_fullness[B.undergarment_chosen] += B.GetFullnessFromBelly()
			new_fullness[B.undergarment_chosen + "-ifnone"] = B.undergarment_if_none
			new_fullness[B.undergarment_chosen + "-color"] = B.undergarment_color
		*/
	for(var/belly_class in vore_icon_bellies)
		new_fullness[belly_class] /= size_multiplier //Divided by pred's size so a macro mob won't get macro belly from a regular prey.
		new_fullness[belly_class] *= belly_size_multiplier // Some mobs are small even at 100% size. Let's account for that.
		new_fullness[belly_class] = round(new_fullness[belly_class], 1) // Because intervals of 0.25 are going to make sprite artists cry.
		vore_fullness_ex[belly_class] = min(vore_capacity_ex[belly_class], new_fullness[belly_class])
		vore_fullness += new_fullness[belly_class]
	if(vore_fullness < 0)
		vore_fullness = 0
	vore_fullness = min(vore_capacity, vore_fullness)
	updating_fullness = FALSE
	return new_fullness
