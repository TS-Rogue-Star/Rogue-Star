//RS FILE
SUBSYSTEM_DEF(inventory_return)
	name = "Inventory Return"
	flags = SS_NO_FIRE

	var/list/master_inv = list()		//Master list for checking against
	var/list/sorted_inv = list()		//A list of lists indexed by mobs real_name
	var/list/blacklisted_types = list(	//A list of types we're not allowed to store
		/obj/item/organ,
		/obj/item/weapon/reagent_containers/food,
		/obj/item/device/paicard
	)

/datum/controller/subsystem/inventory_return/proc/catalogue_object(var/obj/item/I)
	if(!I)
		return FALSE
	if(is_type_in_list(I.type in blacklisted_types))
		return FALSE
	if(!isitem(I))
		return FALSE
	if(!isliving(I.loc))	//If it's not on a mob then we don't have a good way of knowing who it belongs to, and so can't really determine who to return it to
		return FALSE
	var/mob/living/L = I.loc
	master_inv |= I
	if(!sorted_inv[L.real_name])
		sorted_inv[L.real_name] = list(I)
	else
		sorted_inv[L.real_name] |= I

	return TRUE

/datum/controller/subsystem/inventory_return/proc/preserve_object(var/obj/item/I)
	if(!(I in master_inv))
		if(!catalogue_object(I))
			return FALSE

	if(isliving(I.loc))
		var/mob/living/L = I.loc
		L.unEquip(I,force = TRUE)	//Unequip it just to be sure

	mob_check(I,I.loc)	//Check to make sure there's no mobs hidden inside of it, we're about to send it to nullspace, so we want to make extra super sure
	I.moveToNullspace()
	I.digest_stage = null	//Reset its digest damage back to normal
	return TRUE

/datum/controller/subsystem/inventory_return/proc/mob_check(var/atom/movable/AM,var/atom/movable/droploc)
	if(!droploc)	//This check is recursive, so we need to make sure we know of a safe place we can put the mobs
		return
	if(!AM)
		return
	for(var/thing in AM.contents)
		if(isliving(thing))
			var/mob/living/L = thing
			L.forceMove(droploc)
			continue
		if(istype(thing,/obj/item/device/paicard))	//PAIs are mobs that are often hidden in an object, we can't store their cards so let's treat them like a mob
			var/obj/item/device/paicard/P = thing
			P.forceMove(droploc)
			continue
		mob_check(thing,droploc)	//We need to recursive check allllll the way down, since you can hide a person in a bottle, in a shirt, in a bag, etc etc etc

/datum/controller/subsystem/inventory_return/proc/dispense(var/to_dispense, var/turf/dispense_loc)
	if(!to_dispense || !dispense_loc)
		return FALSE
	var/list/ourlist = sorted_inv[to_dispense]
	if(ourlist?.len <= 0)
		return FALSE
	if(!isturf(dispense_loc))
		dispense_loc = get_turf(dispense_loc)
	for(var/obj/item/I in ourlist)
		if(I.loc)
			if(!isbelly(I.loc))	//If we're tracking it and it's not in a belly then someone may be using it or looking at it, so if it isn't in nullspace or in a belly we will assume someone wanted to hold on to it.
				continue
		I.forceMove(dispense_loc)
		master_inv -= I
		sorted_inv[to_dispense] -= I
		I.visible_message("\The [I] appears!",runemessage = "clunk")

	return TRUE

/obj/inventory_recovery
	name = "Inventory Recovery"
	desc = "It's a marvel of modern technology!"
	icon = 'icons/rogue-star/misc32x96.dmi'
	icon_state = "item_recovery"

	anchored = TRUE
	density = FALSE

/obj/inventory_recovery/Initialize(mapload)
	. = ..()
	update_icon()

/obj/inventory_recovery/update_icon()
	. = ..()
	cut_overlays()

	var/image/I = image(icon,null,"[icon_state]_g")
	I.plane = PLANE_LIGHTING_ABOVE
	add_overlay(I)

/obj/inventory_recovery/attack_hand(mob/user)
	. = ..()
	if(!SSinventory_return.dispense(user.real_name,get_turf(src)))
		to_chat(user,SPAN_DANGER("\The [src] hasn't got anything for you, sorry!"))
	else
		visible_message(SPAN_NOTICE("Dispensing for [user] complete! Have a secure day!"),runemessage = "ping")
