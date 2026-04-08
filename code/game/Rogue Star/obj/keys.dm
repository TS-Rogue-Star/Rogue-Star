//RS FILE
/obj/item/key
	name = "key"
	desc = "A small key made out of some kind of metal."
	icon = 'icons/rogue-star/keys.dmi'
	icon_state = "key"
	persist_storable = FALSE
	w_class = ITEMSIZE_TINY
	var/lock_id = "key"
	var/one_time = FALSE	//If true the key will delete itself after use
	var/master_key = FALSE	//If true then this key can open anything with a configured lock!

/obj/item/key/Initialize()
	. = ..()
	pixel_x = rand(-8,8)
	pixel_y = rand(-8,8)
	if(icon_state == "key")
		icon_state  = "[icon_state]-[rand(1,6)]"
		color = "#b4cacc"

/obj/item/key/resolve_attackby(atom/A, mob/user, attack_modifier, click_parameters)
	if(!unlock(A,user))
		return ..()

/obj/item/key/proc/unlock(var/atom/A,var/mob/user)
	if(!A || !user)
		return FALSE

	if(!isobj(A))
		return FALSE

	var/obj/O = A
	if(!O.unlock_with_key(lock_id,src))
		to_chat(user,SPAN_DANGER("\The [src] doesn't fit into \the [A]..."))
		return FALSE

	to_chat(user,SPAN_NOTICE("\The [src] fits cleanly into \the [A]. You give it a firm turn."))

	if(one_time)
		to_chat(user,SPAN_DANGER("\The [src] crumbles away to dust after being used."))
		user.drop_from_inventory(src,get_turf(user))
		qdel(src)
	return TRUE

/obj/item/key/big
	name = "big key"
	desc = "It looks quite menacing! Upon very close inspection, there are some impossibly complicated and detailed engravings on this key."
	icon_state = "big-key"
	color = "#bb883b"
	lock_id = "boss"

/obj/item/key/onetime
	one_time = TRUE

/obj/proc/unlock_with_key(key_id,var/obj/item/key/K)
	if(K)
		if(K.master_key)
			. = TRUE
	if(!key_id)
		return FALSE

/obj/machinery/door/airlock/unlock_with_key(key_id,var/obj/item/key/K)
	. = ..()

	if(key_id == id_tag || (. && id_tag))
		if(K && !locked)
			if(K.one_time)	//Don't destroy keys for doors that are already unlocked.
				return FALSE
		if(locked)
			unlock()
			open()
		else
			lock()
		return TRUE

/obj/structure/simple_door/unlock_with_key(key_id,var/obj/item/key/K)
	. = ..()

	if(key_id == lock_id || (. && lock_id))
		if(K && !locked)
			if(K.one_time)	//Don't destroy keys for doors that are already unlocked.
				return FALSE
		locked = !locked
		return TRUE

/obj/event_obstical/unlock_with_key(key_id,var/obj/item/key/K)
	. = ..()

	if(key_id == id || (. && id))
		if(K && !density)
			if(K.one_time)	//Don't destroy keys for doors that are already unlocked.
				return FALSE
		post_trigger()
		return TRUE
