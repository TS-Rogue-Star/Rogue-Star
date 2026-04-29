///////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star April 2026: New magic staff that summons lightning strikes //
///////////////////////////////////////////////////////////////////////////////////////////////

#define STORM_STAFF_LIGHTNING_RANGE 1
#define STORM_STAFF_LIGHTNING_POWER 20000
#define STORM_STAFF_JITTER_STEPS 24
#define STORM_STAFF_JITTER_PIXEL_X_RANGE 6
#define STORM_STAFF_JITTER_PIXEL_Y_RANGE 2

/obj/item/weapon/gun/magic/stormstaff
	name = "staff of storms"
	desc = "A long staff crackling with restrained stormlight."
	icon = 'icons/obj/wizard.dmi'
	icon_state = "staffofstorms"
	item_state = "staff"
	fire_sound = 'sound/weapons/emitter.ogg'
	fire_sound_text = "thunderclap"
	w_class = ITEMSIZE_HUGE
	checks_antimagic = TRUE
	max_charges = 6
	charges = 0
	recharge_rate = 4
	charge_tick = 0
	can_charge = TRUE

	projectile_type = null

/obj/item/weapon/gun/magic/stormstaff/proc/consume_storm_charge(mob/living/user)
	if(checks_antimagic && locate(/obj/item/weapon/nullrod) in user)
		return FALSE
	if(charges <= 0)
		return FALSE

	charges -= 1
	return TRUE

/obj/item/weapon/gun/magic/stormstaff/proc/stormstaff_jitter_animation(atom/movable/target)
	var/base_pixel_x = target.pixel_x
	var/base_pixel_y = target.pixel_y

	for(var/i in 1 to STORM_STAFF_JITTER_STEPS)
		var/jitter_pixel_x = base_pixel_x + rand(-STORM_STAFF_JITTER_PIXEL_X_RANGE, STORM_STAFF_JITTER_PIXEL_X_RANGE)
		var/jitter_pixel_y = base_pixel_y + rand(-STORM_STAFF_JITTER_PIXEL_Y_RANGE, STORM_STAFF_JITTER_PIXEL_Y_RANGE)
		if(i == 1)
			animate(target, pixel_x = jitter_pixel_x, pixel_y = jitter_pixel_y, time = 1)
		else
			animate(pixel_x = jitter_pixel_x, pixel_y = jitter_pixel_y, time = 1)
	animate(pixel_x = base_pixel_x, pixel_y = base_pixel_y, time = 1)

/obj/item/weapon/gun/magic/stormstaff/proc/stormstaff_lightning_act(mob/living/L)
	stormstaff_jitter_animation(L)
	to_chat(L, span("critical", "You've been struck by lightning!"))

/obj/item/weapon/gun/magic/stormstaff/proc/stormstaff_lightning_strike(turf/T)
	var/datum/planet/P = LAZYACCESS(SSplanets.z_to_planet, T.z)
	if(P)
		var/datum/weather_holder/holder = P.weather_holder
		flick("lightning_flash", holder.special_visuals)

	new /obj/effect/temporary_effect/lightning_strike(T)
	playsound(T, 'sound/effects/lightningbolt.ogg', 100, 1)

	var/sound = get_sfx("thunder")
	for(var/mob/M in player_list)
		if((P && (M.z in P.expected_z_levels)) || M.z == T.z)
			if(M.is_preference_enabled(/datum/client_preference/weather_sounds))
				M.playsound_local(get_turf(M), soundin = sound, vol = 70, vary = FALSE, is_global = TRUE)

	for(var/atom/movable/AM in range(STORM_STAFF_LIGHTNING_RANGE, T))
		if(isliving(AM))
			var/mob/living/L = AM
			if(L.is_incorporeal() || L.stat == DEAD || (L.status_flags & GODMODE))
				continue

			var/shock_damage = CLAMP(round(STORM_STAFF_LIGHTNING_POWER / 400), 10, 90) + rand(-5, 5)
			L.electrocute_act(shock_damage, src, 1 - L.get_shock_protection(), ran_zone(), 0)
			stormstaff_lightning_act(L)
		else
			AM.emp_act(1)

/obj/item/weapon/gun/magic/stormstaff/afterattack(atom/A, mob/living/user, adjacent, params)
	if(!user || !A)
		return
	if(adjacent && !isturf(A))
		return

	if(!user.aiming)
		user.aiming = new(user)

	if(user.client && user.aiming && user.aiming.active && user.aiming.aiming_at != A)
		PreFire(A, user, params)
		return

	if(user.a_intent == I_HELP && user.is_preference_enabled(/datum/client_preference/safefiring))
		to_chat(user, "<span class='warning'>You refrain from calling down lightning with your [src] as your intent is set to help.</span>")
		return

	Fire(A, user, params)

/obj/item/weapon/gun/magic/stormstaff/Fire(atom/target, mob/living/user, clickparams, pointblank=0, reflex=0)
	if(!user || !target)
		return

	var/turf/target_turf = get_turf(target)
	if(!target_turf || target_turf.z != user.z)
		return

	add_fingerprint(user)

	user.break_cloak()

	if(!special_check(user))
		return

	if(world.time < next_fire_time)
		if(world.time % 3)
			to_chat(user, "<span class='warning'>[src] is not ready to call another storm!</span>")
		return

	if(!consume_storm_charge(user))
		handle_click_empty(user)
		user.setClickCooldown(DEFAULT_QUICK_COOLDOWN)
		user.setMoveCooldown(move_delay)
		next_fire_time = world.time + fire_delay
		return

	user.setClickCooldown(DEFAULT_QUICK_COOLDOWN)
	user.setMoveCooldown(move_delay)
	next_fire_time = world.time + fire_delay
	SEND_SIGNAL(user, COMSIG_MOB_FIRED_GUN)

	handle_firing_text(user, target_turf, pointblank, reflex)
	play_fire_sound(user)
	stormstaff_lightning_strike(target_turf)

	last_shot = world.time
	update_icon()
	user.hud_used.update_ammo_hud(user, src)

#undef STORM_STAFF_LIGHTNING_RANGE
#undef STORM_STAFF_LIGHTNING_POWER
#undef STORM_STAFF_JITTER_STEPS
#undef STORM_STAFF_JITTER_PIXEL_X_RANGE
#undef STORM_STAFF_JITTER_PIXEL_Y_RANGE
