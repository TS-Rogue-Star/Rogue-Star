//////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star September 2026: Vore Sprite Sheet Persistence //
//////////////////////////////////////////////////////////////////////////////////

#define VORE_SPRITESHEET_CACHE_REVISION 1

/datum/asset/spritesheet/vore_persistent
	_abstract = /datum/asset/spritesheet/vore_persistent
	var/vore_cache_key
	var/vore_cache_loaded = FALSE
	var/vore_cache_written = FALSE
	var/vore_cache_failure

/datum/asset/spritesheet/vore_persistent/proc/vore_cache_path()
	return "data/spritesheets/[name]_persistent_v[VORE_SPRITESHEET_CACHE_REVISION].json"

/datum/asset/spritesheet/vore_persistent/proc/vore_source_key(list/source_files)
	var/list/inputs = list(VORE_SPRITESHEET_CACHE_REVISION, name, world.byond_version, world.byond_build, "240x240|SOUTH|frame=1|moving=0|first-state-wins")
	for(var/source_file in source_files)
		var/digest = md5(fcopy_rsc(source_file))
		if(!istext(digest) || length(digest) != 32)
			return null
		inputs += list("[source_file]", digest)
	return md5(json_encode(inputs))

/datum/asset/spritesheet/vore_persistent/proc/vore_cache_miss(reason)
	vore_cache_failure = reason
	log_world("Vore sprite sheet [name]: persistent cache miss ([reason]).")
	return FALSE

/datum/asset/spritesheet/vore_persistent/proc/load_vore_cache(list/source_files)
	vore_cache_loaded = FALSE
	vore_cache_written = FALSE
	vore_cache_failure = null
	vore_cache_key = vore_source_key(source_files)
	if(!vore_cache_key)
		return vore_cache_miss("source hashing failed")
	if(!fexists(vore_cache_path()))
		return vore_cache_miss("no persisted cache")
	try
		return restore_vore_cache(json_decode(file2text(vore_cache_path())))
	catch(var/exception/e)
		return vore_cache_miss("invalid cache data: [e]")

/datum/asset/spritesheet/vore_persistent/proc/restore_vore_cache(list/metadata)
	if(!islist(metadata) || metadata["revision"] != VORE_SPRITESHEET_CACHE_REVISION || metadata["source_key"] != vore_cache_key)
		return vore_cache_miss("sources, BYOND build, or cache revision changed")
	var/list/cached_sprites = metadata["sprites"]
	var/list/files = metadata["files"]
	if(!islist(cached_sprites) || !cached_sprites.len || !islist(files) || files.len != 2)
		return vore_cache_miss("incomplete sprite or resource metadata")
	if(metadata["sprites_md5"] != md5(json_encode(cached_sprites)))
		return vore_cache_miss("sprite metadata checksum mismatch")
	var/list/used_indices = list()
	for(var/sprite_name in cached_sprites)
		var/list/sprite = cached_sprites[sprite_name]
		if(!istext(sprite_name) || !islist(sprite) || sprite.len != 2 || sprite[1] != "240x240")
			return vore_cache_miss("invalid sprite dimensions")
		var/index = sprite[2]
		if(!isnum(index) || index != round(index) || index < 0 || index >= cached_sprites.len || used_indices["[index]"])
			return vore_cache_miss("invalid sprite index")
		used_indices["[index]"] = TRUE
	var/list/resources = list()
	for(var/asset_name in list("[name]_240x240.png", "spritesheet_[name].css"))
		var/digest = files[asset_name]
		if(!istext(digest) || length(digest) != 32)
			return vore_cache_miss("invalid resource checksum")
		for(var/index in 1 to 32)
			if(!findtext("0123456789abcdef", copytext(digest, index, index + 1)))
				return vore_cache_miss("invalid resource checksum")
		var/path = "[vore_cache_path()].[digest].cache"
		if(!fexists(path) || rustg_hash_file(RUSTG_HASH_MD5, path) != digest)
			return vore_cache_miss("missing or damaged resource [asset_name]")
		var/resource = fcopy_rsc(path)
		if(!resource || md5(resource) != digest)
			return vore_cache_miss("could not load resource [asset_name]")
		resources[asset_name] = resource
	for(var/asset_name in resources)
		var/datum/asset_cache_item/existing = SSassets.cache[asset_name]
		if(existing && existing.md5 != files[asset_name])
			return vore_cache_miss("registered resource [asset_name] differs from the cache")
	for(var/asset_name in resources)
		if(!SSassets.cache[asset_name])
			register_asset(asset_name, resources[asset_name])
	sprites = cached_sprites
	sizes = list("240x240" = list(sprites.len, null, resources["[name]_240x240.png"]))
	vore_cache_loaded = TRUE
	log_world("Vore sprite sheet [name]: persistent cache hit ([sprites.len] sprites); scaling and sheet construction skipped.")
	return TRUE

/datum/asset/spritesheet/vore_persistent/generate_css()
	if(vore_cache_loaded)
		var/datum/asset_cache_item/css = SSassets.cache["spritesheet_[name].css"]
		return trim(file2text(css.resource))
	return ..()

/datum/asset/spritesheet/vore_persistent/proc/save_vore_cache()
	vore_cache_written = FALSE
	if(!vore_cache_key || !sprites.len || sizes.len != 1 || !sizes["240x240"])
		return FALSE
	try
		vore_cache_written = write_vore_cache()
	catch(var/exception/e)
		vore_cache_failure = "[e]"
	if(vore_cache_written)
		log_world("Vore sprite sheet [name]: persistent cache stored ([sprites.len] sprites).")
	else
		log_world("Vore sprite sheet [name]: could not persist cache; current assets remain available.")
	return vore_cache_written

/datum/asset/spritesheet/vore_persistent/proc/write_vore_cache()
	var/list/files = list()
	for(var/asset_name in get_url_mappings())
		var/datum/asset_cache_item/asset = SSassets.cache[asset_name]
		if(!asset?.resource || !asset.md5)
			return FALSE
		var/path = "[vore_cache_path()].[asset.md5].cache"
		if(!fexists(path) || rustg_hash_file(RUSTG_HASH_MD5, path) != asset.md5)
			fdel(path)
			if(!fcopy(asset.resource, path) || rustg_hash_file(RUSTG_HASH_MD5, path) != asset.md5)
				return FALSE
		files[asset_name] = asset.md5
	var/metadata = json_encode(list(
		"revision" = VORE_SPRITESHEET_CACHE_REVISION,
		"source_key" = vore_cache_key,
		"sprites" = sprites,
		"sprites_md5" = md5(json_encode(sprites)),
		"files" = files
	))
	var/path = vore_cache_path()
	var/temp_path = "[path].tmp"
	fdel(temp_path)
	if(!text2file(metadata, temp_path))
		return FALSE
	fdel(path)
	var/success = fcopy(temp_path, path)
	fdel(temp_path)
	return success

#undef VORE_SPRITESHEET_CACHE_REVISION
