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
	icon = 'icons/rogue-star/obj.dmi'
	icon_state = "fat1"
	drop_sound = 'sound/items/drop/flesh.ogg'
	pickup_sound = 'sound/items/pickup/flesh.ogg'

/obj/item/fat/Initialize()
	. = ..()
	if(icon_state == "fat1")
		icon_state = "fat[rand(1,5)]"
	pixel_x = rand(-8,8)
	pixel_y = rand(-8,8)

// - /datum/reagent/nutriment/triglyceride - Fat

/obj/item/string
	name = "string"
	desc = "Just a little bit of string!"
	icon = 'icons/rogue-star/obj.dmi'
	icon_state = "string1"
	color = "#dfc896"

	w_class = ITEMSIZE_TINY

/obj/item/string/Initialize()
	. = ..()
	if(icon_state == "string1")
		icon_state = "string[rand(1,5)]"
	pixel_x = rand(-8,8)
	pixel_y = rand(-8,8)

/obj/item/string/resolve_attackby(atom/A, mob/user, attack_modifier, click_parameters)
	. = ..()
	if(istype(A,/obj/item/weapon/reagent_containers))
		var/obj/item/weapon/reagent_containers/B = A
		if(B.string_interact(src))
			user.drop_from_inventory(src, get_turf(user))
			qdel(src)

/obj/item/spool
	name = "spool"
	desc = "Holds lots of string!"
	icon = 'icons/rogue-star/obj.dmi'
	icon_state = "spool0"
//	color = "#d6bd69"

	w_class = ITEMSIZE_TINY
	slot_flags = SLOT_POCKET
	var/amount = 0

/obj/item/spool/Initialize()
	. = ..()
	update_icon()
	pixel_x = rand(-8,8)
	pixel_y = rand(-8,8)

/obj/item/spool/examine(mob/user)
	. = ..()
	if(amount > 0)
		var/length = "lengths"
		if(amount == 1)
			length = "length"

		. += SPAN_NOTICE("It has [amount] [length] of string wrapped around on it.")

/obj/item/spool/update_icon()
	. = ..()
	if(amount <= 0)
		icon_state = "spool0"
	else if(amount >= 10)
		icon_state = "spool2"
	else
		icon_state = "spool1"

/obj/item/spool/resolve_attackby(atom/A, mob/user, attack_modifier, click_parameters)
	. = ..()
	if(isturf(A) || istype(A, /obj/item/string))
		scoop_string(A)
	else if(istype(A,/obj/item/weapon/reagent_containers))
		if(amount <= 0)
			return
		var/obj/item/weapon/reagent_containers/B = A
		if(B.string_interact(src))
			amount --
			update_icon()

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
	update_icon()

/obj/item/weapon/reagent_containers/proc/string_interact(var/atom/A)
	var/tallow = 0.0
	var/wax = 0.0
	var/howmuch = 0
	var/list/colors = list()
	if(reagents.total_volume > 0)
		for(var/datum/reagent/thing in reagents.reagent_list)
			if(thing.type == /datum/reagent/nutriment/triglyceride)
				tallow = thing.volume / reagents.total_volume
				howmuch += thing.volume
			if(thing.type == /datum/reagent/wax)
				wax = thing.volume / reagents.total_volume
				howmuch += thing.volume
			else
				colors += thing.color

	if(tallow + wax < 0.75)
		return FALSE
	if(howmuch < 5)
		return FALSE

	var/final_color = null

	if(colors.len)
		for(var/ourcolor in colors)
			if(!final_color)
				final_color = ourcolor
				continue
			final_color = BlendRGB(final_color, ourcolor, 0.5)

	var/our_candle
	howmuch *= 25
	howmuch = round(howmuch, 1)

	switch(howmuch)
		if(5000 to INFINITY)
			our_candle = /obj/item/weapon/flame/candle/handmade/jumbo
		if(3000 to 4999)
			our_candle = /obj/item/weapon/flame/candle/handmade/large
		if(1500 to 2999)
			our_candle = /obj/item/weapon/flame/candle/handmade
		else
			our_candle = /obj/item/weapon/flame/candle/handmade/tiny

	var/obj/item/weapon/flame/candle/handmade/c = new our_candle(get_turf(src))
	c.wax = howmuch
	c.starting_wax = howmuch
	if(final_color)
		c.color = final_color
	for(var/datum/reagent/R in reagents.reagent_list)
		reagents.del_reagent(R.id)
	return TRUE

/obj/item/weapon/reagent_containers/glass/beaker/candle_pot

/obj/item/weapon/flame/candle/handmade
	name = "candle"
	desc = "A home made candle! How rustic!"
	icon = 'icons/rogue-star/candle.dmi'
	icon_state = "candle1"
	icon_type = "candle"
	wax_randomize = FALSE
	wax = 1500
	var/starting_wax = 1500
	var/list/carving_choices
	var/static/list/overlays_cache = list()

/obj/item/weapon/flame/candle/handmade/Initialize()
	. = ..()
	if(!pixel_x)
		pixel_x = rand(-8,8)
	if(!pixel_y)
		pixel_y = rand(-8,8)

	starting_wax = wax

/obj/item/weapon/flame/candle/handmade/attackby(obj/item/weapon/W, mob/user)
	. = ..()
	if(istype(W, /obj/item/weapon/material/knife))
		carve(user)

/obj/item/weapon/flame/candle/handmade/tiny
	icon_state = "candle_tiny1"
	icon_type = "candle_tiny"
	wax = 500

/obj/item/weapon/flame/candle/handmade/large
	icon_state = "candle_large1"
	icon_type = "candle_large"
	wax = 3000
	carving_choices = list(
		"Star",
		"Skull",
		"Tree"
	)

/obj/item/weapon/flame/candle/handmade/jumbo
	icon_state = "candle_jumbo1"
	icon_type = "candle_jumbo"
	wax = 5000
	carving_choices = list(
		"Star",
		"Skull",
		"Tree",
		"Pumpkin",
		"Mouse",
		"Doglin"
	)
/obj/item/weapon/flame/candle/handmade/large/star
	icon_state = "candle_Star1"
	icon_type = "candle_Star"
	carving_choices = null
/obj/item/weapon/flame/candle/handmade/large/skull
	icon_state = "candle_Skull1"
	icon_type = "candle_Skull"
	carving_choices = null
/obj/item/weapon/flame/candle/handmade/large/tree
	icon_state = "candle_Tree1"
	icon_type = "candle_Tree"
	carving_choices = null

/obj/item/weapon/flame/candle/handmade/jumbo/pumpkin
	icon_state = "candle_Pumpkin1"
	icon_type = "candle_Pumpkin"
	carving_choices = null

/obj/item/weapon/flame/candle/handmade/jumbo/mouse
	icon_state = "candle_Mouse1"
	icon_type = "candle_Mouse"
	carving_choices = null
/obj/item/weapon/flame/candle/handmade/jumbo/doglin
	icon_state = "candle_Doglin1"
	icon_type = "candle_Doglin"
	carving_choices = null

/obj/item/weapon/flame/candle/handmade/calc_stage()
	var/third = starting_wax / 3
	if(wax > starting_wax - third)
		stage = 1
	else if(wax > starting_wax - (third * 2))
		stage = 2
	else stage = 3

/obj/item/weapon/flame/candle/handmade/update_icon()
	cut_overlays()
	icon_state = "[icon_type][stage]"

	if(!lit)
		return
	var/f_height = flame_height(stage)
	var/combine_key = "flame-[f_height]"
	var/image/flame_image = overlays_cache[combine_key]
	if(!flame_image)
		flame_image = image(icon,null,"flame")
		flame_image.appearance_flags = RESET_COLOR|KEEP_APART|PIXEL_SCALE
		flame_image.plane = PLANE_LIGHTING_ABOVE
		flame_image.pixel_y = f_height
		overlays_cache[combine_key] = flame_image
	add_overlay(flame_image)

/obj/item/weapon/flame/candle/handmade/burn_out()
	var/obj/item/trash/candle/ourtrash = new(src.loc)
	ourtrash.icon = icon
	ourtrash.icon_state = "[icon_type]4"
	ourtrash.color = color
	ourtrash.pixel_x = pixel_x
	ourtrash.pixel_y = pixel_y
	if(istype(src.loc, /mob))
		src.dropped()
	qdel(src)

/obj/item/weapon/flame/candle/handmade/proc/carve(var/mob/user)
	if(!user)
		return
	if(!carving_choices)
		return
	if(carving_choices.len <= 0)
		return
	var/choice = tgui_input_list(user, "What will you carve it into?", "[src] carving",carving_choices)
	if(choice)
		icon_type = "candle_[choice]"
		update_icon()

/obj/item/weapon/flame/candle/handmade/proc/flame_height(var/our_state)
	. = 0
	switch(icon_type)
		if("candle_tiny")
			switch(our_state)
				if(1)
					. = 5
				if(2)
					. = 3
				if(3)
					. = 1
		if("candle")
			switch(our_state)
				if(1)
					. = 5
				if(2)
					. = 2
				if(3)
					. = 0
		if("candle_large")
			switch(our_state)
				if(1)
					. = 5
				if(2)
					. = 2
				if(3)
					. = 0
		if("candle_jumbo")
			switch(our_state)
				if(1)
					. = 5
				if(2)
					. = 2
				if(3)
					. = -1
		if("candle_Star")
			switch(our_state)
				if(1)
					. = 6
				if(2)
					. = 2
				if(3)
					. = -1
		if("candle_Skull")
			switch(our_state)
				if(1)
					. = 5
				if(2)
					. = 3
				if(3)
					. = 0
		if("candle_Tree")
			switch(our_state)
				if(1)
					. = 5
				if(2)
					. = 2
				if(3)
					. = -1
		if("candle_Pumpkin")
			switch(our_state)
				if(1)
					. = 5
				if(2)
					. = 3
				if(3)
					. = 0
		if("candle_Mouse")
			switch(our_state)
				if(1)
					. = 5
				if(2)
					. = 3
				if(3)
					. = -2
		if("candle_Doglin")
			switch(our_state)
				if(1)
					. = 9
				if(2)
					. = 8
				if(3)
					. = 1
	return .
