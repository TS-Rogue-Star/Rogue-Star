/datum/npc_heap
	var/list/items = list()
	var/list/costs = list()
	var/list/guesses = list()
	var/list/orders = list()
	var/added = 0

/datum/npc_heap/proc/add(item, cost, guess)
	items += item
	costs += cost
	guesses += guess
	orders += ++added
	var/i = length(items)
	while(i > 1)
		var/up = round(i / 2)
		if(!before(i, up))
			break
		swap(i, up)
		i = up

/datum/npc_heap/proc/take()
	var/n = length(items)
	if(!n)
		return null
	. = items[1]
	swap(1, n)
	items.len--
	costs.len--
	guesses.len--
	orders.len--
	n--
	var/i = 1
	while(TRUE)
		var/best = i
		var/left = i * 2
		var/right = left + 1
		if(left <= n && before(left, best))
			best = left
		if(right <= n && before(right, best))
			best = right
		if(best == i)
			break
		swap(i, best)
		i = best

/datum/npc_heap/proc/is_empty()
	return !length(items)

/datum/npc_heap/proc/before(a, b)
	if(costs[a] != costs[b])
		return costs[a] < costs[b]
	if(guesses[a] != guesses[b])
		return guesses[a] < guesses[b]
	return orders[a] < orders[b]

/datum/npc_heap/proc/swap(a, b)
	items.Swap(a, b)
	costs.Swap(a, b)
	guesses.Swap(a, b)
	orders.Swap(a, b)
