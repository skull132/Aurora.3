#define VUEUI_SET_CHECK(a, b, c, d) if (a != b) { a = b; c = d; }
/obj/machinery/photocopier
	name = "photocopier"
	icon = 'icons/obj/library.dmi'
	icon_state = "bigscanner"
	var/insert_anim = "bigscanner1"
	anchored = 1
	density = 1
	use_power = 1
	idle_power_usage = 30
	active_power_usage = 200
	power_channel = EQUIP
	var/obj/item/copyitem = null	//what's in the copier!
	var/toner = 30 //how much toner is left! woooooo~
	var/maxcopies = 10	//how many copies can be copied at once- idea shamelessly stolen from bs12's copier!

/obj/machinery/photocopier/attack_ai(mob/user as mob)
	return attack_hand(user)

/obj/machinery/photocopier/vueui_data_change(var/list/data, var/mob/user, var/vueui/ui)
	var/isChanged = FALSE
	if(!data)
		isChanged = TRUE
		data = list("copies" = 1)
	VUEUI_SET_CHECK(data["toner"], toner, isChanged, TRUE)
	VUEUI_SET_CHECK(data["isAI"], istype(user,/mob/living/silicon), isChanged, TRUE)
	VUEUI_SET_CHECK(data["gotitem"], !!copyitem, isChanged, TRUE)
	VUEUI_SET_CHECK(data["maxcopies"], maxcopies, isChanged, TRUE)
	// Sanity checks to determine if ui haven't gotten too far from reality
	if(data["copies"] < 1)
		VUEUI_SET_CHECK(data["copies"], 1, isChanged, TRUE)
	else if (data["copies"] > maxcopies)
		VUEUI_SET_CHECK(data["copies"], maxcopies, isChanged, TRUE)
	if(isChanged)
		return data

/obj/machinery/photocopier/attack_hand(mob/user as mob)
	user.set_machine(src)
	var/vueui/ui = SSvueui.get_open_ui(user, src)
	if (!ui)
		ui = new(usr, src, "paperwork-photocopier", 450, 350, capitalize(src.name))
	ui.open()

/obj/machinery/photocopier/Topic(href, href_list)
	if(href_list["copy"])
		if(stat & (BROKEN|NOPOWER))
			return
		var/vueui/ui = href_list["vueui"]
		if(!istype(ui))
			return
		var/copies = ui.data["copies"]

		for(var/i = 0, i < copies, i++)
			if(toner <= 0)
				break

			if (istype(copyitem, /obj/item/weapon/paper))
				copy(copyitem)
				sleep(20)
			else if (istype(copyitem, /obj/item/weapon/photo))
				photocopy(copyitem)
				sleep(15)
			else if (istype(copyitem, /obj/item/weapon/paper_bundle))
				var/obj/item/weapon/paper_bundle/B = bundlecopy(copyitem)
				sleep(15*B.pages.len)
			else
				usr << "<span class='warning'>\The [copyitem] can't be copied by \the [src].</span>"
				break

			use_power(active_power_usage)
		SSvueui.check_uis_for_change(src)
	else if(href_list["remove"])
		if(copyitem)
			copyitem.loc = usr.loc
			usr.put_in_hands(copyitem)
			usr << "<span class='notice'>You take \the [copyitem] out of \the [src].</span>"
			copyitem = null
			SSvueui.check_uis_for_change(src)
	else if(href_list["aipic"])
		if(!istype(usr,/mob/living/silicon)) return
		if(stat & (BROKEN|NOPOWER)) return

		if(toner >= 5)
			var/mob/living/silicon/tempAI = usr
			var/obj/item/device/camera/siliconcam/camera = tempAI.aiCamera

			if(!camera)
				return
			var/obj/item/weapon/photo/selection = camera.selectpicture()
			if (!selection)
				return

			var/obj/item/weapon/photo/p = photocopy(selection)
			if (p.desc == "")
				p.desc += "Copied by [tempAI.name]"
			else
				p.desc += " - Copied by [tempAI.name]"
			toner -= 5
			sleep(15)
		SSvueui.check_uis_for_change(src)

/obj/machinery/photocopier/attackby(obj/item/O as obj, mob/user as mob)
	if(istype(O, /obj/item/weapon/paper) || istype(O, /obj/item/weapon/photo) || istype(O, /obj/item/weapon/paper_bundle))
		if(!copyitem)
			user.drop_item()
			copyitem = O
			O.loc = src
			user << "<span class='notice'>You insert \the [O] into \the [src].</span>"
			flick(insert_anim, src)
			SSvueui.check_uis_for_change(src)
		else
			user << "<span class='notice'>There is already something in \the [src].</span>"
	else if(istype(O, /obj/item/device/toner))
		if(toner <= 10) //allow replacing when low toner is affecting the print darkness
			user.drop_item()
			user << "<span class='notice'>You insert the toner cartridge into \the [src].</span>"
			var/obj/item/device/toner/T = O
			toner += T.toner_amount
			qdel(O)
			SSvueui.check_uis_for_change(src)
		else
			user << "<span class='notice'>This cartridge is not yet ready for replacement! Use up the rest of the toner.</span>"
	else if(iswrench(O))
		playsound(loc, 'sound/items/Ratchet.ogg', 50, 1)
		anchored = !anchored
		user << "<span class='notice'>You [anchored ? "wrench" : "unwrench"] \the [src].</span>"
	return

/obj/machinery/photocopier/ex_act(severity)
	switch(severity)
		if(1.0)
			qdel(src)
		if(2.0)
			if(prob(50))
				qdel(src)
			else
				if(toner > 0)
					new /obj/effect/decal/cleanable/blood/oil(get_turf(src))
					toner = 0
		else
			if(prob(50))
				if(toner > 0)
					new /obj/effect/decal/cleanable/blood/oil(get_turf(src))
					toner = 0
	return

/obj/machinery/photocopier/proc/copy(var/obj/item/weapon/paper/copy, var/print = 1, var/use_sound = 1, var/delay = 20)
	var/obj/item/weapon/paper/c = new /obj/item/weapon/paper()
	var/info
	var/pname
	if (toner > 10)	//lots of toner, make it dark
		info = "<font color = #101010>"
	else			//no toner? shitty copies for you!
		info = "<font color = #808080>"
	var/copied = html_decode(copy.info)
	copied = replacetext(copied, "<font face=\"[c.deffont]\" color=", "<font face=\"[c.deffont]\" nocolor=")	//state of the art techniques in action
	copied = replacetext(copied, "<font face=\"[c.crayonfont]\" color=", "<font face=\"[c.crayonfont]\" nocolor=")	//This basically just breaks the existing color tag, which we need to do because the innermost tag takes priority.
	info += copied
	info += "</font>"//</font>
	pname = copy.name // -- Doohl
	c.fields = copy.fields
	c.stamps = copy.stamps
	c.stamped = copy.stamped
	c.ico = copy.ico
	c.offset_x = copy.offset_x
	c.offset_y = copy.offset_y
	var/list/temp_overlays = copy.overlays       //Iterates through stamps
	var/image/img                                //and puts a matching
	for (var/j = 1, j <= min(temp_overlays.len, copy.ico.len), j++) //gray overlay onto the copy
		if (findtext(copy.ico[j], "cap") || findtext(copy.ico[j], "cent"))
			img = image('icons/obj/bureaucracy.dmi', "paper_stamp-circle")
		else if (findtext(copy.ico[j], "deny"))
			img = image('icons/obj/bureaucracy.dmi', "paper_stamp-x")
		else
			img = image('icons/obj/bureaucracy.dmi', "paper_stamp-dots")
		img.pixel_x = copy.offset_x[j]
		img.pixel_y = copy.offset_y[j]
		c.add_overlay(img)
	
	toner--
	if(toner == 0)
		visible_message("<span class='notice'>A red light on \the [src] flashes, indicating that it is out of toner.</span>")
		return
	
	c.set_content_unsafe(pname, info)
	if (print)
		src.print(c, use_sound, 'sound/items/poster_being_created.ogg', delay)
	return c

/obj/machinery/photocopier/proc/photocopy(var/obj/item/weapon/photo/photocopy)
	var/obj/item/weapon/photo/p = photocopy.copy()
	p.loc = src.loc

	var/icon/I = icon(photocopy.icon, photocopy.icon_state)
	if(toner > 10)	//plenty of toner, go straight greyscale
		I.MapColors(rgb(77,77,77), rgb(150,150,150), rgb(28,28,28), rgb(0,0,0))		//I'm not sure how expensive this is, but given the many limitations of photocopying, it shouldn't be an issue.
		p.img.MapColors(rgb(77,77,77), rgb(150,150,150), rgb(28,28,28), rgb(0,0,0))
		p.tiny.MapColors(rgb(77,77,77), rgb(150,150,150), rgb(28,28,28), rgb(0,0,0))
	else			//not much toner left, lighten the photo
		I.MapColors(rgb(77,77,77), rgb(150,150,150), rgb(28,28,28), rgb(100,100,100))
		p.img.MapColors(rgb(77,77,77), rgb(150,150,150), rgb(28,28,28), rgb(100,100,100))
		p.tiny.MapColors(rgb(77,77,77), rgb(150,150,150), rgb(28,28,28), rgb(100,100,100))
	p.icon = I
	toner -= 5	//photos use a lot of ink!
	if(toner < 0)
		toner = 0
		visible_message("<span class='notice'>A red light on \the [src] flashes, indicating that it is out of toner.</span>")

	return p

//If need_toner is 0, the copies will still be lightened when low on toner, however it will not be prevented from printing. TODO: Implement print queues for fax machines and get rid of need_toner
/obj/machinery/photocopier/proc/bundlecopy(var/obj/item/weapon/paper_bundle/bundle, var/need_toner=1)
	var/obj/item/weapon/paper_bundle/p = new /obj/item/weapon/paper_bundle (src)
	for(var/obj/item/weapon/W in bundle.pages)
		if(toner <= 0 && need_toner)
			toner = 0
			visible_message("<span class='notice'>A red light on \the [src] flashes, indicating that it is out of toner.</span>")
			break

		if(istype(W, /obj/item/weapon/paper))
			W = copy(W)
		else if(istype(W, /obj/item/weapon/photo))
			W = photocopy(W)
		W.loc = p
		p.pages += W

	p.loc = src.loc
	p.update_icon()
	p.icon_state = "paper_words"
	p.name = bundle.name
	p.pixel_y = rand(-8, 8)
	p.pixel_x = rand(-9, 9)
	return p

/obj/item/device/toner
	name = "toner cartridge"
	icon_state = "tonercartridge"
	var/toner_amount = 30

#undef VUEUI_SET_CHECK