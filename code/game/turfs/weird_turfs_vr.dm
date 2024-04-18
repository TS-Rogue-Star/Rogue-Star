/turf/simulated/floor/weird_things
	icon = 'icons/turf/flooring/weird_vr.dmi'

/turf/simulated/floor/weird_things/dark
	name = "dark"
	desc = "It's a strange, impenetrable darkness."
	icon_state = "dark"
	can_dirty = FALSE

/turf/simulated/floor/weird_things/dark/Initialize(mapload)
	. = ..()
	if(prob(5))
		add_glow()

/turf/simulated/floor/weird_things/dark/Crossed(O)
	. = ..()
	if(!isliving(O))
		return
	cut_overlays()
	if(prob(5))
		add_glow()
	if(istype(O, /mob/living/carbon/human))
		var/mob/living/carbon/human/L = O
		if(istype(L.species, /datum/species/crew_shadekin))
			L.halloss += 5
			if(prob(50))
				to_chat(L, "<span class='danger'>The more you move through this darkness, the more you can feel a throbbing, shooting ache in your bones.</span>")
			if(prob(5))
				L.visible_message("[L]'s body gives off a faint, sparking, haze...", "Your body gives off a faint, sparking, haze...", runemessage = "gives off a faint, sparking haze")
		else if(istype(L.species, /datum/species/shadekin))
			var/obj/item/organ/internal/brain/shadekin/B = L.internal_organs_by_name["brain"]
			B.dark_energy += 10
			if(prob(10))
				to_chat(L, "<span class='notice'>You can feel the energy flowing into you!</span>")
		else
			if(prob(0.25))
				to_chat(L, "<span class='danger'>The darkness seethes under your feet...</span>")
				L.hallucination += 50

/turf/simulated/floor/weird_things/dark/proc/add_glow()
	var/choice = "overlay-[rand(1,6)]"
	var/image/i = image('icons/turf/flooring/weird_vr.dmi', choice)
	i.plane = PLANE_LIGHTING_ABOVE
	add_overlay(i)

/turf/simulated/floor/weird_things/dark/ChangeTurf()
	cut_overlays()
	return ..()		//RS EDIT

/turf/unsimulated/wall/dark
	name = "dark"
	desc = "It's a strange, impenetrable darkness."
	icon = 'icons/turf/flooring/weird_vr.dmi'
	icon_state = "dark"

/turf/unsimulated/wall/dark/Initialize(mapload)
	. = ..()
	if(prob(5))
		add_glow()
	var/image/i = image('icons/turf/flooring/weird_vr.dmi', "dark-w")	//RS EDIT START
	i.plane = PLANE_BUILDMODE
	add_overlay(i)		//RS EDIT END

/turf/unsimulated/wall/dark/proc/add_glow()
	var/choice = "overlay-[rand(1,6)]"
	var/image/i = image('icons/turf/flooring/weird_vr.dmi', choice)
	i.plane = PLANE_LIGHTING_ABOVE
	add_overlay(i)

/turf/unsimulated/wall/dark/ChangeTurf()
	cut_overlays()		//RS EDIT
	return ..()			//RS EDIT

/turf/unsimulated/floor/dark
	name = "dark"
	desc = "It's a strange, impenetrable darkness."
	icon = 'icons/turf/flooring/weird_vr.dmi'
	icon_state = "dark-w"	//RS EDIT

/turf/unsimulated/floor/dark/Initialize(mapload)
	. = ..()
	icon_state = "dark"	//RS EDIT
	if(prob(5))
		add_glow()

/turf/unsimulated/floor/dark/Crossed(O)
	. = ..()
	if(!isliving(O))
		return
	cut_overlays()
	add_glow()	//RS EDIT
	if(istype(O, /mob/living/carbon/human))
		var/mob/living/carbon/human/L = O
		if(istype(L.species, /datum/species/crew_shadekin))
			L.halloss += 5
			if(prob(50))
				cut_overlays()	//RS EDIT
				to_chat(L, "<span class='danger'>The more you move through this darkness, the more you can feel a throbbing, shooting ache in your bones.</span>")
			if(prob(5))
				L.visible_message("[L]'s body gives off a faint, sparking, haze...", "Your body gives off a faint, sparking, haze...", runemessage = "gives off a faint, sparking haze")
		else if(istype(L.species, /datum/species/shadekin))
			cut_overlays()	//RS EDIT
			var/obj/item/organ/internal/brain/shadekin/B = L.internal_organs_by_name["brain"]
			B.dark_energy += 10
			if(prob(10))
				to_chat(L, "<span class='notice'>You can feel the energy flowing into you!</span>")
		else
			if(prob(0.25))
				to_chat(L, "<span class='danger'>The darkness seethes under your feet...</span>")
				L.hallucination += 50

/turf/unsimulated/floor/dark/proc/add_glow()
	if(prob(33))	//RS EDIT START
		var/choice = "overlay-[rand(1,12)]"
		var/image/i = image('icons/turf/flooring/weird_vr.dmi', choice)
		i.plane = PLANE_LIGHTING_ABOVE
		add_overlay(i)
	if(prob(33))
		var/choiceb = "static-[rand(1,6)]"
		var/image/ii = image('icons/turf/flooring/weird_vr.dmi', choiceb)
		ii.plane = PLANE_LIGHTING_ABOVE	//RS ADD
		//RS EDIT END
		add_overlay(ii)

/turf/unsimulated/floor/dark/ChangeTurf()
	. = ..()
	cut_overlays()
