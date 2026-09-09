//RS FILE
/mob/living/simple_mob/holomob
	name = "hologram"
	desc = "A weird hologram!"
	icon = 'icons/rogue-star/holomob.dmi'
	icon_state = "cube"
	icon_living = "cube"
	icon_dead = "ded"

	faction = "hologram"
	plane = PLANE_LIGHTING_ABOVE
	layer = ABOVE_MOB_LAYER
	maxHealth = 200
	health = 200
	movement_cooldown = 0

	response_help = "pets"
	response_disarm = "slaps"
	response_harm = "punches"

	melee_damage_lower = 2
	melee_damage_upper = 10
	attack_sound = 'sound/rogue-star/bwom b.ogg'

	min_oxy = 0
	max_oxy = 999999
	min_tox = 0
	max_tox = 999999
	min_co2 = 0
	max_co2 = 999999
	min_n2 = 0
	max_n2 = 999999
	minbodytemp = 0
	maxbodytemp = 999999
	unsuitable_atoms_damage = 0

	load_owner = "seriouslydontsavethis"

	ai_ignores = TRUE

	ai_holder_type = /datum/ai_holder/holomob
	low_priority = FALSE
	var/safety = TRUE
	var/halloss_mult = 1
	var/mob/living/simple_mob/holomob/healer/being_healed_by

/mob/living/simple_mob/holomob/death(gibbed,deathmessage="fades away...")
	being_healed_by?.clear_healing_reservation(src)
	. = ..()
	var/obj/item/hologram_projector/HP = new(loc,src)
	forceMove(HP)
	HP.visible_message(SPAN_WARNING("\The [HP] clatters to the ground..."),runemessage = "clatter. . .")
	playsound(HP, 'sound/items/drop/ring.ogg', 50, 1)

/mob/living/simple_mob/holomob/apply_attack(atom/A, damage_to_do)
	if(!safety)
		return ..()

	if(!isliving(A))
		return

	var/mob/living/L = A

	L.apply_hologram_damage(damage_to_do * halloss_mult)

	add_attack_logs(src,L,"HOLOGRAM ATTACK",admin_notify = FALSE)
	src.visible_message("<span class='danger'>\The [src] attacks \the [L]!</span>")
	src.do_attack_animation(L)
	if(attack_sound)
		playsound(src, attack_sound, 75, 1)
	if(ishuman(L))
		var/mob/living/carbon/human/H = L
		if(H.can_feel_pain())
			if(H.stat != CONSCIOUS)
				voidout(H)
				return
	if(L.halloss >= L.health)
		voidout(L)

/mob/living/simple_mob/holomob/Life()
	. = ..()
	if(!. || stat >= DEAD)
		return

	ask_for_healing()

/mob/living/simple_mob/holomob/proc/voidout(var/mob/living/L)
	if(!isliving(L))
		return FALSE
	L.add_modifier(/datum/modifier/off_limits,15 SECONDS)
	L.sleeping = 3
	for(var/mob/living/simple_mob/holomob/HM in view(world.view,get_turf(L)))
		if(HM.ai_holder)
			if(HM.ai_holder.target == L)
				HM.ai_holder?.remove_target()
	var/list/potential_targets = list()
	for(var/obj/effect/landmark/safepoint/safe in world)
		potential_targets += safe
	if(potential_targets.len <= 0)
		return FALSE
	var/turf/T = get_turf(pick(potential_targets))
	L.visible_message(SPAN_WARNING("\The [L] disappears suddenly!!!"),SPAN_NOTICE("Everything fades away as you pass out..."),runemessage = "zap. . .")
	L.halloss = 0
	L.forceMove(T)
	if(ishuman(L))
		var/mob/living/carbon/human/H = L
		H.updateshock()

	return TRUE

/mob/living/simple_mob/holomob/proc/restore()
	cut_overlays()
	var/turf/T = get_turf(src)

	if(!turfcheck())
		return FALSE
	bruteloss = 0
	fireloss = 0
	toxloss = 0
	oxyloss = 0
	cloneloss = 0
	brainloss = 0
	halloss = 0
	weakened = 0
	stunned = 0
	sleeping = 0
	nutrition = 500
	absorbed = FALSE
	resting = FALSE
	health = maxHealth
	stat = CONSCIOUS
	if(ai_holder)
		ai_holder.set_stance(STANCE_IDLE)
		ai_holder.busy = FALSE
	update_icon()

	forceMove(T)

	return TRUE

/mob/living/simple_mob/holomob/proc/turfcheck()	//This should probably check for some kind of special turf or something for holograms to live on
	return TRUE

/mob/living/simple_mob/holomob/proc/needs_healing()
	return stat < DEAD && health <= maxHealth - (maxHealth/4)

/mob/living/simple_mob/holomob/proc/ask_for_healing()
	if(being_healed_by)
		var/mob/living/simple_mob/holomob/healer/current_healer = being_healed_by
		if(QDELETED(current_healer))
			being_healed_by = null
			ai_holder?.set_busy(FALSE)
		else if(current_healer.stat >= DEAD || current_healer.healing_target != src)
			current_healer.clear_healing_reservation(src)
			being_healed_by = null
			ai_holder?.set_busy(FALSE)
		else if(!current_healer.can_process_healing_reservation())
			current_healer.clear_healing_reservation(src)
	if(!needs_healing())
		being_healed_by?.clear_healing_reservation(src)
		return
	for(var/mob/living/simple_mob/holomob/healer/H in view(world.view,get_turf(src)))
		if(H == src)
			continue
		if(!H.ai_holder)
			continue
		if(H.please_heal(src))
			return

/mob/living/proc/apply_hologram_damage(var/damage)

	if(!damage)
		return

	var/dam_zone
	var/obj/item/organ/external/affecting
	if(organs_by_name)
		dam_zone = pick(organs_by_name)
		affecting = get_organ(ran_zone(dam_zone))
	var/armor_block = run_armor_check(affecting, "melee", 0)
	var/armor_soak = get_armor_soak(affecting, "melee", 0)

	apply_damage(damage, HALLOSS, affecting, armor_block, armor_soak, sharp = 0, edge = 0)
	updatehealth()
	return TRUE

//SUBTYPE
/mob/living/simple_mob/holomob/tri
	icon_state = "tri"
	icon_living = "tri"
/mob/living/simple_mob/holomob/itri
	icon_state = "itri"
	icon_living = "itri"

/mob/living/simple_mob/holomob/light
	icon_state = "fish"
	icon_living = "fish"
	movement_cooldown = -2
	halloss_mult = 0.75
	maxHealth = 25

/mob/living/simple_mob/holomob/light/hyper
	icon_state = "critter"
	icon_living = "critter"
	movement_cooldown = -3
	special_attack_cooldown = 5 SECOND
	special_attack_min_range = 2
	special_attack_max_range = 7

/mob/living/simple_mob/holomob/light/hyper/do_special_attack(atom/A)
	if(!A)
		return
	throw_at(A,7,10)
	playsound(src, 'sound/effects/houndstep.ogg', 50, 1)

/mob/living/simple_mob/holomob/heavy
	icon_state = "fella"
	icon_living = "fella"
	movement_cooldown = 1
	halloss_mult = 2
	maxHealth = 500

/mob/living/simple_mob/holomob/sprint
	icon_state = "crawler"
	icon_living = "crawler"
	movement_cooldown = -1
	halloss_mult = 1
	maxHealth = 100

/mob/living/simple_mob/holomob/horrible
	icon_state = "hand"
	icon_living = "hand"
	movement_cooldown = 15
	halloss_mult = 200
	maxHealth = 200000

/mob/living/simple_mob/holomob/ranged
	icon_state = "orb"
	icon_living = "orb"
	projectiletype = /obj/item/projectile/holobeam
	projectile_accuracy = -10
	projectile_dispersion = 5
	needs_reload = TRUE
	reload_max = 3
	reload_time = 4 SECONDS
	reload_sound = 'sound/weapons/flipblade.ogg'

/mob/living/simple_mob/holomob/healer
	icon_state = "bird"
	icon_living = "bird"
	maxHealth = 75
	movement_cooldown = -1
	ai_holder_type = /datum/ai_holder/holomob/healer
	special_attack_cooldown = 6 SECONDS
	halloss_mult = 0.25
	special_attack_min_range = 1
	special_attack_max_range = 7
	var/heal_amount = 100
	var/mob/living/simple_mob/holomob/healing_target
	var/healing_target_busy = FALSE

/mob/living/simple_mob/holomob/healer/proc/can_process_healing_reservation()
	return ai_holder && stat < DEAD && (!key || ai_holder.autopilot)

/mob/living/simple_mob/holomob/healer/proc/clear_healing_reservation(var/mob/living/simple_mob/holomob/holo_target)
	if(!holo_target)
		holo_target = healing_target
	if(holo_target && !QDELETED(holo_target))
		if(holo_target.being_healed_by == src)
			holo_target.being_healed_by = null
		if(healing_target_busy && healing_target == holo_target)
			holo_target.ai_holder?.set_busy(FALSE)
	if(healing_target == holo_target)
		healing_target = null
	healing_target_busy = FALSE
	if(!healing_target && can_process_healing_reservation())
		ai_holder?.sync_processing_to_stance()

/mob/living/simple_mob/holomob/healer/should_special_attack(atom/A)
	if(!isliving(A))
		return FALSE
	var/mob/living/L = A
	if(L.stat >= DEAD)
		return FALSE
	if(healing_target && healing_target != A)
		return FALSE
	if(L.faction != faction)
		return FALSE
	var/mob/living/simple_mob/holomob/holo_target
	if(istype(L, /mob/living/simple_mob/holomob))
		holo_target = L
	if(holo_target)
		if(!holo_target.needs_healing())
			return FALSE
	else if(L.health > L.maxHealth - (L.maxHealth/4))
		return FALSE
	if(holo_target?.being_healed_by && holo_target.being_healed_by != src)
		return FALSE
	var/datum/ai_holder/target_ai = L.ai_holder
	if(target_ai?.busy && (!holo_target || holo_target.being_healed_by != src))
		return FALSE
	return TRUE

/mob/living/simple_mob/holomob/healer/do_special_attack(atom/A)
	set waitfor = FALSE

	if(!isliving(A))
		return
	var/mob/living/L = A
	var/mob/living/simple_mob/holomob/holo_target
	if(istype(L, /mob/living/simple_mob/holomob))
		holo_target = L
	if(L.stat >= DEAD)
		clear_healing_reservation(holo_target)
		return
	if(healing_target && healing_target != holo_target)
		clear_healing_reservation()
		return
	if(holo_target?.being_healed_by && holo_target.being_healed_by != src)
		clear_healing_reservation(holo_target)
		return
	var/datum/ai_holder/target_ai = L.ai_holder
	if(target_ai?.busy && (!holo_target || holo_target.being_healed_by != src))
		clear_healing_reservation(holo_target)
		return
	var/turf/target_turf = get_turf(L)
	if(target_turf)
		target_turf.visible_message(SPAN_WARNING("\The [L] calls for help!"),runemessage = "!!!!!")
	var/turf/source_turf = get_turf(src)
	if(source_turf)
		source_turf.visible_message(SPAN_DANGER("\The [src] begins focusing..."),runemessage = ". . .")
	if(holo_target)
		holo_target.being_healed_by = src
		healing_target = holo_target
		healing_target_busy = TRUE
	target_ai?.set_busy(TRUE)
	ai_holder?.set_busy(TRUE)
	if(!do_after(src,3 SECONDS,A,progress = TRUE))
		ai_holder?.set_busy(FALSE)
		target_ai?.set_busy(FALSE)
		clear_healing_reservation(holo_target)
		return
	ai_holder?.set_busy(FALSE)
	target_ai?.set_busy(FALSE)
	if(QDELETED(L) || L.stat >= DEAD)
		clear_healing_reservation(holo_target)
		return
	clear_healing_reservation(holo_target)
	source_turf = get_turf(src)
	if(source_turf)
		source_turf.visible_message(SPAN_DANGER("\The [src] heals its friend!!!"),runemessage = "! ! !")

	var/healing_bank = heal_amount
	if(L.bruteloss)
		if(L.bruteloss <= healing_bank)
			healing_bank -= L.bruteloss
			L.adjustBruteLoss(-L.bruteloss)
		else
			L.adjustBruteLoss(-healing_bank)
			return
	if(L.fireloss)
		if(L.fireloss <= healing_bank)
			healing_bank -= L.fireloss
			L.adjustFireLoss(-L.fireloss)
		else
			L.adjustFireLoss(-healing_bank)
			return
	if(L.toxloss)
		if(L.toxloss <= healing_bank)
			healing_bank -= L.toxloss
			L.adjustToxLoss(-L.toxloss)
		else
			L.adjustToxLoss(-healing_bank)
			return
	if(L.oxyloss)
		if(L.oxyloss <= healing_bank)
			healing_bank -= L.oxyloss
			L.adjustOxyLoss(-L.oxyloss)
		else
			L.adjustOxyLoss(-healing_bank)
			return
	if(L.cloneloss)
		if(L.cloneloss <= healing_bank)
			healing_bank -= L.cloneloss
			L.adjustCloneLoss(-L.cloneloss)
		else
			L.adjustCloneLoss(-healing_bank)
			return

/mob/living/simple_mob/holomob/healer/proc/please_heal(var/mob/living/L)
	if(!isliving(L))
		return FALSE
	if(L.stat >= DEAD)
		return FALSE
	if(!can_process_healing_reservation())
		return FALSE
	var/mob/living/simple_mob/holomob/holo_target
	if(istype(L, /mob/living/simple_mob/holomob))
		holo_target = L
	if(holo_target && !holo_target.needs_healing())
		return FALSE
	if(healing_target)
		return healing_target == holo_target
	if(ai_holder.busy)
		return FALSE
	if(holo_target?.being_healed_by)
		return FALSE
	if(!ICheckSpecialAttack(L))
		return FALSE
	if(holo_target)
		holo_target.being_healed_by = src
		healing_target = holo_target
		ai_holder.start_fast_processing()
	return TRUE

/mob/living/simple_mob/holomob/healer/can_special_attack(atom/A)
	. = ..()
//AI
/datum/ai_holder/holomob
	hostile = TRUE
	cooperative = FALSE
	returns_home = FALSE
	can_flee = FALSE
	speak_chance = 0
	wander = FALSE

/datum/ai_holder/holomob/can_attack(atom/movable/the_target, vision_required)
	if(isliving(the_target))
		var/mob/living/L = the_target
		if(L.has_modifier_of_type(/datum/modifier/off_limits))
			return FALSE
	return ..()

/datum/ai_holder/holomob/healer/can_attack(atom/movable/the_target, vision_required)
	if(isliving(the_target))
		var/mob/living/L = the_target
		if(L.faction == holder.faction)
			return FALSE
	return ..()

/datum/ai_holder/holomob/healer/handle_special_tactic()
	var/mob/living/simple_mob/holomob/healer/H = holder
	if(!H?.healing_target)
		return
	if(busy)
		if(!H.healing_target_busy)
			H.clear_healing_reservation()
		return
	if(!H.ICheckSpecialAttack(H.healing_target))
		H.clear_healing_reservation()
		return
	var/mob/living/simple_mob/holomob/heal_target = H.healing_target
	H.special_attack_target(heal_target)
	if(H.healing_target == heal_target && !H.healing_target_busy)
		H.clear_healing_reservation(heal_target)

/datum/ai_holder/holomob/healer/handle_stance_tactical()
	var/mob/living/simple_mob/holomob/healer/H = holder
	if(H?.healing_target)
		return
	return ..()
/*
/datum/ai_holder/holomob/healer/pre_special_attack(atom/A)
	busy = TRUE

/datum/ai_holder/holomob/healer/post_special_attack(atom/A)
	busy = FALSE
*/
//PROJECTOR OBJECT
/obj/item/hologram_projector
	name = "hologram projector"
	desc = "A little puck with emitters all over it! If you activate this, a hologram will appear."
	icon = 'icons/rogue-star/holomob.dmi'
	icon_state = "projector"
	persist_storable = FALSE
	randpixel = 8
	w_class = ITEMSIZE_TINY

	var/mob/living/simple_mob/holomob/stored_hologram

/obj/item/hologram_projector/New(loc,var/mob/living/simple_mob/holomob/HM)
	. = ..()
	if(HM)
		stored_hologram = HM

/obj/item/hologram_projector/attack_self(mob/user)
	restore_hologram()

/obj/item/hologram_projector/proc/restore_hologram()
	if(!stored_hologram)
		to_chat(usr,SPAN_DANGER("\The [src] doesn't seem to have a hologram program loaded."))
		return
	if(!stored_hologram.restore())
		return
	if(isliving(loc))
		var/mob/living/L = loc
		L.drop_from_inventory(src)
	var/turf/T = get_turf(src)
	playsound(T, 'sound/effects/whistle.ogg', 100, 1)
	qdel(src)

/obj/effect/landmark/safepoint
	icon = 'icons/rogue-star/holomob.dmi'
	icon_state = "bird"

/datum/modifier/off_limits
	name = "off limits"
	desc = "Holograms will ignore you for a while"

/obj/item/projectile/holobeam
	name = "hologram missile"
	icon_state = "force_missile"
	fire_sound = 'sound/rogue-star/bwom.ogg'
	damage = 15
	damage_type = HALLOSS
	check_armour = "melee"

	impact_effect_type = /obj/effect/temp_visual/impact_effect/blue_laser
	hitsound_wall = 'sound/rogue-star/bwom b.ogg'

/obj/item/projectile/holobeam/Bump(atom/A)
	if(isliving(A))
		var/mob/living/L = A
		if(L.faction == firer.faction)
			var/turf/target_turf = get_turf(L)
			trajectory_ignore_forcemove = TRUE
			forceMove(target_turf)
			permutated.Add(A)
			trajectory_ignore_forcemove = FALSE
			return FALSE
	return ..()

/obj/item/projectile/holobeam/on_impact(atom/A)
	. = ..()
	if(!isliving(A))
		return
	var/mob/living/L = A

	if(!istype(firer,/mob/living/simple_mob/holomob))
		return
	var/mob/living/simple_mob/holomob/HM = firer
	if(ishuman(L))
		var/mob/living/carbon/human/H = L
		if(H.can_feel_pain())
			if(H.stat != CONSCIOUS)
				HM.voidout(H)
				return
	if(L.halloss >= L.health)
		HM.voidout(L)
