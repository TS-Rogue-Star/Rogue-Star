/obj/item/paint_brush/organic
	name = "organic paintbrush"
	desc = "A 'paintbrush' made out of some form of organic material. Strange!"
	description_info = "Click on yourself to change the color!"
	selected_color = "#000000"
	force = 0
	throwforce = 0
	w_class = ITEMSIZE_HUGE
	var/mob/living/carbon/human/creator

/obj/item/paint_brush/organic/reset_plane_and_layer()
	return //Unneeded. The object is deleted.

/obj/item/paint_brush/organic/Initialize(location)
	..()
	START_PROCESSING(SSobj, src)
	if(ismob(loc))
		visible_message("[loc.name] pulls out an organic paintbrush of some sort!")
		creator = loc

/obj/item/paint_brush/organic/dropped(mob/user)
	visible_message("[creator] puts their organic paintbrush back!")
	if(creator.linked_brush) //Sanity, as it was runtiming during testing.
		creator.linked_brush = null
	spawn(1)
		if(src)
			qdel(src)

/obj/item/paint_brush/organic/Destroy()
	STOP_PROCESSING(SSobj, src)
	creator.linked_brush = null
	creator = null
	..()

/obj/item/paint_brush/organic/process()
	if(!creator || loc != creator || !creator.item_is_in_hands(src))
		// Tidy up a bit.
		if(istype(loc,/mob/living/carbon/human))
			var/mob/living/carbon/human/host = loc
			if(istype(host))
				for(var/obj/item/organ/external/organ in host.organs)
					for(var/obj/item/O in organ.implants)
						if(O == src)
							organ.implants -= src
			host.pinned -= src
			host.embedded -= src
			host.drop_from_inventory(src)
		creator.linked_brush = null
		spawn(1)
			if(src)
				qdel(src)
