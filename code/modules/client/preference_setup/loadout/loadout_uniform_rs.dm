// New Talon Uniforms
/datum/gear/uniform/talon
	display_name = "Talon Uniforms"
	description = "Select from a range of outfits available to all Talon crews."
	allowed_roles = list("Talon Captain","Talon Doctor","Talon Engineer","Talon Pilot","Talon Guard","Talon Miner")
	path = /obj/item/clothing/under/rank/talon/basic/refreshed
	sort_category = "Uniforms"
	cost = 1

/datum/gear/uniform/talon/New()
	..()
	var/list/selector_uniforms = list(
		"Refreshed Talon crew Uniform"=/obj/item/clothing/under/rank/talon/basic/refreshed,
		"Old Talon crew Uniform"=/obj/item/clothing/under/rank/talon/basic,
	)
	gear_tweaks += new/datum/gear_tweak/path(sortAssoc(selector_uniforms))

/datum/gear/uniform/talon_captain
	display_name = "Talon - Captain Uniforms"
	description = "Select from a range of outfits available to all Talon Captain."
	allowed_roles = list("Talon Captain")
	path = /obj/item/clothing/under/rank/talon/command/refreshed
	sort_category = "Uniforms"
	cost = 1

/datum/gear/uniform/talon_captain/New()
	..()
	var/list/selector_uniforms = list(
		"Refreshed Talon Command Uniform"=/obj/item/clothing/under/rank/talon/command/refreshed,
		"Old Talon Command Uniform"=/obj/item/clothing/under/rank/talon/command,
	)
	gear_tweaks += new/datum/gear_tweak/path(sortAssoc(selector_uniforms))

/datum/gear/uniform/talon_pilot
	display_name = "Talon - Pilot Uniforms"
	description = "Select from a range of outfits available to all Talon Pilot."
	allowed_roles = list("Talon Pilot")
	path = /obj/item/clothing/under/rank/talon/pilot/refreshed
	sort_category = "Uniforms"
	cost = 1

/datum/gear/uniform/talon_pilot/New()
	..()
	var/list/selector_uniforms = list(
		"Refreshed Talon Pilot Uniform"=/obj/item/clothing/under/rank/talon/pilot/refreshed,
		"Old Talon Pilot Uniform"=/obj/item/clothing/under/rank/talon/pilot,
	)
	gear_tweaks += new/datum/gear_tweak/path(sortAssoc(selector_uniforms))

/datum/gear/uniform/talon_security
	display_name = "Talon - Guard Uniforms"
	description = "Select from a range of outfits available to all Talon Guard."
	allowed_roles = list("Talon Guard")
	path = /obj/item/clothing/under/rank/talon/security/refreshed
	sort_category = "Uniforms"
	cost = 1

/datum/gear/uniform/talon_security/New()
	..()
	var/list/selector_uniforms = list(
		"Refreshed Talon Guard Uniform"=/obj/item/clothing/under/rank/talon/security/refreshed,
		"Old Talon Security Uniform"=/obj/item/clothing/under/rank/talon/security,
	)
	gear_tweaks += new/datum/gear_tweak/path(sortAssoc(selector_uniforms))

/datum/gear/uniform/talon_medical
	display_name = "Talon - Doctor Uniforms"
	description = "Select from a range of outfits available to all Talon Doctor's."
	allowed_roles = list("Talon Doctor")
	path = /obj/item/clothing/under/rank/talon/proper/refreshed
	sort_category = "Uniforms"
	cost = 1

/datum/gear/uniform/talon_medical/New()
	..()
	var/list/selector_uniforms = list(
		"Refreshed Talon Doctor Uniform"=/obj/item/clothing/under/rank/talon/proper/refreshed,
		"Old Talon Doctor Uniform"=/obj/item/clothing/under/rank/talon/proper,
	)
	gear_tweaks += new/datum/gear_tweak/path(sortAssoc(selector_uniforms))

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
