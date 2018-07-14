/proc/vueui_watch_var(source, data, datum/callback/cbSan, datum/callback/cbComp)
	if (cbComp)
		return new /datum/vueui_var_holder/comparator_based(source, data, cbSan, cbComp)
	else
		return new /datum/vueui_var_holder(source, data, cbSan)

/datum/vueui_var_monitor
	var/subject_type
	var/datum/vueui_var_holder/list/var_holders

/datum/vueui_var_monitor/New()
	var_holders = populate_var_holders()

/datum/vueui_var_monitor/proc/populate_var_holders()
	. = list()

/datum/vueui_var_monitor/proc/update_data(datum/ui_source, list/data, mob/user, datum/vueui/ui)
	for (var/_iter in var_holders)
		var/datum/vueui_var_holder/VH = _iter

		if (VH.need_to_replace(ui_source.vars[VH.source_key], data[VH.data_key], user, ui))
			if (VH.sanitizer)
				data[VH.data_key] = VH.sanitizer.Invoke(ui_source.vars[VH.source_key], data[VH.data_key], user, ui)
			else
				data[VH.data_key] = ui_source.vars[VH.source_key]

	return data

/datum/vueui_var_holder
	var/source_key
	var/data_key
	var/datum/callback/sanitizer

/datum/vueui_var_holder/New(source, data, datum/callback/cbSan)
	source_key = source
	data_key = data

	sanitizer = cbSan

/datum/vueui_var_holder/proc/need_to_replace(source, item)
	return source != item

/datum/vueui_var_holder/comparator_based
	var/datum/callback/comparator

/datum/vueui_var_holder/comparator_based/New(source, data, datum/callback/cbSan, datum/callback/cbComp)
	..()

	comparator = cbComp

/datum/vueui_var_holder/comparator_based/need_to_replace(source, item, mob/user, datum/vueui/ui)
	return comparator.Invoke(source, item, user, ui)
