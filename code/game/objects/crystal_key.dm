//RS FILE

#define DELETE_OBSTICAL 1
#define TOGGLE_OBSTICAL 2

var/global/list/event_obstical_keys = list()

/obj/event_key
	name = "crystal"
	icon = 'icons/rogue-star/misc.dmi'
	icon_state = "crystal_key"
	anchored = TRUE
	var/id
	var/spent = FALSE
	var/spent_state = "gold_tri"
	var/mob/living/link
	var/reusable = FALSE
	var/closed_state = "crystal_key_spent"

/obj/event_key/reusable
	reusable = TRUE

/obj/event_key/Initialize()
	. = ..()
	global.event_obstical_keys += src
	seek_link()

/obj/event_key/Destroy()
	global.event_obstical_keys -= src
	unregister_mob()
	return ..()

/obj/event_key/attack_hand(mob/living/user)
	. = ..()
	if(spent)
		return
	if(link)
		if(!link.client && (link?.ai_holder?.hostile || link?.ai_holder?.stance != STANCE_IDLE))
			to_chat(user,"<span class = 'danger'>A barrier prevents you from touching \the [src]. Something else must be done before you can use it.</span>")
			return
		if(!src.Adjacent(link))
			to_chat(user,"<span class = 'danger'>A barrier prevents you from touching \the [src]. Something else must be done before you can use it.</span>")
			return
	to_chat(user,"<span class = 'notice'>You activate \the [src].</span>")
	spent = TRUE
	trigger()

/obj/event_key/proc/trigger()
	for(var/obj/thing in global.event_obstical_keys)
		if(thing == src)
			continue
		if(istype(thing,/obj/event_key))
			var/obj/event_key/key = thing
			if(id == key.id)
				key.post_trigger()
			continue

		if(istype(thing,/obj/event_obstical))
			var/obj/event_obstical/obstical = thing
			if(id == obstical.id)
				obstical.post_trigger()
			continue
	post_trigger()

/obj/event_key/proc/post_trigger()
	var/turf/ourturf = get_turf(src)
	if(reusable)
		ourturf.visible_message("<span class = 'warning'>\The [src] rumbles as something moves in the distance!!!</span>",runemessage = "rumble rumble")
		spent = FALSE
	else
		unregister_mob()
		if(closed_state)
			ourturf.visible_message("<span class = 'warning'>\The [src] shimmers as it closes up!!!</span>",runemessage = "clink")
			icon_state = closed_state
		else
			ourturf.visible_message("<span class = 'warning'>\The [src] crumbles to dust!!!</span>",runemessage = "crumble crumble")
			qdel(src)

/obj/event_key/proc/seek_link()
	for(var/mob/living/thing in get_turf(src))
		if(isliving(thing))
			register_mob(thing)
			return

/obj/event_key/proc/register_mob(var/mob/living/ourmob)
	if(isliving(ourmob))
		link = ourmob
		RegisterSignal(link, COMSIG_MOB_DEATH, PROC_REF(trigger),TRUE)
		RegisterSignal(link, COMSIG_PARENT_QDELETING, PROC_REF(trigger), TRUE)

/obj/event_key/proc/unregister_mob()
	if(link)
		UnregisterSignal(link, COMSIG_MOB_DEATH)
		UnregisterSignal(link, COMSIG_PARENT_QDELETING)

/obj/event_key/hitby(atom/movable/AM)
	. = ..()
	if(isobj(AM))
		trigger()

/obj/event_key/bullet_act(obj/item/projectile/P, def_zone)
	. = ..()
	trigger()

/obj/event_obstical
	name = "impassable rock"
	desc = "A shiny, impassable rock!"
	icon = 'icons/turf/x64.dmi'
	icon_state = "rock-crystal-shiny"
	var/id
	anchored = TRUE
	density = TRUE
	opacity = TRUE
	pixel_x = -16
	pixel_y = -16
	var/trigger_mode = DELETE_OBSTICAL
	var/closed_state = null
	var/open_state = null

/obj/event_obstical/Initialize()
	. = ..()
	global.event_obstical_keys += src

	if(trigger_mode == TOGGLE_OBSTICAL)
		opacity = density
		if(density)
			if(closed_state)
				icon_state = closed_state
			else
				closed_state = icon_state
		else
			if(open_state)
				icon_state = open_state

/obj/event_obstical/Destroy()
	global.event_obstical_keys -= src
	return ..()

/obj/event_obstical/proc/post_trigger()
	var/turf/ourturf = get_turf(src)
	switch(trigger_mode)
		if(DELETE_OBSTICAL)
			ourturf.visible_message("<span class = 'warning'>\The [src] crumbles to dust!!!</span>",runemessage = "crumble crumble")
			qdel(src)
		if(TOGGLE_OBSTICAL)
			if(!closed_state)
				closed_state = icon_state
			density = !density
			opacity = density
			if(density)
				icon_state = closed_state
			else
				icon_state = open_state
			ourturf.visible_message("<span class = 'warning'>\The [src] rumbles as it moves!!!</span>",runemessage = "rumble rumble")

/obj/event_obstical/disguised
	name = "wall"
	icon_state = "crystal_obstical_disguised"
	desc = "It seems to be a section of wall plated with steel."
	icon = 'icons/rogue-star/misc.dmi'
	pixel_x = 0
	pixel_y = 0

/obj/event_obstical/disguised/wall
	icon = 'icons/turf/wall_masks.dmi'
	icon_state = "generic"
	desc = "It seems to be a section of wall plated with steel."

/obj/event_obstical/disguised/wall/reinforced
	icon_state = "rgeneric"
	desc = "It seems to be a section of wall reinforced with plasteel and plated with plasteel."

/obj/event_obstical/disguised/wall/cult
	icon_state = "cult"
	desc = "Hideous images dance beneath the surface."

/obj/event_obstical/disguised/pillar
	name = "decorated pillar"
	icon_state = "crystal_pillar"
	opacity = FALSE
	closed_state = "crystal_pillar"
	open_state = "crystal_pillar_lowered"

/obj/event_obstical/disguised/pillar/toggle
	trigger_mode = TOGGLE_OBSTICAL

/obj/event_obstical/disguised/obstical
	name = "decorated wall"
	icon_state = "crystal_obstical"
	closed_state = "crystal_obstical"
	open_state = "crystal_obstical_lowered"

/obj/event_obstical/disguised/obstical/toggle
	trigger_mode = TOGGLE_OBSTICAL
