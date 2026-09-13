//RS FILE

//Knife meat to separate fat
//Pot to render fat into tallow

//Grass into fibers
//Fibers into string

//Tallow into a cup
//String into cup

/obj/item/fat
	name = "fat"
	desc = "Soft greasy animal fat!"
	icon = 'icons/rogue-star/misc.dmi'
	icon_state = "see"
	drop_sound = 'sound/items/drop/flesh.ogg'
	pickup_sound = 'sound/items/pickup/flesh.ogg'

// - /datum/reagent/nutriment/triglyceride - Fat

/obj/item/string
	name = "string"
	desc = "Just a little bit of string!"
	icon = 'icons/rogue-star/misc.dmi'
	icon_state = "see"
	color = "#76d669"

	w_class = ITEMSIZE_TINY

/obj/item/string/resolve_attackby(atom/A, mob/user, attack_modifier, click_parameters)
	. = ..()
	if(istype(A,/obj/item/weapon/reagent_containers/glass/beaker))
		var/obj/item/weapon/reagent_containers/glass/beaker/B = A
		B.string_interact(src)

/obj/item/spool
	name = "spool"
	desc = "Holds lots of string!"
	icon = 'icons/rogue-star/misc.dmi'
	icon_state = "see"
	color = "#d6bd69"

	w_class = ITEMSIZE_TINY
	slot_flags = SLOT_POCKET
	var/amount = 0

/obj/item/spool/examine(mob/user)
	. = ..()
	if(amount > 0)
		var/length = "lengths"
		if(amount == 1)
			length = "length"

		. += SPAN_NOTICE("It has [amount] [length] of string wrapped around on it.")

/obj/item/spool/resolve_attackby(atom/A, mob/user, attack_modifier, click_parameters)
	. = ..()
	to_world("spool resolve_attackby")
	if(isturf(A))
		scoop_string(A)
	else if(istype(A,/obj/item/weapon/reagent_containers/glass/beaker))
		to_world("Hello I am thinking about a beaker! :)")
		if(amount <= 0)
			return
		var/obj/item/weapon/reagent_containers/glass/beaker/B = A
		if(B.string_interact(src))
			amount --

/obj/item/spool/proc/scoop_string(var/atom/A)
	if(!A)
		return
	var/turf/T = get_turf(A)
	if(!T)
		return
	for(var/thing in T.contents)
		if(istype(thing, /obj/item/string))
			qdel(thing)
			amount ++

/obj/item/weapon/reagent_containers/glass/beaker/proc/string_interact(var/atom/A)
	var/tallow = 0.0
	var/wax = 0.0
	var/howmuch = 0
	var/list/colors = list()
	if(reagents.total_volume != 0)
		for(var/datum/reagent/thing in reagents.reagent_list)
			if(thing.type == /datum/reagent/nutriment/triglyceride)
				tallow = thing.volume / reagents.total_volume
				howmuch += thing.volume
			else
				colors += thing.color

	if(tallow + wax < 0.75)
		return FALSE
	if(howmuch < 10)
		return FALSE

	var/final_color = null

	if(colors.len)
		for(var/ourcolor in colors)
			if(!final_color)
				final_color = ourcolor
				continue
			final_color = BlendRGB(final_color, ourcolor, 0.5)

	var/obj/item/weapon/flame/candle/white/c = new(get_turf(src))
	c.wax = howmuch * 250
	if(final_color)
		c.color = final_color
	c.name = "candle"
	c.desc = "A home made candle! How rustic!"
	for(var/datum/reagent/R in reagents.reagent_list)
		reagents.remove_reagent(R.name,R.volume)
	return TRUE

/obj/item/weapon/reagent_containers/glass/beaker/candle_pot
