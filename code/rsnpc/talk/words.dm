/mob/living
	var/tmp/npc_cached_name
	var/tmp/npc_cached_job
	var/tmp/list/npc_cached_name_forms

/proc/npc_clean_line(text)
	text = lowertext(strip_html_properly(html_decode("[text]")))
	var/list/words = list()
	for(var/word in splittext(text, " "))
		while(length(word) > 2 && copytext(word, 2, 3) == "-" && copytext(word, 1, 2) == copytext(word, 3, 4))
			word = copytext(word, 3)
		words += word
	text = jointext(words, " ")
	. = ""
	var/last = " "
	for(var/i in 1 to length_char(text))
		var/c = text2ascii_char(text, i)
		var/letter
		if(c >= 97 && c <= 122)
			letter = ascii2text(c)
		else if(c < 128)
			letter = " "
		else
			continue
		if(letter == last)
			continue
		. += letter
		last = letter
	return trim(.)

/proc/npc_words_after(line, phrase)
	return npc_words_after_clean(line, npc_clean_line(phrase))

/proc/npc_words_after_clean(line, phrase)
	if(line == phrase)
		return ""
	if(findtext(line, "[phrase] ") == 1)
		return copytext(line, length(phrase) + 2)
	return null

/proc/npc_starts_with(line, phrase)
	return npc_starts_with_clean(line, npc_clean_line(phrase))

/proc/npc_starts_with_clean(line, phrase)
	return line == phrase || findtext(line, "[phrase] ") == 1

/proc/npc_has_words(line, phrase)
	return npc_has_words_clean(line, npc_clean_line(phrase))

/proc/npc_has_words_clean(line, phrase)
	return findtext(" [line] ", " [phrase] ")

/proc/npc_name_forms(mob/living/M, own)
	var/name = own ? M.real_name : M.name
	if(!isnull(M.npc_cached_name_forms) && M.npc_cached_name == name && M.npc_cached_job == M.job)
		return M.npc_cached_name_forms
	M.npc_cached_name = name
	M.npc_cached_job = M.job
	M.npc_cached_name_forms = list()
	. = M.npc_cached_name_forms
	var/full = npc_clean_line(name)
	var/list/words = splittext(full, " ")
	if(!full)
		return
	. |= full
	. |= words[1]
	. |= words[length(words)]
	if(M.job)
		. |= npc_clean_line(M.job)
	. -= ""

/proc/npc_after_name(line, mob/living/M, list/name_matches, own)
	if(name_matches && (M in name_matches))
		return name_matches[M]
	var/best
	for(var/form in npc_name_forms(M, own))
		if(length(form) > length(best) && npc_starts_with_clean(line, form))
			best = form
	. = best ? npc_words_after_clean(line, best) : null
	if(name_matches)
		name_matches[M] = .

/proc/npc_named_in(line, mob/living/M, own)
	for(var/form in npc_name_forms(M, own))
		if(npc_has_words_clean(line, form))
			return TRUE
	return FALSE
