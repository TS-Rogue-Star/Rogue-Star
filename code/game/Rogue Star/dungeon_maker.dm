//RS FILE
/client
	var/list/utility
	var/dungeon_maker = null

/client/proc/toggle_dungeon_maker()
	set name = "Toggle Dungeon Maker"
	set category = "Special Verbs"

	if(!holder)
		clear_utility()
		return

	if(utility)
		clear_utility()
		return
	utility = list()
	show_popup_menus = FALSE
	log_admin("[key_name(usr)] has entered dungeon maker.")
	var/obj/effect/dungeon_maker/holder/H = new()
	utility |= H
	screen += H

/client/proc/clear_utility()
	for(var/thing in utility)
		utility -= thing
		screen -= thing
		qdel(thing)
	show_popup_menus = TRUE
	QDEL_LIST_NULL(utility)
	log_admin("[key_name(usr)] has left dungeon maker.")

/obj/effect/dungeon_maker
	density = TRUE
	anchored = TRUE
	layer = LAYER_HUD_BASE
	plane = PLANE_PLAYER_HUD
	dir = NORTH
	icon = 'icons/rogue-star/dungeon_maker.dmi'
	icon_state = "base"
	color = "#ff9100"

//	screen_loc = "CENTER,WEST"

/obj/effect/dungeon_maker/holder
	var/lock_id = null
	var/trigger_id = null
	screen_loc = "WEST,CENTER"
	icon = null
	icon_state = null

/obj/effect/dungeon_maker/holder/Initialize()
	. = ..()
	add_button(/obj/effect/dungeon_maker/button/link)
	add_button(/obj/effect/dungeon_maker/button/lock)
	add_button(/obj/effect/dungeon_maker/button/mechanic)

/obj/effect/dungeon_maker/holder/Destroy()
	for(var/thing in contents)
		qdel(thing)
	return ..()

/obj/effect/dungeon_maker/holder/proc/add_button(var/button_type)
	if(!ispath(button_type))
		log_and_message_admins("An dungeon_maker/holder was given [button_type], but that is not a type so it didn't make it.")
		return
	var/obj/effect/dungeon_maker/ourbutton = new button_type(src)
	vis_contents += ourbutton

/obj/effect/dungeon_maker/holder/Click(location, control, params)
	var/list/pa = params2list(params)
	if(pa.Find("middle"))
		//???
		return
	else if(pa.Find("left"))
		//Close
		return
	else if(pa.Find("right"))
		//???
		return

/obj/effect/dungeon_maker/button
	var/obj/effect/dungeon_maker/holder/master = null

/obj/effect/dungeon_maker/button/link
	name = "Link"
	icon_state = "link"
//	screen_loc = "CENTER,WEST"

/obj/effect/dungeon_maker/button/link/Click(location, control, params)
	to_world("link")
	var/list/pa = params2list(params)
	if(pa.Find("middle"))
		//Pick up clicked trigger_id
		return
	else if(pa.Find("left"))
		//Apply clicked trigger_id
		return
	else if(pa.Find("right"))
		//Open context menu for given object
		return

/obj/effect/dungeon_maker/button/lock
	name = "Lock"
	icon_state = "lock"
//	screen_loc = "CENTER-1,WEST"
	pixel_y = -34

/obj/effect/dungeon_maker/button/lock/Click(location, control, params)
	to_world("lock")
	var/list/pa = params2list(params)
	if(pa.Find("middle"))
		//Pick up clicked lock_id
		return
	else if(pa.Find("left"))
		//Add or update lock on clicked
		return
	else if(pa.Find("right"))
		//Open context menu for given object
		return

/obj/effect/dungeon_maker/button/mechanic
	name = "Mechanic"
	icon_state = "mechanic"
//	screen_loc = "CENTER-2,WEST"
	pixel_y = -68

/obj/effect/dungeon_maker/button/mechanic/Click(location, control, params)
	to_world("mechanic")
	var/list/pa = params2list(params)
	if(pa.Find("middle"))
		//Pick up clicked object if it is a valid type
		return
	else if(pa.Find("left"))
		//Place selected object if one exists
		return
	else if(pa.Find("right"))
		//Open context menu for given object
		return

/proc/dungeon_maker_click(var/mob/user, buildmode, params, var/obj/object)
