sub init()
    m.names = ["home", "calendar", "weather", "lights", "scenes", "climate"]
    m.cards = []
    for i = 0 to m.names.Count() - 1
        focus = m.top.CreateChild("Rectangle")
        focus.translation = [i * 92, 0]
        focus.width = 76
        focus.height = 76
        focus.color = "0xE5A84BFF"
        panel = m.top.CreateChild("Rectangle")
        panel.translation = [i * 92 + 5, 5]
        panel.width = 66
        panel.height = 66
        panel.color = "0x33271FFF"
        icon = m.top.CreateChild("Poster")
        icon.translation = [i * 92 + 17, 17]
        icon.width = 42
        icon.height = 42
        icon.loadDisplayMode = "scaleToFit"
        icon.uri = "pkg:/images/mdi/tab-" + m.names[i] + ".png"
        m.cards.Push({ focus: focus, panel: panel, icon: icon })
    end for
    renderTabs()
end sub

sub renderTabs()
    if m.cards = invalid then return
    for i = 0 to m.names.Count() - 1
        m.cards[i].focus.visible = m.names[i] = m.top.selected
    end for
end sub
