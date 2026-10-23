' HomeView: the "Home" tab.
' Renders today's and tomorrow's calendar events, the meal plan sensor and
' the inside/outside climate readout from Home Assistant data. OK on the
' calendar panel opens the standalone week calendar page.
sub init()
    m.top.focusable = true
    m.states = {}
    m.resolvedEntities = {}
    m.weatherData = {}
    m.focusIndex = 0

    m.todayRowTimes = []
    m.todayRowTitles = []
    m.tomorrowRowTimes = []
    m.tomorrowRowTitles = []
    for i = 0 to 3
        m.todayRowTimes.Push(m.top.FindNode("today" + i.ToStr() + "Time"))
        m.todayRowTitles.Push(m.top.FindNode("today" + i.ToStr() + "Title"))
        m.tomorrowRowTimes.Push(m.top.FindNode("tomorrow" + i.ToStr() + "Time"))
        m.tomorrowRowTitles.Push(m.top.FindNode("tomorrow" + i.ToStr() + "Title"))
    end for
    m.todayEmpty = m.top.FindNode("todayEmpty")
    m.tomorrowEmpty = m.top.FindNode("tomorrowEmpty")
    m.tomorrowHeader = m.top.FindNode("tomorrowHeader")
    m.calendarPanel = m.top.FindNode("calendarPanel")
    m.mealPanel = m.top.FindNode("mealPanel")
    m.climatePanel = m.top.FindNode("climatePanel")
    m.calendarHeader = m.top.FindNode("calendarHeader")
    m.mealHeader = m.top.FindNode("mealHeader")
    m.climateHeader = m.top.FindNode("climateHeader")
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
    m.todayEvents = []
    m.scheduleDays = []
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
    SetFocusIndex(0)

    m.dateLabel.text = TodayLabel()
    m.mealContent.text = "Waiting for Home Assistant..."
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

sub onWeatherData()
    m.weatherData = m.top.weatherData
    if m.weatherData = invalid then m.weatherData = {}
    UpdateClimate()
end sub

sub onTodayEvents()
    m.todayEvents = m.top.todayEvents
    if m.todayEvents = invalid then m.todayEvents = []
    RenderToday()
end sub

sub onCalendarSchedule()
    value = m.top.calendarSchedule
    if value <> invalid and value.days <> invalid
        m.scheduleDays = value.days
    else
        m.scheduleDays = []
    end if
    RenderTomorrow()
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

sub onThemeData()
    theme = m.top.themeData
    if theme = invalid then return
    opacity = 90
    if theme.item_opacity <> invalid then opacity = theme.item_opacity
    ' Roku is viewed from farther away than the web dashboard. Preserve the
    ' configured colour while keeping text readable over detailed artwork.
    if opacity < 92 then opacity = 92
    panelColor = ThemeColor(theme.item_background, opacity)
    bodyColor = ThemeColor(theme.body_text, 100)
    mutedColor = ThemeColor(theme.muted_text, 100)
    headerColor = ThemeColor(theme.header_text, 100)
    itemHeaderColor = ThemeColor(theme.item_header_text, 100)
    selectedBorder = ThemeColor(theme.selected_border, 100)
    m.calendarPanel.color = panelColor
    m.mealPanel.color = panelColor
    m.climatePanel.color = panelColor
    for each ring in m.rings
        ring.color = selectedBorder
    end for
    m.titleLabel.color = headerColor
    m.dateLabel.color = mutedColor
    m.statusLabel.color = mutedColor
    m.calendarHeader.color = itemHeaderColor
    m.tomorrowHeader.color = itemHeaderColor
    m.mealHeader.color = itemHeaderColor
    m.climateHeader.color = itemHeaderColor
    m.mealContent.color = bodyColor
    m.insideValue.color = bodyColor
    m.outsideValue.color = bodyColor
    m.insideName.color = itemHeaderColor
    m.outsideName.color = itemHeaderColor
    m.insideDetail.color = mutedColor
    m.outsideCondition.color = mutedColor
    m.outsideDetail.color = mutedColor
    for i = 0 to m.todayRowTimes.Count() - 1
        m.todayRowTimes[i].color = mutedColor
        m.todayRowTitles[i].color = bodyColor
        m.tomorrowRowTimes[i].color = mutedColor
        m.tomorrowRowTitles[i].color = bodyColor
    end for
    m.todayEmpty.color = mutedColor
    m.tomorrowEmpty.color = mutedColor
end sub

function ThemeColor(value as dynamic, opacity as integer) as string
    color = "FFF7EA"
    if value <> invalid
        color = UCase(value.ToStr().Replace("#", ""))
        if Len(color) <> 6 then color = "FFF7EA"
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

sub RenderToday()
    RenderEventRows(m.todayEvents, m.todayRowTimes, m.todayRowTitles, m.todayEmpty, m.calendarHeader, "TODAY'S CALENDAR")
end sub

sub RenderTomorrow()
    events = []
    overflow = 0
    if m.scheduleDays.Count() > 1
        day = m.scheduleDays[1]
        if day <> invalid
            if day.events <> invalid then events = day.events
            if day.overflow <> invalid then overflow = day.overflow
        end if
    end if
    RenderEventRows(events, m.tomorrowRowTimes, m.tomorrowRowTitles, m.tomorrowEmpty, m.tomorrowHeader, "TOMORROW'S CALENDAR")
    total = events.Count() + overflow
    if total > m.tomorrowRowTimes.Count()
        m.tomorrowHeader.text = "TOMORROW'S CALENDAR  +" + (total - m.tomorrowRowTimes.Count()).ToStr() + " MORE"
    end if
end sub

sub RenderEventRows(events as dynamic, times as object, titles as object, emptyLabel as object, header as object, headerText as string)
    if events = invalid then events = []
    count = events.Count()
    maxRows = times.Count()
    for i = 0 to maxRows - 1
        visible = i < count
        times[i].visible = visible
        titles[i].visible = visible
        if visible
            event = events[i]
            times[i].text = HomeEventTime(event)
            titles[i].text = event.title.ToStr()
        end if
    end for
    emptyLabel.visible = (count = 0)
    header.text = headerText
    if count > maxRows then header.text = headerText + "  +" + (count - maxRows).ToStr() + " MORE"
end sub

function HomeEventTime(event as object) as string
    if event.all_day = true then return "All day"
    value = event.start.ToStr()
    if Len(value) >= 16 then return Mid(value, 12, 5)
    return ""
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
    m.top.SetFocus(true)
    m.top.restoreFocus = "mealKeyboardClosed"
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
        else if st.attributes <> invalid and st.attributes.current_temperature <> invalid
            temp = st.attributes.current_temperature.ToStr()
        end if
        unit = ""
        if st.attributes <> invalid and st.attributes.temperature_unit <> invalid
            unit = st.attributes.temperature_unit.ToStr()
        end if
        ' Keep the Home card populated even when the configured weather entity
        ' exposes its current reading only through the weather payload.
        if temp = "" and m.weatherData <> invalid and m.weatherData.temperature <> invalid
            temp = m.weatherData.temperature.ToStr()
            if m.weatherData.temperature_unit <> invalid then unit = m.weatherData.temperature_unit.ToStr()
        end if
        m.outsideValue.text = CleanTemperatureWithUnit(temp, unit)
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
        m.outsideIcon.uri = "pkg:/images/weather/home/unknown.png"
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

function CleanTemperatureWithUnit(value as string, unit as string) as string
    if value = "" or value = "unknown" or value = "unavailable" then return "--"
    ' Drop a trailing "0" in whole numbers coming from floats (e.g. "21.0")
    if Len(value) > 2 and Right(value, 2) = ".0"
        value = Left(value, Len(value) - 2)
    end if
    if unit = "" then return value + Chr(176)
    ' Home Assistant weather units already include the degree symbol (°F/°C),
    ' but some integrations report a bare F or C.
    if Left(unit, 1) <> Chr(176) then unit = Chr(176) + unit
    return value + unit
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
    return "pkg:/images/weather/home/" + key + ".png"
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
    m.top.activity = key
    if key = "timeout"
        if m.mealsOpen then CloseMeals()
        SetFocusIndex(0)
        return true
    end if
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
        m.top.tabRequest = "week"
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
