//This file was auto-corrected by findeclaration.exe on 25.5.2012 20:42:33

//All devices that link into the R&D console fall into thise type for easy identification and some shared procs.

//	TODO - Leshana - Remove these.  Just so it compiles for now.
/obj/machinery/r_n_d
	var/list/materials = list()		// Materials this machine can accept.
	var/list/hidden_materials = list()	// Materials this machine will not display, unless it contains them. Must be in the materials list as well.


/obj/machinery/rnd
	name = "R&D Device"
	icon = 'icons/obj/machines/research.dmi'
	density = TRUE
	anchored = TRUE
	use_power = USE_POWER_IDLE
	var/datum/wires/rnd/wires = null
	var/busy = FALSE
	var/hacked = FALSE
	var/console_link = TRUE		//allow console link.
	var/requires_console = TRUE
	var/disabled = FALSE
	var/ui_template = null
	var/obj/machinery/computer/rdconsole/linked_console
	var/obj/item/loaded_item = null //the item loaded inside the machine (currently only used by experimentor and destructive analyzer)
	var/sound/success_sound = 'sound/machines/ping.ogg'			// Plays when finished with a task.
	var/sound/error_sound = 'sound/machines/buzz-sigh.ogg'		// Plays to alert about an error.

/obj/machinery/rnd/proc/set_busy()
	. = (!busy)
	busy = TRUE

/obj/machinery/rnd/proc/reset_busy()
	. = (busy)
	busy = FALSE

/obj/machinery/rnd/Initialize()
	. = ..()
	wires = new /datum/wires/rnd(src)
	default_apply_parts()

/obj/machinery/rnd/Destroy()
	QDEL_NULL(wires)
	return ..()

/obj/machinery/rnd/update_icon()
	. = ..()
	icon_state = panel_open ? "[initial(icon_state)]_t" : initial(icon_state)

/obj/machinery/rnd/proc/buzz(msg)
	audible_message("[bicon(src)] <span class='warning'>[msg]</span>")
	if(error_sound)
		playsound(src, error_sound, 50, 0)

/obj/machinery/rnd/attackby(obj/item/O, mob/user)
	if(busy)
		to_chat(user, "<span class='warning'>[src] is busy right now.</span>")
		return TRUE
	if(default_deconstruction_screwdriver(user, O))
		if(linked_console)
			disconnect_console()
		return
	if(default_deconstruction_crowbar(user, O))
		return
	if(default_part_replacement(user, O))
		return
	if(panel_open && is_wire_tool(O))
		wires.Interact(user)
		return TRUE
	if(reagents && O.is_open_container())
		return FALSE // inserting reagents into the machine
	// TODO - Do I need to check for borgs putting module items inside?
	if(Insert_Item(O, user))
		return TRUE
	if(OnAttackBy(src, O, user))
		return TRUE
	else
		return ..()


/obj/machinery/rnd/MouseDrop_T(obj/item/I, mob/user)
	if(istype(I) && isliving(user) && user.get_active_hand() == I && I.Adjacent(src))
		Insert_Item(I, user)
		return
	return ..()

/obj/machinery/rnd/ui_interact(var/mob/user, var/ui_key = "main", var/datum/nanoui/ui = null, var/force_open = 1, var/datum/topic_state/state = default_state)
	var/list/data = get_ui_data()

	ui = SSnanoui.try_update_ui(user, src, ui_key, ui, data, force_open)
	if(!ui)
		ui = new(user, src, ui_key, ui_template, "Exosuit Fabricator UI", 800, 600)
		ui.set_initial_data(data)
		ui.open()
		ui.set_auto_update(1)

// Return data for NanoUI interface, called by ui_interact
/obj/machinery/rnd/proc/get_ui_data()
	return list()

// Let children with materials override this to forward attackbys.
/obj/machinery/rnd/proc/OnAttackBy(datum/source, obj/item/O, mob/user)
	return

//to disconnect the machine from the r&d console it's linked to
/obj/machinery/rnd/proc/disconnect_console()
	linked_console = null

//proc used to handle inserting items or reagents into rnd machines
/obj/machinery/rnd/proc/Insert_Item(obj/item/I, mob/user)
	return

//whether the machine can have an item inserted in its current state.
/obj/machinery/rnd/proc/is_insertion_ready(mob/user)
	if(panel_open)
		to_chat(user, "<span class='warning'>You can't load [src] while it's opened!</span>")
		return FALSE
	if(disabled)
		to_chat(user, "<span class='warning'>The insertion belts of [src] won't engage!</span>")
		return FALSE
	if(requires_console && !linked_console)
		to_chat(user, "<span class='warning'>[src] must be linked to an R&D console first!</span>")
		return FALSE
	if(busy)
		to_chat(user, "<span class='warning'>[src] is busy right now.</span>")
		return FALSE
	if(stat & BROKEN)
		to_chat(user, "<span class='warning'>[src] is broken.</span>")
		return FALSE
	if(stat & NOPOWER)
		to_chat(user, "<span class='warning'>[src] has no power.</span>")
		return FALSE
	if(loaded_item)
		to_chat(user, "<span class='warning'>[src] is already loaded.</span>")
		return FALSE
	return TRUE

//we eject the loaded item when deconstructing the machine
/obj/machinery/rnd/dismantle()
	if(loaded_item)
		loaded_item.forceMove(drop_location())
		loaded_item = null
	return ..()
