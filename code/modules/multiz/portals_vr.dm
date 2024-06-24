/obj/structure/portal_event
	name = "portal"
	desc = "It leads to someplace else!"
	icon = 'icons/obj/stationobjs_vr.dmi'
	icon_state = "type-d-portal"
	density = TRUE
	unacidable = TRUE//Can't destroy energy portals.
	var/failchance = 0
	anchored = TRUE
	var/obj/structure/portal_event/target
	var/portal_id		//RS ADD START
	var/portal_enabled = FALSE
	var/static/list/event_portal_list = list()

/obj/structure/portal_event/Initialize()
	. = ..()
	event_portal_list += src

	if(portal_id && !target)
		for(var/obj/structure/portal_event/P in event_portal_list)
			if(P == src)
				continue
			if(!P.target && P.portal_id == portal_id)
				target = P
				target.target = src
				toggle_portal()			//RS ADD END

/obj/structure/portal_event/Destroy()
	event_portal_list -= src			//RS EDIT

	if(target)
		target.target = null
		target = null

	for(var/obj/structure/portal_event/P in event_portal_list)	//RS EDIT
		if(P.target == src)		//RS EDIT
			P.target = null		//RS EDIT

	return ..()

/obj/structure/portal_event/Bumped(mob/M as mob|obj)
	if(istype(M,/mob) && !(istype(M,/mob/living)))
		return	//do not send ghosts, zshadows, ai eyes, etc
	spawn(0)
		src.teleport(M)
		return
	return

/obj/structure/portal_event/Crossed(AM as mob|obj)
	if(istype(AM,/mob) && !(istype(AM,/mob/living)))
		return	//do not send ghosts, zshadows, ai eyes, etc
	spawn(0)
		src.teleport(AM)
		return
	return

/obj/structure/portal_event/attack_hand(mob/user as mob)
	if(!istype(user))
		return
	if(!target)
		if(isliving(user))
			to_chat(user, "<span class='notice'>Your hand scatters \the [src]...</span>")
			qdel(src)	//Delete portals which aren't set that people mess with.
		else return		//do not send ghosts, zshadows, ai eyes, etc
	else if(isliving(user) || istype(user, /mob/observer/dead) && user?.client?.holder)	//unless they're staff
		spawn(0)
		src.teleport(user)

/obj/structure/portal_event/attack_ghost(var/mob/observer/dead/user)
	if(!target && user?.client?.holder)
		to_chat(user, "<span class='notice'>Selecting 'Portal Here' will create and link a portal at your location, while 'Target Here' will create an object that is only visible to ghosts which will act as the target, again at your location. Each option will give you the ability to change portal types, but for all options except 'Select Type' you only get one shot at it, so be sure to experiment with 'Select Type' first if you're not familiar with them.</span>")
		var/response = tgui_alert(user, "You appear to be staff. This portal has no exit point. If you want to make one, move to where you want it to go, and click the appropriate option, see chat for more info, otherwise click 'Cancel'", "Unbound Portal", list("Cancel","Portal Here","Target Here", "Select Type"))
		if(response == "Portal Here")
			create_paired_portal(user)		//RS EDIT
		if(response == "Target Here")
			create_paired_portal(user, FALSE)		//RS EDIT
		if(response == "Select Type")
			select_portal_subtype(user)		//RS EDIT
			return

	else if(user?.client?.holder)
		src.teleport(user)
	else return

/obj/structure/portal_event/proc/create_paired_portal(user, make_portal = TRUE)	//RS EDIT START
	if(make_portal)
		target = new type(get_turf(user), src)
		target.toggle_portal()
	else
		target = new /obj/structure/portal_target(get_turf(user), src)
	target.target = src
	target.icon_state = icon_state
	toggle_portal()
	message_admins("The [src]([x],[y],[z]) was given [target]([target.x],[target.y],[target.z]) as a target, and should be ready to use.")

	if(tgui_alert(user, "Would you like to select a different portal type for the portal?", "Change portal", list("No","Yes")) == "Yes")
		select_portal_subtype(user)		//RS EDIT END

/obj/structure/portal_event/proc/select_portal_subtype(user)
	var/portal_type = tgui_alert(user, "What kind of portal would you like it to be?", "Type Selection", list("Tech (Default)","Star","Weird Green","Pulsing"))
	var/portal_icon_selection = "type-d-portal"
	if(portal_type == "Tech (Default)")
		portal_icon_selection = "type-d-portal"
	if(portal_type == "Star")
		var/portal_subtype = tgui_alert(user, "Which subtype would you prefer?", "Subtype Selection", list("Blue","Blue Pulse","Blue Unstable","Red","Red Unstable"))
		if(portal_subtype == "Blue")
			portal_icon_selection = "type-a-blue-portal"
		if(portal_subtype == "Blue Pulse")
			portal_icon_selection = "type-a-blue-portal-b"
		if(portal_subtype == "Blue Unstable")
			portal_icon_selection = "type-a-blue-portal-c"
		if(portal_subtype == "Red")
			portal_icon_selection = "type-a-red-portal"
		if(portal_subtype == "Red Unstable")
			portal_icon_selection = "type-a-red-portal-b"
	if(portal_type == "Weird Green")
		portal_icon_selection = "type-b-portal"
	if(portal_type == "Pulsing")
		var/portal_subtype = tgui_alert(user, "Which subtype would you prefer?", "Subtype Selection", list("Blue","Red","Blue/Red Mix", "Yellow"))
		if(portal_subtype == "Blue")
			portal_icon_selection = "type-c-blue-portal"
		if(portal_subtype == "Red")
			portal_icon_selection = "type-c-red-portal"
		if(portal_subtype == "Blue/Red Mix")
			portal_icon_selection = "type-c-mix-portal"
		if(portal_subtype == "Yellow")
			portal_icon_selection = "type-c-yellow-portal"

	icon_state = portal_icon_selection	//RS EDIT
	if(target && istype(target, /obj/structure/portal_event) && tgui_alert(user, "Would you like portal's target portal to match this style?", "Both?", list("Yes", "No")) == "Yes")	//RS EDIT
		target.icon_state = portal_icon_selection	//RS EDIT

/obj/structure/portal_event/proc/teleport(atom/movable/M as mob|obj)
	if(!portal_enabled && isliving(M))	//RS EDIT
		to_chat(M, "<span class='notice'>\The [src] wavers as you pass through it... it seems to not accept you through... for now...</span>")	//RS EDIT
		return	//RS EDIT
	if(istype(M, /obj/effect)) //sparks don't teleport
		return
	if (M.anchored&&istype(M, /obj/mecha))
		return
	if (!target)
		to_chat(M, "<span class='notice'>\The [src] scatters as you pass through it...</span>")
		qdel(src)
		return
	if (!istype(M, /atom/movable))
		return
	var/turf/ourturf = find_our_turf(M)	//RS EDIT START
	if(!ourturf.check_density(TRUE,TRUE))	//Make sure there isn't a wall there
		M.unbuckle_all_mobs(TRUE)
		if(isliving(M))
			var/mob/living/ourmob = M
			ourmob.stop_pulling()
		do_safe_teleport(M, ourturf, 0)

/obj/structure/portal_event/proc/find_our_turf(var/atom/movable/AM)
	var/offset_x = x - AM.x
	var/offset_y = y - AM.y

	var/turf/temptarg = locate((target.x + offset_x),(target.y + offset_y),target.z)

	return temptarg		//RS EDIT END

/obj/structure/portal_event/Destroy()
	if(target)
		if(istype(target, /obj/structure/portal_event))
			var/obj/structure/portal_event/P = target
			P.target = null
		if(istype(target, /obj/structure/portal_target))
			var/obj/structure/portal_target/P = target
			P.target = null
		qdel_null(target)
	. = ..()

/obj/structure/portal_target
	name = "portal destination"
	desc = "you shouldn't see this unless you're a ghost"
	icon = 'icons/obj/stationobjs_vr.dmi'
	icon_state = "type-b-portal"
	density = 0
	alpha = 100
	invisibility = INVISIBILITY_OBSERVER
	var/target

/obj/structure/portal_target/Destroy()
	if(target)
		var/obj/structure/portal_event/T = target
		T.target = null
		target = null
	. = ..()

/obj/structure/portal_gateway
	name = "portal"
	desc = "It leads to someplace else!"
	icon = 'icons/obj/stationobjs_vr.dmi'
	icon_state = "portalgateway"
	density = TRUE
	unacidable = TRUE//Can't destroy energy portals.
	anchored = TRUE

/obj/structure/portal_gateway/Bumped(mob/M as mob|obj)
	if(istype(M,/mob) && !(istype(M,/mob/living)))
		return	//do not send ghosts, zshadows, ai eyes, etc
	var/obj/effect/landmark/dest = pick(eventdestinations)
	if(dest)
		M << 'sound/effects/phasein.ogg'
		playsound(src, 'sound/effects/phasein.ogg', 100, 1)
		M.forceMove(dest.loc)
		if(istype(M, /mob/living) && dest.abductor)
			var/mob/living/L = M
			//Situations to get the mob out of
			if(L.buckled)
				L.buckled.unbuckle_mob()
			if(istype(L.loc,/obj/mecha))
				var/obj/mecha/ME = L.loc
				ME.go_out()
			else if(istype(L.loc,/obj/machinery/sleeper))
				var/obj/machinery/sleeper/SL = L.loc
				SL.go_out()
			else if(istype(L.loc,/obj/machinery/recharge_station))
				var/obj/machinery/recharge_station/RS = L.loc
				RS.go_out()
			if(!issilicon(L)) //Don't drop borg modules...
				var/list/mob_contents = list() //Things which are actually drained as a result of the above not being null.
				mob_contents |= L // The recursive check below does not add the object being checked to its list.
				mob_contents |= recursive_content_check(L, mob_contents, recursion_limit = 3, client_check = 0, sight_check = 0, include_mobs = 1, include_objects = 1, ignore_show_messages = 1)
				for(var/obj/item/weapon/holder/I in mob_contents)
					var/obj/item/weapon/holder/H = I
					var/mob/living/MI = H.held_mob
					MI.forceMove(get_turf(H))
					if(!issilicon(MI)) //Don't drop borg modules...
						for(var/obj/item/II in MI)
							if(istype(II,/obj/item/weapon/implant) || istype(II,/obj/item/device/nif))
								continue
							MI.drop_from_inventory(II, dest.loc)
					var/obj/effect/landmark/finaldest = pick(awayabductors)
					MI.forceMove(finaldest.loc)
					sleep(1)
					MI.Paralyse(10)
					MI << 'sound/effects/bamf.ogg'
					to_chat(MI,"<span class='warning'>You're starting to come to. You feel like you've been out for a few minutes, at least...</span>")
				for(var/obj/item/I in L)
					if(istype(I,/obj/item/weapon/implant) || istype(I,/obj/item/device/nif))
						continue
					L.drop_from_inventory(I, dest.loc)
			var/obj/effect/landmark/finaldest = pick(awayabductors)
			L.forceMove(finaldest.loc)
			sleep(1)
			L.Paralyse(10)
			L << 'sound/effects/bamf.ogg'
			to_chat(L,"<span class='warning'>You're starting to come to. You feel like you've been out for a few minutes, at least...</span>")
	return

/obj/structure/portal_event/autolink	//RS ADD START
	portal_id = "autolink"

/obj/structure/portal_event/proc/toggle_portal()
	portal_enabled = !portal_enabled
	if(portal_enabled)
		density = TRUE
		set_light(3, 0.75, "#ffffff")
	else
		density = FALSE
		set_light(0)

/obj/structure/portal_event/proc/configure_portal()
	set category = "Object"
	set name = "Configure Portal"

	if(!usr.client.holder)
		return

	var/list/ourlist = list("Cancel")

	if(!target)
		ourlist += "Portal Here"
		ourlist += "Target Here"

	ourlist += "Select Type"
	ourlist += "Enable/Disable"

	var/response = tgui_alert(usr, "Configure the portal's settings!", "Configure Portal", ourlist)

	switch(response)
		if("Portal Here")
			create_paired_portal(usr)
		if("Target Here")
			create_paired_portal(usr, FALSE)
		if("Select Type")
			select_portal_subtype(usr)
		if("Enable/Disable")
			toggle_portal()
		else
			return

//RS ADD END
