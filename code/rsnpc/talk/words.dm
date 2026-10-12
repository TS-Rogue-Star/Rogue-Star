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
	phrase = npc_clean_line(phrase)
	if(line == phrase)
		return ""
	if(findtext(line, "[phrase] ") == 1)
		return copytext(line, length(phrase) + 2)
	return null

/proc/npc_starts_with(line, phrase)
	return !isnull(npc_words_after(line, phrase))

/proc/npc_has_words(line, phrase)
	return findtext(" [line] ", " [npc_clean_line(phrase)] ")

/proc/npc_name_forms(mob/living/M)
	. = list()
	var/full = npc_clean_line(M.name)
	var/list/words = splittext(full, " ")
	if(!full)
		return
	. |= full
	. |= words[1]
	. |= words[length(words)]
	if(M.job)
		. |= npc_clean_line(M.job)
	. -= ""

/proc/npc_after_name(line, mob/living/M)
	var/best
	for(var/form in npc_name_forms(M))
		if(length(form) > length(best) && npc_starts_with(line, form))
			best = form
	if(!best)
		return null
	return npc_words_after(line, best)

/proc/npc_named_in(line, mob/living/M)
	for(var/form in npc_name_forms(M))
		if(npc_has_words(line, form))
			return TRUE
	return FALSE
