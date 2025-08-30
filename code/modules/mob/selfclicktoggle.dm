/obj/clickthroughobj
	var/image/clickthroughimage = null

/mob
	var/image/selfinvis = null
	var/obj/clickthroughobj/clickthroughvis = null

/mob/set_dir()
	. = ..()
	if(. && clickthroughvis)
		clickthroughvis.clickthroughimage.dir = dir

/mob/verb/toggle_clickthroughself()
	set name = "Self-Click Toggle"
	set desc = "Toggle being able to click yourself"
	set category = "IC"

	if(isnull(selfinvis))
		selfinvis = image(null, src) // mouse_opacity is ignored for image objects, so instead we make the mob take up 0 pixels on the client's screen by overriding it with a null icon.
		selfinvis.override = 1
	if(isnull(clickthroughvis))
		clickthroughvis = new()
		clickthroughvis.mouse_opacity = 0
		clickthroughvis.vis_flags = VIS_INHERIT_LAYER|VIS_INHERIT_PLANE
		clickthroughvis.appearance_flags = KEEP_APART|LONG_GLIDE|TILE_BOUND
	if(!src.vis_contents.Find(clickthroughvis))
		src.vis_contents += clickthroughvis
		clickthroughvis.transform = new()
	if(usr.client.images.Find(selfinvis) || usr.client.images.Find(clickthroughvis.clickthroughimage))
		usr.client.images -= selfinvis
		usr.client.images -= clickthroughvis.clickthroughimage
	else
		clickthroughvis.clickthroughimage = image(src, clickthroughvis)
		clickthroughvis.clickthroughimage.appearance_flags = KEEP_TOGETHER|LONG_GLIDE|TILE_BOUND
		clickthroughvis.clickthroughimage.alpha = 50
		clickthroughvis.clickthroughimage.dir = dir
		clickthroughvis.clickthroughimage.transform = new()
		usr << clickthroughvis.clickthroughimage
		usr << selfinvis