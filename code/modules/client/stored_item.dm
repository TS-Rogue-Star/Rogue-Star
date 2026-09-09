/obj/machinery/item_bank
	name = "electronic lockbox"
	desc = "A place to store things you might want later!"
	icon = 'icons/obj/stationobjs_vr.dmi'
	icon_state = "item_bank"
	idle_power_usage = 1
	active_power_usage = 5
	anchored = TRUE
	density = FALSE
	var/busy_bank = FALSE
	var/static/list/item_takers = list()
	var/static/list/unlockable_takers = list()	//RS ADD
	// RS Add Start: New Item Bank Interface (Lira, March 2026)
	var/static/list/item_preview_cache = list()
	var/const/general_compartment_capacity = 50
	var/static/personal_compartment_capacity = null
	// RS Add End

/obj/machinery/item_bank/proc/persist_item_savefile_path(mob/user)
	return "data/player_saves/[copytext(user.ckey, 1, 2)]/[user.ckey]/persist_item.sav"

/obj/machinery/item_bank/proc/persist_item_savefile_save(mob/user, obj/item/O)
	if(IsGuestKey(user.key))
		return 0

	var/savefile/F = new /savefile(src.persist_item_savefile_path(user))

	F["persist item"] << O.type
	F["persist name"] << initial(O.name)

	return 1

/obj/machinery/item_bank/proc/persist_item_savefile_load(mob/user, thing)
	if (IsGuestKey(user.key))
		return 0

	var/path = src.persist_item_savefile_path(user)

	if (!fexists(path))
		return 0

	var/savefile/F = new /savefile(path)

	if(!F) return 0

	var/persist_item
	F["persist item"] >> persist_item

	if (isnull(persist_item) || !ispath(persist_item))
		fdel(path)
		tgui_alert_async(user, "An item could not be retrieved.")
		return 0
	if(thing == "type")
		return persist_item
	if(thing == "name")
		var/persist_name
		F["persist name"] >> persist_name
		return persist_name

//RS ADD START
/obj/machinery/item_bank/proc/legacy_detect(mob/living/user)
	if (fexists(src.persist_item_savefile_path(user)))
		return TRUE
	return FALSE
//RS ADD END

/obj/machinery/item_bank/Initialize()
	. = ..()

// RS Edit Start: New Item Bank Interface (Lira, March 2026)
/obj/machinery/item_bank/attack_hand(mob/living/user)
	. = ..()
	if(!can_use_bank(user, announce = TRUE))
		return
	start_using(user)

/obj/machinery/item_bank/proc/start_using(mob/living/user)
	if(!can_use_bank(user, announce = TRUE))
		return
	if(busy_bank)
		to_chat(user, "<span class='warning'>\The [src] is already in use.</span>")
		return
	busy_bank = TRUE
	if(legacy_detect(user))
		if(tgui_alert(user, "A legacy item has been detected in storage. This item must be bound to a character. Would you like to add it to [user.real_name]'s general storage?", "[src] legacy item detected", list("Yes","No"), timeout = 10 SECONDS) == "Yes")
			var/itemname = persist_item_savefile_load(user, "name")
			var/itemtype = persist_item_savefile_load(user, "type")
			user.etching.legacy_conversion(itemname,itemtype)
			var/path = src.persist_item_savefile_path(user)
			fdel(path)
			log_debug("<span class = 'danger'>[user]/[user.ckey] converted a legacy item persist file to an item_storage state. Item was, [itemname] - [itemtype]</span>")
			busy_bank = FALSE
			return
	busy_bank = FALSE
	tgui_interact(user)

/obj/machinery/item_bank/tgui_state(mob/user)
	return GLOB.tgui_physical_state

/obj/machinery/item_bank/tgui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ItemBank", name)
		ui.open()
		user.playsound_local(get_turf(src), 'sound/rogue-star/lockbox jingle.ogg', 50, FALSE)

/obj/machinery/item_bank/proc/can_use_bank(mob/living/user, announce = FALSE)
	if(!ishuman(user) || !Adjacent(user))
		return FALSE
	if(inoperable() || panel_open)
		if(announce)
			to_chat(user, "<span class='warning'>\The [src] seems to be nonfunctional...</span>")
		return FALSE
	return TRUE

/obj/machinery/item_bank/proc/get_info_text()
	return "The lockbox can store items for you between shifts. Anything that has been retrieved from the general compartment cannot be stored again in the same shift. Anyone can withdraw from the general compartment one time per shift. Some items are not accepted by the lockbox."

/obj/machinery/item_bank/proc/resolve_item_type(var/item_type)
	if(ispath(item_type))
		return item_type
	if(istext(item_type))
		return text2path(item_type)
	return null

/obj/machinery/item_bank/proc/is_personal_item_claimed(mob/living/carbon/human/user, var/item_name, var/item_type)
	if(!user || !istext(item_name))
		return FALSE

	var/claimed_key = "[user.real_name] - [item_name]"
	if(claimed_key in unlockable_takers)
		return TRUE

	if(ispath(item_type))
		var/default_name = "[initial(item_type:name)]"
		if(istext(default_name) && length(default_name) && default_name != item_name)
			var/default_claimed_key = "[user.real_name] - [default_name]"
			if(default_claimed_key in unlockable_takers)
				return TRUE

	return FALSE

/obj/machinery/item_bank/proc/get_unlockable_display_name(var/item_name, var/item_type)
	if(item_name == "unlockable_name" && ispath(item_type))
		return "[initial(item_type:name)]"
	return item_name

/obj/machinery/item_bank/proc/get_type_preview(var/item_type)
	if(!ispath(item_type))
		return null

	var/icon_ref = initial(item_type:icon)
	if(!icon_ref)
		return null

	var/icon_state = initial(item_type:icon_state)
	var/cache_key = "[item_type]|[icon_ref]|[icon_state]"
	if(cache_key in item_preview_cache)
		var/cached_preview = item_preview_cache[cache_key]
		return length(cached_preview) ? cached_preview : null

	var/icon/preview_icon = icon(icon_ref, icon_state ? icon_state : "", SOUTH, 1, FALSE)
	var/encoded_preview = null
	if(preview_icon)
		encoded_preview = icon2base64(preview_icon)
	if(!istext(encoded_preview))
		encoded_preview = null

	item_preview_cache[cache_key] = encoded_preview ? encoded_preview : ""
	return encoded_preview ? encoded_preview : null

/obj/machinery/item_bank/proc/get_general_entries(mob/living/carbon/human/user)
	var/list/entries = list()
	if(!user || !user.etching || !islist(user.etching.item_storage) || !user.etching.item_storage.len)
		return entries

	var/list/item_keys = list()
	for(var/item_name in user.etching.item_storage)
		item_keys += "[item_name]"
	item_keys = sortList(item_keys)

	for(var/item_name in item_keys)
		var/raw_type = user.etching.item_storage[item_name]
		var/item_type = resolve_item_type(raw_type)
		entries += list(list(
			"id" = item_name,
			"label" = item_name,
			"type" = item_type ? "[item_type]" : "[raw_type]",
			"preview" = get_type_preview(item_type)
		))

	return entries

/obj/machinery/item_bank/proc/get_personal_entries(mob/living/carbon/human/user)
	var/list/entries = list()
	if(!user || !user.etching || !islist(user.etching.unlockables) || !user.etching.unlockables.len)
		return entries

	var/list/item_keys = list()
	for(var/item_name in user.etching.unlockables)
		item_keys += "[item_name]"
	item_keys = sortList(item_keys)

	for(var/item_name in item_keys)
		var/raw_type = user.etching.unlockables[item_name]
		var/item_type = resolve_item_type(raw_type)
		var/display_name = get_unlockable_display_name(item_name, item_type)
		entries += list(list(
			"id" = item_name,
			"label" = display_name,
			"type" = item_type ? "[item_type]" : "[raw_type]",
			"preview" = get_type_preview(item_type),
			"claimed" = is_personal_item_claimed(user, item_name, item_type)
		))

	return entries

/obj/machinery/item_bank/proc/get_personal_capacity()
	if(isnum(personal_compartment_capacity))
		return personal_compartment_capacity

	var/list/name_registry = list()
	if(islist(permanent_unlockables))
		for(var/raw_type in permanent_unlockables)
			var/item_type = resolve_item_type(raw_type)
			if(!ispath(item_type))
				continue
			var/item_name = initial(item_type:name)
			if(!istext(item_name) || !length(item_name))
				continue
			name_registry[item_name] = TRUE

	personal_compartment_capacity = name_registry.len
	return personal_compartment_capacity

/obj/machinery/item_bank/tgui_data(mob/user)
	var/list/data = list()
	var/mob/living/carbon/human/human_user = user
	if(!istype(human_user))
		return data

	data["busy"] = busy_bank
	data["characterName"] = human_user.real_name
	data["infoText"] = get_info_text()
	data["generalTaken"] = (human_user.ckey in item_takers)
	data["handsFull"] = human_user.hands_are_full()
	data["generalItems"] = get_general_entries(human_user)
	data["personalItems"] = get_personal_entries(human_user)
	data["generalCapacity"] = general_compartment_capacity
	data["personalCapacity"] = get_personal_capacity()
	data["triangles"] = human_user.etching ? human_user.etching.triangles : 0
	return data

/obj/machinery/item_bank/proc/do_coin_withdrawal(mob/living/carbon/human/user, var/withdrawal_amount)
	if(busy_bank)
		to_chat(user, "<span class='warning'>\The [src] is already in use.</span>")
		return FALSE
	if(!user.etching)
		to_chat(user, "<span class='warning'>No etching data was found.</span>")
		return FALSE

	var/datum/etching/E = user.etching
	if(E.triangles <= 0)
		to_chat(user, "<span class='warning'>You haven't got any coins banked...</span>")
		return FALSE

	withdrawal_amount = round(withdrawal_amount)
	if(withdrawal_amount <= 0)
		return FALSE

	if(withdrawal_amount > E.triangles)
		to_chat(user, "<span class='warning'>\The [src] buzzes at you and flashes red. You do not have ◬:[withdrawal_amount] banked. You have a balance of ◬:[E.triangles]...</span>")
		return FALSE

	busy_bank = TRUE
	E.triangles -= withdrawal_amount
	visible_message("<span class='notice'>\The [src] rattles as it dispenses coins!</span>")
	dispense_triangle_coins(withdrawal_amount,get_turf(src),user)	//RS EDIT
	E.needs_saving = TRUE	//RS EDIT
	busy_bank = FALSE
	return TRUE

/obj/machinery/item_bank/proc/do_general_retrieval(mob/living/carbon/human/user, var/item_name)
	if(busy_bank)
		to_chat(user, "<span class='warning'>\The [src] is already in use.</span>")
		return FALSE
	if(user.hands_are_full())
		to_chat(user, "<span class='notice'>Your hands are full!</span>")
		return FALSE
	if(user.ckey in item_takers)
		to_chat(user, "<span class='warning'>You have already taken something out of \the [src] this shift.</span>")
		return FALSE
	if(!user.etching || !islist(user.etching.item_storage) || !user.etching.item_storage.len)
		to_chat(user, "<span class='warning'>\The [src] doesn't seem to have anything for you...</span>")
		return FALSE
	if(!(item_name in user.etching.item_storage))
		to_chat(user, "<span class='warning'>\The [src] buzzes. That item is no longer available.</span>")
		return FALSE

	busy_bank = TRUE
	icon_state = "item_bank_o"
	if(!can_use_bank(user) || !do_after(user, 10 SECONDS, src, exclusive = TASK_ALL_EXCLUSIVE) || inoperable())
		busy_bank = FALSE
		icon_state = "item_bank"
		return FALSE

	var/raw_type = user.etching.item_storage[item_name]
	var/item_type = resolve_item_type(raw_type)
	if(!item_type)
		user.etching.item_storage -= item_name
		log_and_message_admins("<span class = 'danger'>[user]/[user.ckey] attempted to retrieve an invalid item: [item_name] - [raw_type]</span>")
		busy_bank = FALSE
		icon_state = "item_bank"
		return FALSE

	var/obj/item/new_item = new item_type(get_turf(src))
	log_admin("[key_name_admin(user)] retrieved [new_item] from the item bank.")
	visible_message("<span class='notice'>\The [src] dispenses the [new_item] to \the [user].</span>")
	user.put_in_hands(new_item)
	new_item.persist_storable = FALSE
	item_takers += user.ckey
	user.etching.item_storage -= item_name
	user.etching.needs_saving = TRUE
	busy_bank = FALSE
	icon_state = "item_bank"
	return TRUE

/obj/machinery/item_bank/proc/do_personal_retrieval(mob/living/carbon/human/user, var/item_name)
	if(busy_bank)
		to_chat(user, "<span class='warning'>\The [src] is already in use.</span>")
		return FALSE
	if(user.hands_are_full())
		to_chat(user, "<span class='notice'>Your hands are full!</span>")
		return FALSE
	if(!user.etching)
		to_chat(user, "<span class='warning'>Your personal storage is empty...</span>")
		return FALSE
	if(!islist(user.etching.unlockables) || !user.etching.unlockables.len)
		to_chat(user, "<span class='warning'>Your personal storage is empty...</span>")
		return FALSE
	if(!(item_name in user.etching.unlockables))
		to_chat(user, "<span class='warning'>\The [src] buzzes. That item is no longer available.</span>")
		return FALSE

	var/claimed_item_type = resolve_item_type(user.etching.unlockables[item_name])
	var/display_name = get_unlockable_display_name(item_name, claimed_item_type)
	if(is_personal_item_claimed(user, item_name, claimed_item_type))
		to_chat(user, "<span class='warning'>\The [src] buzzes. You have already claimed your [display_name] this shift.</span>")
		return FALSE

	busy_bank = TRUE
	icon_state = "item_bank_o"
	if(!can_use_bank(user) || !do_after(user, 10 SECONDS, src, exclusive = TASK_ALL_EXCLUSIVE) || inoperable())
		busy_bank = FALSE
		icon_state = "item_bank"
		return FALSE

	var/raw_type = user.etching.unlockables[item_name]
	var/item_type = resolve_item_type(raw_type)
	if(!item_type)
		user.etching.unlockables -= item_name
		log_and_message_admins("<span class = 'danger'>[user]/[user.ckey] attempted to retrieve an invalid unlockable item: [item_name] - [raw_type]</span>")
		busy_bank = FALSE
		icon_state = "item_bank"
		return FALSE

	var/obj/item/new_item = new item_type(get_turf(src))
	log_admin("[key_name_admin(user)] retrieved [new_item] from the item bank.")
	visible_message("<span class='notice'>\The [src] dispenses the [new_item] to \the [user].</span>")
	user.put_in_hands(new_item)
	new_item.name = "[user]'s [new_item.name]"
	new_item.persist_storable = FALSE
	var/claimed_key = "[user.real_name] - [item_name]"
	unlockable_takers += claimed_key
	var/default_name = "[initial(item_type:name)]"
	if(istext(default_name) && length(default_name) && default_name != item_name)
		unlockable_takers += "[user.real_name] - [default_name]"
	busy_bank = FALSE
	icon_state = "item_bank"
	return TRUE

/obj/machinery/item_bank/proc/store_active_hand(mob/living/carbon/human/user)
	if(busy_bank)
		to_chat(user, "<span class='warning'>\The [src] is already in use.</span>")
		return FALSE

	var/obj/item/held = user.get_active_hand()
	if(!held)
		to_chat(user, "<span class='notice'>You are not holding anything in your active hand.</span>")
		return FALSE

	busy_bank = TRUE
	if(istype(held, /obj/item/triangle))	//RS EDIT
		if(user.etching)
			var/obj/item/triangle/coin = held	//RS EDIT
			user.update_etching("triangles", coin.value)
			user.drop_item()
			to_chat(user, "<span class='warning'>\The [src] SCHLORPS up \the [held]!!!</span>")
			qdel(held)
		busy_bank = FALSE
		return TRUE

	if(!user.etching)
		to_chat(user, "<span class='warning'>No etching data was found.</span>")
		busy_bank = FALSE
		return FALSE

	user.etching.store_item(held, src, TRUE)
	return TRUE

/obj/machinery/item_bank/tgui_act(action, params)
	if(..())
		return TRUE

	var/mob/living/carbon/human/user = usr
	if(!istype(user))
		return TRUE
	if(!can_use_bank(user, announce = TRUE))
		return TRUE

	switch(action)
		if("retrieve_general")
			var/item_name = params["id"]
			var/confirm = text2num(params["confirm"])
			if(confirm && istext(item_name))
				do_general_retrieval(user, item_name)
			return TRUE
		if("retrieve_personal")
			var/item_name = params["id"]
			var/confirm = text2num(params["confirm"])
			if(confirm && istext(item_name))
				do_personal_retrieval(user, item_name)
			return TRUE
		if("withdraw_triangles")
			var/confirm = text2num(params["confirm"])
			var/withdrawal_amount = text2num(params["amount"])
			if(confirm)
				do_coin_withdrawal(user, withdrawal_amount)
			return TRUE
		if("store_active_hand")
			var/confirm = text2num(params["confirm"])
			if(confirm)
				store_active_hand(user)
			return TRUE

	return FALSE
// RS Edit End

/obj/machinery/item_bank/attackby(obj/item/O, mob/living/user)
	if(!ishuman(user))
		return
	if(busy_bank)
		to_chat(user, "<span class='warning'>\The [src] is already in use.</span>")
		return
	busy_bank = TRUE
	//RS EDIT BEGIN
	if(istype(O, /obj/item/triangle))
		store_coin(O,user)
		busy_bank = FALSE
		return
	if(istype(O,/obj/item/coinstack) || istype(O,/obj/item/coinpouch))
		var/obj/item/coinpouch/pouch = O
		for(var/thing in pouch.bank())
			if(istype(thing,/obj/item/triangle))
				var/obj/item/triangle/coin = thing
				store_coin(coin,user)
		busy_bank = FALSE
		return

	//RS EDIT END
	user.etching.store_item(O,src)
/*	//RS REMOVAL START - //Removed the old way of storing items, as it is no longer needed.
	var/I = persist_item_savefile_load(user, "type")
	if(!istool(O) && O.persist_storable)
		if(ispath(I))
			to_chat(user, "<span class='warning'>You cannot store \the [O]. You already have something stored.</span>")
			busy_bank = FALSE
			return
		var/choice = tgui_alert(user, "If you store \the [O], anything it contains may be lost to \the [src]. Are you sure?", "[src]", list("Store", "Cancel"), timeout = 10 SECONDS)
		if(!choice || choice == "Cancel" || !Adjacent(user) || inoperable() || panel_open)
			busy_bank = FALSE
			return
		for(var/obj/check in O.contents)
			if(!check.persist_storable)
				to_chat(user, "<span class='warning'>\The [src] buzzes. \The [O] contains [check], which cannot be stored. Please remove this item before attempting to store \the [O]. As a reminder, any contents of \the [O] will be lost if you store it with contents.</span>")
				busy_bank = FALSE
				return
		user.visible_message("<span class='notice'>\The [user] begins storing \the [O] in \the [src].</span>","<span class='notice'>You begin storing \the [O] in \the [src].</span>")
		icon_state = "item_bank_o"
		if(!do_after(user, 10 SECONDS, src, exclusive = TASK_ALL_EXCLUSIVE) || inoperable())
			busy_bank = FALSE
			icon_state = "item_bank"
			return
		src.persist_item_savefile_save(user, O)
		user.visible_message("<span class='notice'>\The [user] stores \the [O] in \the [src].</span>","<span class='notice'>You stored \the [O] in \the [src].</span>")
		log_admin("[key_name_admin(user)] stored [O] in the item bank.")
		qdel(O)
		busy_bank = FALSE
		icon_state = "item_bank"
	else
		to_chat(user, "<span class='warning'>You cannot store \the [O]. \The [src] either does not accept that, or it has already been retrieved from storage this shift.</span>")
		busy_bank = FALSE
*/	//RS REMOVAL END

/////STORABLE ITEMS AND ALL THAT JAZZ/////
//I am only really intending this to be used for single items. Mostly stuff you got right now, but can't/don't want to use right now.
//It is not at all intended to be a thing that just lets you hold on to stuff forever, but just until it's the right time to use it.

//RS ADD - Multiple ways to store coins now so let's just make a proc that all of them can use
/obj/machinery/item_bank/proc/store_coin(var/obj/item/triangle/coin,var/mob/living/user)
	if(!coin || !user)
		return
	if(!user.etching)
		return
	if(!istype(coin,/obj/item/triangle))
		return
	user.update_etching("triangles", coin.value)
	user.drop_from_inventory(coin)
	to_chat(user, "<span class='warning'>\The [src] SCHLORPS up \the [coin]!!!</span>")
	qdel(coin)
	busy_bank = FALSE

/proc/dispense_triangle_coins(var/value,var/turf/dispense_loc,var/mob/living/user)
	if(!value || !dispense_loc)
		return FALSE
	if(!isturf(dispense_loc))
		dispense_loc = get_turf(dispense_loc)
	var/obj/item/triangle/A
	if(value == 7)
		A = new /obj/item/triangle/u7(dispense_loc)
		value -= A.value
	if(value == 13)
		A = new /obj/item/triangle/u13(dispense_loc)
		value -= A.value

	var/list/dispensed = list()
	var/obj/item/coinstack/stack
	while(value > 0)
		if(value >= 1000)
			A = new /obj/item/triangle/u1000(dispense_loc)
		else if(value >= 100)
			A = new /obj/item/triangle/u100(dispense_loc)
		else if(value >= 25)
			A = new /obj/item/triangle/u25(dispense_loc)
		else if(value >= 10)
			A = new /obj/item/triangle/u10(dispense_loc)
		else if(value >= 5)
			A = new /obj/item/triangle/u5(dispense_loc)
		else if(value >= 1)
			A = new /obj/item/triangle/u1(dispense_loc)
		else
			A = new /obj/item/triangle/u02(dispense_loc)
		value -= A.value
		dispensed += A

	if(dispensed.len > 1)
		stack = new(dispense_loc)
		if(isliving(user))
			user.put_in_hands(stack)
		for(var/obj/item/triangle/coin in dispensed)
			stack.stack(coin)
	return TRUE

//RS ADD END
/obj

	var/persist_storable = TRUE		//If this is true, this item can be stored in the item bank.
									//This is automatically set to false when an item is removed from storage

/////LIST OF STUFF WE DON'T WANT PEOPLE STORING/////

/obj/item/device/pda
	persist_storable = FALSE
/obj/item/device/communicator
	persist_storable = FALSE
/obj/item/weapon/card
	persist_storable = FALSE
/obj/item/weapon/holder
	persist_storable = FALSE
/obj/item/device/radio
	persist_storable = FALSE
/obj/item/device/encryptionkey
	persist_storable = FALSE
/obj/item/weapon/storage			//There are lots of things that have stuff that we may not want people to just have. And this is mostly intended for a single thing.
	persist_storable = FALSE		//And it would be annoying to go through and consider all of them, so default to disabled.
/obj/item/weapon/storage/backpack	//But we can enable some where it makes sense. Backpacks and their variants basically never start with anything in them, as an example.
	persist_storable = TRUE
/obj/item/weapon/reagent_containers/hypospray/vial
	persist_storable = FALSE
/obj/item/weapon/cmo_disk_holder
	persist_storable = FALSE
/obj/item/device/defib_kit/compact/combat
	persist_storable = FALSE
/obj/item/clothing/glasses/welding/superior
	persist_storable = FALSE
/obj/item/clothing/shoes/magboots/adv
	persist_storable = FALSE
/obj/item/weapon/rig
	persist_storable = FALSE
/obj/item/clothing/head/helmet/space/void
	persist_storable = FALSE
/obj/item/clothing/suit/space/void
	persist_storable = FALSE
/obj/item/weapon/grab
	persist_storable = FALSE
/obj/item/weapon/grenade
	persist_storable = FALSE
/obj/item/weapon/hand_tele
	persist_storable = FALSE
/obj/item/weapon/paper
	persist_storable = FALSE
/obj/item/weapon/backup_implanter
	persist_storable = FALSE
/obj/item/weapon/disk/nuclear
	persist_storable = FALSE
/obj/item/weapon/gun/energy/locked		//These are guns with security measures on them, so let's say the box won't let you put them in there.
	persist_storable = FALSE			//(otherwise explo will just put their locker/vendor guns into it every round)
/obj/item/device/retail_scanner
	persist_storable = FALSE
/obj/item/weapon/telecube
	persist_storable = FALSE
/obj/item/weapon/reagent_containers/glass/bottle/adminordrazine
	persist_storable = FALSE
/obj/item/weapon/gun/energy/sizegun/admin
	persist_storable = FALSE
/obj/item/stack
	persist_storable = FALSE
/obj/item/weapon/book
	persist_storable = FALSE
/obj/item/weapon/melee/cursedblade
	persist_storable = FALSE
/obj/item/weapon/circuitboard/mecha/imperion
	persist_storable = FALSE
/obj/item/device/paicard
	persist_storable = FALSE
/obj/item/organ
	persist_storable = FALSE
/obj/item/device/soulstone
	persist_storable = FALSE
/obj/item/device/aicard
	persist_storable = FALSE
/obj/item/device/mmi
	persist_storable = FALSE
/obj/item/seeds
	persist_storable = FALSE
/obj/item/weapon/reagent_containers/food/snacks/grown
	persist_storable = FALSE
/obj/item/weapon/stock_parts
	persist_storable = FALSE
/obj/item/weapon/rcd
	persist_storable = FALSE
/obj/item/weapon/spacecash
	persist_storable = FALSE
/obj/item/weapon/spacecasinocash
	persist_storable = FALSE
/obj/item/device/personal_shield_generator
	persist_storable = FALSE
