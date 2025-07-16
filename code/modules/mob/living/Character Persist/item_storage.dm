//RS FILE

#define item_storage_maximum 50

var/global/list/permanent_unlockables = list(
	//SIZE STUFF
	/obj/item/weapon/gun/energy/sizegun,
	/obj/item/device/slow_sizegun,
	/obj/item/weapon/implanter/sizecontrol,
	/obj/item/clothing/under/hyperfiber,
	/obj/item/clothing/under/hyperfiber/bluespace,
	/obj/item/selectable_item/chemistrykit/size,
	//TF RAYS
	/obj/item/weapon/gun/energy/mouseray,
	/obj/item/weapon/gun/energy/mouseray/woof,
	/obj/item/weapon/gun/energy/mouseray/corgi,
	/obj/item/weapon/gun/energy/mouseray/cat,
	/obj/item/weapon/gun/energy/mouseray/chicken,
	/obj/item/weapon/gun/energy/mouseray/lizard,
	/obj/item/weapon/gun/energy/mouseray/rabbit,
	/obj/item/weapon/gun/energy/mouseray/fennec,
	/obj/item/weapon/gun/energy/mouseray/monkey,
	/obj/item/weapon/gun/energy/mouseray/wolpin,
	/obj/item/weapon/gun/energy/mouseray/otie,
	/obj/item/weapon/gun/energy/mouseray/direwolf,
	/obj/item/weapon/gun/energy/mouseray/giantrat,
	/obj/item/weapon/gun/energy/mouseray/redpanda,
	/obj/item/weapon/gun/energy/mouseray/catslug,
	/obj/item/weapon/gun/energy/mouseray/teppi,
	//OTHER
	/obj/item/weapon/disk/nifsoft/compliance,
	/obj/item/weapon/implanter/compliance,
	/obj/item/device/bodysnatcher,
	/obj/item/device/sleevemate,
	/obj/item/weapon/handcuffs/fuzzy,
	/obj/item/weapon/handcuffs/legcuffs/fuzzy,
	/obj/item/clothing/mask/muzzle/ballgag,
	/obj/item/clothing/mask/muzzle/ballgag/ringgag,
	/obj/item/clothing/glasses/sunglasses/blindfold,
	/obj/item/capture_crystal,
	/obj/item/selectable_item/chemistrykit/gender
)

/datum/etching
	var/triangles = 0							//Triangle money
	var/list/item_storage = list()				//Various items that are stored in the bank, these can only be stored and pulled out once
	var/list/unlockables = list()				//Scene items that, once stored, can be pulled once per round forever.
	var/nif_type = null							//The type of nif you have
	var/nif_durability = 0						//The durability of your nif
	var/nif_savedata = list()

/datum/etching/proc/store_item(item,var/obj/machinery/item_bank/bank)
	if(!isobj(item))
		bank.busy_bank = FALSE
		return
	var/obj/O = item
	if(!O.persist_storable)
		to_chat(ourmob, "<span class='warning'>You cannot store \the [O]. \The [bank] either does not accept that, or it has already been retrieved from storage this shift.</span>")
		bank.busy_bank = FALSE
		return
	if(O.type in permanent_unlockables)
		if(O.name in unlockables)
			to_chat(ourmob, "<span class='warning'>\The [bank] has already catalogued \the [O] for you.</span>")
			bank.busy_bank = FALSE
			return
		unlockables += list(O.name = O.type)
		to_chat(ourmob, "<span class='notice'>\The [bank] scans your [item]. It catalogues this to your personal storage! You will be able to retrieve \the [item] again in future shifts.</span>")
		needs_saving = TRUE
		bank.unlockable_takers += "[ourmob.real_name] - [item]"
		bank.busy_bank = FALSE
		O.persist_storable = FALSE
		log_admin("[key_name_admin(ourmob)] has unlocked [O]/[O.type] for [ourmob].")
		return

	if(!istool(O))
		if(item_storage.len >= item_storage_maximum)
			to_chat(ourmob, "<span class='warning'>You can not store \the [O]. Your lockbox is too full.</span>")
			bank.busy_bank = FALSE
			return
		var/choice = tgui_alert(ourmob, "If you store \the [O], anything it contains may be lost to \the [bank]. Are you sure?", "[bank]", list("Store", "Cancel"), timeout = 10 SECONDS)
		if(!choice || choice == "Cancel" || !bank.Adjacent(ourmob) || bank.inoperable() || bank.panel_open)
			bank.busy_bank = FALSE
			return
		for(var/obj/check in O.contents)
			if(!check.persist_storable)
				to_chat(ourmob, "<span class='warning'>\The [bank] buzzes. \The [O] contains [check], which cannot be stored. Please remove this item before attempting to store \the [O]. As a reminder, any contents of \the [O] will be lost if you store it with contents.</span>")
				bank.busy_bank = FALSE
				return
		ourmob.visible_message("<span class='notice'>\The [ourmob] begins storing \the [O] in \the [bank].</span>","<span class='notice'>You begin storing \the [O] in \the [bank].</span>")
		bank.icon_state = "item_bank_o"
		if(!do_after(ourmob, 10 SECONDS, bank, exclusive = TASK_ALL_EXCLUSIVE) || bank.inoperable())
			bank.busy_bank = FALSE
			bank.icon_state = "item_bank"
			return
		save_item(O)
		ourmob.visible_message("<span class='notice'>\The [ourmob] stores \the [O] in \the [bank].</span>","<span class='notice'>You stored \the [O] in \the [bank].</span>")
		log_admin("[key_name_admin(ourmob)] stored [O]/[O.type] in the item bank for [ourmob].")
		qdel(O)
		bank.busy_bank = FALSE
		bank.icon_state = "item_bank"

	else
		to_chat(ourmob, "<span class='warning'>You cannot store \the [O]. \The [bank] either does not accept that, or it has already been retrieved from storage this shift.</span>")
		bank.busy_bank = FALSE

/datum/etching/proc/save_item(var/obj/O)
	item_storage += list("[initial(O.name)] - [time2text(world.timeofday, "YYYYMMDDhhmmss")]" = O.type)
	needs_saving = TRUE

/datum/etching/proc/legacy_conversion(I_name,I_type)
	item_storage += list("[I_name] - [time2text(world.timeofday, "YYYYMMDDhhmmss")]" = I_type)
	needs_saving = TRUE

/datum/etching/update_etching(mode, value)
	. = ..()
	switch(mode)
		if("triangles")
			triangles += value
	needs_saving = TRUE

/datum/etching/proc/report_money()
	. = "<span class='boldnotice'>◬</span>: [triangles]\n\n"
	return .

/datum/etching/proc/item_load(var/list/load)

	if(!load)
		return

	triangles = load["triangles"]
	item_storage = null
	item_storage = load["item_storage"]
	unlockables = load["unlockables"]
	nif_type = load["nif_type"]
	nif_durability = load["nif_durability"]
	nif_savedata = load["nif_savedata"]

	load_nif()

/datum/etching/proc/item_save()
	var/list/to_save = list(
		"triangles" = triangles,
		"item_storage" = item_storage,
		"unlockables" = unlockables
	)

	if(ishuman(ourmob))
		var/mob/living/carbon/human/H = ourmob
		if(H.nif)
			to_save["nif_type"] = H.nif.type
			to_save["nif_durability"] = H.nif.durability
			to_save["nif_savedata"] = H.nif.save_data
	else if(ourclient)	//For nif conversion
		to_save["nif_type"] = nif_type
		to_save["nif_durability"] = nif_durability
		to_save["nif_savedata"] = nif_savedata

	return to_save

/datum/etching/report_status()
	. = ..()

	var/our_money = report_money()
	if(our_money)
		if(.)
			. += "\n"
		. += our_money

/datum/etching/proc/update_nif()
	var/mob/living/carbon/human/H = ourmob
	if(H.nif)		//We have a nif, let's see if it needs to be updated
		if(H.nif.owner != H.real_name)		//Is this nif ours? If not, we shouldn't save it
			return
		//Otherwise if something is asking us to update the nif, then let's update it!
		nif_type = H.nif.type
		nif_durability = H.nif.durability
		nif_savedata = H.nif.save_data
		needs_saving = TRUE

/datum/etching/proc/clear_nif_save()
	nif_type = null
	nif_durability = null
	nif_savedata = null
	needs_saving = TRUE

/proc/persist_nif_data(var/mob/living/carbon/human/H)
	if(!ishuman(H))		//We are not a human, don't bother!
		stack_trace("Persist (NIF): Given a nonhuman: [H]")
		return
	if(!H.etching)		//We do not have the ability to save character persist data, don't bother!
		return
	H.etching.update_nif()

/datum/etching/setup(var/datum/preferences/P)
	. = ..()
	if(ourmob)
		if(ourmob.client.prefs.nif_path)
			convert_nif(ourmob.client, P)
		load_nif()	//We're spawning in!!!
	if(ourclient)
		if(P.nif_path)	//Clean dat shit up
			convert_nif(ourclient,P)

/datum/etching/proc/convert_nif(var/client/thissun,var/datum/preferences/P)
	if(event_character)
		return
	if(!P.nif_path)	//Let's double check
		return	//What are you trying to convert?!
	var/orig = savable	//TBH it is basically impossible that this will ever be relevant but one of you will find a way so let's store this in case somehow you are converting the nif data of an unsavable character
	savable = TRUE
	log_debug("ETCHING: Converting legacy NIF data: [P.nif_path] - [P.nif_durability] - [P.nif_savedata]")
	nif_type = P.nif_path
	nif_durability = P.nif_durability
	nif_savedata = P.nif_savedata
	needs_saving = TRUE
	log_debug("ETCHING: Legacy NIF data conversion complete - [nif_type] - [nif_durability] - [nif_savedata]")
	save()	//Save the etching data so we don't lose anything
	savable = orig	//Return our savable status to what it was

	P.nif_path = null	//Clear the old data, so we don't try to convert it again later
	P.nif_durability = null
	P.nif_savedata = null

	P.save_character()	//Save our character. This SHOULD ONLY HAPPEN when someone is opening character setup, loading a character, or spawning in. If you make it happen at any other times, I don't know what will happen, and it's possible it will mess up the person's save file so don't fuck up.

/datum/etching/proc/load_nif()
	if(!ourmob)	//The product of this proc is the creation of a nif, so if we don't have a mob, then let's not
		return
	if(ourmob.client.prefs.nif_path)	//Hey we have old style nif data saved that wasn't caught, let's convert it
		convert_nif(ourmob.client,ourmob.client.prefs)
	if(!nif_type)	//No nif type, no nif mister!!!
		return
	var/backup
	if(!ispath(nif_type))	//Let's double check and make sure the nif we have is a valid type, in case of type paths changing or whatever. You can put conversion stuff in here.
		backup = nif_type	//Let's hold on to this in case it isn't a type.
		nif_type = text2path(nif_type)	//Convert the string to a path!
	if(!nif_type)	//Was it a valid path?
		log_debug("ETCHING: Attempted to load nif, but had invalid type: [backup], aborting")
		nif_type = backup	//It wasn't, so let's put the data back here, and abort. Someone will need to convert the old type to a new type!
		return

	new nif_type(ourmob,nif_durability,nif_savedata)	//Nice nif bud you go, look how handsome you are with that twinkle in your eye wow
