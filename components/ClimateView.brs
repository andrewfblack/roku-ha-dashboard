sub init()
    m.top.focusable = true
    m.name = m.top.FindNode("name") : m.index = m.top.FindNode("index")
    m.current = m.top.FindNode("current") : m.target = m.top.FindNode("target")
    m.mode = m.top.FindNode("mode") : m.action = m.top.FindNode("action")
    m.humidity = m.top.FindNode("humidity") : m.status = m.top.FindNode("status")
    m.modeGroup = m.top.FindNode("modeButtons")
    m.modeCards = []
    buildModeCards()
    m.items = [] : m.focusIndex = 0
end sub

sub onItems()
    m.items = m.top.items
    if m.items = invalid then m.items = []
    if m.focusIndex >= m.items.Count() then m.focusIndex = 0
    print "CLIMATE UI: "; m.items.Count(); " configured items"
    renderClimate()
end sub

sub renderClimate()
    if m.items.Count() = 0
        m.name.text = "No climate entity selected in Home Assistant"
        m.current.text = "--" : m.target.text = "--" : return
    end if
    item = m.items[m.focusIndex]
    m.name.text = item.name
    m.index.text = (m.focusIndex + 1).ToStr() + " of " + m.items.Count().ToStr()
    m.current.text = tempText(item.current_temperature)
    m.target.text = tempText(item.temperature)
    if item.temperature = invalid and item.target_temp_low <> invalid
        m.target.text = tempText(item.target_temp_low) + " - " + tempText(item.target_temp_high)
    end if
    m.mode.text = "Mode: " + UCase(item.state)
    m.action.text = "Action: " + valueOr(item.hvac_action, "idle")
    if item.humidity <> invalid then m.humidity.text = "Humidity: " + item.humidity.ToStr() + "%" else m.humidity.text = ""
    renderModeCards(item)
end sub

sub buildModeCards()
    for i = 0 to 6
        focus = m.modeGroup.CreateChild("Rectangle")
        focus.width = 160 : focus.height = 92 : focus.translation = [i * 178, 0]
        focus.color = "0xE5A84BFF" : focus.visible = false
        panel = m.modeGroup.CreateChild("Rectangle")
        panel.width = 150 : panel.height = 82 : panel.translation = [i * 178 + 5, 5]
        panel.color = "0x382A1DFF"
        icon = m.modeGroup.CreateChild("Poster")
        icon.width = 50 : icon.height = 50 : icon.translation = [i * 178 + 15, 10]
        icon.loadDisplayMode = "scaleToFit"
        label = m.modeGroup.CreateChild("Label")
        label.width = 80 : label.height = 52 : label.translation = [i * 178 + 70, 20]
        m.modeCards.Push({ focus: focus, panel: panel, icon: icon, label: label })
    end for
end sub

sub renderModeCards(item as object)
    modes = item.hvac_modes
    if modes = invalid then modes = []
    for i = 0 to 6
        card = m.modeCards[i] : visible = i < modes.Count()
        card.panel.visible = visible : card.icon.visible = visible : card.label.visible = visible
        card.focus.visible = false
        if visible
            modeName = modes[i].ToStr()
            card.focus.visible = modeName = item.state
            card.icon.uri = ClimateIconUri(modeName)
            card.label.text = UCase(modeName.Replace("_", " "))
        end if
    end for
end sub

function ClimateIconUri(modeName as string) as string
    key = LCase(modeName)
    supported = { "auto": true, "heat_cool": true, "heat": true, "cool": true, "dry": true, "fan_only": true, "off": true }
    if not supported.DoesExist(key) then key = "auto"
    return "pkg:/images/climate/" + key + ".png"
end function

function tempText(value as dynamic) as string
    if value = invalid then return "--"
    text = value.ToStr()
    if Right(text, 2) = ".0" then text = Left(text, Len(text) - 2)
    return text + Chr(176)
end function

function valueOr(value as dynamic, fallback as string) as string
    if value = invalid then return fallback
    return value.ToStr()
end function

sub onCommandResult()
    result = m.top.commandResult
    if result = invalid then return
    if result.ok then m.status.text = "Updated" else m.status.text = "Update failed"
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    count = m.items.Count()
    if key = "left"
        if m.focusIndex > 0 then m.focusIndex = m.focusIndex - 1 : renderClimate() else m.top.tabRequest = "previous"
        return true
    else if key = "right"
        if m.focusIndex + 1 < count then m.focusIndex = m.focusIndex + 1 : renderClimate() else m.top.tabRequest = "next"
        return true
    else if (key = "up" or key = "down") and count > 0
        item = m.items[m.focusIndex]
        target = item.temperature
        if target = invalid then target = item.current_temperature
        if target = invalid then return true
        stepValue = item.target_temp_step
        if stepValue = invalid then stepValue = 1
        if key = "up" then target = target + stepValue else target = target - stepValue
        if item.min_temp <> invalid and target < item.min_temp then target = item.min_temp
        if item.max_temp <> invalid and target > item.max_temp then target = item.max_temp
        m.status.text = "Setting " + tempText(target) + "..."
        m.top.commandRequest = { action: "climate_temperature", entity_id: item.entity_id, value: target }
        return true
    else if key = "OK" and count > 0
        item = m.items[m.focusIndex] : modes = item.hvac_modes
        if modes = invalid or modes.Count() = 0 then return true
        nextIndex = 0
        for i = 0 to modes.Count() - 1
            if modes[i] = item.state then nextIndex = (i + 1) MOD modes.Count()
        end for
        m.status.text = "Setting " + modes[nextIndex] + "..."
        m.top.commandRequest = { action: "climate_mode", entity_id: item.entity_id, value: modes[nextIndex] }
        return true
    else if key = "back"
        m.top.tabRequest = "previous" : return true
    end if
    return false
end function

sub onKeyInput()
    onKeyEvent(m.top.keyInput, true)
end sub
