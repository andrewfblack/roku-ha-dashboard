' CalendarView: the interactive monthly overview tab.
sub init()
    m.top.focusable = true
    m.status = m.top.FindNode("status")
    m.monthTitle = m.top.FindNode("monthTitle")
    m.monthGrid = m.top.FindNode("monthGrid")
    m.empty = m.top.FindNode("empty")
    m.calendarHint = m.top.FindNode("calendarHint")
    m.monthFocus = m.top.FindNode("monthFocus")
    m.monthDayLabels = []
    m.eventCircles = []
    m.todayOuter = []
    m.todayInner = []
    m.focusCircles = []
    m.monthData = invalid
    m.calendarFocused = false
    m.selectedIndex = 0
    m.eventColor = "0xE5A84B99"
    m.todayColor = "0xFFD080FF"
    m.focusColor = "0xFFF0D5FF"

    m.dayPopup = m.top.FindNode("dayPopup")
    m.popupTitle = m.top.FindNode("popupTitle")
    m.popupRowsGroup = m.top.FindNode("popupRows")
    m.popupEmpty = m.top.FindNode("popupEmpty")
    m.popupRows = []
    m.popupOpen = false
    buildPopupRows()
    buildMonthGrid()
end sub

sub buildPopupRows()
    for i = 0 to 5
        y = i * 62
        timeLabel = m.popupRowsGroup.CreateChild("Label")
        timeLabel.translation = [0, y]
        timeLabel.width = 230
        timeLabel.height = 48
        titleLabel = m.popupRowsGroup.CreateChild("Label")
        titleLabel.translation = [260, y]
        titleLabel.width = 900
        titleLabel.height = 48
        m.popupRows.Push({ time: timeLabel, title: titleLabel })
    end for
end sub

sub buildMonthGrid()
    weekdays = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
    cellWidth = 222
    for col = 0 to 6
        label = m.monthGrid.CreateChild("Label")
        label.text = weekdays[col]
        label.width = 218
        label.height = 40
        label.horizAlign = "center"
        label.font = "font:MediumSystemFont"
        label.color = "0xC0B49CFF"
        label.translation = [col * cellWidth, 0]
    end for

    for index = 0 to 41
        x = (index MOD 7) * cellWidth + 73
        y = 52 + Int(index / 7) * 96 + 6

        eventCircle = m.monthGrid.CreateChild("Poster")
        eventCircle.width = 72
        eventCircle.height = 72
        eventCircle.loadDisplayMode = "scaleToFit"
        eventCircle.uri = "pkg:/images/calendar/event-circle.png"
        eventCircle.translation = [x, y]
        eventCircle.visible = false
        eventCircle.color = m.eventColor
        eventCircle.blendColor = m.eventColor
        m.eventCircles.Push(eventCircle)

        todayOuter = m.monthGrid.CreateChild("Poster")
        todayOuter.width = 82
        todayOuter.height = 82
        todayOuter.loadDisplayMode = "scaleToFit"
        todayOuter.uri = "pkg:/images/calendar/today-ring.png"
        todayOuter.translation = [x - 5, y - 5]
        todayOuter.visible = false
        todayOuter.color = m.todayColor
        todayOuter.blendColor = m.todayColor
        m.todayOuter.Push(todayOuter)

        focusCircle = m.monthGrid.CreateChild("Poster")
        focusCircle.width = 92
        focusCircle.height = 92
        focusCircle.loadDisplayMode = "scaleToFit"
        focusCircle.uri = "pkg:/images/calendar/today-ring.png"
        focusCircle.translation = [x - 10, y - 10]
        focusCircle.visible = false
        focusCircle.color = m.focusColor
        focusCircle.blendColor = m.focusColor
        m.focusCircles.Push(focusCircle)

        label = m.monthGrid.CreateChild("Label")
        label.text = ""
        label.width = 218
        label.height = 84
        label.horizAlign = "center"
        label.vertAlign = "center"
        label.font = "font:LargeSystemFont"
        label.translation = [(index MOD 7) * cellWidth, 52 + Int(index / 7) * 96]
        m.monthDayLabels.Push(label)
    end for
end sub

sub onThemeData()
    theme = m.top.themeData
    if theme = invalid then return
    if theme.item_header_text <> invalid then m.eventColor = ThemeColor(theme.item_header_text, 72)
    if theme.selected_border <> invalid then m.todayColor = ThemeColor(theme.selected_border, 100) : m.focusColor = ThemeColor(theme.selected_border, 100)
    m.monthFocus.color = m.focusColor
    for each circle in m.eventCircles
        circle.blendColor = m.eventColor
    end for
    for each circle in m.todayOuter
        circle.blendColor = m.todayColor
    end for
    for each circle in m.focusCircles
        circle.blendColor = m.focusColor
    end for
end sub

function ThemeColor(value as dynamic, opacity as integer) as string
    color = "E5A84B"
    if value <> invalid
        color = UCase(value.ToStr().Replace("#", ""))
        if Len(color) <> 6 then color = "E5A84B"
    end if
    alpha = Int(opacity * 255 / 100)
    if alpha < 0 then alpha = 0
    if alpha > 255 then alpha = 255
    return "0x" + color + ByteToHex(alpha)
end function

function ByteToHex(value as integer) as string
    digits = "0123456789ABCDEF"
    return Mid(digits, Int(value / 16) + 1, 1) + Mid(digits, (value MOD 16) + 1, 1)
end function

sub onMonthCalendar()
    value = m.top.monthCalendar
    if value = invalid
        m.monthData = invalid
        m.empty.visible = true
        return
    end if
    m.monthData = value
    m.empty.visible = false
    m.calendarFocused = false
    m.selectedIndex = value.first_weekday + value.today - 1
    RenderMonth()
end sub

sub RenderMonth()
    month = m.monthData
    if month = invalid then return
    title = "MONTH"
    if month.title <> invalid then title = month.title.ToStr()
    m.monthTitle.text = UCase(title)
    firstWeekday = month.first_weekday
    daysInMonth = month.days_in_month
    today = month.today
    eventDays = month.event_days
    if eventDays = invalid then eventDays = []

    for index = 0 to 41
        label = m.monthDayLabels[index]
        day = index - firstWeekday + 1
        valid = day >= 1 and day <= daysInMonth
        label.visible = valid
        hasEvents = valid and ArrayContainsNumber(eventDays, day)
        m.eventCircles[index].visible = hasEvents
        m.todayOuter[index].visible = valid and day = today
        m.focusCircles[index].visible = valid and m.calendarFocused and index = m.selectedIndex
        if valid
            text = day.ToStr()
            label.text = text
            if day = today then label.color = m.todayColor else label.color = "0xFFFFFFFF"
        else
            label.text = ""
        end if
    end for
    m.monthFocus.visible = m.calendarFocused
    m.status.text = "DOWN: select calendar"
    if m.calendarFocused then m.status.text = "Selected day " + SelectedDayText()
end sub

function ArrayContainsNumber(values as object, wanted as integer) as boolean
    for each value in values
        if value = wanted then return true
    end for
    return false
end function

function SelectedDayText() as string
    if m.monthData = invalid then return ""
    day = m.selectedIndex - m.monthData.first_weekday + 1
    return m.monthData.month.ToStr() + "/" + day.ToStr()
end function

function SelectedDay() as integer
    return m.selectedIndex - m.monthData.first_weekday + 1
end function

function MoveSelection(delta as integer) as boolean
    if m.monthData = invalid then return false
    candidate = m.selectedIndex + delta
    first = m.monthData.first_weekday
    last = first + m.monthData.days_in_month - 1
    if candidate < first or candidate > last then return false
    m.selectedIndex = candidate
    RenderMonth()
    return true
end function

sub OpenDayPopup()
    if m.monthData = invalid then return
    day = SelectedDay()
    dateKey = m.monthData.year.ToStr() + "-" + TwoDigits(m.monthData.month) + "-" + TwoDigits(day)
    m.popupTitle.text = "EVENTS — " + SelectedDayText()
    count = 0
    events = m.monthData.events
    if events = invalid then events = []
    for each row in m.popupRows
        row.time.visible = false
        row.title.visible = false
    end for
    for each event in events
        if Left(event.start.ToStr(), 10) = dateKey and count < m.popupRows.Count()
            row = m.popupRows[count]
            row.time.visible = true
            row.title.visible = true
            row.time.text = PopupEventTime(event)
            row.title.text = event.title
            count = count + 1
        end if
    end for
    m.popupEmpty.visible = count = 0
    m.dayPopup.visible = true
    m.popupOpen = true
end sub

function PopupEventTime(event as object) as string
    if event.all_day = true then return "ALL DAY"
    value = event.start.ToStr()
    if Len(value) < 16 then return ""
    hour = Val(Mid(value, 12, 2))
    minute = Mid(value, 15, 2)
    suffix = "AM"
    if hour >= 12 then suffix = "PM" : hour = hour - 12
    if hour = 0 then hour = 12
    return hour.ToStr() + ":" + minute + " " + suffix
end function

function TwoDigits(value as integer) as string
    if value < 10 then return "0" + value.ToStr()
    return value.ToStr()
end function

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    m.top.activity = key
    if m.popupOpen
        if key = "back" or key = "OK" or key = "left"
            m.dayPopup.visible = false
            m.popupOpen = false
        end if
        return true
    end if
    if not m.calendarFocused
        if key = "down" or key = "OK"
            m.calendarFocused = true
            RenderMonth()
            return true
        else if key = "left" or key = "back"
            m.top.tabRequest = "previous"
            return true
        else if key = "right"
            m.top.tabRequest = "next"
            return true
        end if
        return false
    end if
    if key = "up"
        if not MoveSelection(-7) then m.calendarFocused = false : RenderMonth()
        return true
    else if key = "down"
        MoveSelection(7)
        return true
    else if key = "left"
        if not MoveSelection(-1) then m.top.tabRequest = "previous"
        return true
    else if key = "right"
        if not MoveSelection(1) then m.top.tabRequest = "next"
        return true
    else if key = "OK"
        OpenDayPopup()
        return true
    else if key = "back"
        m.calendarFocused = false
        RenderMonth()
        return true
    end if
    return false
end function

sub onKeyInput()
    onKeyEvent(m.top.keyInput, true)
end sub
