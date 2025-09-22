// RS file

/obj/random/round_end_lasagna
	name = "round end lasagna"
	desc = "Lasagna at the CentCom cafe that everyone tries to get hands on."
	icon = 'icons/obj/food.dmi'
	icon_state = "lasagna"
	spawn_nothing_percentage = 0

/obj/random/round_end_lasagna/item_to_spawn()
	return pick(
			prob(90);/obj/item/weapon/reagent_containers/food/snacks/lasagna,
			prob(10);/obj/item/toy/plushie/lasagna
			)

/obj/effect/area_mob_spawner
	name = "area mob spawner"
	icon = 'icons/mob/randomlandmarks.dmi'
	icon_state = "monster"
	var/how_many_mobs_min = 1
	var/how_many_mobs_max = 10
	var/list/mobs_to_spawn = list()

/obj/effect/area_mob_spawner/Initialize()
	. = ..()
	return INITIALIZE_HINT_LATELOAD

/obj/effect/area_mob_spawner/LateInitialize()
	. = ..()
	if(mobs_to_spawn.len <= 0)
		var/turf/ourturf = get_turf(src)
		log_debug("[src] in [ourturf.loc] spawned with no mobs to spawn and so will be deleted.")
		qdel(src)
		return

	var/thismany = rand(how_many_mobs_min,how_many_mobs_max)

	while(thismany > 0)
		if(spawn_a_mob())
			thismany --
	qdel(src)

/obj/effect/area_mob_spawner/proc/spawn_a_mob()
	var/turf/ourturf = get_turf(src)
	var/ourtype = pickweight(mobs_to_spawn)
	var/turf/where = pick(ourturf.loc.contents)
	where = get_turf(where)
	if(where.check_density())
		return FALSE
	if(isspace(where) || isopenspace(where))
		return FALSE
	var/mob/living/L = new ourtype(where)
	if(!L)
		return FALSE
	return TRUE

/obj/effect/area_mob_spawner/sirius_point
	mobs_to_spawn = list(
		/mob/living/simple_mob/vore/prancer = 1,
		/mob/living/simple_mob/vore/stellagan = 50,
		/mob/living/simple_mob/vore/alienanimals/dustjumper = 20
	)

/obj/effect/area_mob_spawner/sirius_point/explo
	mobs_to_spawn = list(
		/mob/living/simple_mob/vore/prancer = 25,
		/mob/living/simple_mob/vore/stellagan = 50,
		/mob/living/simple_mob/vore/dust_stalker = 10,
		/mob/living/simple_mob/vore/alienanimals/dustjumper = 20
	)
