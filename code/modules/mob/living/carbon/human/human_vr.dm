//Crazy alternate human stuff
/mob/living/carbon/human/New()
	. = ..()

	var/animal = pick("cow","chicken_brown", "chicken_black", "chicken_white", "chick", "mouse_brown", "mouse_gray", "mouse_white", "lizard", "cat2", "goose", "penguin")
	var/image/img = image('icons/mob/animal.dmi', src, animal)
	img.override = TRUE
	add_alt_appearance("animals", img, displayTo = alt_farmanimals)


/mob/living/carbon/human/Destroy()
	alt_farmanimals -= src

	. = ..()


/mob/living/carbon/human/init_vore()
	. = ..()
	
	//Something else made a NIF meanwhile
	if(nif)
		return TRUE

	//We'll load our client's organs if we have one
	if(client?.prefs_vr?.nif_type)
		var/datum/vore_preferences/prefs_vr = client.prefs_vr
		if(prefs_vr.died_with_nif)
			tgui_alert_async(src, "You appear to have not survived last round, and had a NIF, so you are not spawning with it this round. If you think this is in error, contact an admin.", "NIF Loss")
			prefs_vr.nif_type = null
			prefs_vr.died_with_nif = FALSE
		else
			new prefs_vr.nif_type(src,prefs_vr.nif_health,prefs_vr.nif_savedata)
			