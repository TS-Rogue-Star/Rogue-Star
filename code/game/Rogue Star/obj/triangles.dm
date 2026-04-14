/obj/item/triangle
	name = "random triangle coin"
	desc = "A curious triangular coin made primarily of some kind of dark, smooth metal."
	icon = 'icons/rogue-star/coins.dmi'
	icon_state = "1"
	randpixel = 8
	force = 0.5
	throwforce = 0.5
	w_class = ITEMSIZE_TINY
	slot_flags = SLOT_EARS
	drop_sound = 'sound/items/drop/ring.ogg'
	pickup_sound = 'sound/items/pickup/ring.ogg'

	var/value = 0
	var/close_desc = "You shouldn't see this."
	var/value_desc = "No value"

/obj/item/triangle/New()
	if(value <= 0)
		spawn_random_coin()
		return
	randpixel_xy()
	update_icon()

/obj/item/triangle/get_nametag_desc(mob/user)
	return "◬:[value]"

/obj/item/triangle/examine(mob/user)
	if(istype(src.loc,/obj/item/coinstack))
		var/obj/item/coinstack/stack = src.loc
		. = stack.examine(user)
		return .
	. = ..()
	if(Adjacent(user))
		. += SPAN_NOTICE(close_desc)
		. += SPAN_OCCULT("<br>◬:[value]")
		. += span_green(value_desc)

/obj/item/triangle/Moved(atom/old_loc, direction, forced, movetime)
	. = ..()
	update_icon()

/obj/item/triangle/update_icon()
	if(ismob(loc))
		icon_state = "[value]"
	else
		icon_state = "[value]s"

/obj/item/triangle/attackby(obj/item/weapon/W, mob/user)
	if(istriangle(W))
		var/obj/item/coinstack/stack
		if(istype(src.loc,/obj/item/coinstack))
			stack = src.loc
		else
			stack = new(get_turf(src))
			var/pre_loc = src.loc
			stack.stack(src,user)
			if(istype(pre_loc,/obj/item/weapon/storage))
				var/obj/item/weapon/storage/S = pre_loc
				if(S.can_be_inserted(stack))
					S.handle_item_insertion(stack)

		stack.stack(W,user)
		return
	return ..()
/obj/item/triangle/attack_hand(mob/living/user)
	if(istype(src.loc,/obj/item/coinstack))
		var/obj/item/coinstack/stack = src.loc
		stack.attack_hand(user)
		return
	return ..()

/obj/item/triangle/proc/flip_coin(mob/user)
	var/result = rand(1,2)
	var/comment = ""
	if(result == 1)
		comment = "tails"
	else if(result == 2)
		comment = "heads"
	if(loc == user)	//The coin isn't visible so we want the runemessage to be on what's holding it
		user.visible_message(SPAN_NOTICE("[user] has thrown [src]. It lands on [comment]!"), runemessage = "[comment]! ! !")
	else
		if(user)
			visible_message(SPAN_NOTICE("[user] has thrown [src]. It lands on [comment]!"), runemessage = "[comment]! ! !")
		else
			visible_message(SPAN_NOTICE("\The [src] lands on [comment]!"), runemessage = "[comment]! ! !")

/obj/item/triangle/attack_self(mob/user as mob)
	flip_coin(user)

/obj/item/triangle/throw_at(atom/target, range, speed, mob/thrower, spin, datum/callback/callback)
	. = ..()
	flip_coin(thrower)

/////VARIANTS/////

/obj/item/triangle/u02
	name = "bit"
	desc = "A small oval coin made of a smooth dark metal."
	icon_state = "02"
	value = 0.2
	close_desc = "On the front side features a simple triangular design that is split into five sections. The back side depicts an intricate looking scale set in the center of a square design. It is surrounded in writing you don't understand. The edge of the coin is simple smooth metal."
	value_desc = "This is a bit, which is worth one fifth of a tick! It is basic change, which is most commonly used when purchasing small quantities of everyday items."

/obj/item/triangle/u1
	name = "tick"
	desc = "A small triangular coin made of a smooth dark metal."
	icon_state = "1"
	value = 1
	close_desc = "On the front side is a single triangular design. There is a divot in the center that is satisfying to rub. The back side depicts a simple image of someone working the land. It has a nostalgic composition. The edge of the coin has a very subtle bumpy texture. It's easy to hold."
	value_desc = "This is a tick, a basic single, worth about an hour of simple work. This coin is often exchanged for small everyday items, and is a popular choice in games of chance, there is even a game named after it!"

/obj/item/triangle/u5
	name = "tack"
	desc = "A small triangular coin made of a smooth silver metal. It has a small hole in the middle."
	icon_state = "5"
	value = 5
	close_desc = "This coin features a prominent if small circular hole in the center. On the front side are five individual triangles spread evenly across its face around the hole. The back side is an intricate design of a city on a mountain, with the hole at the center seeming to reflect the sun in the sky. It has an impressive composition. There is some writing along the bottom edge that you don't understand. The edge is machined with grooves running between the front and back. This is a tack, it is worth five ticks or half a mark! This coin might cover a prepared meal from a modest eatery."
	value_desc = "This is a tack, it is worth five ticks or half a mark! This coin might cover a prepared meal from a modest eatery."

/obj/item/triangle/u10
	name = "mark"
	desc = "A triangular coin made of a smooth dark metal. It has a oblong hole in the middle lined with a golden colored accent."
	icon_state = "10"
	value = 10
	close_desc = "The hole at the center is oval shaped and seems as if it is exposing a core of golden metal! The gold is very striking against the dark metal. The front of the coin features ten triangle shapes in groups of two, with each pair being angled so as to be inverted from their partner. The groups are spread evenly across the face. The back side depicts a someone mining, their pick striking toward the gold at the center of the coin, the miner is facing away from you. They seem determined. The rest of the back shows a prominent seal surrounded by a pattern that reminds you of a gear. The edge of the coin features ten tiny triangles pressed into the otherwise mirror smooth surface at equal spacing."
	value_desc = "This is a mark, worth ten ticks, or a little under half a glint. This coin represents a day's wage in a basic trade."

/obj/item/triangle/u25
	name = "glint"
	desc = "A triangular coin made of a smooth dark metal. It has a triangular hole in the middle lined with a magenta colored accent. It has intricate designs on it."
	icon_state = "25"
	value = 25
	close_desc = "The hole at the center of this coin is triangular in shape, the hole triangle is in inverted orientation to the shape of the coin itself. Lining the center of the hole is a cloudy purple crystalline material polished such that it's difficult to tell where the metal ends and the crystal begins! The front of the coin features five, five pointed stars scattered evenly across its surface, with yet more of the crystal peeking through the metal near each point of the coin's triangular shape. The back side features an image of a starship angled in the direction of a constellation. The constellation looks like some kind of majestic animal... at least that's what you think it looks like... Each star gives a glimpse into the cloudy purple crystal at the center of the coin. The image has an inspiring composition. The edge of the coin has small regular ridges machined into the surface, and on top of that is a message pressed into the metal in a language you do not understand."
	value_desc = "This is a glint, worth twenty five ticks, or a quarter shine. This coin might cover about a week's rent in a modest home."

/obj/item/triangle/u100
	name = "shine"
	desc = "A triangular coin made of a smooth pearlescent metal. It has a square hole in the center with some kind of crystalline structure running through the center."
	icon_state = "100"
	value = 100
	close_desc = "The large square hole at the center of this coin has a lattice of reflective crystal running through it set in some kind of clear material, like some kind of resin or glass which fills the hole up. The front side of the coin features some very intricate designs of triangles inside of triangles, and what seems like it might be something like a maze or a circuit pattern. The back of the coin features three seals. One resembles a great beast surrounded by a circle and strange symbols. The next resembles a flame surrounded by a simple square. The last one a one is a winged creature flanked in lines of crystal. Each of them look imposing and exact, none taking up more space than the others. It looks very orderly, and each are surrounded by more of those intricate designs. The edge of the coin is smooth, rounded, but with more of the same intricate patterns etched into the surface."
	value_desc = "This is a shine, worth one hundred ticks, or a tenth of a gleam. This is quite a bit of money! One might be able to buy an expensive object with this, or pay for a month's rent in a modest home."

/obj/item/triangle/u1000
	name = "gleam"
	desc = "An ominous looking triangular coin made of black metal. It has strangely reflective yellow accents."
	icon_state = "1000"
	value = 1000
	close_desc = "While it appears somewhat simple, it has very precise edges and a deceptively complicated design. It has a small triangular hole in the center with the same orientation as the coin itself. The metal black metal is polished to an almost mirror finish, so while light seems to streak across its surface when tilted, it seems to defy definition. The front of the coin is broken up into ten segments. Each segment is plane and smooth, but at three points it reveals an almost luminous yellow material inside! It doesn't actually produce light, but it is incredibly reflective! The back side is similar to the front, but each corner bears an different symbol pressed into the metal. The edge of the coin is similarly ridged as the front and the back, but is otherwise smooth and extremely precisely machined. Unlike the other coins, this coin seems to be designed to be viewed with the tip of the coin pointing down."
	value_desc = "This is a gleam, worth one thousand ticks! This is pretty serious money! You could probably live for half a year or more off of the value of a coin like this. This isn't the kind of thing most people would carry around."

///// These are special coins with special iconography on them!
/obj/item/triangle/u7
	name = "seven star coin"
	desc = "A small circular coin made of a smooth dark metal. It depicts seven stars in reflective golden accents."
	icon_state = "7"
	value = 7
	close_desc = "A simple circular coin, on the front showing seven stars, one large one in the center, and three stars to each side. On the back the same symbol is depicted at the top of the coin, with the curve of the horizon stretching out below it. The composition inspires trepidation. The edge of the coin has seven small, equally spaced indents pressed into it. This coin represents cycles, beginnings and ends, life and death."
	value_desc = "This is an uncommon coin of certain cultural significance. It is not normally found in everyday commerce, but it is valid tender worth seven ticks."

/obj/item/triangle/u13
	name = "reservation coin"
	desc = "A small circular coin made of a smooth dark metal. It shows two opposing triangles in gold and magenta colored accents."
	icon_state = "13"
	value = 13
	close_desc = "A simple circular coin, the front side shows two opposing triangles, each one raised from the surface to form a pair of smooth, shallow pyramids. At the very center, where the points of the triangles meet is a deep divot, where light seems to struggle to get in. On the back side, there are quite a few seals and symbols! It doesn't seem to be writing exactly. The symbols are arranged into a three separate constellations that together seem to form a loose triangular shape. The edge of the coin has thirteen symbols pressed into the smooth metal at equal distance from one another. This coin represents different forms of magic energy and their study."
	value_desc = "This is an uncommon coin of certain cultural significance. It is not normally found in everyday commerce, but it is valid tender worth thirteen ticks."

/obj/item/triangle/proc/spawn_random_coin()
	var/list/coins = list(
		/obj/item/triangle/u1 = 5000,
		/obj/item/triangle/u02 = 1000,
		/obj/item/triangle/u5 = 500,
		/obj/item/triangle/u10 = 100,
		/obj/item/triangle/u25 = 1,
		/obj/item/triangle/u7 = 1,
		/obj/item/triangle/u13 = 1
	)
	var/which = pickweight(coins)
	new which(get_turf(src))
	qdel(src)

/////COIN POUCH/////
/obj/item/coinpouch
	name = "coin pouch"
	desc = "A pouch for holding triangle coins."
	icon = 'icons/rogue-star/coins.dmi'
	icon_state = "pouch"
	color = "#5f3c69"
	slot_flags = SLOT_BELT
	var/static/list/overlays_cache = list()
	var/accent_color = "#971504"

/obj/item/coinpouch/New(var/basecolor,var/accentcolor)
	if(basecolor)
		color = basecolor
	if(accentcolor)
		accent_color = accentcolor
	. = ..()
	update_icon()

/obj/item/coinpouch/examine(mob/user)
	. = ..()
	if(loc == user)
		var/count = 0
		var/value = 0
		var/list/other = list()
		for(var/atom/thing in contents)
			if(istriangle(thing))
				count ++
				var/obj/item/triangle/coin = thing
				value += coin.value
			if(!other["[thing.name]"])
				other["[thing.name]"] = 1
			else
				other["[thing.name]"] += 1
		if(count)
			. += span_green("There are [count] coins inside with a total value of ◬:[value].")
		if(other.len)
			. += SPAN_OCCULT("The following is stored inside:")
			for(var/thing in other)
				. += SPAN_NOTICE("[thing] x [other[thing]]")

	. += SPAN_OCCULT("If you use this on help intent, you can pick any coin you like. On harm intent, you will empty \the [src]. On any other intent, you will pick a random coin.")

// Creates a colored icon for use by the Loadout Gallery (Lira, April 2026)
/obj/item/coinpouch/proc/build_colored_icon()
	var/icon/pouch_icon = icon(icon = src.icon, icon_state = src.icon_state, dir = SOUTH, frame = 1, moving = 0)
	if(src.color)
		if(islist(src.color))
			pouch_icon.MapColors(arglist(src.color))
		else
			pouch_icon.Blend(src.color, ICON_MULTIPLY)
	if(src.accent_color)
		var/accent_state = "[src.icon_state]-accent"
		if(accent_state in icon_states(src.icon))
			var/icon/accent_icon = icon(icon = src.icon, icon_state = accent_state, dir = SOUTH, frame = 1, moving = 0)
			if(islist(src.accent_color))
				accent_icon.MapColors(arglist(src.accent_color))
			else
				accent_icon.Blend(src.accent_color, ICON_MULTIPLY)
			pouch_icon.Blend(accent_icon, ICON_OVERLAY)
	return pouch_icon

/obj/item/coinpouch/Destroy()
	empty()
	return ..()

/obj/item/coinpouch/update_icon()
	cut_overlays()

	if(accent_color)
		var/combine_key = "[icon_state]-accent-[accent_color]"
		var/image/contact = overlays_cache[combine_key]
		if(!contact)
			contact = image(icon,null,"[icon_state]-accent")
			contact.color = accent_color
			contact.appearance_flags = RESET_COLOR|KEEP_APART|PIXEL_SCALE
			overlays_cache[combine_key] = contact
		add_overlay(contact)

/obj/item/coinpouch/attackby(obj/item/weapon/W, mob/user)
	if(istriangle(W))
		var/obj/item/triangle/T = W
		user.drop_from_inventory(T)
		T.forceMove(src)
		to_chat(user,SPAN_NOTICE("You place \the [T] into \the [src]."))
	if(istype(W,/obj/item/coinstack))
		user.visible_message(SPAN_WARNING("\The [user] begins scooping \the [W] into \the [src]."),SPAN_NOTICE("You begin scooping \the [W] into \the [src]."),runemessage = "!")
		if(!do_after(user,0.25 * W.contents.len SECONDS,W,exclusive = TRUE))
			user.visible_message(SPAN_WARNING("\The [user] was interrupted."),SPAN_WARNING("You were interrupted."),runemessage = "...")
			return
		var/obj/item/coinstack/stack = W
		for(var/obj/item/triangle/coin in stack.bank())
			coin.forceMove(src)
	if(ismicro(W))
		user.drop_from_inventory(W)
		var/obj/item/weapon/holder/micro/M = W
		if(M.held_mob.client)
			M.forceMove(src)
			to_chat(M.held_mob,SPAN_WARNING("\The [user] shoves you into \the [src]!"))
			to_chat(user,SPAN_NOTICE("You shove \the [M.held_mob] into \the [src]."))

/obj/item/coinpouch/attack_self(mob/user)
	if(loc != user)
		return
	if(contents.len <= 0)
		return
	var/obj/item/triangle/T
	if(user.a_intent == I_HELP)
		T = tgui_input_list(user,"Which one do you want?","[src]",contents)
		if(!T)
			return
	else if(user.a_intent == I_HURT)
		empty()
		user.visible_message(SPAN_DANGER("\The [user] empties \the [src], spilling its contents on the floor!"),SPAN_DANGER("You empty \the [src], spilling its contents on the floor!"),runemessage = "CLINK")
		return

	if(!T)
		take_random_coin(user)
	else
		take_coin(user,T)

/obj/item/coinpouch/attack_hand(mob/living/user)
	if(user.a_intent == I_HELP)
		return ..()
	take_random_coin(user)

/obj/item/coinpouch/resolve_attackby(atom/A, mob/user, attack_modifier, click_parameters)
	if(!collect_coins_from_turf(A,user))
		return ..()

/obj/item/coinpouch/proc/collect_coins_from_turf(var/search,var/mob/living/user)
	var/turf/T
	var/found = FALSE

	if(isturf(search))
		T = search
	else
		T = get_turf(search)

	if(istriangle(search))
		var/obj/item/triangle/coin = search
		if(isturf(coin.loc))
			found = TRUE
	if(isliving(search))
		if(spont_pref_check(user,search,MICRO_PICKUP))
			found = TRUE

	if(!found)
		for(var/thing in T.contents)
			if(istriangle(thing))
				found = TRUE
				break
			if(isliving(thing))
				var/mob/living/L = thing
				if(spont_pref_check(user,L,MICRO_PICKUP))
					found = TRUE
					break

	if(!found)
		return FALSE
	if(!T)
		return FALSE

	user.visible_message(SPAN_WARNING("\The [user] begins scooping things into \the [src]..."),SPAN_NOTICE("You begin scooping things into \the [src]..."),runemessage = ". . .")
	if(do_after(user,0.25 * T.contents.len SECONDS,T,exclusive = TRUE))
		for(var/thing in T.contents)
			if(istriangle(thing))
				var/obj/item/triangle/coin = thing
				coin.forceMove(src)
			if(isliving(thing))
				var/mob/living/L = thing
				if(!L.client)
					continue
				if(!spont_pref_check(user,L,MICRO_PICKUP))
					continue
				if(L.get_effective_size(TRUE) > 0.35)
					continue
				if(!L.holder_type)
					continue
				var/obj/item/weapon/holder/H = new L.holder_type(src,L)
				L.forceMove(H)
				to_chat(L,span_critical("\The [user] scoops you up into \the [src]!!!"))
				to_chat(user,SPAN_DANGER("You scoop \the [user] up into \the [src]!!!"))

		user.visible_message(SPAN_WARNING("\The [user] scoops things into \the [src]!"),SPAN_NOTICE("You scoop things into \the [src]!"),runemessage = "clink ! ! !")
	else
		user.visible_message(SPAN_WARNING("\The [user] was interrupted!"),SPAN_NOTICE("You were interrupted!"),runemessage = "!")

	return TRUE

/obj/item/coinpouch/proc/take_coin(var/mob/living/user,var/obj/item/triangle/coin)
	if(!coin || !user)
		return
	user.face_atom(src)

	if(ismicro(coin))
		var/obj/item/weapon/holder/H = coin
		if(H.held_mob.client)
			to_chat(H.held_mob,span_critical("\The [user] grabs you!!!"))

	if(user.put_in_hands(coin))
		user.visible_message(SPAN_WARNING("\The [user] reaches into \the [src]... and pulls out \the [coin]!"),SPAN_NOTICE("You reach into \the [src] and pull out \the [coin]!"),runemessage = ". . .")
	else
		user.visible_message(SPAN_WARNING("\The [user] reaches into \the [src]... and pulls out \the [coin]!"),SPAN_DANGER("You reach into \the [src] and pull out \the [coin]... your hands are full though so it falls on the floor..."),runemessage = ". . .")
	if(istriangle(coin))
		playsound(get_turf(user),coin.pickup_sound,100,TRUE)

/obj/item/coinpouch/proc/take_random_coin(var/mob/living/user)
	if(contents.len <= 0)
		return
	var/obj/item/triangle/coin = pick(contents)
	take_coin(user,coin)

/obj/item/coinpouch/proc/empty()
	var/turf/ourturf = get_turf(src)
	for(var/thing in contents)
		if(istriangle(thing))
			var/obj/item/triangle/coin = thing
			coin.forceMove(ourturf)
			coin.randpixel_xy()
		if(ismicro(thing))
			var/obj/item/weapon/holder/micro/M = thing
			if(M.held_mob.client)
				to_chat(M.held_mob,SPAN_DANGER("You are dumped out of \the [src]!"))
			M.dump_mob()

/obj/item/coinpouch/proc/bank()
	var/turf/ourturf = get_turf(src)
	var/return_list = list()
	for(var/obj/item/triangle/coin in contents)
		if(!istriangle(coin))
			continue
		coin.forceMove(ourturf)
		return_list += coin

	return return_list

/obj/item/coinpouch/purse
	name = "coin purse"
	desc = "A cute little purse for holding triangle coins! It has a little snap latch for making sure your coins don't fall out!"
	icon_state = "purse"
	color = "#463b55"
	accent_color = "#d6b367"
	slot_flags = SLOT_POCKET

//POUCH VARIANTS

/obj/item/coinpouch/blackgold
	color = "#0f0d14"
	accent_color = "#fabf68"
/obj/item/coinpouch/whitered
	color = "#fff9e4"
	accent_color = "#ff0000"
/obj/item/coinpouch/bluewhite
	color = "#292f66"
	accent_color = "#f7f7f7"
/obj/item/coinpouch/pink
	color = "#da57b2"
	accent_color = "#ffc3dc"
/obj/item/coinpouch/greenblue
	color = "#294928"
	accent_color = "#1900ff"
/obj/item/coinpouch/leather
	color = "#4e3221"
	accent_color = "#ffeaca"
/obj/item/coinpouch/yellowcyan
	color = "#ffeea3"
	accent_color = "#00eeff"
/obj/item/coinpouch/miala
	color = "#694c2b"
	accent_color = "#081c5f"
/obj/item/coinpouch/fire
	color = "#ff5100"
	accent_color = "#ffee00"
/obj/item/coinpouch/blueorange
	color = "#251ab6"
	accent_color = "#ff8800"
/obj/item/coinpouch/blackred
	color = "#242424"
	accent_color = "#ff0000"
/obj/item/coinpouch/retro
	color = "#57805a"
	accent_color = "#223323"
/obj/item/coinpouch/hip
	color = "#ff49d1"
	accent_color = "#ebff3c"
/obj/item/coinpouch/purple
	color = "#6200be"
	accent_color = "#ff00ea"
/obj/item/coinpouch/itg
	name = "ITG coinpouch"
	desc = "A pouch for holding triangle coins. It has the ITG logo on it."
	color = "#5c4530"
	accent_color = "#838383"

/obj/item/coinpouch/purse/blackgold
	color = "#0f0d14"
	accent_color = "#fabf68"
/obj/item/coinpouch/purse/redblack
	color = "#881717"
	accent_color = "#27242e"
/obj/item/coinpouch/purse/bluewhite
	color = "#292f66"
	accent_color = "#f7f7f7"
/obj/item/coinpouch/purse/pink
	color = "#da57b2"
	accent_color = "#ffdeec"
/obj/item/coinpouch/purse/greensilver
	color = "#294928"
	accent_color = "#bae2fd"
/obj/item/coinpouch/purse/leather
	color = "#4e3221"
	accent_color = "#d6b367"
/obj/item/coinpouch/purse/yellowcyan
	color = "#ffeea3"
	accent_color = "#00eeff"
/obj/item/coinpouch/purse/miala
	color = "#694c2b"
	accent_color = "#081c5f"
/obj/item/coinpouch/purse/fire
	color = "#ff5100"
	accent_color = "#ffee00"
/obj/item/coinpouch/purse/blueorange
	color = "#251ab6"
	accent_color = "#ff8800"
/obj/item/coinpouch/purse/blackred
	color = "#242424"
	accent_color = "#ff0000"
/obj/item/coinpouch/purse/retro
	color = "#57805a"
	accent_color = "#223323"
/obj/item/coinpouch/purse/hip
	color = "#ff49d1"
	accent_color = "#ebff3c"
/obj/item/coinpouch/purse/purple
	color = "#6200be"
	accent_color = "#ff00ea"
/obj/item/coinpouch/purse/itg
	name = "ITG coin purse"
	desc = "A cute little purse for holding triangle coins! It has a little snap latch for making sure your coins don't fall out! It has the ITG logo on it."
	color = "#5c4530"
	accent_color = "#838383"

///// Stacked up /////

/obj/item/coinstack
	name = "coin stack"
	desc = "A stack of coins."
	icon = null
	icon_state = null
	plane = MOB_PLANE
	layer = MOB_LAYER
	var/collapsing = FALSE

/obj/item/coinstack/examine(mob/user)
	. = ..()
	var/value = 0
	for(var/thing in contents)
		if(istriangle(thing))
			var/obj/item/triangle/coin = thing
			value += coin.value
	. += SPAN_OCCULT("There are [contents.len] coins in the stack with a total value of ◬:[value].")

/obj/item/coinstack/attackby(obj/item/weapon/W, mob/user)
	. = ..()
	if(istriangle(W))
		stack(W)
	else
		collapse()

/obj/item/coinstack/Destroy()
	if(!collapsing)
		collapse()

	return ..()

/obj/item/coinstack/attack_hand(mob/living/user)
	if(!isturf(loc))
		return ..()
	if(user.a_intent == I_HELP)
		var/obj/item/triangle/coin = contents[contents.len]
		unstack(coin,user)
	else if(user.a_intent == I_GRAB)
		return ..()
	else
		user.visible_message(SPAN_DANGER("\The [user] shoves \the [src]!"),runemessage = "! ! !")
		collapse()

/obj/item/coinstack/proc/stack(var/obj/item/triangle/coin,var/mob/living/user)
	if(!coin)
		return
	if(user)
		user.face_atom(src)
		user.visible_message(SPAN_NOTICE("\The [user] places \the [coin] on top of \the [src]..."),SPAN_NOTICE("You place \the [coin] on top of \the [src]..."),runemessage = ". . .")
	if(isliving(coin.loc))
		var/mob/living/L = coin.loc
		L.drop_from_inventory(coin)
	else if(istype(coin.loc,/obj/item/weapon/storage))
		var/obj/item/weapon/storage/S = coin.loc
		S.remove_from_storage(coin)
	coin.forceMove(src)
	coin.pixel_y = (contents.len - 1) * 2
	coin.pixel_x = rand(0,1)
	vis_contents += coin

	if(contents.len > 10)
		if(prob(contents.len - 10))
			collapse()

/obj/item/coinstack/proc/unstack(var/obj/item/triangle/coin,var/mob/living/user)
	var/turf/ourturf = get_turf(src)
	if(!coin)
		return
	coin.pixel_x = 0
	coin.pixel_y = 0
	vis_contents -= coin
	if(user)
		user.face_atom(src)
		user.put_in_hands(coin)
		user.visible_message(SPAN_WARNING("\The [user] removes a [coin] from \the [src]."), runemessage = ". . .")
		if(istriangle(coin))
			playsound(get_turf(user),coin.pickup_sound,100,TRUE)
		if(contents.len == 1)
			collapse()

	else
		coin.forceMove(ourturf)
		coin.randpixel_xy()

/obj/item/coinstack/proc/collapse()
	if(collapsing)
		return
	collapsing = TRUE
	var/turf/ourturf = get_turf(src)
	if(contents.len > 1)
		ourturf.visible_message(SPAN_DANGER("\The [src] topples over!"),runemessage = "CLATTER ! ! !")
		playsound(ourturf,'sound/items/drop/ring.ogg',100,TRUE)

	for(var/thing in contents)
		unstack(thing)

	if(istype(loc,/obj/item/weapon/storage))
		var/obj/item/weapon/storage/S = loc
		S.remove_from_storage(src)
		ourturf.visible_message(SPAN_DANGER("Coins spill out of \the [S]!!!"),runemessage = "!")

	qdel(src)

/obj/item/coinstack/proc/bank()
	collapsing = TRUE
	var/turf/ourturf = get_turf(src)
	var/return_list = list()
	for(var/obj/item/triangle/coin in contents)
		coin.forceMove(ourturf)
		return_list += coin
	if(isliving(src.loc))
		var/mob/living/L = src.loc
		L.drop_from_inventory(src)
	qdel(src)
	return return_list

///// LOADOUT /////
/datum/gear/utility/coinpouch
	display_name = "coinpouch selection"
	path = /obj/item/coinpouch
	cost = 0

/datum/gear/utility/coinpouch/New()
	..()
	var/variants = list(
		"Purple and red coinpouch" = /obj/item/coinpouch,
		"Black and gold coinpouch" = /obj/item/coinpouch/blackgold,
		"White and red coinpouch" = /obj/item/coinpouch/whitered,
		"Blue and white coinpouch" = /obj/item/coinpouch/bluewhite,
		"Pink coinpouch" = /obj/item/coinpouch/pink,
		"Green and blue coinpouch" = /obj/item/coinpouch/greenblue,
		"Leather coinpouch" = /obj/item/coinpouch/leather,
		"Lira Blue coinpouch" = /obj/item/coinpouch/yellowcyan,
		"Demi-deity coinpouch" = /obj/item/coinpouch/miala,
		"Fire coinpouch" = /obj/item/coinpouch/fire,
		"Blue and orange coinpouch" = /obj/item/coinpouch/blueorange,
		"Black and red coinpouch" = /obj/item/coinpouch/blackred,
		"Retro coinpouch" = /obj/item/coinpouch/retro,
		"Hip coinpouch" = /obj/item/coinpouch/hip,
		"Purple coinpouch" = /obj/item/coinpouch/purple,
		"ITG coinpouch" = /obj/item/coinpouch/itg,
		"Purple and gold coinpurse" = /obj/item/coinpouch/purse,
		"Black and gold coinpurse" = /obj/item/coinpouch/purse/blackgold,
		"Red and black coinpurse" = /obj/item/coinpouch/purse/redblack,
		"Blue and white coinpurse" = /obj/item/coinpouch/purse/bluewhite,
		"Pink coinpurse" = /obj/item/coinpouch/purse/pink,
		"Green and silver coinpurse" = /obj/item/coinpouch/purse/greensilver,
		"Leather coinpurse" = /obj/item/coinpouch/purse/leather,
		"Lira Blue coinpurse" = /obj/item/coinpouch/purse/yellowcyan,
		"Demi-deity coinpurse" = /obj/item/coinpouch/purse/miala,
		"Fire coinpurse" = /obj/item/coinpouch/purse/fire,
		"Blue and orange coinpurse" = /obj/item/coinpouch/purse/blueorange,
		"Black and red coinpurse" = /obj/item/coinpouch/purse/blackred,
		"Retro coinpurse" = /obj/item/coinpouch/purse/retro,
		"Hip coinpurse" = /obj/item/coinpouch/purse/hip,
		"Purple coinpurse" = /obj/item/coinpouch/purse/purple,
		"ITG coinpurse" = /obj/item/coinpouch/purse/itg
	)
	gear_tweaks += new/datum/gear_tweak/path(variants)
