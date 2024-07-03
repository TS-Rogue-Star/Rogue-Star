/*
Custom Description (for collars)
*/
var/datum/gear_tweak/custom_desc/collar/gear_tweak_collar_desc = new()

/datum/gear_tweak/custom_desc/collar/tweak_item(var/obj/item/clothing/accessory/collar/C, var/metadata)
	if(!istype(C))
		log_error("Attempted to customize collar '[C]' which is type '[C?.type]' and not a collar!")
		return
	if(!metadata)
		return
	C.custom_desc = metadata
