GLOBAL_LIST_EMPTY(npc_kind_supplies)
GLOBAL_LIST_INIT(npc_never_take, list(
	/obj/item/weapon/reagent_containers/food/snacks/monkeycube,
))

/obj/structure/closet/var/list/npc_start_supplies

/proc/npc_contents_kinds(atom/A)
	. = list()
	for(var/obj/item/I in A)
		. |= I.type
		if(istype(I, /obj/item/weapon/storage))
			for(var/obj/item/J in I)
				. |= J.type

/proc/npc_note_kind_supplies(obj/structure/closet/C)
	if(!GLOB.npc_kind_supplies[C.type])
		GLOB.npc_kind_supplies[C.type] = npc_contents_kinds(C)

/proc/npc_note_start_supplies(obj/structure/closet/C)
	C.npc_start_supplies = npc_contents_kinds(C)

/proc/npc_supplies_of(atom/A, close = FALSE)
	if(istype(A, /obj/structure/closet))
		var/obj/structure/closet/C = A
		return close && C.opened ? npc_contents_kinds(get_turf(C)) : GLOB.npc_kind_supplies[A.type]
	if(istype(A, /obj/machinery/vending))
		var/obj/machinery/vending/V = A
		. = list()
		for(var/datum/stored_item/vending_product/P as anything in V.product_records)
			if(P.category == CAT_NORMAL)
				. |= P.item_path
		return
	if(istype(A, /obj/item/weapon/storage))
		return close ? npc_contents_kinds(A) : null
	return null

/proc/npc_holds(list/supplies, want)
	for(var/kind in supplies)
		if(ispath(kind, want))
			return TRUE
	return FALSE

/proc/npc_worth_taking(want, kind, atom/thing)
	if(thing)
		kind = thing.type
	for(var/bad in GLOB.npc_never_take)
		if(ispath(kind, bad))
			return FALSE
	if(thing && ispath(want, /obj/item/weapon/reagent_containers/food/drinks))
		return thing.reagents?.total_volume >= 5
	return TRUE

/proc/npc_find_at(turf/T, want)
	if(!T)
		return null
	for(var/obj/item/I in T)
		if(istype(I, want) && npc_worth_taking(want, null, I))
			return I
	for(var/obj/item/weapon/storage/S in T)
		for(var/obj/item/I in S)
			if(istype(I, want) && npc_worth_taking(want, null, I))
				return I
	return null
