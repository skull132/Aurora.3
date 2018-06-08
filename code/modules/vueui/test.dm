/client/var/datum/vueuiuitest/tui

/client/verb/testvueui()
    set name = "test-vueui"
    if(!tui)
        tui = new()
    tui.open_ui()

/datum/vueuiuitest

/datum/vueuiuitest/proc/open_ui()
    var/datum/vueuiui/ui = SSvueui.get_open_ui(usr, src)
    if (!ui)
        ui = new(usr, src, "test", 300, 300)
    ui.open()

/datum/vueuiuitest/vueui_state_change(var/list/newstate, var/mob/user, var/datum/vueuiui/ui)
    if(!newstate)
        // generate new state
        return list("c" = 0)
    if(newstate["c"] >= 10)
        return list("c" = 0)
    return


/datum/vueuiuitest/Topic(href, href_list)
    if(href_list["action"] == "test")
        world << "VueUiTest got action Test called with data [href_list["data"]]"
    return