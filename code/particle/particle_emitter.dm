//RS FILE
/obj/particle_emitter
	name = "particle emitter"
	desc = "You shouldn't see this"
	icon = 'icons/rogue-star/particlesx32.dmi'
	icon_state = "particle-emitter"
	mouse_opacity = 0
	particles = new/particles/seething/active
	plane = PLANE_LIGHTING_ABOVE
	anchored = TRUE
	density = FALSE
	var/lifespan = -1	// < 0 = infinite. | > 0 = how many fastprocessing ticks
	var/delete_at_time

/obj/particle_emitter/Initialize(mapload)
	icon = null
	icon_state = null
	. = ..()
	if(lifespan > 0)
		START_PROCESSING(SSfastprocess,src)

/obj/particle_emitter/Destroy()
	. = ..()
	STOP_PROCESSING(SSfastprocess,src)

/obj/particle_emitter/process()
	if(lifespan < 0)
		return
	if(lifespan > 0)
		lifespan --
	if(lifespan <= 0)
		if(!delete_at_time)
			particles.spawning = 0
			delete_at_time = world.time + particles.lifespan + 1 SECOND
			return
	if(delete_at_time)
		if(world.time >= delete_at_time)
			qdel(src)
