//RS FILE
/particles/weather
	icon = 'icons/rogue-star/particlesx32.dmi'
	icon_state = list("x","X")
	width =	500
	height = 500
	spawning = 1	// per 0.1s
	lifespan = 10 SECONDS
	count = 1000
	position = generator("box", list(-260,500,0), list(260,500,0))	//All across the top of the screen
	gravity = list(0, -3)

/particles/weather/snowfall
	icon_state = list("snowflake_1","snowflake_2","snowflake_3","snowflake_4","snowflake_5","snowflake_6",)
	spawning = 10
	lifespan = 6 SECONDS
	friction = 0.3
	drift = generator("sphere", 0, 5)
	fade = 2 SECONDS
	velocity = generator("vector",list(-10,-10),list(10,-10))
	spin = generator("num", -50,50)
	grow = -0.0025

/particles/weather/snowfall/tile
	spawning = 5
	width =	64
	height = 1000
	position = generator("box", list(-32,1000,0), list(32,1000,0))
	lifespan = 11 SECONDS

/particles/weather/rainfall
	icon_state = "raindrop"
	color = "#d3ebff"
	spawning = 10
	lifespan = generator("num",25,100)
	velocity = generator("vector",list(0,-5),list(0,-5))
	gravity = list(0.05, -1)

/particles/weather/rainfall/tile
	spawning = 2
	lifespan = 4 SECONDS
	width =	64
	height = 1000
	position = generator("box", list(-32,1000,0), list(32,1000,0))
	gravity = list(0, -1)

/obj/particle_emitter/snow_screen
	icon_state = "snowspawner"
	particles = new/particles/weather/snowfall
/obj/particle_emitter/snow_tile
	icon_state = "snowspawner"
	particles = new/particles/weather/snowfall/tile
/obj/particle_emitter/rain_screen
	icon_state = "rainspawner"
	particles = new/particles/weather/rainfall
/obj/particle_emitter/rain_tile
	icon_state = "rainspawner"
	particles = new/particles/weather/rainfall/tile

/particles/music
	icon = 'icons/rogue-star/particlesx32.dmi'
	icon_state = list("note","double-note")
	width =	500
	height = 500
	lifespan = 10
	spawning = 1
	count = 1
	fade = 2
	position = generator("box", list(-6,8,0), list(6,8,0))
	velocity = generator("vector",list(-3,0.1),list(3,0.1))
	gravity = list(0, 1)
	gradient = list(0, "#f55", 1, "#ff5", 2, "#7f5", 3, "#5ff", 4, "#55f", 5, "#f5f", 6, "#f55", "loop")
	color_change = generator("num",0.1,1)

/obj/particle_emitter/music
	particles = new/particles/music
	lifespan = 2
/obj/particle_emitter/music/indefinite
	lifespan = -1

/particles/shine
	icon = 'icons/rogue-star/particlesx32.dmi'
	icon_state = "shine"
	width =	500
	height = 500
	lifespan = 1
	spawning = 1
	count = 1
	fade = 2
	position = list(0,8,0)
	gravity = list(0, 5)
	grow = 1

/obj/particle_emitter/shine
	particles = new/particles/shine

/particles/twinkle
	icon = 'icons/rogue-star/particlesx32.dmi'
	icon_state = "sparkle_a"
	width =	500
	height = 500
	lifespan = 3
	spawning = 1
	count = 1
	fade = 1

/obj/particle_emitter/twinkle
	particles = new/particles/twinkle
	lifespan = 2

/decl/emote/visible/wink/do_extra(atom/user, atom/target)
	if(isliving(user))
		var/mob/living/L = user
		var/obj/particle_emitter/twinkle/T = new(get_turf(L))
		if(L.dir == WEST || L.dir == NORTH)
			T.particles.position = list(-2,10,0)
			T.particles.gravity = list(-2,0)
			T.particles.spin = -50
		else
			T.particles.position = list(2,10,0)
			T.particles.gravity = list(2, 0)
			T.particles.spin = 50

/particles/smelly
	icon = 'icons/rogue-star/particlesx32.dmi'
	icon_state = list("smelly1","smelly2")
	color = "#79966b"
	width =	500
	height = 500
	spawning = 1
	count = 3
	lifespan = 10
	gravity = list(0,0.5)
	position = generator("box",list(-16,-16,0),list(16,16,0))
	grow = 0.1
	fade = 3
	fadein = 2

/obj/particle_emitter/smelly
	particles = new/particles/smelly
	lifespan = 2

/obj/particle_emitter/smelly/indefinite
	lifespan = -1

/mob/living
	var/smelly = FALSE

/mob/living/Life()
	. = ..()
	if(smelly)
		new /obj/particle_emitter/smelly(get_turf(src))

///////BELCHING///////

/particles/belch
	icon = 'icons/rogue-star/particlesx32.dmi'
	icon_state = list("bubble","bubble-a","bubble-s","bubble-s-a")
	width =	500
	height = 500
	lifespan = 10
	spawning = 1
	count = 3
	velocity = generator("vector",list(-2,-2),list(2,2))
	color = "#129606"
	friction = 0.3
	fade = 2
	grow = 0.1

/particles/belch/north
	icon_state = list("bubble","bubble-s","puffn","bigpuffn")
	position = list(0,8,0)
	velocity = generator("vector",list(-1,5),list(1,15))
	gravity = list(0, 0.5)

/particles/belch/south
	icon_state = list("bubble","bubble-s","puffs","bigpuffs")
	position = list(0,6,0)
	velocity = generator("vector",list(-1,-5),list(1,-15))
	gravity = list(0, 0.5)

/particles/belch/east
	icon_state = list("bubble","bubble-s","puffe","bigpuffe")
	position = list(6,8,0)
	velocity = generator("vector",list(5,-1),list(15,1))
	gravity = list(1, 0.5)

/particles/belch/west
	icon_state = list("bubble","bubble-s","puffw","bigpuffw")
	position = list(-6,8,0)
	velocity = generator("vector",list(-5,-1),list(-15,1))
	gravity = list(-1, 0.5)

/obj/particle_emitter/belch
	lifespan = 3
/obj/particle_emitter/belch/n
	particles = new/particles/belch/north
/obj/particle_emitter/belch/s
	particles = new/particles/belch/south
/obj/particle_emitter/belch/e
	particles = new/particles/belch/east
/obj/particle_emitter/belch/w
	particles = new/particles/belch/west

/mob/living/proc/belch_particles()
	var/obj/particle_emitter/belch/B
	switch(dir)
		if(NORTH)
			B = new /obj/particle_emitter/belch/n(get_turf(src))
		if(SOUTH)
			B = new /obj/particle_emitter/belch/s(get_turf(src))
		if(EAST)
			B = new /obj/particle_emitter/belch/e(get_turf(src))
		if(WEST)
			B = new /obj/particle_emitter/belch/w(get_turf(src))
	if(client?.prefs_vr.belch_color)
		B.particles.color = client.prefs_vr.belch_color

/decl/emote/audible/belch/do_extra(atom/user, atom/target)
	if(isliving(user))
		var/mob/living/L = user
		L.belch_particles()

/mob/living/verb/set_belch_color()
	set name = "Set Belch Color"
	set category = "Preferences"

	var/color_choice = input(src, "Choose your belch color", "Belch Color", client.prefs_vr.belch_color) as color|null
	if(color_choice)
		client.prefs_vr.belch_color = sanitize_hexcolor(color_choice)

/particles/sword_rain
	icon = 'icons/rogue-star/misc.dmi'
	icon_state = "wind_blade"
	width = 500
	height = 500
	count = 1000
	spawning = 1
	bound1 = list(-1000, -300, -1000)
	lifespan = 10
	position = generator("box", list(-300,250,0), list(300,250,0))
	friction = 0.0
	velocity = list(1,-50)
	spin = -100

/obj/particle_emitter/sword_rain
	particles = new/particles/sword_rain
