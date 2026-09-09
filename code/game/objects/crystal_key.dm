//RS FILE
/obj/dungeon_switch
	name = "crystal"
	icon = 'icons/rogue-star/misc.dmi'
	icon_state = "crystal_key"
	anchored = TRUE
	var/open_state = "crystal_key"
	var/closed_state = "crystal_key_spent"

/obj/dungeon_switch/attack_hand(mob/living/user)
	. = ..()
	user.visible_message(SPAN_NOTICE("\The [user] touches \the [src]."),SPAN_NOTICE("You touch \the [src]."),runemessage = "tuch")
	if(!action(user))
		to_chat(user,SPAN_WARNING("\The [src] doesn't respond..."))

/obj/dungeon_switch/hitby(atom/movable/AM)
	. = ..()
	if(isobj(AM))
		action()

/obj/dungeon_switch/bullet_act(obj/item/projectile/P, def_zone)
	. = ..()
	action()

/obj/dungeon_switch/proc/action(var/mob/user)
	if(!cantrigger(user))
		return FALSE
	SEND_SIGNAL(src,COMSIG_DUNGEON_TRIGGER,user)
	return TRUE

/obj/dungeon_switch/dungeon_trigger(var/mob/user)
	update_icon()

/obj/dungeon_switch/update_icon()
	. = ..()
	var/turf/ourturf = get_turf(src)
	if(istriggered())
		icon_state = closed_state
		ourturf.visible_message(SPAN_WARNING("\The [src] shimmers as it closes up!!!"),runemessage = "clink")
	else
		icon_state = open_state
		ourturf.visible_message(SPAN_WARNING("\The [src] flashes as it opens up!!!"),runemessage = "shing")

//Obstacle//

/obj/dungeon_obstacle
	name = "decorated pillar"
	desc = "An impassable pillar made of a very hard material. It has some intricate engravings etched in its surface."
	icon = 'icons/rogue-star/misc.dmi'
	icon_state = "crystal_pillar"
	anchored = TRUE
	density = TRUE
	opacity = TRUE
	var/closed_state = "crystal_pillar"
	var/open_state = "crystal_pillar_lowered"

/obj/dungeon_obstacle/dungeon_lock()
	if(density)
		return FALSE
	var/turf/ourturf = get_turf(src)
	density = TRUE
	opacity = TRUE
	icon_state = closed_state
	SEND_SIGNAL(src,COMSIG_DUNGEON_TRIGGER)
	ourturf.visible_message(SPAN_WARNING("\The [src] rumbles into a closed position!"),runemessage = "rumble")
	return TRUE

/obj/dungeon_obstacle/dungeon_unlock()
	if(!density)
		return FALSE
	var/turf/ourturf = get_turf(src)
	if(!open_state)
		ourturf.visible_message(SPAN_WARNING("\The [src] crumbles to dust!!!"),runemessage = ". . .")
		qdel(src)
		return TRUE
	density = FALSE
	opacity = FALSE
	icon_state = open_state
	SEND_SIGNAL(src,COMSIG_DUNGEON_UNTRIGGER)
	ourturf.visible_message(SPAN_NOTICE("\The [src] clunks into an open position!"),runemessage = "clunk")
	return TRUE

/obj/dungeon_obstacle/dungeon_trigger()	//Something somewhere is telling us to trigger, so we're just going to assume it wants us to toggle our state
	if(icon_state == closed_state)
		return dungeon_unlock()
	else
		return dungeon_lock()

/obj/dungeon_obstacle/pillar/open
	icon_state = "crystal_pillar_lowered"
	density = FALSE
	opacity = FALSE

/obj/dungeon_obstacle/disguised
	name = "wall"
	icon_state = "crystal_obstical_disguised"
	desc = "It seems to be a section of wall plated with steel."
	closed_state = "crystal_obstical_disguised"
	open_state = "crystal_obstical_disguised_lowered"

/obj/dungeon_obstacle/disguised/open
	icon_state = "crystal_obstical_disguised_lowered"
	density = FALSE
	opacity = FALSE

/obj/dungeon_obstacle/wall
	name = "wall"
	desc = "It seems to be a section of wall plated with steel."
	icon = 'icons/turf/wall_masks.dmi'
	icon_state = "generic"
	desc = "It seems to be a section of wall plated with steel."
	closed_state = "generic"
	open_state = "blank"

/obj/dungeon_obstacle/wall/open
	icon_state = "blank"
	density = FALSE
	opacity = FALSE

/obj/dungeon_obstacle/wall/reinforced
	icon_state = "rgeneric"
	desc = "It seems to be a section of wall reinforced with plasteel and plated with plasteel."
	closed_state = "rgeneric"

/obj/dungeon_obstacle/wall/reinforced/open
	icon_state = "blank"
	density = FALSE
	opacity = FALSE

/obj/dungeon_obstacle/wall/cult
	icon_state = "cult"
	desc = "Hideous images dance beneath the surface."
	closed_state = "cult"

/obj/dungeon_obstacle/wall/cult/open
	icon_state = "blank"
	density = FALSE
	opacity = FALSE

/obj/dungeon_obstacle/obstical
	name = "decorated wall"
	icon_state = "crystal_obstical"
	closed_state = "crystal_obstical"
	open_state = "crystal_obstical_lowered"

/obj/dungeon_obstacle/obstical/open
	icon_state = "crystal_obstical_lowered"
	density = FALSE
	opacity = FALSE

/obj/dungeon_obstacle/crystal
	name = "impassable rock"
	desc = "A shiny, impassable rock!"
	icon = 'icons/turf/x64.dmi'
	icon_state = "rock-crystal-shiny"
	pixel_x = -16
	pixel_y = -16
	closed_state = "rock-crystal-shiny"
	open_state = null
