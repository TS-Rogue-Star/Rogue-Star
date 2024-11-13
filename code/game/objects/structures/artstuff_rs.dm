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
	creator.linked_brush = null
	creator = null
	..()
