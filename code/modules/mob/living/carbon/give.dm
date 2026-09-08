/mob/living/verb/give(var/mob/living/target in living_mobs_in_view(1)) //RS Edit Chomp port #7484
	set category = "IC"
	set name = "Give"

	do_give(target)

// RS EDIT
/mob/living/proc/do_give(var/mob/living/carbon/human/target, obj/item/offering)
	if(incapacitated())
		return FALSE
	if(!istype(target))
		return FALSE
	if(target.incapacitated())
		return FALSE

	var/obj/item/I = offering || get_active_hand() || get_inactive_hand()
	if(!I || !item_is_in_hands(I))
		to_chat(src, SPAN_WARNING("You don't have anything in your hands to give to \the [target]."))
		return FALSE

	visible_message(SPAN_NOTICE("\The [src] holds out \the [I] to \the [target]."), SPAN_NOTICE("You hold out \the [I] to \the [target], waiting for them to accept it."))

	var/accepted = target.accepts_offer(src, I)
	if(!accepted)
		visible_message(SPAN_NOTICE("\The [src] tried to hand \the [I] to \the [target], but \the [target] didn't want it."))
		return FALSE

	return complete_give(target, I)

// RS EDIT
/mob/living/proc/accepts_offer(mob/living/giver, obj/item/I)
	if(client)
		var/answer = tgui_alert(src, "[giver] wants to give you \a [I]. Will you accept it?", "Item Offer", list("Yes", "No"))
		return answer == "Yes"
	return FALSE

// RS EDIT
/mob/living/proc/complete_give(var/mob/living/carbon/human/target, obj/item/I)
	if(QDELETED(I) || QDELETED(target))
		return FALSE

	if(!Adjacent(target))
		to_chat(src, SPAN_WARNING("You need to stay in reaching distance while giving an object"))
		to_chat(target, SPAN_WARNING("\The [src] moved too far away."))
		return FALSE

	if(I.loc != src || !item_is_in_hands(I))
		to_chat(src, SPAN_WARNING("You need to keep the item in your hands."))
		to_chat(target, SPAN_WARNING("\The [src] seems to have given up on passing \the [I] to you."))
		return FALSE

	if(target.hands_are_full())
		to_chat(target, SPAN_WARNING("Your hands are full."))
		to_chat(src, SPAN_WARNING("Their hands are full."))
		return FALSE

	if(!unEquip(I))
		return FALSE

	target.put_in_hands(I) // If this fails it will just end up on the floor, but that's fitting for things like dionaea.
	target.visible_message(SPAN_NOTICE("\The [src] handed \the [I] to \the [target]"))
	return TRUE
