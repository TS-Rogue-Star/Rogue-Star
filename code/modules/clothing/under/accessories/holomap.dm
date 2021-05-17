/obj/item/clothing/accessory/holomap_chip
	name = "holomap chip"
	desc = "A device meant to be attached on a jumpsuit, granting a certain degree of situational awareness."
	icon_state = "holochip"
	item_icons = list(
		slot_l_hand_str = 'icons/mob/items/lefthand.dmi',
		slot_r_hand_str = 'icons/mob/items/righthand.dmi',
		)
	item_state = null
	slot = ACCESSORY_SLOT_UTILITY
	var/destroyed = 0

	//Holomap stuff
	var/mob/living/carbon/human/activator = null
	var/list/holomap_images = list()
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

	action_button_name = "Toggle Holomap"

/obj/item/clothing/accessory/holomap_chip/deathsquad
	name = "deathsquad holomap chip"
	icon_state = "holochip_ds"
	marker_prefix = "ds"
	holomap_filter = HOLOMAP_FILTER_DEATHSQUAD
	holomap_color = "#0B74B4"

/obj/item/clothing/accessory/holomap_chip/operative
	name = "nuclear operative holomap chip"
	icon_state = "holochip_op"
	marker_prefix = "op"
	holomap_filter = HOLOMAP_FILTER_NUKEOPS
	holomap_color = "#13B40B"

/obj/item/clothing/accessory/holomap_chip/ert
	name = "emergency response team holomap chip"
	icon_state = "holochip_ert"
	marker_prefix = "ert"
	holomap_filter = HOLOMAP_FILTER_ERT
	holomap_color = "#5FFF28"

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

/obj/item/clothing/accessory/holomap_chip/Initialize()
	. = ..()
	holomap_chips += src
	base_prefix = marker_prefix

	var/image/ping = image('icons/effects/effects.dmi',icon_state = "holomap_ping")
	ping.plane = PLANE_HOLOMAP
	ping.blend_mode = BLEND_ADD
	icon_image_cache["p"] = ping

	// This would be done automatically on pickup, however
	// we might start attached to a suit and never get picked up
	action = new /datum/action/item_action/accessory(src)
	action.name = action_button_name

/obj/item/clothing/accessory/holomap_chip/Destroy()
	holomap_chips -= src

	deactivate_holomap()
	STOP_PROCESSING(SSobj, src)

	map_image_cache.Cut()
	icon_image_cache.Cut()

	return ..()

/obj/item/clothing/accessory/holomap_chip/ui_action_click()
	togglemap()

/obj/item/clothing/accessory/holomap_chip/on_attached(obj/item/clothing/C, mob/user)
	if(!istype(C) || C.action)
		if(user)
			to_chat(user, SPAN_WARNING("You can't attach [src] to that."))
		return
	return ..()

/obj/item/clothing/accessory/holomap_chip/on_removed(mob/user as mob)
	deactivate_holomap()
	return ..()

/obj/item/clothing/accessory/holomap_chip/proc/togglemap()
	if(usr.stat != CONSCIOUS)
		return

	if(!has_suit)
		return

	if(!ishuman(usr))
		to_chat(usr, "<span class='warning'>Only humanoids can use this device.</span>")
		return

	var/mob/living/carbon/human/H = usr

	if(!istype(loc))
		to_chat(H, "<span class='warning'>This device needs to be set on a uniform first.</span>")

	if(H.get_equipped_item(slot_w_uniform) != has_suit)
		to_chat(H, "<span class='warning'>You need to wear the suit first.</span>")
		return

	if(activator)
		deactivate_holomap()
		to_chat(H, "<span class='notice'>You disable the holomap.</span>")
	else
		activator = H
		START_PROCESSING(SSobj, src)
		process()
		to_chat(H, "<span class='notice'>You enable the holomap.</span>")



#define HOLOMAP_ERROR	0
#define HOLOMAP_YOU		1
#define HOLOMAP_OTHER	2
#define HOLOMAP_DEAD	3

/obj/item/clothing/accessory/holomap_chip/proc/handle_sanity(var/turf/T)
	if((!has_suit) || (!activator) || (activator.get_equipped_item(slot_w_uniform) != has_suit) || (!activator.client) || isnull(SSholomaps.holoMiniMaps[T.z]))
		return FALSE
	return TRUE

/obj/item/clothing/accessory/holomap_chip/proc/update_holomap()
	var/turf/T = get_turf(src)
	if(!T)//nullspace begone!
		return

	if(!handle_sanity(T))
		deactivate_holomap()
		return

	activator.client.images -= holomap_images

	holomap_images.len = 0

	var/image/bgmap
	var/holomap_bgmap = "[T.z]"

	// The main map part is cached here, with the markers (which are static, so won't be changing)
	if(!(holomap_bgmap in map_image_cache))
		var/image/tmp = image(SSholomaps.holoMiniMaps[T.z])
		tmp.appearance_flags = PIXEL_SCALE
		tmp.plane = PLANE_HOLOMAP
		tmp.layer = HUD_LAYER
		tmp.color = holomap_color
		tmp.loc = activator.hud_used.holomap_obj // Attaches to the user's hud element, but not presented until this is in client.images

		for(var/marker in holomap_markers)
			var/datum/holomap_marker/holomarker = holomap_markers[marker]
			if(holomarker.z == T.z && holomarker.filter & holomap_filter)
				var/image/markerImage = image(holomarker.icon,holomarker.id)
				markerImage.plane = FLOAT_PLANE
				markerImage.layer = FLOAT_LAYER
				markerImage.appearance_flags = RESET_COLOR|PIXEL_SCALE
				if(using_map.holomap_offset_x.len >= T.z)
					markerImage.pixel_x = holomarker.x+holomarker.offset_x+using_map.holomap_offset_x[T.z]
					markerImage.pixel_y = holomarker.y+holomarker.offset_y+using_map.holomap_offset_y[T.z]
				else
					markerImage.pixel_x = holomarker.x+holomarker.offset_x
					markerImage.pixel_y = holomarker.y+holomarker.offset_y
				tmp.overlays += markerImage
		
		map_image_cache[holomap_bgmap] = tmp

	bgmap = map_image_cache[holomap_bgmap]
	

	// Prevents the map background from sliding across the screen when the map is enabled for the first time.
	if(!bgmap.pixel_x)
		bgmap.pixel_x = -1*T.x + activator.client.view*WORLD_ICON_SIZE + 16*(WORLD_ICON_SIZE/32)
	if(!bgmap.pixel_y)
		bgmap.pixel_y = -1*T.y + activator.client.view*WORLD_ICON_SIZE + 17*(WORLD_ICON_SIZE/32)


	// The holomap moves around, the user is always in the center. This slides the holomap.
	if(using_map.holomap_offset_x.len >= T.z)
		animate(bgmap,pixel_x = -1*T.x - using_map.holomap_offset_x[T.z] + activator.client.view*WORLD_ICON_SIZE + 16*(WORLD_ICON_SIZE/32), pixel_y = -1*T.y - using_map.holomap_offset_y[T.z] + activator.client.view*WORLD_ICON_SIZE + 17*(WORLD_ICON_SIZE/32), time = 5, easing = LINEAR_EASING)
	else
		animate(bgmap,pixel_x = -1*T.x + activator.client.view*WORLD_ICON_SIZE + 16*(WORLD_ICON_SIZE/32), pixel_y = -1*T.y + activator.client.view*WORLD_ICON_SIZE + 17*(WORLD_ICON_SIZE/32), time = 5, easing = LINEAR_EASING)
	holomap_images += bgmap

	// Populate holomap chip icons
	for(var/obj/item/clothing/accessory/holomap_chip/HC in holomap_chips)
		if(HC.holomap_filter != holomap_filter)
			continue
		var/obj/item/clothing/under/U = HC.has_suit
		var/mob_indicator = HOLOMAP_ERROR
		var/turf/TU = get_turf(HC)
		
		// Marker not on a turf
		if(!TU)
			continue
		
		// We're the marker
		if(HC == src)
			mob_indicator = HOLOMAP_YOU
		
		// The marker is held by a borg
		else if(isrobot(HC.loc) && (TU.z == T.z))
			var/mob/living/silicon/robot/R = HC.loc
			if(R.stat == DEAD)
				mob_indicator = HOLOMAP_DEAD
			else
				mob_indicator = HOLOMAP_OTHER
		
		// The marker is worn by a human
		else if(U && (TU.z == T.z) && ishuman(U.loc))
			var/mob/living/carbon/human/H = U.loc
			if(H.get_equipped_item(slot_w_uniform) == U)
				if(H.stat == DEAD)
					mob_indicator = HOLOMAP_DEAD
				else
					mob_indicator = HOLOMAP_OTHER
			// It's on a uniform but not worn
			else
				continue
		
		// It's not attached to anything useful
		else
			continue

		
		// Ask it to update it's icon based on helmet (or whatever)
		HC.update_marker()

		// Generate the icon and apply it to the list of images to show the client
		if(mob_indicator != HOLOMAP_ERROR)

			// This is so specific because the icons are pixel_x and pixel_y only relative to OUR view of where THEY are relative to us
			var/holomap_marker = "\ref[HC]_[HC.marker_prefix]_[mob_indicator]"

			if(!(holomap_marker in icon_image_cache))
				icon_image_cache[holomap_marker] = image('icons/holomap_markers.dmi',"[HC.marker_prefix][mob_indicator]")

			var/image/I = icon_image_cache[holomap_marker]
			I.plane = PLANE_HOLOMAP_ICONS
			
			handle_marker(I,T,TU)
			
			if(mob_indicator == HOLOMAP_YOU)
				I.layer = HUD_LAYER-0.1
				
			else
				I.layer = HUD_LAYER+0.1
			I.loc = activator.hud_used.holomap_obj

			holomap_images += I

	//Additional things we might want to track
	extra_update()

	activator.client.images |= holomap_images

/obj/item/clothing/accessory/holomap_chip/proc/extra_update()
	return

/*
/obj/item/clothing/accessory/holomap_chip/deathsquad/extra_update()
	
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

/obj/item/clothing/accessory/holomap_chip/elite/extra_update()
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

/obj/item/clothing/accessory/holomap_chip/ert/extra_update()
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
			bgmap.pixel_x = -1*T.x + activator.client.view*WORLD_ICON_SIZE + 16*(WORLD_ICON_SIZE/32)
		if(!bgmap.pixel_y)
			bgmap.pixel_y = -1*T.y + activator.client.view*WORLD_ICON_SIZE + 17*(WORLD_ICON_SIZE/32)

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
			animate(bgmap,pixel_x = -1*T.x - map.holomap_offset_x[T.z] + activator.client.view*WORLD_ICON_SIZE + 16*(WORLD_ICON_SIZE/32), pixel_y = -1*T.y - map.holomap_offset_y[T.z] + activator.client.view*WORLD_ICON_SIZE + 17*(WORLD_ICON_SIZE/32), time = 5, easing = LINEAR_EASING)
		else
			animate(bgmap,pixel_x = -1*T.x + activator.client.view*WORLD_ICON_SIZE + 16*(WORLD_ICON_SIZE/32), pixel_y = -1*T.y + activator.client.view*WORLD_ICON_SIZE + 17*(WORLD_ICON_SIZE/32), time = 5, easing = LINEAR_EASING)

		holomap_images += bgmap
*/

/obj/item/clothing/accessory/holomap_chip/proc/update_marker()
	marker_prefix = base_prefix
	if (prefix_update_head)
		var/obj/item/clothing/under/U = has_suit
		if(U && ishuman(U.loc))
			var/mob/living/carbon/human/H = U.loc
			var/obj/item/helmet = H.get_equipped_item(slot_head)
			if(helmet && ("[helmet.type]" in prefix_update_head))
				marker_prefix = prefix_update_head["[helmet.type]"]
	else if (prefix_update_rig)
		var/obj/item/clothing/under/U = has_suit
		if(U && ishuman(U.loc))
			var/mob/living/carbon/human/H = U.loc
			var/obj/item/weapon/rig = H.get_rig()
			if(rig && ("[rig.type]" in prefix_update_rig))
				marker_prefix = prefix_update_rig["[rig.type]"]

/obj/item/clothing/accessory/holomap_chip/proc/handle_marker(var/image/I,var/turf/T,var/turf/TU)
	//if a new marker is created, we immediately set its offset instead of letting animate() take care of it, so it doesn't slide accross the screen.
	if(!I.pixel_x || !I.pixel_y)
		I.pixel_x = TU.x - T.x + activator.client.view*WORLD_ICON_SIZE + 8*(WORLD_ICON_SIZE/32)
		I.pixel_y = TU.y - T.y + activator.client.view*WORLD_ICON_SIZE + 9*(WORLD_ICON_SIZE/32)
	animate(I,alpha = 255, pixel_x = TU.x - T.x + activator.client.view*WORLD_ICON_SIZE + 8*(WORLD_ICON_SIZE/32), pixel_y = TU.y - T.y + activator.client.view*WORLD_ICON_SIZE + 9*(WORLD_ICON_SIZE/32), time = 5, loop = -1, easing = LINEAR_EASING)
	animate(alpha = 255, time = 8, loop = -1, easing = SINE_EASING)
	animate(alpha = 0, time = 5, easing = SINE_EASING)
	animate(alpha = 255, time = 2, easing = SINE_EASING)

#undef HOLOMAP_ERROR
#undef HOLOMAP_YOU
#undef HOLOMAP_OTHER
#undef HOLOMAP_DEAD


/obj/item/clothing/accessory/holomap_chip/proc/deactivate_holomap()
	if(activator && activator.client)
		activator.client.images -= holomap_images
	activator = null

	for(var/image/I in holomap_images)
		animate(I)

	holomap_images.len = 0
	STOP_PROCESSING(SSobj, src)


/obj/item/clothing/accessory/holomap_chip/process()
	update_holomap()
