sub init()
    m.top.focusable = true
    m.cardsGroup = m.top.FindNode("cards")
    m.modePopup = m.top.FindNode("modePopup")
    m.popupTitle = m.top.FindNode("popupTitle")
    m.popupModesGroup = m.top.FindNode("popupModes")
    m.status = m.top.FindNode("status")
    m.empty = m.top.FindNode("empty")
    m.items = []
    m.cards = []
    m.focusIndex = 0
    m.popupOpen = false
    m.popupIndex = 0
    m.popupModes = []
    buildCards()
end sub

sub buildCards()
    for i = 0 to 1
        x = i * 850
        focus = m.cardsGroup.CreateChild("Rectangle")
        focus.translation = [x, 0]
        focus.width = 790
        focus.height = 700
        focus.color = "0xF2A24BFF"
        focus.visible = false
        panel = m.cardsGroup.CreateChild("Rectangle")
        panel.translation = [x + 7, 7]
        panel.width = 776
        panel.height = 686
        panel.color = "0x382A22FF"
        name = m.cardsGroup.CreateChild("Label")
        name.translation = [x + 30, 35]
        name.width = 730
        name.height = 62
        name.horizAlign = "center"
        name.font = "font:LargeSystemFont"
        current = m.cardsGroup.CreateChild("Label")
        current.translation = [x + 30, 145]
        current.width = 350
        current.height = 125
        current.horizAlign = "center"
        current.font = "font:LargestSystemFont"
        target = m.cardsGroup.CreateChild("Label")
        target.translation = [x + 410, 145]
        target.width = 350
        target.height = 125
        target.horizAlign = "center"
        target.font = "font:LargestSystemFont"
        currentLabel = m.cardsGroup.CreateChild("Label")
        currentLabel.translation = [x + 30, 275]
        currentLabel.width = 350
        currentLabel.height = 42
        currentLabel.horizAlign = "center"
        currentLabel.text = "CURRENT"
        currentLabel.color = "0xC0B49CFF"
        targetLabel = m.cardsGroup.CreateChild("Label")
        targetLabel.translation = [x + 410, 275]
        targetLabel.width = 350
        targetLabel.height = 42
        targetLabel.horizAlign = "center"
        targetLabel.text = "TARGET"
        targetLabel.color = "0xC0B49CFF"
        modeIcon = m.cardsGroup.CreateChild("Poster")
        modeIcon.translation = [x + 335, 370]
        modeIcon.width = 120
        modeIcon.height = 120
        modeIcon.loadDisplayMode = "scaleToFit"
        mode = m.cardsGroup.CreateChild("Label")
        mode.translation = [x + 30, 510]
        mode.width = 730
        mode.height = 58
        mode.horizAlign = "center"
        mode.font = "font:MediumSystemFont"
        humidity = m.cardsGroup.CreateChild("Label")
        humidity.translation = [x + 30, 605]
        humidity.width = 730
        humidity.height = 42
        humidity.horizAlign = "center"
        humidity.color = "0xC0B49CFF"
        m.cards.Push({ focus: focus, panel: panel, name: name, current: current, target: target, modeIcon: modeIcon, mode: mode, humidity: humidity, currentLabel: currentLabel, targetLabel: targetLabel })
    end for
end sub

sub onItems()
    m.items = m.top.items
    if m.items = invalid then m.items = []
    if m.focusIndex >= m.items.Count() then m.focusIndex = 0
    renderClimate()
end sub

sub renderClimate()
    m.empty.visible = m.items.Count() = 0
    for i = 0 to 1
        card = m.cards[i]
        visible = i < m.items.Count()
        card.panel.visible = visible
        card.focus.visible = visible and i = m.focusIndex
        card.name.visible = visible
        card.current.visible = visible
        card.target.visible = visible
        card.modeIcon.visible = visible
        card.mode.visible = visible
        card.humidity.visible = visible
        card.currentLabel.visible = visible
        card.targetLabel.visible = visible
        if visible then renderCard(card, m.items[i])
    end for
end sub

sub renderCard(card as object, item as object)
    card.name.text = item.name
    card.current.text = tempText(item.current_temperature)
    card.target.text = tempText(item.temperature)
    if item.temperature = invalid and item.target_temp_low <> invalid
        card.target.text = tempText(item.target_temp_low) + " - " + tempText(item.target_temp_high)
    end if
    modeName = valueOr(item.state, "unknown")
    card.mode.text = "MODE: " + UCase(modeName.Replace("_", " "))
    card.modeIcon.uri = ClimateIconUri(modeName)
    if item.humidity <> invalid then card.humidity.text = "Humidity: " + item.humidity.ToStr() + "%" else card.humidity.text = ""
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

sub openModePopup()
    if m.items.Count() = 0 then return
    item = m.items[m.focusIndex]
    modes = item.hvac_modes
    if modes = invalid or modes.Count() = 0 then return
    m.popupModes = modes
    m.popupIndex = 0
    for i = 0 to modes.Count() - 1
        if LCase(modes[i].ToStr()) = LCase(item.state.ToStr()) then m.popupIndex = i
    end for
    m.popupTitle.text = item.name + " — HVAC MODE"
    clearPopupModes()
    for i = 0 to modes.Count() - 1
        label = m.popupModesGroup.CreateChild("Label")
        label.translation = [0, i * 65]
        label.width = 820
        label.height = 55
        label.horizAlign = "center"
        label.font = "font:MediumSystemFont"
        label.text = UCase(modes[i].ToStr().Replace("_", " "))
        label.color = "0xFFF0D5FF"
        m.popupLabels.Push(label)
    end for
    renderPopupFocus()
    m.modePopup.visible = true
    m.popupOpen = true
end sub

sub clearPopupModes()
    m.popupLabels = []
    for each child in m.popupModesGroup.GetChildren(-1, 0)
        m.popupModesGroup.RemoveChild(child)
    end for
end sub

sub renderPopupFocus()
    for i = 0 to m.popupLabels.Count() - 1
        if i = m.popupIndex then m.popupLabels[i].color = "0xFFD080FF" else m.popupLabels[i].color = "0xFFF0D5FF"
    end for
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    m.top.activity = key
    if m.popupOpen
        if key = "up" and m.popupIndex > 0 then m.popupIndex = m.popupIndex - 1 : renderPopupFocus() : return true
        if key = "down" and m.popupIndex + 1 < m.popupLabels.Count() then m.popupIndex = m.popupIndex + 1 : renderPopupFocus() : return true
        if key = "OK"
            m.top.commandRequest = { action: "climate_mode", entity_id: m.items[m.focusIndex].entity_id, value: m.popupModes[m.popupIndex] }
            m.status.text = "Setting " + m.popupModes[m.popupIndex] + "..."
            m.modePopup.visible = false : m.popupOpen = false
            return true
        end if
        if key = "back" then m.modePopup.visible = false : m.popupOpen = false : return true
        return true
    end if
    count = m.items.Count()
    if key = "left" and count > 0 then m.focusIndex = (m.focusIndex - 1 + count) MOD count : renderClimate() : return true
    if key = "right" and count > 0 then m.focusIndex = (m.focusIndex + 1) MOD count : renderClimate() : return true
    if key = "up" or key = "down"
        if count > 0
            item = m.items[m.focusIndex]
            target = item.temperature
            if target = invalid then target = item.current_temperature
            if target <> invalid
                if key = "up" then target = target + 1 else target = target - 1
                m.top.commandRequest = { action: "climate_temperature", entity_id: item.entity_id, value: target }
            end if
        end if
        return true
    end if
    if key = "OK" then openModePopup() : return true
    return false
end function

sub onCommandResult()
    result = m.top.commandResult
    if result <> invalid then if result.ok then m.status.text = "Updated" else m.status.text = "Command failed"
end sub

sub onKeyInput()
    onKeyEvent(m.top.keyInput, true)
end sub
