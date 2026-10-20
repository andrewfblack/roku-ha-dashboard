' HomeView: the "Home" tab.
' Renders today's calendar events, the meal plan sensor and the
' inside/outside climate readout from Home Assistant data.
sub init()
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
    m.outsideName = m.top.FindNode("outsideName")
    m.outsideDetail = m.top.FindNode("outsideDetail")
    m.statusLabel = m.top.FindNode("statusLabel")
    m.dateLabel = m.top.FindNode("dateLabel")

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

sub onMealPlan()
    meal = m.top.mealPlan
    if meal = invalid or meal = "" or meal = "unknown" or meal = "unavailable"
        m.mealContent.text = "No meal plan set." + Chr(10) + "Update your meal plan sensor in Home Assistant."
    else
        m.mealContent.text = meal
    end if
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
        visible = i < count
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
        name = FriendlyName(insideId, st)
        if name <> "" then m.insideName.text = name
        detail = ""
        if st.attributes <> invalid and st.attributes.humidity <> invalid
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
        m.outsideName.text = TitleCase(st.state.ToStr())
        detail = ""
        if st.attributes <> invalid and st.attributes.humidity <> invalid
            detail = st.attributes.humidity.ToStr() + "% humidity"
        end if
        m.outsideDetail.text = detail
    else
        m.outsideValue.text = "--"
        m.outsideName.text = "Outside"
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
    if key = "right"
        SetFocusIndex((m.focusIndex + 1) MOD m.rings.Count())
        return true
    else if key = "left"
        SetFocusIndex((m.focusIndex + m.rings.Count() - 1) MOD m.rings.Count())
        return true
    end if
    return false
end function
