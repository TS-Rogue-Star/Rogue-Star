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

/obj/machinery/item_bank/attack_hand(mob/living/user)
	. = ..()
	if(!ishuman(user))
		return
	if(istype(user) && Adjacent(user))
		if(inoperable() || panel_open)
			to_chat(user, "<span class='warning'>\The [src] seems to be nonfunctional...</span>")
		else
			start_using(user)

/obj/machinery/item_bank/proc/start_using(mob/living/user)
	if(!ishuman(user))
		return
	if(busy_bank)
		to_chat(user, "<span class='warning'>\The [src] is already in use.</span>")
		return
	busy_bank = TRUE
	if(legacy_detect(user))	//RS EDIT START
		if(tgui_alert(user, "A legacy item has been detected in storage. This item must be bound to a character. Would you like to add it to [user.real_name]'s general storage?", "[src] legacy item detected", list("Yes","No"), timeout = 10 SECONDS) == "Yes")

			var/itemname = persist_item_savefile_load(user, "name")
			var/itemtype = persist_item_savefile_load(user, "type")
			user.etching.legacy_conversion(itemname,itemtype)
			var/path = src.persist_item_savefile_path(user)
			fdel(path)
			log_debug("<span class = 'danger'>[user]/[user.ckey] converted a legacy item persist file to an item_storage state. Item was, [itemname] - [itemtype]</span>")
			busy_bank = FALSE
			return
	var/choice = tgui_alert(user, "What would you like to do [src]?", "[src]", list("General", "Personal","Coin", "Info", "Cancel"), timeout = 10 SECONDS)
	if(!choice || choice == "Cancel" || !Adjacent(user) || inoperable() || panel_open)
		busy_bank = FALSE
		return
	else if(choice == "General")	//RS EDIT END
		if(user.hands_are_full())
			to_chat(user,"<span class='notice'>Your hands are full!</span>")
			busy_bank = FALSE
			return
		if(user.ckey in item_takers)
			to_chat(user, "<span class='warning'>You have already taken something out of \the [src] this shift.</span>")
			busy_bank = FALSE
			return
		var/list/our_item = list()	//RS EDIT START
		if(user.etching.item_storage.len)
			our_item = tgui_input_list(user, "Which item would you like to retrieve?", "[src] - General Compartment",user.etching.item_storage)
			if(!our_item)
				busy_bank = FALSE
				return
		else
			to_chat(user, "<span class='warning'>\The [src] doesn't seem to have anything for you...</span>")
			busy_bank = FALSE
			return
		choice = tgui_alert(user, "If you remove \the [our_item] from the bank, it will be unable to be stored again. Do you still want to remove it?", "[src]", list("No", "Yes"), timeout = 10 SECONDS)	//RS EDIT END
		icon_state = "item_bank_o"
		if(!choice || choice == "No" || !Adjacent(user) || inoperable() || panel_open)
			busy_bank = FALSE
			icon_state = "item_bank"
			return
		else if(!do_after(user, 10 SECONDS, src, exclusive = TASK_ALL_EXCLUSIVE) || inoperable())
			busy_bank = FALSE
			icon_state = "item_bank"
			return
		var/ourtype = user.etching.item_storage[our_item]	//RS EDIT START
		var/backup
		if(!ispath(ourtype))
			backup = ourtype
			ourtype = text2path(ourtype)

		if(!ourtype)
			user.etching.item_storage -= our_item
			log_and_message_admins("<span class = 'danger'>[user]/[user.ckey] attempted to retrieve an invalid item: [our_item] - [backup]</span>")

			return
		var/obj/N = new ourtype(get_turf(src))				//RS EDIT END
		log_admin("[key_name_admin(user)] retrieved [N] from the item bank.")
		visible_message("<span class='notice'>\The [src] dispenses the [N] to \the [user].</span>")
		user.put_in_hands(N)
		N.persist_storable = FALSE
		item_takers += user.ckey
		user.etching.item_storage -= our_item	//RS EDIT
		user.etching.needs_saving = TRUE		//RS EDIT
		busy_bank = FALSE
		icon_state = "item_bank"

	else if(choice == "Info")
		to_chat(user, "<span class='notice'>\The [src] can store items for you between shifts! Anything that has been retrieved from the bank cannot be stored again in the same shift. Anyone can withdraw from the bank one time per shift. Some items are not able to be accepted by the bank.</span>")	//RS EDIT START
		busy_bank = FALSE
		return
	else if(choice == "Personal")
		if(!user.etching.unlockables.len)
			to_chat(user, "<span class='warning'>Your personal storage is empty...</span>")
			busy_bank = FALSE
			return
		var/our_item = tgui_input_list(user, "Which item would you like to retrieve?", "[src] - Personal Compartment",user.etching.unlockables)
		if(!our_item)
			busy_bank = FALSE
			return

		icon_state = "item_bank_o"
		if(!choice || choice == "No" || !Adjacent(user) || inoperable() || panel_open)
			busy_bank = FALSE
			icon_state = "item_bank"
			return

		if("[user.real_name] - [our_item]" in unlockable_takers)
			to_chat(user, "<span class='warning'>\The [src] buzzes. You have already claimed your [our_item] this shift.</span>")
			busy_bank = FALSE
			return

		else if(!do_after(user, 10 SECONDS, src, exclusive = TASK_ALL_EXCLUSIVE) || inoperable())
			busy_bank = FALSE
			icon_state = "item_bank"
			return
		var/ourtype = user.etching.unlockables[our_item]
		//RS EDIT START
		var/backup
		if(!ispath(ourtype))
			backup = ourtype
			ourtype = text2path(ourtype)

		if(!ourtype)
			user.etching.unlockables -= our_item
			log_and_message_admins("<span class = 'danger'>[user]/[user.ckey] attempted to retrieve an invalid unlockable item: [our_item] - [backup]</span>")
			return
		//RS EDIT END
		var/obj/N = new ourtype(get_turf(src))
		log_admin("[key_name_admin(user)] retrieved [N] from the item bank.")
		visible_message("<span class='notice'>\The [src] dispenses the [N] to \the [user].</span>")
		user.put_in_hands(N)
		N.name = "[user]'s [N.name]"
		N.persist_storable = FALSE
		unlockable_takers += "[user.real_name] - [our_item]"
		busy_bank = FALSE
		icon_state = "item_bank"

	else if(choice == "Coin")
		if(user.etching)
			var/datum/etching/E = user.etching
			if(E.triangles <= 0)
				to_chat(user, "<span class='warning'>You haven't got any coins banked...</span>")
				busy_bank = FALSE
				return
			else
				var/ourtris = tgui_input_number(user, "How much would you like to withdraw? You have ◬:[E.triangles] banked.", "Withdraw", timeout = 10 SECONDS)
				if(ourtris <= 0)
					busy_bank = FALSE
					return
				if(ourtris > E.triangles)
					to_chat(user, "<span class='warning'>\The [src] buzzes at you and flashes red. You do not have ◬:[ourtris] banked. You have a balance of ◬:[E.triangles]...</span>")
					busy_bank = FALSE
					return
				ourtris = round(ourtris)
				E.triangles -= ourtris
				visible_message("<span class='notice'>\The [src] rattles as it dispenses coins!</span>")
				busy_bank = FALSE
				var/turf/here = get_turf(src)
				var/obj/item/weapon/aliencoin/A
				while(ourtris > 0)
					if(ourtris >= 1000)
						A = new /obj/item/weapon/aliencoin/exotic(here)
					else if(ourtris >= 100)
						A = new /obj/item/weapon/aliencoin/diamond(here)
					else if(ourtris >= 20)
						A = new /obj/item/weapon/aliencoin/phoron(here)
					else if(ourtris >= 10)
						A = new /obj/item/weapon/aliencoin/gold(here)
					else if(ourtris >= 5)
						A = new /obj/item/weapon/aliencoin/silver(here)
					else
						A = new /obj/item/weapon/aliencoin/basic(here)
					ourtris -= A.value
				//RS EDIT END

/obj/machinery/item_bank/attackby(obj/item/O, mob/living/user)
	if(!ishuman(user))
		return
	if(busy_bank)
		to_chat(user, "<span class='warning'>\The [src] is already in use.</span>")
		return
	busy_bank = TRUE
	//RS EDIT BEGIN
	if(istype(O, /obj/item/weapon/aliencoin))
		if(user.etching)
			var/obj/item/weapon/aliencoin/coin = O
			user.update_etching("triangles", coin.value)
			user.drop_item()
			to_chat(user, "<span class='warning'>\The [src] SCHLORPS up \the [O]!!!</span>")
			qdel(O)
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
