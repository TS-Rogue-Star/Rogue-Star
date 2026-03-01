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
	if(!check_viability(I))
		return FALSE
	var/mob/living/L = I.loc
	master_inv |= I
	if(!sorted_inv[L.real_name])
		sorted_inv[L.real_name] = list(I)
	else
		sorted_inv[L.real_name] |= I

	RegisterSignal(I, COMSIG_PARENT_QDELETING, PROC_REF(unregister_item), TRUE)

	return TRUE

/datum/controller/subsystem/inventory_return/proc/preserve_object(var/obj/item/I)
	if(!(I in master_inv))
		if(!catalogue_object(I))
			return FALSE

	if(isliving(I.loc))
		var/mob/living/L = I.loc
		L.unEquip(I,force = TRUE)	//Unequip it just to be sure

	mob_check(I)	//Check to make sure there's no mobs hidden inside of it, we're about to send it to nullspace, so we want to make extra super sure
	I.moveToNullspace()
	I.digest_stage = null	//Reset its digest damage back to normal
	return TRUE

/datum/controller/subsystem/inventory_return/proc/mob_check(var/atom/movable/AM,var/atom/droploc)
	if(!AM)
		return

	if(!droploc)
		droploc = find_belly_or_turf(AM)

	for(var/thing in AM.contents)
		if(isliving(thing))
			var/mob/living/L = thing
			L.forceMove(droploc)
			continue
		if(istype(thing,/obj/item/weapon/holder/micro))	//Micro holders always hold mobs! If we find one we don't even need to think about it
			var/obj/item/weapon/holder/micro/M = thing
			M.forceMove(droploc)
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
		UnregisterSignal(I,COMSIG_PARENT_QDELETING)

	return TRUE

/datum/controller/subsystem/inventory_return/proc/check_viability(var/obj/item/candidate)
	if(!candidate)
		return FALSE
	if(is_type_in_list(candidate.type, blacklisted_types))
		return FALSE
	if(!isitem(candidate))
		return FALSE
	if(!isliving(candidate.loc))	//If it's not on a mob then we don't have a good way of knowing who it belongs to, and so can't really determine who to return it to
		return FALSE
	var/mob/living/L = candidate.loc
	if(!L.player_login_key_log)
		return FALSE
	return TRUE

/datum/controller/subsystem/inventory_return/proc/check_item(var/obj/item/candidate)
	if(!candidate)
		return FALSE
	if(candidate in master_inv)
		return TRUE

	return check_viability(candidate)

/datum/controller/subsystem/inventory_return/proc/unregister_item()
	var/obj/item/I = args[1]	//args got from signal

	if(!I)
		return

	UnregisterSignal(I,COMSIG_PARENT_QDELETING)

	master_inv -= I

	for(var/thing in sorted_inv)
		if(!islist(sorted_inv[thing]))
			continue
		sorted_inv[thing] -= I

/proc/find_belly_or_turf(var/atom/movable/AM)
	if(!AM)
		return FALSE
	if(isturf(AM.loc) || isbelly(AM.loc))
		return AM.loc

	return find_belly_or_turf(AM.loc)


////////////////////////////////////////////////////////////////////////////////

/obj/inventory_recovery
	name = "\improper \a Utility Reclamation Platform"
	desc = "It's a marvel of modern technology! The U.R.P. tracks a user's belongings and can usually recover them from certain inconvenient places, such as <span class='cult'>particularly cramped organic environments</span>!"
	icon = 'icons/rogue-star/misc32x96.dmi'
	icon_state = "item_recovery"

	anchored = TRUE
	density = FALSE
	plane = MOB_PLANE
	layer = MOB_LAYER

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
