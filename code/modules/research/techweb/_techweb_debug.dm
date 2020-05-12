

/client/verb/DebugShowDesigns()
	set name = "Debug Show Designs"
	var/datum/asset/iconsheet/research_designs/icon_assets = get_asset_datum(/datum/asset/iconsheet/research_designs)
	icon_assets.send(src)

	var/list/lines = list()

	lines += "<table>"
	lines += "<tr>"
	lines += "<th>id</th>"
	lines += "<th>name</th>"
	lines += "<th>build_type</th>"
	lines += "<th>build_path</th>"
	lines += "<th>category</th>"
	lines += "<th>sort_string</th>"
	lines += "<th>dpt_flags</th>"
	lines += "<th>req_tech</th>"
	lines += "<th>icon</th>"
	lines += "</tr>"
	for(var/id in SSresearch.techweb_designs)
		var/datum/design/D = SSresearch.techweb_designs[id]
		lines += "<tr>"
		lines += "<td>[D.id]</td>"
		lines += "<td>[D.name]</td>"
		lines += "<td>[D.build_type_str()]</td>"
		lines += "<td>[D.build_path]</td>"
		lines += "<td>[D.category]</td>"
		lines += "<td>[D.sort_string]</td>"
		lines += "<td>[D.departmental_flags_str()]</td>"
		lines += "<td>[json_encode(D.req_tech)]</td>"
		lines += "<td>[icon_assets.icon_tag(D.id)]</td>"
		lines += "</tr>"
	lines += "</table>"

	var/datum/browser/popup = new(mob, "designsdebug", "Debugging Design List", 400, 800, src)
	popup.set_content(lines.Join())
	popup.add_head_content(icon_assets.css_tag())
	popup.open()


/datum/design/proc/departmental_flags_str()
	if(departmental_flags == ALL)
		return "ALL"
	if(departmental_flags == NONE)
		return ""
	var/list/dat = list()
	if(departmental_flags & DEPARTMENTAL_FLAG_SECURITY)
		dat += "SECURITY"
	if(departmental_flags & DEPARTMENTAL_FLAG_MEDICAL)
		dat += "MEDICAL"
	if(departmental_flags & DEPARTMENTAL_FLAG_CARGO)
		dat += "CARGO"
	if(departmental_flags & DEPARTMENTAL_FLAG_SCIENCE)
		dat += "SCIENCE"
	if(departmental_flags & DEPARTMENTAL_FLAG_ENGINEERING)
		dat += "ENGINEERING"
		return dat.Join("|")

/datum/design/proc/build_type_str()
	if(build_type == ALL)
		return "ALL"
	if(build_type == NONE)
		return ""
	var/list/dat = list()
	if(build_type & IMPRINTER)
		dat += "IMPRINTER"
	if(build_type & PROTOLATHE)
		dat += "PROTOLATHE"
	if(build_type & AUTOLATHE)
		dat += "AUTOLATHE"
	if(build_type & CRAFTLATHE)
		dat += "CRAFTLATHE"
	if(build_type & MECHFAB)
		dat += "MECHFAB"
	if(build_type & BIOGENERATOR)
		dat += "BIOGENERATOR"
	if(build_type & LIMBGROWER)
		dat += "LIMBGROWER"
	if(build_type & SMELTER)
		dat += "SMELTER"
	if(build_type & NANITE_COMPILER)
		dat += "NANITE_COMPILER"
	if(build_type & PROSFAB)
		dat += "PROSFAB"
	return dat.Join("|")
