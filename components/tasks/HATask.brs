' HATask: background Task that talks to Home Assistant.
' - Validates the connection (REST /api/)
' - Loads all entity states (REST /api/states)
' - Resolves inside/outside temperature entities (explicit or auto-detected)
' - Fetches today's calendar events and the meal-plan sensor
' - Opens a WebSocket (/api/websocket) for live state_changed updates
'
' Publishes results through interface fields observed by MainScene.

sub init()
    m.top.functionName = "executeTask"
end sub

sub executeTask()
    print "HA TASK: started"
    m.url = m.top.url
    if Right(m.url, 1) = "/" then m.url = Left(m.url, Len(m.url) - 1)
    m.token = m.top.token
    m.pairingMode = Len(m.token) <= 64
    m.top.lastConfig = {
        url: m.top.url
        token: m.top.token
        mealEntity: m.top.mealEntity
        insideEntity: m.top.insideEntity
        outsideEntity: m.top.outsideEntity
    }

    if m.pairingMode
        conn = FetchPairingData()
    else
        conn = ValidateConnection()
    end if
    print "HA TASK: validation result = "; conn
    if conn <> "ok"
        m.top.connectionStatus = conn
        return
    end if
    m.top.connectionStatus = "connected"

    if m.pairingMode
        m.lastCommandId = -1
        while true
            for tick = 1 to 120
                Sleep(250)
                ProcessPendingCommand()
            end for
            refreshStatus = FetchPairingData()
            if refreshStatus <> "ok" then m.top.connectionStatus = refreshStatus
        end while
    end if

    m.states = {}
    FullRefresh()

    calendarTimer = CreateObject("roTimespan")
    calendarTimer.Mark()
    while true
        ok = RunWebsocket()
        if m.top.connectionStatus = "auth_error" then return
        m.top.connectionStatus = "reconnecting"
        if calendarTimer.TotalSeconds() > 900
            calendarTimer.Mark()
            FullRefresh()
        end if
        Sleep(5000)
    end while
end sub

' ---------------- REST helpers ----------------

function HttpGet(path as string) as object
    xfer = CreateObject("roUrlTransfer")
    xfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    xfer.InitClientCertificates()
    xfer.RetainBodyOnError(true)
    xfer.EnableEncodings(true)
    xfer.AddHeader("Authorization", "Bearer " + m.token)
    xfer.SetUrl(m.url + path)
    port = CreateObject("roMessagePort")
    xfer.SetMessagePort(port)
    if not xfer.AsyncGetToString()
        return { code: -1, body: "" }
    end if
    msg = Wait(15000, port)
    if msg = invalid or Type(msg) <> "roUrlEvent"
        return { code: -2, body: "" }
    end if
    return { code: msg.GetResponseCode(), body: msg.GetString() }
end function

function HttpGetJson(path as string) as dynamic
    resp = HttpGet(path)
    if resp.code < 200 or resp.code >= 300 then return { error: resp.code }
    return ParseJson(resp.body)
end function

function HttpGetPublic(path as string) as object
    xfer = CreateObject("roUrlTransfer")
    xfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    xfer.InitClientCertificates()
    xfer.RetainBodyOnError(true)
    xfer.EnableEncodings(true)
    xfer.SetUrl(m.url + path)
    port = CreateObject("roMessagePort")
    xfer.SetMessagePort(port)
    if not xfer.AsyncGetToString() then return { code: -1, body: "" }
    msg = Wait(15000, port)
    if msg = invalid or Type(msg) <> "roUrlEvent" then return { code: -2, body: "" }
    return { code: msg.GetResponseCode(), body: msg.GetString() }
end function

function HttpPostPublic(path as string, body as string) as object
    xfer = CreateObject("roUrlTransfer")
    xfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    xfer.InitClientCertificates()
    xfer.RetainBodyOnError(true)
    xfer.AddHeader("Content-Type", "application/json")
    xfer.SetUrl(m.url + path)
    port = CreateObject("roMessagePort")
    xfer.SetMessagePort(port)
    if not xfer.AsyncPostFromString(body) then return { code: -1, body: "" }
    msg = Wait(15000, port)
    if msg = invalid or Type(msg) <> "roUrlEvent" then return { code: -2, body: "" }
    return { code: msg.GetResponseCode(), body: msg.GetString() }
end function

sub ProcessPendingCommand()
    command = m.top.command
    if not IsAssociativeArray(command) or command.request_id = invalid then return
    if command.request_id = m.lastCommandId then return
    m.lastCommandId = command.request_id
    print "COMMAND TASK: received "; command.action; " -> "; command.entity_id
    commandPath = "/api/roku_dashboard/" + UrlEscape(UCase(m.token)) + "/action"
    commandBody = FormatJson(command)
    response = HttpPostPublic(commandPath, commandBody)
    ok = response.code >= 200 and response.code < 300
    print "COMMAND HTTP: status="; response.code; " body="; response.body
    m.top.commandResult = {
        request_id: command.request_id
        ok: ok
        status: response.code
    }
    if ok then FetchPairingData()
end sub

function FetchPairingData() as string
    resp = HttpGetPublic("/api/roku_dashboard/" + UrlEscape(UCase(m.token)))
    if resp.code = 401 then return "auth_error"
    if resp.code < 200 or resp.code >= 300 then return "network_error"
    data = ParseJson(resp.body)
    if not IsAssociativeArray(data) or data.ok <> true then return "network_error"

    if data.device_token <> invalid and data.device_token <> ""
        m.token = UCase(data.device_token.ToStr())
        section = CreateObject("roRegistrySection", "haDashboard")
        section.Write("token", m.token)
        section.Flush()
        print "HA TASK: pairing upgraded to secure device credential"
    end if

    states = data.states
    if not IsAssociativeArray(states) then states = {}
    m.states = states
    m.top.states = states
    if IsAssociativeArray(data.resolved_entities)
        m.top.resolvedEntities = data.resolved_entities
    end if
    if data.meal_plan <> invalid then m.top.mealPlan = data.meal_plan.ToStr()
    if IsArray(data.weekly_meal_plan) then m.top.weeklyMealPlan = data.weekly_meal_plan
    if data.title <> invalid then m.top.dashboardTitle = data.title.ToStr()
    if IsAssociativeArray(data.theme) then m.top.themeData = data.theme

    events = []
    if IsArray(data.calendar_events)
        for each raw in data.calendar_events
            start = raw.start.ToStr()
            allDay = raw.all_day = true
            timeLabel = "All day"
            if not allDay then timeLabel = FormatEventTime(start)
            events.Push({
                title: raw.title.ToStr()
                timeLabel: timeLabel
                allDay: allDay
                sortKey: start
            })
        end for
    end if
    m.top.calendarEvents = events
    if IsArray(data.today_events) then m.top.todayEvents = data.today_events
    if IsAssociativeArray(data.month_calendar)
        m.top.monthCalendar = data.month_calendar
    end if
    if IsAssociativeArray(data.calendar_schedule)
        m.top.calendarSchedule = data.calendar_schedule
    end if
    if IsAssociativeArray(data.weather)
        m.top.weatherData = data.weather
    end if
    if data.background <> invalid
        bgMode = data.background.ToStr()
        bgUrl = ""
        if bgMode = "uploaded" and data.has_uploaded_background = true
            version = ""
            if data.background_version <> invalid then version = data.background_version.ToStr()
            bgUrl = m.url + "/api/roku_dashboard/" + UrlEscape(UCase(m.token)) + "/background?v=" + version
        else if bgMode = "custom_url" and data.background_url <> invalid and data.background_url <> ""
            bgUrl = data.background_url.ToStr()
            if Left(bgUrl, 1) = "/" then bgUrl = m.url + bgUrl
        end if
        m.top.backgroundData = { mode: bgMode, url: bgUrl }
    end if
    if IsAssociativeArray(data.tabs) then m.top.tabsData = data.tabs
    if IsArray(data.lights) then m.top.lightsData = data.lights
    if IsArray(data.scenes) then m.top.scenesData = data.scenes
    if IsArray(data.climates) then m.top.climatesData = data.climates
    m.top.connectionStatus = "connected"
    return "ok"
end function

function ValidateConnection() as string
    resp = HttpGet("/api/")
    if resp.code = 200
        return "ok"
    else if resp.code = 401 or resp.code = 403
        return "auth_error"
    else
        return "network_error"
    end if
end function

function UrlEscape(s as string) as string
    hexDigits = "0123456789ABCDEF"
    out = ""
    for i = 1 to Len(s)
        c = Mid(s, i, 1)
        code = Asc(c)
        if (code >= 48 and code <= 57) or (code >= 65 and code <= 90) or (code >= 97 and code <= 122) or c = "." or c = "_" or c = "-" or c = "@"
            out = out + c
        else
            out = out + "%" + Mid(hexDigits, Int(code / 16) + 1, 1) + Mid(hexDigits, (code MOD 16) + 1, 1)
        end if
    end for
    return out
end function

' ---------------- Data loading ----------------

sub FullRefresh()
    FetchStates()
    ResolveEntities()
    FetchCalendar()
    FetchMeal()
end sub

sub FetchStates()
    data = HttpGetJson("/api/states")
    if not IsArray(data) then return
    states = {}
    for each entity in data
        if entity <> invalid and entity.entity_id <> invalid
            attrs = entity.attributes
            if attrs = invalid then attrs = {}
            states[entity.entity_id] = { state: entity.state, attributes: attrs }
        end if
    end for
    m.states = states
    m.top.states = states
end sub

sub ResolveEntities()
    resolved = { inside: m.top.insideEntity, outside: m.top.outsideEntity }
    if resolved.outside = invalid then resolved.outside = ""
    if resolved.inside = invalid then resolved.inside = ""

    if resolved.outside = ""
        for each id in m.states
            if Left(id, 8) = "weather."
                resolved.outside = id
                exit for
            end if
        end for
    end if

    if resolved.inside = ""
        best = ""
        bestIsClimate = false
        for each id in m.states
            st = m.states[id]
            attrs = st.attributes
            if Left(id, 7) = "climate." and best = ""
                best = id
                bestIsClimate = true
            else if Left(id, 7) = "sensor." and not bestIsClimate and attrs <> invalid
                if attrs.device_class = "temperature" and not IsOutdoorName(id + " " + FriendlyNameOf(id, st))
                    best = id
                end if
            end if
        end for
        resolved.inside = best
    end if

    m.top.resolvedEntities = resolved
end sub

function IsOutdoorName(name as string) as boolean
    n = LCase(name)
    bad = ["outside", "outdoor", "garden", "backyard", "patio", "deck", "yard", "pool", "roof", "street"]
    for each b in bad
        if Instr(1, n, b) > 0 then return true
    end for
    return false
end function

function FriendlyNameOf(entityId as string, st as object) as string
    if st.attributes <> invalid and st.attributes.friendly_name <> invalid
        return st.attributes.friendly_name.ToStr()
    end if
    return entityId
end function

' ---------------- Calendar ----------------

sub FetchCalendar()
    ' Prefer the calendar list chosen in the Roku Dashboard integration
    ' (sensor.roku_dashboard_config); fall back to every calendar.
    cals = ConfigCalendarList()
    if cals.Count() = 0
        raw = HttpGetJson("/api/calendars")
        if IsArray(raw)
            for each cal in raw
                if cal <> invalid and cal.entity_id <> invalid
                    cals.Push(cal.entity_id.ToStr())
                end if
            end for
        end if
    end if

    events = []
    count = 0
    for each calId in cals
        if count >= 10 then exit for
        FetchCalendarEntity(calId, events)
        count = count + 1
    end for
    SortEvents(events)
    today = []
    for each ev in events
        if today.Count() >= 5 then exit for
        today.Push(ev)
    end for
    m.top.calendarEvents = today
end sub

function ConfigCalendarList() as object
    result = []
    resp = HttpGet("/api/states/sensor.roku_dashboard_config")
    if resp.code <> 200 then return result
    data = ParseJson(resp.body)
    if IsAssociativeArray(data) and data.state <> invalid
        cfg = ParseJson(data.state.ToStr())
        if IsAssociativeArray(cfg) and IsArray(cfg.calendar_entities)
            for each id in cfg.calendar_entities
                result.Push(id.ToStr())
            end for
        end if
    end if
    return result
end function

sub FetchCalendarEntity(entityId as string, events as object)
    path = "/api/calendars/" + UrlEscape(entityId) + "?start=" + UrlEscape(DayBoundaryIso(0)) + "&end=" + UrlEscape(DayBoundaryIso(1))
    data = HttpGetJson(path)
    if not IsArray(data) then return
    for each ev in data
        if ev <> invalid and ev.start <> invalid
            allDay = false
            sortKey = ""
            timeLabel = ""
            if ev.start.dateTime <> invalid
                sortKey = ev.start.dateTime.ToStr()
                timeLabel = FormatEventTime(ev.start.dateTime.ToStr())
            else if ev.start.date <> invalid
                allDay = true
                sortKey = ev.start.date.ToStr() + "T00:00:00"
                timeLabel = "All day"
            end if
            if sortKey <> ""
                title = "Untitled"
                if ev.summary <> invalid then title = ev.summary.ToStr()
                events.Push({ title: title, timeLabel: timeLabel, allDay: allDay, sortKey: sortKey })
            end if
        end if
    end for
end sub

function FormatEventTime(iso as string) as string
    if Len(iso) < 16 then return ""
    hour = Val(Mid(iso, 12, 2))
    minute = Mid(iso, 15, 2)
    suffix = "AM"
    h12 = hour
    if hour >= 12
        suffix = "PM"
        h12 = hour - 12
    end if
    if h12 = 0 then h12 = 12
    return h12.ToStr() + ":" + minute + " " + suffix
end function

sub SortEvents(events as object)
    n = events.Count()
    for i = 0 to n - 2
        for j = i + 1 to n - 1
            if events[j].sortKey < events[i].sortKey
                tmp = events[i]
                events[i] = events[j]
                events[j] = tmp
            end if
        end for
    end for
end sub

function DayBoundaryIso(dayOffset as integer) as string
    dt = CreateObject("roDateTime")
    secondsOfDay = dt.GetHours() * 3600 + dt.GetMinutes() * 60 + dt.GetSeconds()
    dt2 = CreateObject("roDateTime")
    dt2.FromSeconds(dt.AsSeconds() - secondsOfDay + dayOffset * 86400)
    return dt2.ToIsoString()
end function

' ---------------- Meal plan ----------------

sub FetchMeal()
    mealEntity = m.top.mealEntity
    if mealEntity = invalid or mealEntity = "" then return
    data = HttpGetJson("/api/states/" + UrlEscape(mealEntity))
    if IsAssociativeArray(data) and data.state <> invalid
        m.top.mealPlan = data.state.ToStr()
    end if
end sub

' ---------------- WebSocket (live updates) ----------------

function WsUrl() as string
    u = m.url
    if Left(u, 5) = "https"
        u = "wss" + Mid(u, 6)
    else
        u = "ws" + Mid(u, 5)
    end if
    if Right(u, 1) = "/" then u = Left(u, Len(u) - 1)
    return u + "/api/websocket"
end function

function RunWebsocket() as boolean
    ws = CreateObject("roWebSocket")
    port = CreateObject("roMessagePort")
    ws.SetMessagePort(port)
    if not ws.SetUrl(WsUrl()) then return false
    if not ws.Open(15000) then return false

    m.wsAuthDone = false
    refreshTimer = CreateObject("roTimespan")
    refreshTimer.Mark()
    ws.SetTimer("keepalive", 30000, true)

    while true
        msg = Wait(60000, port)
        if msg = invalid
            ws.Close()
            return false
        end if
        if Type(msg) = "roWebSocketEvent"
            t = msg.GetType()
            if t = 1 ' opened
                ws.Send(FormatJson({ type: "auth", access_token: m.token }))
            else if t = 5 ' text received
                info = msg.GetInfo()
                if not HandleWsText(info.Text, ws)
                    ws.Close()
                    return false
                end if
            else if t = 9 ' timer
                ws.SetTimer("keepalive", 30000, true)
                if m.wsAuthDone
                    ws.Send(FormatJson({ type: "ping" }))
                end if
                if refreshTimer.TotalSeconds() > 900
                    refreshTimer.Mark()
                    FetchCalendar()
                    FetchMeal()
                end if
            else if t = 2 ' closed
                return false
            end if
        end if
    end while
end function

function HandleWsText(text as string, ws as object) as boolean
    msg = ParseJson(text)
    if not IsAssociativeArray(msg) then return false
    mt = msg.type
    if mt = "auth_ok"
        m.wsAuthDone = true
        ws.Send(FormatJson({ id: 1, type: "subscribe_events", event_type: "state_changed" }))
    else if mt = "auth_invalid"
        m.top.connectionStatus = "auth_error"
        return false
    else if mt = "event"
        ev = msg.event
        if ev <> invalid and ev.event_type = "state_changed" and ev.data <> invalid
            if ev.data.entity_id <> invalid
                ApplyStateChange(ev.data.entity_id.ToStr(), ev.data.new_state)
            end if
        end if
    end if
    return true
end function

sub ApplyStateChange(entityId as string, newstate as dynamic)
    if newstate = invalid
        if m.states.DoesExist(entityId)
            m.states.Delete(entityId)
        end if
    else
        attrs = newstate.attributes
        if attrs = invalid then attrs = {}
        m.states[entityId] = { state: newstate.state, attributes: attrs }
    end if
    m.top.states = m.states

    if m.top.mealEntity <> "" and entityId = m.top.mealEntity
        if newstate <> invalid and newstate.state <> invalid
            m.top.mealPlan = newstate.state.ToStr()
        end if
    end if

    ' Keep auto-detected inside/outside entities up to date (e.g. they
    ' appear or change after startup).
    resolved = m.top.resolvedEntities
    if resolved <> invalid
        needsResolve = false
        if (resolved.inside = "" or resolved.inside = invalid) and (Left(entityId, 7) = "climate." or Left(entityId, 7) = "sensor.")
            needsResolve = true
        end if
        if (resolved.outside = "" or resolved.outside = invalid) and Left(entityId, 8) = "weather."
            needsResolve = true
        end if
        if needsResolve then ResolveEntities()
    end if
end sub

' BrightScript has Type()/GetInterface(), but no portable IsArray or
' IsAssociativeArray globals across Roku OS versions.
function IsArray(value as dynamic) as boolean
    t = Type(value)
    return t = "roArray" or t = "Array"
end function

function IsAssociativeArray(value as dynamic) as boolean
    t = Type(value)
    return t = "roAssociativeArray" or t = "AssociativeArray"
end function
