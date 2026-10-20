sub init()
    m.top.focusable = true
    m.name = m.top.FindNode("name") : m.index = m.top.FindNode("index")
    m.current = m.top.FindNode("current") : m.target = m.top.FindNode("target")
    m.mode = m.top.FindNode("mode") : m.action = m.top.FindNode("action")
    m.humidity = m.top.FindNode("humidity") : m.status = m.top.FindNode("status")
    m.items = [] : m.focusIndex = 0
end sub

sub onItems()
    m.items = m.top.items
    if m.items = invalid then m.items = []
    if m.focusIndex >= m.items.Count() then m.focusIndex = 0
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
end sub

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
