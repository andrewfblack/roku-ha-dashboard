sub init()
    m.grid = m.top.FindNode("grid")
    m.status = m.top.FindNode("status")
    m.empty = m.top.FindNode("empty")
    m.items = []
    m.cards = []
    m.focusIndex = 0
    buildCards()
end sub

sub buildCards()
    for i = 0 to 11
        col = i MOD 3
        row = Int(i / 3)
        x = col * 590
        y = row * 205
        focus = m.grid.CreateChild("Rectangle")
        focus.translation = [x, y]
        focus.width = 550
        focus.height = 175
        focus.color = "0xF2A24BFF"
        focus.visible = false
        panel = m.grid.CreateChild("Rectangle")
        panel.translation = [x + 7, y + 7]
        panel.width = 536
        panel.height = 161
        panel.color = "0x241A10EE"
        name = m.grid.CreateChild("Label")
        name.translation = [x + 28, y + 25]
        name.width = 490
        name.height = 55
        state = m.grid.CreateChild("Label")
        state.translation = [x + 28, y + 92]
        state.width = 490
        state.height = 48
        state.color = "0xC0B49CFF"
        m.cards.Push({ focus: focus, panel: panel, name: name, state: state })
    end for
end sub

sub onItems()
    m.items = m.top.items
    if m.items = invalid then m.items = []
    if m.focusIndex >= m.items.Count() then m.focusIndex = 0
    m.empty.visible = (m.items.Count() = 0)
    for i = 0 to m.cards.Count() - 1
        card = m.cards[i]
        visible = i < m.items.Count()
        card.panel.visible = visible
        card.name.visible = visible
        card.state.visible = visible
        card.focus.visible = visible and i = m.focusIndex
        if visible
            item = m.items[i]
            card.name.text = item.name
            detail = UCase(item.state)
            if item.brightness <> invalid
                detail = detail + "   " + Int(item.brightness * 100 / 255).ToStr() + "%"
            end if
            card.state.text = detail
        end if
    end for
end sub

sub renderFocus()
    for i = 0 to m.cards.Count() - 1
        m.cards[i].focus.visible = i < m.items.Count() and i = m.focusIndex
    end for
end sub

sub onCommandResult()
    result = m.top.commandResult
    if result = invalid then return
    if result.ok then m.status.text = "Command sent" else m.status.text = "Command failed"
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    count = m.items.Count()
    if key = "left"
        if count = 0 or m.focusIndex MOD 3 = 0
            m.top.tabRequest = "previous"
        else
            m.focusIndex = m.focusIndex - 1
            renderFocus()
        end if
        return true
    else if key = "right"
        if count = 0 or m.focusIndex + 1 >= count or m.focusIndex MOD 3 = 2
            m.top.tabRequest = "next"
        else
            m.focusIndex = m.focusIndex + 1
            renderFocus()
        end if
        return true
    else if key = "up" and m.focusIndex >= 3
        m.focusIndex = m.focusIndex - 3
        renderFocus()
        return true
    else if key = "down" and m.focusIndex + 3 < count
        m.focusIndex = m.focusIndex + 3
        renderFocus()
        return true
    else if key = "OK" and count > 0
        m.status.text = "Sending..."
        m.top.commandRequest = { action: "light_toggle", entity_id: m.items[m.focusIndex].entity_id }
        return true
    else if key = "play" and count > 0
        item = m.items[m.focusIndex]
        pct = 0
        if item.brightness <> invalid then pct = Int(item.brightness * 100 / 255)
        nextPct = 25
        if pct >= 25 then nextPct = 50
        if pct >= 50 then nextPct = 75
        if pct >= 75 then nextPct = 100
        if pct >= 100 then nextPct = 25
        m.status.text = "Setting " + nextPct.ToStr() + "%..."
        m.top.commandRequest = { action: "light_brightness", entity_id: item.entity_id, value: nextPct }
        return true
    else if key = "back"
        m.top.tabRequest = "previous"
        return true
    end if
    return false
end function
