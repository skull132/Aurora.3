/*
Byond Vue UI framework
main ui datum.
*/
#define UIDEBUG 0

/vueui
    var/name = "Vueui"
    // title of ui window
    var/title = "HTML5 UI"
    // user that opened this ui
    var/mob/user
    // object that contains this ui
    var/datum/object
    // browser window width
    var/width = 100
    // browser window height
    var/height = 100
    // current state of ui data
    var/list/data
    // currently used server generated assets
    var/list/assets
    // current status of ui
    var/status = STATUS_INTERACTIVE
    var/datum/topic_state/state = null
    // currently active ui component
    var/activeui = "test"
    // header used for this ui, should be set before open()
    var/header = "default"
    // window id
    var/windowid
    // determines if ui state should be constantly be cheacked for updates
    var/auto_update_content = FALSE


/**
  * Creates a new ui
  *
  * @param nuser - user that has opened this ui
  * @param nobject - object that hosts this ui and handles all data / Topic processing
  * @param nactiveui - Vue component that is opened to render this ui's data
  * @param nwidth - initial width of this ui
  * @param nheight - initial height of this ui
  * @param ntitle - title of this ui
  * @param ndata - initial data. Optional.
  * @param nstate - Topic state used for this ui's checks. Optional.
  *
  * @return nothing
  */
/vueui/New(var/nuser, var/nobject, var/nactiveui = 0, var/nwidth = 0, var/nheight = 0, var/ntitle, var/list/ndata, var/datum/topic_state/nstate = default_state)
    user = nuser
    object = nobject
    data = ndata
    state = nstate

    if (nactiveui)
        activeui = nactiveui
    if (nwidth)
        width = nwidth
    if (nheight)
        height = nheight
    if (ntitle)
        title = ntitle

    SSvueui.ui_opened(src)
    windowid = "vueui\ref[src]"
    name = "Vueui [object]/[user]"

/**
  * Opens this ui, gathers initial data
  *
  * @return nothing
  */
/vueui/proc/open()
    if(QDELETED(object))
        return
    if(!user.client)
        return
    
    if(!data)
        data = object.vueui_data_change(null, user, src)
    update_status()
    if(!status || status == STATUS_CLOSE)
        return

    var/params = "window=[windowid];"
    if(width && height)
        params += "size=[width]x[height];"
    send_resources_and_assets(user.client)
    user << browse(generate_html(), params)
    winset(user, "mapwindow.map", "focus=true")
    spawn(1)
        winset(user, windowid, "on-close=\"vueuiclose \ref[src]\"")

/**
  * Closes this ui
  *
  * @return nothing
  */
/vueui/proc/close()
    SSvueui.ui_closed(src)
    user << browse(null, "window=[windowid]")
    status = null
    
/**
  * Generates base html for this ui to be rendered.
  *
  * @return html code - text
  */
/vueui/proc/generate_html()
#if UIDEBUG
    var/debugtxt = "<div id=\"dapp\"></div>"
#else
    var/debugtxt = ""
#endif
    return {"
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="X-UA-Compatible" content="IE=11">
        <meta charset="UTF-8">
        <link rel="stylesheet" type="text/css" href="vueui.css">
    </head>
    <body class="[get_theme_class()]">
        <div id="header">
            <header-[header]></header-[header]>
        </div>
        <div id="app">

        </div>
        [debugtxt]
        <noscript>
            <div id='uiNoScript'>
                <h2>JAVASCRIPT REQUIRED</h2>
                <p>Your Internet Explorer's Javascript is disabled (or broken).<br/>
                Enable Javascript and then open this UI again.</p>
            </div>
        </noscript>
    </body>
    <script type="application/json" id="initialstate">
        [generate_data_json()]
    </script>
    <script type="text/javascript" src="vueui.js"></script>
</html>
    "}

/**
  * Generates json state object to be sent to ui.
  *
  * @return json object - text
  */
/vueui/proc/generate_data_json()
    var/list/sdata = list()
    sdata["state"] = src.data
    sdata["assets"] = list()
    sdata["active"] = activeui
    sdata["uiref"] = "\ref[src]"
    sdata["status"] = status
    sdata["title"] = title
    sdata["wtime"] = world.time
    for(var/asset_name in assets)
        var/asset = assets[asset_name]
        sdata["assets"][asset_name] = list("ref" = ckey("\ref[asset["img"]]"))
    return json_encode(sdata)

/**
  * Sends all resources required for proper renderig of ui
  *
  * @param cl - client that should get assets
  *
  * @return nothing
  */ 
/vueui/proc/send_resources_and_assets(var/client/cl)
#if UIDEBUG
    cl << browse_rsc(file("vueui/dist/main.js"), "vueui.js")
    cl << browse_rsc(file("vueui/dist/main.css"), "vueui.css")
#else
    var/datum/asset/assets = get_asset_datum(/datum/asset/simple/vueui)
    assets.send(cl)
#endif
    for(var/asset_name in assets)
        var/asset = assets[asset_name]
        if (!QDELETED(asset["img"]))
            cl << browse_rsc(asset["img"], "vueuiimg_" + ckey("\ref[asset["img"]]") + ".png")

/**
  * Sends requested asset to ui's client
  *
  * @param name - asset's name that should be sent to client
  *
  * @return nothing
  */ 
/vueui/proc/send_asset(var/name)
    if (!QDELETED(user) || !user.client)
        return
    name = ckey(name)
    if (name in assets)
        user.client << browse_rsc(assets[name]["img"], "vueuiimg_" + ckey("\ref[assets[name]["img"]]") + ".png")

/**
  * Adds / sets dynamic asset for this ui's use
  *
  * @param name - name of asset that should be added
  * @param img - image, an asset that will be used
  *
  * @return nothing
  */ 
/vueui/proc/add_asset(var/name, var/image/img)
    if(QDELETED(img))
        return
    name = ckey(name)
    LAZYINITLIST(assets)
    assets[name] = list("name" = name, "img" = img)

/**
  * Removes dynamic asset for this ui's use
  *
  * @param name - name of asset that will be removed
  *
  * @return nothing
  */ 
/vueui/proc/remove_asset(var/name)
    name = ckey(name)
    assets -= assets[name]

/**
  * Handles interactivity and state updates
  *
  * @return nothing
  */ 
/vueui/Topic(href, href_list)
    update_status()
    if(status < STATUS_INTERACTIVE || user != usr)
        return
    if(href_list["vueuistateupdate"])
        var/rdata = json_decode(href_list["vueuistateupdate"])
        var/ndata = rdata["state"]
        var/ret = object.vueui_data_change(ndata, user, src)
        if(ret)
            ndata = ret
            push_change(ret)
        src.data = ndata
    href_list["vueui"] = src // Let's pass our UI object to object for it to do things.
    object.Topic(href, href_list)

/**
  * Pushes latest data to client (Including metadata such as: assets index, status, activeui)
  *
  * @param ndate - new data that should be pushed to client, if null then exisitng data is pushed
  *
  * @return nothing
  */ 
/vueui/proc/push_change(var/list/ndata)
    if(ndata && status > STATUS_DISABLED)
        src.data = ndata
    user << output(list2params(list(generate_data_json())),"[windowid].browser:receiveUIState")

/**
  * Check for change and push that change of data
  *
  * @param force - determines should data be pushed even if no change is present
  *
  * @return nothing
  */ 
/vueui/proc/check_for_change(var/force = 0)
    if(status > STATUS_DISABLED)
        var/ret = object.vueui_data_change(data, user, src)
        if(ret)
            push_change(ret)
        else if (force)
            push_change(null)
    else if (force && status == STATUS_DISABLED)
        push_change(null)

/**
  * Set the current status (also known as visibility) of this ui.
  *
  * @param state int The status to set, see the defines at the top of this file
  *
  * @return nothing
  */
/vueui/proc/set_status(nstatus)
    if (nstatus != status) // Only update if it is different
        status = nstatus
        if(nstatus > STATUS_DISABLED)
            check_for_change(1) // Gather data and update it
        else if (nstatus == STATUS_DISABLED)
            push_change(null) // Only update ui data
        else
            close()

/**
  * Update the status (visibility) of this ui based on the user's status
  *
  * @return nothing
  */
/vueui/proc/update_status()
    set_status(object.CanUseTopic(user, state))

/**
  * Process this ui
  *
  * @return nothing
  */
/vueui/process()
    if (!object || !user || status < 0)
        close()
        return
    update_status()
    if(auto_update_content)
        check_for_change()

/**
  * Returns actuve theme on varous conditions
  *
  * @return themes class - text
  */
/vueui/proc/get_theme_class()
    return get_html_theme_class(user)

#undef UIDEBUG