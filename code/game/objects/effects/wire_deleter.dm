/obj/effect/wire_deleter
	name = "wire deleter"
	icon = 'icons/mob/screen1.dmi'
	icon_state = "x2"
	anchored = TRUE
	unacidable = TRUE
	simulated = FALSE
	invisibility = 100
	var/wire_deletion_rate = 33

/obj/effect/wire_deleter/Initialize(mapload)
	. = ..()

	for(var/c in loc.contents)
		if(istype(c, /obj/structure/cable))
			if(prob(wire_deletion_rate))
				qdel(c)
	qdel(src)
