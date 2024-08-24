#define HYPO_SPRAY 0
#define HYPO_INJECT 1

//#define WAIT_SPRAY 2 SECONDS
#define WAIT_INJECT 2 SECONDS
//#define SELF_SPRAY 1 SECONDS
//#define SELF_INJECT 1 SECONDS

//#define DELUXE_WAIT_SPRAY 1 SECONDS
#define DELUXE_WAIT_INJECT 1 SECONDS
//#define DELUXE_SELF_SPRAY 1 SECONDS
//#define DELUXE_SELF_INJECT 1 SECONDS

//#define COMBAT_WAIT_SPRAY 0
#define COMBAT_WAIT_INJECT 0
//#define COMBAT_SELF_SPRAY 0
//#define COMBAT_SELF_INJECT 0

//A vial-loaded hypospray. Cartridge-based! But betterer!
/obj/item/weapon/hypospray_mkii
	name = "hypospray"
	icon_state = "nhypo"
	icon = 'icons/obj/syringe.dmi'
	item_state = "nhypo"
	item_icons = list(
		slot_l_hand_str = 'icons/mob/items/lefthand.dmi',
		slot_r_hand_str = 'icons/mob/items/righthand.dmi',
		)
	desc = "A refined development from DeForest Medical, altered construction materials enable wider availability, this hypospray takes 30-unit vials as the drug supply for easy swapping."
	w_class = ITEMSIZE_SMALL
	var/list/allowed_containers = list(/obj/item/weapon/reagent_containers/glass/beaker/vial)
	var/mode = HYPO_INJECT
	var/obj/item/weapon/reagent_containers/glass/beaker/vial/vial

	//var/obj/item/weapon/reagent_containers/glass/beaker/vial/vial
	var/start_vial = /obj/item/weapon/reagent_containers/glass/beaker/vial
	//var/start_vial = /obj/item/weapon/reagent_containers/glass/beaker/vial
	var/injecting //Added to stop you from queuing up a bunch of injections at once
	var/spawnwithvial = TRUE
	var/inject_wait = WAIT_INJECT
	//var/spray_wait = WAIT_SPRAY
	//var/spray_self = SELF_SPRAY
	//var/inject_self = SELF_INJECT
	var/quickload = TRUE
	var/emagged = FALSE
	var/amount_per_transfer_from_this = "vial"
	var/possible_transfer_amounts = list("vial",1,5,10,15)
	slot_flags = SLOT_BELT
	unacidable = TRUE
	drop_sound = 'sound/items/drop/gun.ogg'
	pickup_sound = 'sound/items/pickup/gun.ogg'
	preserve_item = TRUE

/obj/item/weapon/hypospray_mkii/CMO
	name = "hypospray mk.II deluxe"
	allowed_containers = list(/obj/item/weapon/reagent_containers/glass/bottle, /obj/item/weapon/reagent_containers/glass/beaker/vial)
	icon_state = "nadvhypo"
	item_state = "nadvhypo"
	desc = "The Deluxe Hypospray can take larger-size vials. It also acts faster and delivers more reagents per spray."
	possible_transfer_amounts = list("vial",1,5,10,15,25,30)
	//start_vial = /obj/item/weapon/reagent_containers/glass/bottle
	start_vial = /obj/item/weapon/reagent_containers/glass/bottle/preloaded/tricordrazine
	inject_wait = DELUXE_WAIT_INJECT
	//spray_wait = DELUXE_WAIT_SPRAY
	//spray_self = DELUXE_SELF_SPRAY
	//inject_self = DELUXE_SELF_INJECT
	quickload = TRUE

/obj/item/weapon/hypospray_mkii/CMO/combat
	name = "combat hypospray mk.II"
	desc = "A combat-ready deluxe hypospray that acts almost instantly. It can be tactically reloaded by using a vial on it."
	icon_state = "ncadvhypo"
	item_state = "ncadvhypo"
	start_vial = /obj/item/weapon/reagent_containers/glass/beaker
	//start_vial = /obj/item/weapon/reagent_containers/glass/bottle
	//var/obj/item/weapon/reagent_containers/glass/beaker/vial
	inject_wait = COMBAT_WAIT_INJECT
	//spray_wait = COMBAT_WAIT_SPRAY
	//spray_self = COMBAT_SELF_SPRAY
	//inject_self = COMBAT_SELF_INJECT
	quickload = TRUE

/obj/item/weapon/hypospray_mkii/Initialize()
	. = ..()
	if(!spawnwithvial)
		update_icon()
		return
	if(start_vial)
		vial = new start_vial
	update_icon()

/obj/item/weapon/hypospray_mkii/update_icon()
	..()
	icon_state = "[initial(icon_state)][vial ? "" : "_empty"]"
	if(ismob(loc))
		var/mob/M = loc
		M.update_inv_active_hand()
	return

/obj/item/weapon/hypospray_mkii/examine(mob/user)
	. = ..()
	//. += span_notice("<b>Alt-Click</b> it to toggle its mode from spraying to injecting and vice versa.")
	. += span_notice("<b>Alt-Click</b> it to Adjust injection ammount.")
	. += span_notice("<b>Ctrl-Click</b> it to unload a vial.")
	if(vial)
		. += "[vial] has [vial.reagents.total_volume]u remaining."
	else
		. += "It has no vial loaded in."
	. += "[src] is set to [mode ? "Inject" : "Spray"] contents on application."

/obj/item/weapon/hypospray_mkii/proc/unload_hypo(obj/item/I, mob/user, var/drop)
	if(is_type_in_list(I, allowed_containers))
		var/obj/item/weapon/reagent_containers/glass/beaker/vial/V = I
		if(drop)
			V.forceMove(user.loc)
			user.put_in_hands(V)
			to_chat(user, span_notice("You remove [vial] from [src]."))
		vial = null
		update_icon()
		playsound(loc, 'sound/weapons/empty.ogg', 50, 1)
	else
		to_chat(user, span_notice("This hypo isn't loaded!"))
		return

/obj/item/weapon/hypospray_mkii/attackby(obj/item/I, mob/living/user)
	if(is_type_in_list(I, allowed_containers) && vial != null)
		if(!quickload)
			to_chat(user, span_warning("[src] can not hold more than one vial!"))
			return FALSE

		var/obj/item/weapon/reagent_containers/glass/beaker/vial/V = I
		user.drop_from_inventory(V,src)
		unload_hypo(vial, user, 1)
		vial = V
		user.visible_message(span_notice("[user] has loaded a vial into [src]."),span_notice("You have loaded [vial] into [src]."))
		update_icon()
		playsound(loc, 'sound/weapons/empty.ogg', 35, 1)
		return TRUE

	else if(is_type_in_list(I, allowed_containers))
		var/obj/item/weapon/reagent_containers/glass/beaker/vial/V = I
		//if(!is_type_in_list(V, allowed_containers))
		//	to_chat(user, span_notice("[src] doesn't accept this type of vial."))
		//	return FALSE
		user.drop_from_inventory(V,src)
		vial = V
		user.visible_message(span_notice("[user] has loaded a vial into [src]."),span_notice("You have loaded [vial] into [src]."))
		update_icon()
		playsound(loc, 'sound/weapons/empty.ogg', 35, 1)
		return TRUE
	else
		to_chat(user, span_notice("This doesn't fit in [src]."))
		return FALSE

/obj/item/weapon/hypospray_mkii/emag_act(mob/user)
	. = ..()
	if(emagged)
		to_chat(user, span_warning("[src] happens to be already overcharged."))
		return
	inject_wait = COMBAT_WAIT_INJECT
	//spray_wait = COMBAT_WAIT_SPRAY
	//spray_self = COMBAT_SELF_INJECT
	//inject_self = COMBAT_SELF_SPRAY
	to_chat(user, span_warning("You overcharge [src]'s control circuit."))
	emagged = TRUE
	return TRUE

/obj/item/weapon/hypospray_mkii/attack_hand(mob/user)
	. = ..() //Don't bother changing this or removing it from containers will break.

/obj/item/weapon/hypospray_mkii/attack(obj/item/I, mob/user, params)
	return

/obj/item/weapon/hypospray_mkii/afterattack(atom/target, mob/user, proximity)
	var/obj/item/weapon/I = target
	if(!proximity || !isliving(target) || injecting == 1)
		if(!istype(I, /obj/item/weapon/reagent_containers))
			return
		var/obj/item/weapon/storage/storedloc = I.loc
		var/obj/item/weapon/reagent_containers/glass/beaker/vial/V = I
		if(is_type_in_list(I, allowed_containers) && vial != null)
			if(!quickload)
				to_chat(user, span_warning("[src] can not hold more than one vial!"))
				return FALSE
			user.drop_from_inventory(V,src)
			if(isobj(storedloc))
				storedloc.handle_item_insertion(vial,1)
				unload_hypo(vial, user, 0)
			else
				unload_hypo(vial, user, 1)
			vial = V
			user.visible_message(span_notice("[user] has loaded a vial into [src]."),span_notice("You have loaded [vial] into [src]."))
			update_icon()
			playsound(loc, 'sound/weapons/empty.ogg', 35, 1)
			return TRUE

		else if(is_type_in_list(I, allowed_containers))
			if(isobj(storedloc))
				storedloc.remove_from_storage(I, src)
			user.drop_from_inventory(V,src)
			vial = V
			user.visible_message(span_notice("[user] has loaded a vial into [src]."),span_notice("You have loaded [vial] into [src]."))
			update_icon()
			playsound(loc, 'sound/weapons/empty.ogg', 35, 1)
			return TRUE
		else
			to_chat(user, span_notice("This doesn't fit in [src]."))
			return FALSE

	if(!vial || !proximity || !isliving(target) || injecting == 1)
		return
	var/mob/living/L = target

	if(!L.reagents)
		return

	if(iscarbon(L))
		var/obj/item/organ/external/affected = L.get_organ(user.zone_sel.selecting)
		if(!affected)
			to_chat(user, span_warning("The limb is missing!"))
			return
		if(affected.status != ORGAN_FLESH)
			to_chat(user, span_notice("Medicine won't work on a robotic limb!"))
			return

	//Always log attemped injections for admins
	var/contained = vial.reagentlist()
	if(!vial)
		to_chat(user, span_notice("[src] doesn't have any vial installed!"))
		return
	if(!vial.reagents.total_volume)
		to_chat(user, span_notice("[src]'s vial is empty!"))
		return

	var/fp_verb = mode == HYPO_SPRAY ? "spray" : "inject"

	if(L != user)
		L.visible_message(span_danger("\The [user] is trying to [fp_verb] \the [L] with \the [src]!"), \
						span_danger("\The [user] is trying to [fp_verb] you with \the [src]!"))
	add_attack_logs(user, L, "[user] attemped to use [src] on [L] which had [contained]")
	injecting = 1
	if(!emagged && inject_wait != COMBAT_WAIT_INJECT)
		var/inject_wait_me = inject_wait
		if(amount_per_transfer_from_this == "vial") //use vial transfer rate
			inject_wait_me = 5 + vial.amount_per_transfer_from_this
		else
			inject_wait_me = 5 + amount_per_transfer_from_this
		if(!do_mob(user, L, inject_wait_me, 0, 0, 1, 0, 1))
			injecting = 0
			return

	if(!vial.reagents.total_volume)
		injecting = 0
		return
	add_attack_logs(user, L, "[user] applied [src] to [L], which had [contained] (INTENT: [uppertext(user.a_intent)]) (MODE: [fp_verb])")
	if(L != user)
		L.visible_message(span_danger("\The [user] [fp_verb]s \the [L] with \the [src]!"), \
						span_danger("\The [user] [fp_verb]s you with \the [src]!"))
	else
		add_attack_logs(user, L, "[user] applied [src] on [L] with [src] which had [contained]")
	if(amount_per_transfer_from_this == "vial") //use vial transfer rate
		if(mode == HYPO_SPRAY)
			vial.reagents.trans_to_mob(target, vial.amount_per_transfer_from_this,CHEM_TOUCH)
		else if(mode == HYPO_INJECT)
			vial.reagents.trans_to_mob(target, vial.amount_per_transfer_from_this, CHEM_BLOOD)
		to_chat(user, span_notice("You [fp_verb] [vial.amount_per_transfer_from_this] units of the solution. The hypospray's cartridge now contains [vial.reagents.total_volume] units."))
	else //Use hypo transfer rate
		if(mode == HYPO_SPRAY)
			vial.reagents.trans_to_mob(target, amount_per_transfer_from_this,CHEM_TOUCH)
		else if(mode == HYPO_INJECT)
			vial.reagents.trans_to_mob(target, amount_per_transfer_from_this, CHEM_BLOOD)
		to_chat(user, span_notice("You [fp_verb] [amount_per_transfer_from_this] units of the solution. The hypospray's cartridge now contains [vial.reagents.total_volume] units."))
	injecting = 0
	playsound(loc, 'sound/effects/hypospray.ogg', 50)
	playsound(loc, 'sound/effects/refill.ogg', 50)


/obj/item/weapon/hypospray_mkii/attack_self(mob/living/user)
	if(user)
		if(user.incapacitated())
			return
		else if(!vial)
			to_chat(user, "\The [src] needs to be loaded first!")
			return
		else
			unload_hypo(vial,user,1)

/obj/item/weapon/hypospray_mkii/verb/set_APTFT() //set amount_per_transfer_from_this
	set name = "Set transfer amount"
	set category = "Object"
	set src in range(0)
	var/N = tgui_input_list(usr, "Amount per transfer from this:","[src]", possible_transfer_amounts)
	//if(N)
	if(N == "vial")
		to_chat(usr, "[src] Defaulting to vial transfer amount.")
	else
		to_chat(usr, "[src] Setting injection amount to [N].")
	amount_per_transfer_from_this = N

/obj/item/weapon/hypospray_mkii/verb/swap_mode() //set amount_per_transfer_from_this
	set name = "Swap spray mode"
	set category = "Object"
	set src in range(0)
	switch(mode)
		if(HYPO_SPRAY)
			mode = HYPO_INJECT
			to_chat(usr, "[src] is now set to inject contents on application.")
		if(HYPO_INJECT)
			mode = HYPO_SPRAY
			to_chat(usr, "[src] is now set to spray contents on application.")

/obj/item/weapon/hypospray_mkii/AltClick(mob/living/user)
	. = ..()
	if(user.CanUseTopic(src, FALSE))
		if(possible_transfer_amounts && user.Adjacent(src))
			set_APTFT()
		/*switch(mode)
			if(HYPO_SPRAY)
				mode = HYPO_INJECT
				to_chat(user, "[src] is now set to inject contents on application.")
			if(HYPO_INJECT)
				mode = HYPO_SPRAY
				to_chat(user, "[src] is now set to spray contents on application.")
		*/ //Moved to a verb

		return TRUE

/obj/item/weapon/hypospray_mkii/CtrlClick(mob/living/user)
	if(user)
		if(user.incapacitated())
			return
		else if(vial)
			unload_hypo(vial, user, 1)
			return TRUE
		else
			to_chat(user, "This Hypo needs to be loaded first!")
			return

#undef HYPO_SPRAY
#undef HYPO_INJECT
//#undef WAIT_SPRAY
#undef WAIT_INJECT
//#undef SELF_SPRAY
//#undef SELF_INJECT
//#undef DELUXE_WAIT_SPRAY
#undef DELUXE_WAIT_INJECT
//#undef DELUXE_SELF_SPRAY
//#undef DELUXE_SELF_INJECT
//#undef COMBAT_WAIT_SPRAY
#undef COMBAT_WAIT_INJECT
//#undef COMBAT_SELF_SPRAY
//#undef COMBAT_SELF_INJECT


//Hypo mkI vials, will be moved later
/obj/item/weapon/reagent_containers/glass/beaker/vial/preloaded/bicaridine
	name = "Bicaridine bottle"
	icon_state = "vial"
	prefill = list("bicaridine" = 30)

/obj/item/weapon/reagent_containers/glass/beaker/vial/preloaded/antitoxin
	name = "Dylovene vial"
	icon_state = "vial"
	prefill = list("anti_toxin" = 30)

/obj/item/weapon/reagent_containers/glass/beaker/vial/preloaded/kelotane
	name = "KeloDerma vial"
	icon_state = "vial"
	prefill = list("kelotane" = 15, "dermaline" = 15)

/obj/item/weapon/reagent_containers/glass/beaker/vial/preloaded/dexalin
	name = "Dexalin vial"
	icon_state = "vial"
	prefill = list("dexalin" = 30)

/obj/item/weapon/reagent_containers/glass/beaker/vial/preloaded/tricordrazine
	name = "Tricordrazine vial"
	icon_state = "vial"
	prefill = list("tricordrazine" = 30)

/obj/item/weapon/reagent_containers/glass/beaker/vial/preloaded/tramadol
	name = "Tramadol vial"
	icon_state = "vial"
	prefill = list("tricordrazine" = 30)

//preloaded bottles
/obj/item/weapon/reagent_containers/glass/bottle/preloaded/bicaridine
	name = "Bicaridine bottle"
	icon = 'icons/obj/chemical.dmi'
	icon_state = "bottle-1"
	prefill = list("bicaridine" = 60)

/obj/item/weapon/reagent_containers/glass/bottle/preloaded/antitoxin
	name = "Dylovene bottle"
	icon = 'icons/obj/chemical.dmi'
	icon_state = "bottle-1"
	prefill = list("anti_toxin" = 60)

/obj/item/weapon/reagent_containers/glass/bottle/preloaded/keloderma
	name = "KeloDerma bottle"
	icon = 'icons/obj/chemical.dmi'
	icon_state = "bottle-1"
	prefill = list("kelotane" = 30, "dermaline" = 30)

/obj/item/weapon/reagent_containers/glass/bottle/preloaded/dexalin
	name = "Dexalin bottle"
	icon = 'icons/obj/chemical.dmi'
	icon_state = "bottle-1"
	prefill = list("dexalin" = 60)

/obj/item/weapon/reagent_containers/glass/bottle/preloaded/tricordrazine
	name = "Tricordrazine bottle"
	icon = 'icons/obj/chemical.dmi'
	icon_state = "bottle-1"
	prefill = list("tricordrazine" = 60)

/obj/item/weapon/reagent_containers/glass/bottle/preloaded/tramadol
	name = "Tramadol bottle"
	icon = 'icons/obj/chemical.dmi'
	icon_state = "bottle-1"
	prefill = list("tramadol" = 60)
