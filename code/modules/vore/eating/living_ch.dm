///////////////////// Mob Living /////////////////////
/mob/living
	var/list/vore_organs_reagents = list()	//Reagent datums in vore bellies in a mob
	var/receive_reagents = FALSE			//Pref for people to avoid others transfering reagents into them.
	var/give_reagents = FALSE				//Pref for people to avoid others taking reagents from them.
	var/vore_footstep_volume = 0			//Variable volume for a mob, updated every 5 steps where a footstep hasnt occurred.
	var/vore_footstep_chance = 0
	var/vore_footstep_volume_cooldown = 0	//goes up each time a step isnt heard, and will proc update of list of viable bellies to determine the most filled and loudest one to base audio on.

mob/living/proc/check_vorefootstep(var/m_intent, var/turf/T)
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


//
// Returns examine messages for how much reagents are in bellies
//
/mob/living/proc/examine_reagent_bellies()
	if(!show_pudge()) //Some clothing or equipment can hide this. Reagent inflation is not very different in this aspect.
		return ""

	var/message = ""
	for (var/belly in vore_organs)
		var/obj/belly/B = belly

		if(0 <= B.reagents.total_volume && B.reagents.total_volume <= 20 && B.liquid_fullness1_messages)
			message += B.get_reagent_examine_msg1()
		if(20 < B.reagents.total_volume && B.reagents.total_volume <= 40 && B.liquid_fullness2_messages)
			message += B.get_reagent_examine_msg2()
		if(40 < B.reagents.total_volume && B.reagents.total_volume <= 60 && B.liquid_fullness3_messages)
			message += B.get_reagent_examine_msg3()
		if(60 < B.reagents.total_volume && B.reagents.total_volume <= 80 && B.liquid_fullness4_messages)
			message += B.get_reagent_examine_msg4()
		if(80 < B.reagents.total_volume && B.reagents.total_volume <= 100 && B.liquid_fullness5_messages)
			message += B.get_reagent_examine_msg5()

	return message
