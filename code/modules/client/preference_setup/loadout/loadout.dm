////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star August 2025 to create a new gallery view with icons //
////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star September 2026: Character Designer - Loadout /////////
////////////////////////////////////////////////////////////////////////////////////////

var/list/loadout_categories = list()
var/list/gear_datums = list()

/datum/loadout_category
	var/category = ""
	var/list/gear = list()

/datum/loadout_category/New(var/cat)
	category = cat
	..()

/hook/startup/proc/populate_gear_list()

	//create a list of gear datums to sort
	for(var/datum/gear/G as anything in subtypesof(/datum/gear))
		if(initial(G.type_category) == G)
			continue
		var/use_name = initial(G.display_name)
		var/use_category = initial(G.sort_category)

		if(!use_name)
			error("Loadout - Missing display name: [G]")
			continue
		if(isnull(initial(G.cost)))
			error("Loadout - Missing cost: [G]")
			continue
		if(!initial(G.path))
			error("Loadout - Missing path definition: [G]")
			continue

		if(!loadout_categories[use_category])
			loadout_categories[use_category] = new /datum/loadout_category(use_category)
		var/datum/loadout_category/LC = loadout_categories[use_category]
		gear_datums[use_name] = new G
		LC.gear[use_name] = gear_datums[use_name]

	loadout_categories = sortAssoc(loadout_categories)
	for(var/loadout_category in loadout_categories)
		var/datum/loadout_category/LC = loadout_categories[loadout_category]
		LC.gear = sortAssoc(LC.gear)
	return 1

/datum/category_item/player_setup_item/loadout
	name = "Loadout"
	show_in_character_setup = FALSE // RS Add: Character Designer - Loadout (Lira, September 2026)
	sort_order = 1

/datum/category_item/player_setup_item/loadout/load_character(var/savefile/S)
	from_file(S["gear_list"], pref.gear_list)
	from_file(S["gear_slot"], pref.gear_slot)
	if(pref.gear_list!=null && pref.gear_slot!=null)
		pref.gear = pref.gear_list["[pref.gear_slot]"]
	else
		from_file(S["gear"], pref.gear)
		pref.gear_slot = 1

/datum/category_item/player_setup_item/loadout/save_character(var/savefile/S)
	pref.gear_list["[pref.gear_slot]"] = pref.gear
	to_file(S["gear_list"], pref.gear_list)
	to_file(S["gear_slot"], pref.gear_slot)

/datum/category_item/player_setup_item/loadout/proc/valid_gear_choices(var/max_cost)
	. = list()
	var/mob/preference_mob = preference_mob() //VOREStation Add
	for(var/gear_name in gear_datums)
		var/datum/gear/G = gear_datums[gear_name]

		if(G.whitelisted && config.loadout_whitelist != LOADOUT_WHITELIST_OFF && pref.client) //VOREStation Edit.
			if(config.loadout_whitelist == LOADOUT_WHITELIST_STRICT && G.whitelisted != pref.species)
				continue
			if(config.loadout_whitelist == LOADOUT_WHITELIST_LAX && !is_alien_whitelisted(preference_mob(), GLOB.all_species[G.whitelisted]))
				continue
		if(max_cost && G.cost > max_cost)
			continue
		//VOREStation Edit Start
		if(preference_mob && preference_mob.client)
			if(G.ckeywhitelist && !(preference_mob.ckey in G.ckeywhitelist))
				continue
			if(G.character_name && !(preference_mob.client.prefs.real_name in G.character_name))
				continue
		//VOREStation Edit End
		. += gear_name

/datum/category_item/player_setup_item/loadout/sanitize_character()
	var/mob/preference_mob = preference_mob()
	if(!islist(pref.gear))
		pref.gear = list()
	if(!islist(pref.gear_list))
		pref.gear_list = list()

	for(var/gear_name in pref.gear)
		if(!(gear_name in gear_datums))
			pref.gear -= gear_name
	var/total_cost = 0
	for(var/gear_name in pref.gear)
		if(!gear_datums[gear_name])
			to_chat(preference_mob, "<span class='warning'>You cannot have more than one of the \the [gear_name]</span>")
			pref.gear -= gear_name
		else if(!(gear_name in valid_gear_choices()))
			to_chat(preference_mob, "<span class='warning'>You cannot take \the [gear_name] as you are not whitelisted for the species or item.</span>")		//Vorestation Edit
			pref.gear -= gear_name
		else
			var/datum/gear/G = gear_datums[gear_name]
			if(total_cost + G.cost > MAX_GEAR_COST)
				pref.gear -= gear_name
				to_chat(preference_mob, "<span class='warning'>You cannot afford to take \the [gear_name]</span>")
			else
				total_cost += G.cost

/datum/category_item/player_setup_item/loadout/proc/get_gear_metadata(var/datum/gear/G)
	. = pref.gear[G.display_name]
	if(!.)
		. = list()
		pref.gear[G.display_name] = .

/datum/category_item/player_setup_item/loadout/proc/get_tweak_metadata(var/datum/gear/G, var/datum/gear_tweak/tweak)
	var/list/metadata = get_gear_metadata(G)
	. = metadata["[tweak]"]
	if(!.)
		. = tweak.get_default()
		metadata["[tweak]"] = .

/datum/category_item/player_setup_item/loadout/proc/set_tweak_metadata(var/datum/gear/G, var/datum/gear_tweak/tweak, var/new_metadata)
	var/list/metadata = get_gear_metadata(G)
	metadata["[tweak]"] = new_metadata

// RS Edit: Character Designer - Loadout (Lira, September 2026)
/datum/category_item/player_setup_item/loadout/OnTopic(href, href_list, user)
	pref.open_body_markings_designer(user, "loadout")
	return TOPIC_HANDLED

/datum/gear
	var/display_name       //Name/index. Must be unique.
	var/description        //Description of this gear. If left blank will default to the description of the pathed item.
	var/path               //Path to item.
	var/cost = 1           //Number of points used. Items in general cost 1 point, storage/armor/gloves/special use costs 2 points.
	var/slot               //Slot to equip to.
	var/list/allowed_roles //Roles that can spawn with this item.
	var/whitelisted        //Term to check the whitelist for..
	var/sort_category = "General"
	var/list/gear_tweaks = list() //List of datums which will alter the item after it has been spawned.
	var/exploitable = 0		//Does it go on the exploitable information list?
	var/type_category = null
	var/customize = 1		//Can the item be customized; RS Add

/datum/gear/New()
	if(!description)
		var/obj/O = path
		description = initial(O.desc)
	if (customize == 1) //RS Add
		gear_tweaks = list(gear_tweak_free_name, gear_tweak_free_desc, GLOB.gear_tweak_free_matrix_recolor) //RS Edit - Port Chomp 6159

/datum/gear_data
	var/path
	var/location

/datum/gear_data/New(var/path, var/location)
	src.path = path
	src.location = location

/datum/gear/proc/spawn_item(var/location, var/metadata)
	var/datum/gear_data/gd = new(path, location)
	if(length(gear_tweaks) && metadata)
		for(var/datum/gear_tweak/gt in gear_tweaks)
			gt.tweak_gear_data(metadata["[gt]"], gd)
	var/item = new gd.path(gd.location)
	if(length(gear_tweaks) && metadata)
		for(var/datum/gear_tweak/gt in gear_tweaks)
			gt.tweak_item(item, metadata["[gt]"])
	var/mob/M = location
	if(istype(M) && exploitable) //Update exploitable info records for the mob without creating a duplicate object at their feet.
		M.amend_exploitable(item)
	return item
