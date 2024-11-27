// Note for newly added quest items: Ckeys should not contain any spaces, underscores or capitalizations,
// or else the item will not be usable.
// Example: Someone whose username is "Master Pred_Man" should be written as "masterpredman" instead
// Note: Do not use characters such as # in the display_name. It will cause the item to be unable to be selected.

/datum/gear/quest
	path = /obj/item
	customize = 0
	sort_category = "Quest Items"
	display_name = "If this item can be chosen or seen, ping a coder immediately!"
	ckeywhitelist = list("This entry should never be choosable with this variable set.") //If it does, then that means somebody fucked up the whitelist system pretty hard
	character_name = list("This entry should never be choosable with this variable set.")
	cost = 0
/*
/datum/gear/quest/ManaSword
	path = /obj/item/weapon/Sword
	display_name = "Mana Sword - Example Item"
	description = "An example item that you probably shouldn't see!"
	ckeywhitelist = list("lira13")
	allowed_roles = list("Influencer")
*/


/datum/gear/quest/collar //Use this as a base path for collars if you'd like to set tags in loadout. Make sure you don't use apostrophes in the display name or this breaks!
	slot = slot_tie

/datum/gear/quest/collar/New()
	..()
	gear_tweaks += gear_tweak_collar_tag



/datum/gear/quest/AncientKatana
	path = /obj/item/weapon/melee/QuestAncientKatana
	display_name = "Ancient Katana"
	ckeywhitelist = list("marlowmouser")
	character_name = list("Aspen Winters")
