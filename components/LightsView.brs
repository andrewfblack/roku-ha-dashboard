sub init()
    m.top.focusable = true
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
        col = i MOD 4
        row = Int(i / 4)
        x = col * 340
        y = row * 285
        focus = m.grid.CreateChild("Rectangle")
        focus.translation = [x, y]
        focus.width = 300
        focus.height = 300
        focus.color = "0xF2A24BFF"
        focus.visible = false
        panel = m.grid.CreateChild("Rectangle")
        panel.translation = [x + 7, y + 7]
        panel.width = 286
        panel.height = 286
        panel.color = "0x241A10F2"
        name = m.grid.CreateChild("Label")
        name.translation = [x + 18, y + 20]
        name.width = 264
        name.height = 55
        name.horizAlign = "center"
        name.font = "font:LargeSystemFont"
        icon = m.grid.CreateChild("Poster")
        icon.translation = [x + 102, y + 88]
        icon.width = 96
        icon.height = 96
        icon.loadDisplayMode = "scaleToFit"
        state = m.grid.CreateChild("Label")
        state.translation = [x + 18, y + 220]
        state.width = 264
        state.height = 48
        state.horizAlign = "center"
        state.color = "0xC0B49CFF"
        m.cards.Push({ focus: focus, panel: panel, name: name, icon: icon, state: state })
    end for
end sub

sub onItems()
    m.items = m.top.items
    if m.items = invalid then m.items = []
    if m.focusIndex >= m.items.Count() then m.focusIndex = 0
    print "LIGHTS UI: "; m.items.Count(); " configured items"
    m.empty.visible = (m.items.Count() = 0)
    for i = 0 to m.cards.Count() - 1
        card = m.cards[i]
        visible = i < m.items.Count()
        card.panel.visible = visible
        card.name.visible = visible
        card.icon.visible = visible
        card.state.visible = visible
        card.focus.visible = visible and i = m.focusIndex
        if visible
            item = m.items[i]
            card.name.text = item.name
            card.icon.uri = LightIconUri(item)
            detail = UCase(item.state)
            if item.brightness <> invalid
                detail = detail + "   " + Int(item.brightness * 100 / 255).ToStr() + "%"
            end if
            card.state.text = detail
        end if
    end for
end sub

function LightIconUri(item as object) as string
    domain = "light"
    if item.domain <> invalid then domain = LCase(item.domain.ToStr())
    if domain = "switch" then return "pkg:/images/mdi/light-switch.png"
    return "pkg:/images/mdi/lightbulb-on.png"
end function

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
    m.top.activity = key
    count = m.items.Count()
    if key = "left"
        if count > 0 then m.focusIndex = (m.focusIndex - 1 + count) MOD count : renderFocus()
        return true
    else if key = "right"
        if count > 0 then m.focusIndex = (m.focusIndex + 1) MOD count : renderFocus()
        return true
    else if key = "up" and m.focusIndex >= 4
        m.focusIndex = m.focusIndex - 4
        renderFocus()
        return true
    else if key = "down" and m.focusIndex + 4 < count
        m.focusIndex = m.focusIndex + 4
        renderFocus()
        return true
    else if key = "OK" and count > 0
        m.status.text = "Sending..."
        m.top.commandRequest = { action: "light_toggle", entity_id: m.items[m.focusIndex].entity_id }
        return true
    else if key = "play" and count > 0 and (m.items[m.focusIndex].domain = invalid or m.items[m.focusIndex].domain = "light")
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
        return true
    end if
    return false
end function

sub onKeyInput()
    onKeyEvent(m.top.keyInput, true)
end sub
