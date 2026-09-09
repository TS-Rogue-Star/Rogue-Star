//RS FILE

/*
/////IDEAS
Make search potentially require being approached from a certain direction?
Sofa and comfy chair hidden inventory has a small chance to add small searchers to their hidden inventory

Make a corresponding HIDE ability, in which you can stash things in an object, and have stashes persist. :)

/////POSSIBLE SEARCHABLES
Sofa
Bed
Potted plant
Comfy chair
Vending machiene - ONLY FROM BEHIND?
Trash piles?
*/

/atom/proc/search()
	if(usr == src)
		return FALSE
	if(!Adjacent(usr))
		return FALSE
	if(!isliving(usr))
		return
	var/mob/living/L = usr
	SEND_SIGNAL(src,COMSIG_SEARCHED,usr)
	var/adjective = pick(list(
		"snoop",
		"quest",
		"feel",
		"probe",
		"survey",
		"peek",
		"poke",
		"prod",
		"forage",
		"scan",
		"investigate",
		"scour",
		"hunt",
		"look",
		"frisk"
	))
	L.visible_message(SPAN_NOTICE("\The [L] [adjective]s around \the [src]..."),SPAN_NOTICE("You [adjective] around \the [src]..."),runemessage = ". . .")

/client
	var/static/obj/screen/search_overlay

/client/proc/generate_search_overlay()
	if(search_overlay)
		return
	search_overlay = new()
	search_overlay.mouse_opacity = FALSE
	search_overlay.icon = 'icons/rogue-star/search_overlay.dmi'
	search_overlay.icon_state = "search"
	search_overlay.color = "#daba63"
	search_overlay.screen_loc = "WEST,SOUTH"
	search_overlay.layer = LAYER_HUD_UNDER
//	search_overlay.plane = LIGHTING

/mob
	var/click_flags = 0
/mob/proc/search_on()
	click_flags |= CLICK_SEARCH
	if(client)
		if(!client.search_overlay)
			client.generate_search_overlay()
		client.screen |= client.search_overlay
/mob/proc/search_off()
	click_flags &= ~CLICK_SEARCH
	client?.screen -= client.search_overlay
/mob/verb/toggle_search()
	set name = "Toggle-Search"
	set hidden = TRUE
	if(click_flags & CLICK_SEARCH)
		search_off()
	else
		search_on()

/obj/search()
	. = ..()
	if(micro_target)
		if(!Adjacent(usr))
			return FALSE
		micro_interact()
		return TRUE

/obj
	var/hidden_inventory_percent = 0
	var/hidden_inventory_type
	var/hidden_inventory_description = null

/obj/Initialize(mapload)
	. = ..()
	if(hidden_inventory_percent > 0 && hidden_inventory_type)
		if(prob(hidden_inventory_percent))
			create_hidden_inventory()

/obj/proc/create_hidden_inventory()
	if(hidden_inventory_type)
		LoadComponent(hidden_inventory_type,hidden_inventory_description)

/obj/structure/bed/chair/sofa
	hidden_inventory_percent = 5
	hidden_inventory_type = /datum/component/hidden_inventory
	hidden_inventory_description = "Under the cushions."

/datum/component/hidden_inventory
	var/description = "A small compartment."
	var/list/inventory = list()
	var/found = FALSE	//We only generate loot and xp for the first person to find us.
	var/list/potential_loot = list(
		"coin" = 50,
		"cash" = 25,
		"toy" = 10,
		"trash" = 2
	)
	var/potential_loot_quantity = 3

/datum/component/hidden_inventory/New(list/raw_args)
	. = ..()
	if(raw_args[2])
		description = raw_args[2]

/datum/component/hidden_inventory/Initialize()
	. = ..()
	RegisterSignal(parent, COMSIG_SEARCHED, PROC_REF(search))
/datum/component/hidden_inventory/Destroy(force, silent)
	UnregisterSignal(parent, COMSIG_SEARCHED)
	. = ..()

/datum/component/hidden_inventory/proc/search()
	if(!isliving(args[2]))
		return
	var/mob/living/L = args[2]
	if(!L)
		return
	if(!found)
		first_found()
		L.grant_xp(SKILL_SEEKING,1)
	else if(inventory.len == 0)
		qdel(src)
		return

	var/choice = tgui_input_list(L,description,"Search",inventory)
	if(choice)
		inventory -= choice
		var/turf/T = get_turf(parent)
		if(isobj(choice))
			var/obj/thing = choice
			thing.forceMove(get_turf(L))
			L.put_in_hands(thing)
			T.visible_message(SPAN_WARNING("\The [thing] tumbles free from \the [parent]!"),runemessage = "POF!")
			if(inventory.len <= 0)
				qdel(src)

/datum/component/hidden_inventory/proc/interpret_string(var/string)
	switch(string)
		if("coin")
			return pick(subtypesof(/obj/item/weapon/coin))
		if("cash")
			return pick(subtypesof(/obj/item/weapon/spacecash))
		if("toy")
			return pick(subtypesof(/obj/item/toy))
		if("trash")
			return pick(subtypesof(/obj/item/trash))
	return FALSE

/datum/component/hidden_inventory/proc/first_found()
	found = TRUE
	var/howmany = rand(1,potential_loot_quantity)

	while(howmany > 0)
		howmany --

		var/iteration = pick(potential_loot)
		if(iteration != "coin")
			potential_loot -= iteration

		if(ispath(iteration))
			var/a = new iteration()
			inventory += a
		else
			iteration = interpret_string(iteration)
			if(ispath(iteration))
				var/a = new iteration()
				inventory += a
	potential_loot = null

// /datum/component/hidden_inventory/general

/*


	var/list/potential_loot = list(
		"coin" = 50,
		"cash" = 25,
		"toy" = 10,
		"trash" = 2,

		/obj/item/weapon/gun/energy/sizegun = 1,
		/obj/item/device/slow_sizegun = 1,
		/obj/item/pizzavoucher = 1,
		/obj/item/device/bodysnatcher = 1,
		/obj/item/weapon/bluespace_harpoon = 1,
		/obj/item/device/perfect_tele = 1,
		/obj/item/device/sleevemate = 1,
		/obj/item/weapon/disk/nifsoft/compliance = 1,
		/obj/item/weapon/implanter/compliance = 1,
		/obj/item/seeds/ambrosiadeusseed = 1,
		/obj/item/seeds/ambrosiavulgarisseed = 1,
		/obj/item/seeds/libertymycelium = 1,
		/obj/fiftyspawner/platinum = 1,

	)

	var/how_many_things = rand(1,3)
	var/list/picked_loot = list()

	while(how_many_things > 0)
		how_many_things --

		var/iteration = pick(potential_loot)
		if(iteration != "coin")
			potential_loot -= iteration

		picked_loot += iteration



*/
