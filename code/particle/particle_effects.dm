//RS FILE
/particles/weather
	icon = 'icons/rogue-star/particlesx32.dmi'
	icon_state = "X"
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
	position = generator("box", list(-6,8,0), list(6,8,0))
	velocity = generator("vector",list(-3,0.1),list(3,0.1))
	gravity = list(0, 1)

/obj/particle_emitter/music
	particles = new/particles/music
