/obj/item/decoration/halloween
	desc = "Everybody scream!"
	icon = 'icons/holidays/halloween/decorations.dmi'
	icon_state = "1"

/obj/item/weapon/carved_pumpkin
	name = "carved pumpkin"
	desc = "Everybody hail to the pumkin song!"
	icon = 'icons/holidays/halloween/decorations.dmi'
	icon_state = "pumpkin"
	var/icon_state_off = "pumpkin"
	var/glow_icon_state = ""
	var/obj/item/candle/candle
	var/candled = FALSE

/obj/item/weapon/carved_pumpkin/candled
	candled = TRUE

/obj/item/weapon/carved_pumpkin/atom_init()
	. = ..()
	icon_state_off = "pumpkin_[rand(1, 8)]"
	glow_icon_state = "[icon_state_off]_light"
	icon_state = icon_state_off

	if(candled)
		candle = new(src)
		if(hasproc(candle, "light"))
			candle.light()
		update_icon()

/obj/item/weapon/carved_pumpkin/update_icon()
	overlays.Cut()

	if(candle)
		icon_state = "[icon_state_off]_on"

		// Настройка динамического освещения (света вокруг)
		if(candle.light_color)
			set_light(3, 1, candle.light_color)
		else
			set_light(3, 1, "#FF8800") // Дефолтный оранжевый свет, если у свечи нет цвета

		// РЕНДЕР СВЕЧЕНИЯ ТЫКВЫ В ТЕМНОТЕ ДЛЯ ROGUE STAR
		if(glow_icon_state)
			var/mutable_appearance/glow = mutable_appearance(icon, glow_state = "[icon_state_off]_on") // Используем стейт включенной тыквы как основу, либо glow_icon_state если там маска глазами
			// Если в Tau Ceti стейт свечения содержал только глаза, используем его:
			glow = mutable_appearance(icon, glow_icon_state)
			glow.plane = PLANE_LIGHTING_ABOVE
			overlays += glow
	else
		icon_state = icon_state_off
		set_light(0)


/obj/item/weapon/carved_pumpkin/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/candle) && !candle)
		var/obj/item/candle/new_candle = I
		if(!new_candle.lit)
			return
		user.drop_from_inventory(new_candle, src)
		candle = new_candle
		update_icon()
		return
	return ..()

/obj/item/weapon/carved_pumpkin/attack_self(mob/user)
	. = ..()
	if(!candle || (hasproc(user, "is_busy") && user.is_busy()))
		return

	if(do_after(user, 5, target = src))
		user.put_in_hands(candle)
		candle = null
		update_icon()

// Garland
/obj/item/decoration/garland/halloween
	name = "halloween garland"
	desc = "Beautiful lights! Shinee!"
	icon = 'icons/holidays/halloween/decorations.dmi'
	icon_state = "garland"

	var/icon_state_off = "garland"
	var/glow_icon_state = "garland_lights"
	var/list/light_colors = list("#f8731e", "#ffd401", "#ef0001")
	var/random = TRUE
	var/variations = 7
	var/current_color = "#FFD700"

/obj/item/decoration/garland/halloween/Initialize(mapload)
	. = ..()
	if(random)
		var/v_num = rand(1, variations)
		icon_state_off = "garland_[v_num]"
		glow_icon_state = "garland_[v_num]_lights"

	icon_state = icon_state_off
	if(light_colors && light_colors.len)
		current_color = pick(light_colors)

	set_light(2, 1, current_color)
	update_icon()

/obj/item/decoration/garland/halloween/update_icon()
	overlays.Cut()
	icon_state = icon_state_off

	// Наложение маски свечения диодов гирлянды поверх темноты
	if(glow_icon_state)
		var/mutable_appearance/lights = mutable_appearance(icon, glow_icon_state)
		lights.plane = PLANE_LIGHTING_ABOVE
		lights.color = current_color // Красим белые лампочки в выбранный цвет гирлянды
		overlays += lights

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
	variations = 20
	random = TRUE

/obj/item/decoration/tinsel/halloween/Initialize(mapload)
	. = ..()
	if(random)
		icon_state = "[rand(1, variations)]"

/obj/item/decoration/tinsel/halloween/pumkings
	icon_state = "1"
	random = FALSE

/obj/item/decoration/tinsel/halloween/ghosts
	icon_state = "2"
	random = FALSE

/obj/item/decoration/tinsel/halloween/bats
	icon_state = "14"
	random = FALSE
