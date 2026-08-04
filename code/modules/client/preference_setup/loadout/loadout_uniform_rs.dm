// New Talon Uniforms
/datum/gear/uniform/refreshedtalonbasic
	display_name = "Refreshed Talon Jumpsuit"
	description = "Select from a range of outfits available to all Talon crew."
	allowed_roles = list("Talon Captain","Talon Doctor","Talon Engineer","Talon Pilot","Talon Guard","Talon Miner")
	path = /obj/item/clothing/under/rank/talon/basic/refreshed
	sort_category = "Uniforms"
	cost = 1

/datum/gear/uniform/refreshedtalonbasic/New()
	..()
	var/list/selector_uniforms = list(
		"Refreshed Talon crew Uniform" = /obj/item/clothing/under/rank/talon/basic/refreshed,
		"Old Talon crew Uniform"       = /obj/item/clothing/under/rank/talon/basic,
	)
	gear_tweaks += new/datum/gear_tweak/path(selector_uniforms)

/datum/gear/uniform/refreshedtaloncaptain
	display_name = "Refreshed Talon Command Uniform"
	description = "Select from a range of outfits available to all Talon Captains."
	allowed_roles = list("Talon Captain")
	path = /obj/item/clothing/under/rank/talon/command/refreshed
	sort_category = "Uniforms"
	cost = 1

/datum/gear/uniform/refreshedtaloncaptain/New()
	..()
	var/list/selector_uniforms = list(
		"Refreshed Talon Command Uniform" = /obj/item/clothing/under/rank/talon/command/refreshed,
		"Old Talon Command Uniform"       = /obj/item/clothing/under/rank/talon/command,
	)
	gear_tweaks += new/datum/gear_tweak/path(selector_uniforms)

/datum/gear/uniform/refreshedtalonpilot
	display_name = "Refreshed Talon Pilot Uniform"
	description = "Select from a range of outfits available to all Talon Pilots."
	allowed_roles = list("Talon Pilot")
	path = /obj/item/clothing/under/rank/talon/pilot/refreshed
	sort_category = "Uniforms"
	cost = 1

/datum/gear/uniform/refreshedtalonpilot/New()
	..()
	var/list/selector_uniforms = list(
		"Refreshed Talon Pilot Uniform" = /obj/item/clothing/under/rank/talon/pilot/refreshed,
		"Old Talon Pilot Uniform"       = /obj/item/clothing/under/rank/talon/pilot,
	)
	gear_tweaks += new/datum/gear_tweak/path(selector_uniforms)

/datum/gear/uniform/refreshedtalonsecurity
	display_name = "Refreshed Talon Security Jumpsuit"
	description = "Select from a range of outfits available to all Talon Guards."
	allowed_roles = list("Talon Guard")
	path = /obj/item/clothing/under/rank/talon/security/refreshed
	sort_category = "Uniforms"
	cost = 1

/datum/gear/uniform/refreshedtalonsecurity/New()
	..()
	var/list/selector_uniforms = list(
		"Refreshed Talon Guard Uniform" = /obj/item/clothing/under/rank/talon/security/refreshed,
		"Old Talon Security Uniform"    = /obj/item/clothing/under/rank/talon/security,
	)
	gear_tweaks += new/datum/gear_tweak/path(selector_uniforms)

/datum/gear/uniform/refreshedtalonmedical
	display_name = "Refreshed Talon Medical Jumpsuit"
	description = "Select from a range of outfits available to all Talon Doctors."
	allowed_roles = list("Talon Doctor")
	path = /obj/item/clothing/under/rank/talon/medical/refreshed
	sort_category = "Uniforms"
	cost = 1

/datum/gear/uniform/refreshedtalonmedical/New()
	..()
	var/list/selector_uniforms = list(
		"Refreshed Talon Doctor Uniform" = /obj/item/clothing/under/rank/talon/medical/refreshed,
		"Old Talon Doctor Uniform"       = /obj/item/clothing/under/rank/talon/medical,
	)
	gear_tweaks += new/datum/gear_tweak/path(selector_uniforms)

/datum/gear/uniform/refreshedtalonengineer
	display_name = "Refreshed Talon Engineer Jumpsuit"
	description = "Select from a range of outfits available to all Talon Engineers."
	allowed_roles = list("Talon Engineer")
	path = /obj/item/clothing/under/rank/talon/engineer/refreshed
	sort_category = "Uniforms"
	cost = 1

/datum/gear/uniform/refreshedtalonengineer/New()
	..()
	var/list/selector_uniforms = list(
		"Refreshed Talon Engineer Uniform" = /obj/item/clothing/under/rank/talon/engineer/refreshed,
		"Old Talon Engineer Uniform"       = /obj/item/clothing/under/rank/talon/engineer,
	)
	gear_tweaks += new/datum/gear_tweak/path(selector_uniforms)

/datum/gear/uniform/refreshedtalonatmos
	display_name = "Refreshed Talon Atmos Tech's Jumpsuit"
	description = "Select from a range of outfits available to all Talon Engineers."
	allowed_roles = list("Talon Engineer")
	path = /obj/item/clothing/under/rank/talon/atmos/refreshed
	sort_category = "Uniforms"
	cost = 1

/datum/gear/uniform/refreshedtalonatmos/New()
	..()
	var/list/selector_uniforms = list(
		"Refreshed Talon Atmospheric Technician Uniform" = /obj/item/clothing/under/rank/talon/atmos/refreshed,
		"Old Talon Talon Atmospheric Technician Uniform" = /obj/item/clothing/under/rank/talon/atmos,
	)
	gear_tweaks += new/datum/gear_tweak/path(selector_uniforms)

/datum/gear/uniform/refreshedtalonminer
	display_name = "Refreshed Talon Miner Jumpsuit"
	description = "Select from a range of outfits available to all Talon Miners."
	allowed_roles = list("Talon Miner")
	path = /obj/item/clothing/under/rank/talon/miner/refreshed
	sort_category = "Uniforms"
	cost = 1

/datum/gear/uniform/refreshedtalonminer/New()
	..()
	var/list/selector_uniforms = list(
		"Refreshed Talon Miner Uniform" = /obj/item/clothing/under/rank/talon/miner/refreshed,
		"Old Talon Miner Uniform"       = /obj/item/clothing/under/rank/talon/miner,
	)
	gear_tweaks += new/datum/gear_tweak/path(selector_uniforms)

/datum/gear/uniform/hfjumpskirt
	display_name = "HYPER jumpskirt"
	path = /obj/item/clothing/under/hyperfiber/skirt
	cost = 2

/datum/gear/uniform/bsjumpsuit
	path = /obj/item/clothing/under/hyperfiber/bluespace
	display_name = "bluespace jumpsuit"
	cost = 4

/datum/gear/uniform/bsjumpskirt
	path = /obj/item/clothing/under/hyperfiber/bluespace/skirt
	display_name = "bluespace jumpskirt"
	cost = 4
