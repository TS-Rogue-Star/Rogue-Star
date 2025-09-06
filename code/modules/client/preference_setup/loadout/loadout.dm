//////////////////////////////////////////////////////////////////////////////////////
//Updated by Lira for Rogue Star August 2025 to create a new gallery view with icons//
//////////////////////////////////////////////////////////////////////////////////////

var/list/loadout_categories = list()
var/list/gear_datums = list()

//RS Add: Caches to speed up loadout gallery (Lira, August 2025)
var/global/list/loadout_icon_cache_base = list()
var/global/list/loadout_icon_cache_worn = list()
var/global/list/loadout_human_wearable_cache = list()

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
	sort_order = 1
	var/current_tab = "General"

	//RS Add: Gallery vars (Lira, August 2025)
	var/last_search_query = null
	var/gallery_worn_preview = FALSE
	var/list/gallery_entries_cache = null

//RS Add: Determine if a given item type is wearable by humans (Lira, August 2025)
/datum/category_item/player_setup_item/loadout/proc/is_itemtype_human_compatible(var/itemtype)
	if(!ispath(itemtype, /obj/item))
		return FALSE
	var/key = "[itemtype]"
	if(LAZYACCESS(loadout_human_wearable_cache, key))
		return loadout_human_wearable_cache[key]
	var/ok = TRUE
	if(ispath(itemtype, /obj/item/clothing))
		var/obj/item/clothing/tmp = new itemtype(null)
		if(tmp)
			var/list/R = tmp.species_restricted
			if(islist(R) && R.len)
				var/exclusive = ("exclude" in R)
				if(exclusive)
					ok = !(SPECIES_HUMAN in R)
				else
					ok = (SPECIES_HUMAN in R)
			qdel(tmp)
	loadout_human_wearable_cache[key] = ok
	return ok

//RS Add: Loadout gallery (Lira, August 2025)
/datum/category_item/player_setup_item/loadout/proc/loadout_gallery_window(mob/user, var/category, var/page, var/search)
	var/dat = "<html><body style='background:#111;color:#ddd;font-family:Verdana,Arial;'><center>"
	dat += "<h3>Select Loadout Items</h3>"
	var/search_link = "<a href='?src=\ref[src];loadout_gallery_search=1'>Search</a>"
	if(search)
		search_link = "Search: <b>[html_encode(search)]</b> ( <a href='?src=\ref[src];loadout_gallery_search_clear=1'>clear</a> )"
	var/prev_label = gallery_worn_preview ? "Worn" : "Base"
	var/prev_toggle = "Preview: <a href='?src=\ref[src];loadout_gallery_preview_toggle=1" + (search ? ";loadout_gallery_search_term=[url_encode(search)]" : "") + "'>[prev_label]</a>"
	dat += "<div>" + search_link + " | " + prev_toggle + " | <a href='?src=\ref[src];loadout_gallery_close=1'>Close</a></div>"

	var/total_cost = 0
	if(pref.gear && pref.gear.len)
		for(var/i = 1 to pref.gear.len)
			var/datum/gear/Gh = gear_datums[pref.gear[i]]
			if(istype(Gh)) total_cost += Gh.cost
	var/fcolor =  "#3366CC"
	if(total_cost < MAX_GEAR_COST)
		fcolor = "#E67300"
	dat += "<div style='margin:6px;'><b><font color='[fcolor]'>[total_cost]/[MAX_GEAR_COST]</font> loadout points spent.</b></div>"

	var/list/cats = sortAssoc(loadout_categories)
	if(!category || !(category in cats))
		category = src.current_tab
	if(!category || !(category in cats))
		category = (cats.len ? cats[1] : "General")
	var/catbar = ""
	for(var/c in cats)
		if(c == category)
			catbar += " <b>[c]</b>"
		else
			catbar += " <a href='?src=\ref[src];loadout_gallery_cat=[url_encode(c)]" + (search ? ";loadout_gallery_search_term=[url_encode(search)]" : "") + "'>[c]</a>"
	dat += "<div style='margin:6px;padding:6px;border:1px solid #333;background:#111;'>[catbar]</div>"

	var/list/valid_names = valid_gear_choices()
	var/datum/loadout_category/LC = loadout_categories[category]
	var/page_num = max(1, text2num(page) || 1)
	var/list/entries = list()
	var/list/categories_to_scan = list()

	if(LC && istype(LC))
		categories_to_scan += category

	if(!search)
		if(!gallery_entries_cache)
			gallery_entries_cache = list()
		if(LAZYACCESS(gallery_entries_cache, category))
			entries = gallery_entries_cache[category]
		else
			var/datum/loadout_category/LCb = loadout_categories[category]
			if(LCb && istype(LCb))
				for(var/gear_name in LCb.gear)
					if(!(gear_name in valid_names))
						continue
					var/datum/gear/G2b = gear_datums[gear_name]
					if(!istype(G2b))
						continue
					var/list/expanded_b = null
					for(var/datum/gear_tweak/path/PTb in G2b.gear_tweaks)
						expanded_b = PTb.valid_paths
						break
					if(islist(expanded_b) && expanded_b.len)
						for(var/variant_name_b in expanded_b)
							entries += list(list("g" = gear_name, "v" = variant_name_b))
					else
						entries += list(list("g" = gear_name))
			gallery_entries_cache[category] = entries
	else
		for(var/cn in categories_to_scan)
			var/datum/loadout_category/LC2 = loadout_categories[cn]
			if(!LC2 || !istype(LC2))
				continue
			for(var/gear_name in LC2.gear)
				if(!(gear_name in valid_names))
					continue
				var/datum/gear/G2 = gear_datums[gear_name]
				if(!istype(G2))
					continue
				var/list/expanded = null
				for(var/datum/gear_tweak/path/PT in G2.gear_tweaks)
					expanded = PT.valid_paths
					break
				if(islist(expanded) && expanded.len)
					for(var/variant_name in expanded)
						var/atom/alt = expanded[variant_name]
						var/base_name = initial(alt.name)
						var/needle = lowertext(search)
						if(!findtext(lowertext(variant_name), needle) && !findtext(lowertext(base_name), needle) && !findtext(lowertext(gear_name), needle))
							continue
						entries += list(list("g" = gear_name, "v" = variant_name))
				else
					var/atom/itemtype0 = G2.path
					var/base_name0 = initial(itemtype0.name)
					var/needle0 = lowertext(search)
					if(!findtext(lowertext(base_name0), needle0) && !findtext(lowertext(gear_name), needle0))
						continue
					entries += list(list("g" = gear_name))

	//Sort entries alphabetically by underlying name
	var/list/sortmap = list()
	var/sidx = 0
	for(var/entry in entries)
		sidx += 1
		var/gear_name = entry["g"]
		var/variant_name = entry["v"]
		var/datum/gear/Gs = gear_datums[gear_name]
		var/atom/itemtype_sort = Gs.path
		var/skey
		if(variant_name)
			skey = lowertext("[variant_name]")
		else
			skey = lowertext("[initial(itemtype_sort.name)]")
		var/ukey = "[skey]#[sidx]"
		sortmap[ukey] = entry
	var/list/sorted_keys = sortList(sortmap)

	if(LAZYLEN(sorted_keys))
		var/page_size = gallery_worn_preview ? 60 : 60
		var/total = sorted_keys.len
		var/total_pages = max(1, round((total + page_size - 1) / page_size))
		if(page_num > total_pages) page_num = total_pages
		var/icon/I = null
		var/start_i = ((page_num - 1) * page_size) + 1
		var/end_i = min(total, page_num * page_size)
		var/prev_link = (page_num > 1) ? "<a href='?src=\ref[src];loadout_gallery_page=[page_num-1];loadout_gallery_cat=[url_encode(category)]" + (search ? ";loadout_gallery_search_term=[url_encode(search)]" : "") + "'>Prev</a>" : "Prev"
		var/next_link = (page_num < total_pages) ? "<a href='?src=\ref[src];loadout_gallery_page=[page_num+1];loadout_gallery_cat=[url_encode(category)]" + (search ? ";loadout_gallery_search_term=[url_encode(search)]" : "") + "'>Next</a>" : "Next"
		dat += "<div style='margin:6px;'>[prev_link] | Page [page_num] / [total_pages] | [next_link]</div>"
		dat += "<div style='max-height:640px; overflow-y:auto; padding:6px; border:1px solid #333; background:#111; margin:6px;'>"
		dat += "<table cellspacing='6' cellpadding='0' style='border-collapse:separate;'><tr>"
		var/col = 0
		var/max_cols = 6
		for(var/idx = start_i to end_i)
			var/key = sorted_keys[idx]
			I = null
			if(!key)
				continue
			var/list/entry = sortmap[key]
			var/gear_name = entry["g"]
			var/variant_name = entry["v"]
			var/datum/gear/G = gear_datums[gear_name]
			if(!istype(G)) continue
			var/atom/itemtype = G.path
			var/datum/gear_tweak/path/path_tweak = null
			for(var/datum/gear_tweak/path/PT in G.gear_tweaks)
				path_tweak = PT
				break
			if(variant_name && path_tweak)
				var/atom/alt = path_tweak.valid_paths[variant_name]
				if(ispath(alt))
					itemtype = alt
			var/slot_name_cached = null
			if(gallery_worn_preview)
				slot_name_cached = get_slot_name_for_path(itemtype)
			var/human_ok = TRUE
			if(slot_name_cached)
				human_ok = is_itemtype_human_compatible(itemtype)
			//Try cache first
			if(gallery_worn_preview && slot_name_cached && human_ok)
				var/c_key_w = "[itemtype]#[slot_name_cached]"
				if(LAZYACCESS(loadout_icon_cache_worn, c_key_w))
					var/icon/I_w = loadout_icon_cache_worn[c_key_w]
					if(isicon(I_w))
						I = I_w
			else
				var/c_key_b = "[itemtype]"
				if(LAZYACCESS(loadout_icon_cache_base, c_key_b))
					var/icon/I_b = loadout_icon_cache_base[c_key_b]
					if(isicon(I_b))
						I = I_b

			//No cache entry
			//Worn first try
			if(gallery_worn_preview && !isicon(I) && human_ok)
				var/icon/base_icon = icon(get_markings_base_preview_icon())
				var/applied = FALSE
				var/slot_name = slot_name_cached
				if(slot_name)
					var/def_file = get_default_worn_icon_for_slot(slot_name)
					var/obj/item/temp = new itemtype(null)
					var/file2 = temp.get_worn_icon_file(null, slot_name, def_file, FALSE)
					var/state2 = temp.get_worn_icon_state(slot_name)
					if(istype(temp, /obj/item/clothing/under))
						var/ws2 = temp.vars["worn_state"]
						if(!isnull(ws2))
							state2 = ws2
					if(file2 && (isfile(file2) || isicon(file2)) && state2 && (state2 in icon_states(file2)))
						var/icon/acc2 = null
						try
							acc2 = new/icon(icon = file2, icon_state = state2, frame = 1)
						catch(var/exception/E_acc2)
							log_debug("Loadout gallery worn: icon build failed for [G?.display_name] ([itemtype]) file=[file2] state=[state2]: [E_acc2]")
						if(isicon(acc2))
							base_icon.Blend(acc2, ICON_OVERLAY)
							applied = TRUE
					//Second try: use make_worn_icon base layer
					if(!applied)
						var/image/standing = temp.make_worn_icon(null, slot_name, FALSE, def_file, 0, null)
						if(standing && istype(standing))
							var/I_src = standing.icon
							var/icon/acc = null
							if(I_src)
								acc = getFlatIcon(standing)
							if(isicon(acc))
								base_icon.Blend(acc, ICON_OVERLAY)
								applied = TRUE
					if(temp) qdel(temp)
				if(applied)
					var/icon/ib = null
					try
						ib = icon(base_icon)
					catch(var/exception/E_ib)
						log_debug("Loadout gallery worn: base_icon copy failed for [G?.display_name] ([itemtype]): [E_ib]")
					if(isicon(ib))
						I = ib

			//If preview failed or not requested, try base icon
			if(!isicon(I))
				var/icon_file = initial(itemtype.icon)
				var/icon_state = initial(itemtype.icon_state)
				if(icon_file && (isfile(icon_file) || isicon(icon_file)))
					var/icon_states_list = icon_states(icon_file)
					if(icon_state && (icon_state in icon_states_list))
						I = icon(icon_file, icon_state, SOUTH, 1)
			//Fallback: Create the item and use its current icon/item_state
			if(!isicon(I))
				if(ispath(itemtype, /obj/item))
					var/obj/item/base_tmp = new itemtype(null)
					if(base_tmp)
						var/icon_file2 = base_tmp.icon
						if(icon_file2 && (isfile(icon_file2) || isicon(icon_file2)))
							var/icon_states_list2 = icon_states(icon_file2)
							var/icon_state2 = base_tmp.icon_state
							var/item_state2 = base_tmp.item_state
							if(icon_state2 && (icon_state2 in icon_states_list2))
								var/icon/it1 = null
								try
									it1 = icon(icon_file2, icon_state2, SOUTH, 1)
								catch(var/exception/E_it1)
									log_debug("Loadout gallery: icon build2 failed for [G?.display_name] ([itemtype]) file=[icon_file2] state=[icon_state2]: [E_it1]")
								if(isicon(it1)) I = it1
							else if(item_state2 && (item_state2 in icon_states_list2))
								var/icon/it2 = null
								try
									it2 = icon(icon_file2, item_state2, SOUTH, 1)
								catch(var/exception/E_it2)
									log_debug("Loadout gallery: icon build3 failed for [G?.display_name] ([itemtype]) file=[icon_file2] state=[item_state2]: [E_it2]")
								if(isicon(it2)) I = it2
						qdel(base_tmp)

			//Special-case: certain overlay-based items have a deliberately blank base state; use known icon/state
			if(ispath(itemtype, /obj/item/weapon/material/ashtray))
				I = icon('icons/obj/objects.dmi', "ashtray", SOUTH, 1)

			//Fallback to plain icon markup if still missing
			if(!isicon(I))
				I = icon('icons/turf/floors.dmi', "", SOUTH, 1)

			//Scale once and store in cache
			if(isicon(I))
				I.Scale(64, 64)
				if(gallery_worn_preview && slot_name_cached)
					var/cw = "[itemtype]#[slot_name_cached]"
					if(!LAZYACCESS(loadout_icon_cache_worn, cw))
						loadout_icon_cache_worn[cw] = I
				else
					var/cb = "[itemtype]"
					if(!LAZYACCESS(loadout_icon_cache_base, cb))
						loadout_icon_cache_base[cb] = I

			var/selected = (G.display_name in pref.gear)
			if(variant_name && path_tweak && selected)
				var/current_choice = get_tweak_metadata(G, path_tweak)
				selected = (current_choice == variant_name)
			var/cell_style = selected ? "border:2px solid #66a3ff;" : "border:1px solid #444;"
			dat += "<td style='[cell_style] background:#222; text-align:center; width:120px; height:140px; vertical-align:top; padding:4px;'>"
			dat += "<div style='display:block;margin:0 auto;'>"
			var/href_extra = variant_name ? ";loadout_toggle_variant=[url_encode(variant_name)]" : ""
			dat += "<a href='?src=\ref[src];loadout_toggle=[url_encode(G.display_name)][href_extra];loadout_gallery_cat=[url_encode(category)];loadout_gallery_page=[page_num]" + (search ? ";loadout_gallery_search_term=[url_encode(search)]" : "") + "' title='[html_encode(G.description)]'>[bicon(I)]</a>"
			dat += "</div>"
			var/label = variant_name ? "[variant_name] ([G.cost])" : "[G.display_name] ([G.cost])"
			dat += "<div style='font-size:11px;color:#ccc;margin-top:4px;max-width:112px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;' title='[G.display_name]'>[label]</div>"
			dat += "</td>"
			col += 1
			if(col >= max_cols)
				dat += "</tr><tr>"
				col = 0
		dat += "</tr></table>"
		dat += "</div>"
	else
		dat += "<p>No loadout items available in this category.</p>"

		dat += "<div><a href='?src=\ref[src];loadout_gallery_close=1'>Close</a></div>"
	dat += "</center></body></html>"
	user << browse(dat, "window=prefs_loadout_gallery;size=1000x900")

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

/datum/category_item/player_setup_item/loadout/content()
	. = list()
	var/mob/preference_mob = preference_mob()	//Vorestation Edit
	var/total_cost = 0
	if(pref.gear && pref.gear.len)
		for(var/i = 1; i <= pref.gear.len; i++)
			var/datum/gear/G = gear_datums[pref.gear[i]]
			if(G)
				total_cost += G.cost

	var/fcolor =  "#3366CC"
	if(total_cost < MAX_GEAR_COST)
		fcolor = "#E67300"

	. += "<table align = 'center' width = 100%>"
	. += "<tr><td colspan=3><center><a href='?src=\ref[src];loadout_gallery=1'>Loadout Gallery</a></center></td></tr>" // RS Add: Open new gallery (Lira, August 2025)
	. += "<tr><td colspan=3><center><a href='?src=\ref[src];prev_slot=1'>\<\<</a><b><font color = '[fcolor]'>\[[pref.gear_slot]\]</font> </b><a href='?src=\ref[src];next_slot=1'>\>\></a><b><font color = '[fcolor]'>[total_cost]/[MAX_GEAR_COST]</font> loadout points spent.</b> \[<a href='?src=\ref[src];clear_loadout=1'>Clear Loadout</a>\]</center></td></tr>"

	. += "<tr><td colspan=3><center><b>"
	var/firstcat = 1
	for(var/category in loadout_categories)

		if(firstcat)
			firstcat = 0
		else
			. += " |"

		var/datum/loadout_category/LC = loadout_categories[category]
		var/category_cost = 0
		for(var/gear in LC.gear)
			if(gear in pref.gear)
				var/datum/gear/G = LC.gear[gear]
				category_cost += G.cost

		if(category == current_tab)
			. += " <span class='linkOn'>[category] - [category_cost]</span> "
		else
			if(category_cost)
				. += " <a href='?src=\ref[src];select_category=[category]'><font color = '#E67300'>[category] - [category_cost]</font></a> "
			else
				. += " <a href='?src=\ref[src];select_category=[category]'>[category] - 0</a> "
	. += "</b></center></td></tr>"

	var/datum/loadout_category/LC = loadout_categories[current_tab]
	. += "<tr><td colspan=3><hr></td></tr>"
	. += "<tr><td colspan=3><b><center>[LC.category]</center></b></td></tr>"
	. += "<tr><td colspan=3><hr></td></tr>"
	for(var/gear_name in LC.gear)
		var/datum/gear/G = LC.gear[gear_name]
		//VOREStation Edit Start
		if(preference_mob && preference_mob.client)
			if(G.ckeywhitelist && !(preference_mob.ckey in G.ckeywhitelist))
				continue
			if(G.character_name && !(preference_mob.client.prefs.real_name in G.character_name))
				continue
		//VOREStation Edit End
		var/ticked = (G.display_name in pref.gear)
		. += "<tr style='vertical-align:top;'><td width=25%><a style='white-space:normal;' [ticked ? "class='linkOn' " : ""]href='?src=\ref[src];toggle_gear=[html_encode(G.display_name)]'>[G.display_name]</a></td>"
		. += "<td width = 10% style='vertical-align:top'>[G.cost]</td>"
		. += "<td><font size=2><i>[G.description]</i></font></td></tr>"
		if(ticked)
			. += "<tr><td colspan=3>"
			for(var/datum/gear_tweak/tweak in G.gear_tweaks)
				. += " <a href='?src=\ref[src];gear=[url_encode(G.display_name)];tweak=\ref[tweak]'>[tweak.get_contents(get_tweak_metadata(G, tweak))]</a>"
			. += "</td></tr>"
	. += "</table>"
	. = jointext(., null)

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

//RS Add: Gallery support datum (Lira, August 2025)
/datum/category_item/player_setup_item/loadout/proc/get_slot_name_for_path(var/itemtype)
	if(ispath(itemtype, /obj/item/clothing/under))
		return slot_w_uniform_str
	if(ispath(itemtype, /obj/item/clothing/suit))
		return slot_wear_suit_str
	if(ispath(itemtype, /obj/item/clothing/head))
		return slot_head_str
	if(ispath(itemtype, /obj/item/clothing/glasses))
		return slot_glasses_str
	if(ispath(itemtype, /obj/item/clothing/mask))
		return slot_wear_mask_str
	if(ispath(itemtype, /obj/item/clothing/gloves))
		return slot_gloves_str
	if(ispath(itemtype, /obj/item/clothing/shoes))
		return slot_shoes_str
	if(ispath(itemtype, /obj/item/weapon/storage/belt))
		return slot_belt_str
	if(ispath(itemtype, /obj/item/weapon/storage/backpack) || ispath(itemtype, /obj/item/weapon/storage/backpack/dufflebag))
		return slot_back_str
	if(ispath(itemtype, /obj/item/clothing/accessory))
		return slot_tie_str
	if(ispath(itemtype, /obj/item/clothing/ears))
		return slot_l_ear_str
	return null

//RS Add: Gallery support datum (Lira, August 2025)
/datum/category_item/player_setup_item/loadout/proc/get_default_worn_icon_for_slot(var/slot_name)
	if(slot_name == slot_w_uniform_str)
		return INV_W_UNIFORM_DEF_ICON
	if(slot_name == slot_wear_suit_str)
		return INV_SUIT_DEF_ICON
	if(slot_name == slot_head_str)
		return INV_HEAD_DEF_ICON
	if(slot_name == slot_glasses_str)
		return INV_EYES_DEF_ICON
	if(slot_name == slot_wear_mask_str)
		return INV_MASK_DEF_ICON
	if(slot_name == slot_gloves_str)
		return INV_GLOVES_DEF_ICON
	if(slot_name == slot_shoes_str)
		return INV_FEET_DEF_ICON
	if(slot_name == slot_belt_str)
		return INV_BELT_DEF_ICON
	if(slot_name == slot_back_str)
		return INV_BACK_DEF_ICON
	if(slot_name == slot_tie_str)
		return INV_ACCESSORIES_DEF_ICON
	return null

/datum/category_item/player_setup_item/loadout/OnTopic(href, href_list, user)

	//RS Add Start: Gallery href support (Lira, August 2025)
	if(href_list["loadout_gallery"]) //Open gallery window
		src.loadout_gallery_window(user, src.current_tab, 1, null)
		return TOPIC_HANDLED
	if(href_list["loadout_gallery_close"]) //Close gallery window
		user << browse(null, "window=prefs_loadout_gallery")
		return TOPIC_HANDLED
	if(href_list["loadout_gallery_preview_toggle"]) //Toggle worn mode
		gallery_worn_preview = !gallery_worn_preview
		var/page = text2num(href_list["loadout_gallery_page"]) || 1
		var/cat = url_decode(href_list["loadout_gallery_cat"]) || src.current_tab
		var/search = href_list["loadout_gallery_search_term"] ? url_decode(href_list["loadout_gallery_search_term"]) : null
		src.loadout_gallery_window(user, cat, page, search)
		return TOPIC_HANDLED
	if(href_list["loadout_gallery_search"]) //Search prompt
		var/q = input(user, "Search loadout items by name:", "Loadout Search", src.last_search_query) as text|null
		if(isnull(q))
			return TOPIC_HANDLED
		src.last_search_query = q
		src.loadout_gallery_window(user, src.current_tab, 1, q)
		return TOPIC_HANDLED
	if(href_list["loadout_gallery_search_clear"]) //Clear search
		src.last_search_query = null
		src.loadout_gallery_window(user, src.current_tab, 1, null)
		return TOPIC_HANDLED
	if(href_list["loadout_toggle"]) //Toggle gear from gallery
		var/name = url_decode(href_list["loadout_toggle"])
		var/variant = href_list["loadout_toggle_variant"] ? url_decode(href_list["loadout_toggle_variant"]) : null
		var/datum/gear/TG = gear_datums[name]
		if(istype(TG))
			var/datum/gear_tweak/path/path_tweak = null
			for(var/datum/gear_tweak/path/PT in TG.gear_tweaks)
				path_tweak = PT
				break
			var/already = (TG.display_name in pref.gear)
			if(already)
				if(variant && path_tweak)
					var/current_choice = get_tweak_metadata(TG, path_tweak)
					if(current_choice == variant)
						pref.gear -= TG.display_name
					else
						set_tweak_metadata(TG, path_tweak, variant)
				else
					pref.gear -= TG.display_name
			else
				var/total_cost = 0
				for(var/gear_name in pref.gear)
					var/datum/gear/G = gear_datums[gear_name]
					if(istype(G)) total_cost += G.cost
				if((total_cost+TG.cost) <= MAX_GEAR_COST)
					pref.gear += TG.display_name
					if(variant && path_tweak)
						set_tweak_metadata(TG, path_tweak, variant)
		var/page = text2num(href_list["loadout_gallery_page"]) || 1
		var/cat = url_decode(href_list["loadout_gallery_cat"]) || src.current_tab
		var/search = href_list["loadout_gallery_search_term"] ? url_decode(href_list["loadout_gallery_search_term"]) : null
		src.loadout_gallery_window(user, cat, page, search)
		return TOPIC_REFRESH_UPDATE_PREVIEW
	if(href_list["loadout_gallery_cat"]) //Change gallery category
		var/cat = url_decode(href_list["loadout_gallery_cat"]) || src.current_tab
		src.current_tab = cat
		var/page = text2num(href_list["loadout_gallery_page"]) || 1
		var/search = href_list["loadout_gallery_search_term"] ? url_decode(href_list["loadout_gallery_search_term"]) : null
		src.loadout_gallery_window(user, cat, page, search)
		return TOPIC_HANDLED
	if(href_list["loadout_gallery_page"]) //Change gallery page
		var/page = text2num(href_list["loadout_gallery_page"]) || 1
		var/cat = url_decode(href_list["loadout_gallery_cat"]) || src.current_tab
		var/search = href_list["loadout_gallery_search_term"] ? url_decode(href_list["loadout_gallery_search_term"]) : null
		src.loadout_gallery_window(user, cat, page, search)
		return TOPIC_HANDLED
	//RS Add End

	if(href_list["toggle_gear"])
		var/datum/gear/TG = gear_datums[href_list["toggle_gear"]]
		if(TG.display_name in pref.gear)
			pref.gear -= TG.display_name
		else
			var/total_cost = 0
			for(var/gear_name in pref.gear)
				var/datum/gear/G = gear_datums[gear_name]
				if(istype(G)) total_cost += G.cost
			if((total_cost+TG.cost) <= MAX_GEAR_COST)
				pref.gear += TG.display_name
		return TOPIC_REFRESH_UPDATE_PREVIEW
	if(href_list["gear"] && href_list["tweak"])
		var/datum/gear/gear = gear_datums[url_decode(href_list["gear"])]
		var/datum/gear_tweak/tweak = locate(href_list["tweak"])
		if(!tweak || !istype(gear) || !(tweak in gear.gear_tweaks))
			return TOPIC_NOACTION
		// RS Edit: Updated to call color matrix when appropriate (Lira, September 2025)
		var/metadata
		if(istype(tweak, /datum/gear_tweak/matrix_recolor))
			var/datum/gear_tweak/matrix_recolor/mt = tweak
			metadata = mt.get_metadata(user, get_tweak_metadata(gear, mt), gear, get_gear_metadata(gear))
		else
			metadata = tweak.get_metadata(user, get_tweak_metadata(gear, tweak))
		// RS Edit End
		if(!metadata || !CanUseTopic(user))
			return TOPIC_NOACTION
		set_tweak_metadata(gear, tweak, metadata)
		return TOPIC_REFRESH_UPDATE_PREVIEW
	if(href_list["next_slot"] || href_list["prev_slot"])
		//Set the current slot in the gear list to the currently selected gear
		pref.gear_list["[pref.gear_slot]"] = pref.gear
		//If we're moving up a slot..
		if(href_list["next_slot"])
			//change the current slot number
			pref.gear_slot = pref.gear_slot+1
			if(pref.gear_slot>config.loadout_slots)
				pref.gear_slot = 1
		//If we're moving down a slot..
		else if(href_list["prev_slot"])
			//change current slot one down
			pref.gear_slot = pref.gear_slot-1
			if(pref.gear_slot<1)
				pref.gear_slot = config.loadout_slots
		// Set the currently selected gear to whatever's in the new slot
		if(pref.gear_list["[pref.gear_slot]"])
			pref.gear = pref.gear_list["[pref.gear_slot]"]
		else
			pref.gear = list()
			pref.gear_list["[pref.gear_slot]"] = list()
		// Refresh?
		return TOPIC_REFRESH_UPDATE_PREVIEW
	else if(href_list["select_category"])
		current_tab = href_list["select_category"]
		return TOPIC_REFRESH
	else if(href_list["clear_loadout"])
		pref.gear.Cut()
		return TOPIC_REFRESH_UPDATE_PREVIEW
	return ..()

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
