//RS FILE

/obj/deployable_teleporter
	name = "teleporter"
	desc = "A teleport pad that can be deployed! How convenient!"
	icon = 'icons/rogue-star/misc_32x64.dmi'
	icon_state = "teleporter"

	anchored = TRUE
	var/overlay_state = "teleporter_l"
	var/obj/deployable_teleporter/partner
	var/countdown = 5
	var/master = FALSE
	var/master_color = "#ffad4f"
	var/partner_color = "#4fc7ff"
	var/deployable_item = TRUE
	var/teleport_active = TRUE
	var/requires_power = TRUE

/obj/deployable_teleporter/Destroy()
	STOP_PROCESSING(SSobj, src)
	unpair()
	. = ..()

/obj/deployable_teleporter/process()
	if(countdown <= 0)
		countdown = 5
		var/consequences = teleport_active
		if(!check_power())
			return
		if(!consequences)
			return
		do_teleport()
	else
		countdown --
		if(!teleport_active)
			return
		if(countdown < 2)
			playsound(src, 'sound/effects/pop.ogg', 100, 1,-6)
			playsound(partner, 'sound/effects/pop.ogg', 100, 1,-6)

/obj/deployable_teleporter/attack_hand(mob/living/user)
	if(partner)
		return

	if(!deployable_item)
		to_chat(usr,SPAN_DANGER("\The [src] has already dispensed its linked deployable."))
		return

	deployable_item = FALSE
	var/obj/item/teleporter_deployer/dude_wheres_my_teleporter = new(get_turf(src),src)
	visible_message(SPAN_NOTICE("\The [src] clicks as it dispenses \the [dude_wheres_my_teleporter]."), runemessage = "clack")

/obj/deployable_teleporter/Crossed(O)
	. = ..()
	if(isliving(O))
		var/mob/living/L = O
		L.pixel_y = 10

/obj/deployable_teleporter/Uncrossed(O)
	. = ..()
	if(isliving(O))
		var/mob/living/L = O
		L.pixel_y = 0

/obj/deployable_teleporter/proc/pair(var/obj/deployable_teleporter/pair_partner)
	if(partner)
		return

	if(!istype(pair_partner,/obj/deployable_teleporter))
		return

	if(pair_partner.partner)
		return

	STOP_PROCESSING(SSobj, pair_partner)
	STOP_PROCESSING(SSobj, src)

	master = TRUE
	partner = pair_partner
	partner.partner = src
	partner.teleport_active = teleport_active
	update_icon()
	partner.update_icon()
	countdown = 5
	START_PROCESSING(SSobj, src)

/obj/deployable_teleporter/proc/unpair()
	if(!partner)
		return
	STOP_PROCESSING(SSobj, partner)
	STOP_PROCESSING(SSobj, src)
	master = FALSE
	partner.master = FALSE
	partner.partner = null
	partner.update_icon()
	partner = null
	update_icon()

/obj/deployable_teleporter/update_icon()
	. = ..()
	cut_overlays()
	if(!partner || !overlay_state || !teleport_active)
		set_light(0)
		return
	var/starlight_color
	if(master)
		starlight_color = master_color
	else
		starlight_color = partner_color
	var/image/our_overlay = image(icon,null,overlay_state)

	our_overlay.color = starlight_color
	our_overlay.appearance_flags = RESET_COLOR|KEEP_APART|PIXEL_SCALE
	our_overlay.plane = PLANE_LIGHTING_ABOVE
	add_overlay(our_overlay)

	our_overlay = image('icons/rogue-star/misc.dmi',null,"starlight")
	our_overlay.color = starlight_color
	our_overlay.appearance_flags = RESET_COLOR|KEEP_APART|PIXEL_SCALE
	our_overlay.plane = PLANE_LIGHTING_ABOVE
	add_overlay(our_overlay)
	set_light(3, 0.75, starlight_color)

/obj/deployable_teleporter/proc/get_teleport_list()
	var/list/to_teleport = list()
	for(var/atom/movable/thing in get_turf(src))
		if(thing == src)
			continue
		if(thing.anchored)
			continue

		to_teleport |= thing
	return to_teleport

/obj/deployable_teleporter/proc/do_teleport()
	var/list/A = get_teleport_list()
	var/list/B = partner.get_teleport_list()

	if(A.len > 0 || B.len > 0)
		flick("[icon_state]_teleport",src)
		flick("[partner.icon_state]_teleport",partner)
		playsound(src, "sparks", 100, 1)
		playsound(partner, "sparks", 100, 1)
	else
		flick("[icon_state]_dryteleport",src)
		flick("[partner.icon_state]_dryteleport",partner)
		return

	for(var/atom/movable/thing in A)
		thing.forceMove(find_random_adjacent_turf(partner))	//Let's just forcemove so people aren't randomly getting teleported to annoying places.
	for(var/atom/movable/thing in B)
		thing.forceMove(find_random_adjacent_turf(src))

/obj/deployable_teleporter/proc/check_power()
	if(requires_power)
		var/area/A = get_area(src)
		if(A)
			if(!A.powered(EQUIP))
				if(teleport_active)
					teleport_active = FALSE
					partner.teleport_active = FALSE
					update_icon()
					partner.update_icon()
				return FALSE
			A.use_power_oneoff(20 KILOWATTS, EQUIP)
		if(!teleport_active)
			teleport_active = TRUE
			partner.teleport_active = TRUE
			update_icon()
			partner.update_icon()
	return TRUE

/obj/deployable_teleporter/away
	name = "deployed teleporter"
	icon = 'icons/rogue-star/misc_32x64.dmi'
	icon_state = "deployable"
	deployable_item = FALSE
	overlay_state = "deployable_l"

/obj/deployable_teleporter/away/verb/undeploy()
	set category = "Object"
	set name = "Pack Up Teleporter"
	set src in view(1)

	if(!isliving(usr))
		return
	var/mob/living/L = usr
	L.visible_message(SPAN_WARNING("\The [L] begins to pack up \the [src]..."), runemessage = ". . .")
	if(!do_after(L, 10 SECONDS, progress = TRUE, exclusive = TRUE))
		L.visible_message(SPAN_DANGER("\The [L] is interrupted."))
		return

	var/obj/item/teleporter_deployer/dude_wheres_my_teleporter = new(get_turf(src),partner)
	dude_wheres_my_teleporter.visible_message(SPAN_NOTICE("\The [src] beeps and deactivates as it packs away neatly."),runemessage = "beep")
	qdel(src)

/obj/item/teleporter_deployer
	name = "packed teleportation device"
	desc = "A complicated looking device that is all folded up! Press the button to deploy a linked teleporter!"
	icon = 'icons/rogue-star/misc.dmi'
	icon_state = "deployable_teleporter"

	var/obj/deployable_teleporter/parent

/obj/item/teleporter_deployer/New(loc,source)
	. = ..()
	if(istype(source,/obj/deployable_teleporter))
		parent = source

/obj/item/teleporter_deployer/proc/deploy()
	if(!parent)
		to_chat(usr,SPAN_DANGER("\The [src] beeps indignantly, it seems like it's not linked to a teleporter, so it can't be deployed."))
		return
	if(!isliving(usr))
		return
	var/mob/living/L = usr

	L.visible_message(SPAN_NOTICE("\The [L] begins to unpack \the [src]..."), runemessage = ". . .")
	if(!do_after(L, 10 SECONDS, progress = TRUE, exclusive = TRUE))
		L.visible_message(SPAN_DANGER("\The [L] is interrupted."), runemessage = "!")
		return

	var/obj/deployable_teleporter/away/dude_wheres_my_teleporter = new(get_turf(src))

	dude_wheres_my_teleporter.visible_message(SPAN_NOTICE("\The [usr] deploys [dude_wheres_my_teleporter]!"), runemessage = "clank")

	parent.pair(dude_wheres_my_teleporter)
	L.drop_from_inventory(src)
	qdel(src)

/obj/item/teleporter_deployer/attack_self(mob/user)
	. = ..()
	if(!isliving(user))
		return
	var/mob/living/L = user
	if(L.stat || L.stunned || L.weakened)
		return
	deploy()

/obj/deployable_teleporter/away/AltClick(mob/user)
	. = ..()
	if(!isliving(user))
		return
	var/mob/living/L = user
	if(L.stat || L.stunned || L.weakened)
		return
	if(!Adjacent(L))
		return
	undeploy()
