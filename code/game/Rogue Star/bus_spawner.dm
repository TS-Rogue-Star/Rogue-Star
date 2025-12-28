//RS FILE - Make a thing that you can use to spawn many things with altered properties.
/obj/effect/bus_spawner
	name = "BUS SPAWNER"
	desc = "Adjust some variables and click me to spawn your adminbus!!!"
	icon = 'icons/rogue-star/misc.dmi'
	icon_state = "birdcage"

	alpha = 100

	plane = PLANE_ADMIN_SECRET

	var/bus_type = null

	var/bus_name = null
	var/bus_desc = null

	var/icon/bus_icon = null
	var/bus_icon_state = null

	var/bus_mob_size_mult = null
	var/bus_health = null
	var/bus_dmg_low = null
	var/bus_dmg_high = null

	var/bus_mob_ai = null
	var/bus_mob_hostile = null
	var/bus_mob_retaliate = null

/obj/effect/bus_spawner/proc/spawn_bus()
	if(!check_rights(R_ADMIN, R_FUN))
		return

	if(!bus_type)	//Need a type to spawn
		setup_bus()	//So if we got here we'll just prompt setup
		return

	var/atom/ourspawn = new bus_type(get_turf(src))
	if(isliving(ourspawn))	//Handle mob here instead of later in hopes of getting ahead of the AI holder spawning to try to save some work.
		var/mob/living/L = ourspawn
		if(bus_mob_ai)
			L.ai_holder_type = bus_mob_ai
			if(L.ai_holder)
				L.initialize_ai_holder()	//If the AI holder exist though we can just replace it.
		if(bus_mob_size_mult)
			L.resize(bus_mob_size_mult)
		if(bus_health)
			L.maxHealth = bus_health
			L.health = bus_health
		if(bus_dmg_low || bus_dmg_high)
			if(isanimal(L))
				var/mob/living/simple_mob/S = L
				if(bus_dmg_low)
					S.melee_damage_lower = bus_dmg_low
				if(bus_dmg_high)
					S.melee_damage_upper = bus_dmg_high

	if(bus_name)
		ourspawn.name = bus_name
	if(bus_desc)
		ourspawn.desc = bus_desc
	if(bus_icon)
		ourspawn.icon = bus_icon
		var/icon/I = icon(src.bus_icon)
		ourspawn.pixel_x = ((I.Width() / 2) - 16) * -1
	if(bus_icon_state)
		ourspawn.icon_state = bus_icon_state
		if(isanimal(ourspawn))
			var/mob/living/simple_mob/S = ourspawn
			S.icon_living = bus_icon_state
			S.icon_dead = "[bus_icon_state]_dead"
			S.icon_rest = "[bus_icon_state]_rest"

/obj/effect/bus_spawner/proc/setup_bus()
	if(!check_rights(R_ADMIN, R_FUN))
		return

	bus_type = get_path_from_partial_text(bus_type)

	if(!bus_type)
		return

	bus_name = tgui_input_text(usr,"Enter a name? (Optional)","Name",bus_name)
	bus_desc = tgui_input_text(usr,"Enter a desc? (Optional)","Description",bus_desc)

	bus_icon = input(usr, "Select an icon? (Optional)","Upload An Icon",bus_icon) as null|file

	if(bus_icon)
		bus_icon_state = tgui_input_text(usr,"Enter an icon_state? (Optional)","icon_state",bus_icon_state)

	bus_mob_size_mult = tgui_input_number(usr,"Enter a size_multiplier? (Optional)","size_multiplier",bus_mob_size_mult)

	bus_mob_ai = text2path(tgui_input_text(usr,"Enter an ai_holder_type ","ai_holder_type",bus_mob_ai))
	if(bus_mob_ai)
		var/choice = tgui_alert(usr,"Should the mob be hostile?","Hostile",list("Hostile","Retaliate Only","Passive"))
		switch(choice)
			if("Hostile")
				bus_mob_hostile = TRUE
				bus_mob_retaliate = TRUE
			if("Retaliate Only")
				bus_mob_hostile = FALSE
				bus_mob_retaliate = TRUE
			if("Passive")
				bus_mob_hostile = FALSE
				bus_mob_retaliate = FALSE
	bus_health = tgui_input_number(usr,"How much health should it have? (Optional)","health",bus_health)
	bus_dmg_low = tgui_input_number(usr,"What should the lower bound for its damage be? (Optional)","Damage minimum",bus_dmg_low)
	bus_dmg_high = tgui_input_number(usr,"What should the upper bound for its damage be? (Optional)","Damage maximum",bus_dmg_high)


/obj/effect/bus_spawner/Click(location, control, params)
	if(!check_rights(R_ADMIN, R_FUN))
		return
	spawn_bus()

/obj/effect/bus_spawner/verb/bus_spawner_setup()
	set category = "Fun"
	set name = "Spawner Setup"
	set src in view(7)

	setup_bus()
