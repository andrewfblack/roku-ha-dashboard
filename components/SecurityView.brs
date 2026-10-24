sub init()
    m.top.focusable = true
    m.controlsGroup = m.top.FindNode("controls")
    m.familyGroup = m.top.FindNode("family")
    m.status = m.top.FindNode("status")
    m.empty = m.top.FindNode("empty")
    m.controls = []
    m.family = []
    m.items = []
    m.familyItems = []
    m.focusIndex = 0
    buildControlCards()
    buildFamilyRows()
end sub

sub buildControlCards()
    for i = 0 to 6
        col = i MOD 2
        row = Int(i / 2)
        x = col * 500
        y = row * 175
        focus = m.controlsGroup.CreateChild("Rectangle")
        focus.translation = [x, y]
        focus.width = 480
        focus.height = 150
        focus.color = "0xF2A24BFF"
        focus.visible = false
        panel = m.controlsGroup.CreateChild("Rectangle")
        panel.translation = [x + 6, y + 6]
        panel.width = 468
        panel.height = 138
        panel.color = "0x382A22FF"
        icon = m.controlsGroup.CreateChild("Poster")
        icon.translation = [x + 22, y + 35]
        icon.width = 72
        icon.height = 72
        icon.loadDisplayMode = "scaleToFit"
        name = m.controlsGroup.CreateChild("Label")
        name.translation = [x + 115, y + 24]
        name.width = 330
        name.height = 48
        name.font = "font:MediumSystemFont"
        state = m.controlsGroup.CreateChild("Label")
        state.translation = [x + 115, y + 78]
        state.width = 330
        state.height = 42
        state.color = "0xC0B49CFF"
        m.controls.Push({ focus: focus, panel: panel, icon: icon, name: name, state: state, item: invalid })
    end for
end sub

sub buildFamilyRows()
    for i = 0 to 7
        row = m.familyGroup.CreateChild("Label")
        row.translation = [0, i * 78]
        row.width = 550
        row.height = 58
        row.font = "font:MediumSystemFont"
        m.family.Push(row)
    end for
end sub

sub onData()
    data = m.top.data
    if data = invalid then data = {}
    m.items = []
    covers = data.garage_doors
    if covers <> invalid then
        for each item in covers
            item.kind = "cover"
            m.items.Push(item)
        end for
    end if
    locks = data.locks
    if locks <> invalid then
        for each item in locks
            item.kind = "lock"
            m.items.Push(item)
        end for
    end if
    if data.alarm <> invalid
        alarm = data.alarm
        alarm.kind = "alarm"
        m.items.Push(alarm)
    end if
    m.familyItems = data.family
    if m.familyItems = invalid then m.familyItems = []
    if m.focusIndex >= m.items.Count() then m.focusIndex = 0
    render()
end sub

sub render()
    m.empty.visible = m.items.Count() = 0 and m.familyItems.Count() = 0
    for i = 0 to m.controls.Count() - 1
        card = m.controls[i]
        visible = i < m.items.Count()
        card.panel.visible = visible
        card.icon.visible = visible
        card.name.visible = visible
        card.state.visible = visible
        card.focus.visible = visible and i = m.focusIndex
        if visible
            item = m.items[i]
            card.item = item
            card.name.text = item.name
            card.state.text = SecurityState(item)
            card.icon.uri = SecurityIcon(item.kind)
        end if
    end for
    for i = 0 to m.family.Count() - 1
        visible = i < m.familyItems.Count()
        m.family[i].visible = visible
        if visible
            person = m.familyItems[i]
            if person.home = true then m.family[i].text = "●  " + person.name + "    HOME" else m.family[i].text = "○  " + person.name + "    AWAY"
        end if
    end for
end sub

function SecurityState(item as object) as string
    state = LCase(item.state.ToStr())
    if item.kind = "cover"
        if state = "open" then return "OPEN" else return UCase(state)
    else if item.kind = "lock"
        if state = "locked" then return "LOCKED" else return UCase(state)
    end if
    return UCase(state.Replace("_", " "))
end function

function SecurityIcon(kind as string) as string
    if kind = "cover" then return "pkg:/images/mdi/garage.png"
    if kind = "lock" then return "pkg:/images/mdi/lock.png"
    return "pkg:/images/mdi/shield-home.png"
end function

sub renderFocus()
    for i = 0 to m.controls.Count() - 1
        m.controls[i].focus.visible = i < m.items.Count() and i = m.focusIndex
    end for
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
    else if key = "up" and m.focusIndex >= 2
        m.focusIndex = m.focusIndex - 2 : renderFocus() : return true
    else if key = "down" and m.focusIndex + 2 < count
        m.focusIndex = m.focusIndex + 2 : renderFocus() : return true
    else if key = "OK" and count > 0
        item = m.items[m.focusIndex]
        if item.kind = "cover" then action = "security_cover_toggle" else if item.kind = "lock" then action = "security_lock_toggle" else action = "security_alarm_command"
        request = { action: action, entity_id: item.entity_id }
        if item.kind = "alarm"
            state = LCase(item.state.ToStr())
            if state = "disarmed" then request.command = "alarm_arm_home" else request.command = "alarm_disarm"
        end if
        m.top.commandRequest = request
        m.status.text = "Sending..."
        return true
    else if key = "back"
        return true
    end if
    return false
end function

sub onCommandResult()
    result = m.top.commandResult
    if result <> invalid then if result.ok then m.status.text = "Updated" else m.status.text = "Command failed"
end sub

sub onKeyInput()
    onKeyEvent(m.top.keyInput, true)
end sub
