//////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star November 2026: Drink Memories //
//////////////////////////////////////////////////////////////////

/decl/chemical_reaction
	var/list/drink_pour_order
	var/list/drink_preparation_notes
	var/drink_max_batch_multiplier = 0

/decl/chemical_reaction/instant/drinks/spacebeer
	drink_pour_order = list("cornoil", "flour", "enzyme")
	drink_preparation_notes = list("Add enzyme after the corn oil and flour. Enzyme added too early can turn the corn oil into cooking oil.")

/decl/chemical_reaction/instant/drinks/aloe
	drink_pour_order = list("cream", "watermelonjuice", "whiskey")
	drink_preparation_notes = list("Add whiskey last. Cream and whiskey mixed before the watermelon juice can become Irish Cream.")

/decl/chemical_reaction/instant/drinks/snowwhite
	drink_pour_order = list("pineapplejuice", "rum", "lemon_lime", "egg", "kahlua", "sugar")
	drink_preparation_notes = list("Start with pineapple juice and add sugar last. Rum and sugar can otherwise become Fire Punch before the drink is finished.")

/decl/chemical_reaction/instant/drinks/driverspunch
	drink_pour_order = list("appleade", "orangejuice", "sodawater", "mint")
	drink_preparation_notes = list("Add soda water before mint. It prevents the appleade and mint from becoming Mint Apple Sparkle.")

/decl/chemical_reaction/instant/drinks/peanutmilkshake
	drink_pour_order = list("cream", "ice", "peanutbutter", "milk")
	drink_max_batch_multiplier = 1
	drink_preparation_notes = list("Finish each small batch before adding ingredients for the next. Larger additions of milk and ice can make ordinary Milkshake instead, regardless of pouring order.")

/decl/chemical_reaction/instant/drinks/rotgut
	drink_pour_order = list("vodka", "rum", "whiskey", "cola")
	drink_preparation_notes = list("Start with vodka and add cola last. Otherwise Rum and Cola or Whiskey Cola can form before the drink is finished.")

/decl/chemical_reaction/instant/drinks/negroni
	drink_pour_order = list("gin", "bitters", "vermouth")
	drink_preparation_notes = list("Add bitters before vermouth. Bitters prevent the gin and vermouth from becoming a Classic Martini.")

/decl/chemical_reaction/instant/drinks/daiquiri
	drink_pour_order = list("rum", "limejuice", "sugar")
	drink_preparation_notes = list("Add sugar last. Rum and sugar mixed before the lime juice can become Fire Punch.")

/datum/character_memory/proc/build_drink_traits(var/datum/reagent/drink)
	if(!drink)
		return null
	var/static/list/allergen_names = list(
		"Meat" = ALLERGEN_MEAT,
		"Fish" = ALLERGEN_FISH,
		"Fruit" = ALLERGEN_FRUIT,
		"Vegetables" = ALLERGEN_VEGETABLE,
		"Grains" = ALLERGEN_GRAINS,
		"Beans" = ALLERGEN_BEANS,
		"Seeds and nuts" = ALLERGEN_SEEDS,
		"Dairy" = ALLERGEN_DAIRY,
		"Fungi" = ALLERGEN_FUNGI,
		"Coffee" = ALLERGEN_COFFEE,
		"Sugars" = ALLERGEN_SUGARS,
		"Eggs" = ALLERGEN_EGGS,
		"Stimulants" = ALLERGEN_STIMULANT,
		"Chocolate" = ALLERGEN_CHOCOLATE
	)
	var/list/allergens = list()
	for(var/allergen in allergen_names)
		if(drink.allergen_type & allergen_names[allergen])
			allergens += allergen
	var/alcohol = "Non-alcoholic"
	var/list/effects = list()
	var/temperature_change = 0
	if(istype(drink, /datum/reagent/ethanol))
		var/datum/reagent/ethanol/alcoholic_drink = drink
		if(alcoholic_drink.strength <= 10)
			alcohol = "Very strong alcohol"
		else if(alcoholic_drink.strength <= 20)
			alcohol = "Strong alcohol"
		else if(alcoholic_drink.strength <= 40)
			alcohol = "Moderate alcohol"
		else
			alcohol = "Mild alcohol"
		if(alcoholic_drink.druggy)
			effects += "Drugged sensation"
		if(alcoholic_drink.halluci)
			effects += "Hallucinations"
		temperature_change = alcoholic_drink.adj_temp
	else if(istype(drink, /datum/reagent/drink))
		var/datum/reagent/drink/soft_drink = drink
		if(soft_drink.adj_dizzy < 0)
			effects += "Reduces dizziness"
		else if(soft_drink.adj_dizzy > 0)
			effects += "Dizziness"
		if(soft_drink.adj_drowsy < 0 || soft_drink.adj_sleepy < 0)
			effects += "Reduces drowsiness"
		if(soft_drink.adj_drowsy > 0 || soft_drink.adj_sleepy > 0)
			effects += "Drowsiness"
		temperature_change = soft_drink.adj_temp
	if(temperature_change > 0)
		effects += "Warming"
	else if(temperature_change < 0)
		effects += "Cooling"
	return list("taste" = drink.taste_description, "alcohol" = alcohol, "allergens" = allergens, "effects" = effects)
