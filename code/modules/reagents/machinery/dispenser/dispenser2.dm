/obj/machinery/chemical_dispenser
	name = "chemical dispenser"
	desc = "Automagically fabricates chemicals from electricity."
	icon = 'icons/obj/chemical.dmi'
	icon_state = "dispenser"
	clicksound = "switch"

	var/list/spawn_cartridges = null // Set to a list of types to spawn one of each on New()

	var/list/cartridges = list() // Associative, label -> cartridge
	var/obj/item/weapon/reagent_containers/container = null

	var/ui_title = "Chemical Dispenser"

	var/accept_drinking = FALSE
	var/amount = 30

	use_power = USE_POWER_IDLE
	idle_power_usage = 0.1 KILOWATTS
	anchored = TRUE
	unacidable = TRUE

/obj/machinery/chemical_dispenser/Initialize()
	. = ..()
	if(spawn_cartridges)
		for(var/type in spawn_cartridges)
			add_cartridge(new type(src))

/obj/machinery/chemical_dispenser/examine(mob/user)
	. = ..()
	. += "It has [cartridges.len] cartridges installed, and has space for [DISPENSER_MAX_CARTRIDGES - cartridges.len] more."
	. += "Use a crowbar to retrieve installed cartridges"

/obj/machinery/chemical_dispenser/update_icon()
	if(accept_drinking) //drink dispensors don't have fancy sprites, so this is a very handy checker
		icon_state = initial(icon_state) //just in case some weirdness happens I guess.
		return

	cut_overlays()
	icon_state = initial(icon_state)
	if(panel_open)
		add_overlay("[initial(icon_state)]_panel-o")
	if(container)
		icon_state = "[initial(icon_state)]_working"
		if(istype(container, /obj/item/weapon/reagent_containers/glass/beaker/bluespace))
			add_overlay("[initial(icon_state)]_bsbeaker")
		else if(istype(container, /obj/item/weapon/reagent_containers/glass/beaker/noreact))
			add_overlay("[initial(icon_state)]_nrbeaker")
		else	//the only see-through one gets filling updates, and we can only do glass and subtypes of glass anyway.
			var/obj/item/weapon/reagent_containers/glass/C = container
			if(C.reagents && C.reagents.total_volume)
				var/mutable_appearance/filling = mutable_appearance('icons/obj/reagentfillings.dmi', "[initial(icon_state)]_1")
				var/percent = round((C.reagents.total_volume / C.volume) * 100)
				switch(percent)
					if(0 to 35)			filling.icon_state = "[initial(icon_state)]_1"
					if(36 to 74)		filling.icon_state = "[initial(icon_state)]_5"
					if(75 to INFINITY)	filling.icon_state = "[initial(icon_state)]_10"
				filling.color = C.reagents.get_color()
				//Add our filling, if any.
				add_overlay(filling)
			//Then overlay the beaker atop of the filling, so it appears behind it.
			add_overlay("[initial(icon_state)]_beaker")

	if(stat & NOPOWER)
		icon_state = "[initial(icon_state)]_nopower"

	if(stat & BROKEN)
		icon_state = "[initial(icon_state)]_broken"
	return

/obj/machinery/chemical_dispenser/verb/rotate_clockwise()
	set name = "Rotate Dispenser Clockwise"
	set category = "Object"
	set src in oview(1)

	if (src.anchored || usr:stat)
		to_chat(usr, "It is fastened down!")
		return FALSE
	src.set_dir(turn(src.dir, 270))
	return TRUE

/obj/machinery/chemical_dispenser/proc/add_cartridge(obj/item/weapon/reagent_containers/chem_disp_cartridge/C, mob/user)
	if(!istype(C))
		if(user)
			to_chat(user, span_warning("[C] will not fit in [src]!"))
		return

	if(cartridges.len >= DISPENSER_MAX_CARTRIDGES)
		if(user)
			to_chat(user, span_warning("[src] does not have any slots open for [C] to fit into!"))
		return

	if(!C.label)
		if(user)
			to_chat(user, span_warning("[C] does not have a label!"))
		return

	if(cartridges[C.label])
		if(user)
			to_chat(user, span_warning("[src] already contains a cartridge with that label!"))
		return

	if(user)
		user.drop_from_inventory(C, src)
		to_chat(user, span_notice("You add [C] to [src]."))

	C.forceMove(src)
	cartridges[C.label] = C
	cartridges = sortAssoc(cartridges)
	SStgui.update_uis(src)

/obj/machinery/chemical_dispenser/proc/remove_cartridge(label)
	. = cartridges[label]
	cartridges -= label
	SStgui.update_uis(src)

/obj/machinery/chemical_dispenser/attackby(obj/item/weapon/W, mob/user)
	if(default_unfasten_wrench(user, W, 5 SECONDS))
		return

	if(istype(W, /obj/item/weapon/reagent_containers/chem_disp_cartridge))
		if(!panel_open)
			to_chat(user, span_notice("You need to open the access hatch first!"))
			return
		add_cartridge(W, user)

	if(istype(W, /obj/item/weapon/reagent_containers/glass) || istype(W, /obj/item/weapon/reagent_containers/food))
		if(container)
			to_chat(user, span_warning("There is already \a [container] on [src]!"))
			return

		var/obj/item/weapon/reagent_containers/RC = W

		if(!accept_drinking && istype(RC,/obj/item/weapon/reagent_containers/food))
			to_chat(user, span_warning("This machine only accepts beakers!"))
			return

		if(!RC.is_open_container())
			to_chat(user, span_warning("You don't see how [src] could dispense reagents into [RC] with the lid on."))
			return

		replace_container(user, RC)
		to_chat(user, span_notice("You add [RC] to [src]."))
		updateUsrDialog()
		update_icon()

	if(default_deconstruction_screwdriver(user, W))
		update_icon()
		return

	if(panel_open)
		if(W.has_tool_quality(TOOL_CROWBAR))	//I would make the deconstructable, but the cartridge system makes this... unwise.
			var/label = tgui_input_list(user, "Which cartridge would you like to remove?", "Chemical Dispenser", cartridges)
			if(!label) return
			var/obj/item/weapon/reagent_containers/chem_disp_cartridge/C = remove_cartridge(label)
			if(C)
				to_chat(user, span_notice("You remove [C] from [src]."))
				C.forceMove(get_turf(src))
				playsound(src, W.usesound, 50, 1)

	else
		return ..()

/obj/machinery/chemical_dispenser/AltClick(mob/user)
	if(container)
		container.forceMove(get_turf(src))
		if(Adjacent(usr)) // So the AI doesn't get a beaker somehow.
			user.put_in_hands(container)
		container = null
		update_icon()

/obj/machinery/chemical_dispenser/proc/replace_container(mob/living/user, obj/item/weapon/reagent_containers/new_container)
	if(container)
		container.forceMove(drop_location())
		if(user && Adjacent(user))
			user.put_in_hands(container)
	if(new_container)
		if(user && Adjacent(user))
			user.drop_from_inventory(new_container, src)
		container = new_container
	else
		container = null
	update_icon()
	return TRUE

/obj/machinery/chemical_dispenser/tgui_interact(mob/user, datum/tgui/ui = null)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ChemDispenser", ui_title) // 390, 655
		ui.open()

/obj/machinery/chemical_dispenser/tgui_data(mob/user)
	var/data[0]
	data["amount"] = amount
	data["isBeakerLoaded"] = container ? 1 : 0
	data["glass"] = accept_drinking

	var/beakerContents[0]
	if(container && container.reagents && container.reagents.reagent_list.len)
		for(var/datum/reagent/R in container.reagents.reagent_list)
			beakerContents.Add(list(list("name" = R.name, "id" = R.id, "volume" = R.volume))) // list in a list because Byond merges the first list...
	data["beakerContents"] = beakerContents

	if(container)
		data["beakerCurrentVolume"] = container.reagents.total_volume
		data["beakerMaxVolume"] = container.reagents.maximum_volume
	else
		data["beakerCurrentVolume"] = null
		data["beakerMaxVolume"] = null

	var/chemicals[0]
	for(var/label in cartridges)
		var/obj/item/weapon/reagent_containers/chem_disp_cartridge/C = cartridges[label]
		chemicals.Add(list(list("title" = label, "id" = label, "amount" = C.reagents.total_volume))) // list in a list because Byond merges the first list...
	data["chemicals"] = chemicals
	return data

/obj/machinery/chemical_dispenser/tgui_act(action, params)
	if(..())
		return TRUE

	. = TRUE
	switch(action)
		if("amount")
			amount = clamp(round(text2num(params["amount"]), 1), 0, 120) // round to nearest 1 and clamp 0 - 120
		if("dispense")
			var/label = params["reagent"]
			if(cartridges[label] && container && container.is_open_container())
				var/obj/item/weapon/reagent_containers/chem_disp_cartridge/C = cartridges[label]
				playsound(src, 'sound/machines/reagent_dispense.ogg', 25, 1)
				C.reagents.trans_to(container, amount)
				update_icon()
		if("remove")
			var/amount = text2num(params["amount"])
			if(!container || !amount)
				return
			var/datum/reagents/R = container.reagents
			var/id = params["reagent"]
			if(amount > 0)
				R.remove_reagent(id, amount)
			else if(amount == -1) // Isolate
				R.isolate_reagent(id)
			update_icon()
		if("ejectBeaker")
			replace_container(usr)
			. = TRUE //no afterattack
		else
			return FALSE

	add_fingerprint(usr)

/obj/machinery/chemical_dispenser/attack_ghost(mob/user)
	if(stat & BROKEN)
		return
	tgui_interact(user)

/obj/machinery/chemical_dispenser/attack_ai(mob/user)
	attack_hand(user)

/obj/machinery/chemical_dispenser/attack_hand(mob/user)
	if(stat & BROKEN)
		return
	tgui_interact(user)
