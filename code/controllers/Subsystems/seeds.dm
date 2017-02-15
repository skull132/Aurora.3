/var/datum/subsystem/plants/plant_controller

/datum/subsystem/plants
	name = "Seeds & Plants"
	flags = SS_TICKER | SS_NO_TICK_CHECK
	wait = 75
	init_order = SS_INIT_MISC

	var/list/product_descs = list()         // Stores generated fruit descs.
	var/list/plant_queue = list()           // All queued plants.
	var/list/seeds = list()                 // All seed data stored here.
	var/list/gene_tag_masks = list()        // Gene obfuscation for delicious trial and error goodness.
	var/list/plant_icon_cache = list()      // Stores images of growth, fruits and seeds.
	var/list/plant_sprites = list()         // List of all harvested product sprites.
	var/list/plant_product_sprites = list() // List of all growth sprites plus number of growth stages.

	var/tmp/list/queue = list()

/datum/subsystem/plants/New()
	NEW_SS_GLOBAL(plant_controller)

/datum/subsystem/plants/Initialize(timeofday)
	// Build the icon lists.
	for(var/icostate in icon_states('icons/obj/hydroponics_growing.dmi'))
		var/split = findtext(icostate,"-")
		if(!split)
			// invalid icon_state
			continue

		var/ikey = copytext(icostate,(split+1))
		if(ikey == "dead")
			// don't count dead icons
			continue
		ikey = text2num(ikey)
		var/base = copytext(icostate,1,split)

		if(!(plant_sprites[base]) || (plant_sprites[base]<ikey))
			plant_sprites[base] = ikey

	for(var/icostate in icon_states('icons/obj/hydroponics_products.dmi'))
		var/split = findtext(icostate,"-")
		if(split)
			plant_product_sprites |= copytext(icostate,1,split)

	// Populate the global seed datum list.
	for(var/type in typesof(/datum/seed)-/datum/seed)
		var/datum/seed/S = new type
		seeds[S.name] = S
		S.uid = "[seeds.len]"
		S.roundstart = 1

	// Make sure any seed packets that were mapped in are updated
	// correctly (since the seed datums did not exist a tick ago).
	for(var/obj/item/seeds/S in world)
		S.update_seed()

	//Might as well mask the gene types while we're at it.
	var/list/used_masks = list()
	var/list/plant_traits = ALL_GENES
	while(plant_traits && plant_traits.len)
		var/gene_tag = pick(plant_traits)
		var/gene_mask = "[uppertext(num2hex(rand(0,255)))]"

		while(gene_mask in used_masks)
			gene_mask = "[uppertext(num2hex(rand(0,255)))]"

		used_masks += gene_mask
		plant_traits -= gene_tag
		gene_tag_masks[gene_tag] = gene_mask
	
	..()

/datum/subsystem/plants/Recover()
	src.product_descs = plant_controller.product_descs
	src.plant_queue = plant_controller.plant_queue
	src.seeds = plant_controller.seeds
	src.gene_tag_masks = plant_controller.gene_tag_masks
	src.plant_icon_cache = plant_controller.plant_icon_cache
	src.plant_sprites = plant_controller.plant_sprites
	src.plant_product_sprites = plant_controller.plant_product_sprites

// Proc for creating a random seed type.
/datum/subsystem/plants/proc/create_random_seed(var/survive_on_station)
	var/datum/seed/seed = new()
	seed.randomize()
	seed.uid = plant_controller.seeds.len + 1
	seed.name = "[seed.uid]"
	seeds[seed.name] = seed

	if(survive_on_station)
		if(seed.consume_gasses)
			seed.consume_gasses["phoron"] = null
			seed.consume_gasses["carbon_dioxide"] = null
		if(seed.chems && !isnull(seed.chems["pacid"]))
			seed.chems["pacid"] = null // Eating through the hull will make these plants completely inviable, albeit very dangerous.
			seed.chems -= null // Setting to null does not actually remove the entry, which is weird.
		seed.set_trait(TRAIT_IDEAL_HEAT,293)
		seed.set_trait(TRAIT_HEAT_TOLERANCE,20)
		seed.set_trait(TRAIT_IDEAL_LIGHT,8)
		seed.set_trait(TRAIT_LIGHT_TOLERANCE,5)
		seed.set_trait(TRAIT_LOWKPA_TOLERANCE,25)
		seed.set_trait(TRAIT_HIGHKPA_TOLERANCE,200)
	return seed

/datum/subsystem/plants/stat_entry()
	..("P:[plant_queue.len]")

/datum/subsystem/plants/fire(resumed = 0)
	if (!resumed)
		queue = plant_queue
		plant_queue = list()

	var/list/curr_queue = queue

	while (curr_queue.len)
		var/obj/effect/plant/P = curr_queue[curr_queue.len]
		curr_queue.len--

		if (!P || P.gcDestroyed || !istype(P))
			continue

		P.process()

		if (MC_TICK_CHECK)
			return

	if (!plant_queue.len)
		disable()

/datum/subsystem/plants/proc/add_plant(var/obj/effect/plant/plant)
	plant_queue |= plant
	enable()

/datum/subsystem/plants/proc/remove_plant(var/obj/effect/plant/plant)
	plant_queue -= plant


// Debug for testing seed genes.
/client/proc/show_plant_genes()
	set category = "Debug"
	set name = "Show Plant Genes"
	set desc = "Prints the round's plant gene masks."

	if(!holder)	return

	if(!plant_controller || !plant_controller.gene_tag_masks)
		usr << "Gene masks not set."
		return

	for(var/mask in plant_controller.gene_tag_masks)
		usr << "[mask]: [plant_controller.gene_tag_masks[mask]]"
