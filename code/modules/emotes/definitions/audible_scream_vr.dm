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
					"sound" = pick("sound/rogue-star/bau/bau1.ogg","sound/rogue-star/bau/bau2.ogg","sound/rogue-star/bau/bau3.ogg","sound/rogue-star/bau/bau4.ogg","sound/rogue-star/bau/bau5.ogg","sound/rogue-star/bau/bau6.ogg","sound/rogue-star/bau/bau7.ogg","sound/rogue-star/bau/bau8.ogg","sound/rogue-star/bau/bau9.ogg","sound/rogue-star/bau/bau10.ogg","sound/rogue-star/bau/bau11.ogg","sound/rogue-star/bau/bau12.ogg","sound/rogue-star/bau/bau13.ogg","sound/rogue-star/bau/bau14.ogg","sound/rogue-star/bau/bau15.ogg"),
					"vol" = emote_volume
				)
			if(5)
				return list(
					"sound" = pick("sound/voice/augh1.ogg","sound/voice/augh2.ogg"),
					"vol" = emote_volume
				)

	switch(H.species.name)
		if(SPECIES_VULPKANIN)
			return list(
				"sound" = pick("sound/rogue-star/bau/bau1.ogg","sound/rogue-star/bau/bau2.ogg","sound/rogue-star/bau/bau3.ogg","sound/rogue-star/bau/bau4.ogg","sound/rogue-star/bau/bau5.ogg","sound/rogue-star/bau/bau6.ogg","sound/rogue-star/bau/bau7.ogg","sound/rogue-star/bau/bau8.ogg","sound/rogue-star/bau/bau9.ogg","sound/rogue-star/bau/bau10.ogg","sound/rogue-star/bau/bau11.ogg","sound/rogue-star/bau/bau12.ogg","sound/rogue-star/bau/bau13.ogg","sound/rogue-star/bau/bau14.ogg","sound/rogue-star/bau/bau15.ogg"),
				"vol" = emote_volume
			)
		if("Wolpin")
			return list(
				"sound" = pick("sound/rogue-star/bau/bau1.ogg","sound/rogue-star/bau/bau2.ogg","sound/rogue-star/bau/bau3.ogg","sound/rogue-star/bau/bau4.ogg","sound/rogue-star/bau/bau5.ogg","sound/rogue-star/bau/bau6.ogg","sound/rogue-star/bau/bau7.ogg","sound/rogue-star/bau/bau8.ogg","sound/rogue-star/bau/bau9.ogg","sound/rogue-star/bau/bau10.ogg","sound/rogue-star/bau/bau11.ogg","sound/rogue-star/bau/bau12.ogg","sound/rogue-star/bau/bau13.ogg","sound/rogue-star/bau/bau14.ogg","sound/rogue-star/bau/bau15.ogg"),
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
