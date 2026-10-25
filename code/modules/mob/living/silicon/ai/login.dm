/mob/living/silicon/ai/Login()	//ThisIsDumb(TM) TODO: tidy this up �_� ~Carn
	..()
	for(var/obj/effect/rune/rune in rune_list)
		client.images += rune.blood_image
	if(stat != DEAD)
		for(var/obj/machinery/ai_status_display/O in machines) //change status
			O.mode = 1
			O.emotion = "Neutral"
			O.wake_processing() // RS Add: Station Display and Media Processing (Lira, October 2026)
	if(multicam_on)
		end_multicam()
	src.view_core()
	return