//RS CUSTOM FLUFF CLOTHING BEGIN

//GooglyFox:Portal
/obj/item/clothing/head/soft/fluff/portalsoft
	name = "pizza station employee baseball cap"
	desc = "A deep red baseball cap with a small pizza station logo on the back, and the front of the baseball cap is the pizza station logo, and the name \"Pizza Station\", it fits pretty well, it has some faint initials on the inside, \"P\". You can smell a subtle whiff of pizza."
	icon = 'icons/vore/custom_clothes_rs.dmi'
	icon_override = 'icons/vore/custom_onmob_rs.dmi'
	icon_state = "portalsoft"
	item_state_slots = list(slot_r_hand_str = "redsoft", slot_l_hand_str = "redsoft")

//GooglyFox:Portal
/obj/item/clothing/mask/fluff/portal_mask
	name = "Portal's Mask"
	desc = "A shiny black, crystalline skull-like mask that shimmers in the light, its basically indestructible to most conventional methods, these are usually seen more commonly as white in Portal's species, it still has that latexy feel to it. It smells strongly of oranges and cream."
	icon = 'icons/vore/custom_clothes_rs.dmi'
	icon_override = 'icons/vore/custom_onmob_rs.dmi'
	icon_state = "portalmask"
	item_state = "portalmask_mob"
	item_state_slots = null
	body_parts_covered = FACE
	flags_inv = HIDEFACE
	item_flags = FLEXIBLEMATERIAL|AIRTIGHT
	protean_drop_whitelist = TRUE
//Make indigestible
/obj/item/clothing/mask/fluff/portal_mask/digest_act(var/atom/movable/item_storage = null)
	return FALSE

//GooglyFox:Portal
/obj/item/clothing/suit/storage/fluff/jacket/portaljacket
	name = "pizza station delivery windbreaker"
	desc = "A slick, lightweight white and red pizza station branded button-up windbreaker made with a water-resistant coating polyester exterior, lined with fleece, a comfortable, soft interior to keep the delivery person warm, it has a patch on the right breast, with a \"SAFE DRIVER\", and below it on the same patch dawns the pizza station logo of a rocket. Lower on that side is the name \"Portal\", and on the left breast the logo is once again used, with \"DELIVERY\" written below it. Smells like pizza sauce and cheese."
	icon = 'icons/vore/custom_clothes_rs.dmi'
	icon_override = 'icons/vore/custom_onmob_rs.dmi'
	icon_state = "portaljacket"
	item_state = "portaljacket_mob"
	body_parts_covered = UPPER_TORSO|LOWER_TORSO|ARMS
	cold_protection = UPPER_TORSO|LOWER_TORSO|ARMS
	min_cold_protection_temperature = SPACE_SUIT_MIN_COLD_PROTECTION_TEMPERATURE

//GooglyFox:Portal
/obj/item/clothing/under/fluff/portaluniform
	name = "portal's uniform"
	desc = "A clean, comfy turtleneck in a deep orange color, atop some black jeans which itself is buckled on with a belt dawned with a golden belt buckle in the shape of Nanotrasen's logo. It smells vibrantly of oranges and cream."
	icon = 'icons/vore/custom_clothes_rs.dmi'
	icon_override = 'icons/vore/custom_onmob_rs.dmi'
	icon_state = "portaluniform"
	item_state = "portaluniform_mob"
	body_parts_covered = UPPER_TORSO|LOWER_TORSO|LEGS

//GooglyFox:Portal
/obj/item/clothing/under/fluff/portaluniform2
	name = "pizza station employee uniform"
	desc = "A clean, kempt dress shirt in a deep red color, atop some grey slacks which itself is buckled on with a belt dawned with a silver belt buckle in the shape of a pizza, there's a shape of a rocket on the back in a bright red color with the text \"PIZZA STATION\" written below the logo. There's a nametag on the chest, it reads \"Portal\", it smells vibrantly of oranges and pizza."
	icon = 'icons/vore/custom_clothes_rs.dmi'
	icon_override = 'icons/vore/custom_onmob_rs.dmi'
	icon_state = "portaluniform2"
	item_state = "portaluniform2_mob"
	body_parts_covered = UPPER_TORSO|LOWER_TORSO|LEGS

//GooglyFox:Portal
/obj/item/clothing/gloves/fluff/portalgloves
	name = "work gloves with wedding ring"
	desc = "Some heavy duty work gloves meant for carrying pizzas without your fingers getting cold. It has a golden ring on the left hand on the middle finger, it glimmers brightly with some engraved text, \"T.O.A.S.T.E.R.\". There's also the name \"Portal\" engraved on the inside of the ring."
	icon = 'icons/vore/custom_clothes_rs.dmi'
	icon_override = 'icons/vore/custom_onmob_rs.dmi'
	icon_state = "portalgloves"
	item_state = "portalgloves_mob"

//GooglyFox:Portal
/obj/item/clothing/shoes/boots/fluff/portalboots
	name = "work boots"
	desc = "Some heavy duty work boots meant for long walks and harsh weather or environments. They're pretty loud wherever the person wearing them walk due to being so heavy-duty."
	icon = 'icons/vore/custom_clothes_rs.dmi'
	icon_override = 'icons/vore/custom_onmob_rs.dmi'
	icon_state = "portalboots"
	item_state = "portalboots_mob"

//GooglyFox:Portal
/obj/item/weapon/storage/backpack/satchel/fluff/portalbag
	name = "pizza station delivery satchel"
	desc = "A clunky, heavy white and red pizza station branded satchel with a insulated interior to keep your food warm, and drinks cold, with seperate spots in the bag for each to sit without making eachother warmer or colder! Truly modern technology. The bag also comes with a \"DELIVERY\" patch on the bag, and the pizza station logo on the flap. It smells like pepperoni!"
	icon = 'icons/vore/custom_clothes_rs.dmi'
	icon_override = 'icons/vore/custom_onmob_rs.dmi'
	icon_state = "portalbag"
	item_state = "portalbag_mob"
	slowdown = 0.4
	max_storage_space = ITEMSIZE_COST_NORMAL * 8 // FOR THE PIZZAS AND DRINKS!
