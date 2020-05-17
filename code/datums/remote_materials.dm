/*
This component allows machines to connect remotely to a material container
(namely an /obj/machinery/ore_silo) elsewhere. It offers optional graceful
fallback to a local material storage in case remote storage is unavailable, and
handles linking back and forth.
*/

/datum/remote_materials
	var/atom/parent // Actual atom we are providing materials to (lathe etc)
	// Three possible states:
	// 1. silo exists, mat_container is parented to silo
	// 2. silo is null, mat_container is parented to parent
	// 3. silo is null, matmat_containererials is null
	var/obj/machinery/ore_silo/silo
	var/datum/material_container/mat_container
	var/datum/callback/precondition
	var/datum/callback/after_insert
	var/category
	var/allow_standalone
	var/local_size = INFINITY

/datum/remote_materials/New(parent, category, mapload, allow_standalone = TRUE, force_connect = FALSE, datum/callback/precondition, datum/callback/after_insert)
	if(!isatom(parent))
		CRASH("Oi! What is the meaning of this? Atoms please.")
	src.parent = parent
	src.category = category
	src.allow_standalone = allow_standalone
	src.precondition = precondition
	src.after_insert = after_insert

	if(force_connect || (mapload && (get_z(parent) in using_map.station_levels)))
		addtimer(CALLBACK(src, .proc/LateInitialize))
	else if(allow_standalone)
		_MakeLocal()

/datum/remote_materials/proc/LateInitialize()
	silo = GLOB.ore_silo_default
	if(silo)
		silo.connected += src
		mat_container = silo.materials
	else if(allow_standalone)
		_MakeLocal()

/datum/remote_materials/Destroy()
	if(silo)
		silo.connected -= src
		silo.updateUsrDialog()
		silo = null
		mat_container = null
	else if(mat_container)
		var/atom/P = parent
		mat_container.retrieve_all(P.drop_location())
		QDEL_NULL(mat_container)
	return ..()

/datum/remote_materials/proc/_MakeLocal()
	silo = null

	// Materials that would be reasonably used in manufaturing designs.
	var/static/list/allowed_mats = list(
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

	// atom/parent, list/allowed_mats, max_amt = 0, list/allowed_types, list/hidden_mats, preserve_composites = TRUE, datum/callback/after_insert)
	mat_container = new(parent, allowed_mats, local_size, allowed_types=/obj/item/stack/material, hidden_mats = hidden_materials, after_insert = after_insert)

/datum/remote_materials/proc/set_local_size(size)
	local_size = size
	if(!silo && mat_container)
		mat_container.max_amount = size

// called if disconnected by ore silo UI or destruction
/datum/remote_materials/proc/disconnect_from(obj/machinery/ore_silo/old_silo)
	if(!old_silo || silo != old_silo)
		return
	silo = null
	mat_container = null
	if(allow_standalone)
		_MakeLocal()

// We need to pass thru OnExamine to local materials datum (if existing) because without the component system it can't register on parent itself.
/datum/remote_materials/proc/OnExamine(datum/source, mob/user, list/examine_list)
	if(!silo && !mat_container)
		mat_container.OnExamine(source, user, examine_list)

/datum/remote_materials/proc/OnAttackBy(datum/source, obj/item/I, mob/user)
	if(istype(I, /obj/item/device/multitool))
		return OnMultitool(parent, user, I)

/datum/remote_materials/proc/OnMultitool(datum/source, mob/user, obj/item/device/multitool/M)
	if(!istype(M))
		return // Not a multitool, sheesh!
	if(QDELETED(M.buffer))
		to_chat(user, "<span class='warning'>[M] has no data buffer!</span>")
		return TRUE
	if(istype(M.buffer, /obj/machinery/ore_silo))
		if(silo == M.buffer)
			to_chat(user, "<span class='warning'>[parent] is already connected to [silo]!</span>")
			return TRUE
		if(silo)
			silo.connected -= src
			silo.updateUsrDialog()
		else if(mat_container)
			mat_container.retrieve_all()
			qdel(mat_container)
		silo = M.buffer
		silo.connected += src
		silo.updateUsrDialog()
		mat_container = silo.materials
		to_chat(user, "<span class='notice'>You connect [parent] to [silo] from the multitool's buffer.</span>")
		return TRUE

/datum/remote_materials/proc/get_status_message()
	if(!mat_container)
		return "No connection to material storage, please contact the quartermaster."
	else if(on_hold())
		return "Material access is on hold, please contact the quartermaster."
	return null // No errors

/datum/remote_materials/proc/on_hold()
	return silo && silo.holds["[REF(get_area(parent))]/[parent.type]"]

/datum/remote_materials/proc/silo_log(obj/machinery/M, action, amount, noun, list/mats)
	if(silo)
		silo.silo_log(M || parent, action, amount, noun, mats)

/datum/remote_materials/proc/format_amount()
	if(mat_container)
		return "[mat_container.total_amount] / [mat_container.max_amount == INFINITY ? "Unlimited" : mat_container.max_amount] ([silo ? "remote" : "local"])"
	else
		return "0 / 0"
