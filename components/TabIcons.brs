sub init()
    m.names = ["home", "calendar", "weather", "lights", "scenes", "climate"]
    m.cards = []
    for i = 0 to m.names.Count() - 1
        focus = m.top.CreateChild("Rectangle")
        focus.translation = [i * 102, 0]
        focus.width = 90
        focus.height = 82
        focus.color = "0xE5A84BFF"
        panel = m.top.CreateChild("Rectangle")
        panel.translation = [i * 102 + 5, 5]
        panel.width = 80
        panel.height = 72
        panel.color = "0x211A16FF"
        icon = m.top.CreateChild("Poster")
        icon.translation = [i * 102 + 22, 15]
        icon.width = 46
        icon.height = 46
        icon.loadDisplayMode = "scaleToFit"
        icon.uri = "pkg:/images/mdi/tab-" + m.names[i] + ".png"
        label = m.top.CreateChild("Label")
        label.translation = [i * 102 + 5, 58]
        label.width = 80
        label.height = 25
        label.horizAlign = "center"
        label.font = "font:SmallSystemFont"
        label.text = UCase(m.names[i])
        label.color = "0xD8CBB9FF"
        label.visible = false
        m.cards.Push({ focus: focus, panel: panel, icon: icon, label: label })
    end for
    renderTabs()
end sub

sub renderTabs()
    if m.cards = invalid then return
    for i = 0 to m.names.Count() - 1
        selected = m.names[i] = m.top.selected
        focused = m.top.focusTab <> invalid and m.top.focusTab <> "" and m.names[i] = m.top.focusTab
        m.cards[i].focus.visible = focused or (not focused and selected)
        if selected then m.cards[i].label.color = "0xFFF4D6FF" else m.cards[i].label.color = "0xD8CBB9FF"
    end for
end sub
