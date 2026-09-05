////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star September 2025: New system for allowing players to create custom markings ////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star November 2025: Refactor moving most of the work to TGUI and adding new options to overlay and replace parts //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star November 2025: Updated to support 64x64 markings /////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star December 2025: Updated to support loaout and job gear ////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star December 2025: New body marking selection tab added //////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star December 2025: New basic appearence tab added ////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star August 2026: Character Designer - Species and Prosthetics ////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star August 2026: Character Designer - Traits Tab /////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#define CUSTOM_MARKING_DEFAULT_WIDTH 32
#define CUSTOM_MARKING_DEFAULT_HEIGHT 32

#ifndef CUSTOM_MARKING_CANVAS_MAX_WIDTH
#define CUSTOM_MARKING_CANVAS_MAX_WIDTH 64
#endif
#ifndef CUSTOM_MARKING_CANVAS_MAX_HEIGHT
#define CUSTOM_MARKING_CANVAS_MAX_HEIGHT 64
#endif

#define BODY_MARKING_CHUNK_PENDING -7
#define BODY_MARKING_SELECTION_LIMIT 40

#ifndef CUSTOM_MARKING_CHECK_TICK
#define CUSTOM_MARKING_CHECK_TICK custom_marking_yield_heartbeat(FALSE)
#define CUSTOM_MARKING_CHECK_TICK_DEFINED_IN_DESIGNER
#endif

// Shared cache for the global body marking definitions payload (Lira, December 2025)
var/global/list/custom_marking_body_definition_cache = null

// Shared cache for the global basic appearance definitions payload (Lira, December 2025)
var/global/list/custom_marking_basic_appearance_definition_cache = null

// Shared cache for canvas background payloads (Lira, December 2025)
var/global/list/custom_marking_canvas_background_cache = null

// Shared cache for icon visibility checks (Lira, December 2025)
var/global/list/custom_marking_visible_pixel_cache = null

var/global/list/custom_marking_species_body_preview_cache = null

var/global/list/custom_marking_species_catalog_cache = null

var/global/list/custom_marking_species_icon_base_option_cache = null

var/global/custom_marking_prosthetic_preview_cache_complete = FALSE

var/global/custom_marking_gear_preview_cache_complete = FALSE

var/global/list/custom_marking_static_source_digest_cache = list()
var/global/custom_marking_static_source_digest_complete = TRUE

/proc/custom_marking_static_source_digest(icon_source)
	if(!icon_source)
		custom_marking_static_source_digest_complete = FALSE
		return null
	var/source_key = "[icon_source]"
	if(source_key in custom_marking_static_source_digest_cache)
		return custom_marking_static_source_digest_cache[source_key]
	var/source_file = fcopy_rsc(icon_source)
	var/source_digest = isfile(source_file) ? md5(source_file) : null
	if(!istext(source_digest) || length(source_digest) != 32)
		custom_marking_static_source_digest_complete = FALSE
		source_digest = "unhashed-[md5(source_key)]"
	custom_marking_static_source_digest_cache[source_key] = source_digest
	return source_digest

// Helper used to build the cache (Lira, December 2025)
/datum/tgui_module/custom_marking_designer/cache_builder/New()
	prefs = new /datum/preferences
	state_session_token = "cache"
	reference_asset_token_counter = 0
	icon_shift_map = list()
	use_shared_atlas = TRUE
	return

// Helper used to build the basic appearance cache (Lira, December 2025)
/datum/tgui_module/custom_marking_designer/basic_appearance_cache_builder/New()
	prefs = new /datum/preferences
	state_session_token = "cache-basic-appearance"
	reference_asset_token_counter = 0
	icon_shift_map = list()
	use_shared_atlas = TRUE
	return

// Helper used to build canvas background cache (Lira, December 2025)
/datum/tgui_module/custom_marking_designer/background_cache_builder/New()
	state_session_token = "cache-background"
	reference_asset_token_counter = 0
	icon_shift_map = list()
	use_shared_atlas = FALSE
	return

/datum/tgui_module/custom_marking_designer/species_preview_cache_builder/New()
	state_session_token = "cache-species-body"
	reference_asset_token_counter = 0
	icon_shift_map = list()
	use_shared_atlas = TRUE
	return

/datum/tgui_module/custom_marking_designer/gear_cache_builder/New()
	state_session_token = "cache-gear"
	reference_asset_token_counter = 0
	icon_shift_map = list()
	use_shared_atlas = TRUE
	return

/mob/living/carbon/human/dummy/mannequin/custom_marking_visual
	appearance_only = TRUE

/mob/living/carbon/human/dummy/mannequin/custom_marking_gear
	appearance_only = TRUE

/mob/living/carbon/human/dummy/mannequin/custom_marking_gear/update_icons_body()
	return

/mob/living/carbon/human/dummy/mannequin/custom_marking_gear/update_hair()
	return

/mob/living/carbon/human/dummy/mannequin/custom_marking_gear/update_tail_showing()
	return

/mob/living/carbon/human/dummy/mannequin/custom_marking_gear/update_wing_showing()
	return

/mob/living/carbon/human/dummy/mannequin/custom_marking_gear/update_vore_belly_sprite()
	return

/datum/tgui_module/custom_marking_designer/species_catalog_cache_builder/New()
	state_session_token = "cache-species-catalog"
	reference_asset_token_counter = 0
	icon_shift_map = list()
	use_shared_atlas = TRUE
	return

// Build body marking definition cache (Lira, December 2025)
/proc/build_body_marking_definition_cache()
	if(islist(custom_marking_body_definition_cache))
		return custom_marking_body_definition_cache
	if(!islist(body_marking_styles_list) || !body_marking_styles_list.len)
		return null
	var/datum/tgui_module/custom_marking_designer/cache_builder/helper = new
	custom_marking_body_definition_cache = helper.build_body_marking_definitions(TRUE)
	return custom_marking_body_definition_cache

// Build basic appearance definition cache (Lira, December 2025)
/proc/build_basic_appearance_definition_cache()
	if(islist(custom_marking_basic_appearance_definition_cache))
		return custom_marking_basic_appearance_definition_cache
	if(!islist(hair_styles_list) || !hair_styles_list.len)
		return null
	if(!islist(facial_hair_styles_list) || !facial_hair_styles_list.len)
		return null
	var/list/yield_context = custom_marking_begin_manual_yield()
	var/datum/tgui_module/custom_marking_designer/basic_appearance_cache_builder/helper = new
	custom_marking_basic_appearance_definition_cache = helper.build_basic_appearance_definitions()
	custom_marking_end_manual_yield(yield_context)
	return custom_marking_basic_appearance_definition_cache

// Build canvas background cache (Lira, December 2025)
/proc/build_custom_marking_canvas_background_cache()
	if(islist(custom_marking_canvas_background_cache))
		return custom_marking_canvas_background_cache
	var/datum/tgui_module/custom_marking_designer/background_cache_builder/helper = new
	custom_marking_canvas_background_cache = helper.build_canvas_background_options_internal()
	return custom_marking_canvas_background_cache

/proc/build_custom_marking_species_body_preview_cache()
	if(islist(custom_marking_species_body_preview_cache) && custom_marking_species_body_preview_cache.len)
		return custom_marking_species_body_preview_cache
	if(!islist(GLOB.all_species) || !GLOB.all_species.len)
		return null
	if(!islist(GLOB.playable_species) || !GLOB.playable_species.len)
		return null
	var/list/yield_context = custom_marking_begin_manual_yield()
	var/datum/tgui_module/custom_marking_designer/species_preview_cache_builder/helper = new
	helper.build_species_body_preview_cache()
	custom_marking_end_manual_yield(yield_context)
	return custom_marking_species_body_preview_cache

/proc/build_custom_marking_prosthetic_preview_cache()
	if(custom_marking_prosthetic_preview_cache_complete)
		return TRUE
	if(!islist(chargen_robolimbs) || !chargen_robolimbs.len)
		return null
	if(!islist(GLOB.all_species) || !GLOB.all_species.len)
		return null
	var/list/yield_context = custom_marking_begin_manual_yield()
	var/datum/tgui_module/custom_marking_designer/species_preview_cache_builder/helper = new
	var/succeeded = helper.prewarm_static_prosthetic_preview_assets()
	custom_marking_end_manual_yield(yield_context)
	if(succeeded)
		custom_marking_prosthetic_preview_cache_complete = TRUE
	return succeeded

/proc/build_custom_marking_gear_preview_cache()
	if(custom_marking_gear_preview_cache_complete)
		return TRUE
	if(!islist(GLOB.all_species) || !GLOB.all_species.len)
		return null
	if(!islist(tail_styles_list) || !tail_styles_list.len)
		return null
	var/list/yield_context = custom_marking_begin_manual_yield()
	var/datum/tgui_module/custom_marking_designer/gear_cache_builder/helper = new
	var/succeeded = helper.prewarm_static_gear_preview_assets()
	custom_marking_end_manual_yield(yield_context)
	if(succeeded)
		custom_marking_gear_preview_cache_complete = TRUE
	return succeeded

/proc/build_custom_marking_species_catalog_cache()
	if(islist(custom_marking_species_catalog_cache) && custom_marking_species_catalog_cache.len && islist(custom_marking_species_icon_base_option_cache))
		return custom_marking_species_catalog_cache
	if(!islist(GLOB.all_species) || !GLOB.all_species.len)
		return null
	if(!islist(GLOB.playable_species) || !GLOB.playable_species.len)
		return null
	if(!islist(all_traits) || !all_traits.len)
		return null
	var/list/yield_context = custom_marking_begin_manual_yield()
	var/datum/tgui_module/custom_marking_designer/species_catalog_cache_builder/helper = new
	helper.build_species_catalog_cache()
	custom_marking_end_manual_yield(yield_context)
	return custom_marking_species_catalog_cache

/proc/custom_marking_static_icon_base_choices_for_species(species_id)
	if(!istext(species_id) || !length(species_id))
		return null
	var/datum/species/species = GLOB.all_species?[species_id]
	if(!istype(species))
		return null
	var/list/choices = null
	if(species.selects_bodytype == SELECTS_BODYTYPE_SHAPESHIFTER)
		choices = species.get_valid_shapeshifter_forms()
		if(islist(choices))
			choices = choices.Copy()
	else if(species.selects_bodytype == SELECTS_BODYTYPE_CUSTOM)
		choices = islist(GLOB.custom_species_bases) ? GLOB.custom_species_bases.Copy() : list()
		if(species_id != SPECIES_CUSTOM)
			choices = (choices | species_id)
	if(!islist(choices) || !choices.len)
		return null
	return choices

/proc/custom_marking_species_detail_var_defs()
	var/static/list/defs = list(
		"breath_type" = list("section" = "survival", "title" = "Atmosphere & Survival", "label" = "Breath Gas", "description" = "Gas required for normal breathing.", "format" = "gas", "severity" = "warning", "none_severity" = "positive"),
		"poison_type" = list("section" = "survival", "title" = "Atmosphere & Survival", "label" = "Poisonous Gas", "description" = "Atmospheric gas that is toxic to breathe.", "format" = "gas", "severity" = "warning", "none_severity" = "positive"),
		"exhale_type" = list("section" = "survival", "title" = "Atmosphere & Survival", "label" = "Exhaled Gas", "description" = "Gas produced when breathing.", "format" = "gas"),
		"minimum_breath_pressure" = list("section" = "survival", "title" = "Atmosphere & Survival", "label" = "Minimum Breath Pressure", "description" = "Minimum partial pressure needed to breathe safely.", "format" = "pressure", "severity" = "warning", "lower_severity" = "positive", "higher_severity" = "warning"),
		"water_breather" = list("section" = "survival", "title" = "Atmosphere & Survival", "label" = "Water Breathing", "description" = "Can breathe while lying in water.", "format" = "bool", "severity" = "positive"),
		"water_damage_mod" = list("section" = "survival", "title" = "Atmosphere & Survival", "label" = "Water Damage", "description" = "Toxin damage multiplier from water exposure.", "format" = "number", "severity" = "warning"),
		"light_dam" = list("section" = "survival", "title" = "Atmosphere & Survival", "label" = "Light Damage", "description" = "Light level over which the species takes damage.", "format" = "number", "severity" = "critical"),
		"passive_temp_gain" = list("section" = "survival", "title" = "Atmosphere & Survival", "label" = "Passive Heat Gain", "description" = "Body temperature gained passively each second.", "format" = "number", "severity" = "warning"),
		"allergens" = list("section" = "survival", "title" = "Atmosphere & Survival", "label" = "Allergens", "description" = "Foods or reagents that trigger allergic reactions.", "format" = "allergens", "severity" = "warning"),

		"safe_pressure" = list("section" = "environment", "title" = "Temperature & Pressure", "label" = "Safe Pressure", "description" = "Preferred ambient pressure.", "format" = "pressure"),
		"warning_low_pressure" = list("section" = "environment", "title" = "Temperature & Pressure", "label" = "Low Pressure Warning", "description" = "Low pressure warning threshold.", "format" = "pressure_low", "severity" = "warning", "permissive_direction" = "lower"),
		"hazard_low_pressure" = list("section" = "environment", "title" = "Temperature & Pressure", "label" = "Low Pressure Hazard", "description" = "Dangerous low pressure threshold.", "format" = "pressure_low", "severity" = "critical", "permissive_direction" = "lower"),
		"warning_high_pressure" = list("section" = "environment", "title" = "Temperature & Pressure", "label" = "High Pressure Warning", "description" = "High pressure warning threshold.", "format" = "pressure_high", "severity" = "warning", "permissive_direction" = "higher"),
		"hazard_high_pressure" = list("section" = "environment", "title" = "Temperature & Pressure", "label" = "High Pressure Hazard", "description" = "Dangerous high pressure threshold.", "format" = "pressure_high", "severity" = "critical", "permissive_direction" = "higher"),
		"body_temperature" = list("section" = "environment", "title" = "Temperature & Pressure", "label" = "Body Temperature", "description" = "Body temperature the species stabilizes around.", "format" = "temperature"),
		"cold_level_1" = list("section" = "environment", "title" = "Temperature & Pressure", "label" = "Cold Damage 1", "description" = "Ambient cold threshold for light damage.", "format" = "temperature_low", "severity" = "warning", "permissive_direction" = "lower"),
		"cold_level_2" = list("section" = "environment", "title" = "Temperature & Pressure", "label" = "Cold Damage 2", "description" = "Ambient cold threshold for moderate damage.", "format" = "temperature_low", "severity" = "warning", "permissive_direction" = "lower"),
		"cold_level_3" = list("section" = "environment", "title" = "Temperature & Pressure", "label" = "Cold Damage 3", "description" = "Ambient cold threshold for severe damage.", "format" = "temperature_low", "severity" = "critical", "permissive_direction" = "lower"),
		"breath_cold_level_1" = list("section" = "environment", "title" = "Temperature & Pressure", "label" = "Cold Breath 1", "description" = "Cold breathed-gas threshold for light damage.", "format" = "temperature_low", "severity" = "warning", "permissive_direction" = "lower"),
		"breath_cold_level_2" = list("section" = "environment", "title" = "Temperature & Pressure", "label" = "Cold Breath 2", "description" = "Cold breathed-gas threshold for moderate damage.", "format" = "temperature_low", "severity" = "warning", "permissive_direction" = "lower"),
		"breath_cold_level_3" = list("section" = "environment", "title" = "Temperature & Pressure", "label" = "Cold Breath 3", "description" = "Cold breathed-gas threshold for severe damage.", "format" = "temperature_low", "severity" = "critical", "permissive_direction" = "lower"),
		"heat_level_1" = list("section" = "environment", "title" = "Temperature & Pressure", "label" = "Heat Damage 1", "description" = "Ambient heat threshold for light damage.", "format" = "temperature_high", "severity" = "warning", "permissive_direction" = "higher"),
		"heat_level_2" = list("section" = "environment", "title" = "Temperature & Pressure", "label" = "Heat Damage 2", "description" = "Ambient heat threshold for moderate damage.", "format" = "temperature_high", "severity" = "warning", "permissive_direction" = "higher"),
		"heat_level_3" = list("section" = "environment", "title" = "Temperature & Pressure", "label" = "Heat Damage 3", "description" = "Ambient heat threshold for severe damage.", "format" = "temperature_high", "severity" = "critical", "permissive_direction" = "higher"),
		"breath_heat_level_1" = list("section" = "environment", "title" = "Temperature & Pressure", "label" = "Hot Breath 1", "description" = "Hot breathed-gas threshold for light damage.", "format" = "temperature_high", "severity" = "warning", "permissive_direction" = "higher"),
		"breath_heat_level_2" = list("section" = "environment", "title" = "Temperature & Pressure", "label" = "Hot Breath 2", "description" = "Hot breathed-gas threshold for moderate damage.", "format" = "temperature_high", "severity" = "warning", "permissive_direction" = "higher"),
		"breath_heat_level_3" = list("section" = "environment", "title" = "Temperature & Pressure", "label" = "Hot Breath 3", "description" = "Hot breathed-gas threshold for severe damage.", "format" = "temperature_high", "severity" = "critical", "permissive_direction" = "higher"),

		"total_health" = list("section" = "damage", "title" = "Damage & Medicine", "label" = "Total Health", "description" = "Health pool before critical condition.", "format" = "number", "permissive_direction" = "higher"),
		"brute_mod" = list("section" = "damage", "title" = "Damage & Medicine", "label" = "Brute Damage", "description" = "Physical damage multiplier.", "format" = "multiplier", "permissive_direction" = "lower"),
		"burn_mod" = list("section" = "damage", "title" = "Damage & Medicine", "label" = "Burn Damage", "description" = "Burn damage multiplier.", "format" = "multiplier", "permissive_direction" = "lower"),
		"oxy_mod" = list("section" = "damage", "title" = "Damage & Medicine", "label" = "Oxygen Loss", "description" = "Oxygen loss multiplier.", "format" = "multiplier", "permissive_direction" = "lower"),
		"toxins_mod" = list("section" = "damage", "title" = "Damage & Medicine", "label" = "Toxin Damage", "description" = "Toxin damage multiplier.", "format" = "multiplier", "permissive_direction" = "lower"),
		"radiation_mod" = list("section" = "damage", "title" = "Damage & Medicine", "label" = "Radiation Damage", "description" = "Radiation damage multiplier.", "format" = "multiplier", "permissive_direction" = "lower"),
		"flash_mod" = list("section" = "damage", "title" = "Damage & Medicine", "label" = "Flash Stun", "description" = "Flash and flashbang stun multiplier.", "format" = "multiplier", "permissive_direction" = "lower"),
		"flash_burn" = list("section" = "damage", "title" = "Damage & Medicine", "label" = "Flash Burn", "description" = "Burn damage from being flashed.", "format" = "number", "severity" = "warning", "permissive_direction" = "lower"),
		"sound_mod" = list("section" = "damage", "title" = "Damage & Medicine", "label" = "Flashbang Range", "description" = "Flashbang range multiplier.", "format" = "multiplier", "permissive_direction" = "lower"),
		"pain_mod" = list("section" = "damage", "title" = "Damage & Medicine", "label" = "Pain Effects", "description" = "Pain effect multiplier.", "format" = "multiplier", "permissive_direction" = "lower"),
		"spice_mod" = list("section" = "damage", "title" = "Damage & Medicine", "label" = "Spice Effects", "description" = "Capsaicin and frostoil effect multiplier.", "format" = "multiplier", "permissive_direction" = "lower"),
		"trauma_mod" = list("section" = "damage", "title" = "Damage & Medicine", "label" = "Traumatic Shock", "description" = "Traumatic shock multiplier.", "format" = "multiplier", "permissive_direction" = "lower"),
		"chem_strength_heal" = list("section" = "damage", "title" = "Damage & Medicine", "label" = "Healing Chems", "description" = "Beneficial chemical strength multiplier.", "format" = "multiplier", "permissive_direction" = "higher"),
		"chem_strength_pain" = list("section" = "damage", "title" = "Damage & Medicine", "label" = "Painkillers", "description" = "Painkiller strength multiplier.", "format" = "multiplier", "permissive_direction" = "higher"),
		"chem_strength_tox" = list("section" = "damage", "title" = "Damage & Medicine", "label" = "Toxic Chems", "description" = "Toxic chemical strength multiplier.", "format" = "multiplier", "permissive_direction" = "lower"),
		"chem_strength_alcohol" = list("section" = "damage", "title" = "Damage & Medicine", "label" = "Alcohol Strength", "description" = "Alcohol strength multiplier.", "format" = "multiplier", "permissive_direction" = "lower"),
		"chemOD_threshold" = list("section" = "damage", "title" = "Damage & Medicine", "label" = "Overdose Threshold", "description" = "Overdose threshold multiplier.", "format" = "multiplier", "permissive_direction" = "higher"),
		"chemOD_mod" = list("section" = "damage", "title" = "Damage & Medicine", "label" = "Overdose Damage", "description" = "Overdose damage multiplier.", "format" = "multiplier", "permissive_direction" = "lower"),
		"emp_dmg_mod" = list("section" = "damage", "title" = "Damage & Medicine", "label" = "EMP Damage", "description" = "EMP damage multiplier.", "format" = "multiplier", "permissive_direction" = "lower"),
		"emp_stun_mod" = list("section" = "damage", "title" = "Damage & Medicine", "label" = "EMP Stun", "description" = "EMP stun and disorientation multiplier.", "format" = "multiplier", "permissive_direction" = "lower"),
		"blood_volume" = list("section" = "damage", "title" = "Damage & Medicine", "label" = "Blood Volume", "description" = "Expected full blood volume; zero indicates a bloodless species.", "format" = "number", "permissive_direction" = "higher", "zero_severity" = "positive"),
		"bloodloss_rate" = list("section" = "damage", "title" = "Damage & Medicine", "label" = "Bleeding Rate", "description" = "Bleeding rate multiplier.", "format" = "multiplier", "permissive_direction" = "lower"),
		"siemens_coefficient" = list("section" = "damage", "title" = "Damage & Medicine", "label" = "Shock Conductivity", "description" = "Electrical shock conductivity.", "format" = "multiplier", "permissive_direction" = "lower"),
		"throwforce_absorb_threshold" = list("section" = "damage", "title" = "Damage & Medicine", "label" = "Thrown Impact Absorption", "description" = "Thrown item force ignored below this value.", "format" = "number", "permissive_direction" = "higher"),

		"has_organ" = list("section" = "body", "title" = "Body & Physiology", "label" = "Internal Organs", "description" = "Internal organ set used for surgery, metabolism, and survival.", "format" = "organs"),
		"mob_size" = list("section" = "body", "title" = "Body & Physiology", "label" = "Body Size", "description" = "Mob size used for movement and interactions.", "format" = "mob_size"),
		"primitive_form" = list("section" = "body", "title" = "Body & Physiology", "label" = "Primitive Form", "description" = "Lesser form used by transformation effects.", "format" = "text"),
		"unarmed_types" = list("section" = "body", "title" = "Body & Physiology", "label" = "Natural Attacks", "description" = "Unarmed attacks available to this species.", "format" = "path_list"),
		"flags" = list("section" = "body", "title" = "Body & Physiology", "label" = "Species Flags", "description" = "Built-in physiological immunities and restrictions.", "format" = "species_flags"),
		"virus_immune" = list("section" = "body", "title" = "Body & Physiology", "label" = "Virus Immunity", "description" = "Immune to normal viral infection.", "format" = "bool", "severity" = "positive"),
		"hunger_factor" = list("section" = "body", "title" = "Body & Physiology", "label" = "Hunger Rate", "description" = "Nutrition loss rate.", "format" = "number"),
		"metabolic_rate" = list("section" = "body", "title" = "Body & Physiology", "label" = "Metabolic Rate", "description" = "Species metabolism rate multiplier.", "format" = "multiplier"),
		"metabolism" = list("section" = "body", "title" = "Body & Physiology", "label" = "Reagent Metabolism", "description" = "Reagent processing rate.", "format" = "number"),
		"reagent_tag" = list("section" = "biochemical", "title" = "Biochemical", "label" = "Chemistry Reactions", "description" = "Reagents that affect this species differently from humans.", "format" = "presence"),
		"gluttonous" = list("section" = "body", "title" = "Body & Physiology", "label" = "Gluttonous", "description" = "Can eat some mobs depending on value.", "format" = "optional_number"),
		"organic_food_coeff" = list("section" = "body", "title" = "Body & Physiology", "label" = "Organic Food Nutrition", "description" = "Nutrition gained from organic food.", "format" = "multiplier"),
		"synthetic_food_coeff" = list("section" = "body", "title" = "Body & Physiology", "label" = "Synthetic Food Nutrition", "description" = "Nutrition gained from synthetic food sources.", "format" = "multiplier"),
		"digestion_efficiency" = list("section" = "body", "title" = "Body & Physiology", "label" = "Digestion Efficiency", "description" = "Efficiency for digestion-related nutrition.", "format" = "multiplier"),
		"digestion_nutrition_modifier" = list("section" = "body", "title" = "Body & Physiology", "label" = "Digestion Nutrition", "description" = "Nutrition modifier from digestion.", "format" = "multiplier"),
		"bloodsucker" = list("section" = "body", "title" = "Body & Physiology", "label" = "Blood Nutrition", "description" = "Can safely gain nutrition from blood.", "format" = "bool", "severity" = "positive"),
		"electrovore" = list("section" = "body", "title" = "Body & Physiology", "label" = "Electrovore", "description" = "Can drain power cells for nutrition.", "format" = "bool", "severity" = "positive"),
		"eat_minerals" = list("section" = "body", "title" = "Body & Physiology", "label" = "Mineral Diet", "description" = "Can use minerals as a food source.", "format" = "bool", "severity" = "positive"),

		"slowdown" = list("section" = "movement", "title" = "Movement & Senses", "label" = "Movement Speed", "description" = "Unencumbered species movement speed relative to humans.", "format" = "movement_speed", "permissive_direction" = "lower"),
		"item_slowdown_mod" = list("section" = "movement", "title" = "Movement & Senses", "label" = "Item Slowdown", "description" = "Multiplier for slowdown from carried or worn items.", "format" = "multiplier", "permissive_direction" = "lower"),
		"water_movement" = list("section" = "movement", "title" = "Movement & Senses", "label" = "Water Movement", "description" = "Remaining shallow- and deep-water slowdown relative to humans.", "format" = "water_movement", "permissive_direction" = "lower"),
		"snow_movement" = list("section" = "movement", "title" = "Movement & Senses", "label" = "Snow Movement", "description" = "Remaining snow slowdown relative to humans.", "format" = "snow_movement", "permissive_direction" = "lower"),
		"darksight" = list("section" = "movement", "title" = "Movement & Senses", "label" = "Dark Vision", "description" = "Native darksight range.", "format" = "tiles", "permissive_direction" = "higher"),
		"short_sighted" = list("section" = "movement", "title" = "Movement & Senses", "label" = "Short Sighted", "description" = "Has permanent short-sighted vision.", "format" = "bool", "severity" = "critical"),
		"has_glowing_eyes" = list("section" = "movement", "title" = "Movement & Senses", "label" = "Glowing Eyes", "description" = "Eyes render above lighting.", "format" = "bool"),
		"has_floating_eyes" = list("section" = "movement", "title" = "Movement & Senses", "label" = "Floating Eyes", "description" = "Eyes can render above other body icons.", "format" = "bool"),
		"can_space_freemove" = list("section" = "movement", "title" = "Movement & Senses", "label" = "Space Movement", "description" = "Can move freely in space.", "format" = "bool", "severity" = "positive"),
		"can_zero_g_move" = list("section" = "movement", "title" = "Movement & Senses", "label" = "Zero-G Movement", "description" = "Can move freely in zero gravity.", "format" = "bool", "severity" = "positive"),
		"soft_landing" = list("section" = "movement", "title" = "Movement & Senses", "label" = "Soft Landing", "description" = "Can safely lower down short falls.", "format" = "bool", "severity" = "positive"),
		"clumsy" = list("section" = "movement", "title" = "Movement & Senses", "label" = "Clumsy", "description" = "Takes damage from short falls that others may avoid.", "format" = "bool", "severity" = "critical"),
		"can_climb" = list("section" = "movement", "title" = "Movement & Senses", "label" = "Can Climb", "description" = "Can climb where climbing is supported.", "format" = "bool", "severity" = "positive"),
		"climbing_delay" = list("section" = "movement", "title" = "Movement & Senses", "label" = "Climbing Delay", "description" = "Delay multiplier for climbing.", "format" = "number", "permissive_direction" = "lower"),
		"lightweight" = list("section" = "movement", "title" = "Movement & Senses", "label" = "Lightweight", "description" = "More vulnerable to bump stumbles.", "format" = "bool", "severity" = "critical"),

		"inherent_verbs" = list("section" = "abilities", "title" = "Abilities & Restrictions", "label" = "Species Verbs", "description" = "Species-specific verbs granted on spawn.", "format" = "path_list"),
		"has_fine_manipulation" = list("section" = "abilities", "title" = "Abilities & Restrictions", "label" = "Fine Manipulation", "description" = "Can use small items normally.", "format" = "bool"),
		"greater_form" = list("section" = "abilities", "title" = "Abilities & Restrictions", "label" = "Greater Form", "description" = "Greater form used by transformation effects.", "format" = "text")
	)
	return defs

/proc/custom_marking_species_detail_value_differs(var/value, var/baseline_value)
	if(isnull(value) && isnull(baseline_value))
		return FALSE
	if(isnull(value) || isnull(baseline_value))
		return TRUE
	if(islist(value) || islist(baseline_value))
		if(!islist(value) || !islist(baseline_value))
			return TRUE
		var/list/value_list = value
		var/list/baseline_list = baseline_value
		if(value_list.len != baseline_list.len)
			return TRUE
		for(var/key in value_list)
			if(!(key in baseline_list))
				return TRUE
			if(custom_marking_species_detail_value_differs(value_list[key], baseline_list[key]))
				return TRUE
		return FALSE
	return value != baseline_value

/proc/custom_marking_species_detail_entry_ids(var/list/sections)
	var/list/ids = list()
	if(!islist(sections))
		return ids
	for(var/list/section in sections)
		if(!islist(section))
			continue
		var/list/entries = section["entries"]
		if(!islist(entries))
			continue
		for(var/list/entry in entries)
			if(!islist(entry))
				continue
			var/id = entry["id"]
			if(istext(id) && length(id))
				ids[id] = TRUE
	return ids

/proc/custom_marking_copy_species_detail_sections(var/list/sections)
	var/list/copied_sections = list()
	if(!islist(sections))
		return copied_sections
	for(var/list/section in sections)
		if(!islist(section))
			continue
		var/list/copied_section = section.Copy()
		var/list/copied_entries = list()
		var/list/entries = section["entries"]
		if(islist(entries))
			for(var/list/entry in entries)
				if(islist(entry))
					copied_entries += list(entry.Copy())
		copied_section["entries"] = copied_entries
		copied_sections += list(copied_section)
	return copied_sections

/proc/custom_marking_find_species_detail_section(var/list/sections, var/section_id, var/title)
	if(!islist(sections))
		return null
	for(var/list/section in sections)
		if(islist(section) && section["id"] == section_id)
			return section
	var/list/new_section = list(
		"id" = section_id,
		"title" = title,
		"entries" = list()
	)
	sections += list(new_section)
	return new_section

/proc/custom_marking_add_species_detail_entry(var/list/sections, var/section_id, var/title, var/id, var/label, var/value = null, var/baseline_value = null, var/description = null, var/severity = null)
	if(!islist(sections) || !istext(section_id) || !length(section_id) || !istext(label) || !length(label))
		return null
	var/list/section = custom_marking_find_species_detail_section(sections, section_id, title)
	if(!islist(section))
		return null
	var/list/entry = list(
		"id" = istext(id) && length(id) ? id : label,
		"label" = label
	)
	if(!isnull(value))
		entry["value"] = value
	if(!isnull(baseline_value))
		entry["baseline_value"] = baseline_value
	if(istext(description) && length(description))
		entry["description"] = description
	if(istext(severity) && length(severity))
		entry["severity"] = severity
	var/list/entries = section["entries"]
	entries += list(entry)
	return entry

/proc/custom_marking_species_language_names(var/value)
	var/list/names = list()
	if(istext(value) && length(value))
		names |= value
	else if(islist(value))
		for(var/language_name in value)
			if(istext(language_name) && length(language_name))
				names |= language_name
	return names

/proc/custom_marking_species_language_definition(var/language_name)
	if(!istext(language_name) || !length(language_name))
		return null
	var/datum/language/language_datum = GLOB.all_languages?[language_name]
	if(!istype(language_datum) || !istext(language_datum.desc) || !length(language_datum.desc))
		return null
	return language_datum.desc

/proc/custom_marking_add_species_language_details(var/list/sections, var/datum/species/species)
	if(!islist(sections) || !istype(species))
		return FALSE
	var/alternate_language_slots = isnum(species.num_alternate_languages) ? max(0, species.num_alternate_languages) : 0
	var/alternate_language_slot_value = alternate_language_slots ? "Up to [alternate_language_slots]" : "None"
	custom_marking_add_species_detail_entry(
		sections,
		"languages",
		"Languages & Culture",
		"additional-language-slots",
		"Additional Language Slots",
		alternate_language_slot_value,
		null,
		"Base number of optional languages this species may select during character creation. These slots are an allowance, not languages known automatically."
	)

	var/list/automatically_known = custom_marking_species_language_names(species.language)
	automatically_known |= custom_marking_species_language_names(species.default_language)
	var/list/species_languages = custom_marking_species_language_names(species.species_language)
	var/list/optional_languages = custom_marking_species_language_names(species.secondary_langs)
	var/list/cultural_languages = species_languages.Copy()
	cultural_languages |= optional_languages
	var/list/language_names = automatically_known.Copy()
	language_names |= cultural_languages
	for(var/language_name in language_names)
		var/list/statuses = list()
		if(language_name in automatically_known)
			statuses += "Automatically known"
		if(language_name == species.default_language)
			statuses += "Species speech default"
		if(language_name in cultural_languages)
			statuses += "Cultural language"
		if((language_name in optional_languages) && !(language_name in automatically_known))
			statuses += "Optional character-creation choice"
		custom_marking_add_species_detail_entry(
			sections,
			"languages",
			"Languages & Culture",
			"species-language-[language_name]",
			language_name,
			jointext(statuses, "; "),
			null,
			custom_marking_species_language_definition(language_name)
		)
	return TRUE

/proc/custom_marking_add_species_unassisted_language_detail(var/list/sections, var/datum/species/species, var/datum/species/baseline)
	if(!islist(sections) || !istype(species) || !istype(baseline))
		return FALSE
	var/list/species_assisted_languages = custom_marking_species_language_names(species.assisted_langs)
	var/list/unassisted_languages = list()
	for(var/language_name in custom_marking_species_language_names(baseline.assisted_langs))
		if(!(language_name in species_assisted_languages))
			unassisted_languages |= language_name
	if(!unassisted_languages.len)
		return FALSE
	var/list/definitions = list()
	for(var/language_name in unassisted_languages)
		var/definition = custom_marking_species_language_definition(language_name)
		if(definition)
			definitions += "[language_name]: [definition]"
	var/description = "Languages this species can physically articulate without speech assistance even though humans and species with the typical vocal range cannot. This does not grant knowledge of those languages automatically."
	if(definitions.len)
		description += " [jointext(definitions, " ")]"
	custom_marking_add_species_detail_entry(
		sections,
		"languages",
		"Languages & Culture",
		"expanded-vocal-range",
		"Expanded Vocal Range",
		custom_marking_species_detail_list_label(unassisted_languages),
		null,
		description,
		"positive"
	)
	return TRUE

/proc/custom_marking_species_reagent_reactions(var/reagent_tag)
	var/profile_id
	switch(reagent_tag)
		if(IS_DIONA)
			profile_id = "diona"
		if(IS_VOX)
			profile_id = "vox"
		if(IS_SKRELL)
			profile_id = "skrell"
		if(IS_UNATHI)
			profile_id = "unathi"
		if(IS_TAJARA)
			profile_id = "tajara"
		if(IS_TESHARI)
			profile_id = "teshari"
		if(IS_SLIME)
			profile_id = "slime"
		if(IS_CHIMERA)
			profile_id = "chimera"
		if(IS_SHADEKIN)
			profile_id = "shadekin"
		if(IS_ALRAUNE)
			profile_id = "alraune"
	if(!profile_id)
		return list()

	var/static/list/reactions_by_profile = list(
		"diona" = list(
			list("id" = "overdoses", "label" = "Reagent Overdoses", "value" = "The shared overdose reaction deals no toxin damage. Reagent-specific overdose effects can still apply."),
			list("id" = "toxins", "label" = "Most Toxins", "value" = "The shared toxin reaction deals no toxin damage, although named toxin behaviors can still apply."),
			list("id" = "common-medicine", "label" = "Common Medicines", "value" = "Inaprovaline, Bicaridine, Calcium Carbonate, Kelotane, Dermaline, Dylovene, Carthatoline, Dexalin, Tricordrazine, Synaptizine, Alkysine, Osteodaxon, Myelamine, Vermicetol, Adranol, and their listed variants provide none of their normal healing or stabilizing effects."),
			list("id" = "special-medicine", "label" = "Radiation, Temperature & Genetic Medicine", "value" = "Ethylredoxrazine, Hyronalin, Arithrazine, Prussian Blue, Leporazine, and Rezadone provide none of their normal effects."),
			list("id" = "immunosuprizine", "label" = "Immunosuprizine", "value" = "Provides one-quarter of its normal transplant-protection strength but does not inflict its associated toxin damage."),
			list("id" = "adrenaline-modifiers", "label" = "Adrenaline & Modifier Chemicals", "value" = "Adrenaline and generic modifier-applying chemicals provide no effect."),
			list("id" = "nutriment", "label" = "Nutriment & Animal Protein", "value" = "Ordinary nutriment and animal protein provide no healing, blood restoration, or nutrition."),
			list("id" = "food-drink", "label" = "Food & Drink Bonuses", "value" = "Species-specific effects from lime, orange, and tomato juice, milk, tea, coffee, Doctor's Delight, Hell Ramen, Nuclear Waste, and several special alcoholic drinks are skipped."),
			list("id" = "spices", "label" = "Frost Oil, Capsaicin & Burnout", "value" = "Metabolized frost oil and capsaicin have no effect. Burnout does not cause its simulated internal-heat reaction."),
			list("id" = "neurochemicals", "label" = "Sedatives & Neurochemicals", "value" = "Lithium, mercury, neurotoxic protein, zombie and lich powders, Lexorin, soporific, chloral hydrate, serotrotium, cryptobiolin, impedrezene, mindbreaker toxin, and irritant venom provide none of their species-gated effects."),
			list("id" = "plantbgone", "label" = "Plant-B-Gone", "value" = "Bloodstream or skin exposure causes 50 toxin damage per metabolized unit."),
			list("id" = "sivian-sap", "label" = "Sivian Sap", "value" = "Provides nutrition instead of toxin damage and a slow pulse; its special overdose reaction is ignored."),
			list("id" = "pyrotoxin", "label" = "Pyrotoxin", "value" = "Still causes burn damage and its initial small fire-stack gain, but skips the additional fire-stack and ignition rolls."),
			list("id" = "slime-jelly", "label" = "Slime Jelly", "value" = "Provides none of its normal random healing or severe toxin reactions."),
			list("id" = "liquid-protean", "label" = "Liquid Protean", "value" = "Provides none of its normal oxygen, brute, burn, or toxin healing. Its separate NIF interaction can still apply."),
			list("id" = "carbon", "label" = "Carbon", "value" = "Does not purge other ingested reagents."),
			list("id" = "prion-resistance", "label" = "Prion Disease Resistance", "value" = "Resistant to prion diseases."),
			list("id" = "recreational-drugs", "label" = "Recreational Drugs", "value" = "The shared drug handler skips its high and sober messages and random-behavior trigger. Effects implemented directly by a particular drug can remain.")
		),
		"vox" = list(
			list("id" = "oxygen", "label" = "Oxygen", "value" = "Causes toxin damage when metabolized."),
			list("id" = "dexalin", "label" = "Dexalin & Dexalin Plus", "value" = "Cause heavy toxin damage instead of treating oxygen loss."),
			list("id" = "phoron", "label" = "Phoron", "value" = "Heals oxygen loss in the bloodstream. Skin exposure skips the usual chemical burns and phoron sickness, but can still add fire stacks."),
			list("id" = "prion-resistance", "label" = "Prion Disease Resistance", "value" = "Resistant to prion diseases.")
		),
		"skrell" = list(
			list("id" = "recreational-drugs", "label" = "Bliss, Ambrosia Extract & Redeemer's Brew", "value" = "Their intoxicating or drug-like strength is reduced by 20%."),
			list("id" = "psilocybin", "label" = "Psilocybin", "value" = "Dose thresholds are increased by 20%."),
			list("id" = "talum-quem", "label" = "Talum-Quem", "value" = "Its drug effect is reduced by 20%, and it causes no species-mismatch toxin damage."),
			list("id" = "meat-drinks", "label" = "Monster Tamer & Hair of the Rat", "value" = "Ingesting or injecting them causes additional toxin damage from their meat content."),
			list("id" = "pepper-spray", "label" = "Condensed Capsaicin", "value" = "Contact strength is increased from 5 to 8 because of larger exposed eyes."),
			list("id" = "lexorin", "label" = "Lexorin", "value" = "Causes 20% less organ damage and stops increasing breath loss at 10 instead of 15."),
			list("id" = "sedatives", "label" = "Soporific & Chloral Hydrate", "value" = "Dose thresholds are increased by 20%."),
			list("id" = "mental-toxins", "label" = "Cryptobiolin & Mindbreaker Toxin", "value" = "Dizziness, confusion, and hallucination strength are reduced by 20%."),
			list("id" = "immunosuprizine", "label" = "Immunosuprizine", "value" = "Acts at 150% transplant-protection strength and causes less associated toxin damage."),
			list("id" = "skrell-immunosuppressant", "label" = "Skrell Immunosuppressant", "value" = "Acts at full strength and causes no mismatch toxin damage; other species receive half strength and toxin damage.")
		),
		"unathi" = list(
			list("id" = "nutriment", "label" = "Nutriment", "value" = "Ordinary nutriment is processed at half strength."),
			list("id" = "protein", "label" = "Animal Protein, Monster Tamer & Hair of the Rat", "value" = "Animal-protein nutrition is processed at 112.5% of the human rate after the general nutriment penalty."),
			list("id" = "sugar", "label" = "Sugar, Honey & Sugary Juice", "value" = "Cause dose-dependent yawning, blurred vision, drowsiness, knockdown, and eventually sleep."),
			list("id" = "immunosuprizine", "label" = "Immunosuprizine", "value" = "Acts at 175% transplant-protection strength and causes less associated toxin damage.")
		),
		"tajara" = list(
			list("id" = "stimm", "label" = "Stimm", "value" = "Its metabolized dose is increased by 25%, increasing the physical damage from its violent-shudder reaction."),
			list("id" = "immunosuprizine", "label" = "Immunosuprizine", "value" = "Acts at twice its normal transplant-protection strength and causes less associated toxin damage.")
		),
		"teshari" = list(
			list("id" = "protein", "label" = "Animal Protein, Monster Tamer & Hair of the Rat", "value" = "Animal-protein nutrition is processed at 120% of the human rate.")
		),
		"slime" = list(
			list("id" = "blood", "label" = "Blood & Promethean Goo", "value" = "Matching Promethean goo refills their blood supply. Other blood feeds them, restores blood, and heals brute damage, but also causes some toxin damage; touch and injection use the same reaction."),
			list("id" = "nutriment", "label" = "Injected Nutriment", "value" = "Ordinary nutriment can be processed as food when injected instead of causing the usual toxin damage for non-injectable food reagents."),
			list("id" = "toxins", "label" = "Most Toxins", "value" = "Base toxin damage is halved. Below 10 units, many toxins can also heal brute and burn damage; at 10 units or more they instead add nutrition."),
			list("id" = "slime-jelly", "label" = "Slime Jelly", "value" = "Usually provides very strong brute, burn, and toxin healing plus a powerful painkiller effect instead of its dangerous random human reaction."),
			list("id" = "salts", "label" = "Salt & Potassium Salts", "value" = "Table salt causes burn damage. Potassium chloride and potassium chlorophoride cause additional burn damage."),
			list("id" = "phoron", "label" = "Phoron & Hydrophoron", "value" = "Add large amounts of fire stacks; hydrophoron can ignite the species after a delay."),
			list("id" = "water-drinks", "label" = "Water-Based Drinks", "value" = "Bloodstream exposure causes three times the usual drink-related toxin damage."),
			list("id" = "ice", "label" = "Ice, Iced Tea & Iced Coffee", "value" = "Ingestion or bloodstream exposure pushes body temperature toward 0 C."),
			list("id" = "pepper-spray", "label" = "Condensed Capsaicin", "value" = "Pepper spray can cause severe agony across every exposed body region, even when the face is protected."),
			list("id" = "recreational-drugs", "label" = "Recreational & Mental Drugs", "value" = "Bliss and Ambrosia Extract are 20% stronger; Psilocybin has lower dose thresholds; Cryptobiolin and Mindbreaker Toxin are 20% stronger."),
			list("id" = "trauma-medicine", "label" = "Trauma, Burn & Antitoxin Medicine", "value" = "Bicaridine, Dermaline, Dylovene, Tricordrazine, Tricorlidaze, and Vermicetol work at reduced strength. Kelotane is half strength and also causes brute damage; Dylovene and Carthatoline can cause a drugged state."),
			list("id" = "dexalin", "label" = "Dexalin & Dexalin Plus", "value" = "At high doses they provide pain relief and may heal brain damage while causing knockdown, instead of treating oxygen loss."),
			list("id" = "cryo-medicine", "label" = "Cryoxadone, Clonexadone, Mortiferin & Necroxadone", "value" = "Most healing is reduced, and cold treatment causes hardening, silence, jittering, and knockdown."),
			list("id" = "painkillers", "label" = "Paracetamol, Tramadol & Oxycodone", "value" = "Pain relief is reduced; these medicines add slowdown or stuttering, with an additional slowdown on paracetamol overdose."),
			list("id" = "stimulants", "label" = "Synaptizine, Hyperzine & Alkysine", "value" = "Synaptizine has reduced normal effects but can heal brute and burn damage at higher doses; Hyperzine causes jitter and consumes nutrition; Alkysine is quarter strength and can cause paralysis or knockdown."),
			list("id" = "organ-medicine", "label" = "Organ Repair & Immunosuprizine", "value" = "Respirodaxon, Gastirodaxon, and Cordradaxon work at 60%; Hepanephrodaxon at 40%; Immunosuprizine at 75%. Peridaxon also adds pain relief and possible confusion."),
			list("id" = "antibiotics", "label" = "Antibiotics & Sterilizers", "value" = "Spaceacillin produces recurring unfocused-senses messages, Corophizine can cause escalating systemic damage, Spacomycaze produces itching messages, and Sterilizine causes burn and toxin damage."),
			list("id" = "space-cleaner", "label" = "Space Cleaner", "value" = "Contact causes toxin damage, while ingestion causes twice the human toxin damage."),
			list("id" = "liquid-protean", "label" = "Liquid Protean", "value" = "Oxygen, burn, and toxin healing are reduced to half strength; brute healing is unchanged."),
			list("id" = "lexorin-sedatives", "label" = "Lexorin, Soporific & Chloral Hydrate", "value" = "Lexorin causes agony, toxin damage, and possible stunning instead of respiratory arrest. Sedatives require much larger doses and impair senses or coordination rather than causing normal sleep."),
			list("id" = "genetic-medicine", "label" = "Mutagen, Ryetalyn & Rezadone", "value" = "Mutagen can randomly shift body colors; Ryetalyn shifts colors toward white and causes toxin damage; Rezadone shifts colors toward dark gray while retaining its normal healing."),
			list("id" = "prion-resistance", "label" = "Prion Disease Resistance", "value" = "Resistant to prion diseases.")
		),
		"chimera" = list(
			list("id" = "nutriment", "label" = "Nutriment & Animal Protein", "value" = "Ordinary nutriment is processed at 25% strength, while animal protein cancels that penalty and is processed at the human rate."),
			list("id" = "injected-food", "label" = "Injected Nutriment, Monster Tamer & Hair of the Rat", "value" = "Injected food reagents provide nutrition instead of the usual toxin damage."),
			list("id" = "neurotoxic-protein", "label" = "Neurotoxic Protein", "value" = "Causes no toxin, movement, or brain effects."),
			list("id" = "prion-resistance", "label" = "Prion Disease Resistance", "value" = "Resistant to prion diseases.")
		),
		"shadekin" = list(
			list("id" = "prion-resistance", "label" = "Prion Disease Resistance", "value" = "Resistant to prion diseases.")
		),
		"alraune" = list(
			list("id" = "spices", "label" = "Frost Oil & Capsaicin", "value" = "Ingestion causes only a mild cooling or warming effect without the normal agony reaction."),
			list("id" = "burnout", "label" = "Burnout", "value" = "Does not cause its simulated internal-heat reaction.")
		)
	)
	var/list/reactions = reactions_by_profile[profile_id]
	return islist(reactions) ? reactions : list()

/proc/custom_marking_add_species_reagent_details(var/list/sections, var/datum/species/species)
	if(!islist(sections) || !istype(species) || isnull(species.reagent_tag))
		return FALSE
	var/list/reactions = custom_marking_species_reagent_reactions(species.reagent_tag)
	if(!islist(reactions) || !reactions.len)
		return FALSE
	for(var/list/reaction in reactions)
		if(!islist(reaction))
			continue
		var/reaction_id = reaction["id"]
		custom_marking_add_species_detail_entry(
			sections,
			"biochemical",
			"Biochemical",
			"chemistry-[species.reagent_tag]-[reaction_id]",
			reaction["label"],
			reaction["value"],
			null,
			"Species-specific reagent behavior."
		)
	return TRUE

/proc/custom_marking_species_flag_detail_defs()
	var/static/list/flag_defs = list(
		list("id" = "minor-cut-resistance", "flag" = NO_MINOR_CUT, "label" = "Minor Cut Resistance", "description" = "Unaffected by minor cutting hazards such as broken glass and cactus needles.", "severity" = "positive"),
		list("id" = "plantlike-physiology", "flag" = IS_PLANT, "label" = "Plantlike Physiology", "description" = "Uses plantlike physiology: resists organ infections and hallucinations, ignores shocks delivered through the hands, and responds to botanical mutation and yield rays."),
		list("id" = "unscannable-dna", "flag" = NO_SCAN, "label" = "Unscannable DNA", "description" = "Cannot be DNA-scanned, have DNA extracted, or use genetic cloning; it also resists DNA-dependent effects."),
		list("id" = "pain-immunity", "flag" = NO_PAIN, "label" = "Pain Immunity", "description" = "Cannot feel pain or accumulate halloss, the temporary damage used for many pain effects.", "severity" = "positive"),
		list("id" = "natural-surefootedness", "flag" = NO_SLIP, "label" = "Natural Surefootedness", "description" = "Natural traction prevents ordinary slips while the species' feet are uncovered.", "severity" = "positive"),
		list("id" = "toxin-immunity", "flag" = NO_POISON, "label" = "Toxin Immunity", "description" = "Cannot accumulate toxin damage and does not undergo normal hallucination processing.", "severity" = "positive"),
		list("id" = "embedding-immunity", "flag" = NO_EMBED, "label" = "Embedding Immunity", "description" = "Intended to prevent minor cuts and embedded shrapnel, but no current gameplay checks read this flag."),
		list("id" = "hallucination-immunity", "flag" = NO_HALLUCINATION, "label" = "Hallucination Immunity", "description" = "Does not experience hallucination effects.", "severity" = "positive"),
		list("id" = "bloodless", "flag" = NO_BLOOD, "label" = "Bloodless", "description" = "Has no blood supply, cannot bleed, and does not leave blood trails.", "severity" = "positive"),
		list("id" = "undead-physiology", "flag" = UNDEAD, "label" = "Undead Physiology", "description" = "External organs do not naturally heal or deteriorate through normal organic processing."),
		list("id" = "infection-immunity", "flag" = NO_INFECT, "label" = "Infection Immunity", "description" = "Internal and external organs cannot develop infections.", "severity" = "positive"),
		list("id" = "defibrillator-incompatibility", "flag" = NO_DEFIB, "label" = "Defibrillator Incompatibility", "description" = "Cannot be revived with a defibrillator.", "severity" = "critical")
	)
	return flag_defs

/proc/custom_marking_add_species_flag_details(var/list/sections, var/datum/species/species, var/datum/species/baseline)
	if(!islist(sections) || !istype(species) || !istype(baseline))
		return FALSE
	var/species_flags = isnum(species.flags) ? species.flags : 0
	var/baseline_flags = isnum(baseline.flags) ? baseline.flags : 0
	var/added = FALSE
	for(var/list/flag_def in custom_marking_species_flag_detail_defs())
		if(!islist(flag_def))
			continue
		var/flag_value = flag_def["flag"]
		if(!isnum(flag_value))
			continue
		var/species_has_flag = (species_flags & flag_value) != 0
		var/baseline_has_flag = (baseline_flags & flag_value) != 0
		if(species_has_flag == baseline_has_flag)
			continue
		var/flag_id = flag_def["id"]
		var/severity = flag_def["severity"]
		if(!species_has_flag)
			if(severity == "positive")
				severity = "critical"
			else if(severity == "critical")
				severity = "positive"
		custom_marking_add_species_detail_entry(
			sections,
			"body",
			"Body & Physiology",
			"species-flag-[flag_id]",
			flag_def["label"],
			species_has_flag ? "Present" : "Absent",
			baseline_has_flag ? "Present" : "Absent",
			flag_def["description"],
			severity
		)
		added = TRUE
	return added

/proc/custom_marking_species_verb_ability_defs()
	var/static/list/ability_defs = list(
		list("id" = "winged-flight", "label" = "Winged Flight", "description" = "Can fly when a wing style is selected, consuming nutrition while airborne. Related controls allow hovering to arrest drift and optionally enable flight-vore bump interactions.", "verbs" = list(/mob/living/proc/flying_toggle, /mob/living/proc/flying_vore_toggle, /mob/living/proc/start_wings_hovering)),
		list("id" = "aquatic-ambush", "label" = "Aquatic Ambush", "description" = "Can dive beneath deep water for stealth and faster movement, then pull an eligible nearby target into its selected belly.", "verbs" = list(/mob/living/carbon/human/proc/water_stealth, /mob/living/carbon/human/proc/underwater_devour)),
		list("id" = "aquatic-rush", "label" = "Aquatic Rush", "description" = "While submerged, can rush an eligible target within eight tiles; matched vore preferences determine which participant swallows the other.", "verbs" = list(/mob/living/carbon/human/proc/rushdown)),
		list("id" = "small-frame-agility", "label" = "Small-Frame Agility", "description" = "Can hide beneath tables or certain objects and toggle agile movement over tables, railings, and hydroponics trays.", "verbs" = list(/mob/living/proc/hide, /mob/living/proc/toggle_pass_table)),
		list("id" = "environmental-listening", "label" = "Environmental Listening", "description" = "Can listen for living creatures within normal view, learning their direction and approximate distance when sound can travel.", "verbs" = list(/mob/living/carbon/human/proc/sonar_ping)),
		list("id" = "wound-licking", "label" = "Antiseptic Saliva", "description" = "Can spend nutrition to clean, salve, bandage, and disinfect small wounds on nearby organic limbs.", "verbs" = list(/mob/living/carbon/human/proc/lick_wounds)),
		list("id" = "silk-weaving", "label" = "Silk Weaving", "description" = "Can produce and monitor silk reserves, choose the silk color, and spend silk to weave structures or items.", "verbs" = list(/mob/living/carbon/human/proc/check_silk_amount, /mob/living/carbon/human/proc/toggle_silk_production, /mob/living/carbon/human/proc/weave_structure, /mob/living/carbon/human/proc/weave_item, /mob/living/carbon/human/proc/set_silk_color)),
		list("id" = "mutable-form", "label" = "Mutable Form", "description" = "Can alter available aspects of its form during play, including emulated body shape, colors, hair, sex and gender presentation, ears, tail, wings, transparency, or clothing fit.", "verbs" = list(/mob/living/carbon/human/proc/shapeshifter_select_shape, /mob/living/carbon/human/proc/shapeshifter_select_colour, /mob/living/carbon/human/proc/shapeshifter_select_hair, /mob/living/carbon/human/proc/shapeshifter_select_eye_colour, /mob/living/carbon/human/proc/shapeshifter_select_hair_colors, /mob/living/carbon/human/proc/shapeshifter_select_gender, /mob/living/carbon/human/proc/shapeshifter_select_wings, /mob/living/carbon/human/proc/shapeshifter_select_tail, /mob/living/carbon/human/proc/shapeshifter_select_ears, /mob/living/carbon/human/proc/shapeshifter_select_secondary_ears, /mob/living/carbon/human/proc/promethean_select_opaqueness, /mob/living/carbon/human/proc/nano_change_fitting)),
		list("id" = "size-shifting", "label" = "Size Shifting", "description" = "Can adjust body size from 25% to 200%, with the wider 1% to 600% range available in dormitory areas.", "verbs" = list(/mob/living/proc/set_size, /mob/living/carbon/human/proc/nano_set_size)),
		list("id" = "amorphous-form", "label" = "Amorphous Form", "description" = "Can switch between humanoid and amorphous blob forms while conscious and in a suitable open space.", "verbs" = list(/mob/living/carbon/human/proc/prommie_blobform, /mob/living/carbon/human/proc/nano_blobform)),
		list("id" = "organic-regeneration", "label" = "Regeneration", "description" = "Can spend stored nutrition and remain still to repair internal organs and regrow missing or ruined limbs and organs.", "verbs" = list(/mob/living/carbon/human/proc/regenerate)),
		list("id" = "protean-refactoring", "label" = "Protean Refactoring", "description" = "Can use stored steel to rebuild missing limbs and organs or reshape individual limbs and the whole body to mimic approved manufacturers.", "verbs" = list(/mob/living/carbon/human/proc/nano_partswap, /mob/living/carbon/human/proc/nano_regenerate)),
		list("id" = "powered-nanite-healing", "label" = "Powered Nanite Healing", "description" = "Can toggle an energy- and steel-fueled repair routine for brute and burn damage.", "verbs" = list(/mob/living/carbon/human/proc/nano_healing)),
		list("id" = "material-storage", "label" = "Material Storage", "description" = "Can consume compatible material stacks into its refactory module for later reconstruction and repair.", "verbs" = list(/mob/living/carbon/human/proc/nano_metalnom)),
		list("id" = "diona-splitting", "label" = "Split into Nymphs", "description" = "Can break its humanoid body into five Diona nymphs, transferring player control to one of them.", "verbs" = list(/mob/living/carbon/human/proc/diona_split_nymph)),
		list("id" = "xenochimera-reconstitution", "label" = "Reconstitute Form", "description" = "Can slowly reconstruct its entire form, recovering from severe injury or death before hatching from the rebuilt body.", "verbs" = list(/mob/living/carbon/human/proc/reconstitute_form)),
		list("id" = "fruit-cultivation", "label" = "Fruit Cultivation", "description" = "Can choose the fruit or vegetable produced by its internal fruit gland, allowing that produce to be harvested once grown.", "verbs" = list(/mob/living/carbon/human/proc/alraune_fruit_select)),
		list("id" = "hive-language-range", "section" = "languages", "title" = "Languages & Culture", "label" = "Hive-Language Range", "description" = "Can set its special hive language to transmit globally, across the current level, locally, or only to adjacent listeners.", "verbs" = list(/mob/proc/adjust_hive_range)),
		list("id" = "phase-flicker-control", "label" = "Phase-In Light Effects", "description" = "Can configure the duration, color, and light-breaking chance of the flicker produced when phasing in.", "verbs" = list(/mob/living/carbon/human/proc/adjust_flicker), "omit_detail" = TRUE),
		list("id" = "vent-crawling", "label" = "Vent Crawling", "description" = "Can enter an air vent and travel through the connected pipe network.", "verbs" = list(/mob/living/proc/ventcrawl)),
		list("id" = "regurgitation", "label" = "Regurgitation", "description" = "Can immediately eject all swallowed occupants from its stomach onto the current tile.", "verbs" = list(/mob/living/carbon/human/proc/regurgitate)),
		list("id" = "resin-shaping", "label" = "Alien Weeds & Resin", "description" = "Can spend stored plasma to plant alien weeds and shape resin doors, walls, membranes, nests, or raw resin.", "verbs" = list(/mob/living/carbon/human/proc/plant, /mob/living/carbon/human/proc/resin)),
		list("id" = "corrosive-acid", "label" = "Corrosive Acid", "description" = "Can spend stored plasma to coat a nearby object, wall, or floor in acid that destroys it over time.", "verbs" = list(/mob/living/carbon/human/proc/corrosive_acid)),
		list("id" = "chemical-spit", "label" = "Acid & Neurotoxin Spit", "description" = "Can prepare ranged acid that burns unprotected targets or neurotoxin that briefly paralyzes them.", "verbs" = list(/mob/living/carbon/human/proc/acidspit, /mob/living/carbon/human/proc/neurotoxin)),
		list("id" = "plasma-transfer", "label" = "Plasma Transfer", "description" = "Can transfer stored plasma to another xenomorph with a functioning plasma vessel.", "verbs" = list(/mob/living/carbon/human/proc/transfer_plasma)),
		list("id" = "queen-evolution", "label" = "Evolve into a Queen", "description" = "Can spend a full plasma reserve to become a xenomorph queen when no active queen already exists.", "verbs" = list(/mob/living/carbon/human/proc/evolve)),
		list("id" = "egg-laying", "label" = "Lay Xenomorph Egg", "description" = "Can spend a full plasma reserve to lay an egg that eventually hatches into a xenomorph larva.", "verbs" = list(/mob/living/carbon/human/proc/lay_egg)),
		list("id" = "pounce-and-tackle", "label" = "Pounce & Tackle", "description" = "Can tackle adjacent targets or leap up to four tiles to knock a target down and seize them.", "verbs" = list(/mob/living/carbon/human/proc/tackle, /mob/living/carbon/human/proc/leap), "require_all" = TRUE),
		list("id" = "tackle", "label" = "Tackle", "description" = "Can attempt to knock down an adjacent target, with a failed tackle knocking the user down instead.", "verbs" = list(/mob/living/carbon/human/proc/tackle)),
		list("id" = "leap", "label" = "Predatory Leap", "description" = "Can leap up to four tiles to knock down a target and seize them with a free hand.", "verbs" = list(/mob/living/carbon/human/proc/leap)),
		list("id" = "slaughter", "label" = "Slaughter", "description" = "Can maul a target held in an aggressive grab, inflicting severe brute damage and destroying an already-dead target.", "verbs" = list(/mob/living/carbon/human/proc/gut)),
		list("id" = "psychic-whisper", "label" = "Psychic Whisper", "description" = "Can send a silent private message directly into the mind of a visible target at range.", "verbs" = list(/mob/living/carbon/human/proc/psychic_whisper)),
		list("id" = "exit-virtual-reality", "label" = "Exit Virtual Reality", "description" = "Can leave virtual reality and return to the original body; some damage suffered in VR carries back as temporary pain.", "verbs" = list(/mob/living/carbon/human/proc/exit_vr)),
		list("id" = "hair-styling", "label" = "Hair Styling", "description" = "Can restyle tieable hair during play.", "verbs" = list(/mob/living/carbon/human/proc/tie_hair))
	)
	return ability_defs

/proc/custom_marking_species_mutable_form_description(var/list/matched_verbs)
	var/list/aspects = list()
	if(/mob/living/carbon/human/proc/shapeshifter_select_shape in matched_verbs)
		aspects += "emulated body shape"
	if(/mob/living/carbon/human/proc/shapeshifter_select_colour in matched_verbs)
		aspects += "body color"
	var/can_select_hair = (/mob/living/carbon/human/proc/shapeshifter_select_hair in matched_verbs)
	var/can_select_hair_colors = (/mob/living/carbon/human/proc/shapeshifter_select_hair_colors in matched_verbs)
	if(can_select_hair && can_select_hair_colors)
		aspects += "hair styles and colors"
	else if(can_select_hair)
		aspects += "hair and facial-hair styles"
	else if(can_select_hair_colors)
		aspects += "hair colors"
	if(/mob/living/carbon/human/proc/shapeshifter_select_eye_colour in matched_verbs)
		aspects += "eye color"
	if(/mob/living/carbon/human/proc/shapeshifter_select_gender in matched_verbs)
		aspects += "sex and gender presentation"
	if((/mob/living/carbon/human/proc/shapeshifter_select_ears in matched_verbs) || (/mob/living/carbon/human/proc/shapeshifter_select_secondary_ears in matched_verbs))
		aspects += "ears"
	if(/mob/living/carbon/human/proc/shapeshifter_select_tail in matched_verbs)
		aspects += "tail"
	if(/mob/living/carbon/human/proc/shapeshifter_select_wings in matched_verbs)
		aspects += "wings"
	if(/mob/living/carbon/human/proc/promethean_select_opaqueness in matched_verbs)
		aspects += "body transparency"
	if(/mob/living/carbon/human/proc/nano_change_fitting in matched_verbs)
		aspects += "species fit used by worn clothing"
	return aspects.len ? "Can reshape itself during play, changing [english_list(aspects)]." : "Can alter its form during play."

/proc/custom_marking_add_species_verb_details(var/list/sections, var/datum/species/species, var/datum/species/baseline)
	if(!islist(sections) || !istype(species) || !istype(baseline))
		return FALSE
	var/list/species_verbs = islist(species.inherent_verbs) ? species.inherent_verbs : list()
	var/list/baseline_verbs = islist(baseline.inherent_verbs) ? baseline.inherent_verbs : list()
	var/list/handled_verbs = list()
	var/added = FALSE
	for(var/list/ability_def in custom_marking_species_verb_ability_defs())
		if(!islist(ability_def))
			continue
		var/list/ability_verbs = ability_def["verbs"]
		if(!islist(ability_verbs) || !ability_verbs.len)
			continue
		var/list/matched_verbs = list()
		for(var/verb_path in ability_verbs)
			if(!handled_verbs[verb_path] && (verb_path in species_verbs))
				matched_verbs |= verb_path
		if(!matched_verbs.len)
			continue
		if(ability_def["require_all"] && matched_verbs.len != ability_verbs.len)
			continue
		var/differs_from_baseline = FALSE
		for(var/verb_path in matched_verbs)
			handled_verbs[verb_path] = TRUE
			if(!(verb_path in baseline_verbs))
				differs_from_baseline = TRUE
		if(!differs_from_baseline)
			continue
		if(ability_def["omit_detail"])
			continue
		var/ability_id = ability_def["id"]
		var/description = ability_def["description"]
		var/section_id = ability_def["section"] || "abilities"
		var/section_title = ability_def["title"] || "Abilities & Restrictions"
		if(ability_id == "mutable-form")
			description = custom_marking_species_mutable_form_description(matched_verbs)
		custom_marking_add_species_detail_entry(
			sections,
			section_id,
			section_title,
			"species-ability-[ability_id]",
			ability_def["label"],
			"Available",
			null,
			description,
			"positive"
		)
		added = TRUE
	for(var/verb_path in species_verbs)
		if(handled_verbs[verb_path] || (verb_path in baseline_verbs))
			continue
		var/verb_label = capitalize(custom_marking_species_detail_path_label(verb_path))
		custom_marking_add_species_detail_entry(
			sections,
			"abilities",
			"Abilities & Restrictions",
			"species-verb-[verb_path]",
			verb_label,
			"Available",
			null,
			"Species-specific action granted on spawn.",
			"positive"
		)
		added = TRUE
	return added

/proc/custom_marking_species_detail_bitfield_names(var/value, var/list/flag_defs)
	var/list/names = list()
	var/flags = isnum(value) ? value : 0
	for(var/flag_name in flag_defs)
		var/flag_value = flag_defs[flag_name]
		if(flags & flag_value)
			names += flag_name
	return names.len ? english_list(names) : "None"

/proc/custom_marking_species_detail_path_label(var/value)
	if(!value)
		return "None"
	var/path_text = "[value]"
	var/proc_start = findtext(path_text, "/proc/")
	if(proc_start)
		path_text = copytext(path_text, proc_start + length("/proc/"))
	var/attack_start = findtext(path_text, "/datum/unarmed_attack/")
	if(attack_start)
		path_text = copytext(path_text, attack_start + length("/datum/unarmed_attack/"))
	var/list/path_parts = splittext(path_text, "/")
	if(path_parts.len)
		path_text = path_parts[path_parts.len]
	return replacetext(replacetext(path_text, "_", " "), "/", " ")

/proc/custom_marking_species_detail_list_label(var/value, var/path_labels = FALSE)
	if(isnull(value))
		return "None"
	var/list/labels = list()
	if(islist(value))
		var/list/value_list = value
		for(var/entry in value_list)
			if(path_labels)
				labels += custom_marking_species_detail_path_label(entry)
			else
				labels += replacetext("[entry]", "_", " ")
	else
		labels += path_labels ? custom_marking_species_detail_path_label(value) : replacetext("[value]", "_", " ")
	return labels.len ? english_list(labels) : "None"

/proc/custom_marking_species_detail_pressure(var/value, var/high_limit = FALSE, var/low_limit = FALSE)
	if(!isnum(value))
		return custom_marking_format_species_detail_value(value, "text")
	if(high_limit && value == INFINITY)
		return "No upper limit"
	if(low_limit && value < 0)
		return "No lower limit"
	return "[round(value, 0.1)] kPa"

/proc/custom_marking_species_detail_temperature(var/value, var/low_limit = FALSE)
	if(!isnum(value))
		return custom_marking_format_species_detail_value(value, "text")
	if(low_limit && value < 0)
		return "No lower limit"
	return "[round(value - T0C, 0.1)] C ([round(value, 0.1)] K)"

/proc/custom_marking_species_detail_movement_speed(var/value)
	if(!isnum(value))
		return "[value]"
	var/movement_delay_multiplier = 1 + value
	if(movement_delay_multiplier <= 0)
		return "Maximum speed boost"
	return "[round(1 / movement_delay_multiplier, 0.01)]x human speed"

/proc/custom_marking_species_detail_terrain_slowdown(var/value, var/human_slowdown)
	if(!isnum(value) || !isnum(human_slowdown) || human_slowdown <= 0)
		return "[value]"
	var/adjusted_slowdown = clamp(human_slowdown + value, -3, 15)
	if(adjusted_slowdown < 0)
		return "speed boost"
	if(adjusted_slowdown == 0)
		return "none"
	if(adjusted_slowdown == human_slowdown)
		return "normal"
	return "[round(100 * adjusted_slowdown / human_slowdown, 0.1)]% of human"

/proc/custom_marking_species_detail_water_movement(var/value)
	if(!isnum(value))
		return "[value]"
	var/shallow_slowdown = custom_marking_species_detail_terrain_slowdown(value, 4)
	var/deep_slowdown = custom_marking_species_detail_terrain_slowdown(value, 8)
	return "Shallow slowdown: [shallow_slowdown]; deep: [deep_slowdown]"

/proc/custom_marking_species_detail_snow_movement(var/value)
	if(!isnum(value))
		return "[value]"
	var/snow_slowdown = custom_marking_species_detail_terrain_slowdown(value, 2)
	if(snow_slowdown == "speed boost")
		return "Speed boost on snow"
	if(snow_slowdown == "none")
		return "No snow slowdown"
	if(snow_slowdown == "normal")
		return "Normal snow slowdown"
	return "[snow_slowdown] snow slowdown"

/proc/custom_marking_format_species_detail_value(var/value, var/format = "text", var/id = null)
	switch(format)
		if("bool")
			return value ? "Yes" : "No"
		if("presence")
			return isnull(value) ? "No" : "Yes"
	if(isnull(value))
		return "None"
	if(istext(value) && !length(value))
		return "None"
	switch(format)
		if("gas")
			return replacetext("[value]", "_", " ")
		if("path")
			return custom_marking_species_detail_path_label(value)
		if("path_list")
			return custom_marking_species_detail_list_label(value, TRUE)
		if("list")
			return custom_marking_species_detail_list_label(value)
		if("organs")
			return custom_marking_species_detail_list_label(value)
		if("pressure")
			return custom_marking_species_detail_pressure(value)
		if("pressure_high")
			return custom_marking_species_detail_pressure(value, TRUE)
		if("pressure_low")
			return custom_marking_species_detail_pressure(value, FALSE, TRUE)
		if("temperature")
			return custom_marking_species_detail_temperature(value)
		if("temperature_high")
			return custom_marking_species_detail_temperature(value)
		if("temperature_low")
			return custom_marking_species_detail_temperature(value, TRUE)
		if("movement_speed")
			return custom_marking_species_detail_movement_speed(value)
		if("water_movement")
			return custom_marking_species_detail_water_movement(value)
		if("snow_movement")
			return custom_marking_species_detail_snow_movement(value)
		if("multiplier")
			return isnum(value) ? "[round(value, 0.01)]x" : "[value]"
		if("tiles")
			return isnum(value) ? "[value] tile[value == 1 ? "" : "s"]" : "[value]"
		if("number")
			return isnum(value) ? "[round(value, 0.01)]" : "[value]"
		if("optional_number")
			if(!value)
				return "None"
			return isnum(value) ? "[round(value, 0.01)]" : "[value]"
		if("mob_size")
			switch(value)
				if(MOB_TINY)
					return "Tiny"
				if(MOB_SMALL)
					return "Small"
				if(MOB_MEDIUM)
					return "Medium"
				if(MOB_LARGE)
					return "Large"
				if(MOB_HUGE)
					return "Huge"
			return "[value]"
		if("species_flags")
			return custom_marking_species_detail_bitfield_names(value, list(
				"No minor cuts" = NO_MINOR_CUT,
				"Plantlike" = IS_PLANT,
				"No DNA scan" = NO_SCAN,
				"No pain" = NO_PAIN,
				"Surefooted" = NO_SLIP,
				"Poison immune" = NO_POISON,
				"No embedding" = NO_EMBED,
				"No hallucinations" = NO_HALLUCINATION,
				"No blood" = NO_BLOOD,
				"Undead" = UNDEAD,
				"No infection" = NO_INFECT,
				"No defibrillation" = NO_DEFIB
			))
		if("appearance_flags")
			return custom_marking_species_detail_bitfield_names(value, list(
				"Skin tone" = HAS_SKIN_TONE,
				"Skin color" = HAS_SKIN_COLOR,
				"Lips" = HAS_LIPS,
				"Underwear" = HAS_UNDERWEAR,
				"Eye color" = HAS_EYE_COLOR,
				"Hair color" = HAS_HAIR_COLOR
			))
		if("spawn_flags")
			return custom_marking_species_detail_bitfield_names(value, list(
				"Requires whitelist" = SPECIES_IS_WHITELISTED,
				"Restricted" = SPECIES_IS_RESTRICTED,
				"Can join" = SPECIES_CAN_JOIN,
				"Whitelist selectable" = SPECIES_WHITELIST_SELECTABLE
			))
		if("allergens")
			return custom_marking_species_detail_bitfield_names(value, list(
				"Meat" = ALLERGEN_MEAT,
				"Fish" = ALLERGEN_FISH,
				"Fruit" = ALLERGEN_FRUIT,
				"Vegetables" = ALLERGEN_VEGETABLE,
				"Grains" = ALLERGEN_GRAINS,
				"Beans" = ALLERGEN_BEANS,
				"Seeds" = ALLERGEN_SEEDS,
				"Dairy" = ALLERGEN_DAIRY,
				"Fungi" = ALLERGEN_FUNGI,
				"Coffee" = ALLERGEN_COFFEE,
				"Sugars" = ALLERGEN_SUGARS,
				"Eggs" = ALLERGEN_EGGS,
				"Stimulants" = ALLERGEN_STIMULANT,
				"Chocolate" = ALLERGEN_CHOCOLATE
			))
	return "[value]"

/proc/custom_marking_species_detail_var_differs(var/datum/species/species, var/datum/species/baseline, var/var_name)
	if(!istype(species) || !istype(baseline))
		return FALSE
	var/list/defs = custom_marking_species_detail_var_defs()
	var/list/def = defs[var_name]
	if(!islist(def))
		return FALSE
	var/value = species.vars[var_name]
	var/baseline_value = baseline.vars[var_name]
	if(!custom_marking_species_detail_value_differs(value, baseline_value))
		return FALSE
	var/format = def["format"] || "text"
	return custom_marking_format_species_detail_value(value, format, var_name) != custom_marking_format_species_detail_value(baseline_value, format, var_name)

/proc/custom_marking_add_species_var_detail(var/list/sections, var/datum/species/species, var/datum/species/baseline, var/var_name)
	if(!istype(species) || !istype(baseline))
		return FALSE
	if(var_name == "flags")
		return custom_marking_add_species_flag_details(sections, species, baseline)
	if(var_name == "inherent_verbs")
		return custom_marking_add_species_verb_details(sections, species, baseline)
	if(var_name == "reagent_tag")
		return custom_marking_add_species_reagent_details(sections, species)
	var/list/defs = custom_marking_species_detail_var_defs()
	var/list/def = defs[var_name]
	if(!islist(def))
		return FALSE
	var/value = species.vars[var_name]
	var/baseline_value = baseline.vars[var_name]
	if(!custom_marking_species_detail_var_differs(species, baseline, var_name))
		return FALSE
	var/format = def["format"] || "text"
	var/formatted_value = custom_marking_format_species_detail_value(value, format, var_name)
	var/severity = def["severity"]
	if(formatted_value == "None" && istext(def["none_severity"]))
		severity = def["none_severity"]
	else if(isnum(value) && value == 0 && istext(def["zero_severity"]))
		severity = def["zero_severity"]
	else if(isnum(value) && isnum(baseline_value))
		var/permissive_direction = def["permissive_direction"]
		if(permissive_direction == "lower")
			severity = value < baseline_value ? "positive" : "critical"
		else if(permissive_direction == "higher")
			severity = value > baseline_value ? "positive" : "critical"
		else if(value < baseline_value && istext(def["lower_severity"]))
			severity = def["lower_severity"]
		else if(value > baseline_value && istext(def["higher_severity"]))
			severity = def["higher_severity"]
	custom_marking_add_species_detail_entry(
		sections,
		def["section"],
		def["title"],
		var_name,
		def["label"],
		formatted_value,
		custom_marking_format_species_detail_value(baseline_value, format, var_name),
		def["description"],
		severity
	)
	return TRUE

/proc/custom_marking_add_species_trait_details(var/list/sections, var/list/trait_source)
	if(!islist(trait_source) || !trait_source.len)
		return
	for(var/trait_path in trait_source)
		var/datum/trait/T = all_traits?[trait_path]
		if(!istype(T))
			continue
		custom_marking_add_species_detail_entry(
			sections,
			"abilities",
			"Abilities & Restrictions",
			"trait-[trait_path]",
			T.name,
			"Selected",
			null,
			T.desc,
			"positive"
		)

/proc/custom_marking_append_species_detail_notes(var/list/sections, var/list/notes)
	if(!islist(notes) || !notes.len)
		return
	for(var/list/note in notes)
		if(!islist(note))
			continue
		custom_marking_add_species_detail_entry(
			sections,
			note["section"] || "abilities",
			note["title"] || "Abilities & Restrictions",
			note["id"] || note["label"],
			note["label"],
			note["value"],
			note["baseline_value"],
			note["description"],
			note["severity"]
		)

/proc/custom_marking_build_species_detail_sections(var/datum/species/species, var/mob/user = null, var/list/trait_source = null, include_notes = TRUE)
	var/list/sections = list()
	if(!istype(species))
		return sections
	var/datum/species/baseline = GLOB.all_species?[SPECIES_HUMAN]
	if(!istype(baseline))
		return sections
	custom_marking_add_species_language_details(sections, species)
	custom_marking_add_species_unassisted_language_detail(sections, species, baseline)
	var/list/defs = custom_marking_species_detail_var_defs()
	for(var/var_name in defs)
		custom_marking_add_species_var_detail(sections, species, baseline, var_name)
	if(isnull(trait_source))
		trait_source = species.traits
	custom_marking_add_species_trait_details(sections, trait_source)
	if(include_notes)
		custom_marking_append_species_detail_notes(sections, species.get_species_detail_notes(user))
	return sections

/datum/tgui_module/custom_marking_designer/proc/build_species_modifier_entries(datum/species/species)
	if(!istype(species))
		return list()
	var/static/list/modifier_defs = list(
		"brute_mod" = list("label" = "Brute Damage", "description" = "Physical damage multiplier."),
		"burn_mod" = list("label" = "Burn Damage", "description" = "Burn damage multiplier."),
		"oxy_mod" = list("label" = "Oxygen Loss", "description" = "Oxygen loss modifier."),
		"toxins_mod" = list("label" = "Toxin Damage", "description" = "Toxin damage modifier."),
		"radiation_mod" = list("label" = "Radiation Damage", "description" = "Radiation damage modifier."),
		"flash_mod" = list("label" = "Flash Stun", "description" = "Flash/flashbang stun multiplier."),
		"flash_burn" = list("label" = "Flash Burn", "description" = "Burn damage from being flashed."),
		"sound_mod" = list("label" = "Flashbang Range", "description" = "Flashbang range multiplier."),
		"pain_mod" = list("label" = "Pain Effects", "description" = "Pain effects multiplier."),
		"spice_mod" = list("label" = "Spice Effects", "description" = "Spice/capsaicin effects multiplier."),
		"trauma_mod" = list("label" = "Traumatic Shock", "description" = "Traumatic shock multiplier."),
		"chem_strength_heal" = list("label" = "Healing Chems", "description" = "Healing chem strength multiplier."),
		"chem_strength_pain" = list("label" = "Painkillers", "description" = "Painkiller strength multiplier."),
		"chem_strength_tox" = list("label" = "Toxic Chems", "description" = "Toxic chem strength multiplier."),
		"chem_strength_alcohol" = list("label" = "Alcohol Strength", "description" = "Alcohol strength multiplier."),
		"chemOD_threshold" = list("label" = "Overdose Threshold", "description" = "Overdose threshold multiplier."),
		"chemOD_mod" = list("label" = "Overdose Damage", "description" = "Overdose damage multiplier."),
		"hunger_factor" = list("label" = "Hunger Rate", "description" = "Hunger rate multiplier."),
		"bloodloss_rate" = list("label" = "Bleeding Rate", "description" = "Bleeding rate multiplier."),
		"total_health" = list("label" = "Total Health", "description" = "Total health pool."),
		"slowdown" = list("label" = "Movement Speed", "description" = "Movement speed modifier."),
		"item_slowdown_mod" = list("label" = "Item Slowdown", "description" = "Item slowdown multiplier."),
		"water_movement" = list("label" = "Water Movement", "description" = "Water movement modifier."),
		"snow_movement" = list("label" = "Snow Movement", "description" = "Snow movement modifier."),
		"emp_dmg_mod" = list("label" = "EMP Damage", "description" = "EMP damage multiplier."),
		"emp_stun_mod" = list("label" = "EMP Stun", "description" = "EMP stun/disorient multiplier.")
	)
	var/list/modifiers = list()
	for(var/mod_key in modifier_defs)
		var/list/def = modifier_defs[mod_key]
		if(!islist(def))
			continue
		var/value = species.vars[mod_key]
		if(isnull(value))
			continue
		if(!isnum(value) && !istext(value))
			continue
		modifiers += list(list(
			"id" = mod_key,
			"label" = def["label"],
			"description" = def["description"],
			"value" = value
		))
	return modifiers

/datum/tgui_module/custom_marking_designer/proc/build_species_trait_entries(datum/species/species)
	if(!istype(species))
		return list()
	var/list/traits = list()
	if(!islist(species.has_organ) || !species.has_organ[O_HEART])
		traits += list(list("name" = "No Heart", "description" = "Does not have a circulatory system."))
	if(!islist(species.has_organ) || !species.has_organ[O_LUNGS])
		traits += list(list("name" = "No Lungs", "description" = "Does not have a respiratory system."))
	if(species.flags & NO_SCAN)
		traits += list(list("name" = "No DNA", "description" = "Does not have DNA."))
	if(species.flags & NO_DEFIB)
		traits += list(list("name" = "No Defibrillation", "description" = "Cannot be defibrillated."))
	if(species.flags & NO_PAIN)
		traits += list(list("name" = "No Pain", "description" = "Does not feel pain."))
	if(species.flags & NO_SLIP)
		traits += list(list("name" = "Surefooted", "description" = "Has excellent traction."))
	if(species.flags & NO_POISON)
		traits += list(list("name" = "Poison Immune", "description" = "Immune to most poisons."))
	if(species.flags & IS_PLANT)
		traits += list(list("name" = "Plantlike", "description" = "Has a plantlike physiology."))
	if(species.appearance_flags & HAS_SKIN_TONE)
		traits += list(list("name" = "Skin Tone Options", "description" = "Has a variety of skin tones."))
	if(species.appearance_flags & HAS_SKIN_COLOR)
		traits += list(list("name" = "Skin Color Options", "description" = "Has a variety of skin colors."))
	if(species.appearance_flags & HAS_EYE_COLOR)
		traits += list(list("name" = "Eye Color Options", "description" = "Has a variety of eye colors."))
	var/list/trait_source = islist(species.traits) ? species.traits : list()
	if(islist(trait_source) && trait_source.len)
		for(var/trait_path in trait_source)
			var/datum/trait/T = all_traits?[trait_path]
			if(!istype(T))
				continue
			traits += list(list(
				"id" = "[trait_path]",
				"name" = T.name,
				"description" = T.desc
			))
	return traits

/datum/tgui_module/custom_marking_designer/proc/is_species_selectable(mob/user, datum/species/species)
	if(!istype(species))
		return FALSE
	if(check_rights(R_ADMIN|R_EVENT, 0, user))
		return TRUE
	if(species.spawn_flags & SPECIES_WHITELIST_SELECTABLE)
		return TRUE
	if(!(species.spawn_flags & SPECIES_CAN_JOIN))
		return FALSE
	return is_alien_whitelisted(user, species)

/datum/tgui_module/custom_marking_designer/proc/resolve_species_restriction_reason(mob/user, datum/species/species)
	if(!istype(species))
		return "Unavailable."
	if(check_rights(R_ADMIN|R_EVENT, 0, user))
		return null
	if(species.spawn_flags & SPECIES_WHITELIST_SELECTABLE)
		return null
	if(!(species.spawn_flags & SPECIES_CAN_JOIN))
		return "Not available for play as a station species."
	if(!(is_alien_whitelisted(user, species)))
		return "Requires whitelist approval."
	return null

/datum/tgui_module/custom_marking_designer/proc/resolve_species_preview_fallback_icon(species_id)
	switch(species_id)
		if(SPECIES_HUMAN, SPECIES_ALRAUNE)
			return 'icons/mob/human_races/r_human.dmi'
	return null

/datum/tgui_module/custom_marking_designer/proc/should_build_species_preview_from_parts(species_id)
	return species_id == SPECIES_ZADDAT

/datum/tgui_module/custom_marking_designer/proc/build_species_preview_from_parts(icon_source)
	if(!icon_source)
		return null
	var/list/icon_states = cached_icon_states(icon_source)
	if(!islist(icon_states))
		return null
	var/list/part_states = list("torso_m", "groin_m", "head_m", "l_arm", "r_arm", "l_leg", "r_leg", "l_hand", "r_hand", "l_foot", "r_foot")
	if(!(part_states[1] in icon_states))
		return null
	var/icon/preview_icon = icon(icon_source, part_states[1], SOUTH)
	if(!isicon(preview_icon))
		return null
	for(var/i = 2 to part_states.len)
		var/part_state = part_states[i]
		if(!(part_state in icon_states))
			continue
		var/icon/part_icon = icon(icon_source, part_state, SOUTH)
		if(isicon(part_icon))
			preview_icon.Blend(part_icon, ICON_OVERLAY)
	return preview_icon

/datum/tgui_module/custom_marking_designer/proc/resolve_species_body_preview_base(species_id, preview_icon_base = null)
	if(!istext(species_id) || !length(species_id))
		return null
	var/datum/species/species = GLOB.all_species?[species_id]
	if(!istype(species))
		return null
	if(istext(preview_icon_base) && length(preview_icon_base))
		var/datum/species/preview_species = GLOB.all_species?[preview_icon_base]
		if(istype(preview_species))
			return preview_icon_base
	if(species.selects_bodytype && istext(species.base_species) && length(species.base_species))
		var/datum/species/base_species = GLOB.all_species?[species.base_species]
		if(istype(base_species))
			return species.base_species
	return species_id

/datum/tgui_module/custom_marking_designer/proc/resolve_species_allowed_biological_gender(datum/species/species, biological_gender)
	if(!istype(species) || !islist(species.genders) || !species.genders.len)
		return biological_gender
	if(biological_gender in species.genders)
		return biological_gender
	return species.genders[1]

/datum/tgui_module/custom_marking_designer/proc/resolve_species_body_preview_gender_suffix(datum/species/preview_species, biological_gender = null)
	if(isnull(biological_gender))
		biological_gender = prefs?.biological_gender
	biological_gender = resolve_species_allowed_biological_gender(preview_species, biological_gender)
	return biological_gender == FEMALE ? "f" : "m"

/datum/tgui_module/custom_marking_designer/proc/build_base_biological_gender_options()
	var/datum/species/selected_species = GLOB.all_species?[prefs?.species]
	var/list/possible_genders = list(MALE, FEMALE)
	if(istype(selected_species) && islist(selected_species.genders) && selected_species.genders.len)
		possible_genders = selected_species.genders.Copy()
	return possible_genders

/datum/tgui_module/custom_marking_designer/proc/build_basic_biological_gender_options(list/base_genders = null)
	var/list/possible_genders = islist(base_genders) && base_genders.len ? base_genders.Copy() : build_base_biological_gender_options()
	if(prefs?.organ_data?[BP_TORSO] == "cyborg")
		possible_genders |= NEUTER
	return possible_genders

/datum/tgui_module/custom_marking_designer/proc/resolve_basic_biological_gender(list/possible_genders, biological_gender)
	if(!islist(possible_genders) || !possible_genders.len)
		return biological_gender
	if(biological_gender in possible_genders)
		return biological_gender
	return possible_genders[1]

/datum/tgui_module/custom_marking_designer/proc/resolve_basic_alternate_preview_gender(list/possible_genders, biological_gender)
	var/datum/species/selected_species = GLOB.all_species?[prefs?.species]
	var/current_suffix = resolve_species_body_preview_gender_suffix(selected_species, biological_gender)
	for(var/possible_gender in possible_genders)
		if(resolve_species_body_preview_gender_suffix(selected_species, possible_gender) != current_suffix)
			return possible_gender
	return null

/datum/tgui_module/custom_marking_designer/proc/species_body_preview_cache_key(species_id, preview_icon_base = null, gender_suffix = "m", digitigrade = FALSE)
	var/base_id = resolve_species_body_preview_base(species_id, preview_icon_base)
	if(!base_id)
		return null
	var/normalized_gender = gender_suffix == "f" ? "f" : "m"
	var/digitigrade_label = digitigrade ? "digi" : "normal"
	return "[species_id]|[base_id]|[normalized_gender]|[digitigrade_label]"

/datum/tgui_module/custom_marking_designer/proc/preview_part_is_runtime_underlay(icon_position, dir)
	if(!isnum(icon_position))
		return FALSE
	if(icon_position & (LEFT | RIGHT))
		return (dir == EAST && (icon_position & LEFT)) || (dir == WEST && (icon_position & RIGHT))
	return !!(icon_position & UNDER)

/datum/tgui_module/custom_marking_designer/proc/build_static_species_part_order(datum/species/species, dir = SOUTH)
	if(!istype(species) || !islist(species.has_limbs))
		return null
	var/list/underlay_order = list()
	var/list/overlay_order = list()
	if(BP_TORSO in species.has_limbs)
		overlay_order += BP_TORSO
	for(var/part_id in species.has_limbs)
		if(part_id == BP_TORSO)
			continue
		var/list/organ_data = species.has_limbs[part_id]
		var/limb_path = organ_data?["path"]
		var/icon_position = 0
		if(ispath(limb_path, /obj/item/organ/external))
			var/obj/item/organ/external/limb_template = limb_path
			icon_position = initial(limb_template.icon_position)
		if(preview_part_is_runtime_underlay(icon_position, dir))
			// Runtime applies each underlay beneath the composite built so far.
			underlay_order.Insert(1, part_id)
		else
			overlay_order += part_id
	underlay_order += overlay_order
	return underlay_order

/datum/tgui_module/custom_marking_designer/proc/normalize_digitigrade_preview_part_icon(icon/part_icon, should_normalize = FALSE)
	if(!isicon(part_icon) || !should_normalize)
		return part_icon
	var/icon/normalized_part_icon = icon('icons/effects/effects.dmi', "nothing", null, 1, 0)
	normalized_part_icon.Blend(part_icon, ICON_OVERLAY)
	return normalized_part_icon

/datum/tgui_module/custom_marking_designer/proc/resolve_static_species_part_frame(datum/species/species, part_id, gender_suffix = "m", digitigrade = FALSE)
	if(!istype(species) || !istext(part_id) || !length(part_id))
		return null
	if(!islist(species.has_limbs) || !(part_id in species.has_limbs))
		return null
	var/list/organ_data = species.has_limbs[part_id]
	if(!islist(organ_data))
		return null
	var/limb_path = organ_data["path"]
	if(!ispath(limb_path, /obj/item/organ/external))
		return null
	var/obj/item/organ/external/limb_template = limb_path
	var/icon_name = initial(limb_template.icon_name)
	if(!istext(icon_name) || !length(icon_name))
		return null
	var/is_digitigrade_part = ispath(limb_path, /obj/item/organ/external/leg) || ispath(limb_path, /obj/item/organ/external/foot)
	var/icon_source = (digitigrade && is_digitigrade_part && species.icodigi) ? species.icodigi : species.icobase
	if(!icon_source)
		return null
	var/list/state_list = cached_icon_states(icon_source)
	if(!islist(state_list) || !state_list.len)
		return null
	var/state_name = icon_name
	if(initial(limb_template.gendered_icon))
		var/normalized_gender = gender_suffix == "f" ? "f" : "m"
		var/gendered_state = "[icon_name]_[normalized_gender]"
		if(gendered_state in state_list)
			state_name = gendered_state
	if(!(state_name in state_list))
		return null
	return list(
		"source" = icon_source,
		"state" = state_name,
		"normalize_digitigrade" = digitigrade && is_digitigrade_part
	)

/datum/tgui_module/custom_marking_designer/proc/build_static_species_part_icon(datum/species/species, part_id, dir, gender_suffix = "m", digitigrade = FALSE, return_transparent = FALSE, list/build_metadata = null)
	if(islist(build_metadata))
		build_metadata["intentionally_transparent"] = FALSE
	var/list/frame = resolve_static_species_part_frame(species, part_id, gender_suffix, digitigrade)
	if(!islist(frame))
		return null
	var/icon_source = frame["source"]
	var/state_name = frame["state"]
	var/icon/part_icon = icon(icon_source, state_name, dir, 1, 0)
	if(!isicon(part_icon))
		return null
	part_icon = normalize_digitigrade_preview_part_icon(part_icon, !!frame["normalize_digitigrade"])
	if(!icon_has_visible_pixels(part_icon, "[icon_source]|[state_name]|[dir]"))
		if(islist(build_metadata))
			build_metadata["intentionally_transparent"] = TRUE
		if(!return_transparent)
			return null
	return part_icon

/datum/tgui_module/custom_marking_designer/proc/build_static_species_part_asset(datum/species/species, part_id, dir, gender_suffix = "m", digitigrade = FALSE, normalize_transparent = FALSE)
	var/list/frame = resolve_static_species_part_frame(species, part_id, gender_suffix, digitigrade)
	if(!islist(frame))
		return null
	var/preprocessing = frame["normalize_digitigrade"] ? "digitigrade-canvas" : "raw"
	if(normalize_transparent)
		preprocessing = "[preprocessing]+transparent-luminance"
	var/canonical_key = build_static_icon_canonical_key(frame["source"], frame["state"], dir, preprocessing)
	var/list/cached_payload = find_static_icon_asset(canonical_key, "anatomy")
	if(islist(cached_payload))
		return cached_payload
	var/icon/part_icon = build_static_species_part_icon(species, part_id, dir, gender_suffix, digitigrade)
	if(!isicon(part_icon))
		return null
	if(normalize_transparent)
		part_icon = normalize_static_transparent_species_part_icon(part_icon)
	return build_icon_asset(part_icon, canonical_key, "anatomy")

/datum/tgui_module/custom_marking_designer/proc/resolve_static_species_part_hair_frame(datum/species/species, part_id)
	if(!istype(species) || !istext(part_id) || !length(part_id))
		return null
	var/list/organ_data = species.has_limbs?[part_id]
	var/limb_path = organ_data?["path"]
	if(!ispath(limb_path, /obj/item/organ/external) || !species.icobase)
		return null
	var/obj/item/organ/external/limb_template = limb_path
	var/icon_name = initial(limb_template.icon_name)
	var/body_hair = initial(limb_template.body_hair)
	if(!istext(icon_name) || !length(icon_name) || !istext(body_hair) || !length(body_hair))
		return null
	var/state_name = "[icon_name]_[body_hair]"
	var/list/state_list = cached_icon_states(species.icobase)
	if(!islist(state_list) || !(state_name in state_list))
		return null
	return list(
		"source" = species.icobase,
		"state" = state_name
	)

/datum/tgui_module/custom_marking_designer/proc/build_static_species_part_hair_icon(datum/species/species, part_id, dir, return_transparent = FALSE, list/build_metadata = null)
	if(islist(build_metadata))
		build_metadata["intentionally_transparent"] = FALSE
	var/list/frame = resolve_static_species_part_hair_frame(species, part_id)
	if(!islist(frame))
		return null
	var/icon_source = frame["source"]
	var/state_name = frame["state"]
	var/icon/hair_icon = icon(icon_source, state_name, dir, 1, 0)
	if(!isicon(hair_icon))
		return null
	if(!icon_has_visible_pixels(hair_icon, "[icon_source]|[state_name]|[dir]|body-hair"))
		if(islist(build_metadata))
			build_metadata["intentionally_transparent"] = TRUE
		if(!return_transparent)
			return null
	return hair_icon

/datum/tgui_module/custom_marking_designer/proc/build_static_species_part_hair_asset(datum/species/species, part_id, dir)
	var/list/frame = resolve_static_species_part_hair_frame(species, part_id)
	if(!islist(frame))
		return null
	var/canonical_key = build_static_icon_canonical_key(frame["source"], frame["state"], dir, "body-hair-raw")
	var/list/cached_payload = find_static_icon_asset(canonical_key, "anatomy")
	if(islist(cached_payload))
		return cached_payload
	var/icon/hair_icon = build_static_species_part_hair_icon(species, part_id, dir)
	if(!isicon(hair_icon))
		return null
	return build_icon_asset(hair_icon, canonical_key, "anatomy")

/datum/tgui_module/custom_marking_designer/proc/resolve_static_prosthetic_part_frame(datum/species/species, datum/robolimb/prosthetic, part_id, gender_suffix = "m")
	if(!istype(species) || !istype(prosthetic) || !istext(part_id) || !length(part_id))
		return null
	if(!islist(prosthetic.parts) || !(part_id in prosthetic.parts))
		return null
	var/list/organ_data = species.has_limbs?[part_id]
	var/limb_path = organ_data?["path"]
	if(!ispath(limb_path, /obj/item/organ/external) || !prosthetic.icon)
		return null
	var/obj/item/organ/external/limb_template = limb_path
	var/state_name = initial(limb_template.icon_name)
	if(!istext(state_name) || !length(state_name))
		return null
	var/list/state_list = cached_icon_states(prosthetic.icon)
	if(!islist(state_list) || !state_list.len)
		return null
	if(initial(limb_template.gendered_icon))
		var/normalized_gender = gender_suffix == "f" ? "f" : "m"
		var/gendered_state = "[state_name]_[normalized_gender]"
		if(gendered_state in state_list)
			state_name = gendered_state
	if(!(state_name in state_list))
		return null
	return list(
		"source" = prosthetic.icon,
		"state" = state_name
	)

/datum/tgui_module/custom_marking_designer/proc/build_static_prosthetic_part_asset(datum/species/species, datum/robolimb/prosthetic, part_id, dir, gender_suffix = "m")
	var/list/frame = resolve_static_prosthetic_part_frame(species, prosthetic, part_id, gender_suffix)
	if(!islist(frame))
		return null
	var/canonical_key = build_static_icon_canonical_key(frame["source"], frame["state"], dir, "prosthetic-raw")
	var/datum/asset/spritesheet/custom_marking_designer/atlas = get_asset_datum(/datum/asset/spritesheet/custom_marking_designer)
	var/full_key = "[canonical_key]|shift:0,0"
	var/list/cached_payload = atlas.get_icon_asset(full_key)
	if(islist(cached_payload))
		if(use_shared_atlas && atlas.can_accept_assets())
			return atlas.note_icon_asset_request(full_key, "anatomy")
		return cached_payload
	if(!use_shared_atlas || !atlas.can_accept_assets())
		return null
	var/icon/prosthetic_icon = icon(frame["source"], frame["state"], dir, 1, 0)
	if(!isicon(prosthetic_icon) || !icon_has_visible_pixels(prosthetic_icon, "[canonical_key]|visible"))
		return null
	return build_icon_asset(prosthetic_icon, canonical_key, "anatomy")

/datum/tgui_module/custom_marking_designer/proc/is_static_prosthetic_part_intentionally_transparent(datum/species/species, datum/robolimb/prosthetic, part_id, dir, gender_suffix = "m")
	var/list/frame = resolve_static_prosthetic_part_frame(species, prosthetic, part_id, gender_suffix)
	if(!islist(frame))
		return FALSE
	var/canonical_key = build_static_icon_canonical_key(frame["source"], frame["state"], dir, "prosthetic-raw")
	if(!istext(canonical_key) || !length(canonical_key))
		return FALSE
	if(islist(custom_marking_visible_pixel_cache) && (canonical_key in custom_marking_visible_pixel_cache))
		return !custom_marking_visible_pixel_cache[canonical_key]
	var/icon/prosthetic_icon = icon(frame["source"], frame["state"], dir, 1, 0)
	return isicon(prosthetic_icon) && !icon_has_visible_pixels(prosthetic_icon, canonical_key)

/datum/tgui_module/custom_marking_designer/proc/is_static_prosthetic_state_intentionally_transparent(icon_source, state_name, dir)
	var/canonical_key = build_static_icon_canonical_key(icon_source, state_name, dir, "prosthetic-raw")
	if(!istext(canonical_key) || !length(canonical_key))
		return FALSE
	if(islist(custom_marking_visible_pixel_cache) && (canonical_key in custom_marking_visible_pixel_cache))
		return !custom_marking_visible_pixel_cache[canonical_key]
	var/icon/prosthetic_icon = icon(icon_source, state_name, dir, 1, 0)
	return isicon(prosthetic_icon) && !icon_has_visible_pixels(prosthetic_icon, canonical_key)

/datum/tgui_module/custom_marking_designer/proc/build_static_prosthetic_gallery_state_profile(datum/species/species, gender_suffix = "m")
	if(!istype(species) || !islist(species.has_limbs))
		return null
	var/list/profile = list()
	var/normalized_gender = gender_suffix == "f" ? "f" : "m"
	for(var/part_id in BP_ALL)
		var/list/organ_data = species.has_limbs[part_id]
		var/limb_path = organ_data?["path"]
		if(!ispath(limb_path, /obj/item/organ/external))
			return null
		var/obj/item/organ/external/limb_template = limb_path
		var/state_name = initial(limb_template.icon_name)
		if(!istext(state_name) || !length(state_name))
			return null
		var/list/state_entry = list("state" = state_name)
		if(initial(limb_template.gendered_icon))
			state_entry["gendered_state"] = "[state_name]_[normalized_gender]"
		profile[part_id] = state_entry
	return profile

/datum/tgui_module/custom_marking_designer/proc/build_static_prosthetic_gallery_profile_key(list/profile)
	if(!islist(profile))
		return null
	var/list/key_parts = list("profile-v1")
	for(var/part_id in BP_ALL)
		var/list/state_entry = profile[part_id]
		var/state_name = state_entry?["state"]
		var/gendered_state = state_entry?["gendered_state"]
		if(!istext(state_name) || !length(state_name))
			return null
		key_parts += "[part_id]=[gendered_state ? gendered_state : state_name]~[state_name]"
	return key_parts.Join("|")

/datum/tgui_module/custom_marking_designer/proc/resolve_static_prosthetic_gallery_state_name(list/profile, part_id, list/icon_state_names)
	var/list/state_entry = profile?[part_id]
	if(!islist(state_entry) || !islist(icon_state_names))
		return null
	var/gendered_state = state_entry["gendered_state"]
	if(istext(gendered_state) && length(gendered_state) && (gendered_state in icon_state_names))
		return gendered_state
	var/state_name = state_entry["state"]
	return istext(state_name) && length(state_name) && (state_name in icon_state_names) ? state_name : null

/datum/tgui_module/custom_marking_designer/proc/build_static_prosthetic_gallery_composite_key(list/resolved_states)
	if(!islist(resolved_states))
		return null
	var/list/key_parts = list("gallery-v1")
	for(var/part_id in BP_ALL)
		var/state_name = resolved_states[part_id]
		if(!istext(state_name) || !length(state_name))
			return null
		key_parts += "[part_id]=[state_name]"
	return key_parts.Join("|")

/datum/tgui_module/custom_marking_designer/proc/is_static_prosthetic_full_body_model(datum/robolimb/prosthetic)
	if(!istype(prosthetic) || !islist(prosthetic.parts))
		return FALSE
	for(var/part_id in BP_ALL)
		if(!(part_id in prosthetic.parts))
			return FALSE
	return TRUE

/datum/tgui_module/custom_marking_designer/proc/build_static_prosthetic_gallery_composite_asset(datum/robolimb/prosthetic, list/resolved_states, composite_key, dir)
	if(!istype(prosthetic) || !prosthetic.icon || !islist(resolved_states) || !istext(composite_key) || !length(composite_key))
		return null
	var/source_digest = custom_marking_static_source_digest(prosthetic.icon)
	if(!istext(source_digest) || !length(source_digest))
		return null
	var/canonical_key = "prosthetic-gallery-composite-v1|[prosthetic.icon]|content:[source_digest]|[composite_key]|[dir]"
	var/list/cached_payload = find_static_icon_asset(canonical_key, "anatomy")
	if(islist(cached_payload))
		return cached_payload
	var/icon/composite = icon('icons/effects/effects.dmi', "nothing", null, 1, 0)
	for(var/part_id in BP_ALL)
		var/state_name = resolved_states[part_id]
		var/icon/part_icon = icon(prosthetic.icon, state_name, dir, 1, 0)
		if(!isicon(part_icon))
			return null
		composite.Blend(part_icon, ICON_OVERLAY)
	if(!icon_has_visible_pixels(composite, canonical_key))
		return null
	return build_icon_asset(composite, canonical_key, "anatomy")

/datum/tgui_module/custom_marking_designer/proc/prewarm_static_prosthetic_preview_assets()
	if(!use_shared_atlas || !islist(chargen_robolimbs) || !chargen_robolimbs.len || !islist(GLOB.all_species))
		return FALSE
	var/datum/asset/spritesheet/custom_marking_designer/atlas = get_asset_datum(/datum/asset/spritesheet/custom_marking_designer)
	if(!atlas.can_accept_assets() && !atlas.is_persistent_cache_validation_pending())
		return FALSE
	var/list/state_names_by_part = list()
	var/list/gallery_state_profiles = list()
	for(var/species_id in GLOB.all_species)
		var/datum/species/species = GLOB.all_species[species_id]
		if(!istype(species) || !islist(species.has_limbs))
			continue
		for(var/part_id in BP_ALL)
			var/list/organ_data = species.has_limbs[part_id]
			var/limb_path = organ_data?["path"]
			if(!ispath(limb_path, /obj/item/organ/external))
				continue
			var/obj/item/organ/external/limb_template = limb_path
			var/state_name = initial(limb_template.icon_name)
			if(!istext(state_name) || !length(state_name))
				continue
			var/list/part_state_names = state_names_by_part[part_id]
			if(!islist(part_state_names))
				part_state_names = list()
				state_names_by_part[part_id] = part_state_names
			part_state_names[state_name] = TRUE
			if(initial(limb_template.gendered_icon))
				part_state_names["[state_name]_m"] = TRUE
				part_state_names["[state_name]_f"] = TRUE
		for(var/gender_suffix in list("m", "f"))
			var/list/profile = build_static_prosthetic_gallery_state_profile(species, gender_suffix)
			var/profile_key = build_static_prosthetic_gallery_profile_key(profile)
			if(istext(profile_key) && length(profile_key))
				gallery_state_profiles[profile_key] = profile
	var/list/catalog_models = list()
	for(var/company in chargen_robolimbs)
		CUSTOM_MARKING_CHECK_TICK
		var/datum/robolimb/prosthetic = chargen_robolimbs[company]
		if(!istype(prosthetic) || !prosthetic.icon || !islist(prosthetic.parts))
			continue
		var/list/prosthetic_parts = prosthetic.parts
		var/list/icon_state_names = cached_icon_states(prosthetic.icon)
		if(!islist(icon_state_names) || !icon_state_names.len)
			continue
		var/list/state_names = list()
		for(var/part_id in prosthetic_parts)
			var/list/part_state_names = state_names_by_part[part_id]
			if(!islist(part_state_names))
				continue
			for(var/state_name in part_state_names)
				if(state_name in icon_state_names)
					state_names[state_name] = TRUE
		if(prosthetic.includes_tail && ("tail" in icon_state_names))
			state_names["tail"] = TRUE
		if(prosthetic.includes_ears && ("ears" in icon_state_names))
			state_names["ears"] = TRUE
		if(prosthetic.includes_wing && ("wing" in icon_state_names))
			state_names["wing"] = TRUE
		var/list/catalog_states = list()
		for(var/state_name in state_names)
			var/list/directional_assets = list()
			var/list/transparent_dirs = list()
			for(var/dir in list(NORTH, SOUTH, EAST, WEST))
				CUSTOM_MARKING_CHECK_TICK
				var/list/asset = build_static_source_icon_asset(prosthetic.icon, state_name, dir, "anatomy", "prosthetic-raw")
				var/reference = get_static_icon_asset_reference(asset)
				if(reference)
					directional_assets["[dir]"] = reference
				else if(is_static_prosthetic_state_intentionally_transparent(prosthetic.icon, state_name, dir))
					transparent_dirs += dir
			if(directional_assets.len || transparent_dirs.len)
				catalog_states[state_name] = list(
					"assets" = directional_assets,
					"transparent_dirs" = transparent_dirs
				)
		var/list/gallery_composites = list()
		if(is_static_prosthetic_full_body_model(prosthetic))
			var/list/resolved_profiles = list()
			for(var/profile_key in gallery_state_profiles)
				var/list/profile = gallery_state_profiles[profile_key]
				var/list/resolved_states = list()
				for(var/part_id in BP_ALL)
					var/resolved_state = resolve_static_prosthetic_gallery_state_name(profile, part_id, icon_state_names)
					if(!resolved_state)
						resolved_states = null
						break
					resolved_states[part_id] = resolved_state
				var/composite_key = build_static_prosthetic_gallery_composite_key(resolved_states)
				if(istext(composite_key) && length(composite_key))
					resolved_profiles[composite_key] = resolved_states
			for(var/composite_key in resolved_profiles)
				var/list/resolved_states = resolved_profiles[composite_key]
				var/list/directional_assets = list()
				for(var/dir in list(NORTH, SOUTH, EAST, WEST))
					CUSTOM_MARKING_CHECK_TICK
					var/list/asset = build_static_prosthetic_gallery_composite_asset(prosthetic, resolved_states, composite_key, dir)
					var/reference = get_static_icon_asset_reference(asset)
					if(reference)
						directional_assets["[dir]"] = reference
				if(directional_assets.len == 4)
					gallery_composites[composite_key] = list("assets" = directional_assets)
		var/list/model_entry = list(
			"id" = company,
			"name" = company,
			"description" = prosthetic.desc,
			"parts" = prosthetic_parts.Copy(),
			"skin_tone" = !!prosthetic.skin_tone,
			"skin_color" = !!prosthetic.skin_color,
			"can_be_digitigrade" = !!prosthetic.can_be_digitigrade,
			"includes_tail" = !!prosthetic.includes_tail,
			"includes_ears" = !!prosthetic.includes_ears,
			"includes_wing" = !!prosthetic.includes_wing,
			"states" = catalog_states
		)
		if(gallery_composites.len)
			model_entry["gallery_composites"] = gallery_composites
		catalog_models[company] = model_entry
	if(!atlas.set_prosthetic_catalog(list("models" = catalog_models)))
		return FALSE
	return TRUE

/datum/tgui_module/custom_marking_designer/proc/is_static_gear_icon_source(icon_source)
	if(isfile(icon_source))
		return TRUE
	if(!istext(icon_source) || !length(icon_source))
		return FALSE
	return is_valid_dmi_file(icon_source) && fexists(icon_source)

/datum/tgui_module/custom_marking_designer/proc/note_static_gear_source_state(list/sources_by_key, list/states_by_key, icon_source, icon_state = null, all_states = FALSE)
	if(!islist(sources_by_key) || !islist(states_by_key))
		return
	if(!is_static_gear_icon_source(icon_source))
		return
	var/source_key = "[icon_source]"
	if(!length(source_key))
		return
	sources_by_key[source_key] = icon_source
	var/list/source_states = states_by_key[source_key]
	if(!islist(source_states))
		source_states = list()
		states_by_key[source_key] = source_states
	if(all_states)
		source_states["*"] = TRUE
	else if(istext(icon_state) && length(icon_state))
		source_states[icon_state] = TRUE

/datum/tgui_module/custom_marking_designer/proc/prewarm_static_gear_preview_assets()
	if(!use_shared_atlas || !islist(GLOB.all_species) || !GLOB.all_species.len)
		return FALSE
	var/list/sources_by_key = list()
	var/list/states_by_key = list()
	note_static_gear_source_state(sources_by_key, states_by_key, 'icons/effects/effects.dmi', "nothing")
	if(global_underwear)
		for(var/datum/category_group/underwear/underwear_category in global_underwear.categories)
			for(var/datum/category_item/underwear/underwear_item in underwear_category.items)
				CUSTOM_MARKING_CHECK_TICK
				if(underwear_item.icon && underwear_item.icon_state)
					note_static_gear_source_state(sources_by_key, states_by_key, underwear_item.icon, underwear_item.icon_state)
	for(var/species_id in GLOB.all_species)
		var/datum/species/species = GLOB.all_species[species_id]
		if(istype(species) && species.suit_storage_icon)
			note_static_gear_source_state(sources_by_key, states_by_key, species.suit_storage_icon, null, TRUE)
	for(var/tail_name in tail_styles_list)
		var/datum/sprite_accessory/tail/tail_style = tail_styles_list[tail_name]
		if(!istype(tail_style))
			continue
		var/clip_source = tail_style.clip_mask_icon || tail_style.icon
		if(tail_style.clip_mask_state)
			note_static_gear_source_state(sources_by_key, states_by_key, clip_source, tail_style.clip_mask_state)
		if(istype(tail_style, /datum/sprite_accessory/tail/taur))
			var/datum/sprite_accessory/tail/taur/taur_style = tail_style
			if(taur_style.suit_sprites)
				note_static_gear_source_state(sources_by_key, states_by_key, taur_style.suit_sprites, null, TRUE)
	for(var/obj/item/item_type as anything in typesof(/obj/item))
		CUSTOM_MARKING_CHECK_TICK
		var/list/item_states = list()
		var/item_state = initial(item_type.item_state)
		var/icon_state = initial(item_type.icon_state)
		var/addblend_state = initial(item_type.addblends)
		if(istext(item_state) && length(item_state))
			item_states[item_state] = TRUE
		if(istext(icon_state) && length(icon_state))
			item_states[icon_state] = TRUE
		if(istext(addblend_state) && length(addblend_state))
			item_states[addblend_state] = TRUE
		var/list/item_state_slots = initial(item_type.item_state_slots)
		if(islist(item_state_slots))
			for(var/slot_name in item_state_slots)
				var/slot_state = item_state_slots[slot_name]
				if(istext(slot_state) && length(slot_state))
					item_states[slot_state] = TRUE
		if(ispath(item_type, /obj/item/clothing/under))
			var/obj/item/clothing/under/under_type = item_type
			var/worn_state = initial(under_type.worn_state)
			if(istext(worn_state) && length(worn_state))
				item_states[worn_state] = TRUE
				item_states["[worn_state]_d"] = TRUE
				item_states["[worn_state]_r"] = TRUE
		if(ispath(item_type, /obj/item/clothing/accessory))
			var/obj/item/clothing/accessory/accessory_type = item_type
			var/overlay_state = initial(accessory_type.overlay_state) || icon_state
			if(istext(overlay_state) && length(overlay_state))
				item_states[overlay_state] = TRUE
				item_states["[overlay_state]_mob"] = TRUE
				item_states["[overlay_state]_tie"] = TRUE
			var/list/rolled_states = initial(accessory_type.on_rolled)
			if(islist(rolled_states))
				for(var/rolled_key in rolled_states)
					var/rolled_state = rolled_states[rolled_key]
					if(istext(rolled_state) && length(rolled_state) && rolled_state != "none")
						item_states[rolled_state] = TRUE
		var/list/item_sources = list()
		var/slot_flags = initial(item_type.slot_flags)
		if(slot_flags & SLOT_ID)
			item_sources |= INV_WEAR_ID_DEF_ICON
		if(slot_flags & SLOT_HEAD)
			item_sources |= INV_HEAD_DEF_ICON
		if(slot_flags & SLOT_BACK)
			item_sources |= INV_BACK_DEF_ICON
		if(slot_flags & SLOT_ICLOTHING)
			item_sources |= INV_W_UNIFORM_DEF_ICON
		if(slot_flags & SLOT_TIE)
			item_sources |= INV_ACCESSORIES_DEF_ICON
		if(slot_flags & SLOT_OCLOTHING)
			item_sources |= INV_SUIT_DEF_ICON
		if(slot_flags & SLOT_GLOVES)
			item_sources |= INV_GLOVES_DEF_ICON
		if(slot_flags & SLOT_EYES)
			item_sources |= INV_EYES_DEF_ICON
		if(slot_flags & SLOT_EARS)
			item_sources |= INV_EARS_DEF_ICON
		if(slot_flags & SLOT_FEET)
			item_sources |= INV_FEET_DEF_ICON
		if(slot_flags & SLOT_BELT)
			item_sources |= INV_BELT_DEF_ICON
		if(slot_flags & SLOT_MASK)
			item_sources |= INV_MASK_DEF_ICON
		var/default_worn_icon = initial(item_type.default_worn_icon)
		var/icon_override = initial(item_type.icon_override)
		if(default_worn_icon)
			item_sources |= default_worn_icon
		if(icon_override)
			item_sources |= icon_override
		var/list/item_icons = initial(item_type.item_icons)
		if(islist(item_icons))
			for(var/slot_name in item_icons)
				var/slot_source = item_icons[slot_name]
				if(slot_source)
					item_sources |= slot_source
		var/list/sprite_sheets = initial(item_type.sprite_sheets)
		if(islist(sprite_sheets))
			for(var/body_type in sprite_sheets)
				var/body_source = sprite_sheets[body_type]
				if(body_source)
					item_sources |= body_source
		if(ispath(item_type, /obj/item/clothing))
			var/obj/item/clothing/clothing_type = item_type
			for(var/clothing_source in list(
				initial(clothing_type.update_icon_define),
				initial(clothing_type.update_icon_define_orig),
				initial(clothing_type.update_icon_define_digi)
			))
				if(clothing_source)
					item_sources |= clothing_source
		if(ispath(item_type, /obj/item/weapon/storage/belt))
			note_static_gear_source_state(sources_by_key, states_by_key, INV_BELT_DEF_ICON, null, TRUE)
		var/all_source_states = ispath(item_type, /obj/item/weapon/storage/rig) || ispath(item_type, /obj/item/clothing/under/fluff/sari)
		if(all_source_states)
			var/item_icon = initial(item_type.icon)
			if(item_icon)
				item_sources |= item_icon
		for(var/source in item_sources)
			if(all_source_states)
				note_static_gear_source_state(sources_by_key, states_by_key, source, null, TRUE)
				continue
			for(var/state_name in item_states)
				note_static_gear_source_state(sources_by_key, states_by_key, source, state_name)
	for(var/source_key in sources_by_key)
		var/icon_source = sources_by_key[source_key]
		var/list/requested_states = states_by_key[source_key]
		if(!islist(requested_states) || !requested_states.len)
			continue
		var/list/source_states = cached_icon_states(icon_source)
		if(!islist(source_states) || !source_states.len)
			continue
		var/all_states = !!requested_states["*"]
		for(var/state_name in source_states)
			if(!all_states && !requested_states[state_name])
				continue
			for(var/dir in list(NORTH, SOUTH, EAST, WEST))
				CUSTOM_MARKING_CHECK_TICK
				build_static_source_icon_asset(icon_source, state_name, dir, "gear", "gear-raw")
	return TRUE

/datum/tgui_module/custom_marking_designer/proc/is_static_species_part_intentionally_transparent(datum/species/species, part_id, dir, gender_suffix = "m", digitigrade = FALSE)
	var/list/build_metadata = list()
	var/icon/part_icon = build_static_species_part_icon(species, part_id, dir, gender_suffix, digitigrade, TRUE, build_metadata)
	return isicon(part_icon) && !!build_metadata["intentionally_transparent"]

/datum/tgui_module/custom_marking_designer/proc/is_static_species_part_hair_intentionally_transparent(datum/species/species, part_id, dir)
	var/list/build_metadata = list()
	var/icon/hair_icon = build_static_species_part_hair_icon(species, part_id, dir, TRUE, build_metadata)
	return isicon(hair_icon) && !!build_metadata["intentionally_transparent"]

/datum/tgui_module/custom_marking_designer/proc/resolve_static_species_body_alpha(datum/species/anatomy_species)
	if(!istype(anatomy_species) || !islist(anatomy_species.has_limbs) || !anatomy_species.has_limbs.len)
		return null
	var/has_limb = FALSE
	for(var/part_id in anatomy_species.has_limbs)
		var/list/organ_data = anatomy_species.has_limbs[part_id]
		var/limb_path = organ_data?["path"]
		if(!ispath(limb_path, /obj/item/organ/external))
			return null
		var/obj/item/organ/external/limb_template = limb_path
		has_limb = TRUE
		if(!initial(limb_template.transparent))
			return null
	return has_limb ? 180 : null

/datum/tgui_module/custom_marking_designer/proc/normalize_static_transparent_species_part_icon(icon/part_icon)
	if(!isicon(part_icon))
		return null
	part_icon.MapColors("#4D4D4D", "#969696", "#1C1C1C", "#000000")
	part_icon.SetIntensity(1)
	return part_icon

/datum/tgui_module/custom_marking_designer/proc/build_static_species_tail_icon(datum/species/species, dir, body_alpha = null)
	if(!istype(species))
		return null
	var/species_tail = species.get_tail(null)
	if(!istext(species_tail) || !length(species_tail))
		return null
	var/tail_icon_source = species.get_tail_animation(null)
	if(!tail_icon_source && species.icobase_tail)
		tail_icon_source = species.icobase
	if(!tail_icon_source)
		tail_icon_source = 'icons/effects/species.dmi'
	var/tail_state = "[species_tail]_s"
	var/list/state_list = cached_icon_states(tail_icon_source)
	if(!islist(state_list) || !(tail_state in state_list))
		return null
	var/icon/tail_icon = icon(tail_icon_source, tail_state, dir, 1, 0)
	if(!isicon(tail_icon) || !icon_has_visible_pixels(tail_icon, "[tail_icon_source]|[tail_state]|[dir]|static-tail"))
		return null
	if(isnum(body_alpha))
		tail_icon += rgb(,,,body_alpha)
	return tail_icon

/datum/tgui_module/custom_marking_designer/proc/build_static_species_tail_asset(datum/species/species, dir, body_alpha = null)
	if(!istype(species))
		return null
	var/species_tail = species.get_tail(null)
	if(!istext(species_tail) || !length(species_tail))
		return null
	var/tail_icon_source = species.get_tail_animation(null)
	if(!tail_icon_source && species.icobase_tail)
		tail_icon_source = species.icobase
	if(!tail_icon_source)
		tail_icon_source = 'icons/effects/species.dmi'
	var/tail_state = "[species_tail]_s"
	var/preprocessing = isnum(body_alpha) ? "alpha-[body_alpha]" : "raw"
	var/canonical_key = build_static_icon_canonical_key(tail_icon_source, tail_state, dir, preprocessing)
	var/list/cached_payload = find_static_icon_asset(canonical_key, "anatomy")
	if(islist(cached_payload))
		return cached_payload
	var/icon/tail_icon = build_static_species_tail_icon(species, dir, body_alpha)
	if(!isicon(tail_icon))
		return null
	return build_icon_asset(tail_icon, canonical_key, "anatomy")

/datum/tgui_module/custom_marking_designer/proc/build_static_species_eye_icon(datum/species/art_species, dir, datum/species/presence_owner = null, datum/species/appearance_owner = null)
	if(!istype(art_species) || !islist(art_species.has_limbs))
		return null
	if(!istype(presence_owner))
		presence_owner = art_species
	if(!istype(appearance_owner))
		appearance_owner = presence_owner
	var/list/head_data = art_species.has_limbs[BP_HEAD]
	if(!islist(head_data))
		return null
	var/head_path = head_data["path"]
	if(!ispath(head_path, /obj/item/organ/external/head))
		return null
	var/obj/item/organ/external/head/head_template = head_path
	var/eye_icon_state = initial(head_template.eye_icon)
	var/eye_icon_location = initial(head_template.eye_icon_location)
	if(!eye_icon_state || !eye_icon_location)
		return null
	var/should_have_eyes = islist(presence_owner.has_organ) && !!presence_owner.has_organ[O_EYES]
	var/has_eye_color = !!(appearance_owner.appearance_flags & HAS_EYE_COLOR)
	if(!(should_have_eyes || has_eye_color))
		return null
	var/icon/eyes_icon = new/icon(eye_icon_location, eye_icon_state)
	var/icon/directional = icon(eyes_icon, null, dir, 1, 0)
	if(!isicon(directional))
		return null
	if(!icon_has_visible_pixels(directional, "[eye_icon_location]|[eye_icon_state]|[dir]|static-eyes"))
		return null
	return directional

/datum/tgui_module/custom_marking_designer/proc/build_static_species_eye_asset(datum/species/art_species, dir, datum/species/presence_owner = null, datum/species/appearance_owner = null)
	if(!istype(art_species) || !islist(art_species.has_limbs))
		return null
	if(!istype(presence_owner))
		presence_owner = art_species
	if(!istype(appearance_owner))
		appearance_owner = presence_owner
	var/list/head_data = art_species.has_limbs[BP_HEAD]
	var/head_path = head_data?["path"]
	if(!ispath(head_path, /obj/item/organ/external/head))
		return null
	var/obj/item/organ/external/head/head_template = head_path
	var/eye_icon_state = initial(head_template.eye_icon)
	var/eye_icon_location = initial(head_template.eye_icon_location)
	var/should_have_eyes = islist(presence_owner.has_organ) && !!presence_owner.has_organ[O_EYES]
	var/has_eye_color = !!(appearance_owner.appearance_flags & HAS_EYE_COLOR)
	if(!eye_icon_state || !eye_icon_location || !(should_have_eyes || has_eye_color))
		return null
	var/canonical_key = build_static_icon_canonical_key(eye_icon_location, eye_icon_state, dir, "raw")
	var/list/cached_payload = find_static_icon_asset(canonical_key, "anatomy")
	if(islist(cached_payload))
		return cached_payload
	var/icon/eye_icon = build_static_species_eye_icon(art_species, dir, presence_owner, appearance_owner)
	if(!isicon(eye_icon))
		return null
	return build_icon_asset(eye_icon, canonical_key, "anatomy")

/datum/tgui_module/custom_marking_designer/proc/resolve_static_species_body_color_blend_mode(datum/species/species)
	if(!istype(species) || (species.appearance_flags & HAS_SKIN_TONE) || !(species.appearance_flags & HAS_SKIN_COLOR))
		return null
	return species.color_mult ? ICON_MULTIPLY : ICON_ADD

/datum/tgui_module/custom_marking_designer/proc/resolve_static_species_appearance_owner(datum/species/selected_species, datum/species/base_species)
	if(!istype(selected_species) || !istype(base_species))
		return null
	if(selected_species.selects_bodytype == SELECTS_BODYTYPE_CUSTOM)
		return base_species
	return selected_species

/datum/tgui_module/custom_marking_designer/proc/resolve_static_species_tail_owner(datum/species/selected_species, datum/species/base_species)
	if(!istype(selected_species) || !istype(base_species))
		return null
	if(selected_species.selects_bodytype == SELECTS_BODYTYPE_SHAPESHIFTER && !istype(selected_species, /datum/species/shapeshifter))
		return selected_species
	return base_species

/datum/tgui_module/custom_marking_designer/proc/resolve_static_species_forced_prosthetic(datum/species/species, part_id)
	if(!istype(species) || !istext(part_id) || !length(part_id))
		return null
	var/list/organ_data = species.has_limbs?[part_id]
	var/limb_path = organ_data?["path"]
	if(!ispath(limb_path, /obj/item/organ/external))
		return null
	var/obj/item/organ/external/limb_template = limb_path
	if(initial(limb_template.robotic) < ORGAN_ROBOT)
		return null
	var/model = initial(limb_template.model)
	var/datum/robolimb/prosthetic = istext(model) && length(model) ? all_robolimbs?[model] : basic_robolimb
	return istype(prosthetic) ? prosthetic : null

/datum/tgui_module/custom_marking_designer/proc/species_prefers_static_body_preview(datum/species/species)
	if(!istype(species) || !islist(species.has_limbs))
		return FALSE
	for(var/part_id in species.has_limbs)
		if(resolve_static_species_forced_prosthetic(species, part_id))
			return TRUE
	return FALSE

/datum/tgui_module/custom_marking_designer/proc/build_static_species_body_preview_sources(species_id, preview_icon_base = null, gender_suffix = "m", digitigrade = FALSE)
	var/base_id = resolve_species_body_preview_base(species_id, preview_icon_base)
	var/datum/species/selected_species = GLOB.all_species?[species_id]
	var/datum/species/base_species = GLOB.all_species?[base_id]
	if(!istype(selected_species) || !istype(base_species))
		return null
	if(digitigrade && !selected_species.digi_allowed)
		digitigrade = FALSE
	var/list/part_order = build_static_species_part_order(base_species)
	if(!islist(part_order) || !part_order.len)
		return null
	var/datum/species/appearance_owner = resolve_static_species_appearance_owner(selected_species, base_species)
	var/body_color_blend_mode = resolve_static_species_body_color_blend_mode(appearance_owner)
	var/list/body_color_excluded_parts = isnull(body_color_blend_mode) ? part_order.Copy() : list()
	var/list/forced_prosthetics = list()
	for(var/part_id in part_order)
		var/datum/robolimb/forced_prosthetic = resolve_static_species_forced_prosthetic(selected_species, part_id)
		if(!istype(forced_prosthetic))
			continue
		forced_prosthetics[part_id] = forced_prosthetic
		if(forced_prosthetic.skin_color)
			body_color_excluded_parts -= part_id
		else if(!(part_id in body_color_excluded_parts))
			body_color_excluded_parts += part_id
	var/body_alpha = resolve_static_species_body_alpha(selected_species)
	var/list/dirs = direction_order || list(NORTH, SOUTH, EAST, WEST)
	var/list/preview_sources = list()
	for(var/dir in dirs)
		CUSTOM_MARKING_CHECK_TICK
		var/list/part_assets = list()
		var/list/part_hair_assets = list()
		for(var/part_id in part_order)
			CUSTOM_MARKING_CHECK_TICK
			var/datum/robolimb/forced_prosthetic = forced_prosthetics[part_id]
			var/list/part_asset = null
			if(istype(forced_prosthetic))
				part_asset = build_static_prosthetic_part_asset(selected_species, forced_prosthetic, part_id, dir, gender_suffix)
				if(!islist(part_asset) && !is_static_prosthetic_part_intentionally_transparent(selected_species, forced_prosthetic, part_id, dir, gender_suffix))
					return null
			else
				part_asset = build_static_species_part_asset(base_species, part_id, dir, gender_suffix, digitigrade, !isnull(body_alpha))
			if(islist(part_asset))
				part_assets[part_id] = part_asset
			if(!istype(forced_prosthetic))
				var/list/part_hair_asset = build_static_species_part_hair_asset(base_species, part_id, dir)
				if(islist(part_hair_asset))
					part_hair_assets[part_id] = part_hair_asset
		var/eye_part_id = null
		var/eye_color_mode = "none"
		var/list/eye_asset = build_static_species_eye_asset(base_species, dir, selected_species, appearance_owner)
		if(islist(eye_asset))
			eye_part_id = (appearance_owner.appearance_flags & HAS_EYE_COLOR) ? "eyes" : "native_eyes"
			eye_color_mode = eye_part_id == "eyes" ? "separate" : "native"
			part_assets[eye_part_id] = eye_asset
		var/list/overlay_assets = list()
		var/datum/species/tail_owner = resolve_static_species_tail_owner(selected_species, base_species)
		var/list/tail_asset = build_static_species_tail_asset(tail_owner, dir, body_alpha)
		if(islist(tail_asset))
			overlay_assets += list(list(
				"slot" = "species_tail",
				"layer" = dir == SOUTH ? 7 : 16,
				"asset" = tail_asset
			))
		if(!part_assets.len)
			continue
		var/list/resolved_part_order = build_static_species_part_order(base_species, dir)
		if(!islist(resolved_part_order) || !resolved_part_order.len)
			resolved_part_order = part_order.Copy()
		var/list/resolved_body_color_excluded_parts = body_color_excluded_parts.Copy()
		if(eye_part_id)
			resolved_part_order += eye_part_id
			if(!(eye_part_id in resolved_body_color_excluded_parts))
				resolved_body_color_excluded_parts += eye_part_id
		var/list/entry = list(
			"dir" = dir,
			"label" = direction_label(dir),
			"reference_part_assets" = part_assets,
			"reference_part_hair_assets" = part_hair_assets,
			"reference_part_marking_assets" = list(),
			"part_order" = resolved_part_order,
			"hidden_body_parts" = list(),
			"marking_excluded_parts" = list(),
			"body_color_excluded_parts" = resolved_body_color_excluded_parts,
			"eye_color_mode" = eye_color_mode
		)
		if(!isnull(body_color_blend_mode))
			entry["body_color_blend_mode"] = body_color_blend_mode
		if(!isnull(body_alpha))
			entry["body_alpha"] = body_alpha
		if(overlay_assets.len)
			entry["overlay_assets"] = overlay_assets
		preview_sources += list(entry)
	return preview_sources.len ? preview_sources : null

/datum/tgui_module/custom_marking_designer/proc/build_cached_species_body_preview_sources(species_id, preview_icon_base = null, gender_suffix = null, digitigrade = FALSE)
	if(!istext(gender_suffix) || !length(gender_suffix))
		gender_suffix = "m"
	gender_suffix = gender_suffix == "f" ? "f" : "m"
	var/base_id = resolve_species_body_preview_base(species_id, preview_icon_base)
	var/datum/species/selected_species = GLOB.all_species?[species_id]
	var/datum/species/base_species = GLOB.all_species?[base_id]
	if(!istype(selected_species) || !istype(base_species))
		return null
	if(digitigrade && !selected_species.digi_allowed)
		digitigrade = FALSE
	var/cache_key = species_body_preview_cache_key(species_id, preview_icon_base, gender_suffix, digitigrade)
	if(!cache_key)
		return null
	if(!islist(custom_marking_species_body_preview_cache))
		custom_marking_species_body_preview_cache = list()
	if(cache_key in custom_marking_species_body_preview_cache)
		return custom_marking_species_body_preview_cache[cache_key]
	var/list/sources = build_static_species_body_preview_sources(species_id, preview_icon_base, gender_suffix, digitigrade)
	if(!islist(sources))
		sources = list()
	custom_marking_species_body_preview_cache[cache_key] = sources
	return sources

/datum/tgui_module/custom_marking_designer/proc/reject_shared_static_preview_sources(reason)
	shared_static_preview_failure_reason = istext(reason) && length(reason) ? reason : "unknown atlas recipe failure"
	return FALSE

/datum/tgui_module/custom_marking_designer/proc/report_shared_static_preview_failure(digitigrade = FALSE)
	var/reason = istext(shared_static_preview_failure_reason) && length(shared_static_preview_failure_reason) ? shared_static_preview_failure_reason : "atlas recipe construction returned no bundle"
	var/species_id = prefs?.species || "unknown"
	var/custom_base = prefs?.custom_base || "none"
	var/report_key = "[species_id]|[custom_base]|[!!digitigrade]|[reason]"
	if(!islist(shared_static_preview_reported_failures))
		shared_static_preview_reported_failures = list()
	if(shared_static_preview_reported_failures[report_key])
		return
	shared_static_preview_reported_failures[report_key] = TRUE
	log_error("Custom Marking Designer atlas-only preview unavailable (species=[species_id], custom_base=[custom_base], digitigrade=[!!digitigrade]): [reason].")

/datum/tgui_module/custom_marking_designer/proc/can_use_shared_static_preview_sources(digitigrade = FALSE)
	shared_static_preview_failure_reason = null
	if(!prefs)
		return reject_shared_static_preview_sources("preferences datum is unavailable")
	var/datum/asset/spritesheet/custom_marking_designer/atlas = get_asset_datum(/datum/asset/spritesheet/custom_marking_designer)
	if(!atlas.is_ready())
		return reject_shared_static_preview_sources("the shared atlas is not ready")
	if(prefs.synth_color)
		return reject_shared_static_preview_sources("synthetic recoloring is not represented by the atlas recipe")
	var/preview_icon_base = resolve_species_icon_base(prefs.species, prefs.custom_base)
	var/base_id = resolve_species_body_preview_base(prefs.species, preview_icon_base)
	var/datum/species/selected_species = GLOB.all_species?[prefs.species]
	var/datum/species/base_species = GLOB.all_species?[base_id]
	if(!istype(selected_species) || !istype(base_species))
		return reject_shared_static_preview_sources("selected species or anatomy base could not be resolved")
	if(digitigrade && !selected_species.digi_allowed)
		return reject_shared_static_preview_sources("digitigrade anatomy was requested for a species that does not allow it")
	if(!islist(base_species.has_limbs) || !base_species.has_limbs.len)
		return reject_shared_static_preview_sources("the anatomy base has no limb definitions")
	var/gender_suffix = resolve_species_body_preview_gender_suffix(selected_species)
	var/list/required_dirs = direction_order || list(NORTH, SOUTH, EAST, WEST)
	if(islist(prefs.organ_data))
		for(var/part_id in BP_ALL)
			var/status = prefs.organ_data[part_id]
			if(!status)
				continue
			var/datum/robolimb/forced_prosthetic = resolve_static_species_forced_prosthetic(selected_species, part_id)
			if(status == "cyborg" && istype(forced_prosthetic))
				continue
			if(part_id == BP_HEAD)
				return reject_shared_static_preview_sources("head override '[status]' needs an explicit head-layer recipe")
			if(status == "amputated")
				continue
			if(status != "cyborg")
				return reject_shared_static_preview_sources("unsupported organ status '[status]' for part '[part_id]'")
			var/company = prefs.rlimb_data?[part_id]
			var/datum/robolimb/prosthetic = istext(company) && length(company) ? all_robolimbs?[company] : basic_robolimb
			if(!istype(prosthetic))
				return reject_shared_static_preview_sources("prosthetic model '[company]' for part '[part_id]' could not be resolved")
			if(islist(prosthetic.species_cannot_use) && (selected_species.name in prosthetic.species_cannot_use))
				return reject_shared_static_preview_sources("prosthetic model '[company]' does not support species '[selected_species.name]'")
			var/list/organ_data = base_species.has_limbs[part_id]
			var/limb_path = organ_data?["path"]
			var/is_digitigrade_part = ispath(limb_path, /obj/item/organ/external/leg) || ispath(limb_path, /obj/item/organ/external/foot)
			if(digitigrade && is_digitigrade_part && prosthetic.can_be_digitigrade)
				return reject_shared_static_preview_sources("digitigrade prosthetic part '[part_id]' for model '[company]' needs an explicit source recipe")
			if(prosthetic.skin_color && !(base_species.appearance_flags & HAS_SKIN_COLOR))
				return reject_shared_static_preview_sources("skin-color prosthetic part '[part_id]' is incompatible with anatomy base '[base_id]'")
			for(var/dir in required_dirs)
				var/list/prosthetic_asset = build_static_prosthetic_part_asset(base_species, prosthetic, part_id, dir, gender_suffix)
				if(islist(prosthetic_asset) || is_static_prosthetic_part_intentionally_transparent(base_species, prosthetic, part_id, dir, gender_suffix))
					continue
				return reject_shared_static_preview_sources("prosthetic model '[company]' is missing atlas frame '[part_id]' direction '[dir]'")
	for(var/part_id in base_species.has_limbs)
		var/list/organ_data = base_species.has_limbs[part_id]
		var/limb_path = organ_data?["path"]
		if(!ispath(limb_path, /obj/item/organ/external))
			return reject_shared_static_preview_sources("part '[part_id]' has unsupported limb path '[limb_path]'")
		var/obj/item/organ/external/limb_template = limb_path
		if(resolve_static_species_forced_prosthetic(selected_species, part_id))
			continue
		if(initial(limb_template.robotic) >= ORGAN_ROBOT)
			return reject_shared_static_preview_sources("part '[part_id]' uses robotic default anatomy")
		if(initial(limb_template.transparent) || initial(limb_template.nonsolid))
			return reject_shared_static_preview_sources("part '[part_id]' uses transparent or nonsolid anatomy")
		if(initial(limb_template.force_icon) || initial(limb_template.force_icon_key) || initial(limb_template.model))
			return reject_shared_static_preview_sources("part '[part_id]' uses a forced-icon or model override")
		if(initial(limb_template.pixel_x) || initial(limb_template.pixel_y))
			return reject_shared_static_preview_sources("part '[part_id]' uses a nonzero pixel offset")
	var/cache_key = species_body_preview_cache_key(prefs.species, preview_icon_base, gender_suffix, digitigrade)
	var/list/cached_sources = islist(custom_marking_species_body_preview_cache) ? custom_marking_species_body_preview_cache[cache_key] : null
	if(!islist(cached_sources) || !cached_sources.len)
		return reject_shared_static_preview_sources("no cached body recipe exists for key '[cache_key]'")
	var/list/required_part_order = build_static_species_part_order(base_species)
	if(!islist(required_part_order) || !required_part_order.len)
		return reject_shared_static_preview_sources("the anatomy base produced no ordered body parts")
	if(cached_sources.len < required_dirs.len)
		return reject_shared_static_preview_sources("cached body recipe has [cached_sources.len] directions but [required_dirs.len] are required")
	for(var/list/cached_entry as anything in cached_sources)
		if(!islist(cached_entry))
			return reject_shared_static_preview_sources("cached body recipe contains an invalid direction entry")
		var/cached_dir = cached_entry["dir"]
		if(!isnum(cached_dir))
			return reject_shared_static_preview_sources("cached body recipe contains a direction without a numeric id")
		var/list/cached_part_assets = cached_entry["reference_part_assets"]
		if(!islist(cached_part_assets))
			return reject_shared_static_preview_sources("cached direction '[cached_dir]' has no body-part asset map")
		var/list/cached_part_hair_assets = cached_entry["reference_part_hair_assets"]
		if(!islist(cached_part_hair_assets))
			return reject_shared_static_preview_sources("cached direction '[cached_dir]' has no body-hair asset map")
		for(var/part_id in required_part_order)
			var/list/cached_asset = cached_part_assets[part_id]
			var/datum/robolimb/forced_prosthetic = resolve_static_species_forced_prosthetic(selected_species, part_id)
			var/intentionally_transparent = FALSE
			if(istype(forced_prosthetic))
				intentionally_transparent = is_static_prosthetic_part_intentionally_transparent(selected_species, forced_prosthetic, part_id, cached_dir, gender_suffix)
			else
				intentionally_transparent = is_static_species_part_intentionally_transparent(base_species, part_id, cached_dir, gender_suffix, digitigrade)
			if(!islist(cached_asset) && !intentionally_transparent)
				return reject_shared_static_preview_sources("cached direction '[cached_dir]' is missing visible body part '[part_id]'")
			if(istype(forced_prosthetic))
				continue
			var/list/hair_organ_data = base_species.has_limbs[part_id]
			var/hair_limb_path = hair_organ_data?["path"]
			var/obj/item/organ/external/hair_limb_template = hair_limb_path
			if(!initial(hair_limb_template.body_hair))
				continue
			var/list/cached_hair_asset = cached_part_hair_assets[part_id]
			if(islist(cached_hair_asset) || is_static_species_part_hair_intentionally_transparent(base_species, part_id, cached_dir))
				continue
			return reject_shared_static_preview_sources("cached direction '[cached_dir]' is missing body hair for part '[part_id]'")
		for(var/asset_part_id in cached_part_assets)
			var/list/atlas_asset = cached_part_assets[asset_part_id]
			if(!islist(atlas_asset) || !istext(atlas_asset["atlas"]) || !isnum(atlas_asset["atlas_x"]) || !isnum(atlas_asset["atlas_y"]))
				return reject_shared_static_preview_sources("cached direction '[cached_dir]' part '[asset_part_id]' is not backed by finalized atlas coordinates")
		for(var/hair_part_id in cached_part_hair_assets)
			var/list/atlas_hair_asset = cached_part_hair_assets[hair_part_id]
			if(!islist(atlas_hair_asset) || !istext(atlas_hair_asset["atlas"]) || !isnum(atlas_hair_asset["atlas_x"]) || !isnum(atlas_hair_asset["atlas_y"]))
				return reject_shared_static_preview_sources("cached direction '[cached_dir]' body hair '[hair_part_id]' is not backed by finalized atlas coordinates")
	return TRUE

/datum/tgui_module/custom_marking_designer/proc/get_static_limb_override_signature()
	var/list/limb_overrides = list()
	if(!prefs)
		return limb_overrides
	for(var/part_id in BP_ALL)
		var/status = prefs.organ_data?[part_id]
		if(status != "amputated" && status != "cyborg")
			continue
		var/list/entry = list("status" = status)
		if(status == "cyborg")
			entry["company"] = prefs.rlimb_data?[part_id]
		limb_overrides[part_id] = entry
	return limb_overrides

/datum/tgui_module/custom_marking_designer/proc/report_static_gear_failure(reason)
	if(!istext(reason) || !length(reason))
		return
	if(!islist(static_gear_reported_failures))
		static_gear_reported_failures = list()
	if(static_gear_reported_failures[reason])
		return
	static_gear_reported_failures[reason] = TRUE
	log_error("Custom Marking Designer gear atlas recipe omitted an unsupported appearance: [reason].")

/datum/tgui_module/custom_marking_designer/proc/get_static_gear_preview_signature()
	if(!prefs)
		return null
	var/list/signature = list(
		"species" = prefs.species,
		"custom_base" = prefs.custom_base,
		"gender" = prefs.biological_gender,
		"identifying_gender" = prefs.identifying_gender,
		"age" = prefs.age,
		"tail_style" = prefs.tail_style,
		"digitigrade" = prefs.digitigrade,
		"backbag" = prefs.backbag,
		"underwear" = prefs.all_underwear?.Copy(),
		"underwear_metadata" = prefs.all_underwear_metadata?.Copy(),
		"shoe_hater" = prefs.shoe_hater,
		"job_civilian_low" = prefs.job_civilian_low,
		"job_civilian_high" = prefs.job_civilian_high,
		"job_medsci_high" = prefs.job_medsci_high,
		"job_engsec_high" = prefs.job_engsec_high,
		"player_alt_titles" = prefs.player_alt_titles?.Copy(),
		"gear" = prefs.gear?.Copy()
	)
	return md5(json_encode(signature))

/datum/tgui_module/custom_marking_designer/proc/get_static_gear_recipe_mannequin()
	if(!istype(gear_recipe_mannequin))
		gear_recipe_mannequin = new /mob/living/carbon/human/dummy/mannequin/custom_marking_gear(null)
	return gear_recipe_mannequin

/datum/tgui_module/custom_marking_designer/proc/resolve_static_gear_appearance_asset(icon_source, icon_state, dir)
	if(!is_static_gear_icon_source(icon_source))
		report_static_gear_failure("generated or non-static icon source '[icon_source]' cannot be referenced by the gear atlas")
		return null
	if(!istext(icon_state) || !length(icon_state))
		report_static_gear_failure("source '[icon_source]' has no icon state")
		return null
	var/canonical_key = build_static_icon_canonical_key(icon_source, icon_state, dir, "gear-raw")
	if(!istext(canonical_key) || !length(canonical_key))
		return null
	var/datum/asset/spritesheet/custom_marking_designer/atlas = get_asset_datum(/datum/asset/spritesheet/custom_marking_designer)
	var/list/payload = atlas.get_icon_asset("[canonical_key]|shift:0,0")
	if(islist(payload))
		return get_static_icon_asset_reference(payload)
	if(islist(custom_marking_visible_pixel_cache) && (canonical_key in custom_marking_visible_pixel_cache) && !custom_marking_visible_pixel_cache[canonical_key])
		return null
	var/list/states = cached_icon_states(icon_source)
	if(!islist(states) || !(icon_state in states))
		report_static_gear_failure("source '[icon_source]' has no state '[icon_state]'")
	else
		report_static_gear_failure("source '[icon_source]' state '[icon_state]' direction '[dir]' was not prewarmed")
	return null

/datum/tgui_module/custom_marking_designer/proc/is_static_gear_appearance_transparent(icon_source, icon_state, dir)
	if(!is_static_gear_icon_source(icon_source) || !istext(icon_state) || !length(icon_state))
		return FALSE
	var/canonical_key = build_static_icon_canonical_key(icon_source, icon_state, dir, "gear-raw")
	return istext(canonical_key) && islist(custom_marking_visible_pixel_cache) && (canonical_key in custom_marking_visible_pixel_cache) && !custom_marking_visible_pixel_cache[canonical_key]

/datum/tgui_module/custom_marking_designer/proc/collect_static_gear_appearance_components(list/components, entry, dir, list/inherited_colors = null, inherited_alpha = 255, inherited_shift_x = 0, inherited_shift_y = 0)
	if(!islist(components) || !entry)
		return FALSE
	if(islist(entry))
		var/had_list_entry = FALSE
		for(var/element in entry)
			if(!element)
				continue
			had_list_entry = TRUE
			if(!collect_static_gear_appearance_components(components, element, dir, inherited_colors, inherited_alpha, inherited_shift_x, inherited_shift_y))
				return FALSE
		return had_list_entry
	if(!isdatum(entry))
		report_static_gear_failure("appearance entry '[entry]' is not a raw appearance")
		return FALSE
	var/matrix/appearance_transform = entry:transform
	if(istype(appearance_transform) && (appearance_transform.a != 1 || appearance_transform.b || appearance_transform.c || appearance_transform.d || appearance_transform.e != 1 || appearance_transform.f))
		report_static_gear_failure("source '[entry:icon]' state '[entry:icon_state]' uses an unsupported appearance transform")
		return FALSE
	var/appearance_flags = isnum(entry:appearance_flags) ? entry:appearance_flags : 0
	var/blend_mode = isnum(entry:blend_mode) ? entry:blend_mode : BLEND_DEFAULT
	if(blend_mode && blend_mode != BLEND_ADD)
		report_static_gear_failure("source '[entry:icon]' state '[entry:icon_state]' uses unsupported blend mode '[blend_mode]'")
		return FALSE
	if(blend_mode == BLEND_ADD && (length(entry:underlays) || length(entry:overlays)))
		report_static_gear_failure("source '[entry:icon]' state '[entry:icon_state]' uses a compound additive appearance")
		return FALSE
	var/list/effective_colors = (appearance_flags & RESET_COLOR) ? list() : (islist(inherited_colors) ? inherited_colors.Copy() : list())
	var/entry_color = entry:color
	var/color_transform = null
	if(islist(entry_color) && length(entry_color))
		var/list/color_matrix = entry_color
		if(!(color_matrix.len in list(9, 12, 16, 20)))
			report_static_gear_failure("source '[entry:icon]' state '[entry:icon_state]' uses unsupported [color_matrix.len]-value color matrix")
			return FALSE
		for(var/matrix_value in color_matrix)
			if(!isnum(matrix_value))
				report_static_gear_failure("source '[entry:icon]' state '[entry:icon_state]' uses a non-numeric color matrix")
				return FALSE
		if(color_matrix.len >= 16 && (color_matrix[4] || color_matrix[8] || color_matrix[12] || (color_matrix.len == 20 && color_matrix[20])))
			report_static_gear_failure("source '[entry:icon]' state '[entry:icon_state]' uses a color matrix that can create alpha from transparent pixels")
			return FALSE
		color_transform = color_matrix.Copy()
	else if(istext(entry_color) && length(entry_color))
		color_transform = entry_color
	if(!isnull(color_transform))
		var/list/ordered_colors = list(color_transform)
		for(var/existing_transform in effective_colors)
			ordered_colors += list(existing_transform)
		effective_colors = ordered_colors
	var/entry_alpha = isnum(entry:alpha) ? entry:alpha : 255
	var/effective_alpha = (appearance_flags & RESET_ALPHA) ? entry_alpha : round(inherited_alpha * entry_alpha / 255)
	if(effective_alpha <= 0)
		return TRUE
	var/shift_x = inherited_shift_x + (isnum(entry:pixel_x) ? round(entry:pixel_x) : 0)
	var/shift_y = inherited_shift_y + (isnum(entry:pixel_y) ? round(entry:pixel_y) : 0)
	var/list/underlays = entry:underlays
	if(islist(underlays))
		for(var/underlay in underlays)
			if(!underlay)
				continue
			var/mutable_appearance/underlay_appearance = new /mutable_appearance(underlay)
			if(!collect_static_gear_appearance_components(components, underlay_appearance, dir, effective_colors, effective_alpha, shift_x, shift_y))
				return FALSE
	var/icon_source = entry:icon
	var/icon_state = entry:icon_state
	if(icon_source && istext(icon_state) && length(icon_state))
		var/asset = resolve_static_gear_appearance_asset(icon_source, icon_state, dir)
		if(asset)
			var/list/component = list("asset" = asset)
			if(effective_colors.len)
				component["colors"] = effective_colors
			if(effective_alpha < 255)
				component["alpha"] = effective_alpha
			if(shift_x)
				component["shift_x"] = shift_x
			if(shift_y)
				component["shift_y"] = shift_y
			if(blend_mode == BLEND_ADD)
				component["blend"] = "add"
			components += list(component)
		else if(!is_static_gear_appearance_transparent(icon_source, icon_state, dir))
			return FALSE
	var/list/overlays = entry:overlays
	if(islist(overlays))
		for(var/overlay in overlays)
			if(!overlay)
				continue
			var/mutable_appearance/overlay_appearance = new /mutable_appearance(overlay)
			if(!collect_static_gear_appearance_components(components, overlay_appearance, dir, effective_colors, effective_alpha, shift_x, shift_y))
				return FALSE
	return TRUE

/datum/tgui_module/custom_marking_designer/proc/resolve_static_gear_clip_mask(mob/living/carbon/human/dummy/mannequin/custom_marking_gear/mannequin, layer_index, dir)
	var/datum/sprite_accessory/tail/tail_style = mannequin?.tail_style
	if(!istype(tail_style) || !tail_style.clip_mask_state)
		return null
	var/should_mask = FALSE
	var/obj/item/clothing/suit/suit = mannequin.wear_suit
	switch(layer_index)
		if(10) // UNIFORM_LAYER
			should_mask = !(suit && ((suit.flags_inv & HIDETAIL) || suit.taurized))
		if(14, 18) // BELT_LAYER, BELT_LAYER_ALT
			should_mask = TRUE
		if(15) // SUIT_LAYER
			should_mask = !(suit && ((suit.flags_inv & HIDETAIL) || suit.taurized))
		if(20) // BACK_LAYER
			should_mask = !istype(mannequin.back, /obj/item/weapon/storage/backpack/saddlebag) && !istype(mannequin.back, /obj/item/weapon/storage/backpack/saddlebag_common)
	if(!should_mask)
		return null
	var/icon_source = tail_style.clip_mask_icon || tail_style.icon
	return resolve_static_gear_appearance_asset(icon_source, tail_style.clip_mask_state, dir)

/datum/tgui_module/custom_marking_designer/proc/build_static_gear_overlay_assets_for_layers(mob/living/carbon/human/dummy/mannequin/custom_marking_gear/mannequin, dir, list/allowed_layers)
	if(!istype(mannequin) || !islist(allowed_layers) || !allowed_layers.len || !islist(mannequin.overlays_standing))
		return null
	var/list/overlay_assets = list()
	for(var/layer_index in allowed_layers)
		var/entry = mannequin.overlays_standing[layer_index]
		if(!entry)
			continue
		var/list/components = list()
		if(!collect_static_gear_appearance_components(components, entry, dir))
			continue
		if(!components.len)
			continue
		var/list/base_component = components[1]
		var/list/overlay_entry = base_component.Copy()
		overlay_entry["layer"] = layer_index
		var/slot = get_preview_overlay_slot(layer_index)
		if(slot)
			overlay_entry["slot"] = slot
		if(components.len > 1)
			var/list/component_overlays = list()
			for(var/component_index = 2 to components.len)
				component_overlays += list(components[component_index])
			overlay_entry["overlays"] = component_overlays
		var/mask_asset = resolve_static_gear_clip_mask(mannequin, layer_index, dir)
		if(mask_asset)
			overlay_entry["mask_asset"] = mask_asset
		overlay_assets += list(overlay_entry)
	return overlay_assets.len ? overlay_assets : null

/datum/tgui_module/custom_marking_designer/proc/build_static_gear_preview_recipes()
	if(!prefs || !custom_marking_gear_preview_cache_complete)
		return null
	var/cache_key = get_static_gear_preview_signature()
	if(!cache_key)
		return null
	if(!islist(static_gear_recipe_cache))
		static_gear_recipe_cache = list()
	var/list/cached_recipes = static_gear_recipe_cache[cache_key]
	if(islist(cached_recipes))
		return cached_recipes
	var/mob/living/carbon/human/dummy/mannequin/custom_marking_gear/mannequin = get_static_gear_recipe_mannequin()
	if(!istype(mannequin))
		return null
	var/static/list/gear_layers = list(
		6, 9, 10, 11, 12, 13, 14, 15, 17, 18, 19, 20, 23, 25, 26, 27
	)
	var/static/list/equipment_layers = list(6, 20)
	var/list/dirs = islist(direction_order) && direction_order.len ? direction_order : list(NORTH, SOUTH, EAST, WEST)
	reset_mannequin_equipment(mannequin, gear_layers)
	copy_preferences_to_mannequin_without_marking(mannequin)
	mannequin.update_underwear()
	var/list/tail_override = apply_preview_tail_override(mannequin)
	var/list/equipment_by_dir = list()
	prefs.equip_prepared_preview_mob(mannequin, EQUIP_PREVIEW_EQUIPMENT)
	for(var/dir in dirs)
		var/list/equipment_assets = build_static_gear_overlay_assets_for_layers(mannequin, dir, equipment_layers)
		if(islist(equipment_assets) && equipment_assets.len)
			equipment_by_dir["[dir]"] = equipment_assets
	reset_mannequin_equipment(mannequin, gear_layers)
	var/list/job_by_dir = list()
	prefs.equip_prepared_preview_mob(mannequin, EQUIP_PREVIEW_JOB)
	for(var/dir in dirs)
		var/list/job_assets = build_static_gear_overlay_assets_for_layers(mannequin, dir, gear_layers)
		if(islist(job_assets) && job_assets.len)
			job_by_dir["[dir]"] = job_assets
	reset_mannequin_equipment(mannequin, gear_layers)
	var/list/loadout_by_dir = list()
	prefs.equip_prepared_preview_mob(mannequin, EQUIP_PREVIEW_LOADOUT)
	for(var/dir in dirs)
		var/list/loadout_assets = build_static_gear_overlay_assets_for_layers(mannequin, dir, gear_layers)
		if(islist(loadout_assets) && loadout_assets.len)
			loadout_by_dir["[dir]"] = loadout_assets
	reset_mannequin_equipment(mannequin, gear_layers)
	if(tail_override)
		restore_preview_tail_override(tail_override)
	var/list/result = list(
		"equipment" = equipment_by_dir,
		"job" = job_by_dir,
		"loadout" = loadout_by_dir
	)
	static_gear_recipe_cache[cache_key] = result
	return result

/datum/tgui_module/custom_marking_designer/proc/build_species_preview_gear_recipes(species_id, mob/user, preview_icon_base = null)
	if(!prefs || !istext(species_id) || !length(species_id))
		return null
	var/datum/species/preview_species = GLOB.all_species?[species_id]
	if(!istype(preview_species))
		return null
	var/resolved_icon_base = resolve_species_icon_base(species_id, preview_icon_base)
	var/icon_base_changed = istext(resolved_icon_base) && length(resolved_icon_base) && resolved_icon_base != prefs.custom_base
	var/requires_override = species_id != prefs.species || icon_base_changed
	if(!requires_override)
		return build_static_gear_preview_recipes()
	var/original_biological_gender = prefs.biological_gender
	var/original_identifying_gender = prefs.identifying_gender
	var/original_age = prefs.age
	var/original_real_name = prefs.real_name
	var/list/restore = apply_preview_species_override(species_id, user, FALSE, preview_icon_base)
	if(!islist(restore))
		return null
	var/resolved_biological_gender = resolve_species_allowed_biological_gender(preview_species, prefs.biological_gender)
	if(resolved_biological_gender != prefs.biological_gender)
		prefs.set_biological_gender(resolved_biological_gender)
	prefs.sanitize_body_styles()
	if(isnum(preview_species.min_age) && isnum(preview_species.max_age))
		prefs.age = max(min(prefs.age, preview_species.max_age), preview_species.min_age)
	var/list/recipes = build_static_gear_preview_recipes()
	restore_preview_species_override(restore)
	prefs.biological_gender = original_biological_gender
	prefs.identifying_gender = original_identifying_gender
	prefs.age = original_age
	prefs.real_name = original_real_name
	return recipes

/datum/tgui_module/custom_marking_designer/proc/get_shared_static_preview_signature(digitigrade)
	if(!prefs)
		return null
	var/list/signature = list(
		"species" = prefs.species,
		"custom_base" = prefs.custom_base,
		"gender" = prefs.biological_gender,
		"digitigrade" = !!digitigrade,
		"skin_tone" = prefs.s_tone,
		"limb_overrides" = get_static_limb_override_signature(),
		"synth_markings" = prefs.synth_markings,
		"gear" = get_static_gear_preview_signature()
	)
	return md5(json_encode(signature))

/datum/tgui_module/custom_marking_designer/proc/build_shared_static_preview_source_bundle(digitigrade = FALSE)
	if(!can_use_shared_static_preview_sources(digitigrade))
		return null
	var/cache_key = get_shared_static_preview_signature(digitigrade)
	if(!cache_key)
		reject_shared_static_preview_sources("the atlas recipe cache signature could not be built")
		return null
	if(!islist(shared_static_preview_bundle_cache))
		shared_static_preview_bundle_cache = list()
	var/list/cached_bundle = shared_static_preview_bundle_cache[cache_key]
	if(islist(cached_bundle))
		return cached_bundle
	var/datum/species/selected_species = GLOB.all_species?[prefs.species]
	var/gender_suffix = resolve_species_body_preview_gender_suffix(selected_species)
	var/preview_icon_base = resolve_species_icon_base(prefs.species, prefs.custom_base)
	var/source_cache_key = species_body_preview_cache_key(prefs.species, preview_icon_base, gender_suffix, digitigrade)
	var/list/cached_sources = islist(custom_marking_species_body_preview_cache) ? custom_marking_species_body_preview_cache[source_cache_key] : null
	if(!islist(cached_sources) || !cached_sources.len)
		reject_shared_static_preview_sources("the cached body recipe disappeared for key '[source_cache_key]'")
		return null
	var/base_id = resolve_species_body_preview_base(prefs.species, preview_icon_base)
	var/datum/species/base_species = GLOB.all_species?[base_id]
	var/apply_skin_tone = istype(base_species) && (base_species.appearance_flags & HAS_SKIN_TONE) && isnum(prefs.s_tone) && prefs.s_tone
	var/has_limb_overrides = FALSE
	for(var/part_id in BP_ALL)
		var/override_status = prefs.organ_data?[part_id]
		if(override_status == "amputated" || override_status == "cyborg")
			has_limb_overrides = TRUE
			break
	var/list/gear_recipes = build_static_gear_preview_recipes()
	var/list/equipment_gear_by_dir = gear_recipes?["equipment"]
	var/list/job_gear_by_dir = gear_recipes?["job"]
	var/list/loadout_gear_by_dir = gear_recipes?["loadout"]
	var/list/sources = list()
	for(var/list/cached_entry as anything in cached_sources)
		if(!islist(cached_entry))
			continue
		var/cached_dir = cached_entry["dir"]
		var/list/cached_part_assets = cached_entry["reference_part_assets"]
		var/list/cached_part_hair_assets = cached_entry["reference_part_hair_assets"]
		var/list/entry = cached_entry.Copy()
		var/list/part_assets = cached_part_assets
		var/list/part_hair_assets = cached_part_hair_assets
		if(apply_skin_tone || has_limb_overrides)
			part_assets = list()
			for(var/part_id in cached_part_assets)
				var/list/cached_asset = cached_part_assets[part_id]
				var/datum/robolimb/forced_prosthetic = resolve_static_species_forced_prosthetic(selected_species, part_id)
				var/apply_part_skin_tone = apply_skin_tone && (!istype(forced_prosthetic) || forced_prosthetic.skin_tone)
				if(!islist(cached_asset) || part_id == "eyes" || part_id == "native_eyes" || !apply_part_skin_tone)
					part_assets[part_id] = cached_asset
					continue
				var/list/asset = cached_asset.Copy()
				var/cached_token = cached_asset["token"]
				asset["token"] = "[cached_token]-tone-[prefs.s_tone]"
				asset["tone"] = prefs.s_tone
				asset -= "canonical"
				part_assets[part_id] = asset
			entry["reference_part_assets"] = part_assets
		if(has_limb_overrides)
			part_hair_assets = islist(cached_part_hair_assets) ? cached_part_hair_assets.Copy() : list()
			entry["reference_part_hair_assets"] = part_hair_assets
		var/list/equipment_gear_assets = equipment_gear_by_dir?["[cached_dir]"]
		if(islist(equipment_gear_assets) && equipment_gear_assets.len)
			entry["equipment_overlay_assets"] = equipment_gear_assets
		var/list/job_gear_assets = job_gear_by_dir?["[cached_dir]"]
		if(islist(job_gear_assets) && job_gear_assets.len)
			entry["job_overlay_assets"] = job_gear_assets
		var/list/loadout_gear_assets = loadout_gear_by_dir?["[cached_dir]"]
		if(islist(loadout_gear_assets) && loadout_gear_assets.len)
			entry["loadout_overlay_assets"] = loadout_gear_assets
		if(!has_limb_overrides)
			sources += list(entry)
			continue
		var/list/hidden_body_parts = entry["hidden_body_parts"]
		hidden_body_parts = islist(hidden_body_parts) ? hidden_body_parts.Copy() : list()
		var/list/marking_excluded_parts = entry["marking_excluded_parts"]
		marking_excluded_parts = islist(marking_excluded_parts) ? marking_excluded_parts.Copy() : list()
		var/list/body_color_excluded_parts = entry["body_color_excluded_parts"]
		body_color_excluded_parts = islist(body_color_excluded_parts) ? body_color_excluded_parts.Copy() : list()
		for(var/part_id in BP_ALL)
			var/status = prefs.organ_data?[part_id]
			if(status == "amputated")
				part_assets -= part_id
				part_hair_assets -= part_id
				if(!(part_id in hidden_body_parts))
					hidden_body_parts += part_id
				if(!(part_id in marking_excluded_parts))
					marking_excluded_parts += part_id
				continue
			if(status != "cyborg")
				continue
			if(resolve_static_species_forced_prosthetic(selected_species, part_id))
				continue
			var/company = prefs.rlimb_data?[part_id]
			var/datum/robolimb/prosthetic = istext(company) && length(company) ? all_robolimbs?[company] : basic_robolimb
			var/list/prosthetic_asset = build_static_prosthetic_part_asset(base_species, prosthetic, part_id, cached_dir, gender_suffix)
			if(!islist(prosthetic_asset))
				if(!is_static_prosthetic_part_intentionally_transparent(base_species, prosthetic, part_id, cached_dir, gender_suffix))
					reject_shared_static_preview_sources("prosthetic model '[company]' could not resolve part '[part_id]' direction '[cached_dir]' during recipe assembly")
					return null
				part_assets -= part_id
				if(!(part_id in marking_excluded_parts))
					marking_excluded_parts += part_id
				continue
			if(apply_skin_tone && prosthetic.skin_tone)
				var/list/tone_asset = prosthetic_asset.Copy()
				var/prosthetic_token = prosthetic_asset["token"]
				tone_asset["token"] = "[prosthetic_token]-tone-[prefs.s_tone]"
				tone_asset["tone"] = prefs.s_tone
				tone_asset -= "canonical"
				prosthetic_asset = tone_asset
			part_assets[part_id] = prosthetic_asset
			if(prefs.synth_markings)
				marking_excluded_parts -= part_id
			else if(!(part_id in marking_excluded_parts))
				marking_excluded_parts += part_id
			if(prosthetic.skin_color)
				body_color_excluded_parts -= part_id
			else if(!(part_id in body_color_excluded_parts))
				body_color_excluded_parts += part_id
		entry["reference_part_assets"] = part_assets
		entry["reference_part_hair_assets"] = part_hair_assets
		entry["hidden_body_parts"] = hidden_body_parts
		entry["marking_excluded_parts"] = marking_excluded_parts
		entry["body_color_excluded_parts"] = body_color_excluded_parts
		sources += list(entry)
	if(!sources.len)
		reject_shared_static_preview_sources("atlas recipe assembly produced no directional sources")
		return null
	body_preview_revision++
	var/list/bundle = build_reference_transport_bundle(sources, body_preview_revision, cache_key)
	if(!islist(bundle))
		reject_shared_static_preview_sources("atlas recipe transport canonicalization failed")
		return null
	shared_static_preview_failure_reason = null
	shared_static_preview_bundle_cache[cache_key] = bundle
	return bundle

/datum/tgui_module/custom_marking_designer/proc/attach_custom_grids_to_preview_bundle(list/bundle)
	if(!islist(bundle))
		return null
	var/list/sources = bundle["dirs"]
	if(!islist(sources) || !sources.len)
		return bundle
	var/list/resolved_sources = list()
	for(var/list/source as anything in sources)
		if(!islist(source))
			continue
		var/list/entry = source.Copy()
		var/dir = entry["dir"]
		if(isnum(dir))
			var/list/part_order = entry["part_order"]
			part_order = islist(part_order) ? part_order.Copy() : list("generic")
			if(islist(mark?.body_parts))
				for(var/part in mark.body_parts)
					if(istext(part) && length(part) && !(part in part_order))
						part_order += part
			entry["part_order"] = part_order
			entry["custom_parts"] = build_custom_grid_map_for_parts(dir, part_order)
		resolved_sources += list(entry)
	var/list/resolved_bundle = bundle.Copy()
	resolved_bundle["dirs"] = resolved_sources
	return resolved_bundle

/datum/tgui_module/custom_marking_designer/proc/build_stripped_preview_source_bundle(digitigrade = FALSE)
	var/list/bundle = build_shared_static_preview_source_bundle(digitigrade)
	if(islist(bundle))
		return attach_custom_grids_to_preview_bundle(bundle)
	report_shared_static_preview_failure(digitigrade)
	return null

/datum/tgui_module/custom_marking_designer/proc/build_species_digitigrade_preview_assets(species_id, preview_icon_base = null, gender_suffix = null)
	var/base_id = resolve_species_body_preview_base(species_id, preview_icon_base)
	var/datum/species/selected_species = GLOB.all_species?[species_id]
	var/datum/species/base_species = GLOB.all_species?[base_id]
	if(!istype(selected_species) || !selected_species.digi_allowed || !istype(base_species))
		return null
	if(!istext(gender_suffix) || !length(gender_suffix))
		gender_suffix = resolve_species_body_preview_gender_suffix(selected_species)
	var/list/digitigrade_sources = build_cached_species_body_preview_sources(species_id, preview_icon_base, gender_suffix, TRUE)
	if(!islist(digitigrade_sources) || !digitigrade_sources.len)
		return null
	var/static/list/digitigrade_parts = list(BP_R_LEG, BP_L_LEG, BP_R_FOOT, BP_L_FOOT)
	var/list/assets_by_dir = list()
	for(var/list/source in digitigrade_sources)
		var/dir = source?["dir"]
		var/list/part_assets = source?["reference_part_assets"]
		if(!isnum(dir) || !islist(part_assets))
			continue
		var/list/digitigrade_assets = list()
		for(var/part_id in digitigrade_parts)
			var/list/part_asset = part_assets[part_id]
			if(islist(part_asset))
				digitigrade_assets[part_id] = get_static_icon_asset_reference(part_asset)
		if(digitigrade_assets.len)
			assets_by_dir["[dir]"] = digitigrade_assets
	return assets_by_dir.len ? assets_by_dir : null

/datum/tgui_module/custom_marking_designer/proc/build_static_preview_source_references(list/sources)
	if(!islist(sources))
		return null
	var/list/result = list()
	for(var/list/source as anything in sources)
		if(!islist(source))
			continue
		var/list/entry = source.Copy()
		var/list/source_part_assets = source["reference_part_assets"]
		if(islist(source_part_assets))
			var/list/part_assets = list()
			for(var/part_id in source_part_assets)
				var/value = source_part_assets[part_id]
				part_assets[part_id] = istext(value) ? value : get_static_icon_asset_reference(value)
			entry["reference_part_assets"] = part_assets
		var/list/source_part_hair_assets = source["reference_part_hair_assets"]
		if(islist(source_part_hair_assets))
			var/list/part_hair_assets = list()
			for(var/hair_part_id in source_part_hair_assets)
				var/hair_value = source_part_hair_assets[hair_part_id]
				part_hair_assets[hair_part_id] = istext(hair_value) ? hair_value : get_static_icon_asset_reference(hair_value)
			entry["reference_part_hair_assets"] = part_hair_assets
		var/list/source_overlays = source["overlay_assets"]
		if(islist(source_overlays))
			var/list/overlays = list()
			for(var/list/overlay as anything in source_overlays)
				if(!islist(overlay))
					continue
				var/list/overlay_entry = overlay.Copy()
				var/asset = overlay_entry["asset"]
				if(islist(asset))
					overlay_entry["asset"] = get_static_icon_asset_reference(asset)
				overlays += list(overlay_entry)
			entry["overlay_assets"] = overlays
		result += list(entry)
	return result.len ? result : null

/datum/tgui_module/custom_marking_designer/proc/attach_species_preview_gear_recipes(list/sources, list/gear_recipes)
	if(!islist(sources) || !islist(gear_recipes))
		return sources
	var/list/equipment_by_dir = gear_recipes["equipment"]
	var/list/job_by_dir = gear_recipes["job"]
	var/list/loadout_by_dir = gear_recipes["loadout"]
	var/list/result = list()
	for(var/list/source as anything in sources)
		if(!islist(source))
			continue
		var/list/entry = source.Copy()
		var/dir = entry["dir"]
		var/dir_key = "[dir]"
		var/list/equipment_assets = equipment_by_dir?[dir_key]
		var/list/job_assets = job_by_dir?[dir_key]
		var/list/loadout_assets = loadout_by_dir?[dir_key]
		entry["equipment_overlay_assets"] = islist(equipment_assets) ? equipment_assets : list()
		entry["job_overlay_assets"] = islist(job_assets) ? job_assets : list()
		entry["loadout_overlay_assets"] = islist(loadout_assets) ? loadout_assets : list()
		result += list(entry)
	return result

/datum/tgui_module/custom_marking_designer/proc/build_species_body_preview_cache()
	if(!islist(custom_marking_species_body_preview_cache))
		custom_marking_species_body_preview_cache = list()
	if(!islist(GLOB.all_species) || !GLOB.all_species.len)
		return null
	if(!islist(GLOB.playable_species) || !GLOB.playable_species.len)
		return null
	var/list/species_list = GLOB.playable_species
	for(var/species_name in species_list)
		CUSTOM_MARKING_CHECK_TICK
		var/datum/species/species = GLOB.all_species?[species_name]
		if(!istype(species))
			continue
		for(var/gender_suffix in list("m", "f"))
			build_cached_species_body_preview_sources(species_name, null, gender_suffix, FALSE)
			if(species.digi_allowed)
				build_cached_species_body_preview_sources(species_name, null, gender_suffix, TRUE)
		var/list/icon_base_choices = custom_marking_static_icon_base_choices_for_species(species_name)
		if(!islist(icon_base_choices) || !icon_base_choices.len)
			continue
		for(var/base_id in icon_base_choices)
			CUSTOM_MARKING_CHECK_TICK
			var/datum/species/base_species = GLOB.all_species?[base_id]
			if(!istype(base_species))
				continue
			for(var/gender_suffix in list("m", "f"))
				build_cached_species_body_preview_sources(species_name, base_id, gender_suffix, FALSE)
				if(species.digi_allowed)
					build_cached_species_body_preview_sources(species_name, base_id, gender_suffix, TRUE)
	return custom_marking_species_body_preview_cache

/datum/tgui_module/custom_marking_designer/proc/build_species_preview_assets(icon_source, fallback_icon_source = null, build_from_parts = FALSE, datum/species/native_eye_species = null)
	if(!icon_source)
		icon_source = fallback_icon_source
	if(!icon_source)
		return null
	var/resolved_icon_source = icon_source
	var/list/icon_states = cached_icon_states(resolved_icon_source)
	var/icon/preview_icon = null
	var/has_authored_preview = FALSE
	if(!islist(icon_states) || !("preview" in icon_states))
		if(fallback_icon_source && fallback_icon_source != resolved_icon_source)
			resolved_icon_source = fallback_icon_source
			icon_states = cached_icon_states(resolved_icon_source)
	if(islist(icon_states) && ("preview" in icon_states))
		has_authored_preview = TRUE
	if(has_authored_preview && !istype(native_eye_species))
		var/asset_reference = build_static_source_icon_reference(resolved_icon_source, "preview", SOUTH, "species-gallery")
		if(isnull(asset_reference))
			return null
		var/list/authored_dir_assets = list()
		authored_dir_assets["[SOUTH]"] = asset_reference
		return authored_dir_assets
	var/native_eye_identity = istype(native_eye_species) ? native_eye_species.name : "none"
	var/canonical_icon_source = has_authored_preview ? resolved_icon_source : icon_source
	var/preprocessing = has_authored_preview ? "preview+native-eyes:[native_eye_identity]" : "parts+native-eyes:[native_eye_identity]"
	var/canonical_key = build_static_icon_canonical_key(canonical_icon_source, has_authored_preview ? "preview" : "generated-preview", SOUTH, preprocessing)
	var/list/cached_payload = find_static_icon_asset(canonical_key, "species-gallery")
	if(islist(cached_payload))
		var/list/cached_dir_assets = list()
		cached_dir_assets["[SOUTH]"] = get_static_icon_asset_reference(cached_payload)
		return cached_dir_assets
	if(has_authored_preview)
		preview_icon = icon(resolved_icon_source, "preview", SOUTH)
	if(!isicon(preview_icon) && build_from_parts)
		preview_icon = build_species_preview_from_parts(icon_source)
	if(!isicon(preview_icon))
		return null
	if(istype(native_eye_species))
		var/icon/native_eye_icon = build_static_species_eye_icon(native_eye_species, SOUTH)
		if(isicon(native_eye_icon))
			preview_icon.Blend(native_eye_icon, ICON_OVERLAY)
	var/list/asset_payload = build_icon_asset(preview_icon, canonical_key, "species-gallery")
	if(!islist(asset_payload))
		return null
	var/list/dir_assets = list()
	dir_assets["[SOUTH]"] = get_static_icon_asset_reference(asset_payload)
	return dir_assets.len ? dir_assets : null

/datum/tgui_module/custom_marking_designer/proc/build_static_species_definition(species_id)
	if(!istext(species_id) || !length(species_id))
		return null
	var/datum/species/species = GLOB.all_species?[species_id]
	if(!istype(species))
		return null
	var/list/definition = list(
		"id" = species_id,
		"name" = istext(species.name) && length(species.name) ? species.name : "[species_id]",
		"blurb" = species.blurb,
		"modifiers" = build_species_modifier_entries(species),
		"traits" = build_species_trait_entries(species),
		"detail_sections" = custom_marking_build_species_detail_sections(species, null, species.traits, FALSE)
	)
	var/list/icon_base_choices = custom_marking_static_icon_base_choices_for_species(species_id)
	var/icon_base_count = 0
	if(islist(icon_base_choices))
		for(var/base_id in icon_base_choices)
			var/datum/species/base_species = GLOB.all_species?[base_id]
			if(istype(base_species))
				icon_base_count++
	definition["icon_base_count"] = icon_base_count
	var/datum/species/native_eye_preview_species = species_id == SPECIES_SHADEKIN_CREW ? species : null
	if(!species_prefers_static_body_preview(species))
		var/list/preview_assets = build_species_preview_assets(species.icobase, resolve_species_preview_fallback_icon(species_id), should_build_species_preview_from_parts(species_id), native_eye_preview_species)
		if(islist(preview_assets) && preview_assets.len)
			definition["preview_assets"] = preview_assets
	return definition

/datum/tgui_module/custom_marking_designer/proc/build_static_species_icon_base_option(base_id)
	if(!istext(base_id) || !length(base_id))
		return null
	var/datum/species/base_species = GLOB.all_species?[base_id]
	if(!istype(base_species))
		return null
	var/list/option = list(
		"id" = base_id,
		"name" = istext(base_species.name) && length(base_species.name) ? base_species.name : "[base_id]"
	)
	var/body_color_blend_mode = resolve_static_species_body_color_blend_mode(base_species)
	if(!isnull(body_color_blend_mode))
		option["body_color_blend_mode"] = body_color_blend_mode
	var/list/preview_assets = build_species_preview_assets(base_species.icobase, resolve_species_preview_fallback_icon(base_id), should_build_species_preview_from_parts(base_id))
	if(islist(preview_assets) && preview_assets.len)
		option["preview_assets"] = preview_assets
	return option

/datum/tgui_module/custom_marking_designer/proc/build_species_catalog_cache()
	if(!islist(GLOB.all_species) || !GLOB.all_species.len)
		return null
	if(!islist(GLOB.playable_species) || !GLOB.playable_species.len)
		return null
	var/list/catalog = list()
	var/list/icon_base_options = list()
	for(var/species_id in GLOB.playable_species)
		CUSTOM_MARKING_CHECK_TICK
		var/list/definition = build_static_species_definition(species_id)
		if(!islist(definition))
			continue
		catalog[species_id] = definition
		var/list/icon_base_choices = custom_marking_static_icon_base_choices_for_species(species_id)
		if(!islist(icon_base_choices))
			continue
		for(var/base_id in icon_base_choices)
			CUSTOM_MARKING_CHECK_TICK
			if(islist(icon_base_options[base_id]))
				continue
			var/list/option = build_static_species_icon_base_option(base_id)
			if(islist(option))
				icon_base_options[base_id] = option
	if(!catalog.len)
		return null
	custom_marking_species_catalog_cache = catalog
	custom_marking_species_icon_base_option_cache = icon_base_options
	return custom_marking_species_catalog_cache

/datum/tgui_module/custom_marking_designer/proc/resolve_species_icon_base(species_id, requested_icon_base = null)
	if(!prefs)
		return null
	if(!istext(species_id) || !length(species_id))
		return null
	var/list/choices = prefs.get_custom_bases_for_species(species_id)
	if(!islist(choices) || !choices.len)
		return null
	if(istext(requested_icon_base) && length(requested_icon_base) && (requested_icon_base in choices))
		return requested_icon_base
	if(istext(prefs.custom_base) && length(prefs.custom_base) && (prefs.custom_base in choices))
		return prefs.custom_base
	if(SPECIES_HUMAN in choices)
		return SPECIES_HUMAN
	return choices[1]

/datum/tgui_module/custom_marking_designer/proc/build_species_icon_base_options(species_id, gender_suffix = null)
	if(!istext(species_id) || !length(species_id))
		return null
	var/datum/species/selected_species = GLOB.all_species?[species_id]
	var/prefer_body_preview = species_prefers_static_body_preview(selected_species)
	if(!istext(gender_suffix) || !length(gender_suffix))
		gender_suffix = resolve_species_body_preview_gender_suffix(selected_species)
	var/list/choices = custom_marking_static_icon_base_choices_for_species(species_id)
	if(!islist(choices) || !choices.len)
		return null
	if(!islist(custom_marking_species_icon_base_option_cache))
		build_custom_marking_species_catalog_cache()
	var/list/options = list()
	for(var/base_id in choices)
		CUSTOM_MARKING_CHECK_TICK
		if(!istext(base_id) || !length(base_id))
			continue
		var/datum/species/base_species = GLOB.all_species?[base_id]
		if(!istype(base_species))
			continue
		var/list/static_option = custom_marking_species_icon_base_option_cache?[base_id]
		if(!islist(static_option))
			static_option = build_static_species_icon_base_option(base_id)
		var/list/option = islist(static_option) ? static_option.Copy() : list(
			"id" = base_id,
			"name" = istext(base_species.name) && length(base_species.name) ? base_species.name : "[base_id]"
		)
		if(prefer_body_preview)
			option -= "preview_assets"
		var/list/body_preview_sources = build_cached_species_body_preview_sources(species_id, base_id, gender_suffix, FALSE)
		if(islist(body_preview_sources) && body_preview_sources.len)
			option["body_preview_sources"] = build_static_preview_source_references(body_preview_sources)
		var/list/body_preview_digitigrade_assets = build_species_digitigrade_preview_assets(species_id, base_id, gender_suffix)
		if(islist(body_preview_digitigrade_assets) && body_preview_digitigrade_assets.len)
			option["body_preview_digitigrade_assets"] = body_preview_digitigrade_assets
		options += list(option)
	return options

/datum/tgui_module/custom_marking_designer/proc/build_species_payload(mob/user, preview_species_id = null, preview_icon_base_id = null)
	var/list/yield_context = custom_marking_begin_manual_yield()
	if(!prefs)
		custom_marking_end_manual_yield(yield_context)
		return null
	var/list/payload = list()
	var/list/definitions = list()
	var/list/species_list = islist(GLOB.playable_species) ? GLOB.playable_species : list()
	var/list/species_catalog = build_custom_marking_species_catalog_cache()
	var/custom_species_name = istext(prefs.custom_species) ? html_decode(prefs.custom_species) : null
	var/resolved_preview_species = prefs.species
	if(istext(preview_species_id) && length(preview_species_id))
		var/datum/species/preview_species = GLOB.all_species?[preview_species_id]
		if(istype(preview_species))
			resolved_preview_species = preview_species_id
	var/resolved_preview_icon_base = resolve_species_icon_base(resolved_preview_species, preview_icon_base_id)
	var/list/preview_gear_recipes = build_species_preview_gear_recipes(resolved_preview_species, user, resolved_preview_icon_base)
	for(var/species_name in species_list)
		CUSTOM_MARKING_CHECK_TICK
		var/datum/species/species = GLOB.all_species?[species_name]
		if(!istype(species))
			continue
		var/species_gender_suffix = resolve_species_body_preview_gender_suffix(species)
		var/list/static_def = species_catalog?[species_name]
		if(!islist(static_def))
			static_def = build_static_species_definition(species_name)
		var/list/def = islist(static_def) ? static_def.Copy() : list(
			"id" = species_name,
			"name" = istext(species.name) && length(species.name) ? species.name : "[species_name]",
			"modifiers" = list(),
			"traits" = list(),
			"detail_sections" = list(),
			"icon_base_count" = 0
		)
		if(species_name == SPECIES_CUSTOM)
			def["name"] = SPECIES_CUSTOM
		var/list/detail_notes = species.get_species_detail_notes(user)
		if(islist(detail_notes) && detail_notes.len)
			var/list/detail_sections = custom_marking_copy_species_detail_sections(def["detail_sections"])
			if(!islist(detail_sections))
				detail_sections = list()
			custom_marking_append_species_detail_notes(detail_sections, detail_notes)
			def["detail_sections"] = detail_sections
		var/resolved_species_icon_base = resolve_species_icon_base(species_name)
		var/list/body_preview_sources = build_cached_species_body_preview_sources(species_name, resolved_species_icon_base, species_gender_suffix, FALSE)
		if(islist(body_preview_sources) && body_preview_sources.len)
			var/list/body_preview_references = build_static_preview_source_references(body_preview_sources)
			if(species_name == resolved_preview_species)
				body_preview_references = attach_species_preview_gear_recipes(body_preview_references, preview_gear_recipes)
			def["body_preview_sources"] = body_preview_references
		var/body_color_blend_mode = null
		var/body_color_base_id = resolve_species_body_preview_base(species_name, resolved_species_icon_base)
		var/datum/species/body_color_species = GLOB.all_species?[body_color_base_id]
		if(istype(body_color_species))
			body_color_blend_mode = resolve_static_species_body_color_blend_mode(body_color_species)
		if(!isnull(body_color_blend_mode))
			def["body_color_blend_mode"] = body_color_blend_mode
		var/list/body_preview_digitigrade_assets = build_species_digitigrade_preview_assets(species_name, resolved_species_icon_base, species_gender_suffix)
		if(islist(body_preview_digitigrade_assets) && body_preview_digitigrade_assets.len)
			def["body_preview_digitigrade_assets"] = body_preview_digitigrade_assets
		var/requires_whitelist = (species.spawn_flags & SPECIES_IS_WHITELISTED) != 0
		def["whitelist_locked"] = requires_whitelist && !is_alien_whitelisted(user, species)
		var/selectable = is_species_selectable(user, species)
		def["selectable"] = selectable
		if(!selectable)
			def["restricted_reason"] = resolve_species_restriction_reason(user, species)
		definitions += list(def)
	payload["species"] = definitions
	payload["selected_species"] = prefs.species
	payload["preview_species"] = resolved_preview_species
	payload["selected_icon_base"] = prefs.custom_base
	payload["preview_icon_base"] = resolved_preview_icon_base || prefs.custom_base
	var/list/icon_base_options = build_species_icon_base_options(resolved_preview_species)
	if(islist(icon_base_options) && icon_base_options.len)
		for(var/list/icon_base_option as anything in icon_base_options)
			if(icon_base_option?["id"] != resolved_preview_icon_base)
				continue
			icon_base_option["body_preview_sources"] = attach_species_preview_gear_recipes(icon_base_option["body_preview_sources"], preview_gear_recipes)
		payload["icon_base_options"] = icon_base_options
	payload["custom_species"] = custom_species_name
	payload["custom_species_max_length"] = MAX_NAME_LEN
	custom_marking_end_manual_yield(yield_context)
	return payload

// TGUI module for editing and previewing custom markings
/datum/tgui_module/custom_marking_designer
	name = "Character Designer"
	tgui_id = "CustomMarkingDesigner"

	var/datum/preferences/prefs // Owning preferences datum
	var/datum/custom_marking/mark // Marking being edited
	var/initial_tab = "custom" // Which tab to show on open
	var/last_preview_bundle_revision = 0 // Tracks latest preview revision sent with preview_sources
	var/allow_custom_tab = TRUE // Gate custom tab when no mark exists
	var/active_dir = NORTH // Active direction (NORTH/SOUTH/EAST/WEST)
	var/active_body_part // Currently active body part for editing
	var/is_new_mark = FALSE // Track whether this marking was created during this editor session
	var/list/initial_snapshot // Snapshot of serialized data for reverting
	var/list/direction_order // Direction order for UI
	var/list/sessions // Cached painting sessions by direction/part
	var/original_mark_id // Original ids/styles when the editor opened
	var/original_style_name // Original style name when the editor opened
	var/diff_sequence = 0 // Tracks incremental ids for live diffs
	var/session_token // Tokens for session/state coherence with the client
	var/state_session_token // Token for syncing local UI state
	var/body_part_layer_revision = 0 // Revisions for overlay layers
	var/preview_revision = 1 // Revisions for preview bundles
	var/body_preview_revision = 1 // Revisions for stripped body preview bundles
	var/species_save_result_revision = 0
	var/traits_revision = 1 // Revisions for character trait payloads
	var/traits_save_result_revision = 0
	var/preview_refresh_token = 0 // Tracks external preview refresh triggers
	var/mark_dirty = FALSE // Dirty flag for pending save
	var/save_in_progress = FALSE // Server-side guard against duplicate save actions
	var/body_markings_refresh_pending = FALSE // Defer body preview rebuild until body tab is opened
	var/list/reference_payload_cache // Cached mannequin payloads
	var/reference_cache_signature // Signature key for reference payload cache
	var/reference_mannequin_signature // Signature key for mannequin state cache
	var/reference_build_in_progress = FALSE // Prevent overlapping mannequin rebuilds
	var/list/reference_pending_request // Latest pending mannequin rebuild request
	var/list/body_reference_payload_cache // Cached stripped mannequin payloads for body tab
	var/body_reference_cache_signature // Signature key for stripped reference cache
	var/body_reference_mannequin_signature // Signature key for stripped mannequin state cache
	var/body_reference_build_in_progress = FALSE // Prevent overlapping stripped mannequin rebuilds
	var/list/body_reference_pending_request // Latest pending stripped mannequin rebuild request
	var/preview_payload_build_in_progress = FALSE
	var/reference_asset_token_counter = 0 // Asset token generator
	var/list/reference_asset_signature_cache
	var/list/reference_asset_pending_icons
	var/reference_dynamic_atlas_counter = 0
	var/list/icon_shift_map // Per-icon shift tracking
	var/use_shared_atlas = FALSE
	var/list/shared_static_preview_bundle_cache
	var/shared_static_preview_failure_reason
	var/list/shared_static_preview_reported_failures
	var/mob/living/carbon/human/dummy/mannequin/custom_marking_gear/gear_recipe_mannequin
	var/list/static_gear_recipe_cache
	var/list/static_gear_reported_failures
	var/list/basic_appearance_definition_context_cache
	var/list/body_marking_definition_context_cache
	var/body_marking_chunk_token // Active chunk token for body markings tab saves
	var/list/body_marking_chunk_buffer // Accumulator for chunked body marking payloads
	var/list/body_marking_chunk_order // Accumulator for body marking order across chunks
	var/body_marking_chunk_expected = 0 // Expected chunk count for current body marking save
	var/body_marking_chunk_received = 0 // Received chunk counter for current body marking save
	var/static_atlas_wait_timer
	var/datum/weakref/static_atlas_wait_user
	var/static_manifest_client_ready = FALSE

// Broadcast a partial update about reference build state without forcing tgui_data  (Lira, December 2025)
/datum/tgui_module/custom_marking_designer/proc/broadcast_reference_build_state(state)
	var/key = "[REF(src)]"
	var/list/open_list = SStgui.open_uis_by_src?[key]
	if(!islist(open_list) || !open_list.len)
		return
	for(var/datum/tgui/ui in open_list)
		if(!ui || ui.src_object != src || !ui.user)
			continue
		ui.send_update(list("reference_build_in_progress" = !!state), TRUE)

// Use the standard always-open TGUI state for this editor
/datum/tgui_module/custom_marking_designer/tgui_state(mob/user)
	return GLOB.tgui_always_state

/datum/tgui_module/custom_marking_designer/ui_assets(mob/user)
	var/list/assets = ..()
	var/datum/asset/spritesheet/custom_marking_designer/atlas = get_asset_datum(/datum/asset/spritesheet/custom_marking_designer)
	if(atlas.is_ready())
		assets += atlas
	return assets

/datum/tgui_module/custom_marking_designer/proc/wait_for_static_atlas_prewarm(mob/user)
	if(!SScustom_marking?.is_static_atlas_prewarm_pending())
		return FALSE
	if(prefs)
		prefs.open_custom_marking_designer_loading(user)
	static_atlas_wait_user = WEAKREF(user)
	if(!static_atlas_wait_timer)
		static_atlas_wait_timer = addtimer(CALLBACK(src, PROC_REF(resume_after_static_atlas_prewarm)), 1, TIMER_STOPPABLE)
	return TRUE

/datum/tgui_module/custom_marking_designer/proc/resume_after_static_atlas_prewarm()
	static_atlas_wait_timer = null
	if(SScustom_marking?.is_static_atlas_prewarm_pending())
		static_atlas_wait_timer = addtimer(CALLBACK(src, PROC_REF(resume_after_static_atlas_prewarm)), 1, TIMER_STOPPABLE)
		return
	var/mob/user = static_atlas_wait_user?.resolve()
	static_atlas_wait_user = null
	if(!user?.client)
		prefs?.close_custom_marking_designer_loading()
		return
	tgui_interact(user)

/datum/tgui_module/custom_marking_designer/tgui_interact(mob/user, datum/tgui/ui = null, datum/tgui/parent_ui = null)
	if(wait_for_static_atlas_prewarm(user))
		return
	..(user, ui, parent_ui)
	var/datum/tgui/instanced_ui = SStgui.get_open_ui(user, src)
	if(instanced_ui)
		instanced_ui.set_autoupdate(FALSE)
		if(static_manifest_client_ready)
			prefs?.close_custom_marking_designer_loading()
	return instanced_ui

// Finalize edits and refresh previews when the UI closes
/datum/tgui_module/custom_marking_designer/tgui_close(mob/user)
	var/saved = save_marking_changes(mark_dirty, TRUE)
	. = ..()
	if(saved && prefs && user)
		prefs.skip_custom_marking_cache_invalidation_once = TRUE
		prefs.ShowChoices(user)
	if(prefs)
		prefs.custom_marking_designer_ui = null
		prefs.close_custom_marking_designer_loading()
	static_manifest_client_ready = FALSE
	reset_body_marking_chunk_state()
	return .

/datum/tgui_module/custom_marking_designer/Destroy()
	if(static_atlas_wait_timer)
		deltimer(static_atlas_wait_timer)
		static_atlas_wait_timer = null
	static_atlas_wait_user = null
	static_manifest_client_ready = FALSE
	prefs?.close_custom_marking_designer_loading()
	if(prefs?.custom_marking_designer_ui == src)
		prefs.custom_marking_designer_ui = null
	reset_body_marking_chunk_state()
	if(islist(sessions))
		QDEL_LIST_ASSOC_VAL(sessions)
	if(gear_recipe_mannequin)
		qdel(gear_recipe_mannequin)
		gear_recipe_mannequin = null
	prefs = null
	mark = null
	initial_snapshot = null
	direction_order = null
	sessions = null
	reference_payload_cache = null
	reference_cache_signature = null
	reference_mannequin_signature = null
	reference_pending_request = null
	body_reference_payload_cache = null
	body_reference_cache_signature = null
	body_reference_mannequin_signature = null
	body_reference_pending_request = null
	preview_payload_build_in_progress = FALSE
	icon_shift_map = null
	shared_static_preview_bundle_cache = null
	shared_static_preview_failure_reason = null
	shared_static_preview_reported_failures = null
	static_gear_recipe_cache = null
	static_gear_reported_failures = null
	basic_appearance_definition_context_cache = null
	body_marking_definition_context_cache = null
	return ..()

/datum/tgui_module/custom_marking_designer/proc/acquire_preview_payload_build_lock()
	while(preview_payload_build_in_progress)
		sleep(world.tick_lag > 0 ? world.tick_lag : 1)
	preview_payload_build_in_progress = TRUE

/datum/tgui_module/custom_marking_designer/proc/release_preview_payload_build_lock()
	preview_payload_build_in_progress = FALSE

/datum/tgui_module/custom_marking_designer/proc/invalidate_reference_payload_caches()
	reference_cache_signature = null
	reference_mannequin_signature = null
	reference_payload_cache = null
	reference_pending_request = null
	body_reference_cache_signature = null
	body_reference_mannequin_signature = null
	body_reference_payload_cache = null
	body_reference_pending_request = null
	shared_static_preview_failure_reason = null
	reference_asset_signature_cache = null
	reference_asset_pending_icons = null
	reference_dynamic_atlas_counter = 0
	if(prefs)
		prefs.custom_marking_reference_signature = null
		prefs.custom_marking_reference_payload_cache = null
		prefs.custom_marking_reference_mannequin_signature = null
		prefs.custom_marking_body_reference_signature = null
		prefs.custom_marking_body_reference_payload_cache = null
		prefs.custom_marking_body_reference_mannequin_signature = null

// Set up the designer for an existing or newly created marking
/datum/tgui_module/custom_marking_designer/New(datum/preferences/pref, datum/custom_marking/existing, initial_tab_override = "custom", skip_mark_create = FALSE)
	..()
	prefs = pref
	if(prefs)
		reference_payload_cache = islist(prefs.custom_marking_reference_payload_cache) ? prefs.custom_marking_reference_payload_cache : null
		reference_cache_signature = prefs.custom_marking_reference_signature
		reference_mannequin_signature = prefs.custom_marking_reference_mannequin_signature
		body_reference_payload_cache = islist(prefs.custom_marking_body_reference_payload_cache) ? prefs.custom_marking_body_reference_payload_cache : null
		body_reference_cache_signature = prefs.custom_marking_body_reference_signature
		body_reference_mannequin_signature = prefs.custom_marking_body_reference_mannequin_signature
	else
		reference_payload_cache = null
		reference_cache_signature = null
		reference_mannequin_signature = null
		body_reference_payload_cache = null
		body_reference_cache_signature = null
		body_reference_mannequin_signature = null
	if(istext(initial_tab_override) && length(initial_tab_override))
		initial_tab = initial_tab_override
	else
		initial_tab = "custom"
	if(existing)
		mark = existing
	else if(!skip_mark_create)
		var/owner = pref?.client_ckey || pref?.client?.ckey || "custom"
		var/id = generate_custom_marking_id(owner)
		mark = new(id, "New Custom Marking", list(BP_TORSO), owner)
		mark.register()
		if(pref)
			LAZYINITLIST(pref.custom_markings)
			pref.custom_markings[mark.id] = mark
		is_new_mark = TRUE
	else
		mark = null
		is_new_mark = FALSE
	allow_custom_tab = !!mark
	if(!allow_custom_tab && initial_tab == "custom")
		initial_tab = "body"
	preview_revision = 1
	last_preview_bundle_revision = preview_revision
	initial_snapshot = mark?.to_save()
	if(mark)
		register_custom_marking_style(mark, TRUE)
	original_mark_id = mark?.id
	original_style_name = mark?.get_style_name()
	direction_order = list(NORTH, SOUTH, EAST, WEST)
	sessions = list()
	active_body_part = default_body_part()
	session_token = REF(src)
	state_session_token = session_token

// Ensure there is always a valid body part focus for editing
/datum/tgui_module/custom_marking_designer/proc/default_body_part()
	if(mark?.body_parts && mark.body_parts.len)
		return mark.body_parts[1]
	if(mark)
		if(!mark.body_parts)
			mark.body_parts = list()
		if(!(BP_TORSO in mark.body_parts))
			mark.body_parts += BP_TORSO
			mark.ensure_part_frames(list(BP_TORSO))
	return BP_TORSO

/datum/tgui_module/custom_marking_designer/proc/resolve_trait_category_id(datum/trait/trait)
	if(!istype(trait))
		return null
	if(trait.category > TRAIT_TYPE_NEUTRAL)
		return "positive"
	if(trait.category < TRAIT_TYPE_NEUTRAL)
		return "negative"
	return "neutral"

/datum/tgui_module/custom_marking_designer/proc/resolve_trait_catalog(category_id)
	if(!prefs || !istext(category_id))
		return null
	switch(category_id)
		if("positive")
			return positive_traits_map[prefs.species]
		if("neutral")
			return neutral_traits_map[prefs.species]
		if("negative")
			return negative_traits_map[prefs.species]
	return null

/datum/tgui_module/custom_marking_designer/proc/resolve_selected_traits(category_id)
	if(!prefs || !istext(category_id))
		return null
	switch(category_id)
		if("positive")
			return prefs.pos_traits
		if("neutral")
			return prefs.neu_traits
		if("negative")
			return prefs.neg_traits
	return null

/datum/tgui_module/custom_marking_designer/proc/repair_character_trait_preferences()
	if(!prefs)
		return FALSE
	for(var/category_id in list("positive", "neutral", "negative"))
		var/list/selected_traits = resolve_selected_traits(category_id)
		if(!islist(selected_traits))
			continue
		for(var/trait_path in selected_traits)
			var/datum/trait/trait = all_traits[trait_path]
			if(!istype(trait) || !LAZYLEN(trait.has_preferences))
				continue
			var/list/default_preferences = trait.get_default_prefs()
			if(!islist(default_preferences))
				continue
			var/list/stored_preferences = selected_traits[trait_path]
			if(!islist(stored_preferences))
				stored_preferences = list()
				selected_traits[trait_path] = stored_preferences
			for(var/preference_id in trait.has_preferences)
				if(!(preference_id in stored_preferences))
					stored_preferences[preference_id] = default_preferences[preference_id]
	return TRUE

/datum/tgui_module/custom_marking_designer/proc/resolve_traits_preview_scale()
	var/list/scale = list(
		"icon_scale_x" = 1,
		"icon_scale_y" = 1
	)
	if(!prefs)
		return scale
	var/list/selected_traits = prefs.pos_traits + prefs.neu_traits + prefs.neg_traits
	for(var/trait_path in selected_traits)
		var/datum/trait/trait = all_traits[trait_path]
		if(!istype(trait) || !islist(trait.var_changes))
			continue
		var/scale_x = trait.var_changes["icon_scale_x"]
		var/scale_y = trait.var_changes["icon_scale_y"]
		if(isnum(scale_x) && scale_x > 0)
			scale["icon_scale_x"] = scale_x
		if(isnum(scale_y) && scale_y > 0)
			scale["icon_scale_y"] = scale_y
	return scale

/datum/tgui_module/custom_marking_designer/proc/append_traits_preview_scale(list/payload)
	if(!islist(payload))
		return
	var/list/scale = resolve_traits_preview_scale()
	payload["trait_icon_scale_x"] = scale["icon_scale_x"]
	payload["trait_icon_scale_y"] = scale["icon_scale_y"]

/datum/tgui_module/custom_marking_designer/proc/resolve_trait_anatomy_restriction(datum/trait/trait)
	if(!prefs || !istype(trait))
		return "Trait data is unavailable."
	var/is_synthetic = !!prefs.organ_data?[O_BRAIN]
	if(is_synthetic && !(trait.can_take & SYNTHETICS))
		return "Available to organic characters only."
	if(!is_synthetic && !(trait.can_take & ORGANICS))
		return "Available to synthetic characters only."
	return null

/datum/tgui_module/custom_marking_designer/proc/character_traits_conflict(trait_path, datum/trait/trait, selected_path, datum/trait/selected_trait)
	if(!trait_path || !istype(trait) || !selected_path || !istype(selected_trait))
		return FALSE
	if(selected_path == trait_path)
		return TRUE
	if(islist(trait.excludes) && (selected_path in trait.excludes))
		return TRUE
	if(islist(selected_trait.excludes) && (trait_path in selected_trait.excludes))
		return TRUE
	if(islist(trait.var_changes) && islist(selected_trait.var_changes))
		for(var/changed_var in trait.var_changes)
			if(changed_var in selected_trait.var_changes)
				return TRUE
	if(islist(trait.var_changes_pref) && islist(selected_trait.var_changes_pref))
		for(var/changed_pref in trait.var_changes_pref)
			if(changed_pref in selected_trait.var_changes_pref)
				return TRUE
	return FALSE

/datum/tgui_module/custom_marking_designer/proc/resolve_character_trait_conflict(trait_path, datum/trait/trait, list/selected_paths)
	if(!trait_path || !istype(trait) || !islist(selected_paths))
		return null
	for(var/selected_path in selected_paths)
		var/datum/trait/selected_trait = all_traits[selected_path]
		if(!istype(selected_trait))
			continue
		if(character_traits_conflict(trait_path, trait, selected_path, selected_trait))
			return selected_trait.name
	return null

/datum/tgui_module/custom_marking_designer/proc/build_character_trait_conflict_ids(trait_path, datum/trait/trait, list/trait_paths)
	var/list/conflicts = list()
	if(!trait_path || !istype(trait) || !islist(trait_paths))
		return conflicts
	for(var/selected_path in trait_paths)
		if(selected_path == trait_path)
			continue
		var/datum/trait/selected_trait = all_traits[selected_path]
		if(character_traits_conflict(trait_path, trait, selected_path, selected_trait))
			conflicts += "[selected_path]"
	return conflicts

/datum/tgui_module/custom_marking_designer/proc/build_trait_preference_entries(trait_path, datum/trait/trait, list/selected_traits)
	var/list/entries = list()
	if(!istype(trait) || !LAZYLEN(trait.has_preferences))
		return entries
	var/list/stored_preferences = islist(selected_traits?[trait_path]) ? selected_traits[trait_path] : null
	var/list/default_preferences = trait.get_default_prefs()
	for(var/preference_id in trait.has_preferences)
		var/list/preference_definition = trait.has_preferences[preference_id]
		if(!islist(preference_definition) || preference_definition.len < 2)
			continue
		var/preference_value = null
		if(islist(stored_preferences) && (preference_id in stored_preferences))
			preference_value = stored_preferences[preference_id]
		else if(islist(default_preferences))
			preference_value = default_preferences[preference_id]
		var/preference_kind
		switch(preference_definition[1])
			if(TRAIT_PREF_TYPE_BOOLEAN)
				preference_kind = "boolean"
			if(TRAIT_PREF_TYPE_COLOR)
				preference_kind = "color"
			if(TRAIT_PREF_TYPE_STRING)
				preference_kind = "string"
				if(istext(preference_value))
					preference_value = html_decode(preference_value)
			if(TRAIT_PREF_TYPE_INT)
				preference_kind = "number"
			if(TRAIT_PREF_TYPE_LIST)
				preference_kind = "list"
		if(!preference_kind)
			continue
		var/list/entry = list(
			"id" = "[preference_id]",
			"label" = "[preference_definition[2]]",
			"kind" = preference_kind,
			"value" = preference_value
		)
		if(preference_definition[1] == TRAIT_PREF_TYPE_LIST)
			var/list/options = trait.vars?["list_options"]
			if(islist(options))
				entry["options"] = options.Copy()
		entries += list(entry)
	return entries

/datum/tgui_module/custom_marking_designer/proc/build_character_trait_entry(trait_path, datum/trait/trait, list/trait_catalog, list/selected_traits, list/all_trait_paths)
	if(!istype(trait))
		return null
	var/is_selected = (trait_path in selected_traits)
	var/list/entry = list(
		"id" = "[trait_path]",
		"name" = "[trait.name]",
		"description" = "[trait.desc]",
		"selected" = is_selected,
		"conflicts" = build_character_trait_conflict_ids(trait_path, trait, all_trait_paths)
	)
	if(islist(trait.var_changes))
		var/preview_scale_x = trait.var_changes["icon_scale_x"]
		var/preview_scale_y = trait.var_changes["icon_scale_y"]
		if(isnum(preview_scale_x))
			entry["icon_scale_x"] = preview_scale_x
		if(isnum(preview_scale_y))
			entry["icon_scale_y"] = preview_scale_y
	if(islist(trait.var_changes_pref) && isnum(trait.var_changes_pref["extra_languages"]))
		entry["extra_language_slots"] = trait.var_changes_pref["extra_languages"]
	var/default_tutorial = "This trait has no detailed tutorial yet. Suggest one at #Dev-Suggestions on the discord!"
	if(istext(trait.tutorial) && length(trait.tutorial) && trait.tutorial != default_tutorial)
		entry["tutorial"] = trait.tutorial
	var/anatomy_restriction = resolve_trait_anatomy_restriction(trait)
	if(is_selected)
		if(!(trait_path in trait_catalog))
			var/unavailable_reason = "This saved trait is not available to the current species and may be removed during character validation."
			entry["warning_reason"] = unavailable_reason
			entry["disabled_reason"] = unavailable_reason
		else if(anatomy_restriction)
			entry["warning_reason"] = anatomy_restriction
			entry["disabled_reason"] = anatomy_restriction
	else if(anatomy_restriction)
		entry["disabled_reason"] = anatomy_restriction
	var/list/preference_entries = build_trait_preference_entries(trait_path, trait, selected_traits)
	if(preference_entries.len)
		entry["preferences"] = preference_entries
	return entry

/datum/tgui_module/custom_marking_designer/proc/build_character_trait_category(category_id, list/all_trait_paths)
	var/list/trait_catalog = resolve_trait_catalog(category_id)
	if(!islist(trait_catalog))
		trait_catalog = list()
	var/list/selected_traits = resolve_selected_traits(category_id)
	if(!islist(selected_traits))
		selected_traits = list()
	var/category_name
	var/category_summary
	switch(category_id)
		if("positive")
			category_name = "Positive Traits"
			category_summary = "Powerful advantages that each use one limited trait slot."
		if("neutral")
			category_name = "Neutral Traits"
			category_summary = "Identity and playstyle options with no limited slot cost."
		if("negative")
			category_name = "Negative Traits"
			category_summary = "Meaningful tradeoffs with no selection limit."
	if(!category_name)
		return null
	var/list/trait_paths = list()
	for(var/trait_path in trait_catalog)
		trait_paths += trait_path
	for(var/selected_path in selected_traits)
		if(!(selected_path in trait_paths))
			trait_paths += selected_path
	var/list/trait_entries = list()
	for(var/trait_path in trait_paths)
		var/datum/trait/trait = all_traits[trait_path]
		var/list/entry = build_character_trait_entry(trait_path, trait, trait_catalog, selected_traits, all_trait_paths)
		if(islist(entry))
			trait_entries += list(entry)
	return list(
		"id" = category_id,
		"name" = category_name,
		"summary" = category_summary,
		"selected_count" = selected_traits.len,
		"traits" = trait_entries
	)

/datum/tgui_module/custom_marking_designer/proc/format_character_persistence_value(value)
	if(isnull(value))
		return "None"
	if(istext(value) || isnum(value) || ispath(value))
		return "[value]"
	if(islist(value))
		var/encoded_value
		try
			encoded_value = json_encode(value)
		catch
			encoded_value = null
		if(istext(encoded_value) && length(encoded_value))
			return encoded_value
	return "[value]"

/datum/tgui_module/custom_marking_designer/proc/build_character_persistence_details(list/source, list/ignored_keys)
	var/list/details = list()
	if(!islist(source) || !source.len)
		return details
	for(var/key in source)
		if(islist(ignored_keys) && (key in ignored_keys))
			continue
		var/label = capitalize(replacetext("[key]", "_", " "))
		if(findtext(label, "Ui ") == 1)
			label = "UI [copytext(label, 4)]"
		details += list(list(
			"label" = label,
			"value" = format_character_persistence_value(source[key])
		))
	return details

/datum/tgui_module/custom_marking_designer/proc/build_character_persistence_payload()
	var/list/payload = list(
		"character_name" = prefs?.real_name || "Selected character",
		"experience" = list(),
		"nif" = list(
			"present" = FALSE,
			"details" = list()
		),
		"pet" = list(
			"present" = FALSE,
			"details" = list()
		)
	)
	if(!prefs)
		return payload

	var/client/owner_client = prefs.client
	var/datum/etching/etching = owner_client?.etching
	if(etching)
		if(islist(etching.xp))
			var/list/experience = list()
			for(var/kind in etching.xp)
				var/amount = etching.xp[kind]
				if(!isnum(amount))
					continue
				experience += list(list(
					"label" = capitalize("[kind]"),
					"value" = amount
				))
			payload["experience"] = experience

		var/resolved_nif_type = etching.nif_type
		if(istext(resolved_nif_type))
			resolved_nif_type = text2path(resolved_nif_type)
		if(ispath(resolved_nif_type, /obj/item/device/nif))
			var/obj/item/device/nif/resolved_nif_path = resolved_nif_type
			var/current_durability = isnum(etching.nif_durability) ? etching.nif_durability : 0
			var/maximum_durability = initial(resolved_nif_path.durability)
			var/durability_percent = maximum_durability > 0 ? round(clamp(current_durability / maximum_durability * 100, 0, 100), 0.1) : null
			payload["nif"] = list(
				"present" = TRUE,
				"name" = initial(resolved_nif_path.name),
				"durability" = current_durability,
				"max_durability" = maximum_durability,
				"durability_percent" = durability_percent,
				"details" = build_character_persistence_details(etching.nif_savedata, null)
			)

	if(!owner_client?.ckey)
		return payload
	var/pet_path = "data/player_saves/[copytext(owner_client.ckey, 1, 2)]/[owner_client.ckey]/pet/slot[prefs.default_slot].json"
	if(!fexists(pet_path))
		return payload
	var/pet_text
	try
		pet_text = file2text(pet_path)
	catch
		payload["pet"]["error"] = "The stored pet record could not be read."
		return payload
	if(!istext(pet_text) || !length(pet_text))
		payload["pet"]["error"] = "The stored pet record is empty."
		return payload
	var/list/pet_data
	try
		pet_data = json_decode(pet_text)
	catch
		payload["pet"]["error"] = "The stored pet record could not be decoded."
		return payload
	if(!islist(pet_data))
		payload["pet"]["error"] = "The stored pet record is invalid."
		return payload

	var/resolved_pet_type = pet_data["type"]
	if(istext(resolved_pet_type))
		resolved_pet_type = text2path(resolved_pet_type)
	var/pet_species = "Unknown pet type"
	if(ispath(resolved_pet_type, /mob/living/simple_mob))
		var/mob/living/simple_mob/resolved_pet_path = resolved_pet_type
		pet_species = initial(resolved_pet_path.name)
	payload["pet"] = list(
		"present" = TRUE,
		"name" = istext(pet_data["name"]) && length(pet_data["name"]) ? pet_data["name"] : "Unnamed pet",
		"species" = pet_species,
		"details" = build_character_persistence_details(pet_data, list("ckey", "type", "name"))
	)
	return payload

/datum/tgui_module/custom_marking_designer/proc/resolve_character_language_catalog(mob/user, datum/species/selected_species)
	var/list/available_languages = list()
	if(!istype(selected_species))
		return available_languages
	for(var/language_name in GLOB.all_languages)
		var/datum/language/language_datum = GLOB.all_languages[language_name]
		if(!istype(language_datum) || (language_datum.flags & RESTRICTED))
			continue
		if((islist(selected_species.secondary_langs) && (language_name in selected_species.secondary_langs)) || is_lang_whitelisted(user, language_datum))
			available_languages |= language_name
	available_languages -= selected_species.language
	available_languages -= selected_species.default_language
	return available_languages

/datum/tgui_module/custom_marking_designer/proc/resolve_character_language_custom_key(language_name)
	if(!prefs || !islist(prefs.language_custom_keys))
		return null
	for(var/custom_key in prefs.language_custom_keys)
		if(prefs.language_custom_keys[custom_key] == language_name && character_language_custom_key_is_valid(custom_key))
			return custom_key
	return null

/datum/tgui_module/custom_marking_designer/proc/build_character_languages_payload(mob/user)
	if(!prefs)
		return null
	var/datum/species/selected_species = GLOB.all_species?[prefs.species]
	if(!istype(selected_species))
		return null
	var/list/alternate_languages = islist(prefs.alternate_languages) ? prefs.alternate_languages : list()
	var/list/available_languages = resolve_character_language_catalog(user, selected_species)
	var/list/language_names = list()
	for(var/language_name in GLOB.all_languages)
		var/datum/language/language_datum = GLOB.all_languages[language_name]
		if(istype(language_datum) && !(language_datum.flags & RESTRICTED))
			language_names |= language_name
	if(selected_species.language)
		language_names |= selected_species.language
	if(selected_species.default_language)
		language_names |= selected_species.default_language
	for(var/language_name in alternate_languages)
		language_names |= language_name
	for(var/language_name in available_languages)
		language_names |= language_name
	language_names |= LANGUAGE_GALCOM
	if(prefs.preferred_language)
		language_names |= prefs.preferred_language

	var/list/entries = list()
	for(var/language_name in language_names)
		var/datum/language/language_datum = GLOB.all_languages?[language_name]
		var/is_automatic = language_name == selected_species.language || language_name == selected_species.default_language
		var/is_selectable = (language_name in available_languages)
		var/is_selected = is_automatic || (language_name in alternate_languages)
		var/is_preferred_always = language_name == selected_species.language || language_name == LANGUAGE_GALCOM
		var/is_preferred_eligible = is_preferred_always || (language_name in alternate_languages)
		var/list/entry = list(
			"id" = language_name,
			"name" = language_datum?.name || language_name,
			"description" = istext(language_datum?.desc) && length(language_datum.desc) ? language_datum.desc : "No language description is available.",
			"selected" = is_selected,
			"automatic" = is_automatic,
			"selectable" = is_selectable,
			"preferred_always" = is_preferred_always,
			"preferred_eligible" = is_preferred_eligible,
			"preferred" = prefs.preferred_language == language_name,
			"custom_key" = is_selected ? resolve_character_language_custom_key(language_name) : null
		)
		if((language_name in alternate_languages) && !is_selectable)
			entry["disabled_reason"] = "This saved language is no longer available to the current character. Remove it before saving."
		else if(!is_selected && !is_selectable && !is_preferred_always)
			entry["disabled_reason"] = "This language is not available to the current character."
		entries += list(entry)

	var/base_optional_slots = isnum(selected_species.num_alternate_languages) ? max(0, selected_species.num_alternate_languages) : 0
	var/optional_limit = max(0, base_optional_slots + (isnum(prefs.extra_languages) ? prefs.extra_languages : 0))
	var/list/language_prefixes = islist(prefs.language_prefixes) && prefs.language_prefixes.len ? prefs.language_prefixes.Copy() : config.language_prefixes.Copy()
	return list(
		"base_optional_slots" = base_optional_slots,
		"optional_limit" = optional_limit,
		"selected_optional_count" = alternate_languages.len,
		"preferred_language" = prefs.preferred_language || selected_species.language || LANGUAGE_GALCOM,
		"preferred_fallback" = selected_species.language || LANGUAGE_GALCOM,
		"language_prefixes" = language_prefixes,
		"default_language_prefixes" = config.language_prefixes.Copy(),
		"entries" = entries
	)

/datum/tgui_module/custom_marking_designer/proc/build_traits_payload(mob/user)
	if(!prefs)
		return null
	repair_character_trait_preferences()
	var/limited_traits_selected = prefs.pos_traits.len
	var/traits_remaining = prefs.max_traits - limited_traits_selected
	var/list/all_trait_paths = list()
	for(var/category_id in list("positive", "neutral", "negative"))
		var/list/trait_catalog = resolve_trait_catalog(category_id)
		if(islist(trait_catalog))
			for(var/trait_path in trait_catalog)
				if(!(trait_path in all_trait_paths))
					all_trait_paths += trait_path
		var/list/selected_traits = resolve_selected_traits(category_id)
		if(islist(selected_traits))
			for(var/selected_path in selected_traits)
				if(!(selected_path in all_trait_paths))
					all_trait_paths += selected_path
	var/list/categories = list()
	for(var/category_id in list("positive", "neutral", "negative"))
		var/list/category = build_character_trait_category(category_id, all_trait_paths)
		if(islist(category))
			categories += list(category)
	var/datum/species/selected_species = GLOB.all_species?[prefs.species]
	var/species_name = selected_species?.name || prefs.species
	if(prefs.species == SPECIES_CUSTOM && istext(prefs.custom_species) && length(prefs.custom_species))
		species_name = prefs.custom_species
	return list(
		"revision" = traits_revision,
		"species_id" = prefs.species,
		"species_name" = species_name,
		"anatomy" = prefs.organ_data?[O_BRAIN] ? "Synthetic" : "Organic",
		"max_traits" = prefs.max_traits,
		"limited_traits_selected" = limited_traits_selected,
		"traits_remaining" = traits_remaining,
		"neutral_traits_selected" = prefs.neu_traits.len,
		"total_selected" = prefs.pos_traits.len + prefs.neu_traits.len + prefs.neg_traits.len,
		"persistence" = build_character_persistence_payload(),
		"languages" = build_character_languages_payload(user),
		"categories" = categories
	)

/datum/tgui_module/custom_marking_designer/proc/send_traits_payload(mob/user, list/save_result = null)
	if(!user || !prefs)
		return FALSE
	var/list/payload = build_traits_payload(user)
	if(!islist(payload))
		return FALSE
	var/list/update = list(
		"traits_revision" = traits_revision,
		"traits_species" = prefs.species,
		"traits_payload" = payload
	)
	if(islist(save_result))
		update["traits_save_result"] = save_result
	append_traits_preview_scale(update)
	var/datum/tgui/active_ui = SStgui.get_open_ui(user, src)
	if(active_ui)
		active_ui.send_update(update)
	else
		SStgui.update_uis(src, update)
	return TRUE

/datum/tgui_module/custom_marking_designer/proc/build_traits_save_result(request_id, accepted, list/rejection_reasons = null)
	if(!istext(request_id) || !length(request_id))
		return null
	traits_save_result_revision++
	var/list/result = list(
		"revision" = traits_save_result_revision,
		"request_id" = request_id,
		"accepted" = !!accepted,
		"traits_revision" = traits_revision
	)
	if(LAZYLEN(rejection_reasons))
		result["error"] = rejection_reasons[1]
	return result

/datum/tgui_module/custom_marking_designer/proc/reject_character_traits_payload(list/rejection_reasons, reason)
	if(islist(rejection_reasons) && istext(reason) && length(reason))
		rejection_reasons += reason
	return FALSE

/datum/tgui_module/custom_marking_designer/proc/sanitize_character_trait_preferences(datum/trait/trait, list/incoming_preferences)
	if(!istype(trait) || !LAZYLEN(trait.has_preferences))
		return null
	var/list/default_preferences = trait.get_default_prefs()
	var/list/sanitized_preferences = list()
	for(var/preference_id in trait.has_preferences)
		var/list/preference_definition = trait.has_preferences[preference_id]
		if(!islist(preference_definition) || !preference_definition.len)
			continue
		var/default_value = islist(default_preferences) ? default_preferences[preference_id] : null
		var/incoming_value = islist(incoming_preferences) && (preference_id in incoming_preferences) ? incoming_preferences[preference_id] : default_value
		switch(preference_definition[1])
			if(TRAIT_PREF_TYPE_BOOLEAN)
				var/boolean_value = !!incoming_value
				if(istext(incoming_value))
					boolean_value = (lowertext(incoming_value) in list("1", "true", "yes", "on"))
				sanitized_preferences[preference_id] = boolean_value
			if(TRAIT_PREF_TYPE_COLOR)
				var/default_color = istext(default_value) ? default_value : "#ffffff"
				sanitized_preferences[preference_id] = sanitize_hexcolor(incoming_value, default_color)
			if(TRAIT_PREF_TYPE_STRING)
				var/text_value = istext(incoming_value) ? incoming_value : null
				if(!istext(text_value) || length(text_value) < 3 || length(text_value) > 40)
					text_value = istext(default_value) ? default_value : ""
				sanitized_preferences[preference_id] = html_encode(text_value)
			if(TRAIT_PREF_TYPE_INT)
				var/number_value = incoming_value
				if(!isnum(number_value) && istext(number_value))
					number_value = text2num(number_value)
				if(!isnum(number_value))
					number_value = isnum(default_value) ? default_value : 0
				sanitized_preferences[preference_id] = CLAMP(number_value, 0, 5)
			if(TRAIT_PREF_TYPE_LIST)
				var/list/options = trait.vars?["list_options"]
				var/list_value = incoming_value
				if(!islist(options) || !(list_value in options))
					list_value = islist(options) && (default_value in options) ? default_value : options?[1]
				sanitized_preferences[preference_id] = list_value
	return sanitized_preferences

/datum/tgui_module/custom_marking_designer/proc/store_character_trait_selection(trait_path, datum/trait/trait, list/incoming_preferences, list/positive_traits, list/neutral_traits, list/negative_traits)
	if(!trait_path || !istype(trait))
		return FALSE
	var/list/sanitized_preferences = sanitize_character_trait_preferences(trait, incoming_preferences)
	var/list/target_traits
	switch(resolve_trait_category_id(trait))
		if("positive")
			target_traits = positive_traits
		if("neutral")
			target_traits = neutral_traits
		if("negative")
			target_traits = negative_traits
	if(!islist(target_traits))
		return FALSE
	if(islist(sanitized_preferences))
		target_traits[trait_path] = sanitized_preferences
	else
		target_traits += trait_path
	return TRUE

/datum/tgui_module/custom_marking_designer/proc/resolve_requested_extra_languages(list/requested_paths)
	var/projected_extra_languages = initial(prefs.extra_languages)
	for(var/trait_path in requested_paths)
		var/datum/trait/trait = all_traits[trait_path]
		if(islist(trait?.var_changes_pref) && isnum(trait.var_changes_pref["extra_languages"]))
			projected_extra_languages = trait.var_changes_pref["extra_languages"]
	return projected_extra_languages

/datum/tgui_module/custom_marking_designer/proc/stage_character_languages_payload(list/params, list/requested_paths, mob/user, list/staged_languages, list/rejection_reasons)
	if(!prefs || !islist(params) || !islist(staged_languages))
		return reject_character_traits_payload(rejection_reasons, "Language data is unavailable.")
	var/datum/species/selected_species = GLOB.all_species?[prefs.species]
	if(!istype(selected_species))
		return reject_character_traits_payload(rejection_reasons, "The selected species has no valid language rules.")
	var/projected_extra_languages = resolve_requested_extra_languages(requested_paths)
	var/base_optional_slots = isnum(selected_species.num_alternate_languages) ? selected_species.num_alternate_languages : 0
	var/optional_limit = max(0, base_optional_slots + projected_extra_languages)
	var/languages_included = ("languages" in params)
	if(!languages_included)
		var/list/current_alternate_languages = islist(prefs.alternate_languages) ? prefs.alternate_languages.Copy() : list()
		if(current_alternate_languages.len > optional_limit)
			return reject_character_traits_payload(rejection_reasons, "Your selected traits allow [optional_limit] optional language[optional_limit == 1 ? "" : "s"], but this character currently has [current_alternate_languages.len].")
		staged_languages["alternate_languages"] = current_alternate_languages
		staged_languages["preferred_language"] = prefs.preferred_language
		staged_languages["language_custom_keys"] = islist(prefs.language_custom_keys) ? prefs.language_custom_keys.Copy() : list()
		staged_languages["language_prefixes"] = islist(prefs.language_prefixes) && prefs.language_prefixes.len ? prefs.language_prefixes.Copy() : config.language_prefixes.Copy()
		staged_languages["extra_languages"] = projected_extra_languages
		return TRUE

	var/list/incoming_languages = params["languages"]
	if(!islist(incoming_languages))
		return reject_character_traits_payload(rejection_reasons, "The Traits save did not contain valid language data.")
	var/list/incoming_alternate_languages = incoming_languages["alternate_languages"]
	if(!islist(incoming_alternate_languages))
		return reject_character_traits_payload(rejection_reasons, "The language draft did not contain a valid optional-language list.")
	var/list/available_languages = resolve_character_language_catalog(user, selected_species)
	var/list/requested_alternate_languages = list()
	for(var/language_name in incoming_alternate_languages)
		if(!istext(language_name) || !(language_name in GLOB.all_languages))
			return reject_character_traits_payload(rejection_reasons, "The language draft contained an unknown language.")
		if(language_name in requested_alternate_languages)
			return reject_character_traits_payload(rejection_reasons, "The language draft contained [language_name] more than once.")
		if(!(language_name in available_languages))
			return reject_character_traits_payload(rejection_reasons, "[language_name] is not available to this character. Remove it before saving.")
		requested_alternate_languages += language_name
	if(requested_alternate_languages.len > optional_limit)
		return reject_character_traits_payload(rejection_reasons, "Your selected traits allow [optional_limit] optional language[optional_limit == 1 ? "" : "s"], but [requested_alternate_languages.len] are selected.")

	var/preferred_language = incoming_languages["preferred_language"]
	if(!istext(preferred_language) || !length(preferred_language))
		return reject_character_traits_payload(rejection_reasons, "Choose a preferred language before saving.")
	var/list/preferred_languages = list(selected_species.language, LANGUAGE_GALCOM)
	preferred_languages |= requested_alternate_languages
	if(!(preferred_language in preferred_languages))
		return reject_character_traits_payload(rejection_reasons, "[preferred_language] cannot be used as this character's preferred language.")

	var/list/incoming_custom_keys = incoming_languages["custom_keys"]
	if(!islist(incoming_custom_keys))
		return reject_character_traits_payload(rejection_reasons, "The language draft did not contain valid custom keys.")
	var/list/customizable_languages = list()
	if(selected_species.language)
		customizable_languages |= selected_species.language
	if(selected_species.default_language)
		customizable_languages |= selected_species.default_language
	customizable_languages |= requested_alternate_languages
	var/list/new_language_custom_keys = list()
	for(var/language_name in incoming_custom_keys)
		var/custom_key = incoming_custom_keys[language_name]
		if(!(language_name in customizable_languages))
			return reject_character_traits_payload(rejection_reasons, "A custom key was provided for unavailable language [language_name].")
		if(!character_language_custom_key_is_valid(custom_key))
			return reject_character_traits_payload(rejection_reasons, "The custom key for [language_name] must be one letter or number.")
		if(custom_key in new_language_custom_keys)
			return reject_character_traits_payload(rejection_reasons, "The custom language key [custom_key] is assigned more than once.")
		new_language_custom_keys[custom_key] = language_name

	var/list/incoming_prefixes = incoming_languages["language_prefixes"]
	if(!islist(incoming_prefixes) || !incoming_prefixes.len || incoming_prefixes.len > 3)
		return reject_character_traits_payload(rejection_reasons, "Language keys must contain one to three special characters.")
	var/list/new_language_prefixes = list()
	for(var/prefix in incoming_prefixes)
		if(!character_language_prefix_is_valid(prefix))
			return reject_character_traits_payload(rejection_reasons, "[prefix] cannot be used as a language prefix.")
		new_language_prefixes += prefix

	staged_languages["alternate_languages"] = requested_alternate_languages
	staged_languages["preferred_language"] = preferred_language
	staged_languages["language_custom_keys"] = new_language_custom_keys
	staged_languages["language_prefixes"] = new_language_prefixes
	staged_languages["extra_languages"] = projected_extra_languages
	return TRUE

/datum/tgui_module/custom_marking_designer/proc/apply_character_traits_payload(list/params, list/rejection_reasons = null, mob/user = null, list/change_result = null)
	if(islist(change_result))
		change_result["traits_changed"] = FALSE
	if(!prefs || !islist(params))
		return reject_character_traits_payload(rejection_reasons, "Trait data is unavailable.")
	var/incoming_revision = params?["revision"]
	if(!isnum(incoming_revision) || incoming_revision != traits_revision)
		return reject_character_traits_payload(rejection_reasons, "This Traits draft is out of date. Reload it and try again.")
	var/list/incoming_selected = params?["selected_traits"]
	if(!islist(incoming_selected))
		return reject_character_traits_payload(rejection_reasons, "The Traits save did not contain a valid selection list.")
	var/list/incoming_preferences = params?["trait_preferences"]
	if(!islist(incoming_preferences))
		incoming_preferences = list()
	var/list/requested_paths = list()
	var/list/requested_preferences = list()
	for(var/trait_id in incoming_selected)
		if(!istext(trait_id))
			return reject_character_traits_payload(rejection_reasons, "The Traits save contained an invalid trait identifier.")
		var/trait_path = text2path(trait_id)
		var/datum/trait/trait = all_traits[trait_path]
		if(!istype(trait))
			return reject_character_traits_payload(rejection_reasons, "The Traits save contained an unknown trait.")
		if(trait_path in requested_paths)
			return reject_character_traits_payload(rejection_reasons, "The Traits save contained [trait.name] more than once.")
		requested_paths += trait_path
		var/list/trait_preferences = incoming_preferences[trait_id]
		if(islist(trait_preferences))
			requested_preferences["[trait_path]"] = trait_preferences

	var/positive_trait_count = 0
	for(var/trait_path in requested_paths)
		var/datum/trait/trait = all_traits[trait_path]
		var/category_id = resolve_trait_category_id(trait)
		var/list/trait_catalog = resolve_trait_catalog(category_id)
		if(!islist(trait_catalog) || !(trait_path in trait_catalog))
			return reject_character_traits_payload(rejection_reasons, "[trait.name] is not available to [prefs.species]. Remove it before saving.")
		var/anatomy_restriction = resolve_trait_anatomy_restriction(trait)
		if(anatomy_restriction)
			return reject_character_traits_payload(rejection_reasons, "[trait.name]: [anatomy_restriction]")
		if(category_id == "positive")
			positive_trait_count++
	if(positive_trait_count > prefs.max_traits)
		return reject_character_traits_payload(rejection_reasons, "You selected [positive_trait_count] positive traits, but the limit is [prefs.max_traits].")

	for(var/trait_index = 1, trait_index <= requested_paths.len, trait_index++)
		var/trait_path = requested_paths[trait_index]
		var/datum/trait/trait = all_traits[trait_path]
		for(var/selected_index = 1, selected_index < trait_index, selected_index++)
			var/selected_path = requested_paths[selected_index]
			var/datum/trait/selected_trait = all_traits[selected_path]
			if(character_traits_conflict(trait_path, trait, selected_path, selected_trait))
				return reject_character_traits_payload(rejection_reasons, "[trait.name] conflicts with [selected_trait.name]. Remove one before saving.")

	var/list/staged_languages = list()
	if(!stage_character_languages_payload(params, requested_paths, user, staged_languages, rejection_reasons))
		return FALSE

	var/list/new_positive_traits = list()
	var/list/new_neutral_traits = list()
	var/list/new_negative_traits = list()
	for(var/trait_path in requested_paths)
		var/datum/trait/trait = all_traits[trait_path]
		var/list/trait_preferences = requested_preferences["[trait_path]"]
		if(!store_character_trait_selection(trait_path, trait, trait_preferences, new_positive_traits, new_neutral_traits, new_negative_traits))
			return reject_character_traits_payload(rejection_reasons, "[trait.name] could not be saved.")

	var/list/current_trait_signature = list(
		"positive" = prefs.build_trait_signature(prefs.pos_traits),
		"neutral" = prefs.build_trait_signature(prefs.neu_traits),
		"negative" = prefs.build_trait_signature(prefs.neg_traits)
	)
	var/list/requested_trait_signature = list(
		"positive" = prefs.build_trait_signature(new_positive_traits),
		"neutral" = prefs.build_trait_signature(new_neutral_traits),
		"negative" = prefs.build_trait_signature(new_negative_traits)
	)
	if(islist(change_result))
		change_result["traits_changed"] = json_encode(current_trait_signature) != json_encode(requested_trait_signature)

	var/list/current_paths = prefs.pos_traits + prefs.neu_traits + prefs.neg_traits
	for(var/trait_path in current_paths)
		if(trait_path in requested_paths)
			continue
		var/datum/trait/trait = all_traits[trait_path]
		if(istype(trait))
			trait.remove_pref(prefs)
	for(var/trait_path in requested_paths)
		if(trait_path in current_paths)
			continue
		var/datum/trait/trait = all_traits[trait_path]
		if(istype(trait))
			trait.apply_pref(prefs)

	prefs.pos_traits = new_positive_traits
	prefs.neu_traits = new_neutral_traits
	prefs.neg_traits = new_negative_traits
	prefs.extra_languages = staged_languages["extra_languages"]
	prefs.alternate_languages = staged_languages["alternate_languages"]
	prefs.preferred_language = staged_languages["preferred_language"]
	prefs.language_custom_keys = staged_languages["language_custom_keys"]
	prefs.language_prefixes = staged_languages["language_prefixes"]
	return TRUE

// Toggle dirty flag for pending saves
/datum/tgui_module/custom_marking_designer/proc/set_mark_dirty(state)
	mark_dirty = !!state

// Fetch or create the painting session for the requested frame
/datum/tgui_module/custom_marking_designer/proc/get_session(dir, part = active_body_part)
	RETURN_TYPE(/datum/custom_marking_session)
	if(!mark)
		return null
	if(!sessions)
		sessions = list()
	var/key = mark.frame_key(dir, part)
	var/datum/custom_marking_session/session = sessions[key]
	if(!session)
		session = new(mark, dir, part)
		sessions[key] = session
	return session

// Commit a session and flag the mark as dirty when pixels were modified
/datum/tgui_module/custom_marking_designer/proc/commit_session(datum/custom_marking_session/session)
	if(session?.commit_pending())
		set_mark_dirty(TRUE)
		body_part_layer_revision++
		return TRUE
	return FALSE

// Flush pending brush strokes across every cached session
/datum/tgui_module/custom_marking_designer/proc/commit_all_sessions()
	if(!islist(sessions))
		return FALSE
	var/committed = FALSE
	for(var/key in sessions)
		var/datum/custom_marking_session/session = sessions[key]
		if(commit_session(session))
			committed = TRUE
	return committed

// Make sure a part exists on the mark and sessions
/datum/tgui_module/custom_marking_designer/proc/ensure_body_part_registered(part)
	if(!mark)
		return FALSE
	var/normalized = mark.normalize_part(part)
	if(isnull(normalized))
		return FALSE
	if(!mark.body_parts)
		mark.body_parts = list()
	if(normalized in mark.body_parts)
		return TRUE
	mark.body_parts += normalized
	mark.ensure_part_frames(list(normalized))
	set_mark_dirty(TRUE)
	body_part_layer_revision++
	preview_revision++
	return TRUE

// Switch the editing context to a new body part
/datum/tgui_module/custom_marking_designer/proc/set_active_body_part(part)
	if(!mark)
		return
	var/normalized = mark.normalize_part(part)
	if(isnull(normalized))
		return
	if(normalized != active_body_part)
		commit_session(get_session(active_dir, active_body_part))
		active_body_part = normalized
		body_part_layer_revision++
		preview_revision++

// Apply replacement flags coming from the client
/datum/tgui_module/custom_marking_designer/proc/apply_part_replacement_payload(list/payload)
	if(!mark || !islist(payload))
		return FALSE
	var/changed = FALSE
	for(var/key in payload)
		if(isnull(key))
			continue
		var/value = payload[key]
		var/normalized = mark.normalize_part(key)
		if(isnull(normalized) || normalized == "generic")
			continue
		if(!ensure_body_part_registered(normalized))
			continue
		var/state = null
		if(isnum(value))
			state = !!value
		else if(istext(value))
			var/lower_value = lowertext(value)
			if(lower_value in list("1", "true", "yes", "on"))
				state = TRUE
			else if(lower_value in list("0", "false", "no", "off"))
				state = FALSE
		if(isnull(state))
			continue
		if(mark.is_part_replaced(normalized) == state)
			continue
		mark.set_part_replacement(normalized, state)
		changed = TRUE
	if(changed)
		set_mark_dirty(TRUE)
		preview_revision++
	return changed

// Apply render priority flags coming from the client
/datum/tgui_module/custom_marking_designer/proc/apply_part_render_priority_payload(list/payload)
	if(!mark || !islist(payload))
		return FALSE
	var/changed = FALSE
	var/list/current_map = mark?.get_render_priority_map()
	for(var/key in payload)
		if(isnull(key))
			continue
		var/value = payload[key]
		var/normalized = mark.normalize_part(key)
		if(isnull(normalized) || normalized == "generic")
			continue
		if(!ensure_body_part_registered(normalized))
			continue
		var/state_defined = FALSE
		var/state_value = null
		if(isnum(value))
			state_defined = TRUE
			state_value = !!value
		else if(istext(value))
			var/lower_value = lowertext(value)
			if(lower_value in list("1", "true", "yes", "on"))
				state_defined = TRUE
				state_value = TRUE
			else if(lower_value in list("0", "false", "no", "off"))
				state_defined = TRUE
				state_value = FALSE
		if(!state_defined)
			continue
		var/current_defined = islist(current_map) && (normalized in current_map)
		var/current = mark.is_part_render_priority(normalized)
		if(current_defined && current == state_value)
			continue
		if(mark.set_part_render_priority(normalized, state_value))
			changed = TRUE
	if(changed)
		set_mark_dirty(TRUE)
		preview_revision++
	return changed

// Apply canvas size overrides coming from the client
/datum/tgui_module/custom_marking_designer/proc/apply_part_canvas_size_payload(list/payload)
	if(!mark || !islist(payload))
		return FALSE
	var/changed = FALSE
	for(var/key in payload)
		if(isnull(key))
			continue
		var/value = payload[key]
		var/normalized = mark.normalize_part(key)
		if(isnull(normalized) || normalized == "generic")
			continue
		if(!ensure_body_part_registered(normalized))
			continue
		var/state_defined = FALSE
		var/state_value = null
		if(isnum(value))
			state_defined = TRUE
			state_value = !!value
		else if(istext(value))
			var/lower_value = lowertext(value)
			if(lower_value in list("1", "true", "yes", "on"))
				state_defined = TRUE
				state_value = TRUE
			else if(lower_value in list("0", "false", "no", "off"))
				state_defined = TRUE
				state_value = FALSE
		if(!state_defined)
			continue
		if(mark.is_part_large_canvas(normalized) == state_value)
			continue
		if(mark.set_part_canvas_size(normalized, state_value))
			changed = TRUE
	if(changed)
		set_mark_dirty(TRUE)
		body_part_layer_revision++
		preview_revision++
	return changed

// Drop body parts with no visible pixels across directions
/datum/tgui_module/custom_marking_designer/proc/prune_empty_body_parts()
	if(!mark || !islist(mark.body_parts) || !mark.body_parts.len)
		return FALSE
	var/list/dirs = list(NORTH, SOUTH, EAST, WEST)
	var/list/remove_parts = list()
	for(var/part in mark.body_parts.Copy())
		var/has_pixels = FALSE
		for(var/dir in dirs)
			var/datum/custom_marking_frame/frame = mark.get_frame(dir, part, FALSE)
			if(frame?.has_visible_pixels())
				has_pixels = TRUE
				break
		if(!has_pixels)
			remove_parts += part
	if(remove_parts.len == mark.body_parts.len)
		var/placeholder_part = active_body_part
		if(!(placeholder_part in remove_parts))
			placeholder_part = mark.body_parts[1]
		remove_parts -= placeholder_part
	if(!remove_parts.len)
		return FALSE
	for(var/part in remove_parts)
		mark.body_parts -= part
		mark.clear_part_replacement(part)
		mark.clear_part_render_priority(part)
		var/list/size_map = mark.get_canvas_size_map()
		if(islist(size_map))
			size_map -= part
			if(!size_map.len && islist(mark.options))
				mark.options -= "large_canvas_parts"
		for(var/dir in dirs)
			var/session_key = mark.frame_key(dir, part)
			if(islist(sessions) && sessions[session_key])
				sessions -= session_key
		if(part != "generic" && islist(mark.frames))
			for(var/dir in dirs)
				var/frame_key_value = mark.frame_key(dir, part)
				if(frame_key_value && mark.frames?[frame_key_value])
					mark.frames -= frame_key_value
	body_part_layer_revision++
	preview_revision++
	set_mark_dirty(TRUE)
	return TRUE

// Keep preference body marking data aligned with editor selections
/datum/tgui_module/custom_marking_designer/proc/sync_preference_assignment()
	if(!prefs || !mark)
		return
	register_custom_marking_style(mark, TRUE)
	var/style_name = mark.get_style_name()
	if(!style_name)
		return
	LAZYINITLIST(prefs.body_markings)
	var/list/current = prefs.body_markings?[style_name]
	if(!islist(current))
		prefs.body_markings[style_name] = prefs.mass_edit_marking_list(style_name)
		current = prefs.body_markings[style_name]
	if(!islist(current))
		return
	var/default_color = current["color"]
	if(!istext(default_color))
		default_color = "#FFFFFF"
	var/list/desired_parts = mark.body_parts && mark.body_parts.len ? mark.body_parts : list()
	for(var/part in desired_parts)
		if(!(part in current) || !islist(current[part]))
			current[part] = list("on" = TRUE, "color" = default_color)
	var/list/remove_queue = list()
	for(var/part in current)
		if(!istext(part) || part == "color")
			continue
		if(!(part in desired_parts))
			remove_queue += part
	for(var/part in remove_queue)
		current -= part
	prefs.prune_disallowed_body_markings()
	if(islist(prefs.body_markings))
		var/list/stale = list()
		LAZYINITLIST(body_marking_styles_list)
		for(var/key in prefs.body_markings)
			if(!istext(key))
				continue
			if(!(key in body_marking_styles_list))
				stale += key
		for(var/key in stale)
			prefs.body_markings -= key
	preview_revision++

// Register finished edits into prefs/custom markings
/datum/tgui_module/custom_marking_designer/proc/register_mark_with_prefs()
	if(!mark)
		return
	var/current_id = mark.register()
	if(prefs)
		LAZYINITLIST(prefs.custom_markings)
		if(islist(prefs.custom_markings))
			prefs.custom_markings[current_id] = mark
			if(original_mark_id && original_mark_id != current_id)
				prefs.custom_markings -= original_mark_id
	if(is_new_mark && !original_mark_id)
		original_mark_id = current_id
	var/current_style = mark.get_style_name()
	var/datum/sprite_accessory/marking/custom/style = mark.ensure_sprite_accessory(TRUE)
	if(prefs && islist(prefs.body_markings))
		if(original_style_name && original_style_name != current_style && prefs.body_markings[original_style_name])
			var/list/old_entry = prefs.body_markings[original_style_name]
			prefs.body_markings -= original_style_name
			if(!prefs.body_markings[current_style])
				prefs.body_markings[current_style] = old_entry
		var/list/current_entry = prefs.body_markings[current_style]
		if(islist(current_entry))
			current_entry["datum"] = style
			for(var/part in current_entry)
				if(!istext(part) || part == "color")
					continue
				var/list/details = current_entry[part]
				if(islist(details))
					details["datum"] = style
	original_style_name = current_style

// Commit edits, refresh caches, and update preview assets
/datum/tgui_module/custom_marking_designer/proc/save_marking_changes(force_save = TRUE, refresh_browser = FALSE, refresh_preview_assets = TRUE)
	if(!mark)
		return FALSE
	if(save_in_progress)
		return FALSE
	save_in_progress = TRUE
	try
		var/log_ckey = prefs?.client_ckey || prefs?.client?.ckey || mark?.owner_ckey || "unknown"
		var/committed = commit_all_sessions()
		var/pruned = prune_empty_body_parts()
		var/shrank = mark.shrink_large_parts_if_safe()
		if(shrank)
			set_mark_dirty(TRUE)
			body_part_layer_revision++
			preview_revision++
		if(!force_save && !mark_dirty && !committed && !pruned && !shrank)
			save_in_progress = FALSE
			return FALSE
		var/needs_save = committed || mark_dirty || pruned || shrank
		if(!needs_save)
			save_in_progress = FALSE
			return FALSE
		mark.bump_revision()
		log_debug("CustomMarkings: [log_ckey] saved marking '[mark?.name]' ([mark?.id]) rev=[mark?.style_revision]")
		register_mark_with_prefs()
		sync_preference_assignment()
		mark_dirty = FALSE
		is_new_mark = FALSE
		initial_snapshot = mark.to_save()
		if(prefs && !QDELETED(prefs))
			if(refresh_preview_assets || refresh_browser)
				prefs.skip_custom_marking_cache_invalidation_once = TRUE
			if(refresh_preview_assets)
				prefs.refresh_custom_marking_assets(TRUE, TRUE, mark, TRUE)
		if(refresh_preview_assets)
			preview_revision++
		if(refresh_browser && prefs)
			refresh_preferences_window_if_visible()
		save_in_progress = FALSE
		return TRUE
	catch(var/exception/e)
		save_in_progress = FALSE
		throw e

// Refresh the legacy character setup browser and preview if it's already open (Lira, December 2025)
/datum/tgui_module/custom_marking_designer/proc/refresh_preferences_window_if_visible(refresh_preview = TRUE)
	if(!prefs)
		return FALSE
	var/mob/user = usr
	if(!user && prefs.client)
		user = prefs.client.mob
	if(!user || !user.client)
		return FALSE
	var/visible = winget(user, "preferences_window", "is-visible")
	if(istext(visible) && lowertext(visible) == "true")
		if(refresh_preview)
			INVOKE_ASYNC(prefs, /datum/preferences/proc/update_preview_icon, TRUE)
		INVOKE_ASYNC(prefs, /datum/preferences/proc/ShowChoices, user)
		return TRUE
	return FALSE

// Revert or remove edits depending on whether this is a new mark
/datum/tgui_module/custom_marking_designer/proc/discard_changes()
	if(!mark)
		return
	reset_body_marking_chunk_state()
	if(is_new_mark)
		var/datum/custom_marking/old_mark = mark
		var/old_mark_id = mark.id
		if(prefs)
			prefs.custom_markings -= old_mark_id
		unregister_custom_marking_style(old_mark_id)
		GLOB.custom_markings_by_id -= old_mark_id
		mark = null
		if(islist(sessions))
			QDEL_LIST_ASSOC_VAL(sessions)
		sessions = list()
		if(istype(old_mark) && !QDELETED(old_mark))
			qdel(old_mark)
		SStgui.close_uis(src)
		return
	if(initial_snapshot)
		mark.from_save(initial_snapshot)
	register_custom_marking_style(mark, TRUE)
	if(islist(sessions))
		QDEL_LIST_ASSOC_VAL(sessions)
	sessions = list()
	is_new_mark = FALSE
	mark_dirty = FALSE
	body_part_layer_revision++
	preview_revision++
	active_body_part = default_body_part()
	original_mark_id = mark?.id
	original_style_name = mark?.get_style_name()

// Build composite layers for each part in a direction
/datum/tgui_module/custom_marking_designer/proc/build_body_part_layers(dir)
	if(!mark?.body_parts || !mark.body_parts.len)
		return null
	var/list/layers = list()
	for(var/part in mark.body_parts)
		var/datum/custom_marking_frame/frame = mark.get_frame(dir, part, FALSE)
		var/list/composite = frame?.get_composite()
		if(islist(composite))
			layers[part] = composite
	return layers.len ? layers : null

// Pass static replacement dependency hints to the client
/datum/tgui_module/custom_marking_designer/proc/build_replacement_dependents_payload()
	if(!islist(GLOB.custom_marking_replacement_children) || !GLOB.custom_marking_replacement_children.len)
		return null
	var/list/result = list()
	for(var/parent in GLOB.custom_marking_replacement_children)
		if(isnull(parent))
			continue
		var/list/raw_children = GLOB.custom_marking_replacement_children[parent]
		if(!islist(raw_children) || !raw_children.len)
			continue
		var/list/child_entries = list()
		for(var/child in raw_children)
			if(!isnull(child))
				child_entries += child
		if(child_entries.len)
			result[parent] = child_entries
	return result.len ? result : null

// Produce user-friendly labels for directional buttons
/datum/tgui_module/custom_marking_designer/proc/direction_label(dir)
	switch(dir)
		if(NORTH)
			return "North"
		if(SOUTH)
			return "South"
		if(EAST)
			return "East"
		if(WEST)
			return "West"
	return "Unknown"

// Resolve display strings for body part selections
/datum/tgui_module/custom_marking_designer/proc/get_body_part_label(part)
	if(!part)
		return "Generic"
	var/list/labels = islist(GLOB.custom_marking_part_labels) ? GLOB.custom_marking_part_labels : null
	if(labels && (part in labels))
		return labels[part]
	return capitalize(replacetext(part, "_", " "))

// Supply invariant data such as directions and reference grids to the UI
/datum/tgui_module/custom_marking_designer/tgui_static_data(mob/user)
	var/list/data = ..()
	var/datum/asset/spritesheet/custom_marking_designer/atlas = get_asset_datum(/datum/asset/spritesheet/custom_marking_designer)
	var/manifest_asset_name = atlas.get_manifest_asset_name()
	var/manifest_revision = atlas.get_manifest_revision()
	if(atlas.is_ready() && istext(manifest_asset_name) && length(manifest_asset_name) && isnum(manifest_revision))
		data["static_asset_manifest"] = list(
			"asset" = manifest_asset_name,
			"revision" = manifest_revision
		)
	else if(SScustom_marking?.is_static_atlas_terminal_fallback(atlas))
		data["static_asset_manifest_fallback"] = TRUE
	var/list/dirs = list()
	for(var/dir in direction_order)
		dirs += list(list("dir" = dir, "label" = direction_label(dir)))
	data["directions"] = dirs
	var/list/parts = list()
	var/list/labels = islist(GLOB.custom_marking_part_labels) ? GLOB.custom_marking_part_labels : null
	if(!labels || !labels.len)
		labels = list(
			BP_HEAD = "Head",
			BP_TORSO = "Upper Body",
			BP_GROIN = "Lower Body",
			BP_R_ARM = "Right Arm",
			BP_L_ARM = "Left Arm",
			BP_R_HAND = "Right Hand",
			BP_L_HAND = "Left Hand",
			BP_R_LEG = "Right Leg",
			BP_L_LEG = "Left Leg",
			BP_R_FOOT = "Right Foot",
			BP_L_FOOT = "Left Foot"
		)
	for(var/part in labels)
		parts += list(list("id" = part, "label" = labels[part]))
	data["body_parts"] = parts
	data["width"] = get_canvas_width()
	data["height"] = get_canvas_height()
	data["max_width"] = CUSTOM_MARKING_CANVAS_MAX_WIDTH
	data["max_height"] = CUSTOM_MARKING_CANVAS_MAX_HEIGHT
	data["default_width"] = CUSTOM_MARKING_DEFAULT_WIDTH
	data["default_height"] = CUSTOM_MARKING_DEFAULT_HEIGHT
	var/list/replacement_dependents = build_replacement_dependents_payload()
	if(islist(replacement_dependents) && replacement_dependents.len)
		data["replacement_dependents"] = replacement_dependents
	var/list/canvas_backgrounds = build_canvas_background_options()
	if(islist(canvas_backgrounds) && canvas_backgrounds.len)
		data["canvas_backgrounds"] = canvas_backgrounds
		data["default_canvas_background"] = "default"
	return data

// Create backgrounds for the custom markings designer (Lira, December 2025)
/datum/tgui_module/custom_marking_designer/proc/build_canvas_background_options()
	var/list/cache = build_custom_marking_canvas_background_cache()
	if(islist(cache) && cache.len)
		return cache
	return build_canvas_background_options_internal()

// Build background payloads without caching
/datum/tgui_module/custom_marking_designer/proc/build_canvas_background_options_internal()
	var/list/backgrounds = list(list(
		"id" = "default",
		"label" = "Default",
		"asset" = null
	))
	var/list/season_state_map = list(
		"spring" = "grass-spring4",
		"summer" = "grass-summer4",
		"fall" = "grass-autumn4",
		"winter" = "grass-winter4"
	)
	for(var/season in season_state_map)
		var/state = season_state_map[season]
		if(!istext(state) || !length(state))
			continue
		var/icon/I = icon('icons/seasonal/turf.dmi', state)
		if(!isicon(I))
			continue
		var/list/asset = build_icon_asset(I)
		if(!islist(asset))
			continue
		var/label = capitalize(season)
		if(season == "fall")
			label = "Fall"
		backgrounds += list(list(
			"id" = season,
			"label" = label,
			"asset" = asset
		))
	return backgrounds

// Provide the live editing payload for TGUI rendering
/datum/tgui_module/custom_marking_designer/tgui_data(mob/user)
	var/list/data = list()
	data["marking_id"] = mark?.id
	data["mark_name"] = mark?.name
	data["initial_tab"] = initial_tab
	data["allow_custom_tab"] = allow_custom_tab
	data["custom_marking_enable_disclaimer"] = prefs?.get_custom_markings_enable_disclaimer()
	data["active_dir"] = direction_label(active_dir)
	data["active_dir_key"] = active_dir
	data["is_new"] = is_new_mark
	var/datum/custom_marking_session/session = get_session(active_dir, active_body_part)
	data["grid"] = session ? session.get_grid() : null
	data["diff"] = null
	data["diff_seq"] = diff_sequence
	data["session_token"] = session_token
	data["state_token"] = state_session_token
	data["limited"] = FALSE
	data["finalized"] = FALSE
	data["can_finalize"] = FALSE
	data["width"] = get_canvas_width()
	data["height"] = get_canvas_height()
	data["max_width"] = CUSTOM_MARKING_CANVAS_MAX_WIDTH
	data["max_height"] = CUSTOM_MARKING_CANVAS_MAX_HEIGHT
	data["default_width"] = CUSTOM_MARKING_DEFAULT_WIDTH
	data["default_height"] = CUSTOM_MARKING_DEFAULT_HEIGHT
	data["active_canvas_width"] = mark ? mark.get_part_canvas_width(active_body_part) : get_canvas_width()
	data["active_canvas_height"] = mark ? mark.get_part_canvas_height(active_body_part) : get_canvas_height()
	data["selected_body_parts"] = mark?.body_parts?.Copy() || list()
	data["part_replacements"] = mark?.get_part_replacement_payload()
	data["part_render_priority"] = mark?.get_part_render_priority_payload()
	data["part_canvas_size"] = mark?.get_part_canvas_size_payload()
	data["active_body_part"] = active_body_part
	data["active_body_part_label"] = get_body_part_label(active_body_part)
	var/list/layers = build_body_part_layers(active_dir)
	if(islist(layers) && layers.len)
		data["body_part_layers"] = layers
		data["body_part_layer_order"] = mark?.body_parts?.Copy()
	data["body_part_layer_revision"] = body_part_layer_revision
	data["preview_revision"] = isnum(last_preview_bundle_revision) ? last_preview_bundle_revision : preview_revision
	data["preview_refresh_token"] = preview_refresh_token
	var/list/canvas_backgrounds_live = build_canvas_background_options()
	if(islist(canvas_backgrounds_live) && canvas_backgrounds_live.len)
		data["canvas_backgrounds"] = canvas_backgrounds_live
		data["default_canvas_background"] = "default"
	data["ui_locked"] = save_in_progress
	data["show_equipment"] = !!(prefs?.equip_preview_mob & EQUIP_PREVIEW_EQUIPMENT)
	data["show_job_gear"] = !!(prefs?.equip_preview_mob & EQUIP_PREVIEW_JOB)
	data["show_loadout_gear"] = !!(prefs?.equip_preview_mob & EQUIP_PREVIEW_LOADOUT)
	data["traits_revision"] = traits_revision
	data["traits_species"] = prefs?.species
	append_traits_preview_scale(data)
	data["reference_build_in_progress"] = reference_build_in_progress
	return data

/datum/tgui_module/custom_marking_designer/proc/append_preview_bundle_delta(list/payload, list/bundle, suffix = null, known_revision = null, known_signature = null)
	if(!islist(payload))
		return FALSE
	var/revision_key = istext(suffix) && length(suffix) ? "preview_revision_[suffix]" : "preview_revision"
	var/signature_key = istext(suffix) && length(suffix) ? "preview_signature_[suffix]" : "preview_signature"
	var/sources_key = istext(suffix) && length(suffix) ? "preview_sources_[suffix]" : "preview_sources"
	var/registry_key = istext(suffix) && length(suffix) ? "preview_asset_registry_[suffix]" : "preview_asset_registry"
	if(!islist(bundle))
		payload[revision_key] = 0
		payload[signature_key] = null
		return FALSE
	var/bundle_revision = bundle["revision"]
	var/bundle_signature = bundle["signature"]
	payload[revision_key] = isnum(bundle_revision) ? bundle_revision : 0
	payload[signature_key] = bundle_signature
	var/resolved_known_revision = known_revision
	if(istext(resolved_known_revision) && length(resolved_known_revision))
		resolved_known_revision = text2num(resolved_known_revision)
	var/revision_matches = isnum(resolved_known_revision) && isnum(bundle_revision) && resolved_known_revision == bundle_revision
	var/signature_matches = istext(known_signature) && length(known_signature) && known_signature == bundle_signature
	if(revision_matches || signature_matches)
		return FALSE
	payload[sources_key] = bundle["dirs"]
	payload[registry_key] = bundle["asset_registry"]
	return TRUE

// Build the payload for the standard body markings tab (Lira, December 2025)
/datum/tgui_module/custom_marking_designer/proc/build_body_markings_payload(known_definition_revision = null, known_preview_revision = null, known_preview_signature = null, preview_only = FALSE)
	var/list/yield_context = custom_marking_begin_manual_yield()
	if(!prefs)
		custom_marking_end_manual_yield(yield_context)
		return null
	var/list/payload = list()
	payload["species_id"] = prefs.species
	payload["custom_base"] = prefs.custom_base
	var/digitigrade_allowed = is_digitigrade_allowed()
	payload["digitigrade"] = digitigrade_allowed ? !!prefs.digitigrade : FALSE
	append_body_marking_definition_delta(payload, known_definition_revision)
	if(preview_only)
		payload["preview_only"] = TRUE
	if(!preview_only)
		var/list/original_body_markings = prefs.body_markings ? prefs.body_markings.Copy() : list()
		var/list/filtered_body_markings = list()
		if(islist(original_body_markings))
			for(var/mark in original_body_markings)
				CUSTOM_MARKING_CHECK_TICK
				var/datum/sprite_accessory/marking/style = body_marking_styles_list[mark]
				if(!istype(style))
					continue
				if(!is_body_marking_allowed(style))
					continue
				filtered_body_markings[mark] = original_body_markings[mark]
		payload["body_markings"] = filtered_body_markings.Copy()
		var/list/order = list()
		if(islist(filtered_body_markings))
			for(var/mark in filtered_body_markings)
				order += mark
		payload["order"] = order
	var/list/preview_bundle = null
	var/old_body_markings = prefs.body_markings
	prefs.body_markings = null
	preview_bundle = build_stripped_preview_source_bundle(!!prefs.digitigrade)
	prefs.body_markings = old_body_markings
	append_preview_bundle_delta(payload, preview_bundle, null, known_preview_revision, known_preview_signature)
	payload["preview_width"] = get_preview_canvas_width()
	payload["preview_height"] = get_preview_canvas_height()
	var/list/canvas_backgrounds_live = build_canvas_background_options()
	if(islist(canvas_backgrounds_live) && canvas_backgrounds_live.len)
		payload["canvas_backgrounds"] = canvas_backgrounds_live
		payload["default_canvas_background"] = "default"
	custom_marking_end_manual_yield(yield_context)
	return payload

// Check if the current species can use digitigrade legs (Lira, December 2025)
/datum/tgui_module/custom_marking_designer/proc/is_digitigrade_allowed()
	if(!prefs)
		return FALSE
	var/datum/species/mob_species = GLOB.all_species?[prefs.species]
	return istype(mob_species) && mob_species.digi_allowed

// Count color channels for a sprite accessory (Lira, December 2025)
/datum/tgui_module/custom_marking_designer/proc/get_basic_accessory_channel_count(datum/sprite_accessory/style)
	if(!istype(style) || !style.do_colouration)
		return 0
	var/count = 1
	if(style:extra_overlay)
		count++
	if(style:extra_overlay2)
		count++
	return count

// Placeholder name check (Lira, December 2025)
/datum/tgui_module/custom_marking_designer/proc/is_basic_appearance_placeholder_name(style_name)
	if(!istext(style_name) || !length(style_name))
		return FALSE
	var/normalized = lowertext(style_name)
	return findtext(normalized, "you should not see this") ? TRUE : FALSE

// Build global definitions for the basic appearance tab (Lira, December 2025)
/datum/tgui_module/custom_marking_designer/proc/build_basic_appearance_definitions()
	if(islist(custom_marking_basic_appearance_definition_cache))
		return custom_marking_basic_appearance_definition_cache
	var/list/cache = list()
	cache["hair_styles_by_name"] = build_basic_appearance_hair_definition_map()
	cache["gradient_styles"] = build_basic_appearance_gradient_definitions()
	cache["facial_hair_styles_by_name"] = build_basic_appearance_facial_hair_definition_map()
	cache["ear_styles_by_name"] = build_basic_appearance_ear_definition_map()
	cache["tail_styles_by_name"] = build_basic_appearance_tail_definition_map()
	cache["wing_styles_by_name"] = build_basic_appearance_wing_definition_map()
	custom_marking_basic_appearance_definition_cache = cache
	return cache

// Build hair definitions for basic appearance tab (Lira, December 2025)
/datum/tgui_module/custom_marking_designer/proc/build_basic_appearance_hair_definition_map()
	var/list/defs = list()
	defs["Normal"] = list("id" = "Normal", "name" = "Normal")
	if(!islist(global.hair_styles_list) || !global.hair_styles_list.len)
		return defs
	for(var/style_name in global.hair_styles_list)
		CUSTOM_MARKING_CHECK_TICK
		var/datum/sprite_accessory/hair/style = global.hair_styles_list[style_name]
		if(!istype(style))
			continue
		if(is_basic_appearance_placeholder_name(style_name))
			continue
		var/list/def = list("id" = style_name, "name" = style_name)
		def["do_colouration"] = !!style.do_colouration
		def["color_blend_mode"] = style.color_blend_mode
		def["channel_count"] = style.do_colouration ? 1 : 0
		var/list/dir_assets = list()
		var/icon_source = style.icon
		if(icon_source)
			for(var/dir in list(NORTH, SOUTH, EAST, WEST))
				CUSTOM_MARKING_CHECK_TICK
				var/state_name = "[style.icon_state]_s"
				var/list/assets_for_dir = list()
				var/asset_payload = build_static_source_icon_reference(icon_source, state_name, dir, "hair")
				assets_for_dir += list(asset_payload)
				if(style.do_colouration && style.icon_add)
					var/add_payload = build_static_source_icon_reference(style.icon_add, state_name, dir, "hair")
					assets_for_dir += list(add_payload)
				dir_assets["[dir]"] = assets_for_dir
		if(dir_assets.len)
			def["assets"] = dir_assets
		defs[style_name] = def
	return defs

// Build hair gradiant definitions for basic appearance tab (Lira, December 2025)
/datum/tgui_module/custom_marking_designer/proc/build_basic_appearance_gradient_definitions()
	var/list/grad_defs = list()
	if(!islist(GLOB.hair_gradients) || !GLOB.hair_gradients.len)
		return grad_defs
	for(var/gname in GLOB.hair_gradients)
		CUSTOM_MARKING_CHECK_TICK
		var/icon_state = GLOB.hair_gradients[gname]
		var/list/def = list(
			"id" = gname,
			"name" = gname,
			"icon_state" = icon_state
		)
		var/list/dir_assets = list()
		if(istext(icon_state) && length(icon_state))
			for(var/dir in list(NORTH, SOUTH, EAST, WEST))
				CUSTOM_MARKING_CHECK_TICK
				var/asset_payload = build_static_source_icon_reference('icons/mob/hair_gradients.dmi', icon_state, dir, "hair", "raw", "hair_gradients|[icon_state]|[dir]")
				if(!isnull(asset_payload))
					dir_assets["[dir]"] = asset_payload
		if(dir_assets.len && dir_assets.len < 4)
			var/fallback_asset = dir_assets["[SOUTH]"]
			if(isnull(fallback_asset))
				fallback_asset = dir_assets["[NORTH]"]
			if(isnull(fallback_asset))
				fallback_asset = dir_assets["[EAST]"]
			if(isnull(fallback_asset))
				fallback_asset = dir_assets["[WEST]"]
			if(!isnull(fallback_asset))
				for(var/dir in list(NORTH, SOUTH, EAST, WEST))
					if(isnull(dir_assets["[dir]"]))
						dir_assets["[dir]"] = fallback_asset
		if(dir_assets.len)
			def["assets"] = dir_assets
		grad_defs += list(def)
	return grad_defs

// Build facial hair definitions for basic appearance tab (Lira, December 2025)
/datum/tgui_module/custom_marking_designer/proc/build_basic_appearance_facial_hair_definition_map()
	var/list/defs = list()
	defs["Normal"] = list("id" = "Normal", "name" = "Normal")
	defs["Shaved"] = list("id" = "Shaved", "name" = "Shaved")
	if(!islist(global.facial_hair_styles_list) || !global.facial_hair_styles_list.len)
		return defs
	for(var/style_name in global.facial_hair_styles_list)
		CUSTOM_MARKING_CHECK_TICK
		var/datum/sprite_accessory/facial_hair/style = global.facial_hair_styles_list[style_name]
		if(!istype(style))
			continue
		if(is_basic_appearance_placeholder_name(style_name))
			continue
		var/list/def = list("id" = style_name, "name" = style_name)
		def["do_colouration"] = !!style.do_colouration
		def["color_blend_mode"] = style.color_blend_mode
		def["channel_count"] = style.do_colouration ? 1 : 0
		var/list/dir_assets = list()
		var/icon_source = style.icon
		if(icon_source)
			for(var/dir in list(NORTH, SOUTH, EAST, WEST))
				CUSTOM_MARKING_CHECK_TICK
				var/state_name = "[style.icon_state]_s"
				var/list/assets_for_dir = list()
				var/asset_payload = build_static_source_icon_reference(icon_source, state_name, dir, "hair")
				assets_for_dir += list(asset_payload)
				dir_assets["[dir]"] = assets_for_dir
		if(dir_assets.len)
			def["assets"] = dir_assets
		defs[style_name] = def
	return defs

// Build ear definitions for basic appearance tab (Lira, December 2025)
/datum/tgui_module/custom_marking_designer/proc/build_basic_appearance_ear_definition_map()
	var/list/defs = list()
	defs["Normal"] = list("id" = "Normal", "name" = "Normal")
	if(!islist(global.ear_styles_list) || !global.ear_styles_list.len)
		return defs
	for(var/path in global.ear_styles_list)
		CUSTOM_MARKING_CHECK_TICK
		var/datum/sprite_accessory/ears/style = global.ear_styles_list[path]
		if(!istype(style))
			continue
		var/style_name = style.name
		if(!istext(style_name) || !length(style_name))
			continue
		if(is_basic_appearance_placeholder_name(style_name))
			continue
		var/list/def = list("id" = style_name, "name" = style_name)
		def["do_colouration"] = !!style.do_colouration
		def["color_blend_mode"] = style.color_blend_mode
		def["channel_count"] = get_basic_accessory_channel_count(style)
		var/list/dir_assets = list()
		if(style.icon && style.icon_state)
			for(var/dir in list(NORTH, SOUTH, EAST, WEST))
				CUSTOM_MARKING_CHECK_TICK
				var/list/assets_for_dir = list()
				assets_for_dir += list(build_static_source_icon_reference(style.icon, style.icon_state, dir, "accessories"))
				if(style.extra_overlay)
					assets_for_dir += list(build_static_source_icon_reference(style.icon, style.extra_overlay, dir, "accessories"))
				if(style.extra_overlay2)
					assets_for_dir += list(build_static_source_icon_reference(style.icon, style.extra_overlay2, dir, "accessories"))
				dir_assets["[dir]"] = assets_for_dir
		if(dir_assets.len)
			def["assets"] = dir_assets
		defs[style_name] = def
	return defs

// Build tail definitions for basic appearance tab (Lira, December 2025)
/datum/tgui_module/custom_marking_designer/proc/build_basic_appearance_tail_definition_map()
	var/list/defs = list()
	defs["Normal"] = list("id" = "Normal", "name" = "Normal")
	if(!islist(global.tail_styles_list) || !global.tail_styles_list.len)
		return defs
	for(var/path in global.tail_styles_list)
		CUSTOM_MARKING_CHECK_TICK
		var/datum/sprite_accessory/tail/style = global.tail_styles_list[path]
		if(!istype(style))
			continue
		var/style_name = style.name
		if(!istext(style_name) || !length(style_name))
			continue
		if(is_basic_appearance_placeholder_name(style_name))
			continue
		var/list/def = list("id" = style_name, "name" = style_name)
		def["do_colouration"] = !!style.do_colouration
		def["color_blend_mode"] = style.color_blend_mode
		def["channel_count"] = get_basic_accessory_channel_count(style)
		def["hide_body_parts"] = islist(style.hide_body_parts) ? style.hide_body_parts.Copy() : null
		def["lower_layer_dirs"] = islist(style.lower_layer_dirs) ? style.lower_layer_dirs.Copy() : list(SOUTH)
		var/list/dir_assets = list()
		if(style.icon && style.icon_state)
			for(var/dir in list(NORTH, SOUTH, EAST, WEST))
				CUSTOM_MARKING_CHECK_TICK
				var/list/assets_for_dir = list()
				assets_for_dir += list(build_static_source_icon_reference(style.icon, style.icon_state, dir, "accessories"))
				if(style.extra_overlay)
					assets_for_dir += list(build_static_source_icon_reference(style.icon, style.extra_overlay, dir, "accessories"))
				if(style.extra_overlay2)
					assets_for_dir += list(build_static_source_icon_reference(style.icon, style.extra_overlay2, dir, "accessories"))
				dir_assets["[dir]"] = assets_for_dir
		if(dir_assets.len)
			def["assets"] = dir_assets
		defs[style_name] = def
	return defs

// Build wing definitions for basic appearance tab (Lira, December 2025)
/datum/tgui_module/custom_marking_designer/proc/build_basic_appearance_wing_definition_map()
	var/list/defs = list()
	defs["Normal"] = list("id" = "Normal", "name" = "Normal")
	if(!islist(global.wing_styles_list) || !global.wing_styles_list.len)
		return defs
	for(var/path in global.wing_styles_list)
		CUSTOM_MARKING_CHECK_TICK
		var/datum/sprite_accessory/wing/style = global.wing_styles_list[path]
		if(!istype(style))
			continue
		var/style_name = style.name
		if(!istext(style_name) || !length(style_name))
			continue
		if(is_basic_appearance_placeholder_name(style_name))
			continue
		var/list/def = list("id" = style_name, "name" = style_name)
		def["do_colouration"] = !!style.do_colouration
		def["color_blend_mode"] = style.color_blend_mode
		def["channel_count"] = get_basic_accessory_channel_count(style)
		def["multi_dir"] = !!(style:multi_dir)
		def["wing_offset"] = isnum(style:wing_offset) ? style:wing_offset : 0
		var/list/dir_assets = list()
		var/list/dir_back_assets = list()
		if(style.icon && style.icon_state)
			for(var/dir in list(NORTH, SOUTH, EAST, WEST))
				CUSTOM_MARKING_CHECK_TICK
				var/list/assets_for_dir = list()
				var/state_front = style.icon_state
				if(style:multi_dir)
					state_front = "[state_front]_front"
				assets_for_dir += list(build_static_source_icon_reference(style.icon, state_front, dir, "accessories"))
				if(style.extra_overlay)
					assets_for_dir += list(build_static_source_icon_reference(style.icon, style.extra_overlay, dir, "accessories"))
				if(style.extra_overlay2)
					assets_for_dir += list(build_static_source_icon_reference(style.icon, style.extra_overlay2, dir, "accessories"))
				dir_assets["[dir]"] = assets_for_dir
				if(style:multi_dir)
					var/list/back_assets_for_dir = list()
					var/state_back = "[style.icon_state]_back"
					back_assets_for_dir += list(build_static_source_icon_reference(style.icon, state_back, dir, "accessories"))
					if(style.extra_overlay)
						back_assets_for_dir += list(build_static_source_icon_reference(style.icon, style.extra_overlay, dir, "accessories"))
					if(style.extra_overlay2)
						back_assets_for_dir += list(build_static_source_icon_reference(style.icon, style.extra_overlay2, dir, "accessories"))
					dir_back_assets["[dir]"] = back_assets_for_dir
		if(dir_assets.len)
			def["assets"] = dir_assets
		if(dir_back_assets.len)
			def["back_assets"] = dir_back_assets
		defs[style_name] = def
	return defs

/datum/tgui_module/custom_marking_designer/proc/build_allowed_prosthetic_model_ids()
	var/list/allowed = list()
	if(!prefs || !islist(chargen_robolimbs))
		return allowed
	var/species_id = prefs.species ? prefs.species : SPECIES_HUMAN
	var/user_ckey = prefs.client?.ckey
	for(var/company in chargen_robolimbs)
		var/datum/robolimb/model = chargen_robolimbs[company]
		if(!istype(model))
			continue
		if(islist(model.species_cannot_use) && (species_id in model.species_cannot_use))
			continue
		if(islist(model.whitelisted_to) && model.whitelisted_to.len && !(user_ckey in model.whitelisted_to))
			continue
		allowed += company
	return allowed

/datum/tgui_module/custom_marking_designer/proc/build_basic_prosthetic_context()
	if(!prefs)
		return null
	var/preview_icon_base = resolve_species_icon_base(prefs.species, prefs.custom_base)
	var/base_id = resolve_species_body_preview_base(prefs.species, preview_icon_base)
	var/datum/species/selected_species = GLOB.all_species?[prefs.species]
	var/datum/species/base_species = GLOB.all_species?[base_id]
	if(!istype(selected_species) || !istype(base_species))
		return null
	var/list/definition_context = build_basic_appearance_definition_context()
	var/list/allowed_model_ids = definition_context?["allowed_prosthetic_model_ids"]
	if(!islist(allowed_model_ids))
		allowed_model_ids = build_allowed_prosthetic_model_ids()
	var/gender_suffix = resolve_species_body_preview_gender_suffix()
	var/list/part_states = list()
	var/list/locked_parts = list()
	var/list/synth_color_parts = list()
	for(var/part_id in BP_ALL)
		var/list/organ_definition = base_species.has_limbs?[part_id]
		var/limb_path = organ_definition?["path"]
		if(ispath(limb_path, /obj/item/organ/external))
			var/obj/item/organ/external/limb_template = limb_path
			var/state_name = initial(limb_template.icon_name)
			if(istext(state_name) && length(state_name))
				var/list/state_entry = list("state" = state_name)
				if(initial(limb_template.gendered_icon))
					state_entry["gendered_state"] = "[state_name]_[gender_suffix]"
				part_states[part_id] = state_entry
		var/datum/robolimb/forced_prosthetic = resolve_static_species_forced_prosthetic(selected_species, part_id)
		if(istype(forced_prosthetic))
			locked_parts += part_id
			if(!forced_prosthetic.skin_tone && !forced_prosthetic.skin_color)
				synth_color_parts += part_id
	var/list/external = list()
	for(var/part_id in BP_ALL)
		var/status = prefs.organ_data?[part_id]
		var/list/entry = list("status" = (status == "amputated" || status == "cyborg") ? status : "normal")
		if(status == "cyborg")
			var/company = prefs.rlimb_data?[part_id]
			if(istext(company) && length(company))
				entry["model"] = company
		external[part_id] = entry
	var/list/internal = list()
	var/static/list/conventional_organ_labels = list(
		O_HEART = "Heart",
		O_EYES = "Eyes",
		O_VOICE = "Larynx",
		O_LUNGS = "Lungs",
		O_LIVER = "Liver",
		O_KIDNEYS = "Kidneys",
		O_SPLEEN = "Spleen",
		O_APPENDIX = "Appendix",
		O_INTESTINE = "Intestines",
		O_STOMACH = "Stomach",
		O_BRAIN = "Brain"
		)
	var/list/internal_organ_ids = list()
	for(var/organ_id in conventional_organ_labels)
		if(selected_species.has_organ?[organ_id])
			internal_organ_ids += organ_id
	for(var/organ_id in selected_species.has_organ)
		if(!(organ_id in internal_organ_ids))
			internal_organ_ids += organ_id
	var/list/internal_organ_definitions = list()
	for(var/organ_id in internal_organ_ids)
		var/obj/item/organ/internal/organ_template = selected_species.get_chargen_internal_organ_path(organ_id)
		if(!organ_template)
			continue
		var/list/allowed_states = selected_species.get_chargen_internal_organ_states(organ_id)
		var/locked_state = selected_species.get_chargen_internal_organ_locked_state(organ_id)
		var/status = prefs.organ_data?[organ_id]
		if(!LAZYLEN(allowed_states))
			status = locked_state
		else if(!(status in allowed_states))
			status = "normal"
		internal[organ_id] = list("status" = status)
		var/organ_label = conventional_organ_labels[organ_id]
		if(!istext(organ_label) || !length(organ_label))
			organ_label = capitalize(initial(organ_template.name))
		internal_organ_definitions += list(list(
			"id" = organ_id,
			"label" = organ_label,
			"allowed_states" = allowed_states,
			"locked_state" = LAZYLEN(allowed_states) ? null : locked_state
			))
	var/full_body_allowed = islist(selected_species.has_organ) && !!selected_species.has_organ[O_BRAIN]
	return list(
		"allowed_model_ids" = allowed_model_ids.Copy(),
		"external" = external,
		"internal" = internal,
		"internal_organ_ids" = internal_organ_ids,
		"internal_organ_definitions" = internal_organ_definitions,
		"part_states" = part_states,
		"locked_parts" = locked_parts,
		"gender_suffix" = gender_suffix,
		"digitigrade_parts" = list(BP_L_LEG, BP_R_LEG, BP_L_FOOT, BP_R_FOOT),
		"full_body_allowed" = full_body_allowed,
		"brain_positronic_allowed" = !(selected_species.spawn_flags & SPECIES_NO_POSIBRAIN),
		"brain_drone_allowed" = !(selected_species.spawn_flags & SPECIES_NO_DRONEBRAIN),
		"skin_tone" = prefs.s_tone,
		"apply_skin_tone" = !!(base_species.appearance_flags & HAS_SKIN_TONE),
		"apply_skin_color" = !!(base_species.appearance_flags & HAS_SKIN_COLOR),
		"synth_color_enabled" = !!prefs.synth_color,
		"synth_color" = rgb(prefs.r_synth, prefs.g_synth, prefs.b_synth),
		"synth_color_parts" = synth_color_parts,
		"synth_markings" = !!prefs.synth_markings,
		"color_multiply" = !!base_species.color_mult
	)

/datum/tgui_module/custom_marking_designer/proc/apply_basic_prosthetic_settings(list/params)
	if(!prefs || !islist(params))
		return FALSE
	var/has_blood_type = ("blood_type" in params)
	var/blood_type = null
	if(has_blood_type)
		blood_type = params["blood_type"]
		if(!istext(blood_type) || !(blood_type in valid_bloodtypes))
			return FALSE
	var/has_blood_color = ("blood_color" in params)
	var/safe_blood_color = null
	if(has_blood_color)
		var/raw_blood_color = params["blood_color"]
		if(!istext(raw_blood_color) || !length(raw_blood_color))
			return FALSE
		safe_blood_color = sanitize_hexcolor(raw_blood_color, FALSE)
		if(!istext(safe_blood_color))
			return FALSE
	var/has_blood_reagent = ("blood_reagent" in params)
	var/blood_reagent = null
	if(has_blood_reagent)
		blood_reagent = params["blood_reagent"]
		if(!istext(blood_reagent) || !(blood_reagent in valid_bloodreagents))
			return FALSE
	var/has_needs_glasses = ("needs_glasses" in params)
	var/needs_glasses = null
	if(has_needs_glasses)
		var/raw_needs_glasses = params["needs_glasses"]
		if(isnum(raw_needs_glasses))
			needs_glasses = !!raw_needs_glasses
		else if(istext(raw_needs_glasses) && (lowertext(raw_needs_glasses) in list("1", "0", "true", "false", "yes", "no", "on", "off")))
			needs_glasses = (lowertext(raw_needs_glasses) in list("1", "true", "yes", "on"))
		else
			return FALSE
	var/has_synth_color_enabled = ("synth_color_enabled" in params)
	var/synth_color_enabled = null
	if(has_synth_color_enabled)
		var/raw_synth_color_enabled = params["synth_color_enabled"]
		if(isnum(raw_synth_color_enabled))
			synth_color_enabled = !!raw_synth_color_enabled
		else if(istext(raw_synth_color_enabled) && (lowertext(raw_synth_color_enabled) in list("1", "0", "true", "false", "yes", "no", "on", "off")))
			synth_color_enabled = (lowertext(raw_synth_color_enabled) in list("1", "true", "yes", "on"))
		else
			return FALSE
	var/has_synth_markings = ("synth_markings" in params)
	var/synth_markings = null
	if(has_synth_markings)
		var/raw_synth_markings = params["synth_markings"]
		if(isnum(raw_synth_markings))
			synth_markings = !!raw_synth_markings
		else if(istext(raw_synth_markings) && (lowertext(raw_synth_markings) in list("1", "0", "true", "false", "yes", "no", "on", "off")))
			synth_markings = (lowertext(raw_synth_markings) in list("1", "true", "yes", "on"))
		else
			return FALSE
	var/has_synth_color = ("synth_color" in params)
	var/safe_synth_color = null
	if(has_synth_color)
		var/raw_synth_color = params["synth_color"]
		if(!istext(raw_synth_color) || !length(raw_synth_color))
			return FALSE
		safe_synth_color = sanitize_hexcolor(raw_synth_color, rgb(prefs.r_synth, prefs.g_synth, prefs.b_synth))
	var/list/limb_operations = params?["limb_operations"]
	var/list/organ_operations = params?["organ_operations"]
	if(!isnull(limb_operations) && (!islist(limb_operations) || limb_operations.len > 11))
		return FALSE
	if(!isnull(organ_operations) && (!islist(organ_operations) || organ_operations.len > 10))
		return FALSE
	var/list/original_organ_data = prefs.organ_data
	var/list/original_rlimb_data = prefs.rlimb_data
	var/has_operations = (islist(limb_operations) && limb_operations.len) || (islist(organ_operations) && organ_operations.len)
	if(has_operations)
		prefs.organ_data = islist(original_organ_data) ? original_organ_data.Copy() : list()
		prefs.rlimb_data = islist(original_rlimb_data) ? original_rlimb_data.Copy() : list()
	var/datum/species/selected_species = GLOB.all_species?[prefs.species]
	for(var/list/operation as anything in limb_operations)
		if(!islist(operation))
			prefs.organ_data = original_organ_data
			prefs.rlimb_data = original_rlimb_data
			return FALSE
		var/target = operation["target"]
		var/state = operation["state"]
		var/company = operation["model"]
		if(!istext(target) || !istext(state))
			prefs.organ_data = original_organ_data
			prefs.rlimb_data = original_rlimb_data
			return FALSE
		if(target == "full_body")
			for(var/part_id in BP_ALL)
				if(resolve_static_species_forced_prosthetic(selected_species, part_id))
					prefs.organ_data = original_organ_data
					prefs.rlimb_data = original_rlimb_data
					return FALSE
		else
			var/list/affected_parts = list(target)
			switch(target)
				if(BP_TORSO)
					affected_parts += (BP_ALL - BP_TORSO)
				if(BP_GROIN)
					affected_parts += list(BP_L_LEG, BP_R_LEG, BP_L_FOOT, BP_R_FOOT)
				if(BP_L_LEG)
					affected_parts += BP_L_FOOT
				if(BP_R_LEG)
					affected_parts += BP_R_FOOT
				if(BP_L_ARM)
					affected_parts += BP_L_HAND
				if(BP_R_ARM)
					affected_parts += BP_R_HAND
				if(BP_L_FOOT)
					affected_parts += BP_L_LEG
				if(BP_R_FOOT)
					affected_parts += BP_R_LEG
				if(BP_L_HAND)
					affected_parts += BP_L_ARM
				if(BP_R_HAND)
					affected_parts += BP_R_ARM
			for(var/affected_part_id in affected_parts)
				if(resolve_static_species_forced_prosthetic(selected_species, affected_part_id))
					prefs.organ_data = original_organ_data
					prefs.rlimb_data = original_rlimb_data
					return FALSE
		if(!prefs.apply_chargen_limb_operation(target, state, company, usr))
			prefs.organ_data = original_organ_data
			prefs.rlimb_data = original_rlimb_data
			return FALSE
	for(var/list/operation as anything in organ_operations)
		if(!islist(operation) || !prefs.apply_chargen_internal_organ_operation(operation?["target"], operation?["state"]))
			prefs.organ_data = original_organ_data
			prefs.rlimb_data = original_rlimb_data
			return FALSE
	if(has_synth_color_enabled)
		prefs.synth_color = synth_color_enabled
	if(has_synth_markings)
		prefs.synth_markings = synth_markings
	if(has_synth_color)
		prefs.r_synth = hex2num(copytext(safe_synth_color, 2, 4))
		prefs.g_synth = hex2num(copytext(safe_synth_color, 4, 6))
		prefs.b_synth = hex2num(copytext(safe_synth_color, 6, 8))
	if(has_blood_type)
		prefs.b_type = blood_type
	if(has_blood_color)
		prefs.blood_color = safe_blood_color
	if(has_blood_reagent)
		prefs.blood_reagents = blood_reagent
	if(has_needs_glasses)
		if(needs_glasses)
			prefs.disabilities |= NEARSIGHTED
		else
			prefs.disabilities &= ~NEARSIGHTED
	return TRUE

/datum/tgui_module/custom_marking_designer/proc/can_compose_prosthetics_from_static_catalog()
	if(!prefs)
		return FALSE
	var/datum/asset/spritesheet/custom_marking_designer/atlas = get_asset_datum(/datum/asset/spritesheet/custom_marking_designer)
	if(!atlas.is_ready())
		return FALSE
	var/list/catalog = atlas.get_prosthetic_catalog()
	var/list/models = catalog?["models"]
	return islist(models) && models.len

/datum/tgui_module/custom_marking_designer/proc/apply_neutral_preview_prosthetic_state()
	if(!prefs)
		return null
	var/list/restore = list(
		"organ_data" = prefs.organ_data,
		"rlimb_data" = prefs.rlimb_data,
		"synth_color" = prefs.synth_color
	)
	var/list/neutral_organ_data = islist(prefs.organ_data) ? prefs.organ_data.Copy() : list()
	var/list/neutral_rlimb_data = islist(prefs.rlimb_data) ? prefs.rlimb_data.Copy() : list()
	for(var/part_id in BP_ALL)
		neutral_organ_data[part_id] = null
		neutral_rlimb_data[part_id] = null
	prefs.organ_data = neutral_organ_data
	prefs.rlimb_data = neutral_rlimb_data
	prefs.synth_color = FALSE
	return restore

/datum/tgui_module/custom_marking_designer/proc/restore_preview_prosthetic_state(list/restore)
	if(!prefs || !islist(restore))
		return
	prefs.organ_data = restore["organ_data"]
	prefs.rlimb_data = restore["rlimb_data"]
	prefs.synth_color = restore["synth_color"]

/datum/tgui_module/custom_marking_designer/proc/build_basic_appearance_definition_context()
	if(!prefs)
		return null
	var/access_key = prefs.client?.ckey || ""
	var/context_key = "[prefs.species || ""]|[prefs.custom_base || ""]|[access_key]"
	if(!islist(basic_appearance_definition_context_cache))
		basic_appearance_definition_context_cache = list()
	var/list/cached_context = basic_appearance_definition_context_cache[context_key]
	if(islist(cached_context))
		return cached_context
	var/list/definition_cache = islist(custom_marking_basic_appearance_definition_cache) ? custom_marking_basic_appearance_definition_cache : build_basic_appearance_definition_cache()
	var/list/hair_defs_by_name = islist(definition_cache) ? definition_cache["hair_styles_by_name"] : null
	var/list/grad_defs = islist(definition_cache) ? definition_cache["gradient_styles"] : null
	var/list/facial_defs_by_name = islist(definition_cache) ? definition_cache["facial_hair_styles_by_name"] : null
	var/list/ear_defs_by_name = islist(definition_cache) ? definition_cache["ear_styles_by_name"] : null
	var/list/tail_defs_by_name = islist(definition_cache) ? definition_cache["tail_styles_by_name"] : null
	var/list/wing_defs_by_name = islist(definition_cache) ? definition_cache["wing_styles_by_name"] : null
	if(!islist(hair_defs_by_name))
		hair_defs_by_name = build_basic_appearance_hair_definition_map()
	if(!islist(grad_defs))
		grad_defs = build_basic_appearance_gradient_definitions()
	if(!islist(facial_defs_by_name))
		facial_defs_by_name = build_basic_appearance_facial_hair_definition_map()
	if(!islist(ear_defs_by_name))
		ear_defs_by_name = build_basic_appearance_ear_definition_map()
	if(!islist(tail_defs_by_name))
		tail_defs_by_name = build_basic_appearance_tail_definition_map()
	if(!islist(wing_defs_by_name))
		wing_defs_by_name = build_basic_appearance_wing_definition_map()
	var/list/definition_data = list()
	var/list/hair_defs = list()
	var/list/hair_styles = prefs.get_available_styles(global.hair_styles_list)
	if(islist(hair_styles) && hair_styles.len)
		for(var/style_name in hair_styles)
			CUSTOM_MARKING_CHECK_TICK
			var/list/def = hair_defs_by_name?[style_name]
			if(!islist(def))
				def = list("id" = style_name, "name" = style_name)
			hair_defs += list(def)
	definition_data["hair_styles"] = hair_defs
	definition_data["gradient_styles"] = grad_defs
	var/list/facial_defs = list()
	var/list/facial_styles = prefs.get_available_styles(global.facial_hair_styles_list)
	if(islist(facial_styles) && facial_styles.len)
		for(var/style_name in facial_styles)
			CUSTOM_MARKING_CHECK_TICK
			var/list/def = facial_defs_by_name?[style_name]
			if(!islist(def))
				def = list("id" = style_name, "name" = style_name)
			facial_defs += list(def)
	definition_data["facial_hair_styles"] = facial_defs
	var/list/ear_defs = list()
	var/list/ear_styles = prefs.get_available_styles(global.ear_styles_list)
	if(islist(ear_styles) && ear_styles.len)
		for(var/style_name in ear_styles)
			CUSTOM_MARKING_CHECK_TICK
			var/list/def = ear_defs_by_name?[style_name]
			if(!islist(def))
				def = list("id" = style_name, "name" = style_name)
			ear_defs += list(def)
	definition_data["ear_styles"] = ear_defs
	var/list/tail_defs = list()
	var/list/tail_styles = prefs.get_available_styles(global.tail_styles_list)
	if(islist(tail_styles) && tail_styles.len)
		for(var/style_name in tail_styles)
			CUSTOM_MARKING_CHECK_TICK
			var/list/def = tail_defs_by_name?[style_name]
			if(!islist(def))
				def = list("id" = style_name, "name" = style_name)
			tail_defs += list(def)
	definition_data["tail_styles"] = tail_defs
	var/list/wing_defs = list()
	var/list/wing_styles = prefs.get_available_styles(global.wing_styles_list)
	if(islist(wing_styles) && wing_styles.len)
		for(var/style_name in wing_styles)
			CUSTOM_MARKING_CHECK_TICK
			var/list/def = wing_defs_by_name?[style_name]
			if(!islist(def))
				def = list("id" = style_name, "name" = style_name)
			wing_defs += list(def)
	definition_data["wing_styles"] = wing_defs
	var/list/allowed_style_ids = list()
	for(var/definition_key in list("hair_styles", "gradient_styles", "facial_hair_styles", "ear_styles", "tail_styles", "wing_styles"))
		var/list/allowed_ids = list()
		var/list/definitions = definition_data[definition_key]
		if(islist(definitions))
			for(var/list/definition as anything in definitions)
				var/definition_id = definition?["id"]
				if(istext(definition_id) && length(definition_id))
					allowed_ids += definition_id
		allowed_style_ids[definition_key] = allowed_ids
	var/list/allowed_prosthetic_model_ids = build_allowed_prosthetic_model_ids()
	var/revision_seed = "basic-appearance-definitions-v2|[context_key]|[json_encode(allowed_style_ids)]|[json_encode(allowed_prosthetic_model_ids)]"
	cached_context = list(
		"revision" = md5(revision_seed),
		"definition_data" = definition_data,
		"allowed_style_ids" = allowed_style_ids,
		"allowed_prosthetic_model_ids" = allowed_prosthetic_model_ids
	)
	basic_appearance_definition_context_cache[context_key] = cached_context
	return cached_context

/datum/tgui_module/custom_marking_designer/proc/append_basic_appearance_definitions(list/payload, known_revision = null)
	if(!prefs || !islist(payload))
		return FALSE
	var/list/context = build_basic_appearance_definition_context()
	if(!islist(context))
		return FALSE
	var/revision = context["revision"]
	payload["definition_revision"] = revision
	payload["allowed_style_ids"] = context["allowed_style_ids"]
	if(istext(known_revision) && length(known_revision) && known_revision == revision)
		return FALSE
	payload["definition_data"] = context["definition_data"]
	return TRUE

/datum/tgui_module/custom_marking_designer/proc/build_basic_preview_variant_bundles(digitigrade_value, digitigrade_allowed, biological_gender, list/possible_genders)
	if(!prefs)
		return null
	var/original_biological_gender = prefs.biological_gender
	var/original_identifying_gender = prefs.identifying_gender
	var/original_digitigrade = prefs.digitigrade
	prefs.biological_gender = biological_gender
	if(biological_gender != original_biological_gender)
		prefs.identifying_gender = biological_gender
	prefs.digitigrade = digitigrade_value
	var/list/preview_bundle = build_stripped_preview_source_bundle(digitigrade_value)
	var/list/preview_bundle_alt = null
	if(digitigrade_allowed)
		prefs.digitigrade = !digitigrade_value
		preview_bundle_alt = build_stripped_preview_source_bundle(!digitigrade_value)
	var/alternate_gender = resolve_basic_alternate_preview_gender(possible_genders, biological_gender)
	var/list/preview_bundle_gender_alt = null
	var/list/preview_bundle_gender_alt_digitigrade = null
	if(!isnull(alternate_gender))
		prefs.biological_gender = alternate_gender
		prefs.identifying_gender = alternate_gender
		prefs.digitigrade = digitigrade_value
		preview_bundle_gender_alt = build_stripped_preview_source_bundle(digitigrade_value)
		if(digitigrade_allowed)
			prefs.digitigrade = !digitigrade_value
			preview_bundle_gender_alt_digitigrade = build_stripped_preview_source_bundle(!digitigrade_value)
	prefs.biological_gender = original_biological_gender
	prefs.identifying_gender = original_identifying_gender
	prefs.digitigrade = original_digitigrade
	return list(
		"primary" = preview_bundle,
		"alternate" = preview_bundle_alt,
		"gender_alternate" = preview_bundle_gender_alt,
		"gender_alternate_digitigrade" = preview_bundle_gender_alt_digitigrade
	)

// Build payload for the basic appearance tab (Lira, December 2025)
/datum/tgui_module/custom_marking_designer/proc/build_basic_appearance_payload(preview_digitigrade = null, preview_only = FALSE, known_definition_revision = null, known_preview_revision = null, known_preview_signature = null, known_preview_revision_alt = null, known_preview_signature_alt = null, known_preview_revision_gender_alt = null, known_preview_signature_gender_alt = null, known_preview_revision_gender_alt_digitigrade = null, known_preview_signature_gender_alt_digitigrade = null)
	var/list/yield_context = custom_marking_begin_manual_yield()
	if(!prefs)
		custom_marking_end_manual_yield(yield_context)
		return null
	var/list/payload = list()
	payload["species_id"] = prefs.species
	payload["custom_base"] = prefs.custom_base
	var/list/base_genders = build_base_biological_gender_options()
	var/list/possible_genders = build_basic_biological_gender_options(base_genders)
	var/biological_gender = resolve_basic_biological_gender(possible_genders, prefs.biological_gender)
	var/datum/species/selected_species = GLOB.all_species?[prefs.species]
	payload["biological_gender"] = biological_gender
	payload["base_biological_genders"] = base_genders
	payload["biological_genders"] = possible_genders
	payload["preview_gender_suffix"] = resolve_species_body_preview_gender_suffix(selected_species, biological_gender)
	var/digitigrade_allowed = is_digitigrade_allowed()
	var/digitigrade_value = digitigrade_allowed ? !!prefs.digitigrade : FALSE
	if(!isnull(preview_digitigrade))
		digitigrade_value = digitigrade_allowed ? !!preview_digitigrade : FALSE
	payload["digitigrade_allowed"] = digitigrade_allowed
	payload["digitigrade"] = digitigrade_value
	payload["blood_types"] = valid_bloodtypes.Copy()
	payload["blood_reagents"] = valid_bloodreagents.Copy()
	if(preview_only)
		payload["preview_only"] = TRUE
	if(!preview_only)
		payload["blood_type"] = prefs.b_type
		payload["blood_reagent"] = prefs.blood_reagents
		payload["blood_color"] = prefs.blood_color
		payload["needs_glasses"] = !!(prefs.disabilities & NEARSIGHTED)
		payload["body_color"] = rgb(prefs.r_skin, prefs.g_skin, prefs.b_skin)
		payload["eye_color"] = rgb(prefs.r_eyes, prefs.g_eyes, prefs.b_eyes)
		payload["hair_style"] = prefs.h_style
		payload["hair_color"] = rgb(prefs.r_hair, prefs.g_hair, prefs.b_hair)
		var/grad_style_value = prefs.grad_style
		if(istext(grad_style_value) && length(grad_style_value))
			var/lower_grad = lowertext(grad_style_value)
			if(lower_grad == "none" || !(grad_style_value in GLOB.hair_gradients))
				grad_style_value = null
		payload["hair_gradient_style"] = grad_style_value
		payload["hair_gradient_color"] = rgb(prefs.r_grad, prefs.g_grad, prefs.b_grad)
		payload["facial_hair_style"] = prefs.f_style
		payload["facial_hair_color"] = rgb(prefs.r_facial, prefs.g_facial, prefs.b_facial)
		payload["ear_style"] = prefs.ear_style
		payload["ear_colors"] = list(
			rgb(prefs.r_ears, prefs.g_ears, prefs.b_ears),
			rgb(prefs.r_ears2, prefs.g_ears2, prefs.b_ears2),
			rgb(prefs.r_ears3, prefs.g_ears3, prefs.b_ears3)
		)
		payload["horn_style"] = prefs.ear_secondary_style
		payload["horn_colors"] = islist(prefs.ear_secondary_colors) ? prefs.ear_secondary_colors.Copy() : list()
		payload["tail_style"] = prefs.tail_style
		payload["tail_colors"] = list(
			rgb(prefs.r_tail, prefs.g_tail, prefs.b_tail),
			rgb(prefs.r_tail2, prefs.g_tail2, prefs.b_tail2),
			rgb(prefs.r_tail3, prefs.g_tail3, prefs.b_tail3)
		)
		payload["wing_style"] = prefs.wing_style
		payload["wing_colors"] = list(
			rgb(prefs.r_wing, prefs.g_wing, prefs.b_wing),
			rgb(prefs.r_wing2, prefs.g_wing2, prefs.b_wing2),
			rgb(prefs.r_wing3, prefs.g_wing3, prefs.b_wing3)
		)
	append_basic_appearance_definitions(payload, known_definition_revision)
	var/can_compose_prosthetics = can_compose_prosthetics_from_static_catalog()
	payload["prosthetic_context"] = can_compose_prosthetics ? build_basic_prosthetic_context() : null
	var/original_digitigrade = prefs.digitigrade
	var/original_hair = prefs.h_style
	var/original_grad = prefs.grad_style
	var/original_facial = prefs.f_style
	var/original_ears = prefs.ear_style
	var/original_horns = prefs.ear_secondary_style
	var/original_tail = prefs.tail_style
	var/original_wing = prefs.wing_style
	var/original_body_markings = prefs.body_markings
	var/list/prosthetic_restore = can_compose_prosthetics ? apply_neutral_preview_prosthetic_state() : null
	prefs.h_style = null
	prefs.grad_style = null
	prefs.f_style = "Shaved"
	prefs.ear_style = null
	prefs.ear_secondary_style = null
	prefs.wing_style = null
	prefs.tail_style = "hide species-sprite tail"
	prefs.body_markings = null
	var/list/preview_bundles = build_basic_preview_variant_bundles(digitigrade_value, digitigrade_allowed, biological_gender, possible_genders)
	var/list/preview_bundle = preview_bundles?["primary"]
	var/list/preview_bundle_alt = preview_bundles?["alternate"]
	var/list/preview_bundle_gender_alt = preview_bundles?["gender_alternate"]
	var/list/preview_bundle_gender_alt_digitigrade = preview_bundles?["gender_alternate_digitigrade"]
	prefs.body_markings = original_body_markings
	prefs.h_style = original_hair
	prefs.grad_style = original_grad
	prefs.f_style = original_facial
	prefs.ear_style = original_ears
	prefs.ear_secondary_style = original_horns
	prefs.tail_style = original_tail
	prefs.wing_style = original_wing
	prefs.digitigrade = original_digitigrade
	if(islist(prosthetic_restore))
		restore_preview_prosthetic_state(prosthetic_restore)
	append_preview_bundle_delta(payload, preview_bundle, null, known_preview_revision, known_preview_signature)
	append_preview_bundle_delta(payload, preview_bundle_alt, "alt", known_preview_revision_alt, known_preview_signature_alt)
	append_preview_bundle_delta(payload, preview_bundle_gender_alt, "gender_alt", known_preview_revision_gender_alt, known_preview_signature_gender_alt)
	append_preview_bundle_delta(payload, preview_bundle_gender_alt_digitigrade, "gender_alt_digitigrade", known_preview_revision_gender_alt_digitigrade, known_preview_signature_gender_alt_digitigrade)
	payload["preview_width"] = get_preview_canvas_width()
	payload["preview_height"] = get_preview_canvas_height()
	var/list/canvas_backgrounds_live = build_canvas_background_options()
	if(islist(canvas_backgrounds_live) && canvas_backgrounds_live.len)
		payload["canvas_backgrounds"] = canvas_backgrounds_live
		payload["default_canvas_background"] = "default"
	custom_marking_end_manual_yield(yield_context)
	return payload

// Normalize a part key from incoming params
/datum/tgui_module/custom_marking_designer/proc/resolve_action_part(list/params)
	if(mark)
		var/raw_part = params?["part"]
		if(istext(raw_part) && length(raw_part))
			var/normalized = mark.normalize_part(raw_part)
			if(istext(normalized) && length(normalized))
				return normalized
	if(active_body_part)
		return active_body_part
	return default_body_part()

// Echo diff + ack sequence back to the client
/datum/tgui_module/custom_marking_designer/proc/send_diff_ack(list/diff_payload, width, height, stroke_id = null, list/extra = null)
	diff_sequence++
	var/list/custom = list(
		"diff" = diff_payload,
		"diff_seq" = diff_sequence,
		"width" = width,
		"height" = height,
		"body_part_layer_revision" = body_part_layer_revision,
		"preview_revision" = preview_revision
	)
	if(!isnull(stroke_id))
		custom["stroke"] = stroke_id
	if(islist(extra))
		for(var/key in extra)
			custom[key] = extra[key]
	custom["grid"] = get_session(active_dir, active_body_part)?.get_grid()
	var/datum/tgui/active_ui = SStgui.get_open_ui(usr, src)
	if(active_ui)
		active_ui.send_update(custom)
	else
		SStgui.update_uis(src, custom)

// Handle interactive actions from the TGUI frontend
/datum/tgui_module/custom_marking_designer/tgui_act(action, params)
	if(..())
		return TRUE
	var/handled = TRUE
	if(action == "static_asset_manifest_failed")
		static_manifest_client_ready = FALSE
		prefs?.close_custom_marking_designer_loading()
		return FALSE
	if(action == "static_asset_manifest_fallback_ready")
		var/datum/asset/spritesheet/custom_marking_designer/fallback_atlas = get_asset_datum(/datum/asset/spritesheet/custom_marking_designer)
		if(SScustom_marking?.is_static_atlas_terminal_fallback(fallback_atlas))
			var/fallback_species = prefs?.species || "unknown"
			var/fallback_base = prefs?.custom_base || "none"
			report_custom_marking_atlas_fallback(
				"static-manifest-to-standalone",
				"a Designer session opened without a client-ready canonical atlas",
				"species=[fallback_species], custom_base=[fallback_base]"
			)
			static_manifest_client_ready = TRUE
			prefs?.close_custom_marking_designer_loading()
		return FALSE
	if(action == "static_asset_manifest_ready")
		var/manifest_asset = params?["asset"]
		var/manifest_revision = params?["revision"]
		if(!isnum(manifest_revision))
			manifest_revision = text2num(manifest_revision)
		var/datum/asset/spritesheet/custom_marking_designer/atlas = get_asset_datum(/datum/asset/spritesheet/custom_marking_designer)
		if(atlas.is_ready() && manifest_asset == atlas.get_manifest_asset_name() && manifest_revision == atlas.get_manifest_revision())
			static_manifest_client_ready = TRUE
			prefs?.close_custom_marking_designer_loading()
		return FALSE
	if(action == "load_traits")
		send_traits_payload(usr)
		return TRUE
	if(action == "save_traits")
		var/close_ui = !!params?["close"]
		var/request_id = params?["request_id"]
		var/list/rejection_reasons = list()
		var/list/change_result = list()
		var/traits_updated = apply_character_traits_payload(params, rejection_reasons, usr, change_result)
		if(traits_updated)
			traits_revision++
			refresh_preferences_window_if_visible(!!change_result["traits_changed"])
			if(close_ui)
				SStgui.close_uis(src)
				return FALSE
		var/list/save_result = build_traits_save_result(request_id, traits_updated, rejection_reasons)
		send_traits_payload(usr, save_result)
		return TRUE
	if(action == "close_traits")
		SStgui.close_uis(src)
		return FALSE
	if(action == "enable_custom_markings")
		if(!prefs)
			return TRUE
		var/datum/custom_marking/enabled_mark = prefs.ensure_primary_custom_marking()
		if(!istype(enabled_mark))
			return TRUE
		if(mark != enabled_mark)
			mark = enabled_mark
			is_new_mark = FALSE
			sessions = list()
			active_body_part = default_body_part()
			initial_snapshot = mark.to_save()
			original_mark_id = mark.id
			original_style_name = mark.get_style_name()
			body_part_layer_revision++
			preview_revision++
		allow_custom_tab = TRUE
		register_custom_marking_style(mark, TRUE)
		if(prefs)
			prefs.refresh_custom_marking_assets(FALSE, TRUE, mark, TRUE)
		refresh_preferences_window_if_visible(TRUE)
		SStgui.update_uis(src)
		return TRUE
	if(action == "apply_preview_diff")
		var/list/diff = params?["diff"]
		if(!islist(diff) || !diff.len)
			return TRUE
		var/dir_override = text2num(params?["dir"])
		if(!isnum(dir_override) || !dir_override)
			dir_override = active_dir
		var/part = resolve_action_part(params)
		ensure_body_part_registered(part)
		active_dir = dir_override
		set_active_body_part(part)
		var/datum/custom_marking_session/session = get_session(active_dir, part)
		var/list/diff_result = session?.apply_client_diff(diff, params?["height"], params?["width"])
		var/pixels_changed = FALSE
		var/canvas_changed = FALSE
		if(islist(diff_result))
			pixels_changed = !!diff_result["changed"]
			canvas_changed = !!diff_result["canvas_resized"]
		else
			pixels_changed = !!diff_result
		if(pixels_changed || canvas_changed)
			set_mark_dirty(TRUE)
			body_part_layer_revision++
			preview_revision++
		var/list/extra_update = null
		if(canvas_changed)
			extra_update = list(
				"part_canvas_size" = mark?.get_part_canvas_size_payload(),
				"part_render_priority" = mark?.get_part_render_priority_payload(),
				"active_canvas_width" = mark ? mark.get_part_canvas_width(active_body_part) : get_canvas_width(),
				"active_canvas_height" = mark ? mark.get_part_canvas_height(active_body_part) : get_canvas_height()
			)
		send_diff_ack(diff, params?["width"], params?["height"], params?["stroke"], extra_update)
		commit_session(session)
		if(canvas_changed)
			SStgui.update_uis(src)
	else if(action == "set_canvas_size")
		var/new_width = params?["width"]
		var/new_height = params?["height"]
		var/resized = FALSE
		if(mark)
			resized = mark.resize_canvas(new_width, new_height)
		if(resized)
			register_custom_marking_style(mark, TRUE)
			sessions = list()
			body_part_layer_revision++
			preview_revision++
			set_mark_dirty(TRUE)
		SStgui.update_uis(src)
		return TRUE
	else if(action == "set_part_canvas_size")
		if(!mark)
			return TRUE
		var/part = resolve_action_part(params)
		if(!ensure_body_part_registered(part))
			return TRUE
		var/state_value = params?["large"]
		var/desired = null
		if(isnum(state_value))
			desired = !!state_value
		else if(istext(state_value))
			var/lower_value = lowertext(state_value)
			if(lower_value in list("1", "true", "yes", "on"))
				desired = TRUE
			else if(lower_value in list("0", "false", "no", "off"))
				desired = FALSE
		if(isnull(desired))
			desired = !mark.is_part_large_canvas(part)
		if(mark.set_part_canvas_size(part, desired))
			register_custom_marking_style(mark, TRUE)
			set_mark_dirty(TRUE)
			body_part_layer_revision++
			preview_revision++
		SStgui.update_uis(src)
		return TRUE
	// Added to avoid race condition (Lira, November 2025)
	else if(action == "discard_and_close")
		discard_changes()
		SStgui.close_uis(src)
		return FALSE
	else if(action == "save_and_close")
		if(save_in_progress)
			SStgui.update_uis(src)
			return TRUE
		var/replacements_updated = apply_part_replacement_payload(params?["part_replacements"])
		var/priority_updated = apply_part_render_priority_payload(params?["part_render_priority"])
		var/canvas_updated = apply_part_canvas_size_payload(params?["part_canvas_size"])
		if(replacements_updated || priority_updated || canvas_updated)
			register_custom_marking_style(mark, TRUE)
		var/saved = save_marking_changes(TRUE, TRUE, FALSE)
		if(saved)
			body_markings_refresh_pending = TRUE
		SStgui.close_uis(src)
		return FALSE
	else if(action == "save_progress")
		if(save_in_progress)
			SStgui.update_uis(src)
			return TRUE
		var/replacements_updated = apply_part_replacement_payload(params?["part_replacements"])
		var/priority_updated = apply_part_render_priority_payload(params?["part_render_priority"])
		var/canvas_updated = apply_part_canvas_size_payload(params?["part_canvas_size"])
		if(replacements_updated || priority_updated || canvas_updated)
			register_custom_marking_style(mark, TRUE)
		var/saved = save_marking_changes(TRUE, TRUE, FALSE)
		if(saved)
			body_markings_refresh_pending = TRUE
		SStgui.update_uis(src)
	else if(action == "load_body_markings")
		var/preview_only = FALSE
		var/preview_only_raw = params?["preview_only"]
		if(isnum(preview_only_raw))
			preview_only = !!preview_only_raw
		else if(istext(preview_only_raw))
			var/lower_preview = lowertext(preview_only_raw)
			if(lower_preview in list("1", "true", "yes", "on"))
				preview_only = TRUE
		var/list/species_override = null
		var/preview_species = params?["species"]
		var/preview_icon_base = params?["icon_base"]
		var/override_species = (istext(preview_species) && length(preview_species)) ? preview_species : prefs?.species
		acquire_preview_payload_build_lock()
		if(preview_only && istext(override_species) && length(override_species))
			species_override = apply_preview_species_override(override_species, usr, FALSE, preview_icon_base)
		if(body_markings_refresh_pending)
			if(mark)
				register_custom_marking_style(mark, FALSE)
			invalidate_reference_payload_caches()
			body_markings_refresh_pending = FALSE
		var/list/body_payload = build_body_markings_payload(
			params?["known_definition_revision"],
			params?["known_preview_revision"],
			params?["known_preview_signature"],
			preview_only
		)
		if(islist(species_override))
			restore_preview_species_override(species_override)
		release_preview_payload_build_lock()
		if(islist(body_payload))
			var/list/update = list("body_markings_payload" = body_payload)
			var/datum/tgui/active_ui = SStgui.get_open_ui(usr, src)
			if(active_ui)
				active_ui.send_update(update)
			else
				SStgui.update_uis(src, update)
		return TRUE
	else if(action == "load_basic_appearance")
		var/preview_only = FALSE
		var/preview_only_raw = params?["preview_only"]
		if(isnum(preview_only_raw))
			preview_only = !!preview_only_raw
		else if(istext(preview_only_raw))
			var/lower_preview = lowertext(preview_only_raw)
			if(lower_preview in list("1", "true", "yes", "on"))
				preview_only = TRUE
		var/digi_override = null
		if(preview_only)
			var/digi_raw = params?["digitigrade"]
			if(isnum(digi_raw))
				digi_override = !!digi_raw
			else if(istext(digi_raw))
				var/lower = lowertext(digi_raw)
				if(lower in list("1", "true", "yes", "on"))
					digi_override = TRUE
				else if(lower in list("0", "false", "no", "off"))
					digi_override = FALSE
		var/list/species_override = null
		var/preview_species = params?["species"]
		var/preview_icon_base = params?["icon_base"]
		var/override_species = (istext(preview_species) && length(preview_species)) ? preview_species : prefs?.species
		acquire_preview_payload_build_lock()
		if(preview_only && istext(override_species) && length(override_species))
			species_override = apply_preview_species_override(override_species, usr, FALSE, preview_icon_base)
		var/list/basic_payload = build_basic_appearance_payload(
			digi_override,
			preview_only,
			params?["known_definition_revision"],
			params?["known_preview_revision"],
			params?["known_preview_signature"],
			params?["known_alt_preview_revision"],
			params?["known_alt_preview_signature"],
			params?["known_gender_alt_preview_revision"],
			params?["known_gender_alt_preview_signature"],
			params?["known_gender_alt_digitigrade_preview_revision"],
			params?["known_gender_alt_digitigrade_preview_signature"]
		)
		if(islist(species_override))
			restore_preview_species_override(species_override)
		release_preview_payload_build_lock()
		if(islist(basic_payload))
			var/list/update = list("basic_appearance_payload" = basic_payload)
			var/datum/tgui/active_ui = SStgui.get_open_ui(usr, src)
			if(active_ui)
				active_ui.send_update(update)
			else
				SStgui.update_uis(src, update)
		return TRUE
	else if(action == "save_basic_appearance")
		var/close_ui = params?["close"]
		acquire_preview_payload_build_lock()
		var/basic_updated = apply_basic_appearance_payload(params)
		release_preview_payload_build_lock()
		if(basic_updated)
			traits_revision++
			refresh_preferences_window_if_visible(TRUE)
			if(close_ui)
				SStgui.close_uis(src)
				return FALSE
			SStgui.update_uis(src)
		return TRUE
	else if(action == "close_basic_appearance")
		SStgui.close_uis(src)
		return FALSE
	else if(action == "load_species")
		acquire_preview_payload_build_lock()
		var/list/species_payload = build_species_payload(usr, params?["preview_species"], params?["preview_icon_base"])
		release_preview_payload_build_lock()
		if(islist(species_payload))
			var/list/update = list("species_payload" = species_payload)
			var/datum/tgui/active_ui = SStgui.get_open_ui(usr, src)
			if(active_ui)
				active_ui.send_update(update)
			else
				SStgui.update_uis(src, update)
		return TRUE
	else if(action == "save_species")
		var/close_ui = params?["close"]
		acquire_preview_payload_build_lock()
		var/previous_species = prefs?.species
		var/previous_icon_base = prefs?.custom_base
		var/species_updated = apply_species_payload(params, usr)
		var/list/species_save_result = build_species_save_result_if_needed(species_updated, close_ui, params)
		release_preview_payload_build_lock()
		if(species_updated)
			if(prefs?.species != previous_species || prefs?.custom_base != previous_icon_base)
				traits_revision++
			refresh_preferences_window_if_visible(TRUE)
			if(close_ui)
				SStgui.close_uis(src)
				return FALSE
		var/list/update = islist(species_save_result) ? list("species_save_result" = species_save_result) : null
		var/datum/tgui/active_ui = SStgui.get_open_ui(usr, src)
		if(active_ui && islist(update))
			active_ui.send_update(update)
		else if(islist(update))
			SStgui.update_uis(src, update)
		else
			SStgui.update_uis(src)
		return TRUE
	else if(action == "close_species")
		SStgui.close_uis(src)
		return FALSE
	else if(action == "save_body_markings")
		var/close_ui = params?["close"]
		var/list/save_payload = resolve_body_marking_chunk_payload(params)
		if(save_payload == BODY_MARKING_CHUNK_PENDING)
			return TRUE
		var/body_updated = FALSE
		if(islist(save_payload))
			acquire_preview_payload_build_lock()
			body_updated = apply_body_marking_payload(save_payload)
			release_preview_payload_build_lock()
		if(body_updated)
			refresh_preferences_window_if_visible(TRUE)
			if(close_ui)
				SStgui.close_uis(src)
				return FALSE
			SStgui.update_uis(src)
		return TRUE
	else if(action == "close_body_markings")
		reset_body_marking_chunk_state()
		SStgui.close_uis(src)
		return FALSE
	else if(action == "discard_changes")
		discard_changes()
		SStgui.update_uis(src)
	else if(action == "view_raw_payload")
		handled = view_raw_marking_payload(usr, params)
	else if(action == "client_warning")
		handled = handle_client_warning(usr, params)
	else
		handled = FALSE
	return handled ? TRUE : FALSE

// Apply a basic appearance payload coming from the client (Lira, December 2025)
/datum/tgui_module/custom_marking_designer/proc/apply_basic_appearance_payload(list/params)
	if(!prefs)
		return FALSE
	if(!islist(params))
		return FALSE
	if(!apply_basic_prosthetic_settings(params))
		return FALSE
	var/requested_biological_gender = params?["biological_gender"]
	var/list/possible_genders = build_basic_biological_gender_options()
	if(!istext(requested_biological_gender) || !(requested_biological_gender in possible_genders))
		requested_biological_gender = prefs.biological_gender
	var/biological_gender = resolve_basic_biological_gender(possible_genders, requested_biological_gender)
	if(biological_gender != prefs.biological_gender)
		prefs.set_biological_gender(biological_gender)
	var/safe_hex
	var/digi_raw = params?["digitigrade"]
	var/digi_value = null
	if(isnum(digi_raw))
		digi_value = !!digi_raw
	else if(istext(digi_raw))
		var/lower = lowertext(digi_raw)
		if(lower in list("1", "true", "yes", "on"))
			digi_value = TRUE
		else if(lower in list("0", "false", "no", "off"))
			digi_value = FALSE
	if(!isnull(digi_value))
		if(is_digitigrade_allowed())
			prefs.digitigrade = digi_value
	var/body_color = params?["body_color"]
	if(istext(body_color) && length(body_color))
		safe_hex = sanitize_hexcolor(body_color, rgb(prefs.r_skin, prefs.g_skin, prefs.b_skin))
		prefs.r_skin = hex2num(copytext(safe_hex, 2, 4))
		prefs.g_skin = hex2num(copytext(safe_hex, 4, 6))
		prefs.b_skin = hex2num(copytext(safe_hex, 6, 8))
	var/eye_color = params?["eye_color"]
	if(istext(eye_color) && length(eye_color))
		safe_hex = sanitize_hexcolor(eye_color, rgb(prefs.r_eyes, prefs.g_eyes, prefs.b_eyes))
		prefs.r_eyes = hex2num(copytext(safe_hex, 2, 4))
		prefs.g_eyes = hex2num(copytext(safe_hex, 4, 6))
		prefs.b_eyes = hex2num(copytext(safe_hex, 6, 8))
	var/hair_style = params?["hair_style"]
	if(istext(hair_style) && length(hair_style))
		var/list/hair_styles = prefs.get_available_styles(global.hair_styles_list)
		if(islist(hair_styles) && (hair_style in hair_styles))
			prefs.h_style = (hair_style == "Normal") ? null : hair_style
	else if(isnull(hair_style))
		prefs.h_style = null
	var/hair_color = params?["hair_color"]
	if(istext(hair_color) && length(hair_color))
		safe_hex = sanitize_hexcolor(hair_color, rgb(prefs.r_hair, prefs.g_hair, prefs.b_hair))
		prefs.r_hair = hex2num(copytext(safe_hex, 2, 4))
		prefs.g_hair = hex2num(copytext(safe_hex, 4, 6))
		prefs.b_hair = hex2num(copytext(safe_hex, 6, 8))
	var/grad_style = params?["hair_gradient_style"]
	if(istext(grad_style) && length(grad_style))
		var/lower = lowertext(grad_style)
		if(lower == "none")
			prefs.grad_style = null
		else if(grad_style in GLOB.hair_gradients)
			prefs.grad_style = grad_style
	else if(isnull(grad_style))
		prefs.grad_style = null
	var/grad_color = params?["hair_gradient_color"]
	if(istext(grad_color) && length(grad_color))
		safe_hex = sanitize_hexcolor(grad_color, rgb(prefs.r_grad, prefs.g_grad, prefs.b_grad))
		prefs.r_grad = hex2num(copytext(safe_hex, 2, 4))
		prefs.g_grad = hex2num(copytext(safe_hex, 4, 6))
		prefs.b_grad = hex2num(copytext(safe_hex, 6, 8))
	var/facial_style = params?["facial_hair_style"]
	if(istext(facial_style) && length(facial_style))
		var/list/facial_styles = prefs.get_available_styles(global.facial_hair_styles_list)
		if(islist(facial_styles) && (facial_style in facial_styles))
			prefs.f_style = (facial_style == "Normal") ? "Shaved" : facial_style
	else if(isnull(facial_style))
		prefs.f_style = "Shaved"
	var/facial_color = params?["facial_hair_color"]
	if(istext(facial_color) && length(facial_color))
		safe_hex = sanitize_hexcolor(facial_color, rgb(prefs.r_facial, prefs.g_facial, prefs.b_facial))
		prefs.r_facial = hex2num(copytext(safe_hex, 2, 4))
		prefs.g_facial = hex2num(copytext(safe_hex, 4, 6))
		prefs.b_facial = hex2num(copytext(safe_hex, 6, 8))
	var/list/ear_styles = prefs.get_available_styles(global.ear_styles_list)
	var/ear_style = params?["ear_style"]
	if(istext(ear_style) && length(ear_style) && islist(ear_styles) && (ear_style in ear_styles))
		prefs.ear_style = (ear_style == "Normal") ? null : ear_style
	else if(isnull(ear_style))
		prefs.ear_style = null
	var/horn_style = params?["horn_style"]
	if(istext(horn_style) && length(horn_style) && islist(ear_styles) && (horn_style in ear_styles))
		prefs.ear_secondary_style = (horn_style == "Normal") ? null : horn_style
	else if(isnull(horn_style))
		prefs.ear_secondary_style = null
	var/list/ear_colors = params?["ear_colors"]
	if(islist(ear_colors))
		if(istext(ear_colors[1]) && length(ear_colors[1]))
			safe_hex = sanitize_hexcolor(ear_colors[1], rgb(prefs.r_ears, prefs.g_ears, prefs.b_ears))
			prefs.r_ears = hex2num(copytext(safe_hex, 2, 4))
			prefs.g_ears = hex2num(copytext(safe_hex, 4, 6))
			prefs.b_ears = hex2num(copytext(safe_hex, 6, 8))
		if(istext(ear_colors[2]) && length(ear_colors[2]))
			safe_hex = sanitize_hexcolor(ear_colors[2], rgb(prefs.r_ears2, prefs.g_ears2, prefs.b_ears2))
			prefs.r_ears2 = hex2num(copytext(safe_hex, 2, 4))
			prefs.g_ears2 = hex2num(copytext(safe_hex, 4, 6))
			prefs.b_ears2 = hex2num(copytext(safe_hex, 6, 8))
		if(istext(ear_colors[3]) && length(ear_colors[3]))
			safe_hex = sanitize_hexcolor(ear_colors[3], rgb(prefs.r_ears3, prefs.g_ears3, prefs.b_ears3))
			prefs.r_ears3 = hex2num(copytext(safe_hex, 2, 4))
			prefs.g_ears3 = hex2num(copytext(safe_hex, 4, 6))
			prefs.b_ears3 = hex2num(copytext(safe_hex, 6, 8))
	var/list/horn_colors = params?["horn_colors"]
	if(islist(horn_colors))
		var/list/new_colors = list()
		for(var/i = 1 to length(horn_colors))
			var/value = horn_colors[i]
			if(istext(value) && length(value))
				new_colors += sanitize_hexcolor(value, "#ffffff")
		prefs.ear_secondary_colors = new_colors
	var/list/tail_styles = prefs.get_available_styles(global.tail_styles_list)
	var/tail_style = params?["tail_style"]
	if(istext(tail_style) && length(tail_style) && islist(tail_styles) && (tail_style in tail_styles))
		prefs.tail_style = (tail_style == "Normal") ? null : tail_style
	else if(isnull(tail_style))
		prefs.tail_style = null
	var/list/tail_colors = params?["tail_colors"]
	if(islist(tail_colors))
		if(istext(tail_colors[1]) && length(tail_colors[1]))
			safe_hex = sanitize_hexcolor(tail_colors[1], rgb(prefs.r_tail, prefs.g_tail, prefs.b_tail))
			prefs.r_tail = hex2num(copytext(safe_hex, 2, 4))
			prefs.g_tail = hex2num(copytext(safe_hex, 4, 6))
			prefs.b_tail = hex2num(copytext(safe_hex, 6, 8))
		if(istext(tail_colors[2]) && length(tail_colors[2]))
			safe_hex = sanitize_hexcolor(tail_colors[2], rgb(prefs.r_tail2, prefs.g_tail2, prefs.b_tail2))
			prefs.r_tail2 = hex2num(copytext(safe_hex, 2, 4))
			prefs.g_tail2 = hex2num(copytext(safe_hex, 4, 6))
			prefs.b_tail2 = hex2num(copytext(safe_hex, 6, 8))
		if(istext(tail_colors[3]) && length(tail_colors[3]))
			safe_hex = sanitize_hexcolor(tail_colors[3], rgb(prefs.r_tail3, prefs.g_tail3, prefs.b_tail3))
			prefs.r_tail3 = hex2num(copytext(safe_hex, 2, 4))
			prefs.g_tail3 = hex2num(copytext(safe_hex, 4, 6))
			prefs.b_tail3 = hex2num(copytext(safe_hex, 6, 8))
	var/list/wing_styles = prefs.get_available_styles(global.wing_styles_list)
	var/wing_style = params?["wing_style"]
	if(istext(wing_style) && length(wing_style) && islist(wing_styles) && (wing_style in wing_styles))
		prefs.wing_style = (wing_style == "Normal") ? null : wing_style
	else if(isnull(wing_style))
		prefs.wing_style = null
	var/list/wing_colors = params?["wing_colors"]
	if(islist(wing_colors))
		if(istext(wing_colors[1]) && length(wing_colors[1]))
			safe_hex = sanitize_hexcolor(wing_colors[1], rgb(prefs.r_wing, prefs.g_wing, prefs.b_wing))
			prefs.r_wing = hex2num(copytext(safe_hex, 2, 4))
			prefs.g_wing = hex2num(copytext(safe_hex, 4, 6))
			prefs.b_wing = hex2num(copytext(safe_hex, 6, 8))
		if(istext(wing_colors[2]) && length(wing_colors[2]))
			safe_hex = sanitize_hexcolor(wing_colors[2], rgb(prefs.r_wing2, prefs.g_wing2, prefs.b_wing2))
			prefs.r_wing2 = hex2num(copytext(safe_hex, 2, 4))
			prefs.g_wing2 = hex2num(copytext(safe_hex, 4, 6))
			prefs.b_wing2 = hex2num(copytext(safe_hex, 6, 8))
		if(istext(wing_colors[3]) && length(wing_colors[3]))
			safe_hex = sanitize_hexcolor(wing_colors[3], rgb(prefs.r_wing3, prefs.g_wing3, prefs.b_wing3))
			prefs.r_wing3 = hex2num(copytext(safe_hex, 2, 4))
			prefs.g_wing3 = hex2num(copytext(safe_hex, 4, 6))
			prefs.b_wing3 = hex2num(copytext(safe_hex, 6, 8))
	prefs.sanitize_body_styles()
	return TRUE

/datum/tgui_module/custom_marking_designer/proc/apply_preview_species_override(species_id, mob/user, allow_unselectable = FALSE, preview_icon_base = null)
	if(!prefs)
		return null
	if(!istext(species_id) || !length(species_id))
		return null
	var/datum/species/override = GLOB.all_species?[species_id]
	if(!istype(override))
		return null
	if(!allow_unselectable && user && !is_species_selectable(user, override))
		return null
	var/resolved_icon_base = resolve_species_icon_base(species_id, preview_icon_base)
	var/icon_base_changed = istext(resolved_icon_base) && length(resolved_icon_base) && resolved_icon_base != prefs.custom_base
	if(species_id == prefs.species && !icon_base_changed)
		return null
	var/list/restore = list(
		"species" = prefs.species,
		"custom_base" = prefs.custom_base,
		"custom_species" = prefs.custom_species,
		"h_style" = prefs.h_style,
		"grad_style" = prefs.grad_style,
		"f_style" = prefs.f_style,
		"ear_style" = prefs.ear_style,
		"ear_secondary_style" = prefs.ear_secondary_style,
		"ear_secondary_colors" = islist(prefs.ear_secondary_colors) ? prefs.ear_secondary_colors.Copy() : prefs.ear_secondary_colors,
		"tail_style" = prefs.tail_style,
		"wing_style" = prefs.wing_style,
		"body_markings" = islist(prefs.body_markings) ? prefs.body_markings.Copy() : prefs.body_markings,
		"digitigrade" = prefs.digitigrade
	)
	prefs.species = species_id
	if(icon_base_changed)
		prefs.custom_base = resolved_icon_base
	if(species_id != SPECIES_CUSTOM)
		prefs.custom_species = null
	return restore

/datum/tgui_module/custom_marking_designer/proc/restore_preview_species_override(list/restore)
	if(!prefs || !islist(restore))
		return
	prefs.species = restore["species"]
	prefs.custom_base = restore["custom_base"]
	prefs.custom_species = restore["custom_species"]
	prefs.h_style = restore["h_style"]
	prefs.grad_style = restore["grad_style"]
	prefs.f_style = restore["f_style"]
	prefs.ear_style = restore["ear_style"]
	prefs.ear_secondary_style = restore["ear_secondary_style"]
	var/restored_ear_secondary_colors = restore["ear_secondary_colors"]
	if(islist(restored_ear_secondary_colors))
		var/list/restored_ear_secondary_colors_list = restored_ear_secondary_colors
		prefs.ear_secondary_colors = restored_ear_secondary_colors_list.Copy()
	else
		prefs.ear_secondary_colors = restored_ear_secondary_colors
	prefs.tail_style = restore["tail_style"]
	prefs.wing_style = restore["wing_style"]
	var/restored_body_markings = restore["body_markings"]
	if(islist(restored_body_markings))
		var/list/restored_body_markings_list = restored_body_markings
		prefs.body_markings = restored_body_markings_list.Copy()
	else
		prefs.body_markings = restored_body_markings
	prefs.digitigrade = restore["digitigrade"]

/datum/tgui_module/custom_marking_designer/proc/get_species_preview_mannequin()
	var/key = get_reference_mannequin_key()
	if(!key)
		key = "custom_marking"
	return get_mannequin("[key]-species-preview", /mob/living/carbon/human/dummy/mannequin/custom_marking_visual)

/datum/tgui_module/custom_marking_designer/proc/build_species_body_preview_sources(species_id, mob/user, preview_icon_base = null)
	if(!prefs)
		return null
	if(!istext(species_id) || !length(species_id))
		return null
	var/list/restore = apply_preview_species_override(species_id, user, TRUE, preview_icon_base)
	if(!islist(restore) && species_id != prefs.species)
		return null
	var/mob/living/carbon/human/dummy/mannequin/mannequin = get_species_preview_mannequin()
	if(!mannequin)
		if(islist(restore))
			restore_preview_species_override(restore)
		return null
	var/original_ignore_hide = mannequin.ignore_sprite_accessory_body_hide
	var/original_disable = mannequin.disable_vore_layers
	mannequin.ignore_sprite_accessory_body_hide = TRUE
	mannequin.disable_vore_layers = TRUE
	copy_species_sprite_to_mannequin(mannequin)
	strip_custom_marking_from_mannequin(mannequin)
	mannequin.delete_inventory(TRUE)
	if(islist(mannequin.all_underwear))
		mannequin.all_underwear.Cut()
	if(islist(mannequin.hide_underwear))
		mannequin.hide_underwear.Cut()
	mannequin.update_underwear()
	if(islist(mannequin.organs))
		for(var/obj/item/organ/external/O in mannequin.organs)
			CUSTOM_MARKING_CHECK_TICK
			if(!istype(O))
				continue
			O.update_icon()
	mannequin.force_update_limbs(rebuild_body_icon = FALSE)
	mannequin.update_icons_body()
	mannequin.update_mutations()
	mannequin.update_skin()
	mannequin.update_hair()
	mannequin.update_tail_showing()
	mannequin.update_wing_showing()
	mannequin.ImmediateOverlayUpdate()
	clear_mannequin_preview_overlays(mannequin)
	var/width = get_preview_canvas_width()
	var/height = get_preview_canvas_height()
	var/list/dirs = direction_order || list(NORTH, SOUTH, EAST, WEST)
	var/list/preview_sources = list()
	for(var/dir in dirs)
		CUSTOM_MARKING_CHECK_TICK
		mannequin.set_dir(dir)
		mannequin.ImmediateOverlayUpdate()
		var/list/payload = build_reference_payload_internal(mannequin, dir, width, height, TRUE)
		if(!islist(payload))
			continue
		var/list/entry = list(
			"dir" = dir,
			"label" = direction_label(dir),
			"body_asset" = payload["body_asset"],
			"reference_part_assets" = payload["part_assets"] || list(),
			"reference_part_marking_assets" = payload["part_marking_assets"] || list(),
			"part_order" = payload["part_order"] || list(),
			"hidden_body_parts" = payload["hidden_body_parts"] || list(),
			"body_color_excluded_parts" = payload["body_color_excluded_parts"] || list()
		)
		if(istext(payload["eye_color_mode"]))
			entry["eye_color_mode"] = payload["eye_color_mode"]
		if(isnum(payload["body_alpha"]))
			entry["body_alpha"] = payload["body_alpha"]
		preview_sources += list(entry)
	mannequin.ignore_sprite_accessory_body_hide = original_ignore_hide
	mannequin.disable_vore_layers = original_disable
	mannequin.delete_inventory(TRUE)
	mannequin.ImmediateOverlayUpdate()
	if(islist(restore))
		restore_preview_species_override(restore)
	return preview_sources

/datum/tgui_module/custom_marking_designer/proc/copy_species_sprite_to_mannequin(mob/living/carbon/human/dummy/mannequin/mannequin)
	if(!prefs || !mannequin)
		return
	var/original_hair = prefs.h_style
	var/original_grad = prefs.grad_style
	var/original_facial = prefs.f_style
	var/original_ears = prefs.ear_style
	var/original_horns = prefs.ear_secondary_style
	var/original_tail = prefs.tail_style
	var/original_wing = prefs.wing_style
	var/original_body_markings = prefs.body_markings
	prefs.h_style = null
	prefs.grad_style = null
	prefs.f_style = "Shaved"
	prefs.ear_style = null
	prefs.ear_secondary_style = null
	prefs.tail_style = "hide species-sprite tail"
	prefs.wing_style = null
	prefs.body_markings = null
	copy_preferences_to_mannequin_without_marking(mannequin)
	prefs.h_style = original_hair
	prefs.grad_style = original_grad
	prefs.f_style = original_facial
	prefs.ear_style = original_ears
	prefs.ear_secondary_style = original_horns
	prefs.tail_style = original_tail
	prefs.wing_style = original_wing
	prefs.body_markings = original_body_markings

/datum/tgui_module/custom_marking_designer/proc/build_species_save_body_marking_state()
	var/list/markings = list()
	var/list/order = list()
	if(islist(prefs?.body_markings))
		for(var/marking_id in prefs.body_markings)
			if(!istext(marking_id) || marking_id == "color")
				continue
			var/list/marking_entry = prefs.body_markings[marking_id]
			if(!islist(marking_entry))
				continue
			markings[marking_id] = marking_entry.Copy()
			order += marking_id
	return list(
		"body_markings" = markings,
		"order" = order
	)

/datum/tgui_module/custom_marking_designer/proc/build_species_save_basic_appearance_payload(known_definition_revision = null)
	if(!prefs)
		return null
	var/list/payload = list()
	payload["species_id"] = prefs.species
	payload["custom_base"] = prefs.custom_base
	var/list/base_genders = build_base_biological_gender_options()
	var/list/possible_genders = build_basic_biological_gender_options(base_genders)
	var/biological_gender = resolve_basic_biological_gender(possible_genders, prefs.biological_gender)
	var/datum/species/selected_species = GLOB.all_species?[prefs.species]
	payload["biological_gender"] = biological_gender
	payload["base_biological_genders"] = base_genders
	payload["biological_genders"] = possible_genders
	payload["preview_gender_suffix"] = resolve_species_body_preview_gender_suffix(selected_species, biological_gender)
	var/digitigrade_allowed = is_digitigrade_allowed()
	payload["digitigrade_allowed"] = digitigrade_allowed
	payload["digitigrade"] = digitigrade_allowed ? !!prefs.digitigrade : FALSE
	payload["blood_types"] = valid_bloodtypes.Copy()
	payload["blood_type"] = prefs.b_type
	payload["blood_reagents"] = valid_bloodreagents.Copy()
	payload["blood_reagent"] = prefs.blood_reagents
	payload["blood_color"] = prefs.blood_color
	payload["needs_glasses"] = !!(prefs.disabilities & NEARSIGHTED)
	payload["body_color"] = rgb(prefs.r_skin, prefs.g_skin, prefs.b_skin)
	payload["eye_color"] = rgb(prefs.r_eyes, prefs.g_eyes, prefs.b_eyes)
	payload["hair_style"] = prefs.h_style
	payload["hair_color"] = rgb(prefs.r_hair, prefs.g_hair, prefs.b_hair)
	var/grad_style_value = prefs.grad_style
	if(istext(grad_style_value) && length(grad_style_value))
		var/lower_grad = lowertext(grad_style_value)
		if(lower_grad == "none" || !(grad_style_value in GLOB.hair_gradients))
			grad_style_value = null
	payload["hair_gradient_style"] = grad_style_value
	payload["hair_gradient_color"] = rgb(prefs.r_grad, prefs.g_grad, prefs.b_grad)
	payload["facial_hair_style"] = prefs.f_style
	payload["facial_hair_color"] = rgb(prefs.r_facial, prefs.g_facial, prefs.b_facial)
	payload["ear_style"] = prefs.ear_style
	payload["ear_colors"] = list(
		rgb(prefs.r_ears, prefs.g_ears, prefs.b_ears),
		rgb(prefs.r_ears2, prefs.g_ears2, prefs.b_ears2),
		rgb(prefs.r_ears3, prefs.g_ears3, prefs.b_ears3)
	)
	payload["horn_style"] = prefs.ear_secondary_style
	payload["horn_colors"] = islist(prefs.ear_secondary_colors) ? prefs.ear_secondary_colors.Copy() : list()
	payload["tail_style"] = prefs.tail_style
	payload["tail_colors"] = list(
		rgb(prefs.r_tail, prefs.g_tail, prefs.b_tail),
		rgb(prefs.r_tail2, prefs.g_tail2, prefs.b_tail2),
		rgb(prefs.r_tail3, prefs.g_tail3, prefs.b_tail3)
	)
	payload["wing_style"] = prefs.wing_style
	payload["wing_colors"] = list(
		rgb(prefs.r_wing, prefs.g_wing, prefs.b_wing),
		rgb(prefs.r_wing2, prefs.g_wing2, prefs.b_wing2),
		rgb(prefs.r_wing3, prefs.g_wing3, prefs.b_wing3)
	)
	append_basic_appearance_definitions(payload, known_definition_revision)
	payload["prosthetic_context"] = can_compose_prosthetics_from_static_catalog() ? build_basic_prosthetic_context() : null
	return payload

/datum/tgui_module/custom_marking_designer/proc/build_species_save_preview_source_bundles()
	if(!prefs)
		return null
	var/original_digitigrade = prefs.digitigrade
	var/original_hair = prefs.h_style
	var/original_grad = prefs.grad_style
	var/original_facial = prefs.f_style
	var/original_ears = prefs.ear_style
	var/original_horns = prefs.ear_secondary_style
	var/original_tail = prefs.tail_style
	var/original_wing = prefs.wing_style
	var/original_body_markings = prefs.body_markings
	var/list/prosthetic_restore = can_compose_prosthetics_from_static_catalog() ? apply_neutral_preview_prosthetic_state() : null
	prefs.h_style = null
	prefs.grad_style = null
	prefs.f_style = "Shaved"
	prefs.ear_style = null
	prefs.ear_secondary_style = null
	prefs.tail_style = "hide species-sprite tail"
	prefs.wing_style = null
	prefs.body_markings = null
	var/digitigrade_allowed = is_digitigrade_allowed()
	var/digitigrade_value = digitigrade_allowed ? !!original_digitigrade : FALSE
	var/list/possible_genders = build_basic_biological_gender_options()
	var/biological_gender = resolve_basic_biological_gender(possible_genders, prefs.biological_gender)
	var/list/preview_bundles = build_basic_preview_variant_bundles(digitigrade_value, digitigrade_allowed, biological_gender, possible_genders)
	prefs.digitigrade = original_digitigrade
	prefs.h_style = original_hair
	prefs.grad_style = original_grad
	prefs.f_style = original_facial
	prefs.ear_style = original_ears
	prefs.ear_secondary_style = original_horns
	prefs.tail_style = original_tail
	prefs.wing_style = original_wing
	prefs.body_markings = original_body_markings
	if(islist(prosthetic_restore))
		restore_preview_prosthetic_state(prosthetic_restore)
	return preview_bundles

/datum/tgui_module/custom_marking_designer/proc/build_species_save_result_if_needed(species_updated, close_ui, list/known_payload_state = null)
	if(species_updated && close_ui)
		return null
	return build_species_save_result_payload(known_payload_state, species_updated)

/datum/tgui_module/custom_marking_designer/proc/build_species_save_result_payload(list/known_payload_state = null, accepted = TRUE)
	if(!prefs)
		return null
	species_save_result_revision++
	var/list/body_state = build_species_save_body_marking_state()
	var/list/result = list(
		"revision" = species_save_result_revision,
		"accepted" = !!accepted,
		"species_id" = prefs.species,
		"custom_base" = prefs.custom_base,
		"custom_species" = istext(prefs.custom_species) ? html_decode(prefs.custom_species) : null,
		"body_markings" = body_state["body_markings"],
		"order" = body_state["order"],
		"basic_appearance" = build_species_save_basic_appearance_payload(known_payload_state?["known_basic_definition_revision"])
	)
	var/list/body_definition_payload = list()
	append_body_marking_definition_delta(body_definition_payload, known_payload_state?["known_body_definition_revision"])
	result["body_definition_revision"] = body_definition_payload["definition_revision"]
	result["body_allowed_definition_ids"] = body_definition_payload["allowed_definition_ids"]
	if(islist(body_definition_payload["definition_data"]))
		result["body_definition_data"] = body_definition_payload["definition_data"]
	var/list/preview_bundles = build_species_save_preview_source_bundles()
	var/list/preview_bundle = preview_bundles?["primary"]
	append_preview_bundle_delta(
		result,
		preview_bundle,
		null,
		known_payload_state?["known_body_preview_revision"],
		known_payload_state?["known_body_preview_signature"]
	)
	var/list/preview_bundle_alt = preview_bundles?["alternate"]
	append_preview_bundle_delta(
		result,
		preview_bundle_alt,
		"alt",
		known_payload_state?["known_body_alt_preview_revision"],
		known_payload_state?["known_body_alt_preview_signature"]
	)
	var/list/preview_bundle_gender_alt = preview_bundles?["gender_alternate"]
	append_preview_bundle_delta(
		result,
		preview_bundle_gender_alt,
		"gender_alt",
		known_payload_state?["known_body_gender_alt_preview_revision"],
		known_payload_state?["known_body_gender_alt_preview_signature"]
	)
	var/list/preview_bundle_gender_alt_digitigrade = preview_bundles?["gender_alternate_digitigrade"]
	append_preview_bundle_delta(
		result,
		preview_bundle_gender_alt_digitigrade,
		"gender_alt_digitigrade",
		known_payload_state?["known_body_gender_alt_digitigrade_preview_revision"],
		known_payload_state?["known_body_gender_alt_digitigrade_preview_signature"]
	)
	return result

/datum/tgui_module/custom_marking_designer/proc/apply_species_payload(list/params, mob/user)
	if(!prefs)
		return FALSE
	if(!islist(params))
		return FALSE
	var/target_species = params?["species"]
	if(!istext(target_species) || !length(target_species))
		return FALSE
	var/datum/species/new_species = GLOB.all_species?[target_species]
	if(!istype(new_species))
		return FALSE
	if(!is_species_selectable(user, new_species))
		return FALSE
	var/prev_species = prefs.species
	var/prev_icon_base = prefs.custom_base
	var/custom_species_supplied = ("custom_species" in params)
	var/requested_custom_species = prefs.custom_species
	if(custom_species_supplied)
		var/raw_custom_species = params?["custom_species"]
		if(!isnull(raw_custom_species) && !istext(raw_custom_species))
			return FALSE
		requested_custom_species = sanitize(raw_custom_species, MAX_NAME_LEN)
	if(target_species == SPECIES_CUSTOM && (!istext(requested_custom_species) || !length(requested_custom_species)))
		return FALSE
	var/resolved_icon_base = resolve_species_icon_base(target_species, params?["icon_base"])
	var/icon_base_changed = istext(resolved_icon_base) && length(resolved_icon_base) && resolved_icon_base != prev_icon_base
	var/custom_species_changed = custom_species_supplied && requested_custom_species != prefs.custom_species
	if(prev_species == target_species && !icon_base_changed && !custom_species_changed)
		return TRUE
	prefs.species = target_species
	if(istext(resolved_icon_base) && length(resolved_icon_base))
		prefs.custom_base = resolved_icon_base
	if(prev_species != prefs.species)
		prefs.reconcile_languages_for_species()
		var/resolved_biological_gender = resolve_species_allowed_biological_gender(new_species, prefs.biological_gender)
		if(resolved_biological_gender != prefs.biological_gender)
			prefs.set_biological_gender(resolved_biological_gender)
		prefs.custom_species = null
		var/list/valid_hairstyles = prefs.get_valid_hairstyles()
		if(!(prefs.h_style in valid_hairstyles))
			if(valid_hairstyles.len)
				prefs.h_style = pick(valid_hairstyles)
			else
				prefs.h_style = "Bald"
		var/list/valid_facialhairstyles = prefs.get_valid_facialhairstyles()
		if(!(prefs.f_style in valid_facialhairstyles))
			if(valid_facialhairstyles.len)
				prefs.f_style = pick(valid_facialhairstyles)
			else
				prefs.f_style = "Shaved"
		prefs.sanitize_body_styles()
		if(islist(prefs.organ_data))
			for(var/organ in prefs.organ_data)
				prefs.organ_data[organ] = null
			while(null in prefs.organ_data)
				prefs.organ_data -= null
		if(islist(prefs.rlimb_data))
			for(var/organ in prefs.rlimb_data)
				prefs.rlimb_data[organ] = null
			while(null in prefs.rlimb_data)
				prefs.rlimb_data -= null
		prune_body_markings_for_current_species()
		prefs.real_name = sanitize_name(prefs.real_name, prefs.species)
		if(!prefs.real_name)
			prefs.real_name = random_name(prefs.identifying_gender, prefs.species)
		var/min_age = new_species.min_age
		var/max_age = new_species.max_age
		if(isnum(min_age) && isnum(max_age))
			prefs.age = max(min(prefs.age, max_age), min_age)
		invalidate_reference_payload_caches()
	else if(icon_base_changed)
		prefs.sanitize_body_styles()
		prune_body_markings_for_current_species()
		invalidate_reference_payload_caches()
	if(custom_species_supplied)
		prefs.custom_species = requested_custom_species
	return TRUE

/datum/tgui_module/custom_marking_designer/proc/prune_body_markings_for_current_species()
	if(!prefs || !islist(prefs.body_markings) || !prefs.body_markings.len)
		return
	var/list/filtered_markings = list()
	for(var/marking_id in prefs.body_markings)
		if(!istext(marking_id) || marking_id == "color")
			continue
		var/list/marking_entry = prefs.body_markings[marking_id]
		if(!islist(marking_entry))
			continue
		var/datum/sprite_accessory/marking/style = body_marking_styles_list?[marking_id]
		if(!istype(style))
			continue
		if(!is_body_marking_allowed(style))
			continue
		var/list/sanitized_entry = sanitize_body_marking_entry(marking_id, style, marking_entry)
		if(islist(sanitized_entry))
			filtered_markings[marking_id] = sanitized_entry
	prefs.body_markings = filtered_markings
	prefs.prune_disallowed_body_markings()

// Log and relay client-side warnings
/datum/tgui_module/custom_marking_designer/proc/handle_client_warning(mob/user, list/params)
	if(!islist(params))
		params = list()
	var/message = params?["message"]
	if(!istext(message) || !length(message))
		message = "Unspecified client warning."
	var/safe_message = sanitize_text(message)
	var/list/log_payload = list(
		"message" = message,
		"payload" = params
	)
	if(user)
		to_chat(user, span_warning(safe_message))
	log_tgui(user, "Custom Marking Designer client warning:\n[json_encode(log_payload)]")
	return TRUE

// Build the serialized payload that ends up inside preferences.sav
/datum/tgui_module/custom_marking_designer/proc/build_marking_save_payload()
	if(!mark)
		return null
	var/list/save_data = mark.to_save()
	if(!islist(save_data))
		return null
	var/key = mark.id || "custom_marking"
	if(prefs)
		if(mark.id)
			LAZYINITLIST(prefs.custom_markings)
			if(islist(prefs.custom_markings))
				prefs.custom_markings[mark.id] = mark
		var/list/prefs_payload = prefs.get_custom_markings_payload()
		if(islist(prefs_payload) && prefs_payload.len)
			return prefs_payload
	var/list/fallback = list()
	fallback[key] = save_data
	return fallback

// Present the raw JSON blob that lives in the savefile for this marking
/datum/tgui_module/custom_marking_designer/proc/view_raw_marking_payload(mob/user, params)
	if(!user || !mark)
		return FALSE
	commit_all_sessions()
	var/list/payload = build_marking_save_payload()
	if(!islist(payload) || !payload.len)
		to_chat(user, span_warning("Unable to build a save payload for this marking."))
		return FALSE
	var/json_text = json_encode(payload)
	if(!istext(json_text) || !length(json_text))
		to_chat(user, span_warning("Unable to encode the save payload as JSON."))
		return FALSE
	var/path_hint = prefs?.path
	if(!istext(path_hint) || !length(path_hint))
		path_hint = "data/player_saves/<ckey>/preferences.sav"
	var/style_name = mark?.get_style_name() || "Custom Marking"
	var/list/html_bits = list()
	html_bits += "<html><head><meta charset='utf-8'><title>Custom Marking Payload</title>"
	html_bits += "<style>body{background:#111;color:#ddd;font-family:Consolas,Menlo,monospace;font-size:13px;padding:10px;} h2{margin-top:0;} code{color:#8bf;} textarea{width:100%;height:70vh;background:#000;color:#0f0;border:1px solid #555;resize:vertical;padding:8px;box-sizing:border-box;}</style></head><body>"
	html_bits += "<h2>Raw Save Payload &mdash; [html_encode(style_name)]</h2>"
	html_bits += "<p>This JSON lives inside <code>[html_encode(path_hint)]</code> under the <code>custom_markings</code> entry.</p>"
	html_bits += "<textarea readonly spellcheck='false'>[html_encode(json_text)]</textarea>"
	html_bits += "</body></html>"
	var/html = jointext(html_bits, "")
	user << browse(html, "window=custom_marking_payload;size=720x600")
	return TRUE

// Resolve the current canvas width with sensible defaults
/datum/tgui_module/custom_marking_designer/proc/get_canvas_width()
	var/value = mark ? mark.get_effective_canvas_width() : CUSTOM_MARKING_DEFAULT_WIDTH
	return clamp_custom_marking_dimension(value, CUSTOM_MARKING_DEFAULT_WIDTH, CUSTOM_MARKING_CANVAS_MAX_WIDTH)

// Resolve the current canvas height with sensible defaults
/datum/tgui_module/custom_marking_designer/proc/get_canvas_height()
	var/value = mark ? mark.get_effective_canvas_height() : CUSTOM_MARKING_DEFAULT_HEIGHT
	return clamp_custom_marking_dimension(value, CUSTOM_MARKING_DEFAULT_HEIGHT, CUSTOM_MARKING_CANVAS_MAX_HEIGHT)

// Return the canvas width
/datum/tgui_module/custom_marking_designer/proc/get_preview_canvas_width()
	return CUSTOM_MARKING_CANVAS_MAX_WIDTH

// Return the canvas height
/datum/tgui_module/custom_marking_designer/proc/get_preview_canvas_height()
	return CUSTOM_MARKING_CANVAS_MAX_HEIGHT

// Build a map of composite grids for each part in a direction
/datum/tgui_module/custom_marking_designer/proc/build_custom_grid_map(dir, use_stripped_reference = FALSE)
	var/list/parts = get_preview_part_order(dir, use_stripped_reference)
	return build_custom_grid_map_for_parts(dir, parts)

/datum/tgui_module/custom_marking_designer/proc/build_custom_grid_map_for_parts(dir, list/parts)
	if(!mark)
		return list()
	var/list/result = list()
	if(!islist(parts) || !parts.len)
		parts = list("generic")
	for(var/part in parts)
		var/normalized_part = part
		if(part == "generic")
			normalized_part = null
		var/datum/custom_marking_frame/frame = mark.get_frame(dir, normalized_part, FALSE)
		var/list/composite_grid = null
		if(frame)
			composite_grid = frame.get_composite()
		result[part] = composite_grid
	return result

// Build ordering the client should use for preview layers
/datum/tgui_module/custom_marking_designer/proc/get_preview_part_order(dir_override = null, use_stripped_reference = FALSE)
	var/list/order = list("generic")
	var/list/reference_order = get_reference_part_order(dir_override, use_stripped_reference)
	if(islist(reference_order))
		for(var/ref_part in reference_order)
			if(!istext(ref_part) || !length(ref_part))
				continue
			if(ref_part == "generic")
				continue
			if(!(ref_part in order))
				order += ref_part
	var/list/label_order = islist(GLOB.custom_marking_part_labels) ? GLOB.custom_marking_part_labels : null
	if(islist(label_order))
		for(var/label_key in label_order)
			if(label_key == "generic")
				continue
			if(!(label_key in order))
				order += label_key
	if(islist(mark?.body_parts) && mark.body_parts.len)
		for(var/part in mark.body_parts)
			if(!istext(part) || !length(part))
				continue
			if(part == "generic")
				continue
			if(!(part in order))
				order += part
	return order

// Construct preview source payload for a specific direction
/datum/tgui_module/custom_marking_designer/proc/build_preview_source_for_dir(dir, use_stripped_reference = FALSE)
	var/list/entry = list(
		"dir" = dir,
		"label" = direction_label(dir)
	)
	var/list/payload = get_reference_payload_entry(dir, use_stripped_reference)
	if(islist(payload))
		var/list/part_assets = payload["part_assets"]
		if(islist(part_assets) && part_assets.len)
			entry["reference_part_assets"] = part_assets
		var/list/part_marking_assets = payload["part_marking_assets"]
		if(islist(part_marking_assets) && part_marking_assets.len)
			entry["reference_part_marking_assets"] = part_marking_assets
		var/list/overlay_assets = payload["overlay_assets"]
		if(islist(overlay_assets) && overlay_assets.len)
			entry["overlay_assets"] = overlay_assets
		var/list/body_asset = payload["body_asset"]
		if(islist(body_asset))
			entry["body_asset"] = body_asset
		var/list/equipment_overlay_assets = payload["equipment_overlay_assets"]
		if(islist(equipment_overlay_assets) && equipment_overlay_assets.len)
			entry["equipment_overlay_assets"] = equipment_overlay_assets
		var/list/job_overlay_assets = payload["job_overlay_assets"]
		if(islist(job_overlay_assets) && job_overlay_assets.len)
			entry["job_overlay_assets"] = job_overlay_assets
		var/list/loadout_overlay_assets = payload["loadout_overlay_assets"]
		if(islist(loadout_overlay_assets) && loadout_overlay_assets.len)
			entry["loadout_overlay_assets"] = loadout_overlay_assets
		var/list/hidden_body_parts = payload["hidden_body_parts"]
		if(islist(hidden_body_parts))
			entry["hidden_body_parts"] = hidden_body_parts
		else
			entry["hidden_body_parts"] = list()
		var/list/body_color_excluded_parts = payload["body_color_excluded_parts"]
		if(islist(body_color_excluded_parts))
			entry["body_color_excluded_parts"] = body_color_excluded_parts
		else
			entry["body_color_excluded_parts"] = list()
		if(istext(payload["eye_color_mode"]))
			entry["eye_color_mode"] = payload["eye_color_mode"]
		if(isnum(payload["body_alpha"]))
			entry["body_alpha"] = payload["body_alpha"]
	var/list/custom_parts = build_custom_grid_map(dir, use_stripped_reference)
	if(islist(custom_parts))
		entry["custom_parts"] = custom_parts
	var/list/part_order = get_preview_part_order(dir, use_stripped_reference)
	if(islist(part_order) && part_order.len)
		entry["part_order"] = part_order
	return entry

/datum/tgui_module/custom_marking_designer/proc/reference_payload_entry_has_base(list/payload)
	if(!islist(payload))
		return FALSE
	if(islist(payload["body_asset"]))
		return TRUE
	var/list/part_assets = payload["part_assets"]
	return islist(part_assets) && part_assets.len

/datum/tgui_module/custom_marking_designer/proc/reference_payload_bundle_ready(width, height, use_stripped_reference = FALSE)
	var/list/dirs = direction_order || list(NORTH, SOUTH, EAST, WEST)
	if(width <= 0 || height <= 0)
		return FALSE
	var/list/cache = reference_payload_cache
	if(use_stripped_reference)
		var/cache_signature = get_reference_cache_signature(width, height)
		var/list/cache_map = islist(body_reference_payload_cache) ? body_reference_payload_cache : null
		cache = islist(cache_map) ? cache_map[cache_signature] : null
	if(!islist(cache))
		return FALSE
	for(var/dir in dirs)
		var/key = reference_payload_key(dir, width, height)
		if(!reference_payload_entry_has_base(cache[key]))
			return FALSE
	return TRUE

// Build preview sources for all directions and bump revision on updates
/datum/tgui_module/custom_marking_designer/proc/build_preview_source_bundle(use_stripped_reference = FALSE)
	if(!prefs)
		return null
	var/list/dirs = direction_order || list(NORTH, SOUTH, EAST, WEST)
	var/width = get_preview_canvas_width()
	var/height = get_preview_canvas_height()
	var/updated = ensure_reference_payload_bundle(width, height, use_stripped_reference)
	if(!reference_payload_bundle_ready(width, height, use_stripped_reference))
		var/wait_count = 0
		while((use_stripped_reference ? body_reference_build_in_progress : reference_build_in_progress) && wait_count < 100)
			sleep(world.tick_lag > 0 ? world.tick_lag : 1)
			wait_count++
		updated = ensure_reference_payload_bundle(width, height, use_stripped_reference) || updated
	if(!reference_payload_bundle_ready(width, height, use_stripped_reference))
		return null
	var/list/result = list()
	for(var/dir in dirs)
		var/list/entry = build_preview_source_for_dir(dir, use_stripped_reference)
		if(islist(entry))
			result += list(entry)
	if(updated)
		if(use_stripped_reference)
			body_preview_revision++
		else
			preview_revision++
	var/bundle_revision = use_stripped_reference ? body_preview_revision : preview_revision
	var/bundle_signature = use_stripped_reference ? body_reference_cache_signature : reference_cache_signature
	return build_reference_transport_bundle(result, bundle_revision, bundle_signature)

// Build a stable cache signature that incorporates sprite dimensions
/datum/tgui_module/custom_marking_designer/proc/get_reference_cache_signature(width, height)
	var/signature = "[get_reference_signature()]#[width]x[height]"
	return signature

// Produce the cache key for a direction/dimension pairing
/datum/tgui_module/custom_marking_designer/proc/reference_payload_key(dir, width, height)
	if(!dir)
		dir = NORTH
	return "[dir]-[width]x[height]"

// Derive the mannequin cache key for building reference previews
/datum/tgui_module/custom_marking_designer/proc/get_reference_mannequin_key()
	var/key = prefs?.client_ckey || prefs?.client?.ckey
	if(!key)
		key = "custom_marking"
	return "[key]-markref"

// Fetch (or create) the mannequin used for reference baking
/datum/tgui_module/custom_marking_designer/proc/get_reference_mannequin()
	var/key = get_reference_mannequin_key()
	if(!key)
		return null
	return get_mannequin(key, /mob/living/carbon/human/dummy/mannequin/custom_marking_visual)

// Build a stable signature for current body marking selections/colors
/datum/tgui_module/custom_marking_designer/proc/get_body_marking_cache_signature()
	if(!prefs)
		return null
	var/list/markings = prefs.body_markings
	if(!islist(markings) || !markings.len)
		return null
	var/list/sanitized = list()
	for(var/key in markings)
		if(!istext(key))
			continue
		var/list/entry = markings[key]
		if(!islist(entry))
			continue
		var/datum/sprite_accessory/marking/style = body_marking_styles_list?[key]
		if(!istype(style))
			style = entry["datum"]
		if(istype(style, /datum/sprite_accessory/marking/custom))
			continue
		var/list/out_entry = list()
		var/default_color = entry["color"]
		if(istext(default_color))
			out_entry["color"] = default_color
		var/list/parts = list()
		for(var/part in entry)
			if(part == "color" || part == "datum")
				continue
			if(!istext(part))
				continue
			var/list/details = entry[part]
			if(!islist(details))
				continue
			var/list/detail_signature = list()
			if("on" in details)
				detail_signature["on"] = !!details["on"]
			var/part_color = details["color"]
			if(istext(part_color))
				detail_signature["color"] = part_color
			if(detail_signature.len)
				parts[part] = detail_signature
		if(parts.len)
			out_entry["parts"] = parts
		sanitized[key] = out_entry
	if(!sanitized.len)
		return null
	return md5(json_encode(sanitized))

// Build a hashable payload describing the preview sprite context
/datum/tgui_module/custom_marking_designer/proc/get_reference_signature()
	if(!prefs)
		return ""
	var/list/payload = list(
		"species" = prefs.species,
		"custom_species" = prefs.custom_species,
		"custom_base" = prefs.custom_base,
		"gender" = prefs.biological_gender,
		"digitigrade" = prefs.digitigrade,
		"s_tone" = prefs.s_tone,
		"r_skin" = prefs.r_skin,
		"g_skin" = prefs.g_skin,
		"b_skin" = prefs.b_skin,
		"eye_color" = list(prefs.r_eyes, prefs.g_eyes, prefs.b_eyes),
		"synth_color" = prefs.synth_color,
		"r_synth" = prefs.r_synth,
		"g_synth" = prefs.g_synth,
		"b_synth" = prefs.b_synth,
		"hair_style" = prefs.h_style,
		"hair_color" = list(prefs.r_hair, prefs.g_hair, prefs.b_hair),
		"hair_gradient" = list("style" = prefs.grad_style, "color" = list(prefs.r_grad, prefs.g_grad, prefs.b_grad)),
		"facial_style" = prefs.f_style,
		"facial_color" = list(prefs.r_facial, prefs.g_facial, prefs.b_facial),
		"tail_style" = prefs.tail_style,
		"tail_colors" = list(
			list(prefs.r_tail, prefs.g_tail, prefs.b_tail),
			list(prefs.r_tail2, prefs.g_tail2, prefs.b_tail2),
			list(prefs.r_tail3, prefs.g_tail3, prefs.b_tail3)
		),
		"wing_style" = prefs.wing_style,
		"wing_colors" = list(
			list(prefs.r_wing, prefs.g_wing, prefs.b_wing),
			list(prefs.r_wing2, prefs.g_wing2, prefs.b_wing2),
			list(prefs.r_wing3, prefs.g_wing3, prefs.b_wing3)
		),
		"ear_style" = prefs.ear_style,
		"ear_secondary_style" = prefs.ear_secondary_style,
		"ear_colors" = list(
			list(prefs.r_ears, prefs.g_ears, prefs.b_ears),
			list(prefs.r_ears2, prefs.g_ears2, prefs.b_ears2),
			list(prefs.r_ears3, prefs.g_ears3, prefs.b_ears3)
		),
		"preview_overlay_rev" = 1,
		"job_pref_high" = list(
			"civilian" = prefs.job_civilian_high,
			"medsci" = prefs.job_medsci_high,
			"engsec" = prefs.job_engsec_high
		),
		"equip_preview_mask" = prefs.equip_preview_mob,
		"gear_loadout" = prefs.gear?.Copy(),
		"player_alt_titles" = prefs.player_alt_titles?.Copy(),
		"custom_marking_id" = mark?.id,
		"body_markings" = get_body_marking_cache_signature()
	)
	if(islist(prefs.ear_secondary_colors))
		payload["ear_secondary_colors"] = prefs.ear_secondary_colors.Copy()
	if(islist(prefs.body_descriptors))
		payload["descriptors"] = prefs.body_descriptors.Copy()
	return json_encode(payload)

// Trigger a queued mannequin rebuild after the current one finishes
/datum/tgui_module/custom_marking_designer/proc/process_pending_reference_build()
	if(!islist(reference_pending_request))
		return
	var/list/pending = reference_pending_request
	reference_pending_request = null
	spawn(0)
		ensure_reference_payload_bundle(pending["width"], pending["height"])

// Trigger a queued stripped mannequin rebuild after the current one finishes (Lira, December 2025)
/datum/tgui_module/custom_marking_designer/proc/process_pending_body_reference_build()
	if(!islist(body_reference_pending_request))
		return
	var/list/pending = body_reference_pending_request
	body_reference_pending_request = null
	spawn(0)
		ensure_reference_payload_bundle(pending["width"], pending["height"], TRUE)

// Ensure cached reference payloads exist for each direction at the requested size
/datum/tgui_module/custom_marking_designer/proc/ensure_reference_payload_bundle(width, height, use_stripped_reference = FALSE)
	var/list/yield_context = custom_marking_begin_manual_yield()
	var/target_signature = get_reference_cache_signature(width, height)
	var/build_in_progress = use_stripped_reference ? body_reference_build_in_progress : reference_build_in_progress
	var/list/pending_request = use_stripped_reference ? body_reference_pending_request : reference_pending_request
	if(build_in_progress)
		if(!islist(pending_request) || (pending_request["signature"] != target_signature))
			pending_request = list(
				"width" = width,
				"height" = height,
				"signature" = target_signature
			)
		if(use_stripped_reference)
			body_reference_pending_request = pending_request
		else
			reference_pending_request = pending_request
		custom_marking_end_manual_yield(yield_context)
		return FALSE
	if(use_stripped_reference)
		body_reference_build_in_progress = TRUE
		body_reference_pending_request = null
	else
		reference_build_in_progress = TRUE
		reference_pending_request = null
	var/updated = FALSE
	if(!prefs)
		if(use_stripped_reference)
			body_reference_build_in_progress = FALSE
			custom_marking_end_manual_yield(yield_context)
			process_pending_body_reference_build()
		else
			reference_build_in_progress = FALSE
			custom_marking_end_manual_yield(yield_context)
			process_pending_reference_build()
		return updated
	if(width <= 0 || height <= 0)
		if(use_stripped_reference)
			body_reference_build_in_progress = FALSE
			custom_marking_end_manual_yield(yield_context)
			process_pending_body_reference_build()
		else
			reference_build_in_progress = FALSE
			custom_marking_end_manual_yield(yield_context)
			process_pending_reference_build()
		return updated
	var/list/cache = use_stripped_reference ? body_reference_payload_cache : reference_payload_cache
	var/cache_signature = use_stripped_reference ? body_reference_cache_signature : reference_cache_signature
	var/mannequin_signature = use_stripped_reference ? body_reference_mannequin_signature : reference_mannequin_signature
	var/list/cache_map = null
	var/list/mannequin_signature_map = null
	if(use_stripped_reference)
		cache_map = islist(body_reference_payload_cache) ? body_reference_payload_cache : list()
		cache = islist(cache_map[target_signature]) ? cache_map[target_signature] : null
		cache_signature = target_signature
		mannequin_signature_map = islist(body_reference_mannequin_signature) ? body_reference_mannequin_signature : list()
		if(istext(body_reference_mannequin_signature) && !mannequin_signature_map.len)
			mannequin_signature_map[target_signature] = body_reference_mannequin_signature
		mannequin_signature = mannequin_signature_map[target_signature]
		if(!islist(cache))
			var/legacy_key = reference_payload_key(NORTH, width, height)
			if(islist(cache_map[legacy_key]))
				cache = cache_map
				cache_map = list()
				cache_map[target_signature] = cache
			else
				cache = list()
				cache_map[target_signature] = cache
				updated = TRUE
		body_reference_payload_cache = cache_map
		body_reference_cache_signature = cache_signature
		body_reference_mannequin_signature = mannequin_signature_map
		if(prefs)
			prefs.custom_marking_body_reference_payload_cache = cache_map
			prefs.custom_marking_body_reference_signature = cache_signature
			prefs.custom_marking_body_reference_mannequin_signature = mannequin_signature_map
	else
		if(cache_signature != target_signature || !islist(cache))
			cache_signature = target_signature
			cache = list()
			if(prefs)
				prefs.custom_marking_reference_signature = cache_signature
				prefs.custom_marking_reference_payload_cache = cache
			updated = TRUE
		else if(prefs)
			if(prefs.custom_marking_reference_payload_cache != cache)
				prefs.custom_marking_reference_payload_cache = cache
			if(prefs.custom_marking_reference_signature != cache_signature)
				prefs.custom_marking_reference_signature = cache_signature
	var/list/dirs = direction_order || list(NORTH, SOUTH, EAST, WEST)
	var/list/missing = list()
	for(var/dir in dirs)
		var/key = reference_payload_key(dir, width, height)
		if(!reference_payload_entry_has_base(cache[key]))
			missing += dir
	var/mob/living/carbon/human/dummy/mannequin/mannequin = get_reference_mannequin()
	if(!mannequin)
		if(use_stripped_reference)
			if(!islist(cache_map))
				cache_map = list()
			cache_map[target_signature] = cache
			if(!islist(mannequin_signature_map))
				mannequin_signature_map = list()
			mannequin_signature_map[target_signature] = mannequin_signature
			body_reference_payload_cache = cache_map
			body_reference_cache_signature = cache_signature
			body_reference_mannequin_signature = mannequin_signature_map
			if(prefs)
				prefs.custom_marking_body_reference_payload_cache = cache_map
				prefs.custom_marking_body_reference_signature = cache_signature
				prefs.custom_marking_body_reference_mannequin_signature = mannequin_signature_map
			body_reference_build_in_progress = FALSE
			custom_marking_end_manual_yield(yield_context)
			process_pending_body_reference_build()
		else
			reference_payload_cache = cache
			reference_cache_signature = cache_signature
			reference_mannequin_signature = mannequin_signature
			reference_build_in_progress = FALSE
			custom_marking_end_manual_yield(yield_context)
			process_pending_reference_build()
		return updated
	if(missing.len && !use_stripped_reference)
		broadcast_reference_build_state(TRUE)
	var/original_ignore_hide = mannequin.ignore_sprite_accessory_body_hide
	mannequin.ignore_sprite_accessory_body_hide = TRUE
	if(!missing.len)
		mannequin.ignore_sprite_accessory_body_hide = original_ignore_hide
		if(use_stripped_reference)
			if(!islist(cache_map))
				cache_map = list()
			cache_map[target_signature] = cache
			if(!islist(mannequin_signature_map))
				mannequin_signature_map = list()
			mannequin_signature_map[target_signature] = mannequin_signature
			body_reference_payload_cache = cache_map
			body_reference_cache_signature = cache_signature
			body_reference_mannequin_signature = mannequin_signature_map
			if(prefs)
				prefs.custom_marking_body_reference_payload_cache = cache_map
				prefs.custom_marking_body_reference_signature = cache_signature
				prefs.custom_marking_body_reference_mannequin_signature = mannequin_signature_map
			body_reference_build_in_progress = FALSE
			custom_marking_end_manual_yield(yield_context)
			process_pending_body_reference_build()
		else
			reference_payload_cache = cache
			reference_cache_signature = cache_signature
			reference_mannequin_signature = mannequin_signature
			reference_build_in_progress = FALSE
			custom_marking_end_manual_yield(yield_context)
			process_pending_reference_build()
		return updated
	var/static/list/gear_overlay_layers = list(
		9,  // SHOES_LAYER_ALT
		10, // UNIFORM_LAYER
		11, // ID_LAYER
		12, // SHOES_LAYER
		13, // GLOVES_LAYER
		14, // BELT_LAYER
		15, // SUIT_LAYER
		17, // GLASSES_LAYER
		18, // BELT_LAYER_ALT
		19, // SUIT_STORE_LAYER
		20, // BACK_LAYER
		23, // EARS_LAYER
		25, // FACEMASK_LAYER
		26, // GLASSES_LAYER_ALT
		27  // HEAD_LAYER
	)
	var/original_disable = mannequin.disable_vore_layers
	mannequin.disable_vore_layers = TRUE
	if(mannequin_signature != target_signature)
		copy_preferences_to_mannequin_without_marking(mannequin)
		mannequin_signature = target_signature
		if(use_stripped_reference)
			if(!islist(mannequin_signature_map))
				mannequin_signature_map = list()
			mannequin_signature_map[target_signature] = mannequin_signature
			body_reference_mannequin_signature = mannequin_signature_map
			if(prefs)
				prefs.custom_marking_body_reference_mannequin_signature = mannequin_signature_map
		else if(prefs)
			prefs.custom_marking_reference_mannequin_signature = mannequin_signature
	strip_custom_marking_from_mannequin(mannequin)
	reset_mannequin_equipment(mannequin, gear_overlay_layers)
	if(islist(mannequin.all_underwear))
		mannequin.all_underwear.Cut()
	if(islist(mannequin.hide_underwear))
		mannequin.hide_underwear.Cut()
	mannequin.update_underwear()
	if(islist(mannequin.organs))
		for(var/obj/item/organ/external/O in mannequin.organs)
			if(!istype(O))
				continue
			O.update_icon()
	mannequin.force_update_limbs(FALSE)
	mannequin.update_icons_body()
	mannequin.update_mutations()
	mannequin.update_skin()
	mannequin.update_hair()
	mannequin.update_tail_showing()
	mannequin.update_wing_showing()
	mannequin.ImmediateOverlayUpdate()
	clear_mannequin_preview_overlays(mannequin)
	var/list/payloads_by_dir = list()
	for(var/dir in dirs)
		if(!(dir in missing))
			continue
		CUSTOM_MARKING_CHECK_TICK
		mannequin.set_dir(dir)
		mannequin.ImmediateOverlayUpdate()
		var/list/payload = build_reference_payload_internal(mannequin, dir, width, height, FALSE, "[target_signature]|dir:[dir]")
		if(islist(payload))
			payloads_by_dir["[dir]"] = payload
			if(!islist(cache))
				cache = list()
			var/key = reference_payload_key(dir, width, height)
			if(key)
				cache[key] = payload
			updated = TRUE
	if(payloads_by_dir.len && prefs)
		var/list/gear_recipes = build_static_gear_preview_recipes()
		var/list/equipment_gear_by_dir = gear_recipes?["equipment"]
		var/list/job_gear_by_dir = gear_recipes?["job"]
		var/list/loadout_gear_by_dir = gear_recipes?["loadout"]
		for(var/dir_key in payloads_by_dir)
			CUSTOM_MARKING_CHECK_TICK
			var/list/payload = payloads_by_dir[dir_key]
			var/list/equipment_overlay_assets = equipment_gear_by_dir?[dir_key]
			if(islist(equipment_overlay_assets) && equipment_overlay_assets.len)
				payload["equipment_overlay_assets"] = equipment_overlay_assets
			var/list/job_overlay_assets = job_gear_by_dir?[dir_key]
			if(islist(job_overlay_assets) && job_overlay_assets.len)
				payload["job_overlay_assets"] = job_overlay_assets
			var/list/loadout_overlay_assets = loadout_gear_by_dir?[dir_key]
			if(islist(loadout_overlay_assets) && loadout_overlay_assets.len)
				payload["loadout_overlay_assets"] = loadout_overlay_assets
	finalize_pending_reference_asset_atlases(target_signature)
	mannequin.disable_vore_layers = original_disable
	mannequin.ignore_sprite_accessory_body_hide = original_ignore_hide
	reset_mannequin_equipment(mannequin, gear_overlay_layers)
	mannequin.ImmediateOverlayUpdate()
	custom_marking_end_manual_yield(yield_context)
	if(use_stripped_reference)
		if(!islist(cache_map))
			cache_map = list()
		cache_map[target_signature] = cache
		if(!islist(mannequin_signature_map))
			mannequin_signature_map = list()
		mannequin_signature_map[target_signature] = mannequin_signature
		body_reference_payload_cache = cache_map
		body_reference_cache_signature = cache_signature
		body_reference_mannequin_signature = mannequin_signature_map
		if(prefs)
			prefs.custom_marking_body_reference_payload_cache = cache_map
			prefs.custom_marking_body_reference_signature = cache_signature
			prefs.custom_marking_body_reference_mannequin_signature = mannequin_signature_map
		body_reference_build_in_progress = FALSE
		process_pending_body_reference_build()
	else
		reference_payload_cache = cache
		reference_cache_signature = cache_signature
		reference_mannequin_signature = mannequin_signature
		reference_build_in_progress = FALSE
		broadcast_reference_build_state(FALSE)
		process_pending_reference_build()
	return updated

// Copy preferences to the mannequin while excluding the current custom marking
/datum/tgui_module/custom_marking_designer/proc/copy_preferences_to_mannequin_without_marking(mob/living/carbon/human/dummy/mannequin/mannequin)
	if(!prefs || !mannequin)
		return
	var/list/original_body_markings = prefs.body_markings
	var/list/temp_body_markings = prune_custom_body_markings(original_body_markings)
	if(temp_body_markings)
		prefs.body_markings = temp_body_markings
	prefs.copy_to(mannequin, FALSE, FALSE)
	if(temp_body_markings)
		prefs.body_markings = original_body_markings
	ensure_default_tail_style(mannequin)

// Remove the edited custom marking from a mannequin before baking previews (Lira, December 2025)
/datum/tgui_module/custom_marking_designer/proc/strip_custom_marking_from_mannequin(mob/living/carbon/human/dummy/mannequin/mannequin)
	if(!mannequin || !mark)
		return FALSE
	var/style_name = mark.get_style_name()
	var/removed = FALSE
	if(islist(mannequin.organs))
		for(var/obj/item/organ/external/O in mannequin.organs)
			if(!istype(O))
				continue
			if(!islist(O.markings) || !O.markings.len)
				continue
			var/list/mark_keys = O.markings.Copy()
			for(var/key in mark_keys)
				var/remove_entry = FALSE
				if(istext(style_name) && length(style_name) && key == style_name)
					remove_entry = TRUE
				else
					var/list/mark_data = O.markings[key]
					var/datum/sprite_accessory/marking/mark_style = mark_data?["datum"]
					if(istype(mark_style, /datum/sprite_accessory/marking/custom))
						remove_entry = TRUE
					else if(!mark_style && findtext(key, " (Custom "))
						remove_entry = TRUE
				if(remove_entry)
					O.markings -= key
					removed = TRUE
	if(removed && isnum(mannequin.markings_len) && mannequin.markings_len > 0)
		mannequin.markings_len = max(mannequin.markings_len - 1, 0)
	return removed

// Return a copy of body_markings without custom entries (Lira, December 2025)
/datum/tgui_module/custom_marking_designer/proc/prune_custom_body_markings(list/original)
	if(!islist(original) || !original.len)
		return null
	var/style_name = mark?.get_style_name()
	var/list/pruned = original.Copy()
	var/list/remove_keys = list()
	for(var/key in pruned)
		if(!istext(key) || key == "color")
			continue
		var/datum/sprite_accessory/marking/entry_style = body_marking_styles_list?[key]
		if(!istype(entry_style))
			entry_style = pruned[key]?["datum"]
		var/is_custom = istype(entry_style, /datum/sprite_accessory/marking/custom)
		if(!is_custom && istext(style_name) && key == style_name)
			is_custom = TRUE
		if(!is_custom && findtext(key, " (Custom "))
			is_custom = TRUE
		if(is_custom)
			remove_keys += key
	if(!remove_keys.len)
		return null
	for(var/key in remove_keys)
		pruned -= key
	return pruned

// Temporarily apply mannequin tail defaults to prefs while dressing gear previews (Lira, December 2025)
/datum/tgui_module/custom_marking_designer/proc/apply_preview_tail_override(mob/living/carbon/human/dummy/mannequin/mannequin)
	if(!prefs || !mannequin)
		return null
	if(istext(prefs.tail_style) && length(prefs.tail_style))
		return null
	var/datum/sprite_accessory/tail/style = mannequin.tail_style
	if(!istype(style))
		return null
	var/style_name = style.name
	if(!istext(style_name) || !length(style_name))
		return null
	var/list/override = list(
		"tail_style" = prefs.tail_style,
		"r_tail" = prefs.r_tail,
		"g_tail" = prefs.g_tail,
		"b_tail" = prefs.b_tail,
		"r_tail2" = prefs.r_tail2,
		"g_tail2" = prefs.g_tail2,
		"b_tail2" = prefs.b_tail2,
		"r_tail3" = prefs.r_tail3,
		"g_tail3" = prefs.g_tail3,
		"b_tail3" = prefs.b_tail3
	)
	prefs.tail_style = style_name
	prefs.r_tail = mannequin.r_tail
	prefs.g_tail = mannequin.g_tail
	prefs.b_tail = mannequin.b_tail
	prefs.r_tail2 = mannequin.r_tail2
	prefs.g_tail2 = mannequin.g_tail2
	prefs.b_tail2 = mannequin.b_tail2
	prefs.r_tail3 = mannequin.r_tail3
	prefs.g_tail3 = mannequin.g_tail3
	prefs.b_tail3 = mannequin.b_tail3
	return override

// Restore prefs tail fields after a temporary override (Lira, December 2025)
/datum/tgui_module/custom_marking_designer/proc/restore_preview_tail_override(list/override)
	if(!prefs || !islist(override))
		return
	prefs.tail_style = override["tail_style"]
	prefs.r_tail = override["r_tail"]
	prefs.g_tail = override["g_tail"]
	prefs.b_tail = override["b_tail"]
	prefs.r_tail2 = override["r_tail2"]
	prefs.g_tail2 = override["g_tail2"]
	prefs.b_tail2 = override["b_tail2"]
	prefs.r_tail3 = override["r_tail3"]
	prefs.g_tail3 = override["g_tail3"]
	prefs.b_tail3 = override["b_tail3"]

// Dictionary of tail styles to use with interface
/datum/tgui_module/custom_marking_designer/proc/ensure_default_tail_style(mob/living/carbon/human/dummy/mannequin/mannequin)
	if(!mannequin || mannequin.tail_style)
		return
	var/datum/species/species = mannequin.species
	if(!species)
		return
	var/static/list/species_tail_style_map = list(
		/datum/species/sergal = /datum/sprite_accessory/tail/sergaltaildc,
		/datum/species/akula = /datum/sprite_accessory/tail/special/akula,
		/datum/species/nevrean = /datum/sprite_accessory/tail/special/nevrean,
		/datum/species/hi_zoxxen = /datum/sprite_accessory/tail/special/foxdefault,
		/datum/species/fl_zorren = /datum/sprite_accessory/tail/fennec_tail,
		/datum/species/crew_shadekin = /datum/sprite_accessory/tail/shadekin_short,
		/datum/species/shadekin = /datum/sprite_accessory/tail/shadekin_short,
		/datum/species/xenohybrid = /datum/sprite_accessory/tail/xenohybrid_preview,
		/datum/species/xenochimera = /datum/sprite_accessory/tail/xenochimera_preview,
		/datum/species/harpy = /datum/sprite_accessory/tail/fantail,
		/datum/species/spider = /datum/sprite_accessory/tail/special/vasilissan_spiderlegs,
		/datum/species/vox = /datum/sprite_accessory/tail/special/vox
	)
	var/mapping_entry = species_tail_style_map[species.type]
	if(species.type == /datum/species/xenochimera)
		var/base_species_name = species.base_species
		if(istext(base_species_name) && base_species_name && base_species_name != SPECIES_XENOCHIMERA)
			mapping_entry = null
	if(!mapping_entry && istext(species.base_species))
		var/datum/species/base_species = GLOB.all_species?[species.base_species]
		if(istype(base_species))
			mapping_entry = species_tail_style_map[base_species.type]
	if(mapping_entry)
		var/datum/sprite_accessory/tail/default_style = tail_styles_list[mapping_entry]
		if(set_mannequin_tail_style(mannequin, default_style))
			return
	var/tail_state = species.tail
	if(!istext(tail_state) || !length(tail_state))
		return
	var/target_state = "[tail_state]_s"
	for(var/style_path in tail_styles_list)
		var/datum/sprite_accessory/tail/style = tail_styles_list[style_path]
		if(!istype(style))
			continue
		if(style.icon_state != target_state)
			continue
		if(set_mannequin_tail_style(mannequin, style))
			break

// Apply a tail style with default colors for previews
/datum/tgui_module/custom_marking_designer/proc/set_mannequin_tail_style(mob/living/carbon/human/dummy/mannequin/mannequin, datum/sprite_accessory/tail/style)
	if(!mannequin || !istype(style))
		return FALSE
	mannequin.tail_style = style
	mannequin.r_tail = mannequin.r_skin
	mannequin.g_tail = mannequin.g_skin
	mannequin.b_tail = mannequin.b_skin
	mannequin.r_tail2 = mannequin.r_skin
	mannequin.g_tail2 = mannequin.g_skin
	mannequin.b_tail2 = mannequin.b_skin
	mannequin.r_tail3 = mannequin.r_skin
	mannequin.g_tail3 = mannequin.g_skin
	mannequin.b_tail3 = mannequin.b_skin
	return TRUE

/datum/tgui_module/custom_marking_designer/proc/resolve_reference_body_alpha(mob/living/carbon/human/dummy/mannequin/mannequin)
	if(!mannequin || !islist(mannequin.organs) || !mannequin.organs.len)
		return null
	var/has_visible_limb = FALSE
	for(var/obj/item/organ/external/O in mannequin.organs)
		if(!istype(O) || O.is_stump() || O.is_hidden_by_sprite_accessory())
			continue
		has_visible_limb = TRUE
		if(!O.transparent)
			return null
	return has_visible_limb ? 180 : null

// Construct the payload for a single direction using a prepared mannequin
/datum/tgui_module/custom_marking_designer/proc/build_reference_payload_internal(mob/living/carbon/human/dummy/mannequin/mannequin, dir, width, height, skip_part_visibility_checks = FALSE, asset_signature_prefix = null)
	if(!mannequin)
		return null
	var/body_alpha = resolve_reference_body_alpha(mannequin)
	var/icon/body_icon = icon(mannequin.icon, null, dir, 1, 0)
	var/body_asset_signature = istext(asset_signature_prefix) && length(asset_signature_prefix) ? "[asset_signature_prefix]|body" : null
	var/list/body_asset = build_reference_icon_asset(body_icon, body_asset_signature)
	var/list/hidden_body_parts = list()
	if(islist(mannequin.organs))
		var/original_ignore_hide = mannequin.ignore_sprite_accessory_body_hide
		mannequin.ignore_sprite_accessory_body_hide = FALSE
		for(var/obj/item/organ/external/O in mannequin.organs)
			CUSTOM_MARKING_CHECK_TICK
			if(!istype(O))
				continue
			if(!(O.is_hidden_by_markings() || O.is_hidden_by_sprite_accessory()))
				continue
			var/hidden_normalized = null
			if(istext(O.organ_tag) && length(O.organ_tag))
				hidden_normalized = lowertext(O.organ_tag)
			else if(isnum(O.organ_tag))
				hidden_normalized = "[O.organ_tag]"
			if(istext(hidden_normalized) && length(hidden_normalized) && !(hidden_normalized in hidden_body_parts))
				hidden_body_parts += hidden_normalized
		mannequin.ignore_sprite_accessory_body_hide = original_ignore_hide
	var/list/overlay_assets = list()
	var/overlay_asset_index = 0
	if(islist(mannequin.overlays_standing))
		for(var/i = 1 to mannequin.overlays_standing.len)
			CUSTOM_MARKING_CHECK_TICK
			if(!should_include_preview_overlay_layer(i))
				continue
			var/entry = mannequin.overlays_standing[i]
			if(!entry)
				continue
			var/list/overlay_icons = list()
			collect_reference_overlays(overlay_icons, entry, dir)
			for(var/icon/overlay_icon as anything in overlay_icons)
				CUSTOM_MARKING_CHECK_TICK
				if(!istype(overlay_icon, /icon))
					continue
				var/overlay_slot = get_preview_character_overlay_slot(i)
				var/is_large_overlay = (overlay_icon.Width() > CUSTOM_MARKING_DEFAULT_WIDTH) || (overlay_icon.Height() > CUSTOM_MARKING_DEFAULT_HEIGHT)
				if(is_large_overlay && (width > CUSTOM_MARKING_DEFAULT_WIDTH || height > CUSTOM_MARKING_DEFAULT_HEIGHT))
					var/shift_delta = 8
					if(overlay_slot == "wing_lower" || overlay_slot == "wing_upper")
						var/list/icon_shift = get_icon_shift(overlay_icon)
						var/raw_shift_x = icon_shift?["x"]
						if(isnum(raw_shift_x) && raw_shift_x < 0)
							shift_delta = max(shift_delta, round(abs(raw_shift_x) / 2))
					offset_icon_shift(overlay_icon, shift_delta, 0)
				overlay_asset_index++
				var/overlay_asset_signature = istext(asset_signature_prefix) && length(asset_signature_prefix) ? "[asset_signature_prefix]|character-overlay|layer:[i]|slot:[overlay_slot || "none"]|frame:[overlay_asset_index]" : null
				var/list/overlay_asset = build_reference_icon_asset(overlay_icon, overlay_asset_signature)
				if(islist(overlay_asset))
					var/list/overlay_entry = list(
						"asset" = overlay_asset,
						"layer" = i
					)
					if(overlay_slot)
						overlay_entry["slot"] = overlay_slot
					overlay_assets += list(overlay_entry)
	var/list/part_icons = list()
	var/list/part_marking_icons = list()
	var/list/part_underlay_order = list()
	var/list/part_overlay_order = list()
	var/list/body_color_excluded_parts = list()
	var/eye_color_mode = "none"
	var/normalized
	var/icon/directional_icon
	if(islist(mannequin.organs))
		for(var/obj/item/organ/external/O in mannequin.organs)
			CUSTOM_MARKING_CHECK_TICK
			if(!istype(O))
				continue
			normalized = null
			directional_icon = null
			if(istext(O.organ_tag) && length(O.organ_tag))
				normalized = lowertext(O.organ_tag)
			else if(isnum(O.organ_tag))
				normalized = "[O.organ_tag]"
			if(isnull(normalized))
				continue
			var/check_digi = istype(O, /obj/item/organ/external/leg) || istype(O, /obj/item/organ/external/foot)
			var/digitigrade = FALSE
			if(check_digi)
				if(O.owner)
					digitigrade = O.owner.digitigrade
				else if(O.dna)
					digitigrade = O.dna.digitigrade
			if(O.robotic >= ORGAN_ROBOT)
				var/datum/robolimb/franchise = null
				if(istext(O.model) && length(O.model))
					franchise = all_robolimbs?[O.model]
				if(!(franchise && (franchise.skin_tone || franchise.skin_color)))
					if(!(normalized in body_color_excluded_parts))
						body_color_excluded_parts += normalized
			directional_icon = get_directional_part_icon(O, dir, check_digi ? digitigrade : FALSE, TRUE, skip_part_visibility_checks, isnull(body_alpha))
			if(!isicon(directional_icon))
				continue
			if(O.pixel_x || O.pixel_y)
				directional_icon = shift_icon_for_reference(directional_icon, O.pixel_x, O.pixel_y)
			if(!directional_icon)
				continue
			var/icon/marking_overlay = null
			if(islist(O.markings))
				for(var/M in O.markings)
					var/list/mark_data = O.markings[M]
					if(!islist(mark_data) || !mark_data["on"])
						continue
					var/datum/sprite_accessory/marking/mark_style = mark_data["datum"]
					if(!istype(mark_style))
						mark_style = body_marking_styles_list?[M]
					if(!istype(mark_style))
						continue
					if(mark_style.render_above_body)
						continue
					if(check_digi)
						var/acceptance = mark_style.digitigrade_acceptance
						if(!(acceptance & (digitigrade ? MARKING_DIGITIGRADE_ONLY : MARKING_NONDIGI_ONLY)))
							continue
					var/mark_color = mark_data["color"]
					var/icon/mark_icon = get_cached_marking_icon(mark_style, O.organ_tag, mark_color, check_digi ? digitigrade : FALSE)
					if(!isicon(mark_icon))
						continue
					var/icon/mark_directional = icon(mark_icon, null, dir, 1, 0)
					if(!isicon(mark_directional))
						continue
					if(O.pixel_x || O.pixel_y)
						mark_directional = shift_icon_for_reference(mark_directional, O.pixel_x, O.pixel_y)
					if(!mark_directional)
						continue
					if(!marking_overlay)
						marking_overlay = new/icon(mark_directional)
					else
						marking_overlay.Blend(mark_directional, ICON_OVERLAY)
			var/icon/head_eye_overlay = build_reference_head_eye_overlay(O, dir)
			if(head_eye_overlay)
				eye_color_mode = (mannequin.species?.appearance_flags & HAS_EYE_COLOR) ? "baked" : "native"
				var/icon/body_with_eyes = new/icon(directional_icon)
				body_with_eyes.Blend(head_eye_overlay, ICON_OVERLAY)
				directional_icon = body_with_eyes
			part_icons[normalized] = directional_icon
			if(marking_overlay)
				part_marking_icons[normalized] = marking_overlay
			if(!(normalized in part_underlay_order) && !(normalized in part_overlay_order))
				if(normalized == BP_TORSO)
					part_overlay_order.Insert(1, normalized)
				else if(preview_part_is_runtime_underlay(O.icon_position, dir))
					part_underlay_order.Insert(1, normalized)
				else
					part_overlay_order += normalized
	var/list/part_order = part_underlay_order
	part_order += part_overlay_order
	var/list/part_assets = list()
	var/list/part_marking_assets = list()
	if(islist(part_icons))
		for(var/part in part_icons)
			CUSTOM_MARKING_CHECK_TICK
			var/icon/part_icon = part_icons[part]
			if(!isicon(part_icon))
				continue
			var/part_asset_signature = istext(asset_signature_prefix) && length(asset_signature_prefix) ? "[asset_signature_prefix]|organ-part:[part]" : null
			var/list/part_asset = build_reference_icon_asset(part_icon, part_asset_signature)
			if(islist(part_asset))
				part_assets[part] = part_asset
	if(islist(part_marking_icons))
		for(var/part in part_marking_icons)
			CUSTOM_MARKING_CHECK_TICK
			var/icon/mark_icon = part_marking_icons[part]
			if(!isicon(mark_icon))
				continue
			var/mark_asset_signature = istext(asset_signature_prefix) && length(asset_signature_prefix) ? "[asset_signature_prefix]|part-marking:[part]" : null
			var/list/mark_asset = build_reference_icon_asset(mark_icon, mark_asset_signature)
			if(islist(mark_asset))
				part_marking_assets[part] = mark_asset
	var/list/result = list(
		"body_asset" = body_asset,
		"overlay_assets" = overlay_assets,
		"part_assets" = part_assets,
		"part_marking_assets" = part_marking_assets,
		"part_order" = part_order,
		"hidden_body_parts" = hidden_body_parts,
		"body_color_excluded_parts" = body_color_excluded_parts,
		"eye_color_mode" = eye_color_mode
	)
	if(!isnull(body_alpha))
		result["body_alpha"] = body_alpha
	return result

// Build overlay assets restricted to a whitelist of layers (Lira, December 2025)
/datum/tgui_module/custom_marking_designer/proc/get_preview_overlay_slot(layer_index)
	if(!isnum(layer_index))
		return null
	switch(layer_index)
		if(6)
			return "underwear"
		if(9, 12) // SHOES_LAYER_ALT, SHOES_LAYER
			return "shoes"
		if(10) // UNIFORM_LAYER
			return "uniform"
		if(11) // ID_LAYER
			return "id"
		if(13) // GLOVES_LAYER
			return "gloves"
		if(14, 18) // BELT_LAYER, BELT_LAYER_ALT
			return "belt"
		if(15) // SUIT_LAYER
			return "suit"
		if(17, 26) // GLASSES_LAYER, GLASSES_LAYER_ALT
			return "glasses"
		if(19) // SUIT_STORE_LAYER
			return "suit_store"
		if(20) // BACK_LAYER
			return "back"
		if(23)
			return "ears"
		if(25) // FACEMASK_LAYER
			return "mask"
		if(27) // HEAD_LAYER
			return "head"
	return null

// Compose eye overlays for head references
/datum/tgui_module/custom_marking_designer/proc/build_reference_head_eye_overlay(obj/item/organ/external/O, dir)
	if(!istype(O, /obj/item/organ/external/head))
		return null
	var/obj/item/organ/external/head/head = O
	if(!istype(head))
		return null
	var/mob/living/carbon/human/human = head.owner
	if(!istype(human))
		return null
	var/datum/species/species = human.species
	if(!species)
		return null
	var/should_have_eyes = human.should_have_organ(O_EYES)
	var/has_eye_color = !!(species.appearance_flags & HAS_EYE_COLOR)
	if(!(head.eye_icon && head.eye_icon_location))
		return null
	if(!(should_have_eyes || has_eye_color))
		return null
	var/icon/eyes_icon = new/icon(head.eye_icon_location, head.eye_icon)
	var/obj/item/organ/internal/eyes/eyes = human.internal_organs_by_name[O_EYES]
	if(should_have_eyes)
		if(eyes)
			if(has_eye_color && islist(eyes.eye_colour) && eyes.eye_colour.len >= 3)
				eyes_icon.Blend(rgb(eyes.eye_colour[1], eyes.eye_colour[2], eyes.eye_colour[3]), ICON_ADD)
		else if(has_eye_color)
			eyes_icon.Blend(rgb(human.r_eyes, human.g_eyes, human.b_eyes), ICON_ADD)
	else
		eyes_icon.Blend(rgb(human.r_eyes, human.g_eyes, human.b_eyes), ICON_ADD)
	var/icon/directional = icon(eyes_icon, null, dir, 1, 0)
	if(head.pixel_x || head.pixel_y)
		directional = shift_icon_for_reference(directional, head.pixel_x, head.pixel_y)
	var/visibility_key = "[head.eye_icon_location]|[head.eye_icon]|[dir]|[head.pixel_x],[head.pixel_y]|reference-eyes"
	if(!isicon(directional) || !icon_has_visible_pixels(directional, visibility_key))
		return null
	return directional

// Convert an icon into a 2D color grid for painting overlays
/datum/tgui_module/custom_marking_designer/proc/get_reference_payload_entry(dir_override = null, use_stripped_reference = FALSE)
	if(!prefs)
		return null
	var/width = get_preview_canvas_width()
	var/height = get_preview_canvas_height()
	if(width <= 0 || height <= 0)
		return null
	var/dir = dir_override
	if(isnull(dir))
		dir = active_dir || NORTH
	ensure_reference_payload_bundle(width, height, use_stripped_reference)
	var/list/cache = reference_payload_cache
	if(use_stripped_reference)
		var/cache_signature = get_reference_cache_signature(width, height)
		var/list/cache_map = islist(body_reference_payload_cache) ? body_reference_payload_cache : null
		cache = islist(cache_map) ? cache_map[cache_signature] : null
	return cache?[reference_payload_key(dir, width, height)]

// Return part order from cached reference payload
/datum/tgui_module/custom_marking_designer/proc/get_reference_part_order(dir_override = null, use_stripped_reference = FALSE)
	var/list/payload = get_reference_payload_entry(dir_override, use_stripped_reference)
	if(!islist(payload))
		return null
	var/list/order = payload["part_order"]
	if(islist(order) && order.len)
		return order
	return null

// Recursively gather icons/images that contribute to the reference sprite
/datum/tgui_module/custom_marking_designer/proc/collect_reference_overlays(list/accum, datum/entry, dir, use_flatten = FALSE)
	if(!entry)
		return
	if(islist(entry))
		for(var/element in entry)
			collect_reference_overlays(accum, element, dir, use_flatten)
		return
	if(isicon(entry))
		var/icon/icon_copy = icon(entry, null, dir, 1, 0)
		accum += new/icon(icon_copy)
		return
	if(istype(entry, /image) || istype(entry, /mutable_appearance))
		var/icon/overlay_icon = reference_icon_from_image(entry, dir, use_flatten)
		if(!overlay_icon)
			return
		var/shift_x = 0
		var/shift_y = 0
		if(isdatum(entry))
			shift_x = entry:pixel_x
			shift_y = entry:pixel_y
		overlay_icon = shift_icon_for_reference(overlay_icon, shift_x, shift_y)
		accum += overlay_icon
		return

// Build directional icon for an organ, respecting gendered/digi rules
/datum/tgui_module/custom_marking_designer/proc/get_directional_part_icon(obj/item/organ/external/O, dir, digitigrade = FALSE, include_hidden = FALSE, skip_visibility_check = FALSE, can_apply_transparency = TRUE)
	if(!istype(O))
		return null
	var/normalize_digitigrade = digitigrade && (istype(O, /obj/item/organ/external/leg) || istype(O, /obj/item/organ/external/foot))
	var/original_gendered = O.gendered_icon
	var/force_ungendered = FALSE
	if(original_gendered && !organ_has_gendered_icon_state(O, digitigrade))
		O.gendered_icon = FALSE
		force_ungendered = TRUE
	var/icon/source_icon = O.get_icon(null, can_apply_transparency)
	if(force_ungendered)
		O.gendered_icon = original_gendered
	if(!isicon(source_icon))
		return null
	var/icon/directional = icon(source_icon, null, dir, 1, 0)
	if(skip_visibility_check)
		return normalize_digitigrade_preview_part_icon(directional, normalize_digitigrade)
	if(!icon_has_visible_pixels(directional))
		if(include_hidden)
			directional = get_unhidden_part_icon(O, dir, digitigrade)
		if(!icon_has_visible_pixels(directional))
			return null
	return normalize_digitigrade_preview_part_icon(directional, normalize_digitigrade)

// Get part icon (Lira, December 2025)
/datum/tgui_module/custom_marking_designer/proc/get_unhidden_part_icon(obj/item/organ/external/O, dir, digitigrade = FALSE)
	if(!istype(O))
		return null
	var/mob/living/carbon/human/human = O.owner
	var/datum/species/species = human?.species
	if(!species)
		return null
	var/icon/icon_reference = resolve_organ_icon_resource(O, species, human, digitigrade)
	if(!icon_reference)
		return null
	var/state_name = O.icon_name
	if(!istext(state_name) || !length(state_name))
		return null
	if(O.gendered_icon && organ_has_gendered_icon_state(O, digitigrade))
		var/gender_suffix = get_organ_gender_suffix(O, human)
		if(istext(gender_suffix) && length(gender_suffix))
			state_name = "[state_name]_[gender_suffix]"
	var/icon/base_icon = icon(icon_reference, state_name, dir, 1, 0)
	if(!isicon(base_icon))
		return null
	O.apply_colouration(base_icon)
	return base_icon

// Check if a gendered icon state exists for an organ
/datum/tgui_module/custom_marking_designer/proc/organ_has_gendered_icon_state(obj/item/organ/external/O, digitigrade)
	if(!istype(O) || !O.gendered_icon)
		return TRUE
	var/mob/living/carbon/human/human = O.owner
	var/datum/species/species = human?.species
	if(!species)
		return TRUE
	var/gender_suffix = get_organ_gender_suffix(O, human)
	var/state_name = "[O.icon_name]_[gender_suffix]"
	if(!length(state_name))
		return TRUE
	var/icon/icon_reference = resolve_organ_icon_resource(O, species, human, digitigrade)
	if(!icon_reference)
		return TRUE
	var/list/state_list = cached_icon_states(icon_reference)
	if(!islist(state_list) || !state_list.len)
		return TRUE
	return state_name in state_list

// Resolve the correct icon file for an organ in previews
/datum/tgui_module/custom_marking_designer/proc/resolve_organ_icon_resource(obj/item/organ/external/O, datum/species/species, mob/living/carbon/human/human, digitigrade)
	if(!istype(O))
		return null
	var/skip_forced_icon = O.skip_robo_icon || (digitigrade && O.digi_prosthetic)
	if(O.force_icon && !skip_forced_icon)
		return O.force_icon
	if((O.robotic >= ORGAN_ROBOT) && !skip_forced_icon)
		return 'icons/mob/human_races/robotic.dmi'
	if(O.is_hidden_by_markings())
		return 'icons/mob/human_races/r_blank.dmi'
	if(!species)
		return null
	if(digitigrade && species.icodigi)
		return species.icodigi
	return species.get_icobase(human, (O.status & ORGAN_MUTATED))

// Pick gender suffix for organ icon states
/datum/tgui_module/custom_marking_designer/proc/get_organ_gender_suffix(obj/item/organ/external/O, mob/living/carbon/human/human)
	if(istype(human) && human.gender == FEMALE)
		return "f"
	if(!istype(human))
		var/datum/dna/organ_dna = null
		if(O)
			organ_dna = O.dna
		if(istype(organ_dna) && organ_dna.GetUIState(DNA_UI_GENDER))
			return "f"
	return "m"

// Basic pixel visibility check for icons
/datum/tgui_module/custom_marking_designer/proc/icon_has_visible_pixels(icon/source, cache_key = null)
	if(!isicon(source))
		return FALSE
	var/use_cache = istext(cache_key) && length(cache_key)
	if(use_cache)
		if(!islist(custom_marking_visible_pixel_cache))
			custom_marking_visible_pixel_cache = list()
		else if(cache_key in custom_marking_visible_pixel_cache)
			return !!custom_marking_visible_pixel_cache[cache_key]
	var/width = max(1, source.Width())
	var/height = max(1, source.Height())
	for(var/x = 1 to width)
		for(var/y = 1 to height)
			var/pixel = source.GetPixel(x, y)
			if(istext(pixel) && pixel != "#00000000" && length(pixel))
				if(use_cache)
					custom_marking_visible_pixel_cache[cache_key] = TRUE
				return TRUE
	if(use_cache)
		custom_marking_visible_pixel_cache[cache_key] = FALSE
	return FALSE

// Whitelist specific mannequin overlay indices for previews
/datum/tgui_module/custom_marking_designer/proc/should_include_preview_overlay_layer(layer_index)
	if(!isnum(layer_index))
		return FALSE
	var/static/list/allowed_layers = list(
		1,  // MUTATIONS_LAYER
		2,  // SKIN_LAYER
		3,  // BLOOD_LAYER
		4,  // MOB_DAM_LAYER
		5,  // SURGERY_LAYER
		7,  // TAIL_LOWER_LAYER
		8,  // WING_LOWER_LAYER
		16, // TAIL_UPPER_LAYER
		21, // HAIR_LAYER
		22, // HAIR_ACCESSORY_LAYER
		23, // EARS_LAYER
		24, // EYES_LAYER
		32, // WING_LAYER
		33, // TAIL_UPPER_LAYER_ALT
		34, // MODIFIER_EFFECTS_LAYER
		38, // VORE_BELLY_LAYER
		39, // VORE_TAIL_LAYER
		40  // CUSTOM_MARKING_LAYER
	)
	return layer_index in allowed_layers

// Return slow type(Lira, December 2025)
/datum/tgui_module/custom_marking_designer/proc/get_preview_character_overlay_slot(layer_index)
	if(!isnum(layer_index))
		return null
	switch(layer_index)
		if(7)
			return "tail_lower"
		if(8)
			return "wing_lower"
		if(16)
			return "tail_upper"
		if(21)
			return "hair"
		if(22)
			return "hair_accessory"
		if(23)
			return "ears"
		if(24)
			return "eyes"
		if(32)
			return "wing_upper"
		if(33)
			return "tail_upper_alt"
		if(34)
			return "modifier"
		if(38)
			return "vore_belly"
		if(39)
			return "vore_tail"
		if(40)
			return "custom_marking"
	return null

// Gear-specific overlays for optional preview rendering (Lira, Decemeber 2025)
/datum/tgui_module/custom_marking_designer/proc/should_include_gear_overlay_layer(layer_index)
	if(!isnum(layer_index))
		return FALSE
	var/static/list/gear_layers = list(
		9,  // SHOES_LAYER_ALT
		10, // UNIFORM_LAYER
		11, // ID_LAYER
		12, // SHOES_LAYER
		13, // GLOVES_LAYER
		14, // BELT_LAYER
		15, // SUIT_LAYER
		17, // GLASSES_LAYER
		18, // BELT_LAYER_ALT
		19, // SUIT_STORE_LAYER
		20, // BACK_LAYER
		25, // FACEMASK_LAYER
		26, // GLASSES_LAYER_ALT
		27  // HEAD_LAYER
	)
	return layer_index in gear_layers

// Strip blood/damage overlays from mannequin to keep references clean
/datum/tgui_module/custom_marking_designer/proc/clear_mannequin_preview_overlays(mob/living/carbon/human/dummy/mannequin/mannequin)
	if(!mannequin)
		return
	var/static/list/layers_to_clear = list(3, 4, 5)
	for(var/index in layers_to_clear)
		if(mannequin.overlays_standing?[index])
			mannequin.remove_layer(index)
			mannequin.overlays_standing[index] = null

/datum/tgui_module/custom_marking_designer/proc/reset_mannequin_equipment(mob/living/carbon/human/dummy/mannequin/mannequin, list/equipment_layers)
	if(!mannequin)
		return
	mannequin.delete_inventory(TRUE)
	if(!islist(equipment_layers))
		return
	for(var/layer_index in equipment_layers)
		mannequin.remove_layer(layer_index)

// Safely convert an appearance overlay (image/mutable appearance) into an icon for caching
/datum/tgui_module/custom_marking_designer/proc/reference_icon_from_image(var/source, dir, use_flatten = FALSE)
	if(!source || !isdatum(source))
		return null
	var/should_flatten = use_flatten || istype(source, /mutable_appearance)
	if(should_flatten)
		if(isnum(source:alpha) && source:alpha == 0)
			return null
		var/render_dir = dir
		if(!render_dir)
			render_dir = source:dir || SOUTH
		else if(source:dir && (source:dir & (source:dir - 1)) && !(render_dir & (render_dir - 1)))
			render_dir = source:dir
		var/icon/flat_icon = getFlatIcon(source, render_dir, source:icon, source:icon_state, source:blend_mode, TRUE, TRUE)
		if(!isicon(flat_icon))
			return null
		return flat_icon
	if(!istype(source, /image))
		return null
	var/image/img = source
	if(img.alpha == 0)
		return null
	var/icon/base_icon
	var/icon_path = img.icon
	var/icon_state = img.icon_state
	var/render_dir = dir
	if(!render_dir)
		render_dir = img.dir || SOUTH
	else if(img.dir && (img.dir & (img.dir - 1)) && !(render_dir & (render_dir - 1)))
		render_dir = img.dir
	if(icon_path)
		if(isicon(icon_path))
			base_icon = icon(icon_path, null, render_dir, 1, 0)
		else
			base_icon = icon(icon_path, icon_state, render_dir, 1, 0)
	else
		base_icon = icon('icons/effects/effects.dmi', "nothing", null, 1, 0)
	if(img.alpha && img.alpha < 255)
		base_icon.Blend(rgb(255, 255, 255, img.alpha), ICON_MULTIPLY)
	if(istext(img.color))
		base_icon.Blend(img.color, ICON_MULTIPLY)
	else if(islist(img.color) && length(img.color) >= 20)
		base_icon.MapColors(arglist(img.color))
	if(islist(img.overlays))
		for(var/overlay in img.overlays)
			var/icon/sub_icon = reference_icon_from_image(overlay, dir)
			if(!sub_icon)
				continue
			var/shift_x = 0
			var/shift_y = 0
			if(isdatum(overlay))
				shift_x = overlay:pixel_x
				shift_y = overlay:pixel_y
			sub_icon = shift_icon_for_reference(sub_icon, shift_x, shift_y)
			base_icon.Blend(sub_icon, ICON_OVERLAY)
	return base_icon

// Retrieve any accumulated pixel shift stored for an icon
/datum/tgui_module/custom_marking_designer/proc/get_icon_shift(icon/source)
	if(!isicon(source))
		return list("x" = 0, "y" = 0)
	if(!islist(icon_shift_map))
		icon_shift_map = list()
	var/ref_id = REF(source)
	if(!istext(ref_id))
		return list("x" = 0, "y" = 0)
	var/list/entry = icon_shift_map?[ref_id]
	if(!islist(entry))
		return list("x" = 0, "y" = 0)
	var/shift_x = entry["x"]
	var/shift_y = entry["y"]
	if(!isnum(shift_x))
		shift_x = 0
	if(!isnum(shift_y))
		shift_y = 0
	return list("x" = shift_x, "y" = shift_y)

// Track pixel shift metadata for cloned icons used in previews
/datum/tgui_module/custom_marking_designer/proc/set_icon_shift(icon/source, shift_x, shift_y)
	if(!isicon(source))
		return
	if(!islist(icon_shift_map))
		icon_shift_map = list()
	var/ref_id = REF(source)
	if(!istext(ref_id))
		return
	if(!isnum(shift_x))
		shift_x = 0
	if(!isnum(shift_y))
		shift_y = 0
	icon_shift_map[ref_id] = list("x" = shift_x, "y" = shift_y)

// Clear stored shift metadata for an icon
/datum/tgui_module/custom_marking_designer/proc/clear_icon_shift(icon/source)
	if(!isicon(source) || !islist(icon_shift_map))
		return
	var/ref_id = REF(source)
	if(!istext(ref_id))
		return
	icon_shift_map -= ref_id

// Set the offset for an icon
/datum/tgui_module/custom_marking_designer/proc/offset_icon_shift(icon/source, delta_x, delta_y)
	if(!isicon(source))
		return
	var/list/existing = get_icon_shift(source)
	var/current_x = isnum(existing?["x"]) ? existing["x"] : 0
	var/current_y = isnum(existing?["y"]) ? existing["y"] : 0
	set_icon_shift(source, current_x + delta_x, current_y + delta_y)

// Apply BYOND pixel offsets to a cloned icon for reference usage
/datum/tgui_module/custom_marking_designer/proc/shift_icon_for_reference(icon/source, shift_x, shift_y)
	if(!istype(source, /icon))
		return null
	var/icon/result = new/icon(source)
	var/pad_left = max(0, -shift_x)
	var/pad_bottom = max(0, -shift_y)
	if(pad_left || pad_bottom)
		var/icon/padded = icon('icons/effects/effects.dmi', "nothing", null, 1, 0)
		var/padded_width = max(1, result.Width() + pad_left)
		var/padded_height = max(1, result.Height() + pad_bottom)
		padded.Scale(padded_width, padded_height)
		padded.Blend(result, ICON_OVERLAY, 1 + pad_left, 1 + pad_bottom)
		result = padded
	var/list/original_shift = get_icon_shift(source)
	var/total_shift_x = original_shift["x"]
	var/total_shift_y = original_shift["y"]
	if(shift_x)
		if(shift_x > 0)
			result.Shift(EAST, shift_x)
		else
			result.Shift(WEST, -shift_x)
		total_shift_x += shift_x
	if(shift_y)
		if(shift_y > 0)
			result.Shift(NORTH, shift_y)
		else
			result.Shift(SOUTH, -shift_y)
		total_shift_y += shift_y
	set_icon_shift(result, total_shift_x, total_shift_y)
	return result

#define CUSTOM_MARKING_DYNAMIC_ATLAS_MAX_DIMENSION 1024

/datum/tgui_module/custom_marking_designer/proc/get_dynamic_reference_atlas_bucket(icon/source)
	if(!isicon(source))
		return null
	var/max_dimension = max(source.Width(), source.Height())
	if(max_dimension <= 32)
		return "small"
	if(max_dimension <= 64)
		return "medium"
	if(max_dimension <= 128)
		return "large"
	return "oversized-[source.Width()]x[source.Height()]"

/datum/tgui_module/custom_marking_designer/proc/build_dynamic_reference_icon_asset(icon/source, stable_signature)
	if(!isicon(source) || !istext(stable_signature) || !length(stable_signature))
		return null
	var/list/icon_shift = get_icon_shift(source)
	var/shift_x = round(icon_shift?["x"])
	var/shift_y = round(icon_shift?["y"])
	var/cache_key = "[stable_signature]|[source.Width()]x[source.Height()]|[shift_x],[shift_y]"
	if(!islist(reference_asset_signature_cache))
		reference_asset_signature_cache = list()
	var/list/cached_asset = reference_asset_signature_cache[cache_key]
	if(islist(cached_asset))
		clear_icon_shift(source)
		return cached_asset
	var/key_prefix = state_session_token
	if(!istext(key_prefix) || !length(key_prefix))
		key_prefix = "reference"
	var/token = "[key_prefix]-reference-[md5(cache_key)]"
	var/list/payload = list(
		"token" = token,
		"width" = source.Width(),
		"height" = source.Height(),
		"shift_x" = shift_x,
		"shift_y" = shift_y
	)
	var/icon/source_copy = new/icon(source)
	if(!islist(reference_asset_pending_icons))
		reference_asset_pending_icons = list()
	reference_asset_pending_icons += list(list(
		"icon" = source_copy,
		"payload" = payload,
		"bucket" = get_dynamic_reference_atlas_bucket(source_copy)
	))
	reference_asset_signature_cache[cache_key] = payload
	clear_icon_shift(source)
	return payload

/datum/tgui_module/custom_marking_designer/proc/encode_pending_reference_asset_standalone(list/pending_entry)
	var/icon/source = pending_entry?["icon"]
	var/list/payload = pending_entry?["payload"]
	if(!isicon(source) || !islist(payload))
		return FALSE
	var/png_data = icon2base64(source)
	if(!istext(png_data) || !length(png_data))
		return FALSE
	payload["png"] = png_data
	payload -= "atlas"
	payload -= "atlas_x"
	payload -= "atlas_y"
	payload -= "atlas_png"
	payload -= "atlas_width"
	payload -= "atlas_height"
	pending_entry["icon"] = null
	return TRUE

/datum/tgui_module/custom_marking_designer/proc/finalize_pending_reference_asset_atlases(revision_signature)
	if(!islist(reference_asset_pending_icons) || !reference_asset_pending_icons.len)
		return TRUE
	var/list/buckets = list()
	for(var/list/pending_entry as anything in reference_asset_pending_icons)
		var/bucket_id = pending_entry?["bucket"]
		if(!istext(bucket_id) || !length(bucket_id))
			bucket_id = "other"
		var/list/bucket_entries = buckets[bucket_id]
		if(!islist(bucket_entries))
			bucket_entries = list()
			buckets[bucket_id] = bucket_entries
		bucket_entries += list(pending_entry)
	for(var/bucket_id in buckets)
		var/list/bucket_entries = buckets[bucket_id]
		if(!islist(bucket_entries) || !bucket_entries.len)
			continue
		var/cell_width = 1
		var/cell_height = 1
		for(var/list/pending_entry as anything in bucket_entries)
			var/icon/source = pending_entry?["icon"]
			if(!isicon(source))
				continue
			cell_width = max(cell_width, source.Width())
			cell_height = max(cell_height, source.Height())
		var/max_columns = max(1, round(CUSTOM_MARKING_DYNAMIC_ATLAS_MAX_DIMENSION / cell_width))
		var/max_rows = max(1, round(CUSTOM_MARKING_DYNAMIC_ATLAS_MAX_DIMENSION / cell_height))
		var/chunk_capacity = max(1, max_columns * max_rows)
		var/chunk_start = 1
		while(chunk_start <= bucket_entries.len)
			CUSTOM_MARKING_CHECK_TICK
			var/chunk_end = min(bucket_entries.len, chunk_start + chunk_capacity - 1)
			var/chunk_count = chunk_end - chunk_start + 1
			var/columns = min(max_columns, chunk_count)
			var/rows = max(1, CEILING(chunk_count / columns, 1))
			var/sheet_width = max(1, columns * cell_width)
			var/sheet_height = max(1, rows * cell_height)
			var/icon/atlas_icon = icon('icons/effects/effects.dmi', "nothing", null, 1, 0)
			atlas_icon.Scale(sheet_width, sheet_height)
			var/chunk_offset = 0
			for(var/index = chunk_start to chunk_end)
				var/list/pending_entry = bucket_entries[index]
				var/icon/source = pending_entry?["icon"]
				var/list/payload = pending_entry?["payload"]
				if(!isicon(source) || !islist(payload))
					chunk_offset++
					continue
				var/column = chunk_offset % columns
				var/row = round(chunk_offset / columns)
				var/place_x = (column * cell_width) + 1
				var/place_y = sheet_height - ((row + 1) * cell_height) + (cell_height - source.Height()) + 1
				atlas_icon.Blend(source, ICON_OVERLAY, place_x, place_y)
				payload["atlas_x"] = column * cell_width
				payload["atlas_y"] = row * cell_height
				chunk_offset++
			var/png_data = icon2base64(atlas_icon)
			if(!istext(png_data) || !length(png_data))
				var/revision_id = istext(revision_signature) && length(revision_signature) ? md5(revision_signature) : "none"
				var/fallback_species = prefs?.species || "unknown"
				var/fallback_base = prefs?.custom_base || "none"
				report_custom_marking_atlas_fallback(
					"dynamic-sheet-to-standalone",
					"dynamic reference atlas PNG encoding failed",
					"species=[fallback_species], custom_base=[fallback_base], bucket=[bucket_id], revision=[revision_id], sheet=[sheet_width]x[sheet_height], frames=[chunk_count]",
					chunk_count
				)
				var/standalone_failures = 0
				for(var/index = chunk_start to chunk_end)
					if(!encode_pending_reference_asset_standalone(bucket_entries[index]))
						standalone_failures++
				if(standalone_failures)
					report_custom_marking_atlas_fallback(
						"dynamic-sheet-to-standalone-failed",
						"standalone PNG encoding also failed",
						"species=[fallback_species], custom_base=[fallback_base], bucket=[bucket_id], revision=[revision_id], failed=[standalone_failures]/[chunk_count]",
						standalone_failures
					)
				chunk_start = chunk_end + 1
				continue
			reference_dynamic_atlas_counter++
			var/revision_key = istext(revision_signature) && length(revision_signature) ? revision_signature : "reference"
			var/atlas_signature = "[revision_key]|[bucket_id]|[reference_dynamic_atlas_counter]"
			var/atlas_token = "[state_session_token]-reference-atlas-[md5(atlas_signature)]"
			for(var/index = chunk_start to chunk_end)
				var/list/pending_entry = bucket_entries[index]
				var/list/payload = pending_entry?["payload"]
				if(!islist(payload))
					continue
				payload["atlas"] = atlas_token
				payload["atlas_png"] = png_data
				payload["atlas_width"] = sheet_width
				payload["atlas_height"] = sheet_height
				pending_entry["icon"] = null
			chunk_start = chunk_end + 1
	reference_asset_pending_icons = null
	return TRUE

/datum/tgui_module/custom_marking_designer/proc/build_reference_icon_asset(icon/source, stable_signature = null)
	var/dynamic_fallback_reason = null
	if(istext(stable_signature) && length(stable_signature) && !use_shared_atlas)
		var/list/dynamic_asset = build_dynamic_reference_icon_asset(source, stable_signature)
		if(islist(dynamic_asset))
			return dynamic_asset
		dynamic_fallback_reason = "dynamic atlas queueing rejected the reference frame"
	else if(!use_shared_atlas)
		dynamic_fallback_reason = "no stable reference signature was available for dynamic atlas packaging"
	if(dynamic_fallback_reason)
		var/fallback_species = prefs?.species || "unknown"
		var/fallback_base = prefs?.custom_base || "none"
		var/fallback_source = isicon(source) ? "size=[source.Width()]x[source.Height()]" : "source is not an icon"
		report_custom_marking_atlas_fallback(
			"dynamic-frame-to-standalone",
			dynamic_fallback_reason,
			"species=[fallback_species], custom_base=[fallback_base], [fallback_source]"
		)
	return build_icon_asset(source)

/datum/tgui_module/custom_marking_designer/proc/register_reference_transport_asset(list/payload, list/assets, list/atlases)
	if(!islist(payload) || !islist(assets) || !islist(atlases))
		return null
	var/token = payload["token"]
	if(!istext(token) || !length(token))
		return null
	if(payload["canonical"])
		return token
	if(!islist(assets[token]))
		var/list/transport_payload = payload.Copy()
		transport_payload -= "atlas_png"
		transport_payload -= "atlas_width"
		transport_payload -= "atlas_height"
		assets[token] = transport_payload
	var/atlas_token = payload["atlas"]
	var/atlas_png = payload["atlas_png"]
	if(istext(atlas_token) && length(atlas_token) && istext(atlas_png) && length(atlas_png) && !islist(atlases[atlas_token]))
		atlases[atlas_token] = list(
			"png" = atlas_png,
			"width" = payload["atlas_width"],
			"height" = payload["atlas_height"]
		)
	return token

/datum/tgui_module/custom_marking_designer/proc/canonicalize_reference_asset_map(list/source_assets, list/assets, list/atlases, drop_generic = FALSE)
	var/list/result = list()
	if(!islist(source_assets))
		return result
	for(var/key in source_assets)
		if(drop_generic && key == "generic")
			continue
		var/value = source_assets[key]
		var/token = istext(value) ? value : register_reference_transport_asset(value, assets, atlases)
		if(istext(token) && length(token))
			result[key] = token
	return result

/datum/tgui_module/custom_marking_designer/proc/canonicalize_reference_overlay_assets(list/source_overlays, list/assets, list/atlases)
	var/list/result = list()
	if(!islist(source_overlays))
		return result
	for(var/entry as anything in source_overlays)
		if(istext(entry))
			result += entry
			continue
		if(!islist(entry))
			continue
		var/list/entry_list = entry
		var/wrapped_asset = entry_list["asset"]
		if(islist(wrapped_asset) || istext(entry_list["asset"]))
			var/list/transport_entry = entry_list.Copy()
			var/token = istext(entry_list["asset"]) ? entry_list["asset"] : register_reference_transport_asset(wrapped_asset, assets, atlases)
			if(istext(token) && length(token))
				transport_entry["asset"] = token
				var/recipe_complete = TRUE
				var/mask_asset = entry_list["mask_asset"]
				if(islist(mask_asset) || istext(mask_asset))
					var/mask_token = istext(mask_asset) ? mask_asset : register_reference_transport_asset(mask_asset, assets, atlases)
					if(istext(mask_token) && length(mask_token))
						transport_entry["mask_asset"] = mask_token
					else
						recipe_complete = FALSE
				var/list/source_component_overlays = entry_list["overlays"]
				var/list/component_overlays = canonicalize_reference_overlay_assets(source_component_overlays, assets, atlases)
				if(component_overlays.len)
					transport_entry["overlays"] = component_overlays
				else
					transport_entry -= "overlays"
				if(islist(source_component_overlays) && source_component_overlays.len != component_overlays.len)
					recipe_complete = FALSE
				if(recipe_complete)
					result += list(transport_entry)
			continue
		var/direct_token = register_reference_transport_asset(entry_list, assets, atlases)
		if(istext(direct_token) && length(direct_token))
			result += direct_token
	return result

/datum/tgui_module/custom_marking_designer/proc/build_reference_transport_bundle(list/sources, revision, signature = null)
	if(!islist(sources) || !sources.len)
		return null
	var/list/assets = list()
	var/list/atlases = list()
	var/list/transport_sources = list()
	for(var/list/source as anything in sources)
		if(!islist(source))
			continue
		var/list/entry = source.Copy()
		entry -= "composite_asset"
		var/body_asset = source["body_asset"]
		if(islist(body_asset) || istext(source["body_asset"]))
			entry["body_asset"] = istext(source["body_asset"]) ? source["body_asset"] : register_reference_transport_asset(body_asset, assets, atlases)
		var/list/part_assets = canonicalize_reference_asset_map(source["reference_part_assets"], assets, atlases, TRUE)
		entry["reference_part_assets"] = part_assets
		var/list/part_hair_assets = canonicalize_reference_asset_map(source["reference_part_hair_assets"], assets, atlases)
		entry["reference_part_hair_assets"] = part_hair_assets
		var/list/part_marking_assets = canonicalize_reference_asset_map(source["reference_part_marking_assets"], assets, atlases)
		entry["reference_part_marking_assets"] = part_marking_assets
		for(var/overlay_field in list("overlay_assets", "equipment_overlay_assets", "job_overlay_assets", "loadout_overlay_assets"))
			var/list/overlay_assets = canonicalize_reference_overlay_assets(source[overlay_field], assets, atlases)
			if(overlay_assets.len)
				entry[overlay_field] = overlay_assets
			else
				entry -= overlay_field
		transport_sources += list(entry)
	if(!transport_sources.len)
		return null
	return list(
		"dirs" = transport_sources,
		"revision" = revision,
		"signature" = istext(signature) && length(signature) ? signature : "revision-[revision]",
		"asset_registry" = list(
			"revision" = revision,
			"assets" = assets,
			"atlases" = atlases
		)
	)

#undef CUSTOM_MARKING_DYNAMIC_ATLAS_MAX_DIMENSION

// Allocate a unique token for preview assets
/datum/tgui_module/custom_marking_designer/proc/allocate_reference_asset_token()
	if(reference_asset_token_counter >= 1000000)
		reference_asset_token_counter = 0
	reference_asset_token_counter++
	var/key_prefix = state_session_token
	if(!istext(key_prefix) || !length(key_prefix))
		key_prefix = "asset"
	return "[key_prefix]-[reference_asset_token_counter]"

/datum/tgui_module/custom_marking_designer/proc/build_static_icon_canonical_key(icon_source, icon_state, dir, preprocessing = "raw", frame = 1)
	if(!icon_source || !istext(icon_state) || !length(icon_state) || !isnum(dir))
		return null
	var/source_digest = custom_marking_static_source_digest(icon_source)
	if(!istext(source_digest) || !length(source_digest))
		return null
	return "source-v3|[icon_source]|content:[source_digest]|[icon_state]|[dir]|[frame]|[preprocessing]"

/datum/tgui_module/custom_marking_designer/proc/find_static_icon_asset(canonical_key, family)
	if(!use_shared_atlas || !istext(canonical_key) || !length(canonical_key))
		return null
	var/datum/asset/spritesheet/custom_marking_designer/atlas = get_asset_datum(/datum/asset/spritesheet/custom_marking_designer)
	var/full_key = "[canonical_key]|shift:0,0"
	var/list/payload = atlas.get_icon_asset(full_key)
	if(!islist(payload))
		return null
	return atlas.note_icon_asset_request(full_key, family)

/datum/tgui_module/custom_marking_designer/proc/build_static_source_icon_asset(icon_source, icon_state, dir, family, preprocessing = "raw", visibility_key = null)
	var/canonical_key = build_static_icon_canonical_key(icon_source, icon_state, dir, preprocessing)
	if(!canonical_key)
		return null
	var/list/cached_payload = find_static_icon_asset(canonical_key, family)
	if(islist(cached_payload))
		return cached_payload
	var/icon/source = icon(icon_source, icon_state, dir, 1, 0)
	if(!isicon(source))
		return null
	var/resolved_visibility_key = istext(visibility_key) && length(visibility_key) ? visibility_key : canonical_key
	if(!icon_has_visible_pixels(source, resolved_visibility_key))
		return null
	return build_icon_asset(source, canonical_key, family)

/datum/tgui_module/custom_marking_designer/proc/get_static_icon_asset_reference(list/payload)
	if(!islist(payload))
		return null
	var/token = payload["token"]
	if(payload["canonical"] && istext(token) && length(token))
		return token
	return payload

/datum/tgui_module/custom_marking_designer/proc/build_static_source_icon_reference(icon_source, icon_state, dir, family, preprocessing = "raw", visibility_key = null)
	var/list/payload = build_static_source_icon_asset(icon_source, icon_state, dir, family, preprocessing, visibility_key)
	return get_static_icon_asset_reference(payload)

/datum/tgui_module/custom_marking_designer/proc/build_icon_asset(icon/source, canonical_key = null, family = null)
	if(!isicon(source))
		return null
	var/list/icon_shift = get_icon_shift(source)
	var/shift_x = round(icon_shift?["x"])
	var/shift_y = round(icon_shift?["y"])
	var/token = null
	var/atlas_fallback_path = null
	var/atlas_fallback_reason = null
	var/atlas_fallback_details = null
	if(use_shared_atlas)
		var/datum/asset/spritesheet/custom_marking_designer/atlas = get_asset_datum(/datum/asset/spritesheet/custom_marking_designer)
		if(!istype(atlas))
			stack_trace("Custom Marking Designer could not resolve its canonical atlas.")
			clear_icon_shift(source)
			return null
		if(!atlas.is_valid_family(family))
			stack_trace("Custom Marking Designer static atlas insertion rejected invalid family '[family]'.")
			clear_icon_shift(source)
			return null
		var/full_canonical_key = istext(canonical_key) && length(canonical_key) ? "[canonical_key]|shift:[shift_x],[shift_y]" : null
		if(!full_canonical_key)
			token = allocate_reference_asset_token()
		var/list/atlas_payload = atlas.add_icon_asset(source, token, shift_x, shift_y, full_canonical_key, family)
		if(islist(atlas_payload))
			clear_icon_shift(source)
			return atlas_payload
		if(atlas.is_persistent_cache_validation_pending())
			clear_icon_shift(source)
			return null
		atlas_fallback_path = "canonical-frame-to-standalone/[family]"
		atlas_fallback_reason = atlas.can_accept_assets() ? "canonical atlas rejected a frame insertion" : "canonical atlas was no longer accepting frame insertions"
		var/fallback_key = istext(canonical_key) && length(canonical_key) ? canonical_key : "uncanonicalized"
		atlas_fallback_details = "key=[fallback_key], size=[source.Width()]x[source.Height()], shift=[shift_x],[shift_y]"
		report_custom_marking_atlas_fallback(atlas_fallback_path, atlas_fallback_reason, atlas_fallback_details)
	if(!istext(token) || !length(token))
		token = allocate_reference_asset_token()
	var/png_data = icon2base64(source)
	if(atlas_fallback_reason && (!istext(png_data) || !length(png_data)))
		report_custom_marking_atlas_fallback(
			"[atlas_fallback_path]-failed",
			"standalone PNG encoding failed after the canonical atlas fallback",
			atlas_fallback_details
		)
	var/list/payload = list(
		"token" = token,
		"png" = png_data,
		"width" = source.Width(),
		"height" = source.Height(),
		"shift_x" = shift_x,
		"shift_y" = shift_y
	)
	clear_icon_shift(source)
	return payload

// Resolve category for a body marking
/datum/tgui_module/custom_marking_designer/proc/get_body_marking_category(marking_id)
	if(!istext(marking_id) || !length(marking_id))
		return "all"
	if(body_marking_heads && (marking_id in body_marking_heads))
		return "heads"
	if(body_marking_bodies && (marking_id in body_marking_bodies))
		return "bodies"
	if(body_marking_limbs && (marking_id in body_marking_limbs))
		return "limbs"
	if(body_marking_addons && (marking_id in body_marking_addons))
		return "addons"
	if(body_marking_skintone && (marking_id in body_marking_skintone))
		return "skintone"
	if(body_marking_teshari && (marking_id in body_marking_teshari))
		return "teshari"
	if(body_marking_vox && (marking_id in body_marking_vox))
		return "vox"
	if(body_marking_augment && (marking_id in body_marking_augment))
		return "augment"
	return "all"

// Helper to pick the default color for a marking
/datum/tgui_module/custom_marking_designer/proc/get_body_marking_default_color(datum/sprite_accessory/marking/style)
	if(istype(style) && !style.do_colouration)
		return "#FFFFFF"
	return "#000000"

// Check if a body marking is allowed for the current preferences (Lira, December 2025)
/datum/tgui_module/custom_marking_designer/proc/is_body_marking_allowed(datum/sprite_accessory/marking/style)
	if(!istype(style) || !prefs)
		return TRUE
	if(!islist(style.species_allowed) || !style.species_allowed.len)
		return TRUE
	var/species = prefs.species
	if(istext(species) && length(species) && (species in style.species_allowed))
		return TRUE
	var/custom_base = prefs.custom_base
	if(istext(custom_base) && length(custom_base) && (custom_base in style.species_allowed))
		return TRUE
	return FALSE

/datum/tgui_module/custom_marking_designer/proc/build_body_marking_definition_context()
	if(!prefs)
		return null
	var/context_key = "[prefs.species || ""]|[prefs.custom_base || ""]"
	if(!islist(body_marking_definition_context_cache))
		body_marking_definition_context_cache = list()
	var/list/cached_context = body_marking_definition_context_cache[context_key]
	if(islist(cached_context))
		return cached_context
	var/list/definitions = build_body_marking_definitions()
	var/list/allowed_ids = list()
	if(islist(definitions))
		for(var/list/definition as anything in definitions)
			CUSTOM_MARKING_CHECK_TICK
			var/definition_id = definition?["id"]
			if(istext(definition_id) && length(definition_id))
				allowed_ids += definition_id
	var/revision_seed = "body-marking-definitions-v1|[context_key]|[json_encode(allowed_ids)]"
	cached_context = list(
		"revision" = md5(revision_seed),
		"definition_data" = definitions,
		"allowed_definition_ids" = allowed_ids
	)
	body_marking_definition_context_cache[context_key] = cached_context
	return cached_context

/datum/tgui_module/custom_marking_designer/proc/append_body_marking_definition_delta(list/payload, known_revision = null)
	if(!islist(payload))
		return FALSE
	var/list/context = build_body_marking_definition_context()
	if(!islist(context))
		return FALSE
	var/revision = context["revision"]
	payload["definition_revision"] = revision
	payload["allowed_definition_ids"] = context["allowed_definition_ids"]
	if(istext(known_revision) && length(known_revision) && known_revision == revision)
		return FALSE
	payload["definition_data"] = context["definition_data"]
	return TRUE

// Build icon assets for each covered body part for a marking
/datum/tgui_module/custom_marking_designer/proc/build_marking_part_assets(datum/sprite_accessory/marking/style, dir, digitigrade = FALSE)
	if(!istype(style))
		return null
	var/icon/icon_source = digitigrade && style.digitigrade_icon ? style.digitigrade_icon : style.icon
	if(!icon_source)
		return null
	var/list/state_list = cached_icon_states(icon_source)
	var/list/result = list()
	for(var/part in style.body_parts)
		CUSTOM_MARKING_CHECK_TICK
		if(!istext(part) || !length(part))
			continue
		var/state_name = "[style.icon_state]-[part]"
		if(!islist(state_list) || !(state_name in state_list))
			continue
		var/list/asset = build_static_source_icon_asset(icon_source, state_name, dir, "markings")
		if(!islist(asset))
			continue
		result[part] = get_static_icon_asset_reference(asset)
	return result

// Build the full set of body marking definitions for the UI
/datum/tgui_module/custom_marking_designer/proc/build_body_marking_definitions(skip_filter = FALSE)
	var/list/base_definitions = islist(custom_marking_body_definition_cache) ? custom_marking_body_definition_cache : null
	if(!islist(base_definitions))
		base_definitions = list()
		for(var/marking_id in body_marking_styles_list)
			CUSTOM_MARKING_CHECK_TICK
			var/datum/sprite_accessory/marking/style = body_marking_styles_list[marking_id]
			if(!istype(style))
				continue
			var/list/def = list(
				"id" = marking_id,
				"name" = style.get_display_name(),
				"category" = get_body_marking_category(marking_id),
				"body_parts" = style.body_parts?.Copy() || list(),
				"hide_body_parts" = islist(style.hide_body_parts) ? style.hide_body_parts.Copy() : null,
				"do_colouration" = !!style.do_colouration,
				"color_blend_mode" = style.color_blend_mode,
				"render_above_body" = !!style.render_above_body,
				"render_above_body_parts" = islist(style.render_above_body_parts) ? style.render_above_body_parts.Copy() : null,
				"digitigrade_acceptance" = style.digitigrade_acceptance,
				"hide_from_gallery" = !!style.hide_from_marking_gallery,
				"default_color" = get_body_marking_default_color(style)
			)
			var/list/default_entry = prefs?.mass_edit_marking_list(marking_id, TRUE, TRUE, null, TRUE, def["default_color"])
			if(islist(default_entry))
				def["default_entry"] = default_entry
			var/list/dir_assets = list()
			var/list/dir_digi_assets = list()
			for(var/dir in list(NORTH, SOUTH, EAST, WEST))
				CUSTOM_MARKING_CHECK_TICK
				var/list/assets = build_marking_part_assets(style, dir, FALSE)
				if(islist(assets) && assets.len)
					dir_assets["[dir]"] = assets // numeric keys as associative to avoid sparse index runtimes
				CUSTOM_MARKING_CHECK_TICK
				var/list/digi_assets = build_marking_part_assets(style, dir, TRUE)
				if(islist(digi_assets) && digi_assets.len)
					dir_digi_assets["[dir]"] = digi_assets
			if(dir_assets.len)
				def["assets"] = dir_assets
			if(dir_digi_assets.len)
				def["digitigrade_assets"] = dir_digi_assets
			base_definitions += list(def)
		custom_marking_body_definition_cache = base_definitions
	if(skip_filter || !prefs)
		return base_definitions
	var/list/filtered_definitions = list()
	for(var/entry in base_definitions)
		CUSTOM_MARKING_CHECK_TICK
		var/list/def = entry
		if(!islist(def))
			continue
		var/marking_id = def["id"]
		var/datum/sprite_accessory/marking/style = body_marking_styles_list[marking_id]
		if(!istype(style))
			continue
		if(!is_body_marking_allowed(style))
			continue
		filtered_definitions += list(def)
	return filtered_definitions

// Sanitize an incoming body marking entry from the client
/datum/tgui_module/custom_marking_designer/proc/sanitize_body_marking_entry(marking_id, datum/sprite_accessory/marking/style, list/incoming)
	if(!istext(marking_id) || !istype(style))
		return null
	var/default_color = get_body_marking_default_color(style)
	var/list/base_entry = prefs?.mass_edit_marking_list(marking_id, TRUE, TRUE, null, TRUE, default_color)
	if(!islist(base_entry))
		return null
	if(!islist(incoming))
		return base_entry
	if(incoming["color"])
		if(style.do_colouration)
			base_entry["color"] = sanitize_hexcolor(incoming["color"], default_color)
	for(var/part in incoming)
		if(part == "color")
			continue
		if(!istext(part))
			continue
		if(!(part in style.body_parts))
			continue
		var/list/part_state = base_entry[part]
		if(!islist(part_state))
			part_state = list("on" = TRUE, "color" = default_color)
		var/list/raw_part = incoming[part]
		if(islist(raw_part))
			if("on" in raw_part)
				part_state["on"] = !!raw_part["on"]
			if(style.do_colouration && raw_part["color"])
				part_state["color"] = sanitize_hexcolor(raw_part["color"], default_color)
		base_entry[part] = part_state
	return base_entry

// Reset any in-progress chunked body markings save
/datum/tgui_module/custom_marking_designer/proc/reset_body_marking_chunk_state()
	body_marking_chunk_token = null
	body_marking_chunk_buffer = null
	body_marking_chunk_order = null
	body_marking_chunk_expected = 0
	body_marking_chunk_received = 0

// Merge chunked payload data and return the full payload once complete
/datum/tgui_module/custom_marking_designer/proc/resolve_body_marking_chunk_payload(list/params)
	if(!islist(params))
		reset_body_marking_chunk_state()
		return null
	var/chunk_total = text2num_safe(params?["chunk_total"])
	var/chunk_index = text2num_safe(params?["chunk_index"])
	var/chunk_token = params?["chunk_id"]
	if(!istext(chunk_token) || !chunk_total || chunk_total <= 0 || isnull(chunk_index))
		reset_body_marking_chunk_state()
		return params
	if(chunk_total > 256)
		chunk_total = 256
	if(chunk_token != body_marking_chunk_token)
		reset_body_marking_chunk_state()
		body_marking_chunk_token = chunk_token
	body_marking_chunk_expected = max(body_marking_chunk_expected, chunk_total)
	if(islist(params?["order"]))
		body_marking_chunk_order = params["order"]
	var/list/chunk_map = params?["body_markings"]
	if(islist(chunk_map))
		if(!islist(body_marking_chunk_buffer))
			body_marking_chunk_buffer = list()
		for(var/id in chunk_map)
			if(istext(id))
				body_marking_chunk_buffer[id] = chunk_map[id]
	body_marking_chunk_received = max(body_marking_chunk_received, chunk_index + 1)
	if(body_marking_chunk_expected > 0 && body_marking_chunk_received >= body_marking_chunk_expected)
		var/list/final_map = islist(body_marking_chunk_buffer) ? body_marking_chunk_buffer : list()
		var/list/final_order = islist(body_marking_chunk_order) ? body_marking_chunk_order : list()
		if(!final_order.len && final_map.len)
			for(var/mark_id in final_map)
				final_order += mark_id
		reset_body_marking_chunk_state()
		return list(
			"body_markings" = final_map,
			"order" = final_order
		)
	return BODY_MARKING_CHUNK_PENDING

// Apply a body markings payload coming from the client
/datum/tgui_module/custom_marking_designer/proc/apply_body_marking_payload(list/params)
	if(!prefs)
		return FALSE
	var/list/incoming_map = params?["body_markings"]
	if(!islist(incoming_map))
		return FALSE
	var/list/order = params?["order"]
	var/list/ordered_marks = list()
	if(islist(order) && order.len)
		for(var/id in order)
			ordered_marks += id
	else
		for(var/id in incoming_map)
			ordered_marks += id
	var/list/new_payload = list()
	for(var/mark_id in ordered_marks)
		if(new_payload.len >= BODY_MARKING_SELECTION_LIMIT)
			break
		if(!istext(mark_id) || !incoming_map[mark_id])
			continue
		var/datum/sprite_accessory/marking/style = body_marking_styles_list[mark_id]
		if(!istype(style))
			continue
		if(!is_body_marking_allowed(style))
			continue
		var/list/sanitized = sanitize_body_marking_entry(mark_id, style, incoming_map[mark_id])
		if(!islist(sanitized))
			continue
		new_payload[mark_id] = sanitized
	prefs.body_markings = new_payload
	prefs.sanitize_body_styles()
	return TRUE

#undef BODY_MARKING_SELECTION_LIMIT
#undef CUSTOM_MARKING_DEFAULT_WIDTH
#undef CUSTOM_MARKING_DEFAULT_HEIGHT
#undef CUSTOM_MARKING_CANVAS_MAX_WIDTH
#undef CUSTOM_MARKING_CANVAS_MAX_HEIGHT
#ifdef CUSTOM_MARKING_CHECK_TICK_DEFINED_IN_DESIGNER
#undef CUSTOM_MARKING_CHECK_TICK
#undef CUSTOM_MARKING_CHECK_TICK_DEFINED_IN_DESIGNER
#endif
