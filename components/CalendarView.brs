' CalendarView: the monthly overview tab.
sub init()
    m.top.focusable = true
    m.status = m.top.FindNode("status")
    m.monthTitle = m.top.FindNode("monthTitle")
    m.monthGrid = m.top.FindNode("monthGrid")
    m.empty = m.top.FindNode("empty")
    m.monthDayLabels = []
    m.monthData = invalid
    buildMonthGrid()
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

sub onMonthCalendar()
    value = m.top.monthCalendar
    if value = invalid
        m.monthData = invalid
        m.empty.visible = true
        return
    end if
    m.monthData = value
    m.empty.visible = false
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
        if day < 1 or day > daysInMonth
            label.text = ""
        else
            text = day.ToStr()
            if ArrayContainsNumber(eventDays, day) then text = text + "*"
            if day = today
                label.text = "[" + text + "]"
                label.color = "0xFFD080FF"
            else
                label.text = text
                label.color = "0xFFFFFFFF"
            end if
        end if
    end for
end sub

function ArrayContainsNumber(values as object, wanted as integer) as boolean
    for each value in values
        if value = wanted then return true
    end for
    return false
end function

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    m.top.activity = key
    if key = "left" or key = "back"
        m.top.tabRequest = "previous"
        return true
    else if key = "right"
        m.top.tabRequest = "next"
        return true
    end if
    return false
end function

sub onKeyInput()
    onKeyEvent(m.top.keyInput, true)
end sub
