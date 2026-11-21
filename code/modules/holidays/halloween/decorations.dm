/obj/item/decoration
	name = "decoration"
	desc = "A festive decoration."
	icon = 'icons/holidays/halloween/decorations.dmi'
	w_class = ITEMSIZE_SMALL
	var/random = FALSE
	var/variations = 1
	var/glow_icon_state

/obj/item/decoration/Initialize(mapload)
	. = ..()
	if(random && variations > 1)
		icon_state = "[rand(1, variations)]"
	update_icon()

/obj/item/decoration/garland
	name = "garland"
	anchored = TRUE
	var/icon_state_off = "garland"
	var/list/light_colors
	var/current_color

/obj/item/decoration/garland/Initialize(mapload)
	. = ..()
	if(random)
		var/v_num = rand(1, variations)
		icon_state_off = "garland_[v_num]"
		glow_icon_state = "garland_[v_num]_lights"

	icon_state = icon_state_off

	if(LAZYLEN(light_colors))
		current_color = pick(light_colors)
		set_light(2, 1, current_color)

	update_icon()

/obj/item/decoration/garland/update_icon()
	cut_overlays()
	icon_state = icon_state_off

	if(glow_icon_state)
		var/mutable_appearance/glow = mutable_appearance(icon, glow_icon_state)
		glow.plane = PLANE_LIGHTING_ABOVE
		if(current_color)
			glow.color = current_color
		add_overlay(glow)

/obj/item/decoration/tinsel
	name = "tinsel"
	anchored = TRUE

/obj/item/decoration/halloween
	desc = "Everybody scream!"
	icon = 'icons/holidays/halloween/decorations.dmi'
	icon_state = "1"

/obj/item/weapon/carved_pumpkin
	name = "carved pumpkin"
	desc = "Everybody hail to the pumpkin song!"
	icon = 'icons/holidays/halloween/decorations.dmi'
	icon_state = "pumpkin"
	var/icon_state_off = "pumpkin"
	var/glow_icon_state
	var/obj/item/weapon/flame/candle/candle
	var/candled = FALSE

/obj/item/weapon/carved_pumpkin/candled
	candled = TRUE

/obj/item/weapon/carved_pumpkin/Initialize(mapload)
	. = ..()
	icon_state_off = "pumpkin_[rand(1, 8)]"
	glow_icon_state = "[icon_state_off]_light"
	icon_state = icon_state_off

	if(candled)
		candle = new /obj/item/weapon/flame/candle(src)
		candle.light()
		update_icon()

/obj/item/weapon/carved_pumpkin/Destroy()
	QDEL_NULL(candle)
	return ..()

/obj/item/weapon/carved_pumpkin/update_icon()
	cut_overlays()

	if(candle)
		icon_state = "[icon_state_off]_on"
		set_light(3, 1, candle.light_color ? candle.light_color : "#FF8800")

		if(glow_icon_state)
			var/mutable_appearance/glow = mutable_appearance(icon, glow_icon_state)
			glow.plane = PLANE_LIGHTING_ABOVE
			add_overlay(glow)
	else
		icon_state = icon_state_off
		set_light(0)

/obj/item/weapon/carved_pumpkin/attackby(obj/item/W, mob/user)
	if(istype(W, /obj/item/weapon/flame/candle) && !candle)
		var/obj/item/weapon/flame/candle/new_candle = W
		if(!new_candle.lit)
			return
		user.drop_from_inventory(new_candle, src)
		candle = new_candle
		update_icon()
		return
	return ..()

/obj/item/weapon/carved_pumpkin/attack_self(mob/user)
	. = ..()
	if(!candle)
		return

	if(do_after(user, 5, target = src))
		user.put_in_hands(candle)
		candle = null
		update_icon()

// Garland
/obj/item/decoration/garland/halloween
	desc = "Beautiful lights! Shinee!"
	icon = 'icons/holidays/halloween/decorations.dmi'
	icon_state = "garland"
	light_colors = list("#f8731e", "#ffd401", "#ef0001")
	random = TRUE
	variations = 7

/obj/item/decoration/garland/halloween/long
	icon_state = "garland_1"
	icon_state_off = "garland_1"
	glow_icon_state = "garland_1_lights"
	random = FALSE

/obj/item/decoration/garland/halloween/medium
	icon_state = "garland_2"
	icon_state_off = "garland_2"
	glow_icon_state = "garland_2_lights"
	random = FALSE

/obj/item/decoration/garland/halloween/short
	icon_state = "garland_3"
	icon_state_off = "garland_3"
	glow_icon_state = "garland_3_lights"
	random = FALSE

// Tinsels
/obj/item/decoration/tinsel/halloween
	desc = "Everybody scream! Everybody scream! In our town of Halloween!"
	icon = 'icons/holidays/halloween/tinsel.dmi'
	icon_state = "1"
	layer = 3.3
	variations = 20
	random = TRUE

/obj/item/decoration/tinsel/halloween/pumkings
	icon_state = "1"
	random = FALSE

/obj/item/decoration/tinsel/halloween/ghosts
	icon_state = "2"
	random = FALSE

/obj/item/decoration/tinsel/halloween/bats
	icon_state = "14"
	random = FALSE
