sub init()
    m.top.focusable = true
    m.grid = m.top.FindNode("grid")
    m.status = m.top.FindNode("status")
    m.empty = m.top.FindNode("empty")
    m.items = []
    m.cards = []
    m.focusIndex = 0
    for i = 0 to 11
        col = i MOD 3 : row = Int(i / 3) : x = col * 590 : y = row * 205
        focus = m.grid.CreateChild("Rectangle")
        focus.translation = [x, y] : focus.width = 550 : focus.height = 175
        focus.color = "0xF2A24BFF" : focus.visible = false
        panel = m.grid.CreateChild("Rectangle")
        panel.translation = [x + 7, y + 7] : panel.width = 536 : panel.height = 161 : panel.color = "0x241A10EE"
        name = m.grid.CreateChild("Label")
        name.translation = [x + 28, y + 48] : name.width = 490 : name.height = 62 : name.horizAlign = "center"
        m.cards.Push({ focus: focus, panel: panel, name: name })
    end for
end sub

sub onItems()
    m.items = m.top.items
    if m.items = invalid then m.items = []
    if m.focusIndex >= m.items.Count() then m.focusIndex = 0
    m.empty.visible = m.items.Count() = 0
    for i = 0 to 11
        visible = i < m.items.Count() : card = m.cards[i]
        card.panel.visible = visible : card.name.visible = visible
        card.focus.visible = visible and i = m.focusIndex
        if visible then card.name.text = m.items[i].name
    end for
end sub

sub renderFocus()
    for i = 0 to 11 : m.cards[i].focus.visible = i < m.items.Count() and i = m.focusIndex : end for
end sub

sub onCommandResult()
    result = m.top.commandResult
    if result = invalid then return
    if result.ok then m.status.text = "Activated" else m.status.text = "Activation failed"
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    count = m.items.Count()
    if key = "left"
        if count = 0 or m.focusIndex MOD 3 = 0 then m.top.tabRequest = "previous" else m.focusIndex = m.focusIndex - 1 : renderFocus()
        return true
    else if key = "right"
        if count = 0 or m.focusIndex + 1 >= count or m.focusIndex MOD 3 = 2 then m.top.tabRequest = "next" else m.focusIndex = m.focusIndex + 1 : renderFocus()
        return true
    else if key = "up" and m.focusIndex >= 3
        m.focusIndex = m.focusIndex - 3 : renderFocus() : return true
    else if key = "down" and m.focusIndex + 3 < count
        m.focusIndex = m.focusIndex + 3 : renderFocus() : return true
    else if key = "OK" and count > 0
        m.status.text = "Activating..."
        m.top.commandRequest = { action: "scene_activate", entity_id: m.items[m.focusIndex].entity_id }
        return true
    else if key = "back"
        m.top.tabRequest = "previous" : return true
    end if
    return false
end function

sub onKeyInput()
    onKeyEvent(m.top.keyInput, true)
end sub
