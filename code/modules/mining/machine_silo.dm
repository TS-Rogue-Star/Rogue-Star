GLOBAL_DATUM(ore_silo_default, /obj/machinery/ore_silo)
GLOBAL_LIST_EMPTY(silo_access_logs)

/obj/machinery/ore_silo
	name = "material silo"
	desc = "An all-in-one bluespace storage and transmission system for the station's mineral distribution needs."
	icon = 'icons/obj/mining.dmi'
	icon_state = "silo"
	anchored = TRUE
	density = TRUE
	circuit = /obj/item/weapon/circuitboard/ore_silo

	var/allow_local_insertion = TRUE			// If we should allow inserting sheets by hand
	var/datum/material_container/materials		// Container for our actual materials.
	var/list/holds = list()
	var/list/datum/remote_materials/connected = list()
	var/log_page = 1

/obj/machinery/ore_silo/Initialize(mapload)
	. = ..()
	// Materials that would be reasonably used in manufaturing designs.
	var/static/list/materials_list = list(
		/material/steel,
		/material/glass,
		/material/plasteel,
		/material/plastic,
		/material/graphite,
		/material/gold,
		/material/silver,
		/material/osmium,
		/material/lead,
		/material/phoron,
		/material/uranium,
		/material/diamond,
		/material/durasteel,
		/material/verdantium,
		/material/morphium,
		/material/mhydrogen,
		/material/supermatter,
		/material/plasteel/titanium,
	)

	var/static/list/hidden_materials = list(
		/material/plasteel,
		/material/durasteel,
		/material/graphite,
		/material/verdantium,
		/material/morphium,
		/material/mhydrogen,
		/material/supermatter,
	)

	materials = new(src, materials_list, INFINITY, allowed_types = /obj/item/stack/material, hidden_mats = hidden_materials)
	if (!GLOB.ore_silo_default && mapload && (get_z(src) in using_map.station_levels))
		GLOB.ore_silo_default = src
	default_apply_parts()

/obj/machinery/ore_silo/Destroy()
	if (GLOB.ore_silo_default == src)
		GLOB.ore_silo_default = null

	for(var/C in connected)
		var/datum/remote_materials/mats = C
		mats.disconnect_from(src)

	connected = null
	materials.retrieve_all()
	QDEL_NULL(materials)
	return ..()

// TODO - Make this more accurate as to the mats inserted.  right now it guesses
/obj/machinery/ore_silo/proc/log_item_inserted(obj/machinery/M, action, noun, obj/item/I, amount_inserted)
	log_debug("log_item_inserted([M], [action], [noun], [I] ([I?.type]), [amount_inserted],  [json_encode(I?.matter)]")
	if(istype(I, /obj/item/stack))
		silo_log(M, action, amount_inserted, noun, I.matter)
	else
		silo_log(M, action, 1, noun, I.matter)

// Note, while this machine is constructable it is purposefully not deconstructable for balance reasons.
/obj/machinery/ore_silo/attackby(obj/item/W, mob/user, params)
	if(istype(W, /obj/item/device/multitool) && multitool_act(user, W))
		return
	if(istype(W, /obj/item/stack/material) && user.a_intent == I_HELP)
		var/obj/item/stack/material/S = W
		materials.default_user_insert_item(src, user, S, extra_after_insert = CALLBACK(src, .proc/log_item_inserted, src, "deposited", "[S.singular_name]"))
		return
	return ..()

/obj/machinery/ore_silo/attack_hand(mob/user)
	if((. = ..()))
		return
	user.set_machine(src)
	var/datum/browser/popup = new(user, "ore_silo", null, 600, 550)
	popup.set_content(generate_ui())
	popup.open()

/obj/machinery/ore_silo/proc/generate_ui()
	var/list/ui = list("<head><title>Ore Silo</title></head><body><div class='statusDisplay'><h2>Stored Material:</h2>")
	var/any = FALSE
	for(var/M in materials.materials)
		var/material/mat = get_material_ref(M) // This way it works whether its a type, instance, or id
		var/amount = materials.materials[M]
		var/sheets = round(amount) / SHEET_MATERIAL_AMOUNT
		var/ref = REF(mat)
		if (sheets)
			if (sheets >= 1)
				ui += "<a href='?src=[REF(src)];ejectsheet=[ref];eject_amt=1'>Eject</a>"
			else
				ui += "<span class='linkOff'>Eject</span>"
			if (sheets >= 20)
				ui += "<a href='?src=[REF(src)];ejectsheet=[ref];eject_amt=20'>20x</a>"
			else
				ui += "<span class='linkOff'>20x</span>"
			ui += "<b>[mat.name]</b>: [sheets] sheets<br>"
			any = TRUE
	if(!any)
		ui += "Nothing!"

	ui += "</div><div class='statusDisplay'><h2>Connected Machines:</h2>"
	for(var/C in connected)
		var/datum/remote_materials/mats = C
		var/atom/parent = mats.parent
		var/hold_key = "[REF(get_area(parent))]/[parent.type]"
		ui += "<a href='?src=[REF(src)];remove=[REF(mats)]'>Remove</a>"
		ui += "<a href='?src=[REF(src)];hold[!holds[hold_key]]=[url_encode(hold_key)]'>[holds[hold_key] ? "Allow" : "Hold"]</a>"
		ui += " <b>[parent.name]</b> in [get_area_name(parent, TRUE)]<br>"
	if(!connected.len)
		ui += "Nothing!"

	ui += "</div><div class='statusDisplay'><h2>Access Logs:</h2>"
	var/list/logs = GLOB.silo_access_logs[REF(src)]
	var/len = LAZYLEN(logs)
	var/num_pages = 1 + round((len - 1) / 30)
	var/page = clamp(log_page, 1, num_pages)
	if(num_pages > 1)
		for(var/i in 1 to num_pages)
			if(i == page)
				ui += "<span class='linkOff'>[i]</span>"
			else
				ui += "<a href='?src=[REF(src)];page=[i]'>[i]</a>"

	ui += "<ol>"
	any = FALSE
	for(var/i in (page - 1) * 30 + 1 to min(page * 30, len))
		var/datum/ore_silo_log/entry = logs[i]
		ui += "<li value=[len + 1 - i]>[entry.formatted]</li>"
		any = TRUE
	if (!any)
		ui += "<li>Nothing!</li>"

	ui += "</ol></div>"
	return ui.Join()

/obj/machinery/ore_silo/Topic(href, href_list)
	if(..())
		return
	add_fingerprint(usr)
	usr.set_machine(src)

	if(href_list["remove"])
		var/datum/remote_materials/mats = locate(href_list["remove"]) in connected
		if (mats)
			mats.disconnect_from(src)
			connected -= mats
			updateUsrDialog()
			return TRUE
	else if(href_list["hold1"])
		holds[href_list["hold1"]] = TRUE
		updateUsrDialog()
		return TRUE
	else if(href_list["hold0"])
		holds -= href_list["hold0"]
		updateUsrDialog()
		return TRUE
	else if(href_list["ejectsheet"])
		var/material/eject_sheet = locate(href_list["ejectsheet"])
		var/count = materials.retrieve_sheets(text2num(href_list["eject_amt"]), eject_sheet, drop_location())
		var/list/matlist = list()
		matlist[eject_sheet] = SHEET_MATERIAL_AMOUNT
		silo_log(src, "ejected", -count, "sheets", matlist)
		return TRUE
	else if(href_list["page"])
		log_page = text2num(href_list["page"]) || 1
		updateUsrDialog()
		return TRUE

/obj/machinery/ore_silo/proc/multitool_act(mob/living/user, obj/item/device/multitool/I)
	if (istype(I))
		to_chat(user, "<span class='notice'>You log [src] in the multitool's buffer.</span>")
		I.buffer = src
		return TRUE

/obj/machinery/ore_silo/proc/silo_log(obj/machinery/M, action, amount, noun, list/mats)
	if (!length(mats))
		log_debug("Warning, got logs with empty mats: [json_encode(args)]")
		return
	var/datum/ore_silo_log/entry = new(M, action, amount, noun, mats)

	var/list/datum/ore_silo_log/logs = GLOB.silo_access_logs[REF(src)]
	if(!LAZYLEN(logs))
		GLOB.silo_access_logs[REF(src)] = logs = list(entry)
	else if(!logs[1].merge(entry))
		logs.Insert(1, entry)

	updateUsrDialog()
	flick("silo_active", src)

/obj/machinery/ore_silo/examine(mob/user)
	. = ..()
	. += "<span class='notice'>[src] can be linked to techfabs, circuit printers and protolathes with a multitool.</span>"
	materials.OnExamine(src, user, .)

/datum/ore_silo_log
	var/name  // for VV
	var/formatted  // for display

	var/timestamp
	var/machine_name
	var/area_name
	var/action
	var/noun
	var/amount
	var/list/materials

/datum/ore_silo_log/New(obj/machinery/M, _action, _amount, _noun, list/mats=list())
	timestamp = stationtime2text()
	machine_name = M.name
	area_name = get_area_name(M, TRUE)
	action = _action
	amount = _amount
	noun = _noun
	materials = mats.Copy()
	for(var/each in materials)
		materials[each] *= abs(_amount)
	format()

/datum/ore_silo_log/proc/merge(datum/ore_silo_log/other)
	if (other == src || action != other.action || noun != other.noun)
		return FALSE
	if (machine_name != other.machine_name || area_name != other.area_name)
		return FALSE

	timestamp = other.timestamp
	amount += other.amount
	for(var/each in other.materials)
		materials[each] += other.materials[each]
	format()
	return TRUE

/datum/ore_silo_log/proc/format()
	name = "[machine_name]: [action] [amount]x [noun]"

	var/list/msg = list("([timestamp]) <b>[machine_name]</b> in [area_name]<br>[action] [abs(amount)]x [noun]<br>")
	var/sep = ""
	for(var/key in materials)
		var/material/M = get_material_ref(key)
		var/val = round(materials[key]) / SHEET_MATERIAL_AMOUNT
		msg += sep
		sep = ", "
		msg += "[amount < 0 ? "-" : "+"][val] [M.name]"
	formatted = msg.Join()
