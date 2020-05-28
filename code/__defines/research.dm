#define SHEET_MATERIAL_AMOUNT 2000

#define INVESTIGATE_RESEARCH "research"

/// D-D-DEPRECATED! These were for the old origin_tech research system.
#define TECH_MATERIAL "materials"
#define TECH_ENGINEERING "engineering"
#define TECH_PHORON "phorontech"
#define TECH_POWER "powerstorage"
#define TECH_BLUESPACE "bluespace"
#define TECH_BIO "biotech"
#define TECH_COMBAT "combat"
#define TECH_MAGNET "magnets"
#define TECH_DATA "programming"
#define TECH_ILLEGAL "syndicate"
#define TECH_ARCANE "arcane"
#define TECH_PRECURSOR "precursor"

// Common states for machines with a construction queue
#define BUILD_IDLE		1	// Not building anything.
#define BUILD_WORKING	2	// Currently building first thing in queue
#define BUILD_PAUSED	3	// Voluntarily paused by user command
#define BUILD_ERROR		4	// Cannot continue building (low materials, broken, panel open, etc.)

/// Used in [/datum/design][designs] to specify which machine(s) can build it
#define IMPRINTER		(1<<0)	// For circuits. Uses glass/chemicals.
#define PROTOLATHE		(1<<1)	// New stuff. Uses glass/metal/chemicals
#define AUTOLATHE		(1<<2)	// Uses glass/metal only.
#define CRAFTLATHE		(1<<3)	// Uses fuck if I know. For use eventually.
#define MECHFAB			(1<<4)	// Remember, objects utilising this flag should have construction_time and construction_cost vars.
#define BIOGENERATOR	(1<<5)	// Uses biomass
#define LIMBGROWER		(1<<6)	// Prints natural limbs probably
#define SMELTER			(1<<7)	// uses various minerals
#define NANITE_COMPILER	(1<<8)	// Prints nanite disks
#define PROSFAB			(1<<9)	//For prosthetics/FBP fab
// Note: More than one of these can be added to a design but imprinter and lathe designs are incompatable.

/// Department flags for techwebs. Defines which department can print what from each protolathe so Cargo can't print guns, etc.
#define DEPARTMENTAL_FLAG_SECURITY		(1<<0)
#define DEPARTMENTAL_FLAG_MEDICAL		(1<<1)
#define DEPARTMENTAL_FLAG_CARGO			(1<<2)
#define DEPARTMENTAL_FLAG_SCIENCE		(1<<3)
#define DEPARTMENTAL_FLAG_ENGINEERING	(1<<4)
#define DEPARTMENTAL_FLAG_SERVICE		(1<<5)

///For instances where we don't want a design showing up due to it being for debug/sanity purposes
#define DESIGN_ID_IGNORE "IGNORE_THIS_DESIGN"

/// Special id that tells the destructive analyzer to destroy for raw points/materials instead of boosting.
#define RESEARCH_MATERIAL_RECLAMATION_ID "__materials"

/// Techweb names for new point types. Can be used to define specific point values for specific types of research (science, security, engineering, etc.)
#define TECHWEB_POINT_TYPE_GENERIC "General Research"
#define TECHWEB_POINT_TYPE_NANITES "Nanite Research"

#define TECHWEB_POINT_TYPE_DEFAULT TECHWEB_POINT_TYPE_GENERIC

/// Associative names for techweb point values, see: [/modules/research/techweb/all_nodes][all_nodes]
#define TECHWEB_POINT_TYPE_LIST_ASSOCIATIVE_NAMES list(\
	TECHWEB_POINT_TYPE_GENERIC = "General Research",\
	TECHWEB_POINT_TYPE_NANITES = "Nanite Research"\
	)

// If construction/redemption efficiency ratings apply. If not, always use 100% conversion
#define MATERIAL_EFFICIENT(A) (!(ispath(A, /obj/item/stack/material) || istype(A, /obj/item/stack/material)))

/// Constants for the different screens in R&D console and machinery UIs
#define RDSCREEN_MENU 0
#define RDSCREEN_TECHDISK 1
#define RDSCREEN_DESIGNDISK 20
#define RDSCREEN_DESIGNDISK_UPLOAD 21
#define RDSCREEN_DECONSTRUCT 3
#define RDSCREEN_PROTOLATHE 40
#define RDSCREEN_PROTOLATHE_MATERIALS 41
#define RDSCREEN_PROTOLATHE_CHEMICALS 42
#define RDSCREEN_PROTOLATHE_CATEGORY_VIEW 43
#define RDSCREEN_PROTOLATHE_SEARCH 44
#define RDSCREEN_PROTOLATHE_QUEUE 45
#define RDSCREEN_IMPRINTER 50
#define RDSCREEN_IMPRINTER_MATERIALS 51
#define RDSCREEN_IMPRINTER_CHEMICALS 52
#define RDSCREEN_IMPRINTER_CATEGORY_VIEW 53
#define RDSCREEN_IMPRINTER_SEARCH 54
#define RDSCREEN_IMPRINTER_QUEUE 55
#define RDSCREEN_SETTINGS 61
#define RDSCREEN_DEVICE_LINKING 62
#define RDSCREEN_TECHWEB 70
#define RDSCREEN_TECHWEB_NODEVIEW 71
#define RDSCREEN_TECHWEB_DESIGNVIEW 72

/// Defines for the Protolathe screens, see: [/modules/research/machinery/protolathe][Protolathe]
#define RESEARCH_FABRICATOR_SCREEN_MAIN 1
#define RESEARCH_FABRICATOR_SCREEN_CHEMICALS 2
#define RESEARCH_FABRICATOR_SCREEN_MATERIALS 3
#define RESEARCH_FABRICATOR_SCREEN_SEARCH 4
#define RESEARCH_FABRICATOR_SCREEN_CATEGORYVIEW 5
#define RESEARCH_FABRICATOR_SCREEN_QUEUE 6
