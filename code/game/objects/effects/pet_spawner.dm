/obj/random/mob/semirandom_mob_spawner/pet
	mob_faction = "pet"
	overwrite_hostility = TRUE
	mob_hostile = FALSE
	mob_returns_home = FALSE
	possible_mob_types = list()

/obj/random/mob/semirandom_mob_spawner/pet/all_themes/Initialize()
	//rs redit start - remove leech
	possible_mob_types = list(
		theme_farm,
		theme_bird,
		theme_forest,
		theme_jungle,
		theme_domestic,
		theme_lizard,
		theme_sif - /mob/living/simple_mob/animal/sif/leech,
		theme_space
		)
	//rs edit end
	. = ..()

/obj/random/mob/semirandom_mob_spawner/pet/farm
	icon_state = "animal"
/obj/random/mob/semirandom_mob_spawner/pet/farm/Initialize()
	possible_mob_types = list(theme_farm)
	. = ..()

/obj/random/mob/semirandom_mob_spawner/pet/bird
	icon_state = "bird"
/obj/random/mob/semirandom_mob_spawner/pet/bird/Initialize()
	possible_mob_types = list(theme_bird)
	. = ..()

/obj/random/mob/semirandom_mob_spawner/pet/forest/Initialize()
	possible_mob_types = list(theme_forest)
	. = ..()

/obj/random/mob/semirandom_mob_spawner/pet/jungle/Initialize()
	possible_mob_types = list(theme_jungle)
	. = ..()

/obj/random/mob/semirandom_mob_spawner/pet/domestic
	icon_state = "animal"
/obj/random/mob/semirandom_mob_spawner/pet/domestic/Initialize()
	possible_mob_types = list(theme_domestic)
	. = ..()

/obj/random/mob/semirandom_mob_spawner/pet/lizard/Initialize()
	possible_mob_types = list(theme_lizard)
	. = ..()

/obj/random/mob/semirandom_mob_spawner/pet/sif/Initialize()
	possible_mob_types = list(theme_sif - /mob/living/simple_mob/animal/sif/leech) //rs edit - remove leech
	. = ..()

/obj/random/mob/semirandom_mob_spawner/pet/space/Initialize()
	possible_mob_types = list(theme_space)
	. = ..()
