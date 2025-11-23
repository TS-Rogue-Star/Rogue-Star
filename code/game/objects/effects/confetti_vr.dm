/obj/effect/effect/sparks/confetti
	name = "confetti"
	icon = 'icons/effects/effects_vr.dmi'
	icon_state = "confetti"
	spark_sound = null	//RS ADD - almost everything that calls for confetti makes a sound itself, and the confetti sound was broken anyway, and playing a sound like 10+ times when confetti spawns sounds terrible, SO, the confetti is silent.

/datum/effect/effect/system/confetti_spread
	var/total_sparks = 0 // To stop it being spammed and lagging!

/datum/effect/effect/system/confetti_spread/set_up(n = 3, c = 0, loca)
	if(n > 10)
		n = 10
	number = n
	cardinals = c
	if(istype(loca, /turf/))
		location = loca
	else
		location = get_turf(loca)

/datum/effect/effect/system/confetti_spread/start()
	var/i = 0
	for(i=0, i<src.number, i++)
		if(src.total_sparks > 20)
			return
		spawn(0)
			if(holder)
				src.location = get_turf(holder)
			var/obj/effect/effect/sparks/confetti = new /obj/effect/effect/sparks/confetti(src.location)
			src.total_sparks++
			var/direction
			if(src.cardinals)
				direction = pick(cardinal)
			else
				direction = pick(alldirs)
			for(i=0, i<pick(1,2,3), i++)
				sleep(5)
				step(confetti,direction)
			spawn(20)
				src.total_sparks--
