/obj/structure/closet/secure_closet
	name = "secure locker"
	desc = "It's an immobile card-locked storage unit."
	icon = 'icons/obj/closet.dmi'
	icon_state = "secure1"
	density = TRUE
	opened = 0
	var/locked = 1
	var/broken = 0
	var/large = 1
	wall_mounted = 0 //never solid (You can always pass over it)
	health = 200

	closet_appearance = /decl/closet_appearance/secure_closet

/obj/structure/closet/secure_closet/can_open()
	if(locked)
		return 0
	return ..()

/obj/structure/closet/secure_closet/emp_act(severity)
	if(islocked())	//RS ADD
		return		//RS ADD

	for(var/obj/O in src)
		O.emp_act(severity)
	if(!broken)
		if(prob(50/severity))
			locked = !locked
			update_icon()
		if(prob(20/severity) && !opened)
			if(!locked)
				open()
			else
				req_access = list()
				req_access += pick(get_all_station_access())
	..()

/obj/structure/closet/secure_closet/proc/togglelock(mob/user as mob)
	if(opened)
		to_chat(user, "<span class='notice'>Close the locker first.</span>")
		return
	if(broken)
		to_chat(user, "<span class='warning'>The locker appears to be broken.</span>")
		return
	if(user.loc == src)
		to_chat(user, "<span class='notice'>You can't reach the lock from inside.</span>")
		return
	if(islocked())	//RS ADD START
		to_chat(user,SPAN_WARNING("It appears to have a lock on it, which is of course, locked. It can't be opened without using whatever opens it first."))
		return	//RS ADD END
	if(allowed(user))
		locked = !locked
		playsound(src, 'sound/machines/click.ogg', 15, 1, -3)
		for(var/mob/O in viewers(user, 3))
			if((O.client && !( O.blinded )))
				to_chat(O, "<span class='notice'>The locker has been [locked ? null : "un"]locked by [user].</span>")
		update_icon()
	else
		to_chat(user, "<span class='notice'>Access Denied</span>")

/obj/structure/closet/secure_closet/attackby(obj/item/weapon/W as obj, mob/user as mob)
	if(getlock())	//RS ADD START
		if(W.getkey())
			return	//RS ADD END
	if(W.is_wrench())
		if(opened)
			if(anchored)
				user.visible_message("\The [user] begins unsecuring \the [src] from the floor.", "You start unsecuring \the [src] from the floor.")
			else
				user.visible_message("\The [user] begins securing \the [src] to the floor.", "You start securing \the [src] to the floor.")
			if(do_after(user, 20 * W.toolspeed))
				if(!src) return
				to_chat(user, "<span class='notice'>You [anchored? "un" : ""]secured \the [src]!</span>")
				anchored = !anchored
				return
		else
			to_chat(user, "<span class='notice'>You can't reach the anchoring bolts when the door is closed!</span>")
	else if(opened)
		if(istype(W, /obj/item/weapon/storage/laundry_basket))
			return ..(W,user)
		if(istype(W, /obj/item/weapon/grab))
			var/obj/item/weapon/grab/G = W
			if(large)
				MouseDrop_T(G.affecting, user)	//act like they were dragged onto the closet
			else
				to_chat(user, "<span class='notice'>The locker is too small to stuff [G.affecting] into!</span>")
		if(isrobot(user))
			return
		if(W.loc != user) // This should stop mounted modules ending up outside the module.
			return
		user.drop_item()
		if(W)
			W.forceMove(loc)
	else if(istype(W, /obj/item/weapon/melee/energy/blade))
		if(islocked())	//RS ADD
			return		//RS ADD
		if(emag_act(INFINITY, user, "<span class='danger'>The locker has been sliced open by [user] with \an [W]</span>!", "<span class='danger'>You hear metal being sliced and sparks flying.</span>"))
			var/datum/effect/effect/system/spark_spread/spark_system = new /datum/effect/effect/system/spark_spread()
			spark_system.set_up(5, 0, loc)
			spark_system.start()
			playsound(src, 'sound/weapons/blade1.ogg', 50, 1)
			playsound(src, "sparks", 50, 1)
	else if(istype(W,/obj/item/weapon/packageWrap) || istype(W,/obj/item/weapon/weldingtool))
		return ..(W,user)
	else
		togglelock(user)

/obj/structure/closet/secure_closet/emag_act(var/remaining_charges, var/mob/user, var/emag_source, var/visual_feedback = "", var/audible_feedback = "")
	if(islocked())	//RS ADD
		return		//RS ADD
	if(!broken)
		broken = 1
		locked = 0
		desc = "It appears to be broken."

		if(visual_feedback)
			visible_message(visual_feedback, audible_feedback)
		else if(user && emag_source)
			visible_message("<span class='warning'>\The [src] has been broken by \the [user] with \an [emag_source]!</span>", "You hear a faint electrical spark.")
		else
			visible_message("<span class='warning'>\The [src] sparks and breaks open!</span>", "You hear a faint electrical spark.")
		update_icon()
		return 1

/obj/structure/closet/secure_closet/attack_hand(mob/user as mob)
	add_fingerprint(user)
	if(locked)
		togglelock(user)
	else
		toggle(user)

/obj/structure/closet/secure_closet/AltClick()
	..()
	verb_togglelock()

/obj/structure/closet/secure_closet/verb/verb_togglelock()
	set src in oview(1) // One square distance
	set category = "Object"
	set name = "Toggle Lock"

	if(!usr.canmove || usr.stat || usr.restrained() || !Adjacent(usr)) // Don't use it if you're not able to! Checks for stuns, ghost and restrain
		return

	if(ishuman(usr) || isrobot(usr))
		add_fingerprint(usr)
		togglelock(usr)
	else
		to_chat(usr, "<span class='warning'>This mob type can't use this verb.</span>")

/obj/structure/closet/secure_closet/update_icon()
	if(opened)
		icon_state = "open"
	else
		if(broken)
			icon_state = "closed_emagged[sealed ? "_welded" : ""]"
		else
			if(locked)
				icon_state = "closed_locked[sealed ? "_welded" : ""]"
			else
				icon_state = "closed_unlocked[sealed ? "_welded" : ""]"

/obj/structure/closet/secure_closet/req_breakout()
	if(!opened && locked) return 1
	return ..() //It's a secure closet, but isn't locked.

/obj/structure/closet/secure_closet/break_open()
	desc += " It appears to be broken."
	broken = 1
	locked = 0
	..()

//RS ADD START
/obj/structure/closet/secure_closet/dungeon_trigger(mob/user)
	var/datum/component/dungeon_mechanic/lock/ourlock = getlock()
	if(ourlock)
		if(ourlock.locked)
			dungeon_unlock(user)
		else if(!ourlock.onetime)
			dungeon_lock(user)
	else
		if(locked)
			dungeon_unlock(user)
		else
			dungeon_lock(user)

/obj/structure/closet/secure_closet/dungeon_lock(mob/user)
	. = ..()
	locked = TRUE
	update_icon()

/obj/structure/closet/secure_closet/dungeon_unlock(mob/user)
	. = ..()
	locked = FALSE
	update_icon()
