//RS FILE
/mob/living/simple_mob/vore/scarybot
	name = "robot"
	tt_desc = "robot"
	faction = "robot"
	ai_holder_type = /datum/ai_holder/simple_mob/vore
	load_owner = "seriouslydontsavethis"	//they smort
	var/static/list/overlays_cache = list()

///// VORE RELATED /////
	vore_active = 1

	swallowTime = 2 SECONDS
	vore_capacity = 1
	vore_bump_chance = 25
	vore_bump_emote	= "greedily homms at"
	vore_digest_chance = 0
	vore_absorb_chance = 0
	vore_escape_chance = 10
	vore_pounce_chance = 50
	vore_ignores_undigestable = 0
	vore_default_mode = DM_SELECT
	vore_icons = SA_ICON_LIVING
	vore_stomach_name = "stomach"
	vore_stomach_flavor = "You have found yourself pumping on down, down, down into this extremely soft dog. The slick touches of pulsing walls roll over you in greedy fashion as you're swallowed away, the flesh forms to your figure as in an instant the world is replaced by the hot squeeze of canine gullet. And in another moment a heavy GLLRMMPTCH seals you away, the dog tossing its head eagerly, the way forward stretching to accommodate your shape as you are greedily guzzled down. The wrinkled, doughy walls pulse against you in time to the creature's steady heartbeat. The sounds of the outside world muffled into obscure tones as the wet, grumbling rolls of this soft creature's gut hold you, churning you tightly such that no part of you is spared from these gastric affections."
	vore_default_contamination_flavor = "Wet"
	vore_default_contamination_color = "grey"
	vore_default_item_mode = IM_DIGEST

/mob/living/simple_mob/vore/scarybot/Initialize()
	. = ..()
	glow_color = random_color()
	update_icon()

/mob/living/simple_mob/vore/scarybot/update_icon()
	. = ..()
	if(stat == DEAD)
		return
	var/image/glow = overlays_cache["glow[vore_fullness]"]
	if(!glow)
		glow = image(icon,null,"[icon_state]-l")
		glow.color = "#FFFFFF"
		glow.appearance_flags = RESET_COLOR|KEEP_APART|PIXEL_SCALE
		glow.plane = PLANE_LIGHTING_ABOVE

		overlays_cache["glow[vore_fullness]"] = glow
	add_overlay(glow)

	var/image/glow2 = overlays_cache["glow2[vore_fullness][glow_color]"]
	if(!glow2)
		glow2 = image(icon,null,"[icon_state]-l2")
		glow2.color = glow_color
		glow2.appearance_flags = RESET_COLOR|KEEP_APART|PIXEL_SCALE
		glow2.plane = PLANE_LIGHTING_ABOVE

		overlays_cache["glow2[vore_fullness][glow_color]"] = glow2
	add_overlay(glow2)


/mob/living/simple_mob/vore/scarybot/tall_bot
	desc = "Some kind of big tall robot"

	icon_state = "tall_robot"
	icon_living = "tall_robot"
	icon_dead = "tall_robot_dead"
//	icon_rest = "tall_robot_rest"
	icon = 'icons/rogue-star/mob_64x96.dmi'

	maxHealth = 300
	health = 300
	movement_cooldown = -1

	response_help = "pats"
	response_disarm = "rudely paps"
	response_harm = "punches"

	harm_intent_damage = 3
	melee_damage_lower = 10
	melee_damage_upper = 1
	catalogue_data = list()

	attacktext = list("nipped", "chomped", "slapped", "gnaws on")
	attack_sound = 'sound/voice/bork.ogg'
	friendly = list("snoofs", "nuzzles", "yips at", "smooshes on")

	mob_size = MOB_LARGE

	say_list_type = /datum/say_list/doglin

	has_hands = TRUE
	humanoid_hands = TRUE


	default_pixel_x = -16
	pixel_x = -16
