/***************************************************************
**						Design Datums						  **
**	All the data for building stuff and tracking reliability. **
***************************************************************/
/*
For the materials datum, it assumes you need reagents unless specified otherwise. To designate a material that isn't a reagent,
you use one of the material IDs below. These are NOT ids in the usual sense (they aren't defined in the object or part of a datum),
they are simply references used as part of a "has materials?" type proc. They all start with a  to denote that they aren't reagents.
The currently supporting non-reagent materials:

Don't add new keyword/IDs if they are made from an existing one (such as rods which are made from metal). Only add raw materials.

Design Guidelines
- When adding new designs, check rdreadme.dm to see what kind of things have already been made and where new stuff is needed.
- A single sheet of anything is 2000 units of material. Materials besides metal/glass require help from other jobs (mining for
other types of metals and chemistry for reagents).

*/
//Note: More then one of these can be added to a design.

/datum/design						//Datum for object designs, used in construction
	var/name = null					//Name of the created object. If null it will be 'guessed' from build_path if possible.
	var/desc = null					//Description of the created object. If null it will use group_desc and name where applicable.
	var/item_name = null			//An item name before it is modified by various name-modifying procs
	var/id = DESIGN_ID_IGNORE		//ID of the created object for easy refernece. Alphanumeric, lower-case, no symbols.
	var/list/req_tech = list()		//TECHWEB DEPRECATED - IDs of that techs the object originated from and the minimum level requirements.
	var/build_type = null			//Flag as to what kind machine the design is built in. See defines.
	var/list/materials = list()		//List of materials. Format: "id" = amount.
	var/list/chemicals = list()		//List of chemicals.
	var/build_path = null			//The path of the object that gets created.
	var/time = 10					//How many ticks it requires to build
	var/category = null 			//Primarily used for Mech Fabricators, but can be used for anything.
	var/sort_string = "ZZZZZ"		//Sorting order
	var/dangerous_construction = FALSE	//notify and log for admin investigations if this is printed.
	var/departmental_flags = ALL			//bitflags for deplathes.
	var/list/datum/techweb_node/unlocked_by = list()
	var/contraband = FALSE			//Only buildable in hacked machines. Mostly for autolathes.
	var/research_icon					//Replaces the item icon in the research console
	var/research_icon_state
	var/icon_cache

/datum/design/error_design
	name = "ERROR"
	desc = "This usually means something in the database has corrupted. If this doesn't go away automatically, inform Central Comamnd so their techs can fix this ASAP(tm)"

/datum/design/New()
	item_name = name
	AssembleDesignInfo()

/datum/design/Destroy()
	SSresearch.techweb_designs -= id
	return ..()

// TODO - Leshana -Validate this here!
/datum/design/proc/InitializeMaterials()
	// TODO - Converts to storing material datum instances instead of ids or paths

	// For now tho, lets at least validate!
	for(var/i in materials)
		var/material/M =  get_material_ref(i)
		if(!M)
			log_debug("Design [id] has bad material [i]")
	// var/list/temp_list = list()
	// for(var/i in materials)
	// 	var/amount = materials[i]
	// 	if(!istext(i)) //Not a category, so get the ref the normal way
	// 		var/material/M =  get_material_ref(i)
	// 		temp_list[M] = amount
	// 	else
	// 		temp_list[i] = amount
	// materials = temp_list

/datum/design/proc/icon_html(client/user)
	var/datum/asset/iconsheet/sheet = get_asset_datum(/datum/asset/iconsheet/research_designs)
	sheet.send(user)
	return sheet.icon_tag(id)

//These procs are used in subtypes for assigning names and descriptions dynamically
/datum/design/proc/AssembleDesignInfo()
	AssembleDesignName()
	AssembleDesignDesc()
	return

/datum/design/proc/AssembleDesignName()
	if(!name && build_path)					//Get name from build path if posible
		var/atom/movable/A = build_path
		name = initial(A.name)
		item_name = name
	return

/datum/design/proc/AssembleDesignDesc()
	if(!desc)								//Try to make up a nice description if we don't have one
		desc = "Allows for the construction of \a [item_name]."
	return

//Returns a new instance of the item for this design
//This is to allow additional initialization to be performed, including possibly additional contructor arguments.
/datum/design/proc/Fabricate(var/newloc, var/fabricator)
	return new build_path(newloc)

/datum/design/item
	build_type = PROTOLATHE

//Make sure items don't get free power
/datum/design/item/Fabricate()
	var/obj/item/I = ..()
	var/obj/item/weapon/cell/C = I.get_cell()
	if(C)
		C.charge = 0
		I.update_icon()
	return I