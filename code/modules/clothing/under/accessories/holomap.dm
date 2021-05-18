/obj/item/device/mapping_unit
	name = "mapping unit"
	desc = "A device meant to be attached on a jumpsuit, granting a certain degree of situational awareness."
	icon_state = "mapping_unit"
	item_state = null

	//Holomap stuff
	var/marker_prefix = "basic"
	var/base_prefix = "basic"
	var/holomap_color = null
	var/holomap_filter = HOLOMAP_FILTER_STATIONMAP

	var/list/prefix_update_head
	var/list/prefix_update_rig

	// These are local because they are different for every holochip.
	// The maps and icons are all pixel_x and pixel_y'd so we're in the center.
	var/list/map_image_cache = list()
	var/list/icon_image_cache = list()

	var/pinging = FALSE
	var/updating = FALSE
	var/obj/screen/movable/holomap_holder/hud_item
	var/global/icon/mask_icon
	var/obj/screen/holomap/extras_holder/extras_holder

/obj/item/device/mapping_unit/deathsquad
	name = "deathsquad holomap chip"
	//icon_state = "holochip_ds"
	marker_prefix = "ds"
	holomap_filter = HOLOMAP_FILTER_DEATHSQUAD
	//holomap_color = "#0B74B4"

/obj/item/device/mapping_unit/operative
	name = "nuclear operative holomap chip"
	//icon_state = "holochip_op"
	marker_prefix = "op"
	holomap_filter = HOLOMAP_FILTER_NUKEOPS
	//holomap_color = "#13B40B"

/obj/item/device/mapping_unit/ert
	name = "emergency response team holomap chip"
	//icon_state = "holochip_ert"
	marker_prefix = "ert"
	holomap_filter = HOLOMAP_FILTER_ERT
	//holomap_color = "#5FFF28"

	prefix_update_head = list(
		"/obj/item/clothing/head/helmet/ert/command" = "ertc",
		"/obj/item/clothing/head/helmet/ert/security" = "erts",
		"/obj/item/clothing/head/helmet/ert/engineer" = "erte",
		"/obj/item/clothing/head/helmet/ert/medical" = "ertm",
	)
	
	prefix_update_rig = list(
		"/obj/item/weapon/rig/ert" = "ertc",
		"/obj/item/weapon/rig/ert/security" = "erts",
		"/obj/item/weapon/rig/ert/engineer" = "erte",
		"/obj/item/weapon/rig/ert/medical" = "ertm"
	)

/obj/item/device/mapping_unit/Initialize()
	. = ..()
	mapping_units += src
	base_prefix = marker_prefix

	if(!mask_icon)
		mask_icon = icon('icons/effects/64x64.dmi', "holomap_mask")
	
	extras_holder = new()
	
	var/obj/screen/holomap/marker/mark = new()
	mark.icon = 'icons/effects/64x64.dmi'
	mark.icon_state = "holomap_none"
	mark.layer = 5
	icon_image_cache["bad"] = mark

	var/obj/screen/holomap/map/tmp = new()
	var/icon/canvas = icon(HOLOMAP_ICON, "blank")
	canvas.Crop(1,1,world.maxx,world.maxy)
	canvas.DrawBox("#A7BE97",1,1,world.maxx,world.maxy)
	tmp.icon = icon
	map_image_cache["bad"] = tmp


/obj/item/device/mapping_unit/Destroy()
	mapping_units -= src

	detach_holomap()

	QDEL_LIST_NULL(map_image_cache)
	QDEL_LIST_NULL(icon_image_cache)
	qdel_null(extras_holder)

	return ..()

/obj/item/device/mapping_unit/attack_self()
	togglemap()

/obj/item/device/mapping_unit/dropped(mob/dropper)
	if(loc != dropper) // Not just a juggle
		detach_holomap()

/obj/item/device/mapping_unit/proc/togglemap()
	if(usr.stat != CONSCIOUS)
		return

	if(!ishuman(usr))
		to_chat(usr, "<span class='warning'>Only humanoids can use this device.</span>")
		return

	var/mob/living/carbon/human/H = usr

	if(!ishuman(loc) || usr != loc)
		to_chat(H, "<span class='warning'>This device needs to be on your person.</span>")

	if(hud_item)
		if(detach_holomap(H))
			to_chat(H, "<span class='notice'>You put the [src] away.</span>")
	else if(attach_holomap(H))
		to_chat(H, "<span class='notice'>You hold the [src] where you can see it.</span>")



/obj/item/device/mapping_unit/proc/detach_holomap()
	stop_updates()
	hud_item?.detach(src)
	hud_item = null
	return TRUE

/obj/item/device/mapping_unit/proc/stop_updates()
	STOP_PROCESSING(SSobj, src)
	updating = FALSE



/obj/item/device/mapping_unit/proc/attach_holomap(mob/user)
	if(hud_item)
		detach_holomap()
	hud_item = user.hud_used.holomap_obj
	return hud_item?.attach(src)

/obj/item/device/mapping_unit/proc/start_updates()
	START_PROCESSING(SSobj, src)
	process()
	updating = TRUE



/obj/item/device/mapping_unit/process()
	update_holomap()


#define HOLOMAP_ERROR	0
#define HOLOMAP_YOU		1
#define HOLOMAP_OTHER	2
#define HOLOMAP_DEAD	3

/obj/item/device/mapping_unit/proc/handle_sanity(var/turf/T)
	if(!hud_item || isnull(SSholomaps.holoMiniMaps[T.z]))
		return FALSE
	return TRUE

/obj/item/device/mapping_unit/proc/update_holomap()
	if(!hud_item)
		detach_holomap()
		return

	var/turf/T = get_turf(src)
	if(!T)//nullspace begone!
		return

	if(!handle_sanity(T))
		detach_holomap()
		return

	var/T_x = T.x // Used many times, just grab it to avoid derefs
	var/T_y = T.y
	var/T_z = T.z

	var/obj/screen/holomap/map/bgmap
	var/list/extras = list()

	var/map_cache_key = "[T_z]"
	var/badmap = FALSE
	if(!pinging && using_map && !(T_z in using_map.mappable_levels))
		map_cache_key = "bad"
		badmap = TRUE

	// Cache miss
	if(!(map_cache_key in map_image_cache))
		var/mutable_appearance/map_app = new()
		map_app.appearance_flags = PIXEL_SCALE
		map_app.plane = PLANE_HOLOMAP
		map_app.layer = HUD_LAYER
		map_app.color = holomap_color

		if(!SSholomaps.holoMiniMaps[T_z])
			var/obj/screen/holomap/map/baddo = map_image_cache["bad"]
			map_app.icon = icon(baddo.icon)
			badmap = TRUE
		// SSholomaps did map it and we're allowed to see it
		else
			map_app.icon = icon(SSholomaps.holoMiniMaps[T.z])

			// Apply markers
			for(var/marker in holomap_markers)
				var/datum/holomap_marker/holomarker = holomap_markers[marker]
				if(holomarker.z == T_z && holomarker.filter & holomap_filter)
					var/image/markerImage = image(holomarker.icon,holomarker.id)
					markerImage.plane = FLOAT_PLANE
					markerImage.layer = FLOAT_LAYER
					markerImage.appearance_flags = RESET_COLOR|PIXEL_SCALE
					markerImage.pixel_x = holomarker.x+holomarker.offset_x
					markerImage.pixel_y = holomarker.y+holomarker.offset_y
					map_app.overlays += markerImage

			var/obj/screen/holomap/map/tmp = new()
			tmp.appearance = map_app
			map_image_cache[map_cache_key] = tmp

	bgmap = map_image_cache[map_cache_key]

	// The holomap moves around, the user is always in the center. This slides the holomap.
	var/offset_x = bgmap.offset_x
	var/offset_y = bgmap.offset_y
	extras_holder.pixel_x = bgmap.pixel_x = -1*T_x + offset_x
	extras_holder.pixel_y = bgmap.pixel_y = -1*T_y + offset_y
	//animate(bgmap,pixel_x = map_offset_x, pixel_y = map_offset_y, time = 5, easing = LINEAR_EASING)

	// Populate holomap chip icons
	for(var/hc in mapping_units)
		var/obj/item/device/mapping_unit/HC = hc
		if(!HC.updating || HC.holomap_filter != holomap_filter)
			continue
		var/mob_indicator = HOLOMAP_ERROR
		var/turf/TU = get_turf(HC)
		
		// Marker not on a turf
		if(!TU)
			continue
		
		// We're the marker
		if(HC == src)
			mob_indicator = HOLOMAP_YOU
		
		// The marker is held by a borg
		else if((TU.z == T_z) && isrobot(HC.loc))
			var/mob/living/silicon/robot/R = HC.loc
			if(R.stat == DEAD)
				mob_indicator = HOLOMAP_DEAD
			else
				mob_indicator = HOLOMAP_OTHER
		
		// The marker is worn by a human
		else if((TU.z == T_z) && ishuman(loc))
			var/mob/living/carbon/human/H = loc
			if(H.stat == DEAD)
				mob_indicator = HOLOMAP_DEAD
			else
				mob_indicator = HOLOMAP_OTHER
		
		// It's not attached to anything useful
		else
			continue

		
		// Ask it to update it's icon based on helmet (or whatever)
		HC.update_marker()

		// Generate the icon and apply it to the list of images to show the client
		if(mob_indicator != HOLOMAP_ERROR)

			// This is so specific because the icons are pixel_x and pixel_y only relative to OUR view of where THEY are relative to us
			var/marker_cache_key = "\ref[HC]_[HC.marker_prefix]_[mob_indicator]"

			if(!(marker_cache_key in icon_image_cache))
				var/obj/screen/holomap/marker/mark = new()
				mark.icon_state = "[HC.marker_prefix][mob_indicator]"
				icon_image_cache[marker_cache_key] = mark

			var/obj/screen/holomap/marker/mark = icon_image_cache[marker_cache_key]
			handle_marker(mark,TU.x,TU.y)
			
			if(mob_indicator == HOLOMAP_YOU)
				mark.layer = 1 // Above the other markers

			extras += mark

	//Additional things we might want to track
	extra_update()

	if(badmap)
		var/obj/O = icon_image_cache["bad"]
		O.pixel_x = T_x - offset_x
		O.pixel_y = T_y - offset_y
		extras += icon_image_cache["bad"]

	extras_holder.filters = filter(type = "alpha", icon = mask_icon, x = T_x-(offset_x*0.5), y = T_y-(offset_y*0.5))
	extras_holder.vis_contents = extras

	hud_item.update(bgmap, extras_holder, badmap ? FALSE : pinging)
	

/obj/item/device/mapping_unit/proc/extra_update()
	return

/*
/obj/item/device/mapping_unit/deathsquad/extra_update()
	
	var/turf/T = get_turf(src)
	for(var/obj/mecha/combat/marauder/maraud in mechas_list)
		if(!istype(maraud,/obj/mecha/combat/marauder/series) && !istype(maraud,/obj/mecha/combat/marauder/mauler) && (T.z == maraud.z))//ignore custom-built and syndicate ones
			var/holomap_marker = "marker_\ref[src]_\ref[maraud]_[maraud.occupant ? 1 : 0]"

			if(!(holomap_marker in map_image_cache))
				var/pref = "mar"
				if (istype(maraud,/obj/mecha/combat/marauder/seraph))
					pref = "ser"
				map_image_cache[holomap_marker] = image('icons/holomap_markers.dmi',"[pref][maraud.occupant ? 1 : 0]")

			var/image/I = map_image_cache[holomap_marker]
			I.plane = HUD_PLANE
			I.loc = activator.hud_used.holomap_obj

			if(maraud.occupant)
				I.layer = HUD_ABOVE_ITEM_LAYER
			else
				I.layer = HUD_ITEM_LAYER

			handle_marker(I,T,get_turf(maraud))

			holomap_images += I

/obj/item/device/mapping_unit/elite/extra_update()
	var/turf/T = get_turf(src)
	for(var/obj/mecha/combat/marauder/mauler/maul in mechas_list)
		if(T.z == maul.z)
			var/holomap_marker = "marker_\ref[src]_\ref[maul]_[maul.occupant ? 1 : 0]"

			if(!(holomap_marker in map_image_cache))
				map_image_cache[holomap_marker] = image('icons/holomap_markers.dmi',"mau[maul.occupant ? 1 : 0]")

			var/image/I = map_image_cache[holomap_marker]
			I.plane = HUD_PLANE
			I.loc = activator.hud_used.holomap_obj

			if(maul.occupant)
				I.layer = HUD_ABOVE_ITEM_LAYER
			else
				I.layer = HUD_ITEM_LAYER

			handle_marker(I,T,get_turf(maul))

			holomap_images += I

/obj/item/device/mapping_unit/ert/extra_update()
	var/turf/T = get_turf(src)
	if(T.z == map.zMainStation)
		var/image/bgmap
		var/holomap_bgmap = "background_\ref[src]_[T.z]_areas"
		if(!(holomap_bgmap in map_image_cache))
			map_image_cache[holomap_bgmap] = image(extraMiniMaps[HOLOMAP_EXTRA_STATIONMAPAREAS+"_[map.zMainStation]"])

		bgmap = map_image_cache[holomap_bgmap]
		bgmap.plane = HUD_PLANE
		bgmap.layer = HUD_BASE_LAYER
		bgmap.alpha = 127
		bgmap.loc = activator.hud_used.holomap_obj
		bgmap.overlays.len = 0

		if(!bgmap.pixel_x)
			bgmap.pixel_x = -1*T.x
		if(!bgmap.pixel_y)
			bgmap.pixel_y = -1*T.y

		for(var/marker in holomap_markers)
			var/datum/holomap_marker/holomarker = holomap_markers[marker]
			if(holomarker.z == T.z && holomarker.filter & holomap_filter)
				var/image/markerImage = image(holomarker.icon,holomarker.id)
				markerImage.plane = FLOAT_PLANE
				markerImage.layer = FLOAT_LAYER
				if(map.holomap_offset_x.len >= T.z)
					markerImage.pixel_x = holomarker.x+holomarker.offset_x+map.holomap_offset_x[T.z]
					markerImage.pixel_y = holomarker.y+holomarker.offset_y+map.holomap_offset_y[T.z]
				else
					markerImage.pixel_x = holomarker.x+holomarker.offset_x
					markerImage.pixel_y = holomarker.y+holomarker.offset_y
				markerImage.appearance_flags = RESET_COLOR
				bgmap.overlays += markerImage

		if(map.holomap_offset_x.len >= T.z)
			animate(bgmap,pixel_x = -1*T.x - map.holomap_offset_x[T.z], pixel_y = -1*T.y - map.holomap_offset_y[T.z], time = 5, easing = LINEAR_EASING)
		else
			animate(bgmap,pixel_x = -1*T.x, pixel_y = -1*T.y, time = 5, easing = LINEAR_EASING)

		holomap_images += bgmap
*/

/obj/item/device/mapping_unit/proc/update_marker()
	marker_prefix = base_prefix
	if (prefix_update_head)
		if(ishuman(loc))
			var/mob/living/carbon/human/H = loc
			var/obj/item/helmet = H.get_equipped_item(slot_head)
			if(helmet && ("[helmet.type]" in prefix_update_head))
				marker_prefix = prefix_update_head["[helmet.type]"]
	else if (prefix_update_rig)
		if(ishuman(loc))
			var/mob/living/carbon/human/H = loc
			var/obj/item/weapon/rig = H.get_rig()
			if(rig && ("[rig.type]" in prefix_update_rig))
				marker_prefix = prefix_update_rig["[rig.type]"]

/obj/item/device/mapping_unit/proc/handle_marker(var/obj/screen/holomap/marker/I,var/TU_x,var/TU_y)
	//animate(I,alpha = 255, pixel_x = (TU.x-1) + I.offset_x, pixel_y = (TU.y-1) + I.offset_y, time = 5, loop = -1, easing = LINEAR_EASING)
	I.pixel_x = (TU_x-1) + I.offset_x
	I.pixel_y = (TU_y-1) + I.offset_y
	//animate(alpha = 255, time = 8, loop = -1, easing = SINE_EASING)
	animate(I, alpha = 0, time = 5, easing = SINE_EASING)
	animate(alpha = 255, time = 2, easing = SINE_EASING)

#undef HOLOMAP_ERROR
#undef HOLOMAP_YOU
#undef HOLOMAP_OTHER
#undef HOLOMAP_DEAD
