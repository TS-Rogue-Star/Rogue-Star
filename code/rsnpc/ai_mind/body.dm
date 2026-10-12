GLOBAL_LIST_EMPTY(npc_workers)

GLOBAL_LIST_INIT(npc_species, list(SPECIES_HUMAN, SPECIES_VULPKANIN, SPECIES_UNATHI, SPECIES_TESHARI, SPECIES_NEVREAN, SPECIES_SERGAL))

/mob/living/carbon/human/ai_controlled/station
	ai_holder_type = /datum/ai_holder/complex_npc
	a_intent = I_HELP
	key_access_restricted = FALSE
	to_wear_helmet = null
	to_wear_glasses = null
	to_wear_mask = null
	to_wear_l_radio = null
	to_wear_uniform = null
	to_wear_suit = null
	to_wear_gloves = null
	to_wear_shoes = null
	to_wear_belt = null
	to_wear_l_pocket = null
	to_wear_r_pocket = null
	to_wear_back = null
	to_wear_id_type = null
	to_wear_r_hand = null

/mob/living/carbon/human/ai_controlled/station/Initialize(mapload, job_title, species_name, gender, name, datum/npc_character/character)
	generate_species = (species_name in GLOB.npc_species) ? species_name : pick(GLOB.npc_species)
	. = ..()
	if(character)
		npc_body_from(character)
	else
		npc_random_generate(generate_species, gender, name)
	zone_sel = new /obj/screen/zone_sel(null)
	mind_initialize()
	if(character?.alt_title)
		mind.role_alt_title = character.alt_title
	GLOB.npc_workers += src
	job_master.EquipRank(src, pick_npc_job(character ? character.job : job_title), TRUE)
	allownpcvore = TRUE
	if(character)
		npc_vore_from(character)
	var/datum/ai_holder/complex_npc/ai_mind = npc_ai_mind(src)
	if(ai_mind)
		ai_mind.character = character
		ai_mind.start()

/mob/living/carbon/human/ai_controlled/station/Destroy()
	GLOB.npc_workers -= src
	if(mind?.current == src)
		mind.current = null
	if(mind?.original == src)
		mind.original = null
	return ..()

/mob/living/carbon/human/ai_controlled/station/Logout()
	. = ..()
	var/datum/ai_holder/complex_npc/ai_mind = npc_ai_mind(src)
	if(ai_mind && stat != DEAD)
		ai_mind.start_fast_processing()

/mob/living/carbon/human/ai_controlled/station/proc/npc_random_generate(species, gender, name)
	var/datum/preferences/P = new
	P.species = species
	P.randomize_appearance_and_body_for()
	var/datum/species/S = GLOB.all_species[species]
	if(gender in S.genders)
		P.set_biological_gender(gender)
	P.be_random_name = FALSE
	P.real_name = name || random_name(P.identifying_gender, species)
	P.copy_to(src)
	qdel(P)

/proc/pick_npc_job(job_title)
	if(SSjob.get_job(job_title))
		return job_title
	return pick(npc_jobs())

/proc/npc_jobs()
	. = list()
	for(var/datum/job/J as anything in SSjob.occupations)
		if(J.departments_managed || J.offmap_spawn || !(J.mob_type & JOB_CARBON))
			continue
		. += J.title
