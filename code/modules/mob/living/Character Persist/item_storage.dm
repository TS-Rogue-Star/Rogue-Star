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

/datum/etching/proc/item_save()
	var/list/to_save = list(
		"triangles" = triangles,
		"item_storage" = item_storage,
		"unlockables" = unlockables,
		"nif_type" = nif_type,
		"nif_durability" = nif_durability,
		"nif_savedata" = nif_savedata
	)

	return to_save

/datum/etching/report_status()
	. = ..()

	var/our_money = report_money()
	if(our_money)
		if(.)
			. += "\n"
		. += our_money

/datum/etching/proc/update_nif(var/mob/living/carbon/human/H)
	if(H.nif)		//We have a nif, let's see if it needs to be updated
		if(H.nif.owner != ourmob.real_name)		//Is this nif ours? If not, we shouldn't save it
			nif_type = null
			nif_durability = 0
			needs_saving = TRUE
		if(H.nif.type != nif_type)	//Our nif types don't match, we either just got a nif, or we got an upgrade, nice, let's record it!
			nif_type = H.nif.type
			nif_durability = H.nif.durability
			needs_saving = TRUE
	else if(nif_type)		//We don't have a nif, but we do have a record of one, so we probably got ours removed, let's clear the data.
		nif_type = null
		nif_durability = 0
		needs_saving = TRUE

/proc/persist_nif_data(var/mob/living/carbon/human/H)
	to_world("persist_nif_data")
	if(!ishuman(H))		//We are not a human, don't bother!
		stack_trace("Persist (NIF): Given a nonhuman: [H]")
		return
	if(!H.etching)		//We do not have the ability to save character persist data, don't bother!
		return
	H.etching.update_nif(H)
