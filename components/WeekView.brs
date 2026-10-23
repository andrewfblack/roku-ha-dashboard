' WeekView: the standalone rolling week calendar opened from Home.
sub init()
    m.top.focusable = true
    m.columnsGroup = m.top.FindNode("columns")
    m.status = m.top.FindNode("status")
    m.empty = m.top.FindNode("empty")
    m.detail = m.top.FindNode("detail")
    m.detailColor = m.top.FindNode("detailColor")
    m.detailTitle = m.top.FindNode("detailTitle")
    m.detailTime = m.top.FindNode("detailTime")
    m.detailCalendar = m.top.FindNode("detailCalendar")
    m.columns = []
    m.days = []
    m.dayIndex = 0
    m.dayOffset = 0
    m.eventIndex = 0
    m.detailOpen = false
    buildColumns()
end sub

sub buildColumns()
    for col = 0 to 6
        focus = m.columnsGroup.CreateChild("Rectangle")
        focus.color = "0xF2A24BFF"
        focus.visible = false
        panel = m.columnsGroup.CreateChild("Rectangle")
        header = m.columnsGroup.CreateChild("Rectangle")
        weekday = m.columnsGroup.CreateChild("Label")
        weekday.height = 42
        weekday.horizAlign = "center"
        weekday.font = "font:MediumSystemFont"
        dateLabel = m.columnsGroup.CreateChild("Label")
        dateLabel.height = 48
        dateLabel.horizAlign = "center"
        dateLabel.font = "font:MediumSystemFont"
        eventCards = []
        for row = 0 to 5
            eventFocus = m.columnsGroup.CreateChild("Rectangle")
            eventFocus.color = "0xF2A24BFF"
            eventFocus.visible = false
            card = m.columnsGroup.CreateChild("Rectangle")
            bar = m.columnsGroup.CreateChild("Rectangle")
            timeLabel = m.columnsGroup.CreateChild("Label")
            titleLabel = m.columnsGroup.CreateChild("Label")
            timeLabel.font = "font:SmallSystemFont"
            titleLabel.font = "font:MediumSystemFont"
            titleLabel.wrap = true
            titleLabel.maxLines = 2
            eventCards.Push({ card: card, bar: bar, focus: eventFocus, time: timeLabel, title: titleLabel })
        end for
        overflow = m.columnsGroup.CreateChild("Label")
        overflow.height = 38
        overflow.horizAlign = "center"
        overflow.color = "0xE0A85EFF"
        m.columns.Push({ focus: focus, panel: panel, header: header, weekday: weekday, date: dateLabel, events: eventCards, overflow: overflow })
    end for
end sub

sub onSchedule()
    data = m.top.schedule
    if data = invalid or data.days = invalid
        m.days = []
    else
        m.days = data.days
    end if
    if m.dayIndex >= m.days.Count() then m.dayIndex = 0
    m.dayOffset = 0
    m.eventIndex = 0
    RenderSchedule()
end sub

sub RenderSchedule()
    count = m.days.Count()
    m.empty.visible = count = 0
    if count = 0 then return
    visibleCount = count
    if visibleCount > 5 then visibleCount = 5
    if m.dayIndex < m.dayOffset then m.dayOffset = m.dayIndex
    if m.dayIndex >= m.dayOffset + visibleCount then m.dayOffset = m.dayIndex - visibleCount + 1
    if m.dayOffset + visibleCount > count then m.dayOffset = count - visibleCount
    if m.dayOffset < 0 then m.dayOffset = 0
    columnWidth = Int(1760 / visibleCount)
    for col = 0 to 6
        column = m.columns[col]
        visible = col < visibleCount
        SetColumnVisible(column, visible)
        if visible
            dayDataIndex = m.dayOffset + col
            x = col * columnWidth
            width = columnWidth - 12
            column.focus.translation = [x, 0]
            column.focus.width = width
            column.focus.height = 835
            column.focus.visible = col = m.dayIndex
            column.panel.translation = [x + 5, 5]
            column.panel.width = width - 10
            column.panel.height = 825
            day = m.days[dayDataIndex]
            if day.is_weekend then column.panel.color = "0x211A18EE" else column.panel.color = "0x17130FEE"
            column.header.translation = [x + 5, 5]
            column.header.width = width - 10
            column.header.height = 100
            if day.is_today then column.header.color = "0xC66B2DFF" else column.header.color = "0x3B3025FF"
            column.weekday.translation = [x + 12, 18]
            column.weekday.width = width - 24
            column.weekday.text = day.weekday
            column.date.translation = [x + 12, 57]
            column.date.width = width - 24
            column.date.text = day.month + " " + day.day.ToStr()

            events = day.events
            if events = invalid then events = []
            for row = 0 to 5
                eventCard = column.events[row]
                eventVisible = row < events.Count()
                SetEventVisible(eventCard, eventVisible)
                if eventVisible
                    y = 118 + row * 108
                    event = events[row]
                    eventCard.card.translation = [x + 13, y]
                    eventCard.card.width = width - 26
                    eventCard.card.height = 98
                    eventCard.card.color = "0x342A22FF"
                    eventCard.bar.translation = [x + 13, y]
                    eventCard.bar.width = 10
                    eventCard.bar.height = 98
                    eventCard.bar.color = EventColor(event.color, "FF")
                    eventCard.focus.translation = [x + 9, y - 4]
                    eventCard.focus.width = width - 18
                    eventCard.focus.height = 106
                    eventCard.focus.color = "0xFFF0D5FF"
                    eventCard.focus.visible = dayDataIndex = m.dayIndex and row = m.eventIndex
                    eventCard.time.translation = [x + 32, y + 8]
                    eventCard.time.width = width - 52
                    eventCard.time.height = 32
                    eventCard.time.text = EventTime(event)
                    eventCard.time.color = EventColor(event.color, "FF")
                    eventCard.title.translation = [x + 32, y + 40]
                    eventCard.title.width = width - 52
                    eventCard.title.height = 52
                    eventCard.title.text = event.title
                end if
            end for
            column.overflow.translation = [x + 12, 777]
            column.overflow.width = width - 24
            if day.overflow > 0 then column.overflow.text = "+" + day.overflow.ToStr() + " more" else column.overflow.text = ""
        end if
    end for
    selected = m.days[m.dayIndex]
    m.status.text = selected.weekday + " " + selected.month + " " + selected.day.ToStr()
end sub

sub SetColumnVisible(column as object, visible as boolean)
    column.panel.visible = visible
    column.header.visible = visible
    column.weekday.visible = visible
    column.date.visible = visible
    column.overflow.visible = visible
    if not visible then column.focus.visible = false
    for each eventCard in column.events
        if not visible then SetEventVisible(eventCard, false)
    end for
end sub

sub SetEventVisible(card as object, visible as boolean)
    card.card.visible = visible
    card.bar.visible = visible
    card.time.visible = visible
    card.title.visible = visible
    if not visible then card.focus.visible = false
end sub

function EventColor(value as dynamic, alpha as string) as string
    if value = invalid then return "0xE5A84B" + alpha
    color = value.ToStr().Replace("#", "")
    if Len(color) <> 6 then color = "E5A84B"
    return "0x" + color + alpha
end function

function EventTime(event as object) as string
    if event.all_day = true then return "ALL DAY"
    value = event.start.ToStr()
    if Len(value) >= 16 then return Mid(value, 12, 5)
    return ""
end function

sub OpenDetail()
    day = m.days[m.dayIndex]
    events = day.events
    if events = invalid or events.Count() = 0 or m.eventIndex >= events.Count() then return
    event = events[m.eventIndex]
    m.detailTitle.text = event.title
    m.detailTime.text = day.weekday + " " + day.month + " " + day.day.ToStr() + "   " + EventTime(event)
    m.detailCalendar.text = event.calendar_name
    m.detailColor.color = EventColor(event.color, "FF")
    m.detail.visible = true
    m.detailOpen = true
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    m.top.activity = key
    if m.detailOpen
        if key = "back" or key = "left" or key = "OK"
            m.detail.visible = false
            m.detailOpen = false
        end if
        return true
    end if
    count = m.days.Count()
    if key = "left"
        if m.dayIndex = 0 then m.top.tabRequest = "home" else m.dayIndex = m.dayIndex - 1 : m.eventIndex = 0 : RenderSchedule()
        return true
    else if key = "right"
        if count = 0 or m.dayIndex + 1 >= count then m.top.tabRequest = "next" else m.dayIndex = m.dayIndex + 1 : m.eventIndex = 0 : RenderSchedule()
        return true
    else if key = "up" and m.eventIndex > 0
        m.eventIndex = m.eventIndex - 1 : RenderSchedule() : return true
    else if key = "down" and count > 0
        events = m.days[m.dayIndex].events
        if events <> invalid and m.eventIndex + 1 < events.Count() then m.eventIndex = m.eventIndex + 1 : RenderSchedule()
        return true
    else if key = "OK"
        OpenDetail() : return true
    else if key = "back"
        m.top.tabRequest = "home" : return true
    end if
    return false
end function

sub onKeyInput()
    onKeyEvent(m.top.keyInput, true)
end sub
