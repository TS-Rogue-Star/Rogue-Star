/obj/structure/proc/can_visually_connect()
	return anchored

/obj/structure/proc/can_visually_connect_to(var/obj/structure/S)
	return istype(S, src)

/proc/place_grille(mob/user, loc, obj/item/stack/rods/ST)
	if(ST.get_amount() < 2)
		to_chat(user, "<span class='warning'>You need at least two rods to do this.</span>")
		return
	to_chat(user, "<span class='notice'>Assembling grille...</span>")
	if (!do_after(user, 10))
		return
	if(!ST.use(2))
		return
	var/obj/structure/grille/F = new /obj/structure/grille(loc)
	to_chat(user, "<span class='notice'>You assemble a grille</span>")
	F.add_fingerprint(user)

/proc/place_window(mob/user, loc, dir_to_set, obj/item/stack/ST)
	var/required_amount = (dir_to_set & (dir_to_set - 1)) ? 4 : 1
	if (ST.get_amount() < required_amount)
		to_chat(user, "<span class='notice'>You do not have enough sheets.</span>")
		return
	for(var/obj/structure/window/WINDOW in loc)
		if(WINDOW.dir == dir_to_set)
			to_chat(user, "<span class='notice'>There is already a window facing this way there.</span>")
			return
		if(WINDOW.is_fulltile() && (dir_to_set & (dir_to_set - 1))) //two fulltile windows
			to_chat(user, "<span class='notice'>There is already a window there.</span>")
			return
	to_chat(user, "<span class='notice'>You start placing the window.</span>")
	if(do_after(user,20))
		for(var/obj/structure/window/WINDOW in loc)
			if(WINDOW.dir == dir_to_set)//checking this for a 2nd time to check if a window was made while we were waiting.
				to_chat(user, "<span class='notice'>There is already a window facing this way there.</span>")
				return
			if(WINDOW.is_fulltile() && (dir_to_set & (dir_to_set - 1)))
				to_chat(user, "<span class='notice'>There is already a window there.</span>")
				return

		if (ST.use(required_amount))
			var/obj/structure/window/WD = new(loc, dir_to_set, FALSE)
			to_chat(user, "<span class='notice'>You place [WD].</span>")
			WD.state = 0
			WD.anchored = 0
		else
			to_chat(user, "<span class='notice'>You do not have enough sheets.</span>")
			return

// Comes up with the minimal thing to add to the first argument so that the new list guarantees that the access requirement in the second argument is satisfied.
// Second argument is a number access code or list thereof (like an entry in req_access); the typecasting is false.
/proc/get_minimal_requirement(list/req_access, list/requirement)
	if(!requirement)
		return
	if(!islist(requirement))
		return (requirement in req_access) ? null : requirement
	for(var/req in req_access)
		if(req in requirement)
			return // have one of the requirements, and these use OR, so we're good
		if(islist(req))
			var/fully_contained = TRUE // In this case we check if we are already requiring something more stringent than the new thing.
			for(var/one_req in req)
				if(!(one_req in requirement))
					fully_contained = FALSE
					break
			if(fully_contained)
				return
	return requirement.Copy()

// Modifies req_access in place. Ensures that the list remains miminal.
/proc/add_access_requirement(list/req_access, requirement)
	var/minimal = get_minimal_requirement(req_access, requirement)
	if(minimal)
		req_access[++req_access.len] = minimal

// Given two areas, find the minimal req_access needed such that (return value) + (area access) >= (other area access) and vice versa
/proc/req_access_diff(area/first, area/second)
	if(!length(first.req_access))
		return second.req_access.Copy()
	if(!length(second.req_access))
		return first.req_access.Copy()
	. = list()
	for(var/requirement in first.req_access)
		add_access_requirement(., get_minimal_requirement(second.req_access, requirement))
	for(var/requirement in second.req_access)
		add_access_requirement(., get_minimal_requirement(first.req_access, requirement))

// Given two areas, find the minimal req_access needed such that req_access >= (area access) + (other area access)
/proc/req_access_union(area/first, area/second)
	if(!length(first.req_access))
		return second.req_access.Copy()
	if(!length(second.req_access))
		return first.req_access.Copy()
	. = first.req_access.Copy()
	for(var/requirement in second.req_access)
		add_access_requirement(., requirement)