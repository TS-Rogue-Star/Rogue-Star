///////////////////// Mob Living /////////////////////
/mob/living
	var/receive_reagents = FALSE	//Pref for people to avoid others transfering reagents into them.
	var/give_reagents = FALSE		//Pref for people to avoid others taking reagents from them.

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
