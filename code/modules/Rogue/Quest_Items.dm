/obj/item/weapon/melee/QuestAncientKatana
	name = "Ancient Katana"
	desc = "It hums with an unknown energy."
	icon = 'icons/rogue-star/quest_items.dmi'
	icon_state = "ancient_katana"
	item_state = "katana"
	item_icons = list(
		slot_l_hand_str = 'icons/mob/items/lefthand_material.dmi',
		slot_r_hand_str = 'icons/mob/items/righthand_material.dmi',
		)
	slot_flags = SLOT_BELT | SLOT_BACK
	force = 25
	throwforce = 10
	w_class = ITEMSIZE_NORMAL
	sharp = TRUE
	edge = TRUE
	attack_verb = list("attacked", "slashed", "stabbed", "sliced", "torn", "ripped", "diced", "cut")
	hitsound = 'sound/weapons/bladeslice.ogg'
	drop_sound = 'sound/items/drop/sword.ogg'
	pickup_sound = 'sound/items/pickup/sword.ogg'
