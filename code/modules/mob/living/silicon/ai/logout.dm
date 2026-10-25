/mob/living/silicon/ai/Logout()
	..()
	for(var/obj/machinery/ai_status_display/O in machines) //change status
		O.mode = 0
		O.wake_processing() // RS Add: Station Display and Media Processing (Lira, October 2026)
	if(!isturf(loc))
		if (client)
			client.eye = loc
			client.perspective = EYE_PERSPECTIVE
	src.view_core()
	return