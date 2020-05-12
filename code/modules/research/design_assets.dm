
// Representative icons for each research design
/datum/asset/iconsheet/research_designs
	name = "design"

/datum/asset/iconsheet/research_designs/register()
	var/list/sprites = list()
	for (var/path in subtypesof(/datum/design))
		var/datum/design/D = path
		if(initial(D.id) == DESIGN_ID_IGNORE)
			continue

		var/icon_file
		var/icon_state
		var/icon/I

		if(initial(D.research_icon) && initial(D.research_icon_state)) // If the design has an icon replacement skip the rest
			icon_file = initial(D.research_icon)
			icon_state = initial(D.research_icon_state)
			if(!(icon_state in cached_icon_states(icon_file)))
				warning("design [D] with icon '[icon_file]' missing state '[icon_state]'")
				continue
			I = icon(icon_file, icon_state, SOUTH) // frame=1, moving=FALSE ?

		else
			// construct the icon and slap it into the resource cache
			var/atom/item = initial(D.build_path)
			if (!ispath(item, /atom))
				// biogenerator outputs to beakers by default
				if (initial(D.build_type) & BIOGENERATOR)
					item = /obj/item/weapon/reagent_containers/glass/beaker/large
				else
					continue  // shouldn't happen, but just in case

			// circuit boards become their resulting machines or computers
			if (ispath(item, /obj/item/weapon/circuitboard))
				var/obj/item/weapon/circuitboard/C = item
				var/machine = initial(C.build_path)
				if (machine)
					item = machine

			icon_file = initial(item.icon)
			icon_state = initial(item.icon_state)

			if(!(icon_state in cached_icon_states(icon_file)))
				warning("design [D] with icon '[icon_file]' missing state '[icon_state]'")
				continue
			I = icon(icon_file, icon_state, SOUTH) // frame=1, moving=FALSE ?

			// computers (and snowflakes) get their screen and keyboard sprites
			if (ispath(item, /obj/machinery/computer) || ispath(item, /obj/machinery/power/solar_control))
				var/obj/machinery/computer/C = item
				var/screen = initial(C.icon_screen)
				var/keyboard = initial(C.icon_keyboard)
				var/all_states = cached_icon_states(icon_file)
				if (screen && (screen in all_states))
					I.Blend(icon(icon_file, screen, SOUTH), ICON_OVERLAY)
				if (keyboard && (keyboard in all_states))
					I.Blend(icon(icon_file, keyboard, SOUTH), ICON_OVERLAY)

		sprites["[initial(D.id)]-south"] = I
	..(sprites)
