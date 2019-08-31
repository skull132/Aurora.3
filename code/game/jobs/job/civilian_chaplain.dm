//Due to how large this one is it gets its own file
/datum/job/chaplain
	title = "Chaplain"
	department = "Civilian"
	total_positions = 1
	spawn_positions = 1
	supervisors = "the head of personnel"
	selection_color = "#dddddd"
	access = list(access_morgue, access_chapel_office, access_crematorium, access_maint_tunnels)
	minimal_access = list(access_morgue, access_chapel_office, access_crematorium)
	outfit = /datum/outfit/job/chaplain

/datum/job/chaplain/presbyter
	title = "Presbyter"
	master_job = /datum/job/chaplain

/datum/job/chaplain/rabbi
	title = "Rabbi"
	master_job = /datum/job/chaplain

/datum/job/chaplain/imam
	title = "Imam"
	master_job = /datum/job/chaplain

/datum/job/chaplain/priest
	title = "Priest"
	master_job = /datum/job/chaplain

/datum/job/chaplain/shaman
	title = "Shaman"
	master_job = /datum/job/chaplain

/datum/job/chaplain/counselor
	title = "Counselor"
	master_job = /datum/job/chaplain

/datum/outfit/job/chaplain
	name = "Chaplain"
	jobtype = /datum/job/chaplain
	uniform = /obj/item/clothing/under/rank/chaplain
	shoes = /obj/item/clothing/shoes/black
	l_ear = /obj/item/device/radio/headset/headset_service
	pda = /obj/item/device/pda/chaplain

/datum/outfit/job/chaplain/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	. = ..()

	if(visualsOnly)
		return

	var/obj/item/weapon/storage/bible/B = new /obj/item/weapon/storage/bible(get_turf(H)) //BS12 EDIT
	var/obj/item/weapon/storage/S = locate() in H.contents
	if(S && istype(S))
		B.forceMove(S)

	var/datum/religion/religion = SSrecords.religions[H.religion]
	if (religion)

		if(religion.name == "None" || religion.name == "Other")
			B.verbs += /obj/item/weapon/storage/bible/proc/Set_Religion
			return 1

		B.icon_state = religion.book_sprite
		B.name = religion.book_name
		SSticker.Bible_icon_state = religion.book_sprite
		SSticker.Bible_item_state = religion.book_sprite
		SSticker.Bible_name = religion.book_name
		return 1