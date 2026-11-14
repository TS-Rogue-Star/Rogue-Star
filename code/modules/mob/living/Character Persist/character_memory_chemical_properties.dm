//////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star November 2026: Chemistry Memories //
//////////////////////////////////////////////////////////////////////

/datum/reagent
	var/memory_effects
	var/memory_search_terms
	var/memory_application
	var/memory_limitations
	var/memory_overdose = "Toxic injury, with severity affected by excess volume and species."
	var/list/memory_interactions

/datum/reagent/acid/polyacid
	memory_effects = "Strong corrosive acid that dissolves susceptible items and plants and burns living tissue."
	memory_application = "Apply directly to the object to dissolve it; more than 4 units must reach the target item."
	memory_limitations = "Can destroy equipment and cause severe burns or disfigurement. Acid-resistant objects are protected."

/datum/reagent/adranol
	memory_effects = "Reduces confusion, blurred vision, and jitteriness. Ineffective on Diona."
	memory_application = "Inject, or administer orally for absorption into the bloodstream."

/datum/reagent/advmutationtoxin
	memory_application = "Inject, or administer orally for absorption into the bloodstream."
	memory_effects = "Transforms a susceptible humanoid into a Promethean."
	memory_limitations = "Only affects susceptible organic humanoids. Has no effect on an existing Promethean."

/datum/reagent/alkysine
	memory_effects = "Repairs brain damage and provides mild pain relief. Less effective on Prometheans and may cause weakness or paralysis in them. Ineffective on Diona."
	memory_application = "Inject, or administer orally for absorption into the bloodstream."

/datum/reagent/ammonia
	memory_effects = "Hydroponics nutrient that also improves plant health; used as a chemistry ingredient."
	memory_application = "Add to a hydroponics tray to replenish nutrients and support the crop."

/datum/reagent/amorphorovir
	memory_effects = "Precursor for medicines that change a humanoid's gender."
	memory_application = "Use in further synthesis to produce a targeted transformation medicine."
	memory_limitations = "Has no targeted transformation effect on its own."

/datum/reagent/androgynorovir
	memory_application = "Inject, or administer orally for absorption into the bloodstream."
	memory_effects = "Changes a humanoid's body gender and gender identity to mixed."
	memory_limitations = "Only affects susceptible organic humanoids. Combining it with another gender-changing reagent causes confusion instead of the intended transformation."

/datum/reagent/androrovir
	memory_application = "Inject, or administer orally for absorption into the bloodstream."
	memory_effects = "Changes a humanoid's body gender and gender identity to male."
	memory_limitations = "Only affects susceptible organic humanoids. Combining it with another gender-changing reagent causes confusion instead of the intended transformation."

/datum/reagent/arithrazine
	memory_search_terms = "toxin damage, toxin loss, tox damage, tox loss"
	memory_effects = "Rapidly reduces current and accumulated radiation and treats toxic injury, but can cause physical injuries. Ineffective on Diona."
	memory_application = "Inject, or administer orally for absorption into the bloodstream."

/datum/reagent/bicaridine
	memory_search_terms = "brute damage, brute loss"
	memory_effects = "Heals physical injuries. Less effective on Prometheans; ineffective on Diona."
	memory_overdose = "Toxic injury and blurred vision; also accelerates the closure of bleeding and internal wounds."
	memory_application = "Inject, or administer orally for absorption into the bloodstream."

/datum/reagent/bicaridine/topical
	memory_effects = "Heals physical injuries through skin contact. Less effective on Prometheans; ineffective on Diona."
	memory_application = "Apply to the skin using a topical treatment."
	memory_limitations = "Swallowing or injecting this topical medicine causes toxic injury. Skin contact can also exceed its overdose threshold."

/datum/reagent/blood
	memory_effects = "Replaces lost blood when transfused into a compatible recipient."
	memory_application = "Inject or transfuse compatible blood into the patient."
	memory_limitations = "Species and blood-type compatibility matter. Contaminated blood can carry disease; drinking blood is not an ordinary transfusion."

/datum/reagent/blood/synthblood/dilute
	memory_effects = "Artificial plasma for replenishing blood, providing more blood volume per unit than ordinary blood. Freshly synthesized plasma is broadly compatible across blood types and species."
	memory_application = "Inject or transfuse into a suitable organic patient."
	memory_limitations = "Contamination can still make it unsafe. Replenishes blood but does not repair organs or replace synthetic coolant."

/datum/reagent/calciumcarbonate
	memory_effects = "Antacid that can suppress vomiting. Ineffective on Diona."
	memory_application = "Swallow to relieve stomach upset and reduce vomiting."
	memory_limitations = "Injecting it causes toxic injury."

/datum/reagent/capsaicin
	memory_effects = "Hot pepper oil used as a spice; eating enough causes painful warmth."
	memory_application = "Add to food or use as a chemical ingredient."
	memory_limitations = "Large swallowed doses cause pain and heating. Injecting it causes toxic injury; effects depend on species and spice sensitivity."

/datum/reagent/carpet
	memory_effects = "Colored carpet fibers used to manufacture floor tiles."
	memory_application = "Mix 2 units of this liquid carpet with 1 unit of Plasticide to create 2 matching carpet tiles."
	memory_limitations = "Pouring the liquid directly on a floor does not install carpet; place the resulting tiles."

/datum/reagent/carthatoline
	memory_search_terms = "toxin damage, toxin loss, tox damage, tox loss"
	memory_effects = "Strong antitoxin that can repair organic liver damage and counteract ongoing poisoning. May cause vomiting; produces a drugged sensation in Prometheans. Ineffective on Diona."
	memory_overdose = "Pain and stomach damage."
	memory_application = "Inject, or administer orally for absorption into the bloodstream."

/datum/reagent/chloralhydrate
	memory_overdose = "Toxic injury and oxygen deprivation."
	memory_application = "Inject, or administer orally for absorption into the bloodstream."
	memory_effects = "Strong sedative that causes weakness, blurred vision, and sleep."
	memory_limitations = "Can cause toxic injury before the overdose threshold is reached. Ineffective on Diona; Prometheans suffer severe sensory impairment instead of ordinary sleep."

/datum/reagent/clonexadone
	memory_search_terms = "brute damage, brute loss, burn damage, burn loss, fire damage, fire loss, toxin damage, toxin loss, tox damage, tox loss, oxygen damage, oxygen loss, oxy damage, oxy loss, suffocation, clone damage, clone loss, cloning damage"
	memory_effects = "Strong treatment for physical injuries, burns, poisoning, oxygen deprivation, and genetic damage in sufficiently cold patients."
	memory_interactions = list("Leporazine warms the body toward 310 K, counteracting the cold conditions needed for treatment.")
	memory_application = "Deliver into the bloodstream while keeping body temperature below 170 K, such as in a cooled cryogenic cell."
	memory_limitations = "Does not heal at or above 170 K. Less effective on Prometheans and causes collapse and impaired speech in them."

/datum/reagent/condensedcapsaicin
	memory_effects = "Pepper spray irritant that blinds, stuns, and incapacitates exposed targets."
	memory_application = "Apply with a spray to expose the target's face and skin."
	memory_limitations = "Eye and face protection can reduce or prevent the effect. Swallowing causes pain and heaving; injection causes toxic injury. Effects depend on species and pain sensitivity."

/datum/reagent/coolant
	memory_effects = "Replenishes the internal blood supply of synthetic humanoids."
	memory_application = "Inject into a synthetic humanoid, or administer through its chemical intake."
	memory_limitations = "Does not replenish organic blood or repair damaged robotic organs."

/datum/reagent/cordradaxon
	memory_search_terms = "oxygen damage, oxygen loss, oxy damage, oxy loss, suffocation"
	memory_effects = "Repairs organic circulatory organs and normally treats oxygen deprivation. Can cause confusion."
	memory_interactions = list("Respirodaxon or Peridaxon: breathing difficulties replace the additional oxygen treatment.", "Hepanephrodaxon: vomiting and possible toxic injury replace Hepanephrodaxon's antitoxin effect.")
	memory_application = "Inject, or administer orally for absorption into the bloodstream."

/datum/reagent/corophizine
	memory_effects = "Strong antibiotic. Can cause confusion, weakness, dizziness, hallucinations, and very rarely fractures. Extremely harmful to Prometheans, even below its overdose threshold."
	memory_interactions = list("Opposes Immunosuprizine and Malish-Qualem, potentially restoring transplant rejection and causing organ damage and toxic injury.")
	memory_application = "Inject, or administer orally for absorption into the bloodstream."

/datum/reagent/cryoxadone
	memory_search_terms = "brute damage, brute loss, burn damage, burn loss, fire damage, fire loss, toxin damage, toxin loss, tox damage, tox loss, oxygen damage, oxygen loss, oxy damage, oxy loss, suffocation, clone damage, clone loss, cloning damage"
	memory_effects = "Treats physical injuries, burns, poisoning, oxygen deprivation, and genetic damage in sufficiently cold patients."
	memory_interactions = list("Leporazine warms the body toward 310 K, counteracting the cold conditions needed for treatment.")
	memory_application = "Deliver into the bloodstream while keeping body temperature below 170 K, such as in a cooled cryogenic cell."
	memory_limitations = "Does not heal at or above 170 K. Less effective on Prometheans and causes collapse and impaired speech in them."

/datum/reagent/cryptobiolin
	memory_application = "Inject, or administer orally for absorption into the bloodstream."
	memory_effects = "Causes dizziness and confusion."
	memory_limitations = "Ineffective on Diona; strength varies with species."

/datum/reagent/dermaline
	memory_search_terms = "burn damage, burn loss, fire damage, fire loss"
	memory_effects = "Treats burns, usually at twice Kelotane's strength per unit. Less effective on Prometheans; ineffective on Diona."
	memory_application = "Inject, or administer orally for absorption into the bloodstream."

/datum/reagent/dermaline/topical
	memory_effects = "Heals burns through skin contact. Less effective on Prometheans; ineffective on Diona."
	memory_application = "Apply to the skin using a topical treatment."
	memory_limitations = "Swallowing or injecting this topical medicine causes toxic injury. Skin contact can also exceed its overdose threshold."

/datum/reagent/dexalin
	memory_search_terms = "oxygen damage, oxygen loss, oxy damage, oxy loss, suffocation"
	memory_effects = "Treats oxygen deprivation. Toxic to Vox; ineffective on Diona."
	memory_interactions = list("Removes Lexorin from the bloodstream.")
	memory_application = "Inject, or administer orally for absorption into the bloodstream."
	memory_limitations = "After a cumulative dose of 15 units has been metabolized, Prometheans receive pain relief instead of oxygen treatment, with a chance of brain repair accompanied by collapse."

/datum/reagent/dexalinp
	memory_search_terms = "oxygen damage, oxygen loss, oxy damage, oxy loss, suffocation"
	memory_effects = "Rapidly treats oxygen deprivation. Toxic to Vox; ineffective on Diona."
	memory_interactions = list("Removes Lexorin from the bloodstream.")
	memory_application = "Inject, or administer orally for absorption into the bloodstream."
	memory_limitations = "After a cumulative dose of 10 units has been metabolized, Prometheans receive pain relief instead of oxygen treatment, with a chance of brain repair accompanied by collapse."

/datum/reagent/diethylamine
	memory_effects = "Hydroponics nutrient that improves plant health and reduces pests."
	memory_application = "Add to a hydroponics tray to feed the plant and control pests."

/datum/reagent/drugs/bliss
	memory_overdose = "Toxic injury and brain damage, with possible hallucinations."
	memory_application = "Inject, or administer orally for absorption into the bloodstream."
	memory_effects = "Recreational drug that causes a euphoric high, involuntary movements, and occasional twitching, drooling, or laughter."
	memory_limitations = "Can impair control of movement. Overdosing causes toxic injury and brain damage."

/datum/reagent/drugs/citalopram
	memory_application = "Inject, or administer orally for absorption into the bloodstream."
	memory_effects = "Produces a feeling of mental stability."
	memory_limitations = "Does not directly remove confusion or hallucinations."

/datum/reagent/drugs/methylphenidate
	memory_application = "Inject, or administer orally for absorption into the bloodstream."
	memory_effects = "Produces a feeling of focus and concentration."
	memory_limitations = "Does not directly repair brain damage or remove confusion."

/datum/reagent/drugs/paroxetine
	memory_application = "Inject, or administer orally for absorption into the bloodstream."
	memory_effects = "Produces a feeling of mental stability, with a risk of severe hallucinations."
	memory_limitations = "Hallucinations can occur below the overdose threshold. Does not directly remove confusion."

/datum/reagent/drugs/qerr_quem
	memory_application = "Inject, or administer orally for absorption into the bloodstream."
	memory_effects = "Skrell medicine that produces a sense of calm and sluggishness."
	memory_limitations = "Does not induce sleep or treat confusion."

/datum/reagent/drugs/talum_quem
	memory_application = "Inject, or administer orally for absorption into the bloodstream."
	memory_effects = "Skrell recreational drug that causes a strong high and occasional involuntary movement."
	memory_limitations = "Causes substantial toxic injury in non-Skrell users, even below its overdose threshold."

/datum/reagent/dylovene
	memory_search_terms = "toxin damage, toxin loss, tox damage, tox loss"
	memory_effects = "Treats toxic injury, drowsiness, and hallucinations, and can counteract ongoing poisoning. Less effective on Prometheans and can make them feel drugged after a cumulative dose of 15 units. Ineffective on Diona."
	memory_application = "Inject, or administer orally for absorption into the bloodstream."

/datum/reagent/ethylredoxrazine
	memory_effects = "Clears dizziness, drowsiness, stuttering, and confusion from intoxication. Ineffective on Diona."
	memory_interactions = list("Removes alcoholic reagents from the bloodstream when injected and from the stomach when swallowed.")
	memory_application = "Swallow to clear alcohol from the stomach, or inject to clear it from the bloodstream."

/datum/reagent/firefighting_foam
	memory_effects = "Extinguishes burning people and suppresses fires with firefighting foam."
	memory_application = "Spray burning targets or apply to a burning floor. At least 1 unit on a tile creates a foam patch."
	memory_limitations = "Damages slime creatures on contact."

/datum/reagent/fluorosurfactant
	memory_effects = "Foam precursor that spreads the container's chemicals over an area when mixed with water."
	memory_application = "Combine with water where the foam should spread."
	memory_limitations = "Foam releases as soon as the ingredients react and can carry other chemicals from the container."

/datum/reagent/foaming_agent
	memory_effects = "Precursor for metal foam barriers and distilled topical medicines."
	memory_application = "React with aluminum or iron and Polytrinic Acid for metal foam; use the distillery for topical medicine recipes."
	memory_limitations = "Metal foam expands immediately when the mixture reacts."

/datum/reagent/frostoil
	memory_effects = "Cooling oil used as a cold spice and in chemical synthesis; internal exposure can lower body temperature."
	memory_application = "Use in food or recipes, or administer internally for cooling."
	memory_limitations = "Eating enough causes pain and chilling. Ineffective on Diona; injected Frost Oil removes Capsaicin from the bloodstream."

/datum/reagent/frostoil/cryotoxin
	memory_effects = "Cooling derivative of Frost Oil that clears more slowly from the bloodstream."
	memory_application = "Administer internally for cooling."
	memory_limitations = "The slower clearance does not apply in the stomach. Can cause painful chilling and dangerous cold. Ineffective on Diona."

/datum/reagent/fuel
	memory_effects = "Welding fuel used in tools and chemical reactions; spills create flammable puddles."
	memory_application = "Use as fuel in compatible equipment. Surface application leaves fuel that can ignite."
	memory_limitations = "Poisonous inside the body. Splashing someone makes them more flammable."

/datum/reagent/gastirodaxon
	memory_search_terms = "toxin damage, toxin loss, tox damage, tox loss"
	memory_effects = "Repairs organic digestive organs and normally treats toxic injury. Can cause confusion."
	memory_interactions = list("Hepanephrodaxon or Peridaxon: vomiting or depletion of energy reserves replaces the additional antitoxin effect.", "Respirodaxon: causes breathing difficulties and possible brief incapacitation.")
	memory_application = "Inject, or administer orally for absorption into the bloodstream."

/datum/reagent/glycerol
	memory_effects = "Chemical precursor used in further synthesis, including explosive Nitroglycerin."
	memory_application = "Keep in a reagent container for recipes that require it."
	memory_limitations = "Completing the Nitroglycerin reaction triggers an immediate explosion."

/datum/reagent/gynorovir
	memory_application = "Inject, or administer orally for absorption into the bloodstream."
	memory_effects = "Changes a humanoid's body gender and gender identity to female."
	memory_limitations = "Only affects susceptible organic humanoids. Combining it with another gender-changing reagent causes confusion instead of the intended transformation."

/datum/reagent/hepanephrodaxon
	memory_search_terms = "toxin damage, toxin loss, tox damage, tox loss"
	memory_effects = "Repairs organic liver, kidneys, appendix, and related filtration organs; normally treats toxic injury. Can cause confusion."
	memory_interactions = list("Cordradaxon or Peridaxon: vomiting and possible toxic injury replace the additional antitoxin effect.", "Gastirodaxon: vomiting or depletion of energy reserves replaces Gastirodaxon's additional antitoxin effect.")
	memory_application = "Inject, or administer orally for absorption into the bloodstream."

/datum/reagent/hydrogen/deuterium
	memory_effects = "Gaseous hydrogen isotope used as fusion fuel, produced by processing Hydrophoron with water."
	memory_application = "Use an open container holding at least 300 units of pure Deuterium on a fusion fuel compressor to make a fuel rod assembly."
	memory_limitations = "The compressor consumes the entire contents and rejects mixtures. Has no direct medical or surface effect."

/datum/reagent/hyperzine
	memory_effects = "Increases movement speed. Can cause twitching; makes Prometheans jittery and depletes energy reserves after a cumulative dose of 5 units."
	memory_overdose = "Toxic injury and a chance of heart damage."
	memory_application = "Inject, or administer orally for absorption into the bloodstream."

/datum/reagent/hyronalin
	memory_application = "Inject, or administer orally for absorption into the bloodstream."
	memory_effects = "Reduces current radiation and accumulated radiation exposure."
	memory_limitations = "Ineffective on Diona."

/datum/reagent/ickypak
	memory_application = "Administer to the predator by swallowing or injection."
	memory_effects = "Encourages a predator to expel swallowed, unabsorbed contents."
	memory_limitations = "May take time or repeated doses to work. Does not release absorbed prey. Causes pain and dizziness."

/datum/reagent/imidazoline
	memory_effects = "Repairs organic eyes, reduces blurred vision and temporary blindness, and can reverse blindness once eye damage is low enough."
	memory_application = "Inject, or administer orally for absorption into the bloodstream."

/datum/reagent/immunosuprizine
	memory_effects = "Can stop transplant rejection after a cumulative dose of 15 units. Causes substantial toxic injury in non-Diona patients; effectiveness varies with species."
	memory_interactions = list("Spaceacillin or Corophizine can undo rejection suppression, damaging transplanted organs and causing additional toxic injury.")
	memory_application = "Inject, or administer orally for absorption into the bloodstream."

/datum/reagent/impedrezene
	memory_application = "Inject, or administer orally for absorption into the bloodstream."
	memory_effects = "Reduces jitteriness but causes drowsiness, brain damage, and occasional drooling."
	memory_limitations = "Harms the brain even below its overdose threshold. Ineffective on Diona."

/datum/reagent/inaprovaline
	memory_effects = "Stabilizes breathing, provides mild pain relief, and suppresses allergic reactions. Ineffective on Diona."
	memory_application = "Inject, or administer orally for absorption into the bloodstream."

/datum/reagent/inaprovaline/topical
	memory_effects = "Topical stabilizer and mild painkiller. Ineffective on Diona."
	memory_application = "Apply to the skin using a topical treatment."
	memory_limitations = "Swallowing or injecting this topical medicine causes toxic injury. Skin contact can also exceed its overdose threshold."

/datum/reagent/kelotane
	memory_search_terms = "burn damage, burn loss, fire damage, fire loss"
	memory_effects = "Heals burns. Less effective on Prometheans and also causes them physical injuries. Ineffective on Diona."
	memory_application = "Inject, or administer orally for absorption into the bloodstream."

/datum/reagent/leporazine
	memory_effects = "Moves body temperature toward 310 K. Ineffective on Diona."
	memory_interactions = list("Counteracts the cooling needed for Cryoxadone, Clonexadone, Mortiferin, and the stronger effects of Necroxadone.")
	memory_application = "Inject, or administer orally for absorption into the bloodstream."

/datum/reagent/lexorin
	memory_interactions = list("Dexalin and Dexalin Plus remove Lexorin from the bloodstream.")
	memory_application = "Inject, or administer orally for absorption into the bloodstream."
	memory_effects = "Suppresses breathing and damages tissue."
	memory_limitations = "Causes physical injuries and breathing difficulties even below its overdose threshold. Prometheans instead suffer pain, toxic injury, and possible brief incapacitation; ineffective on Diona."

/datum/reagent/lipostipo
	memory_application = "Inject, or administer orally for absorption into the bloodstream."
	memory_effects = "Increases body weight while depleting energy reserves."
	memory_limitations = "Weight gain stops at approximately 500 pounds. Can cause hunger despite the weight gain."

/datum/reagent/lipozilase
	memory_application = "Inject, or administer orally for absorption into the bloodstream."
	memory_effects = "Reduces body weight while depleting energy reserves."
	memory_limitations = "Weight reduction stops at approximately 50 pounds. Can cause hunger."

/datum/reagent/lipozine
	memory_application = "Inject, or administer orally for absorption into the bloodstream."
	memory_effects = "Depletes energy reserves."
	memory_limitations = "Can leave the patient hungry; it does not directly reduce body weight."

/datum/reagent/lube
	memory_effects = "Makes floors extremely slippery."
	memory_application = "Apply at least 1 unit to a floor to leave a slippery coating."
	memory_limitations = "People crossing the treated floor can slip."

/datum/reagent/luminol
	memory_effects = "Used in forensics to mark blood traces cyan, including residue left after ordinary cleaning."
	memory_application = "Spray suspected floors, blood tracks, or items, then switch on a UV light nearby to reveal hidden traces."
	memory_limitations = "Cannot recover evidence erased by Sterilizine, identify the blood donor, or restore erased DNA. Place items on the floor for the UV light to inspect them."

/datum/reagent/macrocillin
	memory_application = "Inject, or administer orally for absorption into the bloodstream."
	memory_effects = "Gradually increases body size while it is metabolized."
	memory_limitations = "Only changes susceptible bodies; the surroundings can limit the extent of the change. The size change persists after the reagent is gone; Normalcillin moves the body toward a standard baseline size."
	memory_interactions = list("Mixing at least 1 unit of Macrocillin with 1 unit of Microcillin creates a gravitational pull toward the mixing point and consumes the mixture.")

/datum/reagent/microcillin
	memory_application = "Inject, or administer orally for absorption into the bloodstream."
	memory_effects = "Gradually decreases body size while it is metabolized."
	memory_limitations = "Only changes susceptible bodies; the surroundings can limit the extent of the change. The size change persists after the reagent is gone; Normalcillin moves the body toward a standard baseline size."
	memory_interactions = list("Mixing at least 1 unit of Macrocillin with 1 unit of Microcillin creates a gravitational pull toward the mixing point and consumes the mixture.")

/datum/reagent/mindbreaker
	memory_interactions = list("Synaptizine removes Mindbreaker Toxin from the bloodstream.")
	memory_application = "Inject, or administer orally for absorption into the bloodstream."
	memory_effects = "Powerful hallucinogen that causes persistent hallucinations while present."
	memory_limitations = "Ineffective on Diona; strength varies with species."

/datum/reagent/modapplying
	memory_application = "Inject, or administer orally for absorption into the bloodstream."
	memory_effects = "Induces a berserk state with faster and stronger melee attacks, pain immunity, and greater temporary resilience."
	memory_limitations = "Impairs aim and reflexes, depletes energy reserves, and causes exhaustion afterward. Injuries can become critical when the temporary boost ends. Cannot take effect again while exhausted. Requires a conscious, sufficiently nourished user; ineffective on Diona."

/datum/reagent/modapplying/cryofluid
	memory_effects = "Chills and slows living targets and freezes floors."
	memory_application = "Spray a target or floor. Internal exposure also lowers body temperature; swallowing produces stronger cooling than injection."
	memory_limitations = "Repeated exposure increasingly impairs movement and coordination. Excessive cooling can cause hypothermia."

/datum/reagent/mortiferin
	memory_search_terms = "toxin damage, toxin loss, tox damage, tox loss, oxygen damage, oxygen loss, oxy damage, oxy loss, suffocation, clone damage, clone loss, cloning damage"
	memory_effects = "Treats toxic injury and oxygen deprivation in cold patients or corpses supported by a blood pump. Also treats genetic damage in living patients."
	memory_interactions = list("Leporazine counteracts the low body temperature needed for treatment in living patients.")
	memory_application = "Deliver into the bloodstream below 263.15 K. Can also treat a corpse supported by a blood pump."
	memory_limitations = "Requires cold conditions or a blood pump supporting a corpse. Can damage the liver. Less effective on Prometheans and can cause collapse, inability to speak, and jitteriness in them."

/datum/reagent/mutagen
	memory_effects = "Causes random genetic mutations and radiation exposure; can also mutate hydroponics plants."
	memory_application = "Add to a hydroponics tray for plant breeding. Internal exposure or skin contact can mutate susceptible people."
	memory_limitations = "Mutations are unpredictable and usually harmful. Synthetic bodies are unaffected. Species protected from genetic changes resist genetic mutation and radiation, but Prometheans can still undergo coloration changes."

/datum/reagent/myelamine
	memory_effects = "Closes bleeding and internal wounds, but blurs vision. Ineffective on Diona."
	memory_overdose = "Toxic injury with additional wound closure."
	memory_application = "Inject, or administer orally for absorption into the bloodstream."

/datum/reagent/necroxadone
	memory_search_terms = "toxin damage, toxin loss, tox damage, tox loss, oxygen damage, oxygen loss, oxy damage, oxy loss, suffocation, clone damage, clone loss, cloning damage"
	memory_effects = "Treats poisoning, oxygen deprivation, and genetic damage, with stronger effects below 170 K or in a corpse supported by a blood pump. Also processes in corpses."
	memory_interactions = list("Leporazine counteracts the cold conditions needed for its stronger treatment.")
	memory_application = "Deliver into the bloodstream. For stronger treatment, cool below 170 K or support a corpse with a blood pump."
	memory_limitations = "The stronger treatment is less effective on Prometheans and can cause collapse, inability to speak, and jitteriness in them."

/datum/reagent/nitroglycerin
	memory_effects = "Explosive chemical whose synthesis causes a blast."
	memory_application = "Its recipe detonates at the mixing location as soon as the reaction occurs."
	memory_limitations = "The blast can injure nearby people and damage the surroundings. Mixing it is not a safe way to prepare a stored liquid."

/datum/reagent/normalcillin
	memory_application = "Inject, or administer orally for absorption into the bloodstream."
	memory_effects = "Gradually returns the body toward a standard baseline size."
	memory_limitations = "The baseline may differ from the patient's usual size."

/datum/reagent/numbing_enzyme
	memory_overdose = "Can cause collapse, confusion, breathing difficulties, hallucinations, blurred vision, jitteriness, and stuttering."
	memory_effects = "Strong organic painkiller that numbs the body."
	memory_application = "Inject, or administer orally for absorption into the bloodstream."

/datum/reagent/nutriment/glucose
	memory_effects = "Injectable nutrition that also supports blood regeneration. Can also be swallowed."
	memory_application = "Administer orally or inject to provide nutrition and support blood regeneration."

/datum/reagent/nutriment/glucose/slime
	memory_effects = "Injectable nutrition that also supports blood regeneration."
	memory_application = "Swallow or inject to feed a patient. Provides the same nutrition per unit as Glucose."

/datum/reagent/osteodaxon
	memory_search_terms = "brute damage, brute loss"
	memory_effects = "Mends fractures and heals some physical injuries. Fracture repair causes severe pain and weakness; heavily damaged bones may break again. Ineffective on Diona."
	memory_application = "Inject, or administer orally for absorption into the bloodstream."

/datum/reagent/oxycodone
	memory_effects = "Strong, slowly metabolized painkiller. Slows movement and blurs vision. Less effective on Prometheans and interferes with their speech."
	memory_overdose = "Toxic injury, hallucinations, and a drugged sensation."
	memory_application = "Inject, or administer orally for absorption into the bloodstream."

/datum/reagent/paint
	memory_effects = "Recolors floors, objects, and living targets with the paint's color."
	memory_application = "Spray or splash the surface or item you want to recolor. Mixed paints blend their colors."

/datum/reagent/paracetamol
	memory_effects = "Mild, slowly metabolized painkiller. Less effective on Prometheans."
	memory_overdose = "Toxic injury and hallucinations; also slows Prometheans."
	memory_application = "Inject, or administer orally for absorption into the bloodstream."

/datum/reagent/peridaxon
	memory_effects = "Repairs damaged organic internal organs. Can cause confusion and blurred vision."
	memory_overdose = "Toxic injury, pain, and hallucinations."
	memory_interactions = list("Respirodaxon or Cordradaxon: breathing difficulties.", "Gastirodaxon: vomiting or depletion of energy reserves replaces Gastirodaxon's additional antitoxin effect.", "Hepanephrodaxon: vomiting and possible toxic injury replace Hepanephrodaxon's additional antitoxin effect.")
	memory_application = "Inject, or administer orally for absorption into the bloodstream."

/datum/reagent/prussian_blue
	memory_application = "Inject, or administer orally for absorption into the bloodstream."
	memory_effects = "Temporarily suppresses radiation sickness while further treatment is arranged."
	memory_limitations = "Does not remove current or accumulated radiation. Pair with radiation treatment; the protection ends when it leaves the bloodstream."

/datum/reagent/radium
	memory_effects = "Radioactive reagent used in synthesis and to encourage plant mutations."
	memory_application = "Use in chemical recipes or add to a hydroponics tray for mutation attempts."
	memory_limitations = "Internal exposure causes radiation and can cause severe poisoning in infected patients. Harms plants and adds tray toxins; mutations are unpredictable."

/datum/reagent/respirodaxon
	memory_effects = "Repairs organic lungs, vocal organs, and gas bladders; normally eases breathing. Can cause confusion."
	memory_interactions = list("Gastirodaxon or Peridaxon: causes breathing difficulties and possible brief incapacitation.", "Cordradaxon: prevents Cordradaxon's oxygen treatment and causes breathing difficulties.")
	memory_application = "Inject, or administer orally for absorption into the bloodstream."

/datum/reagent/rezadone
	memory_search_terms = "brute damage, brute loss, burn damage, burn loss, fire damage, fire loss, toxin damage, toxin loss, tox damage, tox loss, oxygen damage, oxygen loss, oxy damage, oxy loss, suffocation, clone damage, clone loss, cloning damage"
	memory_effects = "Treats genetic damage, physical injuries, burns, poisoning, and oxygen deprivation. Can remove disfigurement after more than 3 units metabolized; causes dizziness and jitteriness after more than 10. Ineffective on Diona."
	memory_application = "Inject, or administer orally for absorption into the bloodstream."
	memory_limitations = "Can shift Promethean skin, hair, and facial hair coloration toward dark grey."

/datum/reagent/ryetalyn
	memory_application = "Inject, or administer orally for absorption into the bloodstream."
	memory_effects = "Removes mutations and genetic disabilities."
	memory_limitations = "Removes beneficial mutations too. Can poison Prometheans and shift their coloration toward white."

/datum/reagent/silicate
	memory_effects = "Repairs damaged glass windows and reinforces intact windows against damage."
	memory_application = "Apply directly to a window. Repair damage first, then apply more to build up reinforcement."
	memory_limitations = "Reinforcement caps at 100 units of coating, reducing incoming damage by up to half."

/datum/reagent/sizeoxadone
	memory_effects = "Precursor for size-changing medicines."
	memory_application = "Use in further synthesis to make a size-changing treatment."
	memory_limitations = "Taking it unprocessed causes dizziness and confusion without changing size."

/datum/reagent/skrellimmuno
	memory_effects = "Can stop transplant rejection after a cumulative dose of 15 units. Most effective on Skrell; causes toxic injury in other species."
	memory_interactions = list("Spaceacillin or Corophizine can undo rejection suppression, damaging transplanted organs and causing additional toxic injury.")
	memory_application = "Inject, or administer orally for absorption into the bloodstream."

/datum/reagent/slimejelly
	memory_search_terms = "brute damage, brute loss, burn damage, burn loss, fire damage, fire loss, toxin damage, toxin loss, tox damage, tox loss"
	memory_application = "Inject, or administer orally for absorption into the bloodstream."
	memory_effects = "Unpredictable treatment for physical injuries. Prometheans also receive treatment for burns and poisoning."
	memory_limitations = "Can cause severe toxic injury in other species instead of healing them. Ineffective on Diona."

/datum/reagent/slimetoxin
	memory_application = "Inject, or administer orally for absorption into the bloodstream."
	memory_effects = "Slime-derived mutagen that causes random genetic changes and radiation exposure."
	memory_limitations = "Does not itself turn the subject into a Promethean. Synthetic bodies and genetically protected species are unaffected."

/datum/reagent/sodiumchloride
	memory_effects = "Food seasoning and a chemistry ingredient."
	memory_application = "Add to food or use in recipes that require Table Salt."
	memory_limitations = "Causes burns in Prometheans when swallowed or injected."

/datum/reagent/soporific
	memory_application = "Inject, or administer orally for absorption into the bloodstream."
	memory_effects = "Sedative that progresses from drowsiness and blurred vision to sleep as it is metabolized."
	memory_limitations = "The sleep effect takes time to develop, and small doses may be insufficient. Effects vary with body size and species. Ineffective on Diona; Prometheans suffer sensory impairment instead of ordinary sleep."

/datum/reagent/space_cleaner
	memory_effects = "Cleans visible blood, dirt, and stains from people, objects, and floors; also removes glue patches."
	memory_application = "Spray or splash the dirty surface. Apply to skin and worn equipment to clean blood."
	memory_limitations = "Ordinary blood cleaning can leave traces detectable with Luminol and a UV light. Harmful to slime creatures; swallowing it causes toxic injury and can cause vomiting."

/datum/reagent/spaceacillin
	memory_interactions = list("Opposes Immunosuprizine and Malish-Qualem, potentially restoring transplant rejection and causing organ damage and toxic injury.")
	memory_application = "Inject, or administer orally for absorption into the bloodstream. Topical application also provides antibiotic effects."
	memory_effects = "Antibiotic treatment for infections; also works through skin contact."
	memory_limitations = "Can make Prometheans feel unfocused while it remains in the body."

/datum/reagent/spaceglue
	memory_effects = "Creates a sticky floor patch that can trap runners and hinder movement."
	memory_application = "Apply at least 1 unit to a floor. The patch lasts about five minutes."
	memory_limitations = "Can catch people crossing it. Trapped targets must struggle free; slip-resistant footwear can prevent the trip."

/datum/reagent/spacomycaze
	memory_effects = "Topical antibiotic and mild painkiller."
	memory_application = "Apply to the skin, or use on improvised bandages to upgrade the dressing."
	memory_limitations = "Swallowing or injecting it causes toxic injury and provides only weak pain relief. Skin contact can also exceed its overdose threshold."

/datum/reagent/sterilizine
	memory_effects = "Disinfects skin, objects, and floors. Destroys residual blood stains that Luminol would reveal."
	memory_application = "Apply to exposed skin, spray objects, or splash floors to disinfect them and remove residual blood traces."
	memory_limitations = "Harmful to Prometheans and slimes on contact. Treated items can retain visible blood and DNA evidence even after their hidden stains are destroyed."

/datum/reagent/synaptizine
	memory_search_terms = "brute damage, brute loss, burn damage, burn loss, fire damage, fire loss"
	memory_effects = "Relieves drowsiness and hallucinations, helps restore movement after temporary paralysis or collapse, and provides mild pain relief."
	memory_interactions = list("Removes Mindbreaker Toxin from the bloodstream.")
	memory_application = "Inject, or administer orally for absorption into the bloodstream."
	memory_limitations = "Causes toxic injury during treatment. In Prometheans, a cumulative dose of at least 5 units also helps repair physical injuries and burns. Ineffective on Diona."

/datum/reagent/thermite
	memory_effects = "Coats walls so they can be melted through when ignited."
	memory_application = "Apply at least 5 units to a wall, then ignite the coating with a lit welder, plasma cutter, or energy blade."
	memory_limitations = "Some walls resist melting, and reinforced girders can remain. Contact makes people more flammable; internal exposure causes burns."

/datum/reagent/thermite/venom
	memory_effects = "Biological thermite that can coat walls for melting and causes internal burns."
	memory_application = "Apply at least 5 units to a wall, then ignite its coating with a lit welder."
	memory_limitations = "Contact increases flammability. Internal exposure causes burns and can set the victim on fire."

/datum/reagent/toxin/carpotoxin
	memory_application = "Inject, or administer orally for absorption into the bloodstream."
	memory_effects = "Neurotoxin that causes toxic injury and brain damage; also used as a chemical precursor."
	memory_limitations = "Poisonous through internal exposure and, at reduced strength, skin contact."

/datum/reagent/toxin/fertilizer/left4zed
	memory_effects = "Fertilizer that feeds plants and strengthens other mutagenic treatments."
	memory_application = "Add to a hydroponics tray alongside a mutagenic treatment such as Unstable Mutagen or Radium."
	memory_limitations = "Does not trigger mutations by itself or select their outcome. Toxic if absorbed by non-Diona patients."

/datum/reagent/toxin/fertilizer/robustharvest
	memory_effects = "Fertilizer that feeds plants and increases harvest yield."
	memory_application = "Add to a hydroponics tray to improve its crop output."
	memory_limitations = "Toxic if absorbed by non-Diona patients."

/datum/reagent/toxin/hydrophoron
	memory_effects = "Exceptionally toxic and flammable intermediate used to synthesize Deuterium."
	memory_application = "Keep contained for chemical processing. Spilling it on a floor releases hot flammable gas."
	memory_limitations = "Floor exposure can ignite immediately. Internal exposure is extremely poisonous and can set Prometheans on fire; skin contact causes burns."

/datum/reagent/toxin/lichpowder
	memory_effects = "Produces an apparent-death state through skin contact, with suppressed speech and occasional chilling."
	memory_application = "Apply to the skin for the apparent-death effect."
	memory_limitations = "Also causes toxic injury and oxygen deprivation. The apparent-death effect ends when the chemical is removed; ineffective on Diona."

/datum/reagent/toxin/phoron
	memory_search_terms = "oxygen damage, oxygen loss, oxy damage, oxy loss, suffocation"
	memory_effects = "Chemical precursor and flammable toxin. Can treat oxygen deprivation in Vox."
	memory_application = "Use in synthesis, or administer internally to a Vox for oxygen treatment."
	memory_limitations = "Highly poisonous to most other species. Contact can cause burns and increased flammability; floor spills release flammable gas."

/datum/reagent/toxin/plantbgone
	memory_effects = "Destroys spreading plants, damages alien weeds, removes wall fungi, and kills hydroponics weeds."
	memory_application = "Spray the plant, weed, or fungus-covered wall. Add to a hydroponics tray to fight weeds."
	memory_limitations = "Damages the crop and adds toxins in hydroponics trays. Extremely poisonous to Diona, including through skin contact."

/datum/reagent/toxin/potassium_chloride
	memory_overdose = "Toxic injury, oxygen deprivation, and collapse."
	memory_application = "Inject, or administer orally for absorption into the bloodstream."
	memory_effects = "Chemical salt used in synthesis; excessive doses cause oxygen deprivation and collapse."
	memory_limitations = "Its dangerous oxygen-loss and collapse effects occur on overdose. Causes burns in Prometheans even below that threshold."

/datum/reagent/toxin/potassium_chlorophoride
	memory_application = "Inject, or administer orally for absorption into the bloodstream."
	memory_effects = "Toxic compound that causes oxygen deprivation and collapse."
	memory_limitations = "Dangerous even below the overdose threshold; also causes burns in Prometheans."

/datum/reagent/toxin/sifslurry
	memory_overdose = "Radiation and drowsiness in non-Diona patients."
	memory_effects = "Bacterial slurry that nourishes Diona. In other species it causes poisoning and slows the pulse."
	memory_application = "Swallow or inject; its effects are weaker when swallowed."

/datum/reagent/toxin/stimm
	memory_overdose = "Toxic injury and a chance of heart damage."
	memory_application = "Inject, or administer orally for absorption into the bloodstream."
	memory_effects = "Stimulant that increases movement speed at the cost of toxic injury and occasional physical injuries."
	memory_limitations = "Can cause twitching, violent shuddering, and injury even below the overdose threshold. Overdosing can damage the heart."

/datum/reagent/toxin/zombiepowder
	memory_application = "Inject, or administer orally for absorption into the bloodstream."
	memory_effects = "Produces a death-like state with weakness and inability to speak."
	memory_limitations = "Also causes toxic injury and oxygen deprivation. The apparent-death effect ends when the chemical is removed; ineffective on Diona."

/datum/reagent/tramadol
	memory_effects = "Moderate, slowly metabolized painkiller. Less effective on Prometheans and slows them down."
	memory_overdose = "Toxic injury and hallucinations."
	memory_application = "Inject, or administer orally for absorption into the bloodstream."

/datum/reagent/tricordrazine
	memory_search_terms = "brute damage, brute loss, burn damage, burn loss, fire damage, fire loss, toxin damage, toxin loss, tox damage, tox loss, oxygen damage, oxygen loss, oxy damage, oxy loss, suffocation"
	memory_effects = "Treats physical injuries, burns, poisoning, and oxygen deprivation. Also works through skin contact at reduced strength. Less effective on Prometheans; ineffective on Diona."
	memory_application = "Inject, or administer orally for absorption into the bloodstream."

/datum/reagent/tricorlidaze
	memory_search_terms = "brute damage, brute loss, burn damage, burn loss, fire damage, fire loss, toxin damage, toxin loss, tox damage, tox loss, oxygen damage, oxygen loss, oxy damage, oxy loss, suffocation"
	memory_effects = "Topical treatment for physical injuries, burns, poisoning, and oxygen deprivation. Ineffective on Diona."
	memory_application = "Apply to the skin, or use 5 units per gauze dressing to upgrade it."
	memory_limitations = "Swallowing or injecting this topical medicine causes toxic injury."

/datum/reagent/ultraglue
	memory_effects = "Creates a stronger sticky floor patch that is harder to escape."
	memory_application = "Apply at least 1 unit to a floor. The patch lasts about five minutes."
	memory_limitations = "More likely than Space Glue to stop movement and takes longer to escape. Can catch other people crossing it."

/datum/reagent/unsorbitol
	memory_application = "Administer to the predator by swallowing or injection."
	memory_effects = "Interrupts absorption and can separate absorbed prey back into the predator's belly."
	memory_limitations = "Separation may take time or repeated doses and does not itself expel prey. Causes pain, dizziness, confusion, and hallucinations."

/datum/reagent/vermicetol
	memory_search_terms = "brute damage, brute loss"
	memory_effects = "Rapidly repairs physical injuries. Less effective on Prometheans; ineffective on Diona."
	memory_application = "Inject, or administer orally for absorption into the bloodstream."

/datum/reagent/water
	memory_effects = "Relieves dehydration when drunk, extinguishes burning people, suppresses fires, cools hot floors, and supplies hydroponics trays with water."
	memory_application = "Drink to relieve dehydration. Spray or splash fires or burning targets; add to a hydroponics tray for irrigation."
	memory_limitations = "Spills of at least 10 units on cool floors can make them slippery. Splashing slime creatures damages them."
