/datum/gear/eyes/big_round
	display_name = "big round glasses selection"
	path = /obj/item/clothing/glasses/big_round

/datum/gear/eyes/big_round/New()
	..()
	var/list/big_round_glasses = list()
	for(var/obj/item/clothing/glasses/big_round/glasses as anything in typesof(/obj/item/clothing/glasses/big_round))
		big_round_glasses[initial(glasses.name)] = glasses
	gear_tweaks += new/datum/gear_tweak/path(sortAssoc(big_round_glasses))
