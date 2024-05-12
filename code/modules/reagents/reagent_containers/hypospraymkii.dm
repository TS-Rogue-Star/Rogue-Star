#define HYPO_SPRAY 0
#define HYPO_INJECT 1

#define WAIT_SPRAY 5 SECONDS
#define WAIT_INJECT 5 SECONDS
#define SELF_SPRAY 3 SECONDS
#define SELF_INJECT 3 SECONDS

#define DELUXE_WAIT_SPRAY 4 SECONDS
#define DELUXE_WAIT_INJECT 4 SECONDS
#define DELUXE_SELF_SPRAY 2 SECONDS
#define DELUXE_SELF_INJECT 2 SECONDS

#define COMBAT_WAIT_SPRAY 0
#define COMBAT_WAIT_INJECT 0
#define COMBAT_SELF_SPRAY 0
#define COMBAT_SELF_INJECT 0

//A vial-loaded hypospray. Cartridge-based! But betterer!
/obj/item/weapon/hypospray_mkii
	name = "hypospray mk.II"
	icon_state = "hypo2"
	icon = 'icons/obj/syringe.dmi'
	item_state = "hypo2"
	item_icons = list(
		slot_l_hand_str = 'icons/mob/items/lefthand.dmi',
		slot_r_hand_str = 'icons/mob/items/righthand.dmi',
		)
	desc = "A refined development from DeForest Medical, this hypospray takes 30-unit vials as the drug supply for easy swapping. It is more ergonomic for humanoids!"
	w_class = ITEMSIZE_SMALL
	var/list/allowed_containers = list(/obj/item/weapon/reagent_containers/glass/bottle/hypovial/small)
	var/mode = HYPO_INJECT
	var/obj/item/weapon/reagent_containers/glass/bottle/hypovial/vial
	var/start_vial = /obj/item/weapon/reagent_containers/glass/bottle/hypovial/small
	var/spawnwithvial = TRUE
	var/inject_wait = WAIT_INJECT
	var/spray_wait = WAIT_SPRAY
	var/spray_self = SELF_SPRAY
	var/inject_self = SELF_INJECT
	var/quickload = FALSE
	var/emagged = FALSE

	slot_flags = SLOT_BELT
	unacidable = TRUE
	drop_sound = 'sound/items/drop/gun.ogg'
	pickup_sound = 'sound/items/pickup/gun.ogg'
	preserve_item = TRUE

/obj/item/weapon/hypospray_mkii/brute
	start_vial = /obj/item/weapon/reagent_containers/glass/bottle/hypovial/small/preloaded/bicaridine

/obj/item/weapon/hypospray_mkii/toxin
	start_vial = /obj/item/weapon/reagent_containers/glass/bottle/hypovial/small/preloaded/antitoxin

/obj/item/weapon/hypospray_mkii/oxygen
	start_vial = /obj/item/weapon/reagent_containers/glass/bottle/hypovial/small/preloaded/dexalin

/obj/item/weapon/hypospray_mkii/burn
	start_vial = /obj/item/weapon/reagent_containers/glass/bottle/hypovial/small/preloaded/kelotane

/obj/item/weapon/hypospray_mkii/tricord
	start_vial = /obj/item/weapon/reagent_containers/glass/bottle/hypovial/small/preloaded/tricordrazine

/obj/item/weapon/hypospray_mkii/CMO
	name = "hypospray mk.II deluxe"
	allowed_containers = list(/obj/item/weapon/reagent_containers/glass/bottle/hypovial/small, /obj/item/weapon/reagent_containers/glass/bottle/hypovial/large)
	icon_state = "cmo2"
	item_state = "cmo2"
	desc = "The Deluxe Hypospray can take larger-size vials. It also acts faster and delivers more reagents per spray."
	start_vial = /obj/item/weapon/reagent_containers/glass/bottle/hypovial/large/preloaded/CMO
	inject_wait = DELUXE_WAIT_INJECT
	spray_wait = DELUXE_WAIT_SPRAY
	spray_self = DELUXE_SELF_SPRAY
	inject_self = DELUXE_SELF_INJECT

/obj/item/weapon/hypospray_mkii/CMO/combat
	name = "combat hypospray mk.II"
	desc = "A combat-ready deluxe hypospray that acts almost instantly. It can be tactically reloaded by using a vial on it."
	icon_state = "combat2"
	item_state = "combat2"
	start_vial = /obj/item/weapon/reagent_containers/glass/bottle/hypovial/large/preloaded/combat
	inject_wait = COMBAT_WAIT_INJECT
	spray_wait = COMBAT_WAIT_SPRAY
	spray_self = COMBAT_SELF_SPRAY
	inject_self = COMBAT_SELF_INJECT
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
	icon_state = "[initial(icon_state)][vial ? "" : "-e"]"
	if(ismob(loc))
		var/mob/M = loc
		M.update_inv_active_hand()
	return

/obj/item/weapon/hypospray_mkii/examine(mob/user)
	. = ..()
	. += "<span class='notice'><b>Alt-Click</b> it to toggle its mode from spraying to injecting and vice versa.</span>"
	. += "<span class='notice'><b>Ctrl-Click</b> it to unload a vial.</span>"
	if(vial)
		. += "[vial] has [vial.reagents.total_volume]u remaining."
	else
		. += "It has no vial loaded in."
	. += "[src] is set to [mode ? "Inject" : "Spray"] contents on application."

/obj/item/weapon/hypospray_mkii/proc/unload_hypo(obj/item/I, mob/user)
	if(istype(I, /obj/item/weapon/reagent_containers/glass/bottle/hypovial))
		var/obj/item/weapon/reagent_containers/glass/bottle/hypovial/V = I
		V.forceMove(user.loc)
		user.put_in_hands(V)
		to_chat(user, "<span class='notice'>You remove [vial] from [src].</span>")
		vial = null
		update_icon()
		playsound(loc, 'sound/weapons/empty.ogg', 50, 1)
	else
		to_chat(user, "<span class='notice'>This hypo isn't loaded!</span>")
		return

/obj/item/weapon/hypospray_mkii/attackby(obj/item/I, mob/living/user)
	if(istype(I, /obj/item/weapon/reagent_containers/glass/bottle/hypovial) && vial != null)
		if(!quickload)
			to_chat(user, "<span class='warning'>[src] can not hold more than one vial!</span>")
			return FALSE
		unload_hypo(vial, user)

	else if(istype(I, /obj/item/weapon/reagent_containers/glass/bottle/hypovial))
		var/obj/item/weapon/reagent_containers/glass/bottle/hypovial/V = I
		if(!is_type_in_list(V, allowed_containers))
			to_chat(user, "<span class='notice'>[src] doesn't accept this type of vial.</span>")
			return FALSE
		user.drop_from_inventory(V,src)
		vial = V
		user.visible_message("<span class='notice'>[user] has loaded a vial into [src].</span>","<span class='notice'>You have loaded [vial] into [src].</span>")
		update_icon()
		playsound(loc, 'sound/weapons/empty.ogg', 35, 1)
		return TRUE
	else
		to_chat(user, "<span class='notice'>This doesn't fit in [src].</span>")
		return FALSE

/obj/item/weapon/hypospray_mkii/emag_act(mob/user)
	. = ..()
	if(emagged)
		to_chat(user, "[src] happens to be already overcharged.")
		return
	inject_wait = COMBAT_WAIT_INJECT
	spray_wait = COMBAT_WAIT_SPRAY
	spray_self = COMBAT_SELF_INJECT
	inject_self = COMBAT_SELF_SPRAY
	to_chat(user, "You overcharge [src]'s control circuit.")
	emagged = TRUE
	return TRUE

/obj/item/weapon/hypospray_mkii/attack_hand(mob/user)
	. = ..() //Don't bother changing this or removing it from containers will break.

/obj/item/weapon/hypospray_mkii/attack(obj/item/I, mob/user, params)
	return

/obj/item/weapon/hypospray_mkii/afterattack(atom/target, mob/user, proximity)
	if(!vial || !proximity || !isliving(target))
		return
	var/mob/living/L = target

	if(!L.reagents)
		return

	if(iscarbon(L))
		var/obj/item/organ/external/affected = L.get_organ(user.zone_sel.selecting)
		if(!affected)
			to_chat(user, "<span class='warning'>The limb is missing!</span>")
			return
		if(affected.status != ORGAN_FLESH)
			to_chat(user, "<span class='notice'>Medicine won't work on a robotic limb!</span>")
			return

	//Always log attemped injections for admins
	var/contained = vial.reagentlist()
	if(!vial)
		to_chat(user, "<span class='notice'>[src] doesn't have any vial installed!</span>")
		return
	if(!vial.reagents.total_volume)
		to_chat(user, "<span class='notice'>[src]'s vial is empty!</span>")
		return

	var/fp_verb = mode == HYPO_SPRAY ? "spray" : "inject"

	if(L != user)
		L.visible_message("<span class='danger'>\The [user] is trying to [fp_verb] \the [L] with \the [src]!</span>", \
						"<span class='userdanger'>\The [user] is trying to [fp_verb] you with \the [src]!</span>")
	add_attack_logs(user, L, "[user] attemped to use [src] on [L] which had [contained]")

	if(!do_mob(user, L, inject_wait))
		return

	if(!vial.reagents.total_volume)
		return
	add_attack_logs(user, L, "[user] applied [src] to [L], which had [contained] (INTENT: [uppertext(user.a_intent)]) (MODE: [fp_verb])")
	if(L != user)
		L.visible_message("<span class='danger'>\The [user] [fp_verb]s \the [L] with \the [src]!</span>", \
						"<span class='userdanger'>\The [user] [fp_verb]s you with \the [src]!</span>")
	else
		add_attack_logs(user, L, "[user] applied [src] on [L] with [src] which had [contained]")

	if(mode == HYPO_SPRAY)
		vial.reagents.trans_to_mob(target, vial.amount_per_transfer_from_this, CHEM_TOUCH)
	else if(mode == HYPO_INJECT)
		vial.reagents.trans_to_mob(target, vial.amount_per_transfer_from_this, CHEM_BLOOD)

	playsound(loc, 'sound/effects/hypospray.ogg', 50)
	playsound(loc, 'sound/effects/refill.ogg', 50)
	to_chat(user, "<span class='notice'>You [fp_verb] [vial.amount_per_transfer_from_this] units of the solution. The hypospray's cartridge now contains [vial.reagents.total_volume] units.</span>")

/obj/item/weapon/hypospray_mkii/attack_self(mob/living/user)
	if(user)
		if(user.incapacitated())
			return
		else if(!vial)
			to_chat(user, "\The [src] needs to be loaded first!")
			return
		else
			unload_hypo(vial,user)

/obj/item/weapon/hypospray_mkii/AltClick(mob/living/user)
	. = ..()
	if(user.CanUseTopic(src, FALSE))
		switch(mode)
			if(HYPO_SPRAY)
				mode = HYPO_INJECT
				to_chat(user, "[src] is now set to inject contents on application.")
			if(HYPO_INJECT)
				mode = HYPO_SPRAY
				to_chat(user, "[src] is now set to spray contents on application.")
		return TRUE

/obj/item/weapon/hypospray_mkii/CtrlClick(mob/living/user)
	if(user)
		if(user.incapacitated())
			return
		else if(vial)
			unload_hypo(vial, user)
			return TRUE
		else
			to_chat(user, "This Hypo needs to be loaded first!")
			return

#undef HYPO_SPRAY
#undef HYPO_INJECT
#undef WAIT_SPRAY
#undef WAIT_INJECT
#undef SELF_SPRAY
#undef SELF_INJECT
#undef DELUXE_WAIT_SPRAY
#undef DELUXE_WAIT_INJECT
#undef DELUXE_SELF_SPRAY
#undef DELUXE_SELF_INJECT
#undef COMBAT_WAIT_SPRAY
#undef COMBAT_WAIT_INJECT
#undef COMBAT_SELF_SPRAY
#undef COMBAT_SELF_INJECT

//MK II hypovials to avoid cross contamination with base
/obj/item/weapon/reagent_containers/glass/bottle/hypovial
	name = "hypospray vial"
	desc = "This is a vial suitable for loading into mk II hyposprays."
	icon_state = "hypovial"
	item_state = "hypovial"
	w_class = ITEMSIZE_SMALL //Why would it be the same size as a beaker?
	flags = OPENCONTAINER | NOCONDUCT
	unacidable = TRUE
	var/bluespaced = FALSE
	var/comes_with = list() //Easy way of doing this.
	var/fillingsize = "hypovial"
	volume = 10
	can_be_placed_into = list(
		/obj/machinery/chem_master/,
		/obj/machinery/chemical_dispenser,
		/obj/machinery/smartfridge/,
		/obj/structure/table,
		/obj/structure/closet,
		/obj/structure/sink,
		/obj/item/weapon/storage,
		/obj/machinery/disposal,
		/obj/structure/medical_stand
		)	//just storage/washing. sealed containers so they aren't just copycat beakers.

	var/unique_reskin = list("hypovial" = "hypovial",
						"red hypovial" = "hypovial-b",
						"blue hypovial" = "hypovial-d",
						"green hypovial" = "hypovial-a",
						"orange hypovial" = "hypovial-k",
						"purple hypovial" = "hypovial-p",
						"black hypovial" = "hypovial-t"
						)

/obj/item/weapon/reagent_containers/glass/bottle/hypovial/Initialize()
	. = ..()
	if(!icon_state)
		icon_state = "hypovial"
	update_icon()

/obj/item/weapon/reagent_containers/glass/bottle/hypovial/attack(mob/M as mob, mob/user as mob)
	if(M == user)
		to_chat(user, "<span class='notice'>This is a sealed container, you cannot drink from it.</span>")
		return
	else if(istype(M, /mob/living/carbon/human))
		to_chat(user, "<span class='notice'>This is a sealed container, [M] cannot drink from it.</span>")
		return

/obj/item/weapon/reagent_containers/glass/bottle/hypovial/attackby(obj/item/weapon/W as obj, mob/user as mob)
	if(istype(W, /obj/item/weapon/pen) || istype(W, /obj/item/device/flashlight/pen))
		var/selection = tgui_input_list(user, "Label or Recolor?", "Vial Customization", list(
				"Label", "Recolor", "Cancel"))
		if(!selection)
			return

		switch(selection)
			if("Label")
				var/tmp_label = sanitizeSafe(tgui_input_text(user, "Enter a label for [name]", "Label", label_text, MAX_NAME_LEN), MAX_NAME_LEN)
				if(length(tmp_label) > 50)
					to_chat(user, "<span class='notice'>The label can be at most 50 characters long.</span>")
				else if(length(tmp_label) > 10)
					to_chat(user, "<span class='notice'>You set the label.</span>")
					label_text = tmp_label
					update_name_label()
				else
					to_chat(user, "<span class='notice'>You set the label to \"[tmp_label]\".</span>")
					label_text = tmp_label
					update_name_label()
			if("Recolor")
				reskin_vial(user)
			if("Cancel")
				return

/obj/item/weapon/reagent_containers/glass/bottle/hypovial/afterattack(var/obj/target, var/mob/user, var/proximity)
	if(!is_open_container() || !proximity) //Is the container open & are they next to whatever they're clicking?
		return 1 //If not, do nothing.
	for(var/type in can_be_placed_into) //Is it something it can be placed into?
		if(istype(target, type))
			return TRUE
	if(standard_dispenser_refill(user, target)) //Are they clicking a water tank/some dispenser?
		return TRUE
	if(standard_pour_into(user, target)) //Pouring into another beaker?
		return
	if(user.a_intent == I_HURT)
		return
	..()

/obj/item/weapon/reagent_containers/glass/bottle/hypovial/proc/reskin_vial(mob/M)
	if(!LAZYLEN(unique_reskin))
		return
	var/choice = input(M,"Do you wish to recolour your [src]?","Vial Recolor") as null|anything in unique_reskin
	if(!QDELETED(src) && choice && !M.incapacitated() && in_range(M,src))
		if(!unique_reskin[choice])
			return
		icon_state = unique_reskin[choice]
		name = choice
		to_chat(M, "[src] is now skinned as '[choice].'")

/obj/item/weapon/reagent_containers/glass/bottle/hypovial/on_reagent_change()
	update_icon()

/obj/item/weapon/reagent_containers/glass/bottle/hypovial/update_icon()
	cut_overlays()
	if(reagents.total_volume)
		var/mutable_appearance/filling = mutable_appearance('icons/obj/reagentfillings.dmi', "[fillingsize]10")

		var/percent = round((reagents.total_volume / volume) * 100)
		switch(percent)
			if(0 to 9)
				filling.icon_state = "[fillingsize]10"
			if(10 to 29)
				filling.icon_state = "[fillingsize]25"
			if(30 to 49)
				filling.icon_state = "[fillingsize]50"
			if(50 to 69)
				filling.icon_state = "[fillingsize]75"
			if(70 to INFINITY)
				filling.icon_state = "[fillingsize]100"

		filling.color = reagents.get_color()
		add_overlay(filling)
	if(bluespaced)
		add_overlay("[fillingsize]bs")

/obj/item/weapon/reagent_containers/glass/bottle/hypovial/small
	volume = 30
	possible_transfer_amounts = list(5,10,15)

/obj/item/weapon/reagent_containers/glass/bottle/hypovial/small/bluespace
	volume = 60
	bluespaced = TRUE

/obj/item/weapon/reagent_containers/glass/bottle/hypovial/large
	name = "large hypospray vial"
	desc = "This is a vial suitable for loading into the Chief Medical Officer's Hypospray mk II."
	icon_state = "hypoviallarge"
	fillingsize = "hypoviallarge"
	volume = 60
	possible_transfer_amounts = list(5,10,15,25,30)

	unique_reskin = list("large hypovial" = "hypoviallarge",
						"large red hypovial" = "hypoviallarge-b",
						"large blue hypovial" = "hypoviallarge-d",
						"large green hypovial" = "hypoviallarge-a",
						"large orange hypovial" = "hypoviallarge-k",
						"large purple hypovial" = "hypoviallarge-p",
						"large black hypovial" = "hypoviallarge-t"
						)

/obj/item/weapon/reagent_containers/glass/bottle/hypovial/large/bluespace
	volume = 120
	bluespaced = TRUE

/obj/item/weapon/reagent_containers/glass/bottle/hypovial/New()
	..()
	for(var/R in comes_with)
		reagents.add_reagent(R,comes_with[R])

/obj/item/weapon/reagent_containers/glass/bottle/hypovial/small/preloaded/bicaridine
	name = "vial (bicaridine)"
	icon_state = "hypovial-b"
	comes_with = list("bicaridine" = 30)

/obj/item/weapon/reagent_containers/glass/bottle/hypovial/small/preloaded/antitoxin
	name = "vial (Anti-Tox)"
	icon_state = "hypovial-a"
	comes_with = list("anti_toxin" = 30)

/obj/item/weapon/reagent_containers/glass/bottle/hypovial/small/preloaded/kelotane
	name = "vial (kelotane)"
	icon_state = "hypovial-k"
	comes_with = list("kelotane" = 30)

/obj/item/weapon/reagent_containers/glass/bottle/hypovial/small/preloaded/dexalin
	name = "vial (dexalin)"
	icon_state = "hypovial-d"
	comes_with = list("dexalin" = 30)

/obj/item/weapon/reagent_containers/glass/bottle/hypovial/small/preloaded/tricordrazine
	name = "vial (tricord)"
	icon_state = "hypovial"
	comes_with = list("tricordrazine" = 30)

/obj/item/weapon/reagent_containers/glass/bottle/hypovial/large/preloaded/CMO
	name = "large vial (CMO Special)"
	icon_state = "hypoviallarge-cmos"
	comes_with = list("inaprovaline" = 10, "dermaline" = 10, "anti_toxin" = 10, "tramadol" = 10, "bicaridine" = 10, "dexalinp" = 10)

/obj/item/weapon/reagent_containers/glass/bottle/hypovial/large/preloaded/combat
	name = "large vial (Combat Mix)"
	icon_state = "hypoviallarge-cmos"
	comes_with = list("bicaridine" = 10, "kelotane" = 10, "dermaline" = 10, "oxycodone" = 10, "inaprovaline" = 10, "tricordrazine" = 10)

/obj/item/weapon/reagent_containers/glass/bottle/hypovial/large/preloaded/bicaridine
	name = "large vial (Bicaridine)"
	icon_state = "hypoviallarge-b"
	comes_with = list("bicaridine" = 60)

/obj/item/weapon/reagent_containers/glass/bottle/hypovial/large/preloaded/antitoxin
	name = "large vial (Anti-Tox)"
	icon_state = "hypoviallarge-a"
	comes_with = list("anti_toxin" = 60)

/obj/item/weapon/reagent_containers/glass/bottle/hypovial/large/preloaded/dermaline
	name = "large vial (Dermaline)"
	icon_state = "hypoviallarge-k"
	comes_with = list("dermaline" = 60)

/obj/item/weapon/reagent_containers/glass/bottle/hypovial/large/preloaded/dexalin
	name = "large vial (Dexalin Plus)"
	icon_state = "hypoviallarge-d"
	comes_with = list("dexalinp" = 60)
