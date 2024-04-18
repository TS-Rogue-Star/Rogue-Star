//RS ADD - wawo
/obj/structure/flora/tree/cactus
	name = "cactus"
	desc = "A tall, green prickly plant with multiple arms!"
	icon = 'icons/rogue-star/flora32x96.dmi'
	icon_state = "cactus1"
	pixel_x = 0

/obj/structure/flora/tree/cactus/Initialize()
	. = ..()
	icon_state = "cactus[rand(1,4)]"

/obj/structure/flora/tree/cactus/Bumped(AM)
	. = ..()
	if(ishuman(AM))
		var/mob/living/carbon/human/H = AM
		if(H.species.flags & NO_MINOR_CUT)
			return
		to_chat(H, "<span class= 'danger'>You bump into \the [src]!!! \The [src]'s needles dig into you!!! AAAAAAAAAAAAAAAAAAAAAAA!!!!!!!!!</span>")
		H.say("*scream")
		H.adjustBruteLoss(1)
		H.halloss += 75

/obj/effect/light_beam
	name = "light beam"
	desc = "A shaft of light fading into the infinite beyond!"
	icon = 'icons/rogue-star/light_beam32x128.dmi'
	icon_state = "light_beam"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	plane = PLANE_LIGHTING_ABOVE
	anchored = TRUE
	opacity = FALSE
	density = FALSE
	unacidable = TRUE

/obj/effect/light_beam/Initialize()
	. = ..()
	set_light(l_range = 3, l_power = 2, l_color = color)

/obj/effect/light_beam/red
	color = "#ff0000"
/obj/effect/light_beam/blue
	color = "#0015ff"
/obj/effect/light_beam/warm
	color = "#ffdf75"
