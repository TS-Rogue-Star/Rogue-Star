//vars
/client
	var/obj/effect/multichar_holder/multichar
	var/list/multichar_list = list()
	var/multichar_active = TRUE
	var/mob/living/multichar_last
	var/multichar_pet_mode = FALSE

/client/Destroy()
	. = ..()
	if(multichar)
		QDEL_NULL(multichar)

//Toggle multichar
/client/proc/toggle_multichar()
	set name = "Multichar"
	set desc = "Toggle multichar buttons!"
	set category = "Fun"

	if(!check_rights(R_ADMIN, R_FUN))
		return
	multichar_pet_mode = FALSE
	if(!multichar)
		multichar = new/obj/effect/multichar_holder(src,TRUE)
	else
		multichar_active = !multichar_active
	multichar.toggle_visible()

/mob/living/proc/toggle_pet_swap()
	set name = "Pet Swap"
	set desc = "Swap between you and your pet!"
	set category = "IC"

	client.multichar_pet_mode = TRUE

	if(!client.multichar)
		client.multichar = new/obj/effect/multichar_holder(client)
	else
		client.multichar_active = !client.multichar_active
	client.multichar.toggle_visible_pet()

//Register char
/client/proc/register_multichar()
	if(!check_rights(R_ADMIN, R_FUN))
		return
	var/list/ourlist = list()
	for(var/mob/living/L in view(view))
		if(L in multichar_list)
			continue
		if(L.client)
			if(L.client != src)
				continue
		if(L.teleop)
			if(L.teleop != src)
				continue
		ourlist += L
	if(ourlist.len <= 0)
		to_chat(usr,SPAN_WARNING("No valid mobs in view range."))
		return
	var/mob/living/choice = tgui_input_list(usr,"Which mob will you add to multichar?","REGISTER",ourlist)

	if(!choice)
		return
	if(choice.client)
		if(choice.client != src)
			to_chat(usr,SPAN_DANGER("[choice] already has a client that isn't yours, so can't be used with multichar: [choice.client]"))
			return
	if(choice.teleop)
		if(choice.teleop != src)
			to_chat(usr,SPAN_DANGER("[choice] already an associated teleop that isn't yours, so can't be used with multichar: [choice.teleop]"))
			return

	RegisterSignal(choice,COMSIG_PARENT_QDELETING,PROC_REF(multichar_deleted),TRUE)
	multichar_list |= choice
	choice.teleop = mob

//Unregister char
/client/proc/unregister_multichar(var/mob/living/L)
	if(L)
		to_chat(mob,SPAN_DANGER("[L] has been UNREGISTERED from multichar."))
		UnregisterSignal(L, COMSIG_PARENT_QDELETING)
		multichar_list -= L
		L.teleop = null
		if(multichar_last == L)
			update_last_multichar(null)
		return
	var/mob/living/choice = tgui_input_list(usr,"Which mob will you remove?","REMOVE",multichar_list)
	if(!choice)
		return
	unregister_multichar(choice)

/client/proc/multichar_deleted()
	for(var/mob/living/L in multichar_list)
		if(!isliving(L))
			unregister_multichar(L)
			continue
		if(L.gc_destroyed)
			unregister_multichar(L)

//Swap char
/client/proc/swap_multichar()
	if(!check_rights(R_ADMIN, R_FUN))
		return
	var/mob/living/choice = tgui_input_list(usr,"Which mob will you swap to?","SWAP",multichar_list)
	if(!choice)
		return
	if(choice == mob)
		to_chat(usr,SPAN_DANGER("You are already controlling [choice]."))
		return
	actual_swap_multichar(choice)

/client/proc/actual_swap_multichar(var/mob/living/ourmob)
	update_last_multichar(mob)
	ourmob.client = src
	for(var/mob/living/L in multichar_list)
		if(!isliving(L))
			unregister_multichar(L)
			continue
		if(L.client == src)
			L.teleop = null
			continue
		L.teleop = mob
	if(holder && !multichar_pet_mode)
		multichar.toggle_visible()
	else
		multichar.toggle_visible_pet()

//Last
/client/proc/swap_last_multichar()
	if(!multichar_last)
		to_chat(usr,SPAN_DANGER("No previous character! Pick something else, and next time it should switch you back to the mob you're in now!"))
		return
	var/mob/living/L = multichar_last
	actual_swap_multichar(L)

/client/proc/update_last_multichar(var/mob/living/L)
	if(!L || isnull(L))
		multichar.l.vis_contents -= multichar_last
		multichar_last = null
		return
	multichar.l.vis_contents -= multichar_last
	multichar_last = L
	multichar.l.vis_contents |= multichar_last

//Interface
/obj/effect/multichar_holder
	name = "Multichar Holder"
	icon = null
	icon_state = null
	var/client/cl
	var/obj/effect/multichar_button/multichar_pick/p
	var/obj/effect/multichar_button/multichar_last/l
	var/obj/effect/multichar_button/multichar_remove/r
	var/obj/effect/multichar_button/multichar_add/a

/obj/effect/multichar_holder/New(var/client/ourclient,var/extras = FALSE)
	if(!ourclient)
		qdel(src)
		return
	cl = ourclient
	Initialize(extras)

/obj/effect/multichar_holder/Initialize(var/extras = FALSE)
	. = ..()
	l = new/obj/effect/multichar_button/multichar_last(src)
	if(cl.multichar_last)
		l.vis_contents |= cl.multichar_last
	if(cl.holder)
		p = new/obj/effect/multichar_button/multichar_pick(src)
		r = new/obj/effect/multichar_button/multichar_remove(src)
		a = new/obj/effect/multichar_button/multichar_add(src)


/obj/effect/multichar_holder/proc/toggle_visible()
	if(!check_rights(R_ADMIN, R_FUN,cl))
		return
	if(cl.multichar_active)
		cl.screen |= l
		cl.screen |= p
		cl.screen |= r
		cl.screen |= a
	else
		cl.screen -= l
		cl.screen -= a
		cl.screen -= r
		cl.screen -= p

/obj/effect/multichar_holder/proc/toggle_visible_pet()
	if(cl.multichar_active)
		cl.screen |= l
	else
		cl.screen -= l
	cl.screen -= a
	cl.screen -= r
	cl.screen -= p

/obj/effect/multichar_button
	icon = 'icons/rogue-star/misc.dmi'
	icon_state = "box"
	plane = PLANE_LIGHTING_ABOVE

/obj/effect/multichar_button/multichar_pick
	name = "Pick Character"
	desc = "Pick the character you will swap to!"
	screen_loc = "NORTH-1,WEST"
	icon_state = "pick"
/obj/effect/multichar_button/multichar_pick/Click()
	if(ismob(usr))
		var/mob/M = usr
		if(M.client)
			M.client.swap_multichar()

/obj/effect/multichar_button/multichar_last
	name = "Last Character"
	desc = "Swap to the character you most recently switched away from."
	screen_loc = "NORTH-2,WEST"
	icon = null
	icon_state = null
	var/static/image/coverup_overlay

/obj/effect/multichar_button/multichar_last/Initialize()
	. = ..()
	if(!coverup_overlay)
		var/image/our_image = image('icons/rogue-star/misc.dmi',null,"last")
		our_image.appearance_flags = RESET_COLOR|KEEP_APART|PIXEL_SCALE
		our_image.layer = layer + 1
		coverup_overlay = our_image
	add_overlay(coverup_overlay)

/obj/effect/multichar_button/multichar_last/Click()
	if(ismob(usr))
		var/mob/M = usr
		if(M.client)
			M.client.swap_last_multichar()

/obj/effect/multichar_button/multichar_remove
	name = "Remove Character"
	desc = "Remove a character from the multichar list."
	screen_loc = "NORTH-3,WEST"
	icon_state = "remove"
/obj/effect/multichar_button/multichar_remove/Click()
	if(ismob(usr))
		var/mob/M = usr
		if(M.client)
			M.client.unregister_multichar()

/obj/effect/multichar_button/multichar_add
	name = "Add Character"
	desc = "Add a character to the multichar list."
	screen_loc = "NORTH-4,WEST"
	icon_state = "add"
/obj/effect/multichar_button/multichar_add/Click()
	if(ismob(usr))
		var/mob/M = usr
		if(M.client)
			M.client.register_multichar()
