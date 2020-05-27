//////// Arms and Ammunition Autolathe Designs ////////
/datum/design/autolathe/arms
	category = "Arms and Ammunition"


/datum/design/autolathe/arms/syringegun_ammo
	name = "syringe gun cartridge"
	id = "syringegun_ammo"
	materials = list(DEFAULT_WALL_MATERIAL = 125, MAT_GLASS = 375)
	build_path = /obj/item/weapon/syringe_cartridge

////////////////
/*Ammo casings*/
////////////////

/datum/design/autolathe/arms/shotgun_blanks
	name = "ammunition (12g, blank)"
	id = "shotgun_blanks"
	materials = list(DEFAULT_WALL_MATERIAL = 90)
	build_path = /obj/item/ammo_casing/a12g/blank

/datum/design/autolathe/arms/shotgun_beanbag
	name = "ammunition (12g, beanbag)"
	id = "shotgun_beanbag"
	materials = list(DEFAULT_WALL_MATERIAL = 180)
	build_path = /obj/item/ammo_casing/a12g/beanbag

/datum/design/autolathe/arms/shotgun_flash
	name = "ammunition (12g, flash)"
	id = "shotgun_flash"
	materials = list(DEFAULT_WALL_MATERIAL = 90, MAT_GLASS = 90)
	build_path = /obj/item/ammo_casing/a12g/flash

/datum/design/autolathe/arms/shotgun
	name = "ammunition (12g, slug)"
	id = "shotgun"
	materials = list(DEFAULT_WALL_MATERIAL = 360)
	build_path = /obj/item/ammo_casing/a12g
	contraband = TRUE

/datum/design/autolathe/arms/shotgun_pellet
	name = "ammunition (12g, pellet)"
	id = "shotgun_pellet"
	materials = list(DEFAULT_WALL_MATERIAL = 360)
	build_path = /obj/item/ammo_casing/a12g/pellet
	contraband = TRUE

/* Disabled for autolathes.  This requires research so it should be protolathe only.
/datum/design/autolathe/arms/stunshell
	name = "ammunition (stun cartridge, shotgun)"
	id = "stunshell"
	materials = list(DEFAULT_WALL_MATERIAL = 360, MAT_GLASS = 720)
	build_path = /obj/item/ammo_casing/a12g/stunshell
	contraband = TRUE
*/

//////////////////
/*Ammo magazines*/
//////////////////

/////// 5mm
/*
/datum/category_item/autolathe/arms/pistol_5mm
	name = "pistol magazine (5mm)"
	path =/obj/item/ammo_magazine/c5mm
	category = "Arms and Ammunition"
	hidden = 1
*/

/////// .45
/datum/design/autolathe/arms/pistol_45
	name = "pistol magazine (.45)"
	id = "pistol_45"
	materials = list(DEFAULT_WALL_MATERIAL = 525)
	build_path = /obj/item/ammo_magazine/m45
	contraband = TRUE

/datum/design/autolathe/arms/pistol_45p
	name = "pistol magazine (.45 practice)"
	id = "pistol_45p"
	materials = list(DEFAULT_WALL_MATERIAL = 525)
	build_path = /obj/item/ammo_magazine/m45/practice

/datum/design/autolathe/arms/pistol_45r
	name = "pistol magazine (.45 rubber)"
	id = "pistol_45r"
	materials = list(DEFAULT_WALL_MATERIAL = 525)
	build_path = /obj/item/ammo_magazine/m45/rubber

/datum/design/autolathe/arms/pistol_45f
	name = "pistol magazine (.45 flash)"
	id = "pistol_45f"
	materials = list(DEFAULT_WALL_MATERIAL = 525)
	build_path = /obj/item/ammo_magazine/m45/flash

/datum/design/autolathe/arms/pistol_45uzi
	name = "uzi magazine (.45)"
	id = "pistol_45uzi"
	materials = list(DEFAULT_WALL_MATERIAL = 1200)
	build_path = /obj/item/ammo_magazine/m45uzi
	contraband = TRUE

/datum/design/autolathe/arms/tommymag
	name = "Tommy Gun magazine (.45)"
	id = "tommymag"
	materials = list(DEFAULT_WALL_MATERIAL = 1500)
	build_path = /obj/item/ammo_magazine/m45tommy
	contraband = TRUE

/datum/design/autolathe/arms/tommydrum
	name = "Tommy Gun drum magazine (.45)"
	id = "tommydrum"
	materials = list(DEFAULT_WALL_MATERIAL = 3750)
	build_path = /obj/item/ammo_magazine/m45tommydrum
	contraband = TRUE

/////// 9mm

// Full size pistol mags.
/datum/design/autolathe/arms/pistol_9mm
	name = "pistol magazine (9mm)"
	id = "pistol_9mm"
	materials = list(DEFAULT_WALL_MATERIAL = 600)
	build_path = /obj/item/ammo_magazine/m9mm
	contraband = TRUE

/datum/design/autolathe/arms/pistol_9mmr
	name = "pistol magazine (9mm rubber)"
	id = "pistol_9mmr"
	materials = list(DEFAULT_WALL_MATERIAL = 600)
	build_path = /obj/item/ammo_magazine/m9mm/rubber

/datum/design/autolathe/arms/pistol_9mmp
	name = "pistol magazine (9mm practice)"
	id = "pistol_9mmp"
	materials = list(DEFAULT_WALL_MATERIAL = 600)
	build_path = /obj/item/ammo_magazine/m9mm/practice

/datum/design/autolathe/arms/pistol_9mmf
	name = "pistol magazine (9mm flash)"
	id = "pistol_9mmf"
	materials = list(DEFAULT_WALL_MATERIAL = 600)
	build_path = /obj/item/ammo_magazine/m9mm/flash

// Small mags for small or old guns.
/datum/design/autolathe/arms/pistol_9mm_compact
	name = "compact pistol magazine (9mm)"
	id = "pistol_9mm_compact"
	materials = list(DEFAULT_WALL_MATERIAL = 480)
	build_path = /obj/item/ammo_magazine/m9mm/compact
	contraband = TRUE

/datum/design/autolathe/arms/pistol_9mmr_compact
	name = "compact pistol magazine (9mm rubber)"
	id = "pistol_9mmr_compact"
	materials = list(DEFAULT_WALL_MATERIAL = 480)
	build_path = /obj/item/ammo_magazine/m9mm/compact/rubber
	contraband = TRUE // These are all hidden because they are traitor mags and will otherwise just clutter the Autolathe.

/datum/design/autolathe/arms/pistol_9mmp_compact
	name = "compact pistol magazine (9mm practice)"
	id = "pistol_9mmp_compact"
	materials = list(DEFAULT_WALL_MATERIAL = 480)
	build_path = /obj/item/ammo_magazine/m9mm/compact/practice
	contraband = TRUE

/datum/design/autolathe/arms/pistol_9mmf_compact
	name = "compact pistol magazine (9mm flash)"
	id = "pistol_9mmf_compact"
	materials = list(DEFAULT_WALL_MATERIAL = 480)
	build_path = /obj/item/ammo_magazine/m9mm/compact/flash
	contraband = TRUE

// SMG mags
/datum/design/autolathe/arms/smg_9mm
	name = "top-mounted SMG magazine (9mm)"
	id = "smg_9mm"
	materials = list(DEFAULT_WALL_MATERIAL = 1200)
	build_path = /obj/item/ammo_magazine/m9mmt
	contraband = TRUE

/datum/design/autolathe/arms/smg_9mmr
	name = "top-mounted SMG magazine (9mm rubber)"
	id = "smg_9mmr"
	materials = list(DEFAULT_WALL_MATERIAL = 1200)
	build_path = /obj/item/ammo_magazine/m9mmt/rubber

/datum/design/autolathe/arms/smg_9mmp
	name = "top-mounted SMG magazine (9mm practice)"
	id = "smg_9mmp"
	materials = list(DEFAULT_WALL_MATERIAL = 1200)
	build_path = /obj/item/ammo_magazine/m9mmt/practice

/datum/design/autolathe/arms/smg_9mmf
	name = "top-mounted SMG magazine (9mm flash)"
	id = "smg_9mmf"
	materials = list(DEFAULT_WALL_MATERIAL = 1200)
	build_path = /obj/item/ammo_magazine/m9mmt/flash

/////// 10mm
/datum/design/autolathe/arms/smg_10mm
	name = "SMG magazine (10mm)"
	id = "smg_10mm"
	materials = list(DEFAULT_WALL_MATERIAL = 1500)
	build_path = /obj/item/ammo_magazine/m10mm
	contraband = TRUE

/datum/design/autolathe/arms/pistol_44
	name = "pistol magazine (.44)"
	id = "pistol_44"
	materials = list(DEFAULT_WALL_MATERIAL = 1260)
	build_path = /obj/item/ammo_magazine/m44
	contraband = TRUE

/////// 5.45mm
/datum/design/autolathe/arms/rifle_545
	name = "rifle magazine (5.45mm)"
	id = "rifle_545"
	materials = list(DEFAULT_WALL_MATERIAL = 1800)
	build_path = /obj/item/ammo_magazine/m545
	contraband = TRUE

/datum/design/autolathe/arms/rifle_545p
	name = "rifle magazine (5.45mm practice)"
	id = "rifle_545p"
	materials = list(DEFAULT_WALL_MATERIAL = 1800)
	build_path = /obj/item/ammo_magazine/m545/practice

/*/datum/category_item/autolathe/arms/rifle_545_hunter //VOREStation Edit Start. By request of Ace
	name = "rifle magazine (5.45mm hunting)"
	path =/obj/item/ammo_magazine/m545/hunter*/ //VOREStation Edit End.

/datum/design/autolathe/arms/machinegun_545
	name = "machinegun box magazine (5.45)"
	id = "machinegun_545"
	materials = list(DEFAULT_WALL_MATERIAL = 10000)
	build_path = /obj/item/ammo_magazine/m545saw
	contraband = TRUE

/*/datum/category_item/autolathe/arms/machinegun_545_hunter //VOREStation Edit Start. By request of Ace
	name = "machinegun box magazine (5.45 hunting)"
	path =/obj/item/ammo_magazine/m545saw/hunter
	hidden = 1*/ //VOREStation Edit End.

/////// 7.62

/datum/design/autolathe/arms/rifle_762
	name = "rifle magazine (7.62mm)"
	id = "rifle_762"
	materials = list(DEFAULT_WALL_MATERIAL = 2000)
	build_path = /obj/item/ammo_magazine/m762
	contraband = TRUE

/*
/datum/category_item/autolathe/arms/rifle_small_762
	name = "rifle magazine (7.62mm)"
	path =/obj/item/ammo_magazine/s762
	hidden = 1
*/

/////// Shotgun

/datum/design/autolathe/arms/shotgun_clip_beanbag
	name = "2-round 12g speedloader (beanbag)"
	id = "shotgun_clip_beanbag"
	materials = list(DEFAULT_WALL_MATERIAL = 710)
	build_path = /obj/item/ammo_magazine/clip/c12g/beanbag

/datum/design/autolathe/arms/shotgun_clip_slug
	name = "2-round 12g speedloader (slug)"
	id = "shotgun_clip_slug"
	materials = list(DEFAULT_WALL_MATERIAL = 1070)
	build_path = /obj/item/ammo_magazine/clip/c12g
	contraband = TRUE

/datum/design/autolathe/arms/shotgun_clip_pellet
	name = "2-round 12g speedloader (buckshot)"
	id = "shotgun_clip_pellet"
	materials = list(DEFAULT_WALL_MATERIAL = 1070)
	build_path = /obj/item/ammo_magazine/clip/c12g/pellet
	contraband = TRUE

/* Commented out until autolathe stuff is decided/fixed. Will probably remove these entirely. -Spades
// These should always be/empty! The idea is to fill them up manually with ammo clips.

/datum/category_item/autolathe/arms/pistol_5mm
	name = "pistol magazine (5mm)"
	path =/obj/item/ammo_magazine/c5mm/empty
	category = "Arms and Ammunition"
	hidden = 1

/datum/category_item/autolathe/arms/smg_5mm
	name = "top-mounted SMG magazine (5mm)"
	path =/obj/item/ammo_magazine/c5mmt/empty
	category = "Arms and Ammunition"
	hidden = 1

/datum/category_item/autolathe/arms/pistol_45
	name = "pistol magazine (.45)"
	path =/obj/item/ammo_magazine/m45/empty
	category = "Arms and Ammunition"

/datum/category_item/autolathe/arms/pistol_45uzi
	name = "uzi magazine (.45)"
	path =/obj/item/ammo_magazine/m45uzi/empty
	category = "Arms and Ammunition"
	hidden = 1

/datum/category_item/autolathe/arms/tommymag
	name = "Tommy Gun magazine (.45)"
	path =/obj/item/ammo_magazine/m45tommy/empty
	category = "Arms and Ammunition"
	hidden = 1

/datum/category_item/autolathe/arms/tommydrum
	name = "Tommy Gun drum magazine (.45)"
	path =/obj/item/ammo_magazine/m45tommydrum/empty
	category = "Arms and Ammunition"
	hidden = 1

/datum/category_item/autolathe/arms/pistol_9mm
	name = "pistol magazine (9mm)"
	path =/obj/item/ammo_magazine/m9mm/empty
	category = "Arms and Ammunition"

/datum/category_item/autolathe/arms/smg_9mm
	name = "top-mounted SMG magazine (9mm)"
	path =/obj/item/ammo_magazine/m9mmt/empty
	category = "Arms and Ammunition"

/datum/category_item/autolathe/arms/smg_10mm
	name = "SMG magazine (10mm)"
	path =/obj/item/ammo_magazine/m10mm/empty
	category = "Arms and Ammunition"
	hidden = 1

/datum/category_item/autolathe/arms/pistol_44
	name = "pistol magazine (.44)"
	path =/obj/item/ammo_magazine/m44/empty
	category = "Arms and Ammunition"
	hidden = 1

/datum/category_item/autolathe/arms/rifle_545
	name = "10rnd rifle magazine (5.45mm)"
	path =/obj/item/ammo_magazine/m545saw/empty
	category = "Arms and Ammunition"

/datum/category_item/autolathe/arms/rifle_545m
	name = "20rnd rifle magazine (5.45mm)"
	path =/obj/item/ammo_magazine/m545sawm/empty
	category = "Arms and Ammunition"
	hidden = 1

/datum/category_item/autolathe/arms/rifle_SVD
	name = "10rnd rifle magazine (7.62mm)"
	path =/obj/item/ammo_magazine/m762svd/empty
	category = "Arms and Ammunition"
	hidden = 1

/datum/category_item/autolathe/arms/rifle_762
	name = "20rnd rifle magazine (7.62mm)"
	path =/obj/item/ammo_magazine/m762/empty
	category = "Arms and Ammunition"
	hidden = 1

/datum/category_item/autolathe/arms/machinegun_762
	name = "machinegun box magazine (7.62)"
	path =/obj/item/ammo_magazine/a762/empty
	category = "Arms and Ammunition"
	hidden = 1

/datum/category_item/autolathe/arms/shotgun_magazine
	name = "24rnd shotgun magazine (12g)"
	path =/obj/item/ammo_magazine/m12gdrum/empty
	category = "Arms and Ammunition"
	hidden = 1*/

///////////////////////////////
/*Ammo clips and Speedloaders*/
///////////////////////////////

/datum/design/autolathe/arms/speedloader_357
	name = "speedloader (.357)"
	id = "speedloader_357"
	materials = list(DEFAULT_WALL_MATERIAL = 1260)
	build_path = /obj/item/ammo_magazine/s357
	contraband = TRUE

/datum/design/autolathe/arms/speedloader_38
	name = "speedloader (.38)"
	id = "speedloader_38"
	materials = list(DEFAULT_WALL_MATERIAL = 360)
	build_path = /obj/item/ammo_magazine/s38
	contraband = TRUE

/datum/design/autolathe/arms/speedloader_38r
	name = "speedloader (.38 rubber)"
	id = "speedloader_38r"
	materials = list(DEFAULT_WALL_MATERIAL = 360)
	build_path = /obj/item/ammo_magazine/s38/rubber

/datum/design/autolathe/arms/speedloader_45
	name = "speedloader (.45)"
	id = "speedloader_45"
	materials = list(DEFAULT_WALL_MATERIAL = 525)
	build_path = /obj/item/ammo_magazine/s45
	contraband = TRUE

/datum/design/autolathe/arms/speedloader_45r
	name = "speedloader (.45 rubber)"
	id = "speedloader_45r"
	materials = list(DEFAULT_WALL_MATERIAL = 525)
	build_path = /obj/item/ammo_magazine/s45/rubber

// Commented out until metal exploits with autolathe is fixed.
/*/datum/category_item/autolathe/arms/pistol_clip_45
	name = "ammo clip (.45)"
	path =/obj/item/ammo_magazine/clip/c45
	category = "Arms and Ammunition"
	hidden = 1

/datum/category_item/autolathe/arms/pistol_clip_45r
	name = "ammo clip (.45 rubber)"
	path =/obj/item/ammo_magazine/clip/c45/rubber
	category = "Arms and Ammunition"

/datum/category_item/autolathe/arms/pistol_clip_45f
	name = "ammo clip (.45 flash)"
	path =/obj/item/ammo_magazine/clip/c45/flash
	category = "Arms and Ammunition"

/datum/category_item/autolathe/arms/pistol_clip_45p
	name = "ammo clip (.45 practice)"
	path =/obj/item/ammo_magazine/clip/c45/practice
	category = "Arms and Ammunition"

/datum/category_item/autolathe/arms/pistol_clip_9mm
	name = "ammo clip (9mm)"
	path =/obj/item/ammo_magazine/clip/c9mm
	category = "Arms and Ammunition"
	hidden = 1

/datum/category_item/autolathe/arms/pistol_clip_9mmr
	name = "ammo clip (9mm rubber)"
	path =/obj/item/ammo_magazine/clip/c9mm/rubber
	category = "Arms and Ammunition"

/datum/category_item/autolathe/arms/pistol_clip_9mmp
	name = "ammo clip (9mm practice)"
	path =/obj/item/ammo_magazine/clip/c9mm/practice
	category = "Arms and Ammunition"

/datum/category_item/autolathe/arms/pistol_clip_9mmf
	name = "ammo clip (9mm flash)"
	path =/obj/item/ammo_magazine/clip/c9mm/flash
	category = "Arms and Ammunition"

/datum/category_item/autolathe/arms/pistol_clip_5mm
	name = "ammo clip (5mm)"
	path =/obj/item/ammo_magazine/clip/c5mm
	category = "Arms and Ammunition"
	hidden = 1

/datum/category_item/autolathe/arms/pistol_clip_10mm
	name = "ammo clip (10mm)"
	path =/obj/item/ammo_magazine/clip/c10mm
	category = "Arms and Ammunition"
	hidden = 1

/datum/category_item/autolathe/arms/pistol_clip_50
	name = "ammo clip (.44)"
	path =/obj/item/ammo_magazine/clip/c50
	category = "Arms and Ammunition"
	hidden = 1
*/

/datum/design/autolathe/arms/rifle_clip_545
	name = "ammo clip (5.45mm)"
	id = "rifle_clip_545"
	materials = list(DEFAULT_WALL_MATERIAL = 450)
	build_path = /obj/item/ammo_magazine/clip/c545
	contraband = TRUE

/datum/design/autolathe/arms/rifle_clip_545_practice
	name = "ammo clip (5.45mm practice)"
	id = "rifle_clip_545_practice"
	materials = list(DEFAULT_WALL_MATERIAL = 450)
	build_path = /obj/item/ammo_magazine/clip/c545/practice

/datum/design/autolathe/arms/rifle_clip_762
	name = "ammo clip (7.62mm)"
	id = "rifle_clip_762"
	materials = list(DEFAULT_WALL_MATERIAL = 1000)
	build_path = /obj/item/ammo_magazine/clip/c762
	contraband = TRUE

/*/datum/category_item/autolathe/arms/rifle_clip_762_hunter //VOREStation Edit Start. By request of Ace
	name = "ammo clip (7.62mm hunting)"
	path =/obj/item/ammo_magazine/clip/c762/hunter*/ //VOREStation Edit End.

/datum/design/autolathe/arms/rifle_clip_762_practice
	name = "ammo clip (7.62mm practice)"
	id = "rifle_clip_762_practice"
	materials = list(DEFAULT_WALL_MATERIAL = 1000)
	build_path = /obj/item/ammo_magazine/clip/c762/practice

///////////////////
/* Other Weapons */
///////////////////

/datum/design/autolathe/arms/knuckledusters
	name = "knuckle dusters"
	id = "knuckledusters"
	materials = list(DEFAULT_WALL_MATERIAL = 500)
	build_path = /obj/item/clothing/gloves/knuckledusters
	contraband = TRUE

/datum/design/autolathe/arms/tacknife
	name = "tactical knife"
	id = "tacknife"
	materials = list(DEFAULT_WALL_MATERIAL = 500)
	build_path = /obj/item/weapon/material/knife/tacknife
	contraband = TRUE

/datum/design/autolathe/arms/flamethrower
	name = "flamethrower"
	id = "flamethrower"
	materials = list(DEFAULT_WALL_MATERIAL = 500)
	build_path = /obj/item/weapon/flamethrower/full
	contraband = TRUE
