/mob/living/simple_mob/animal/space/goose
	name = "goose"
	desc = "It looks pretty angry!"
	tt_desc = "E Branta canadensis" //that iconstate is just a regular goose
	icon_state = "goose"
	icon_living = "goose"
	icon_dead = "goose_dead"

	faction = "geese"

	maxHealth = 30
	health = 30

	response_help = "pets the"
	response_disarm = "gently pushes aside the"
	response_harm = "hits the"

	harm_intent_damage = 5
	melee_damage_lower = 5 //they're meant to be annoying, not threatening.
	melee_damage_upper = 5 //unless there's like a dozen of them, then you're screwed.
	attacktext = list("pecked")
	attack_sound = 'sound/weapons/bite.ogg'

	organ_names = /decl/mob_organ_names/goose

	has_langs = list(LANGUAGE_ANIMAL)

	meat_type = /obj/item/weapon/reagent_containers/food/snacks/meat/chicken
	meat_amount = 3

/datum/say_list/goose
	speak = list("HONK!")
	emote_hear = list("honks loudly!")
	say_maybe_target = list("Honk?")
	say_got_target = list("HONK!!!")

/mob/living/simple_mob/animal/space/goose/handle_special()
	if((get_AI_stance() in list(STANCE_APPROACH, STANCE_FIGHT)) && !is_AI_busy() && isturf(loc))
		if(health <= (maxHealth * 0.5)) // At half health, and fighting someone currently.
			berserk()

/mob/living/simple_mob/animal/space/goose/verb/berserk()
	set name = "Berserk"
	set desc = "Enrage and become vastly stronger for a period of time, however you will be weaker afterwards."
	set category = "Abilities"

	add_modifier(/datum/modifier/berserk, 30 SECONDS)

/decl/mob_organ_names/goose
	hit_zones = list("head", "chest", "left leg", "right leg", "left wing", "right wing", "neck")

/mob/living/simple_mob/animal/space/goose/white
	icon = 'icons/mob/animal_vr.dmi'
	icon_state = "whitegoose"
	icon_living = "whitegoose"
	icon_dead = "whitegoose_dead"
	name = "white goose"
	desc = "And just when you thought it was a lovely day..."

//Rogue Star Add - Start

/mob/living/simple_mob/animal/space/goose/buff
	icon = 'icons/mob/64x64.dmi'
	icon_state = "buffgoose"
	icon_living = "buffgoose"
	icon_dead = "buffgoose_dead"
	name = "buff goose"
	desc = "It's big and very angry!"

	maxHealth = 250
	health = 250
	melee_damage_lower = 7
	melee_damage_upper = 7
	movement_cooldown = 1

	pixel_x = -16
	default_pixel_x = -16 //Centers hitbox of sprite.

/mob/living/simple_mob/animal/space/goose/elite
	icon = 'icons/mob/75x100.dmi'
	icon_state = "elitegoose"
	icon_living = "elitegoose"
	icon_dead = "elitegoose_dead"
	name = "elite goose"
	desc = "A seasoned and stylish soldier"

	maxHealth = 500
	health = 500
	melee_damage_lower = 10
	melee_damage_upper = 10
	movement_cooldown = 2

	pixel_x = -19
	default_pixel_x = -19 //Centers hitbox of sprite.

/mob/living/simple_mob/animal/space/goose/armored
	icon = 'icons/mob/100x100.dmi'
	icon_state = "armoredgoose"
	icon_living = "armoredgoose"
	icon_dead = "armoredgoose_dead"
	name = "armored goose"
	desc = "A fierce and feathered foe"

	maxHealth = 300
	health = 300
	melee_damage_lower = 30
	melee_damage_upper = 30
	attack_armor_pen = 30
	attack_sound = 'sound/weapons/taser.ogg'
	attacktext = list("pummeled")
	movement_cooldown = 3
	armor = list(melee = 40, bullet = 30, laser = 30, energy = 10, bomb = 10, bio = 100, rad = 100)

	pixel_x = -34
	pixel_y = -15
	old_x = -34
	vis_height = 80
	icon_expected_width = 100
	icon_expected_height = 100

/datum/say_list/goose/armored
	emote_hear = list("honks with authority.")
	emote_see = list("checks its radio","scans the area for threats")

/mob/living/simple_mob/animal/space/goose/armored/ranged
	icon_state = "armoredgoose_ranged"
	icon_living = "armoredgoose_ranged"
	icon_dead = "armoredgoose_ranged_dead"

	maxHealth = 250
	health = 250
	melee_damage_lower = 5
	melee_damage_upper = 5
	attack_sound = 'sound/weapons/bite.ogg'
	projectiletype = /obj/item/projectile/bullet/egg
	attacktext = list("shot")
	movement_cooldown = 3

/mob/living/simple_mob/animal/space/goose/armored/ranged/shoot_target(atom/A)
		flick("armoredgoose_ranged_fire", src)
		. = ..()

/mob/living/simple_mob/animal/space/goose/armored/grenadier
	icon_state = "armoredgoose_grenadier"
	icon_living = "armoredgoose_grenadier"
	icon_dead = "armoredgoose_grenadier_dead"
	desc = "A bad bird with bombs"

	maxHealth = 200
	health = 200
	melee_damage_lower = 5
	melee_damage_upper = 5
	attack_sound = 'sound/weapons/bite.ogg'
	movement_cooldown = 3

	var/grenade_type = /obj/item/weapon/grenade/chem_grenade/teargas
	special_attack_charges = 10
	special_attack_cooldown = 30 SECONDS
	special_attack_min_range = 2
	special_attack_max_range = 8

/mob/living/simple_mob/animal/space/goose/armored/grenadier/do_special_attack(atom/A)
	set waitfor = FALSE
	set_AI_busy(TRUE)

	var/obj/item/weapon/grenade/G = new grenade_type(get_turf(src))
	if(istype(G))
		G.throw_at(A, G.throw_range, G.throw_speed, src)
		G.attack_self(src)
		special_attack_charges = max(special_attack_charges-1, 0)

	set_AI_busy(FALSE)


/mob/living/simple_mob/animal/space/goose/armored/captain
	icon = 'icons/mob/100x100.dmi'
	icon_state = "armoredgoose_captain"
	icon_living = "armoredgoose_captain"
	icon_dead = "armoredgoose_captain_dead"
	name = "armored goose captain"
	desc = "A tough tactician"

	maxHealth = 200
	health = 200
	melee_damage_lower = 5
	melee_damage_upper = 5
	attack_armor_pen = 10
	attack_sound = 'sound/weapons/bite.ogg'

/mob/living/simple_mob/animal/space/goose/armored/captain/handle_special()
	for(var/mob/living/L in range(8, src))
		if(L == src)
			continue
		if(IIsAlly(L))
			L.add_modifier(/datum/modifier/aura/goose_captain_buff, null, src)

/datum/modifier/aura/goose_captain_buff
	name = "Morale Boost"
	on_created_text = "<span class='notice'>With your captain at your side, anything is possible.</span>"
	on_expired_text = "<span class='warning'>Sometimes you have to go it alone.</span>"
	stacks = MODIFIER_STACK_FORBID
	aura_max_distance = 8
	mob_overlay_state = "signal_blue"

	disable_duration_percent = 0.5
	attack_speed_percent = 0.75
	incoming_damage_percent	= 0.75
	evasion = 20
	accuracy = 10

/datum/modifier/aura/goose_captain_buff/tick()
	if(holder.stat == DEAD)
		expire()

//Rogue Star Add - End
