//RS FILE
/obj/item/key
	name = "key"
	desc = "A small key made out of some kind of metal."
	icon = 'icons/rogue-star/keys.dmi'
	icon_state = "key"
	persist_storable = FALSE
	w_class = ITEMSIZE_TINY
	drop_sound = 'sound/items/drop/ring.ogg'
	pickup_sound = 'sound/items/pickup/ring.ogg'
/obj/item/key/Initialize()
	. = ..()
	pixel_x = rand(-8,8)
	pixel_y = rand(-8,8)
	if(icon_state == "key")
		icon_state  = "[icon_state]-[rand(1,6)]"
		color = "#b4cacc"
/obj/item/key/big
	name = "big key"
	desc = "It looks quite menacing! Upon very close inspection, there are some impossibly complicated and detailed engravings on this key."
	icon_state = "big-key"
	color = "#bb883b"

/obj/item/key/scifi
	desc = "A small electronic card with a plastic case, with one end bearing exposed contact points for plugging into an electronic lock."
	icon_state = "scifi-a"
	drop_sound = 'sound/items/drop/device.ogg'
	pickup_sound = 'sound/items/pickup/device.ogg'
	var/static/list/overlays_cache = list()
	var/contact_color = "#f7b947"

/obj/item/key/scifi/Initialize()
	. = ..()
	update_icon()

/obj/item/key/scifi/update_icon()
	cut_overlays()
	if(contact_color)
		var/combine_key = "[icon_state]-contacts-[contact_color]"
		var/image/contact = overlays_cache[combine_key]
		if(!contact)
			contact = image(icon,null,"[icon_state]-contacts")
			contact.color = contact_color
			contact.appearance_flags = RESET_COLOR|KEEP_APART|PIXEL_SCALE
			overlays_cache[combine_key] = contact
		add_overlay(contact)

/obj/item/key/scifi/big
	icon_state = "scifi-b"
	desc = "A broad electronic card with a solid metal case. One end has precisely machined contacts exposed for plugging into an electronic lock."
	var/case_color = "#776f85"

/obj/item/key/scifi/big/update_icon()
	. = ..()
	if(case_color)
		var/combine_key = "[icon_state]-case-[case_color]"
		var/image/case = overlays_cache[combine_key]
		if(!case)
			case = image(icon,null,"[icon_state]-case")
			case.color = case_color
			case.appearance_flags = RESET_COLOR|KEEP_APART|PIXEL_SCALE
			overlays_cache[combine_key] = case
		add_overlay(case)

/obj/item/key/scifi/red
	color = "#ff0000"
/obj/item/key/scifi/blue
	color = "#003cff"
/obj/item/key/scifi/yellow
	color = "#ffd900"
/obj/item/key/scifi/magenta
	color = "#cc00ff"

/obj/item/key/scifi/big/red
	color = "#ff0000"
	case_color = "#6b5c5c"
/obj/item/key/scifi/big/blue
	color = "#003cff"
	case_color = "#545c5c"
/obj/item/key/scifi/big/yellow
	color = "#ffd900"
	case_color = "#7e5c5c"
/obj/item/key/scifi/big/magenta
	color = "#cc00ff"
	case_color = "#5a5c5c"

/obj/item/key/card
	name = "key card"
	desc = "A small rectangular card with a magnet strip running along one side."
	icon_state = "card"
	drop_sound = 'sound/items/drop/card.ogg'
	pickup_sound = 'sound/items/pickup/card.ogg'

/obj/item/key/card/red
	color = "#ff0000"
/obj/item/key/card/blue
	color = "#003cff"
/obj/item/key/card/yellow
	color = "#ffd900"
/obj/item/key/card/magenta
	color = "#cc00ff"
