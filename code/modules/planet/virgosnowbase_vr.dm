var/datum/planet/snowbase/planet_snowbase = null

/datum/time/snowbase
	seconds_in_day = 24 HOURS

/datum/planet/snowbase
	name = "Virgo-5"
	desc = "The outermost planet of the Virgo-Erigone system. While just outside the goldilocks zone and covered in miles of ice, it is technically habitable."
	current_time = new /datum/time/snowbase()
//	expected_z_levels = list(1) // This is defined elsewhere.
	planetary_wall_type = /turf/unsimulated/wall/planetary/snowbase

/datum/planet/snowbase/New()
	..()
	planet_snowbase = src
	weather_holder = new /datum/weather_holder/snowbase(src)

/datum/planet/snowbase/update_sun()
	..()
	var/datum/time/time = current_time
	var/length_of_day = time.seconds_in_day / 10 / 60 / 60
	var/noon = length_of_day / 2
	var/distance_from_noon = abs(text2num(time.show_time("hh")) - noon)
	sun_position = distance_from_noon / noon
	sun_position = abs(sun_position - 1)

	var/low_brightness = null
	var/high_brightness = null

	var/low_color = null
	var/high_color = null
	var/min = 0

	switch(sun_position)
		if(0 to 0.20) // Night
			low_brightness = 0.3
			low_color = "#000066"

			high_brightness = 0.5
			high_color = "#66004D"
			min = 0

		if(0.20 to 0.30) // Twilight
			low_brightness = 0.5
			low_color = "#66004D"

			high_brightness = 0.9
			high_color = "#CC3300"
			min = 0.40

		if(0.30 to 0.40) // Sunrise/set
			low_brightness = 0.9
			low_color = "#CC3300"

			high_brightness = 3.0
			high_color = "#FF9933"
			min = 0.50

		if(0.40 to 1.00) // Noon
			low_brightness = 3.0
			low_color = "#DDDDDD"

			high_brightness = 10.0
			high_color = "#FFFFFF"
			min = 0.70

	var/interpolate_weight = (abs(min - sun_position)) * 4
	var/weather_light_modifier = 1
	if(weather_holder && weather_holder.current_weather)
		weather_light_modifier = weather_holder.current_weather.light_modifier

	var/new_brightness = (LERP(low_brightness, high_brightness, interpolate_weight) ) * weather_light_modifier

	var/new_color = null
	if(weather_holder && weather_holder.current_weather && weather_holder.current_weather.light_color)
		new_color = weather_holder.current_weather.light_color
	else
		var/list/low_color_list = hex2rgb(low_color)
		var/low_r = low_color_list[1]
		var/low_g = low_color_list[2]
		var/low_b = low_color_list[3]

		var/list/high_color_list = hex2rgb(high_color)
		var/high_r = high_color_list[1]
		var/high_g = high_color_list[2]
		var/high_b = high_color_list[3]

		var/new_r = LERP(low_r, high_r, interpolate_weight)
		var/new_g = LERP(low_g, high_g, interpolate_weight)
		var/new_b = LERP(low_b, high_b, interpolate_weight)

		new_color = rgb(new_r, new_g, new_b)

	spawn(1)
		update_sun_deferred(new_brightness, new_color)


/datum/weather_holder/snowbase
	temperature = T0C
	allowed_weather_types = list(
		WEATHER_CLEAR			= new /datum/weather/snowbase/clear(),
		WEATHER_OVERCAST		= new /datum/weather/snowbase/overcast(),
		WEATHER_LIGHT_SNOW		= new /datum/weather/snowbase/light_snow(),
		WEATHER_SNOW			= new /datum/weather/snowbase/snow(),
		WEATHER_BLIZZARD		= new /datum/weather/snowbase/blizzard(),
		)
	roundstart_weather_chances = list(
		WEATHER_SNOW		= 50,
		WEATHER_CLEAR		= 40
		)

/datum/weather/snowbase
	name = "snowbase"
	temp_high = 250.15
	temp_low = 243.15

/datum/weather/snowbase/clear
	name = "clear"
	transition_chances = list(
		WEATHER_OVERCAST = 60,
		WEATHER_SNOW = 20,
		WEATHER_LIGHT_SNOW = 20)
	transition_messages = list(
		"The sky clears up.",
		"The sky is visible.",
		"The weather is calm."
		)
	sky_visible = TRUE
	observed_message = "The sky is clear."
	imminent_transition_message = "The sky is rapidly clearing up."

/datum/weather/snowbase/overcast
	name = "overcast"
	temp_high = 250.15
	temp_low = 243.15
	light_modifier = 0.8
	transition_chances = list(
		WEATHER_SNOW = 25,
		WEATHER_LIGHT_SNOW = 50,
		WEATHER_OVERCAST = 50,
		WEATHER_CLEAR = 25
		)
	observed_message = "It is overcast, all you can see are clouds."
	transition_messages = list(
		"All you can see above are clouds.",
		"Clouds cut off your view of the sky.",
		"It's very cloudy."
		)
	imminent_transition_message = "Benign clouds are quickly gathering."

/datum/weather/snowbase/light_snow
	name = "light snow"
	icon_state = "snowfall_light"
	temp_high = 250.15
	temp_low = 243.15
	light_modifier = 0.7
	transition_chances = list(
		WEATHER_LIGHT_SNOW = 15,
		WEATHER_OVERCAST = 80
		)
	observed_message = "It is snowing lightly."
	transition_messages = list(
		"Small snowflakes begin to fall from above.",
		"It begins to snow lightly.",
		)
	imminent_transition_message = "It appears a light snow is about to start."

/datum/weather/snowbase/snow
	name = "moderate snow"
	icon_state = "snowfall_med"
	temp_high = 250.15
	temp_low = 243.15
	wind_high = 2
	wind_low = 0
	light_modifier = 0.5
	flight_failure_modifier = 5
	transition_chances = list(
		WEATHER_SNOW = 10,
		WEATHER_LIGHT_SNOW = 80,
		)
	observed_message = "It is snowing."
	transition_messages = list(
		"It's starting to snow.",
		"The air feels much colder as snowflakes fall from above."
	)
	imminent_transition_message = "A snowfall is starting."
	outdoor_sounds_type = /datum/looping_sound/weather/outside_snow
	indoor_sounds_type = /datum/looping_sound/weather/inside_snow

/*
/datum/weather/snowbase/snow/process_effects()
	..()
	for(var/turf/simulated/floor/outdoors/snow/S as anything in SSplanets.new_outdoor_turfs) //This didn't make any sense before SSplanets, either
		if(S.z in holder.our_planet.expected_z_levels)
			for(var/dir_checked in cardinal)
				var/turf/simulated/floor/T = get_step(S, dir_checked)
				if(istype(T))
					if(istype(T, /turf/simulated/floor/outdoors) && prob(33))
						T.chill()
*/

/datum/weather/snowbase/blizzard
	name = "blizzard"
	icon_state = "snowfall_heavy"
	temp_high = 250.15
	temp_low = 243.15
	wind_high = 4
	wind_low = 2
	light_modifier = 0.3
	flight_failure_modifier = 10
	transition_chances = list(
		WEATHER_BLIZZARD = 5,
		WEATHER_SNOW = 80
		)
	observed_message = "A blizzard blows snow everywhere."
	transition_messages = list(
		"Strong winds howl around you as a blizzard appears.",
		"It starts snowing heavily, and it feels extremly cold now."
	)
	imminent_transition_message = "Wind is howling. Blizzard is coming."
	outdoor_sounds_type = /datum/looping_sound/weather/outside_blizzard
	indoor_sounds_type = /datum/looping_sound/weather/inside_blizzard

/datum/weather/snowbase/hail
	name = "hail"
	icon_state = "hail"
	light_modifier = 0.3
	flight_failure_modifier = 15
	timer_low_bound = 2
	timer_high_bound = 5
	effect_message = "<span class='warning'>The hail smacks into you!</span>"

	transition_chances = list(
		WEATHER_HAIL = 10,
		WEATHER_SNOW = 40
		)
	observed_message = "Ice is falling from the sky."
	transition_messages = list(
		"Ice begins to fall from the sky.",
		"It begins to hail.",
		"An intense chill is felt, and chunks of ice start to fall from the sky, towards you."
	)
	imminent_transition_message = "Small bits of ice are falling from the sky, growing larger by the second. Hail is starting, get to cover!"

/datum/weather/snowbase/hail/process_effects()
	..()
	for(var/mob/living/carbon/H as anything in human_mob_list)
		if(H.z in holder.our_planet.expected_z_levels)
			var/turf/T = get_turf(H)
			if(!T.is_outdoors())
				continue // They're indoors, so no need to pelt them with ice.

			// If they have an open umbrella, it'll guard from hail
			var/obj/item/weapon/melee/umbrella/U = H.get_active_hand()
			if(!istype(U) || !U.open)
				U = H.get_inactive_hand()

			if(istype(U) && U.open)
				if(show_message)
					to_chat(H, "<span class='notice'>Hail patters onto your umbrella.</span>")
				continue

			var/target_zone = pick(BP_ALL)
			var/amount_blocked = H.run_armor_check(target_zone, "melee")
			var/amount_soaked = H.get_armor_soak(target_zone, "melee")

			var/damage = rand(1,3)

			if(amount_blocked >= 30)
				continue // No need to apply damage. Hardhats are 30. They should probably protect you from hail on your head.
				//Voidsuits are likewise 40, and riot, 80. Clothes are all less than 30.

			if(amount_soaked >= damage)
				continue // No need to apply damage.

			H.apply_damage(damage, BRUTE, target_zone, amount_blocked, amount_soaked, used_weapon = "hail")
			if(show_message)
				to_chat(H, effect_message)
