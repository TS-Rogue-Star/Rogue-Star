/obj/structure/flora/tree/spookytree
	icon = 'icons/rogue-star/spookytrees.dmi'
	desc = "It looks pretty spooky..."
	icon_state = "1"
	base_state = "1"
	health = 999999
	max_health = 999999
	pixel_x = -16
	layer = MOB_LAYER
	indestructable = TRUE
	color = "#3d172a"

/obj/structure/flora/tree/spookytree/choose_icon_state()
	return "[rand(1, 20)]"

/obj/structure/flora/tree/spookytree/stump()
	qdel(src)

/turf/unsimulated/spookygrass
	name = "grass"
	desc = "Grassy!"
	icon = 'icons/rogue-star/turfs.dmi'
	icon_state = "state1"
	color = "#361836"

	footstep_sounds = list("human" = list(
		'sound/effects/footstep/grass1.ogg',
		'sound/effects/footstep/grass2.ogg',
		'sound/effects/footstep/grass3.ogg',
		'sound/effects/footstep/grass4.ogg'))

/turf/unsimulated/spookygrass/New(loc, ...)
	. = ..()
	update_icon()

/turf/unsimulated/spookygrass/update_icon()
	. = ..()
	cut_overlays()
	icon_state = "state[rand(1,10)]"
	var/w = rand(0,6)
	var/d = rand(0,6)

	for(var/i = 1 to w)
		apply_sprig(TRUE)
	for(var/i = 1 to d)
		apply_sprig()

/turf/unsimulated/spookygrass/proc/apply_sprig(var/white = FALSE)
	var/ourstate = "sprig"
	if(white)
		ourstate = "sprig_w"

	var/image/I = image(icon = icon,icon_state = ourstate,layer = ABOVE_TURF_LAYER)
	I.plane = TURF_PLANE
	I.color = color
	I.appearance_flags = RESET_COLOR|KEEP_APART|PIXEL_SCALE
	I.pixel_x = rand(-14,15)
	I.pixel_y = rand(-15,17)
	add_overlay(I)

/turf/unsimulated/spookygrass/tree
	icon_state = "statetree"

/turf/unsimulated/spookygrass/tree/New(loc, ...)
	. = ..()

	new /obj/structure/flora/tree/spookytree(src)
