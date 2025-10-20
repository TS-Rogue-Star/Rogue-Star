//Boop //New and improved, now a simple reagent sniffer. //No longer a sniffer, sprite datums turn it into one.
/obj/item/device/boop_module
	name = "scanner module"
	icon = 'icons/obj/device_alt.dmi'
	icon_state = "forensic2"
	desc = "The scanner module, a simple reagent and atmosphere scanner."
	force = 0
	throwforce = 0
	w_class = ITEMSIZE_TINY

/obj/item/device/boop_module/New()
	..()
	flags |= NOBLUDGEON //No more attack messages

/obj/item/device/boop_module/attack_self(mob/user)
	if (!( istype(user.loc, /turf) ))
		return

	var/datum/gas_mixture/environment = user.loc.return_air()

	var/pressure = environment.return_pressure()
	var/total_moles = environment.total_moles

	user.setClickCooldown(DEFAULT_ATTACK_COOLDOWN)
	user.visible_message("<span class='notice'>[user] scans the air.</span>", "<span class='notice'>You scan the air...</span>")

	to_chat(user, "<span class='notice'><B>Scan results:</B></span>")
	if(abs(pressure - ONE_ATMOSPHERE) < 10)
		to_chat(user, "<span class='notice'>Pressure: [round(pressure,0.1)] kPa</span>")
	else
		to_chat(user, "<span class='warning'>Pressure: [round(pressure,0.1)] kPa</span>")
	if(total_moles)
		for(var/g in environment.gas)
			to_chat(user, "<span class='notice'>[gas_data.name[g]]: [round((environment.gas[g] / total_moles) * 100)]%</span>")
		to_chat(user, "<span class='notice'>Temperature: [round(environment.temperature-T0C,0.1)]&deg;C ([round(environment.temperature,0.1)]K)</span>")

/obj/item/device/boop_module/afterattack(obj/O, mob/user as mob, proximity)
	if(!proximity)
		return
	if (user.stat)
		return
	if(!istype(O))
		return

	user.setClickCooldown(DEFAULT_ATTACK_COOLDOWN)
	user.visible_message("<span class='notice'>[user] scan at \the [O.name].</span>", "<span class='notice'>You scan \the [O.name]...</span>")

	if(!isnull(O.reagents))
		var/dat = ""
		if(O.reagents.reagent_list.len > 0)
			for (var/datum/reagent/R in O.reagents.reagent_list)
				dat += "\n \t <span class='notice'>[R]</span>"

		if(dat)
			to_chat(user, "<span class='notice'>Your [name] indicates: [dat]</span>")
		else
			to_chat(user, "<span class='notice'>No active chemical agents detected in [O].</span>")
	else
		to_chat(user, "<span class='notice'>No significant chemical agents detected in [O].</span>")

	return


//Delivery
/*
/obj/item/weapon/storage/bag/borgdelivery
	name = "fetching storage"
	desc = "Fetch the thing!"
	icon = 'icons/mob/dogborg_vr.dmi'
	icon_state = "dbag"
	w_class = ITEMSIZE_HUGE
	max_w_class = ITEMSIZE_SMALL
	max_combined_w_class = ITEMSIZE_SMALL
	storage_slots = 1
	collection_mode = 0
	can_hold = list() // any
	cant_hold = list(/obj/item/weapon/disk/nuclear)
*/

/obj/item/weapon/shockpaddles/robot/hound
	name = "paws of life"
	icon = 'icons/mob/dogborg_vr.dmi'
	icon_state = "defibpaddles0"
	desc = "Zappy paws. For fixing cardiac arrest."
	combat = 1
	attack_verb = list("batted", "pawed", "bopped", "whapped")
	chargecost = 500

/obj/item/weapon/shockpaddles/robot/hound/jumper
	name = "jumper paws"
	desc = "Zappy paws. For rebooting a full body prostetic."
	use_on_synthetic = 1

/obj/item/weapon/reagent_containers/borghypo/hound
	name = "MediHound hypospray"
	desc = "An advanced chemical synthesizer and injection system utilizing carrier's reserves, designed for heavy-duty medical equipment."
	//RS Edit Start || Ports CHOMPStation PR6626
	//charge_cost = 10
	reagent_ids = list("inaprovaline", "dexalin", "bicaridine", "kelotane", "anti_toxin", "spaceacillin", "tramadol", "adranol")
	//RS Edit End
	var/datum/matter_synth/water = null

// RS Edit || Ports CHOMPStation PR6626
/*
/obj/item/weapon/reagent_containers/borghypo/hound/process() //Recharges in smaller steps and uses the water reserves as well.
	if(isrobot(loc))
		var/mob/living/silicon/robot/R = loc
		if(R && R.cell)
			for(var/T in reagent_ids)
				if(reagent_volumes[T] < volume && water.energy >= charge_cost)
					R.cell.use(charge_cost)
					water.use_charge(charge_cost)
					reagent_volumes[T] = min(reagent_volumes[T] + 1, volume)
	return 1
*/
/obj/item/weapon/reagent_containers/borghypo/hound/lost
	name = "Hound hypospray"
	desc = "An advanced chemical synthesizer and injection system utilizing carrier's reserves."
	reagent_ids = list("tricordrazine", "inaprovaline", "bicaridine", "dexalin", "anti_toxin", "tramadol", "spaceacillin")

/obj/item/weapon/reagent_containers/borghypo/hound/trauma
	name = "Hound hypospray"
	desc = "An advanced chemical synthesizer and injection system utilizing carrier's reserves."
	reagent_ids = list("tricordrazine", "inaprovaline", "oxycodone", "dexalin" ,"spaceacillin")


//Tongue stuff //Formerly the tongue, returns to tongue via sprite datum. Let it be known that I hate what I'm doing here.
/obj/item/device/robot_tongue
	name = "\improper Ms. Fusion portable reactor"
	desc = "A miracle of modern science that converts household waste into modest amounts of energy. The 'fusion' part may just be a misleading brand name."
	icon = 'icons/mob/dogborg_vr.dmi'
	icon_state = "nottongue"
	var/emagged = 0
	var/dogfluff = FALSE

/obj/item/device/robot_tongue/New()
	..()
	flags |= NOBLUDGEON //No more attack messages

/obj/item/device/robot_tongue/attack_self(mob/user)
	var/mob/living/silicon/robot/R = user
	if(R.emagged || R.emag_items)
		emagged = !emagged
		if(emagged)
			name = "[dogfluff ? "hacked tongue of doom" : "faulty Ms. Fusion portable reactor"]"
			desc = "Your [dogfluff ? "tongue" : "reactor"] has been [dogfluff ? "upgraded" : "sabotaged"] successfully. Congratulations."
			if(dogfluff)
				icon = 'icons/mob/dogborg_vr.dmi'
				icon_state = "syndietongue"
		else
			name = "[dogfluff ? "synthetic tongue" : "\improper Ms. Fusion portable reactor"]"
			desc = "[dogfluff ? "Useful for slurping mess off the floor before affectionately licking the crew members in the face." : "A miracle of modern science that converts household waste into modest amounts of energy. The 'fusion' part may just be a misleading brand name."]"
			if(dogfluff)
				icon = 'icons/mob/dogborg_vr.dmi'
				icon_state = "synthtongue"
		update_icon()

/obj/item/device/robot_tongue/afterattack(atom/target, mob/user, proximity)
	if(!proximity)
		return

	user.setClickCooldown(DEFAULT_ATTACK_COOLDOWN)
	if(user.client && (target in user.client.screen))
		to_chat(user, "<span class='warning'>You need to take \the [target.name] off before cleaning it!</span>")
		return
	else if(istype(target,/obj/item))
		if(istype(target,/obj/item/trash))
			user.visible_message("<span class='filter_notice'>[user] [dogfluff ? "nibbles away at \the [target.name]." : "starts placing \the [target.name] into its reactor."]</span>", "<span class='notice'>You begin to [dogfluff ? "nibble away at \the [target.name]" : "place \the [target.name] into your reactor"]...</span>")
			if(do_after (user, 50))
				user.visible_message("<span class='filter_notice'>[user] [dogfluff ? "finishes eating \the [target.name]." : "places \the [target.name] into its reactor."]</span>", "<span class='notice'>You finish [dogfluff ? "eating \the [target.name]." : "placing \the [target.name] into your reactor."]</span>")
				to_chat(user, "<span class='notice'>You finish off \the [target.name].</span>")
				qdel(target)
				var/mob/living/silicon/robot/R = user
				R.cell.charge += 250
			return
		if(istype(target,/obj/item/weapon/cell))
			user.visible_message("<span class='filter_notice'>[user] begins cramming \the [target.name] [dogfluff ? "down its throat." : "into its reactor."]</span>", "<span class='notice'>You begin cramming \the [target.name] [dogfluff ? "down your throat" : "into your reactor"]...</span>")
			if(do_after (user, 50))
				user.visible_message("<span class='filter_notice'>[user] finishes [dogfluff ? "gulping down \the [target.name]." : "fitting \the [target.name] into its reactor."]</span>", "<span class='notice'>You finish [dogfluff ? "swallowing \the [target.name]." : "fitting \the [target.name] into your reactor."]</span>")
				to_chat(user, "<span class='notice'>You finish off \the [target.name], and gain some charge!</span>")
				var/mob/living/silicon/robot/R = user
				var/obj/item/weapon/cell/C = target
				R.cell.charge += C.charge / 3
				qdel(target)
			return
	else if(ishuman(target))
		if(src.emagged)
			var/mob/living/silicon/robot/R = user
			var/mob/living/L = target
			if(R.cell.charge <= 666)
				return
			L.Stun(1)
			L.Weaken(1)
			L.apply_effect(STUTTER, 1)
			L.visible_message("<span class='danger'>[user] has shocked [L] with its [dogfluff ? "tongue" : "reactor"]!</span>", \
								"<span class='userdanger'>[user] has shocked you with its [dogfluff ? "tongue" : "reactor"]! [dogfluff ? "You can feel the betrayal." : "Great scott!"]</span>")
			playsound(src, 'sound/weapons/Egloves.ogg', 50, 1, -1)
			R.cell.charge -= 666
		else
			user.visible_message("<span class='notice'>\The [user] [dogfluff ? "affectionately licks all over" : "shoves its reactor against"]  \the [target]'s face!</span>", "<span class='notice'>You [dogfluff ? "affectionately lick all over" : "shove your reactor against"] \the [target]'s face!</span>")
			if(dogfluff)
				playsound(src, 'sound/effects/attackblob.ogg', 50, 1)
			var/mob/living/carbon/human/H = target
			if(H.species.lightweight == 1)
				H.Stun(3) //RS Port Chomp PR 8154 || CHOMPEdit - Crawling made this useless. Changing to stun instead.
				H.drop_both_hands() //RS Port Chomp PR 8154 || Chopmedit - Stuns no longer drop items, so were forcing it >:3
	return

/obj/item/pupscrubber
	name = "floor scrubber"
	desc = "Toggles floor scrubbing."
	icon = 'icons/mob/dogborg_vr.dmi'
	icon_state = "scrub0"
	var/enabled = FALSE

/obj/item/pupscrubber/New()
	..()
	flags |= NOBLUDGEON

/obj/item/pupscrubber/attack_self(mob/user)
	var/mob/living/silicon/robot/R = user
	if(!enabled)
		R.scrubbing = TRUE
		enabled = TRUE
		icon_state = "scrub1"
	else
		R.scrubbing = FALSE
		enabled = FALSE
		icon_state = "scrub0"

/obj/item/weapon/gun/energy/taser/mounted/cyborg/ertgun //Not a taser, but it's being used as a base so it takes energy and actually works.
	name = "disabler"
	desc = "A small and nonlethal gun produced by NT.."
	icon = 'icons/mob/dogborg_vr.dmi'
	icon_state = "ertgunstun"
	fire_sound = 'sound/weapons/eLuger.ogg'
	projectile_type = /obj/item/projectile/beam/disable
	charge_cost = 240 //Normal cost of a taser. It used to be 1000, but after some testing it was found that it would sap a borg's battery to quick
	recharge_time = 10 //Takes ten ticks to recharge a shot, so don't waste them all!
	//cell_type = null //Same cell as a taser until edits are made.

/obj/item/device/lightreplacer/dogborg
	name = "light replacer"
	desc = "A device to automatically replace lights. This version is capable to produce a few replacements using your internal matter reserves."
	max_uses = 16
	uses = 10
	var/cooldown = 0
	var/datum/matter_synth/glass = null

/obj/item/device/lightreplacer/dogborg/attack_self(mob/user)//Recharger refill is so last season. Now we recycle without magic!

	var/choice = tgui_alert(user, "Do you wish to check the reserves or change the color?", "Selection List", list("Reserves", "Color"))
	if(choice == "Color")
		var/new_color = input(usr, "Choose a color to set the light to! (Default is [LIGHT_COLOR_INCANDESCENT_TUBE])", "", selected_color) as color|null
		if(new_color)
			selected_color = new_color
			to_chat(user, "<span class='filter_notice'>The light color has been changed.</span>")
		return
	else
		if(uses >= max_uses)
			to_chat(user, "<span class='warning'>[src.name] is full.</span>")
			return
		if(uses < max_uses && cooldown == 0)
			if(glass.energy < 125)
				to_chat(user, "<span class='warning'>Insufficient material reserves.</span>")
				return
			to_chat(user, "<span class='filter_notice'>It has [uses] lights remaining. Attempting to fabricate a replacement. Please stand still.</span>")
			cooldown = 1
			if(do_after(user, 50))
				glass.use_charge(125)
				add_uses(1)
				cooldown = 0
			else
				cooldown = 0
		else
			to_chat(user, "<span class='filter_notice'>It has [uses] lights remaining.</span>")
			return

//Pounce stuff for K-9
/obj/item/weapon/dogborg/pounce
	name = "\improper R.A.M. module"
	icon = 'icons/mob/dogborg_vr.dmi'
	icon_state = "notpounce"
	desc = "Leap at your target to momentarily stun them."
	force = 0
	throwforce = 0

/obj/item/weapon/dogborg/pounce/New()
	..()
	flags |= NOBLUDGEON

/obj/item/weapon/dogborg/pounce/attack_self(mob/user)
	var/mob/living/silicon/robot/R = user
	R.leap()

/mob/living/silicon/robot/proc/leap()
	if(last_special > world.time)
		to_chat(src, "<span class='filter_notice'>Your leap actuators are still recharging.</span>")
		return

	if(cell.charge < 1000)
		to_chat(src, "<span class='filter_notice'>Cell charge too low to continue.</span>")
		return

	if(usr.incapacitated(INCAPACITATION_DISABLED))
		to_chat(src, "<span class='filter_notice'>You cannot leap in your current state.</span>")
		return

	var/list/choices = list()
	for(var/mob/living/M in view(3,src))
		if(!istype(M,/mob/living/silicon))
			choices += M
	choices -= src

	var/mob/living/T = tgui_input_list(src,"Who do you wish to leap at?","Target Choice", choices)

	if(!T || !src || src.stat) return

	if(get_dist(get_turf(T), get_turf(src)) > 3) return

	if(last_special > world.time)
		return

	if(usr.incapacitated(INCAPACITATION_DISABLED))
		to_chat(src, "<span class='filter_notice'>You cannot leap in your current state.</span>")
		return

	last_special = world.time + 10
	status_flags |= LEAPING
	pixel_y = pixel_y + 10

	src.visible_message("<span class='danger'>\The [src] leaps at [T]!</span>")
	src.throw_at(get_step(get_turf(T),get_turf(src)), 4, 1, src)
	playsound(src, 'sound/mecha/mechstep2.ogg', 50, 1)
	pixel_y = default_pixel_y
	cell.charge -= 750

	sleep(5)

	if(status_flags & LEAPING) status_flags &= ~LEAPING

	if(!src.Adjacent(T))
		to_chat(src, "<span class='warning'>You miss!</span>")
		return

	if(ishuman(T))
		var/mob/living/carbon/human/H = T
		if(H.species.lightweight == 1)
			//H.Weaken(3)
			H.Stun(3) //RS Port Chomp PR 8047 || CHOMPEdit - Crawling made this useless. Changing to stun instead.
			H.drop_both_hands() //Chopmedit - Stuns no longer drop items, so were forcing it >:3
			return
	var/armor_block = run_armor_check(T, "melee")
	var/armor_soak = get_armor_soak(T, "melee")
	T.apply_damage(20, HALLOSS,, armor_block, armor_soak)
	if(prob(75)) //75% chance to stun for 5 seconds, really only going to be 4 bcus click cooldown+animation.
		//T.apply_effect(5, WEAKEN, armor_block) //RS Port Chomp PR 8047 || Chomp edit
		T.apply_effect(5, STUN, armor_block)
