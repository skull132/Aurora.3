var/datum/subsystem/chemistry/chemistryProcess

/datum/subsystem/chemistry
	name = "Chemistry"
	wait = 2 SECONDS
	flags = SS_NO_INIT

	var/list/active_holders
	var/list/chemical_reactions
	var/list/chemical_reagents

	var/tmp/list/processing_holders = list()

/datum/subsystem/chemistry/New()
	NEW_SS_GLOBAL(chemistryProcess)
	active_holders = list()
	chemical_reactions = chemical_reactions_list
	chemical_reagents = chemical_reagents_list

/datum/subsystem/chemistry/fire(resumed = FALSE)
	if (!resumed)
		processing_holders = active_holders.Copy()

	while (processing_holders.len)
		var/datum/reagents/holder = processing_holders[processing_holders.len]
		processing_holders.len--

		if (!holder.process_reactions())
			active_holders -= holder

		if (MC_TICK_CHECK)
			return
		
/datum/subsystem/chemistry/proc/mark_for_update(var/datum/reagents/holder)
	if (holder in active_holders)
		return

	//Process once, right away. If we still need to continue then add to the active_holders list and continue later
	if (holder.process_reactions())
		active_holders += holder
