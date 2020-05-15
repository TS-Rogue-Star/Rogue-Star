//
//
// DEMO TECHWEB SO I CAN TEST THE CODE
//
//

//Base Nodes
/datum/techweb_node/base
	id = "base"
	starting_node = TRUE
	display_name = "Basic Research Technology"
	description = "NT default research technologies."
	// Default research tech, prevents bricking
	design_ids = list("basic_matter_bin", "basic_cell", "basic_sensor", "basic_capacitor", "basic_micro_laser", "micro_mani", "misc_synth_bag",
				"design_disk", "tech_disk", "destructive_analyzer", "protolathe", "circuit_imprinter", "autolathe", "rdconsole")

/datum/techweb_node/mech
	id = "mecha"
	starting_node = TRUE
	display_name = "Mechanical Exosuits"
	description = "Mechanized exosuits that are several magnitudes stronger and more powerful than the average human."
	design_ids = list("ripley_chassis", "ripley_torso", "ripley_left_arm", "ripley_right_arm", "ripley_left_leg", "ripley_right_leg")

/datum/techweb_node/basic_tools
	id = "basic_tools"
	starting_node = TRUE
	display_name = "Basic Tools"
	description = "Basic mechanical, electronic, surgical and botanical tools."
	design_ids = list()

/datum/techweb_node/basic_medical
	id = "basic_medical"
	starting_node = TRUE
	display_name = "Basic Medical Equipment"
	description = "Basic medical tools and equipment."
	design_ids = list("bone_clamp", "medical_analyzer", "roller_bed", "sleevemate")

/datum/techweb_node/adv_medical
	id = "adv_medical"
	display_name = "Advanced Medical Equipment"
	description = "Advanced medical tools and equipment."
	prereq_ids = list("basic_medical")
	design_ids = list("scalpel_laser1", "scalpel_laser2", "scalpel_laser3", "scalpel_manager", "advanced_saw", "organ_ripper")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 2500)

/datum/techweb_node/pros_limbs
	id = "pros_limbs"
	display_name = "Prosthetic Limbs"
	description = "Prosthetic Limbs"
	prereq_ids = list("basic_medical")
	design_ids = list("pros_torso_m", "pros_torso_f", "pros_head", "pros_l_arm", "pros_l_hand", "pros_r_arm", "pros_r_hand",
					"pros_l_leg", "pros_l_foot", "pros_r_leg", "pros_r_foot")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 2500)

/datum/techweb_node/pros_organs
	id = "pros_organs"
	display_name = "Prosthetic Organs"
	description = "Prosthetic Organs"
	prereq_ids = list("pros_limbs", "engineering")
	design_ids = list("pros_cell", "pros_eyes", "pros_heart", "pros_lung", "pros_liver", "pros_kidney", "pros_spleen", "pros_larynx")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 2500)

/datum/techweb_node/engineering
	id = "engineering"
	display_name = "Industrial Engineering"
	description = "A refresher course on modern engineering technology."
	prereq_ids = list("base")
	design_ids = list("solarcontrol", "mech_recharger", "powermonitor", "rped")
	boost_item_paths = list(/obj/item/device/multitool = list(TECHWEB_POINT_TYPE_GENERIC = 1000))
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 7500)

/datum/techweb_node/adv_power
	id = "adv_power"
	display_name = "Advanced Power Manipulation"
	description = "How to get more zap."
	prereq_ids = list("engineering")
	design_ids = list("smes_cell", "super_cell")
	boost_item_paths = list(/obj/item/device/multitool = list(TECHWEB_POINT_TYPE_GENERIC = 500))
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 2500)

/datum/techweb_node/hyper_power
	id = "hyper_power"
	display_name = "Hyper Advanced Power Manipulation"
	description = "Cooler Cells"
	prereq_ids = list("adv_power")
	design_ids = list("hyper_cell")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 7500)
