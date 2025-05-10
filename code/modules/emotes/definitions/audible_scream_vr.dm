/decl/emote/audible/scream/get_emote_sound(var/atom/user)
	if(!ishuman(user))	//RS EDIT START
		return ..()

	var/mob/living/carbon/human/H = user
	if(H.client)
		switch(H.client.prefs.screamsound)
			if(1)
				return list(
					"sound" = pick("sound/screams/f1.ogg","sound/screams/f2.ogg","sound/screams/f3.ogg","sound/screams/f4.ogg","sound/screams/f5.ogg","sound/screams/f6.ogg","sound/screams/f7.ogg","sound/screams/f8.ogg","sound/screams/f9.ogg","sound/screams/f10.ogg","sound/screams/f11.ogg","sound/screams/f12.ogg","sound/screams/f13.ogg","sound/screams/f14.ogg","sound/screams/f15.ogg"),
					"vol" = emote_volume
				)
			if(2)
				return list(
					"sound" = pick("sound/screams/m1.ogg","sound/screams/m2.ogg","sound/screams/m3.ogg","sound/screams/m4.ogg","sound/screams/m5.ogg","sound/screams/m6.ogg","sound/screams/m7.ogg","sound/screams/m8.ogg","sound/screams/m9.ogg","sound/screams/m10.ogg","sound/screams/m11.ogg","sound/screams/m12.ogg","sound/screams/m13.ogg","sound/screams/m14.ogg","sound/screams/m15.ogg","sound/screams/m16.ogg","sound/screams/m17.ogg"),
					"vol" = emote_volume
				)
			if(3)
				return
			if(4)
				return list(
					"sound" = pick("sound/screams/bau1.ogg","sound/screams/bau2.ogg","sound/screams/bau3.ogg","sound/screams/bau4.ogg","sound/screams/bau5.ogg","sound/screams/bau6.ogg","sound/screams/bau7.ogg","sound/screams/bau8.ogg","sound/screams/bau9.ogg","sound/screams/bau10.ogg","sound/screams/bau11.ogg","sound/screams/bau12.ogg","sound/screams/bau13.ogg","sound/screams/bau14.ogg","sound/screams/bau15.ogg"),
					"vol" = emote_volume
				)

	switch(H.species.name)
		if(SPECIES_VULPKANIN)
			return list(
				"sound" = pick("sound/screams/bau1.ogg","sound/screams/bau2.ogg","sound/screams/bau3.ogg","sound/screams/bau4.ogg","sound/screams/bau5.ogg","sound/screams/bau6.ogg","sound/screams/bau7.ogg","sound/screams/bau8.ogg","sound/screams/bau9.ogg","sound/screams/bau10.ogg","sound/screams/bau11.ogg","sound/screams/bau12.ogg","sound/screams/bau13.ogg","sound/screams/bau14.ogg","sound/screams/bau15.ogg"),
				"vol" = emote_volume
			)
		if("Wolpin")
			return list(
				"sound" = pick("sound/screams/bau1.ogg","sound/screams/bau2.ogg","sound/screams/bau3.ogg","sound/screams/bau4.ogg","sound/screams/bau5.ogg","sound/screams/bau6.ogg","sound/screams/bau7.ogg","sound/screams/bau8.ogg","sound/screams/bau9.ogg","sound/screams/bau10.ogg","sound/screams/bau11.ogg","sound/screams/bau12.ogg","sound/screams/bau13.ogg","sound/screams/bau14.ogg","sound/screams/bau15.ogg"),
				"vol" = emote_volume
			)


	if(H.get_gender() == FEMALE)
		return list(
			"sound" = pick("sound/screams/f1.ogg","sound/screams/f2.ogg","sound/screams/f3.ogg","sound/screams/f4.ogg","sound/screams/f5.ogg","sound/screams/f6.ogg","sound/screams/f7.ogg","sound/screams/f8.ogg","sound/screams/f9.ogg","sound/screams/f10.ogg","sound/screams/f11.ogg","sound/screams/f12.ogg","sound/screams/f13.ogg","sound/screams/f14.ogg","sound/screams/f15.ogg"),
			"vol" = emote_volume
		)
	else
		return list(
			"sound" = pick("sound/screams/m1.ogg","sound/screams/m2.ogg","sound/screams/m3.ogg","sound/screams/m4.ogg","sound/screams/m5.ogg","sound/screams/m6.ogg","sound/screams/m7.ogg","sound/screams/m8.ogg","sound/screams/m9.ogg","sound/screams/m10.ogg","sound/screams/m11.ogg","sound/screams/m12.ogg","sound/screams/m13.ogg","sound/screams/m14.ogg","sound/screams/m15.ogg","sound/screams/m16.ogg","sound/screams/m17.ogg"),
			"vol" = emote_volume
		)
	//RS EDIT END
