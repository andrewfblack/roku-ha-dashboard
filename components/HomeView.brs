' HomeView: the "Home" tab.
' Renders today's calendar events, the meal plan sensor and the
' inside/outside climate readout from Home Assistant data.
sub init()
    m.top.focusable = true
    m.states = {}
    m.resolvedEntities = {}
    m.events = []
    m.focusIndex = 0

    m.rowTimes = []
    m.rowTitles = []
    for i = 0 to 4
        m.rowTimes.Push(m.top.FindNode("row" + i.ToStr() + "Time"))
        m.rowTitles.Push(m.top.FindNode("row" + i.ToStr() + "Title"))
    end for
    m.calendarEmpty = m.top.FindNode("calendarEmpty")
    m.mealContent = m.top.FindNode("mealContent")
    m.insideValue = m.top.FindNode("insideValue")
    m.insideName = m.top.FindNode("insideName")
    m.insideDetail = m.top.FindNode("insideDetail")
    m.outsideValue = m.top.FindNode("outsideValue")
    m.outsideIcon = m.top.FindNode("outsideIcon")
    m.outsideName = m.top.FindNode("outsideName")
    m.outsideCondition = m.top.FindNode("outsideCondition")
    m.outsideDetail = m.top.FindNode("outsideDetail")
    m.statusLabel = m.top.FindNode("statusLabel")
    m.dateLabel = m.top.FindNode("dateLabel")
    m.titleLabel = m.top.FindNode("titleLabel")
    m.monthTitle = m.top.FindNode("monthTitle")
    m.monthGrid = m.top.FindNode("monthGrid")
    m.monthDayLabels = []
    buildMonthGrid()
    m.monthAgenda = m.top.FindNode("monthAgenda")
    m.agendaTitle = m.top.FindNode("agendaTitle")
    m.agendaCount = m.top.FindNode("agendaCount")
    m.agendaRowsGroup = m.top.FindNode("agendaRows")
    m.agendaRows = []
    m.monthEvents = []
    m.todayEvents = []
    m.agendaEvents = []
    m.agendaIndex = 0
    m.agendaOffset = 0
    m.agendaOpen = false
    buildAgendaRows()
    m.weeklyMeals = m.top.FindNode("weeklyMeals")
    m.mealRowsGroup = m.top.FindNode("mealRows")
    m.mealRows = []
    m.weeklyMealData = []
    m.mealsOpen = false
    m.mealIndex = 0
    buildMealRows()

    m.rings = [
        m.top.FindNode("calendarRing")
        m.top.FindNode("mealRing")
        m.top.FindNode("climateRing")
    ]

    m.dateLabel.text = TodayLabel()
    m.mealContent.text = "Waiting for Home Assistant..."
    m.top.SetFocus(true)
end sub

' ---------------- Field observers ----------------

sub onStates()
    m.states = m.top.states
    if m.states = invalid then m.states = {}
    UpdateClimate()
end sub

sub onResolvedEntities()
    m.resolvedEntities = m.top.resolvedEntities
    if m.resolvedEntities = invalid then m.resolvedEntities = {}
    UpdateClimate()
end sub

sub onCalendarEvents()
    m.events = m.top.calendarEvents
    if m.events = invalid then m.events = []
    RenderCalendar()
end sub

sub onTodayEvents()
    m.todayEvents = m.top.todayEvents
    if m.todayEvents = invalid then m.todayEvents = []
end sub

sub onMonthCalendar()
    value = m.top.monthCalendar
    if value <> invalid
        if value.events <> invalid then m.monthEvents = value.events else m.monthEvents = []
        RenderMonth(value)
        if m.agendaOpen then RenderAgenda()
    end if
end sub

sub onMealPlan()
    meal = m.top.mealPlan
    if meal = invalid or meal = "" or meal = "unknown" or meal = "unavailable"
        m.mealContent.text = "No meal plan set." + Chr(10) + "Update your meal plan sensor in Home Assistant."
    else
        m.mealContent.text = meal
    end if
end sub

sub onWeeklyMealPlan()
    m.weeklyMealData = m.top.weeklyMealPlan
    if m.weeklyMealData = invalid then m.weeklyMealData = []
    if m.mealsOpen then RenderMealRows()
end sub

sub onDashboardTitle()
    title = m.top.dashboardTitle
    if title = invalid or title = "" then title = "Family Dashboard"
    m.titleLabel.text = UCase(title)
end sub

sub onConnectionStatus()
    status = m.top.connectionStatus
    if status = "connected"
        m.statusLabel.text = ""
    else if status = "reconnecting"
        m.statusLabel.text = "Reconnecting to Home Assistant..."
    else
        m.statusLabel.text = ""
    end if
end sub

' ---------------- Rendering ----------------

sub RenderCalendar()
    count = m.events.Count()
    for i = 0 to 4
        visible = i < count and i < 3
        m.rowTimes[i].visible = visible
        m.rowTitles[i].visible = visible
        if visible
            ev = m.events[i]
            m.rowTimes[i].text = ev.timeLabel
            m.rowTitles[i].text = ev.title
        end if
    end for
    m.calendarEmpty.visible = (count = 0)
end sub

sub buildMonthGrid()
    weekdays = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
    cellWidth = 117
    for col = 0 to 6
        label = m.monthGrid.CreateChild("Label")
        label.text = weekdays[col]
        label.width = 112
        label.height = 34
        label.horizAlign = "center"
        label.color = "0xC0B49CFF"
        label.translation = [col * cellWidth, 0]
    end for

    for index = 0 to 41
        label = m.monthGrid.CreateChild("Label")
        label.text = ""
        label.width = 112
        label.height = 42
        label.horizAlign = "center"
        label.translation = [(index MOD 7) * cellWidth, 42 + Int(index / 7) * 52]
        m.monthDayLabels.Push(label)
    end for
end sub

sub RenderMonth(month as object)
    if month.title <> invalid then m.monthTitle.text = month.title.ToStr()
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

sub buildAgendaRows()
    for i = 0 to 7
        y = i * 82
        focus = m.agendaRowsGroup.CreateChild("Rectangle")
        focus.translation = [0, y]
        focus.width = 1580
        focus.height = 72
        focus.color = "0xD78335FF"
        focus.visible = false
        panel = m.agendaRowsGroup.CreateChild("Rectangle")
        panel.translation = [6, y + 6]
        panel.width = 1568
        panel.height = 60
        if i MOD 2 = 0 then panel.color = "0x382A1DFF" else panel.color = "0x2B2118FF"
        dateLabel = m.agendaRowsGroup.CreateChild("Label")
        dateLabel.translation = [24, y + 14]
        dateLabel.width = 330
        dateLabel.height = 48
        titleLabel = m.agendaRowsGroup.CreateChild("Label")
        titleLabel.translation = [370, y + 14]
        titleLabel.width = 1170
        titleLabel.height = 48
        m.agendaRows.Push({ focus: focus, panel: panel, date: dateLabel, title: titleLabel })
    end for
end sub

sub OpenAgenda()
    m.agendaEvents = m.todayEvents
    m.agendaOpen = true
    m.agendaIndex = 0
    m.agendaOffset = 0
    m.monthAgenda.visible = true
    RenderAgenda()
end sub

sub CloseAgenda()
    m.agendaOpen = false
    m.monthAgenda.visible = false
end sub

sub RenderAgenda()
    m.agendaCount.text = m.agendaEvents.Count().ToStr() + " events"
    m.agendaTitle.text = "TODAY'S EVENTS"
    for rowIndex = 0 to 7
        eventIndex = m.agendaOffset + rowIndex
        row = m.agendaRows[rowIndex]
        visible = eventIndex < m.agendaEvents.Count()
        row.focus.visible = visible and eventIndex = m.agendaIndex
        row.panel.visible = visible
        row.date.visible = visible
        row.title.visible = visible
        if visible
            event = m.agendaEvents[eventIndex]
            row.date.text = AgendaDate(event.start, event.all_day)
            row.title.text = event.title
        end if
    end for
end sub

function AgendaDate(startValue as dynamic, allDayValue as dynamic) as string
    value = startValue.ToStr()
    if Len(value) < 10 then return value
    result = Mid(value, 6, 2) + "/" + Mid(value, 9, 2)
    if allDayValue = true then return result + "  All day"
    if Len(value) >= 16 then result = result + "  " + Mid(value, 12, 5)
    return result
end function

function HandleAgendaKey(key as string) as boolean
    count = m.agendaEvents.Count()
    if key = "back" or key = "left"
        CloseAgenda()
    else if key = "up" and m.agendaIndex > 0
        m.agendaIndex = m.agendaIndex - 1
        if m.agendaIndex < m.agendaOffset then m.agendaOffset = m.agendaIndex
        RenderAgenda()
    else if key = "down" and m.agendaIndex + 1 < count
        m.agendaIndex = m.agendaIndex + 1
        if m.agendaIndex >= m.agendaOffset + 8 then m.agendaOffset = m.agendaIndex - 7
        RenderAgenda()
    end if
    return true
end function

sub buildMealRows()
    for i = 0 to 6
        y = i * 82
        focus = m.mealRowsGroup.CreateChild("Rectangle")
        focus.translation = [-5, y - 5]
        focus.width = 1190
        focus.height = 80
        focus.color = "0xE5A84BFF"
        focus.visible = false
        panel = m.mealRowsGroup.CreateChild("Rectangle")
        panel.translation = [0, y]
        panel.width = 1180
        panel.height = 70
        if i MOD 2 = 0 then panel.color = "0x382A1DFF" else panel.color = "0x2B2118FF"
        dayLabel = m.mealRowsGroup.CreateChild("Label")
        dayLabel.translation = [25, y + 12]
        dayLabel.width = 250
        dayLabel.height = 48
        mealLabel = m.mealRowsGroup.CreateChild("Label")
        mealLabel.translation = [300, y + 12]
        mealLabel.width = 840
        mealLabel.height = 48
        m.mealRows.Push({ focus: focus, panel: panel, day: dayLabel, meal: mealLabel })
    end for
end sub

sub OpenMeals()
    m.mealsOpen = true
    m.mealIndex = 0
    m.weeklyMeals.visible = true
    RenderMealRows()
end sub

sub CloseMeals()
    m.mealsOpen = false
    m.weeklyMeals.visible = false
end sub

sub RenderMealRows()
    for i = 0 to 6
        row = m.mealRows[i]
        row.focus.visible = m.mealsOpen and i = m.mealIndex
        if i < m.weeklyMealData.Count()
            item = m.weeklyMealData[i]
            row.day.text = item.day
            if item.is_today = true then row.day.text = "> " + UCase(item.day)
            meal = item.meal
            if meal = invalid or meal = "" then meal = "No meal planned"
            row.meal.text = meal
        else
            row.day.text = ""
            row.meal.text = ""
        end if
    end for
end sub

function HandleMealKey(key as string) as boolean
    if key = "back" or key = "left"
        CloseMeals()
    else if key = "up" and m.mealIndex > 0
        m.mealIndex = m.mealIndex - 1
        RenderMealRows()
    else if key = "down" and m.mealIndex < 6
        m.mealIndex = m.mealIndex + 1
        RenderMealRows()
    else if key = "OK"
        OpenMealKeyboard()
    end if
    return true
end function

sub OpenMealKeyboard()
    if m.mealIndex >= m.weeklyMealData.Count() then return
    item = m.weeklyMealData[m.mealIndex]
    dialog = CreateObject("roSGNode", "KeyboardDialog")
    dialog.title = "Meal for " + item.day
    if item.meal <> invalid then dialog.text = item.meal
    dialog.buttons = ["SAVE", "CANCEL"]
    dialog.ObserveField("buttonSelected", "onMealKeyboardButton")
    m.mealDialog = dialog
    m.top.GetScene().dialog = dialog
    dialog.SetFocus(true)
end sub

sub onMealKeyboardButton()
    dialog = m.mealDialog
    if dialog = invalid then return
    if dialog.buttonSelected = 0
        values = []
        for i = 0 to 6
            value = ""
            if i < m.weeklyMealData.Count() and m.weeklyMealData[i].meal <> invalid
                value = m.weeklyMealData[i].meal.ToStr()
            end if
            if i = m.mealIndex then value = dialog.text.Trim()
            values.Push(value)
        end for
        m.top.commandRequest = { action: "meal_week", value: values }
    end if
    dialog.close = true
    m.mealDialog = invalid
    m.top.GetScene().SetFocus(true)
end sub

sub onCommandResult()
    result = m.top.commandResult
    if result <> invalid and result.ok then m.mealContent.text = "Meal plan updated"
end sub

sub UpdateClimate()
    ' --- Inside ---
    insideId = FieldOrBlank(m.resolvedEntities, "inside")
    st = StateFor(insideId)
    if st <> invalid
        value = ""
        if Left(insideId, 7) = "climate." and st.attributes <> invalid and st.attributes.current_temperature <> invalid
            value = st.attributes.current_temperature.ToStr()
        else
            value = st.state.ToStr()
        end if
        m.insideValue.text = CleanTemperature(value)
        m.insideName.text = "Inside"
        detail = ""
        humidityId = FieldOrBlank(m.resolvedEntities, "inside_humidity")
        humidityState = StateFor(humidityId)
        if humidityState <> invalid and humidityState.state <> invalid
            detail = humidityState.state.ToStr() + "% humidity"
        else if st.attributes <> invalid and st.attributes.humidity <> invalid
            detail = st.attributes.humidity.ToStr() + "% humidity"
        end if
        m.insideDetail.text = detail
    else
        m.insideValue.text = "--"
        m.insideName.text = "Inside"
        m.insideDetail.text = "No temperature entity found"
    end if

    ' --- Outside ---
    outsideId = FieldOrBlank(m.resolvedEntities, "outside")
    st = StateFor(outsideId)
    if st <> invalid
        temp = ""
        if st.attributes <> invalid and st.attributes.temperature <> invalid
            temp = st.attributes.temperature.ToStr()
        end if
        m.outsideValue.text = CleanTemperature(temp)
        m.outsideIcon.uri = WeatherIconUri(st.state.ToStr())
        m.outsideName.text = "Outside"
        m.outsideCondition.text = TitleCase(st.state.ToStr())
        detail = ""
        if st.attributes <> invalid and st.attributes.humidity <> invalid
            detail = st.attributes.humidity.ToStr() + "% humidity"
        end if
        m.outsideDetail.text = detail
    else
        m.outsideValue.text = "--"
        m.outsideIcon.uri = "pkg:/images/weather/unknown.png"
        m.outsideName.text = "Outside"
        m.outsideCondition.text = "Unknown"
        m.outsideDetail.text = "No weather entity found"
    end if
end sub

function StateFor(entityId as string) as dynamic
    if entityId = "" then return invalid
    if m.states.DoesExist(entityId) then return m.states[entityId]
    return invalid
end function

function FieldOrBlank(aa as dynamic, key as string) as string
    if aa = invalid then return ""
    value = aa[key]
    if value = invalid then return ""
    return value.ToStr()
end function

function FriendlyName(entityId as string, st as object) as string
    if st.attributes <> invalid and st.attributes.friendly_name <> invalid
        return st.attributes.friendly_name.ToStr()
    end if
    return ""
end function

function CleanTemperature(value as string) as string
    if value = "" or value = "unknown" or value = "unavailable" then return "--"
    ' Drop a trailing "0" in whole numbers coming from floats (e.g. "21.0")
    if Len(value) > 2 and Right(value, 2) = ".0"
        value = Left(value, Len(value) - 2)
    end if
    return value + Chr(176)
end function

function TitleCase(s as string) as string
    if s = "" then return ""
    ' HA weather states run together words: "partlycloudy", "clear-night"
    specials = {
        "partlycloudy": "Partly Cloudy"
        "clear-night": "Clear Night"
        "lightning-rainy": "Thunderstorms"
        "snowy-rainy": "Wintry Mix"
        "windy-variant": "Windy, Clouds"
    }
    key = LCase(s)
    if specials.DoesExist(key) then return specials[key]
    out = s.Replace("-", " ").Replace("_", " ")
    ' capitalize each word
    result = ""
    word = ""
    for i = 1 to Len(out) + 1
        c = Mid(out, i, 1)
        if c = " " or i > Len(out)
            if word <> ""
                if result <> "" then result = result + " "
                result = result + UCase(Left(word, 1))
                if Len(word) > 1 then result = result + LCase(Mid(word, 2))
                word = ""
            end if
        else
            word = word + c
        end if
    end for
    return result
end function

function WeatherIconUri(condition as string) as string
    key = LCase(condition)
    supported = {
        "sunny": true
        "clear-night": true
        "cloudy": true
        "partlycloudy": true
        "rainy": true
        "pouring": true
        "lightning": true
        "lightning-rainy": true
        "snowy": true
        "snowy-rainy": true
        "fog": true
        "windy": true
        "windy-variant": true
        "hail": true
        "exceptional": true
    }
    if not supported.DoesExist(key) then key = "unknown"
    return "pkg:/images/weather/" + key + ".png"
end function

function TodayLabel() as string
    dt = CreateObject("roDateTime")
    weekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    dayIndex = (Int(dt.AsSeconds() / 86400) + 4) MOD 7
    return weekdays[dayIndex] + ", " + months[dt.GetMonth() - 1] + " " + dt.GetDayOfMonth().ToStr()
end function

' ---------------- Focus (left/right between panels) ----------------

sub SetFocusIndex(index as integer)
    m.focusIndex = index
    for i = 0 to m.rings.Count() - 1
        m.rings[i].visible = (i = index)
    end for
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    if key = "timeout"
        if m.agendaOpen then CloseAgenda()
        if m.mealsOpen then CloseMeals()
        SetFocusIndex(0)
        return true
    end if
    if m.agendaOpen then return HandleAgendaKey(key)
    if m.mealsOpen then return HandleMealKey(key)
    if key = "right"
        if m.focusIndex = m.rings.Count() - 1
            m.top.tabRequest = "next"
        else
            SetFocusIndex(m.focusIndex + 1)
        end if
        return true
    else if key = "left"
        if m.focusIndex = 0
            m.top.tabRequest = "previous"
        else
            SetFocusIndex(m.focusIndex - 1)
        end if
        return true
    else if key = "OK" and m.focusIndex = 0
        OpenAgenda()
        return true
    else if key = "OK" and m.focusIndex = 1
        OpenMeals()
        return true
    end if
    return false
end function

sub onKeyInput()
    onKeyEvent(m.top.keyInput, true)
end sub
