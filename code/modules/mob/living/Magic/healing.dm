//RS FILE
/////HEALING MAGIC/////

#define HEALING_MAGIC "healing"

/mob/living/proc/regenerate_other()
	set name = "Regenerate"
	set desc = "Spend energy to heal physical wounds in another creature."
	set category = "Magic"

	if(!etching)
		to_chat("<span class='warning'>You can't do magic.</span>")	//:C
		return FALSE

	var/spell_lv = 1					//Determines how many slots you need devoted to this magic
	var/spell_class = HEALING_MAGIC		//Used with above, this is the kind of magic you need
	var/req_standing = TRUE				//If true, must be on your feet and unrestrained
	var/req_corporeal = TRUE			//If true, must not be phased out or otherwise ghostly
	var/req_visible = TRUE				//If true, must not be invisible
	var/cost = 0						//Automatically determined by a variety of factors

	if(!admin_magic)
		cost = etching.calculate_magic_cost(spell_class,spell_lv)

	if(!consider_magic(cost,spell_class,spell_lv,req_standing,req_corporeal,req_visible))
		return FALSE

	//Unique stuff goes beween here!

	var/list/viewed = oviewers(1)
	var/list/targets = list()
	for(var/mob/living/L in viewed)
		targets += L
	if(!targets.len)
		to_chat(src,"<span class='warning'>Nobody nearby to mend!</span>")
		return FALSE

	var/mob/living/target = tgui_input_list(src,"Pick someone to mend:","Mend Other", targets)
	if(!target)
		return FALSE

	target.add_modifier(/datum/modifier/shadekin/heal_boop,1 MINUTE)
	playsound(src, 'sound/effects/EMPulse.ogg', 75, 1)
	visible_message("<span class='notice'>\The [src] touches \the [target]...</span>")
	face_atom(target)

	//STOP BEING UNIQUE

	consume_mana(cost, spell_lv)
	return TRUE
