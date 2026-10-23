' MainScene: app coordinator.
' Loads saved HA config from the registry, routes between SetupView and
' HomeView, and relays Home Assistant data from HATask into the UI.
sub init()
    m.top.focusable = true
    m.bg = m.top.FindNode("background")
    m.scrim = m.top.FindNode("scrim")
    m.setupView = m.top.FindNode("setupView")
    m.homeView = m.top.FindNode("homeView")
    m.calendarView = m.top.FindNode("calendarView")
    m.weekView = m.top.FindNode("weekView")
    m.weatherView = m.top.FindNode("weatherView")
    m.lightsView = m.top.FindNode("lightsView")
    m.scenesView = m.top.FindNode("scenesView")
    m.climateView = m.top.FindNode("climateView")
    m.securityView = m.top.FindNode("securityView")
    m.views = {
        home: m.homeView
        week: m.weekView
        calendar: m.calendarView
        weather: m.weatherView
        lights: m.lightsView
        scenes: m.scenesView
        climate: m.climateView
        security: m.securityView
    }
    m.tabOrder = ["home", "calendar", "weather", "lights", "scenes", "climate", "security"]
    m.currentTab = "home"
    m.pendingTab = ""
    m.tabsData = {}
    m.commandSeq = 0
    m.focusSeq = 0
    m.inactivityTimer = m.top.CreateChild("Timer")
    m.inactivityTimer.duration = 300
    m.inactivityTimer.repeat = false
    m.inactivityTimer.ObserveField("fire", "onInactivityTimeout")
    m.focusRetryTimer = m.top.CreateChild("Timer")
    m.focusRetryTimer.duration = 0.2
    m.focusRetryTimer.repeat = false
    m.focusRetryTimer.ObserveField("fire", "onFocusRetry")
    m.homeView.ObserveField("tabRequest", "onHomeTabRequest")
    m.calendarView.ObserveField("tabRequest", "onCalendarTabRequest")
    m.weekView.ObserveField("tabRequest", "onWeekTabRequest")
    m.weatherView.ObserveField("tabRequest", "onWeatherTabRequest")
    m.lightsView.ObserveField("tabRequest", "onLightsTabRequest")
    m.scenesView.ObserveField("tabRequest", "onScenesTabRequest")
    m.climateView.ObserveField("tabRequest", "onClimateTabRequest")
    m.securityView.ObserveField("tabRequest", "onSecurityTabRequest")
    m.securityView.ObserveField("commandRequest", "onSecurityCommand")
    for each view in m.views
        m.views[view].ObserveField("activity", "onRemoteActivity")
    end for
    m.lightsView.ObserveField("commandRequest", "onLightsCommand")
    m.scenesView.ObserveField("commandRequest", "onScenesCommand")
    m.climateView.ObserveField("commandRequest", "onClimateCommand")
    m.homeView.ObserveField("commandRequest", "onHomeCommand")
    m.homeView.ObserveField("restoreFocus", "onDialogFocusRestore")
    m.setupView.ObserveField("restoreFocus", "onDialogFocusRestore")
    m.setupView.ObserveField("discoveryRequest", "onDiscoveryRequested")
    ' Observe the submitted config itself. This avoids a separate Boolean
    ' signal that some Roku OS versions coalesce or fail to deliver.
    m.setupView.ObserveField("config", "onConfigSubmitted")
    m.haTask = invalid
    m.discoveryTask = invalid

    loadSavedConfig()
end sub

sub loadSavedConfig()
    section = CreateObject("roRegistrySection", "haDashboard")
    if section.Exists("url") and section.Exists("token") and section.Read("url") <> "" and section.Read("token") <> ""
        config = {
            url: section.Read("url")
            token: section.Read("token")
            mealEntity: section.Read("mealEntity")
            insideEntity: section.Read("insideEntity")
            outsideEntity: section.Read("outsideEntity")
        }
        startDashboard(config)
    else
        showSetup("", invalid)
        startDiscovery()
    end if
end sub

sub onDashboardReady()
    if not m.top.dashboardReady then return
    focusActiveView()
    scheduleFocusRetry()
end sub

sub focusActiveView()
    if m.setupView.visible
        if m.setupView.inputActive
            m.focusSeq = m.focusSeq + 1
            m.setupView.focusRequest = m.focusSeq
        else
            m.top.SetFocus(true)
        end if
        return
    end if
    ' MainScene owns dashboard focus and forwards every key to the visible
    ' view. Keeping one focus owner avoids focus becoming trapped in a hidden
    ' tab or in a child node after setup and native dialogs close.
    m.top.SetFocus(true)
end sub

sub scheduleFocusRetry()
    m.focusRetryCount = 5
    m.focusRetryTimer.control = "stop"
    m.focusRetryTimer.control = "start"
end sub

sub onFocusRetry()
    if m.top.dialog = invalid
        focusActiveView()
    else
        ' A close request is asynchronous. Wait until the native dialog has
        ' actually left the Scene before restoring dashboard focus.
        m.focusRetryCount = m.focusRetryCount - 1
        if m.focusRetryCount > 0
            m.focusRetryTimer.control = "stop"
            m.focusRetryTimer.control = "start"
        end if
    end if
end sub

sub onDialogFocusRestore()
    scheduleFocusRetry()
end sub

sub showSetup(errorMessage as string, config as dynamic)
    m.inactivityTimer.control = "stop"
    m.setupView.visible = true
    m.setupView.inputActive = true
    focusActiveView()
    m.homeView.visible = false
    m.calendarView.visible = false
    m.weekView.visible = false
    m.weatherView.visible = false
    m.lightsView.visible = false
    m.scenesView.visible = false
    m.climateView.visible = false
    m.securityView.visible = false
    if config <> invalid
        m.setupView.prefill = config
    end if
    m.setupView.errorMessage = errorMessage
    scheduleFocusRetry()
end sub

sub onConfigSubmitted()
    config = m.setupView.config
    if config = invalid then return
    print "MAIN: received setup config for "; config.url
    section = CreateObject("roRegistrySection", "haDashboard")
    section.Write("url", config.url)
    section.Write("token", config.token)
    section.Write("mealEntity", config.mealEntity)
    section.Write("insideEntity", config.insideEntity)
    section.Write("outsideEntity", config.outsideEntity)
    section.Flush()
    print "MAIN: registry saved; connecting"
    startDashboard(config)
end sub

sub startDashboard(config as object)
    print "MAIN: startDashboard"
    isPairing = true
    if config.token <> invalid then isPairing = config.token = ""
    m.homeView.visible = not isPairing
    m.setupView.inputActive = false
    m.setupView.visible = isPairing
    m.calendarView.visible = false
    m.weekView.visible = false
    m.weatherView.visible = false
    m.lightsView.visible = false
    m.scenesView.visible = false
    m.climateView.visible = false
    m.securityView.visible = false
    if isPairing
        m.inactivityTimer.control = "stop"
    else
        m.currentTab = "home"
        m.top.SetFocus(true)
        m.inactivityTimer.control = "start"
    end if
    m.homeView.url = config.url
    m.homeView.mealEntity = config.mealEntity
    scheduleFocusRetry()

    if m.haTask <> invalid
        m.haTask.control = "STOP"
        m.top.RemoveChild(m.haTask)
    end if
    m.haTask = m.top.CreateChild("HATask")
    m.haTask.ObserveField("states", "onStates")
    m.haTask.ObserveField("resolvedEntities", "onResolvedEntities")
    m.haTask.ObserveField("todayEvents", "onTodayEvents")
    m.haTask.ObserveField("monthCalendar", "onMonthCalendar")
    m.haTask.ObserveField("calendarSchedule", "onCalendarSchedule")
    m.haTask.ObserveField("weatherData", "onWeatherData")
    m.haTask.ObserveField("backgroundData", "onBackgroundData")
    m.haTask.ObserveField("tabsData", "onTabsData")
    m.haTask.ObserveField("lightsData", "onLightsData")
    m.haTask.ObserveField("scenesData", "onScenesData")
    m.haTask.ObserveField("climatesData", "onClimatesData")
    m.haTask.ObserveField("securityData", "onSecurityData")
    m.haTask.ObserveField("commandResult", "onCommandResult")
    m.haTask.ObserveField("mealPlan", "onMealPlan")
    m.haTask.ObserveField("weeklyMealPlan", "onWeeklyMealPlan")
    m.haTask.ObserveField("dashboardTitle", "onDashboardTitle")
    m.haTask.ObserveField("themeData", "onThemeData")
    m.haTask.ObserveField("pairingCode", "onPairingCode")
    m.haTask.ObserveField("connectionStatus", "onConnectionStatus")
    m.haTask.url = config.url
    m.haTask.token = config.token
    m.haTask.mealEntity = config.mealEntity
    m.haTask.insideEntity = config.insideEntity
    m.haTask.outsideEntity = config.outsideEntity
    m.haTask.control = "RUN"
    print "MAIN: Home Assistant task started"
end sub

sub showConnectedDashboard()
    m.setupView.inputActive = false
    m.setupView.visible = false
    m.homeView.visible = true
    m.currentTab = "home"
    m.top.SetFocus(true)
    m.inactivityTimer.control = "start"
    scheduleFocusRetry()
end sub

sub onPairingCode()
    m.setupView.pairingCode = m.haTask.pairingCode
end sub

sub onDiscoveryRequested()
    startDiscovery()
end sub

sub startDiscovery()
    if m.discoveryTask <> invalid
        m.discoveryTask.control = "STOP"
        m.top.RemoveChild(m.discoveryTask)
    end if
    m.setupView.discoveryStatus = "searching"
    m.discoveryTask = m.top.CreateChild("DiscoveryTask")
    m.discoveryTask.ObserveField("status", "onDiscoveryStatus")
    m.discoveryTask.ObserveField("foundUrl", "onDiscoveryFound")
    m.discoveryTask.control = "RUN"
end sub

sub onDiscoveryStatus()
    m.setupView.discoveryStatus = m.discoveryTask.status
end sub

sub onDiscoveryFound()
    if m.discoveryTask.foundUrl <> "" then m.setupView.foundUrl = m.discoveryTask.foundUrl
end sub

sub onStates()
    m.homeView.states = m.haTask.states
end sub

sub onResolvedEntities()
    m.homeView.resolvedEntities = m.haTask.resolvedEntities
end sub

sub onTodayEvents()
    m.homeView.todayEvents = m.haTask.todayEvents
end sub

sub onMonthCalendar()
    m.calendarView.monthCalendar = m.haTask.monthCalendar
end sub

sub onCalendarSchedule()
    m.weekView.schedule = m.haTask.calendarSchedule
    m.homeView.calendarSchedule = m.haTask.calendarSchedule
end sub

sub onWeatherData()
    m.homeView.weatherData = m.haTask.weatherData
    m.weatherView.weatherData = m.haTask.weatherData
    m.weatherView.secondaryWeatherData = m.haTask.secondaryWeatherData
end sub

sub onBackgroundData()
    data = m.haTask.backgroundData
    if data = invalid then return
    uri = ""
    if data.url <> invalid then uri = data.url.ToStr()
    if uri = ""
        mode = "fall"
        if data.mode <> invalid then mode = data.mode.ToStr()
        if mode <> "winter" and mode <> "spring" and mode <> "summer" then mode = "fall"
        uri = "pkg:/images/" + mode + "-bg.jpg"
    end if
    m.bg.uri = uri
end sub

sub onTabsData()
    m.tabsData = m.haTask.tabsData
end sub

sub onLightsData()
    m.lightsView.items = m.haTask.lightsData
end sub

sub onScenesData()
    m.scenesView.items = m.haTask.scenesData
end sub

sub onClimatesData()
    m.climateView.items = m.haTask.climatesData
end sub

sub onSecurityData()
    m.securityView.data = m.haTask.securityData
end sub

sub onHomeTabRequest()
    navigateTab(m.homeView.tabRequest)
end sub

sub onWeekTabRequest()
    direction = m.weekView.tabRequest
    if direction = "home" or direction = "previous"
        showTab("home")
    else
        navigateTab(direction)
    end if
end sub

sub onCalendarTabRequest()
    navigateTab(m.calendarView.tabRequest)
end sub

sub onWeatherTabRequest()
    navigateTab(m.weatherView.tabRequest)
end sub

sub onLightsTabRequest()
    navigateTab(m.lightsView.tabRequest)
end sub

sub onScenesTabRequest()
    navigateTab(m.scenesView.tabRequest)
end sub

sub onClimateTabRequest()
    navigateTab(m.climateView.tabRequest)
end sub

sub onSecurityTabRequest()
    navigateTab(m.securityView.tabRequest)
end sub

sub showWeatherTab()
    showTab("weather")
end sub

sub showHomeTab()
    showTab("home")
end sub

sub navigateTab(direction as string)
    if direction = "week"
        showTab("week")
        return
    else if direction = "calendar"
        showTab("calendar")
        return
    end if
    currentName = m.currentTab
    if m.pendingTab <> "" then currentName = m.pendingTab
    currentIndex = 0
    for i = 0 to m.tabOrder.Count() - 1
        if m.tabOrder[i] = currentName then currentIndex = i
    end for
    stepValue = 1
    if direction = "previous" then stepValue = -1
    for attempt = 1 to m.tabOrder.Count()
        currentIndex = (currentIndex + stepValue + m.tabOrder.Count()) MOD m.tabOrder.Count()
        candidate = m.tabOrder[currentIndex]
        if tabEnabled(candidate)
            m.pendingTab = candidate
            SetTabFocus(candidate)
            return
        end if
    end for
end sub

function TabIconName(name as string) as string
    if name = "week" then return "calendar"
    return name
end function

sub SetTabFocus(name as string)
    iconName = TabIconName(name)
    for each key in m.views
        icons = m.views[key].FindNode("tabIcons")
        if icons <> invalid then icons.focusTab = iconName
    end for
end sub

sub ClearTabFocus()
    m.pendingTab = ""
    SetTabFocus(m.currentTab)
end sub

function tabEnabled(name as string) as boolean
    if name = "home" then return true
    if m.tabsData = invalid then return true
    value = m.tabsData[name]
    if value = invalid then return true
    return value
end function

sub showTab(name as string)
    view = m.views[name]
    if view = invalid then return
    m.currentTab = name
    m.pendingTab = ""
    for each key in m.views
        m.views[key].visible = (key = name)
    end for
    SetTabFocus(name)
    m.top.SetFocus(true)
    scheduleFocusRetry()
end sub

sub onRemoteActivity()
    m.inactivityTimer.control = "stop"
    m.inactivityTimer.control = "start"
end sub

' MainScene owns focus on the dashboard and forwards keys explicitly. This
' avoids Roku OS leaving focus in hidden setup controls or inactive tabs.
function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    m.inactivityTimer.control = "stop"
    m.inactivityTimer.control = "start"
    if m.setupView.visible then return false
    if key = "back" and m.currentTab = "home" then return false
    if m.pendingTab <> ""
        if key = "OK"
            showTab(m.pendingTab)
            return true
        else if key = "back"
            ClearTabFocus()
            return true
        else if key = "left" or key = "rewind"
            navigateTab("previous")
            return true
        else if key = "right" or key = "fastforward"
            navigateTab("next")
            return true
        end if
    end if
    if m.currentTab = "week"
        if key = "rewind"
            showTab("home")
            return true
        else if key = "fastforward"
            navigateTab("next")
            return true
        end if
    end if
    if key = "rewind"
        navigateTab("previous")
        return true
    else if key = "fastforward"
        navigateTab("next")
        return true
    end if
    view = m.views[m.currentTab]
    if view = invalid then return false
    print "KEY: "; key; " -> "; m.currentTab
    view.keyInput = key
    return true
end function

sub onInactivityTimeout()
    showTab("home")
    m.homeView.keyInput = "timeout"
    m.inactivityTimer.control = "start"
end sub

sub sendCommand(command as object)
    m.commandSeq = m.commandSeq + 1
    command.request_id = m.commandSeq
    print "COMMAND UI: "; command.action; " -> "; command.entity_id; " #"; m.commandSeq
    m.haTask.command = command
end sub

sub onLightsCommand()
    sendCommand(m.lightsView.commandRequest)
end sub

sub onHomeCommand()
    sendCommand(m.homeView.commandRequest)
end sub

sub onScenesCommand()
    sendCommand(m.scenesView.commandRequest)
end sub

sub onClimateCommand()
    sendCommand(m.climateView.commandRequest)
end sub

sub onSecurityCommand()
    sendCommand(m.securityView.commandRequest)
end sub

sub onCommandResult()
    result = m.haTask.commandResult
    m.lightsView.commandResult = result
    m.scenesView.commandResult = result
    m.climateView.commandResult = result
    m.securityView.commandResult = result
    m.homeView.commandResult = result
end sub

sub onMealPlan()
    m.homeView.mealPlan = m.haTask.mealPlan
end sub

sub onWeeklyMealPlan()
    m.homeView.weeklyMealPlan = m.haTask.weeklyMealPlan
end sub

sub onDashboardTitle()
    m.homeView.dashboardTitle = m.haTask.dashboardTitle
end sub

sub onThemeData()
    theme = m.haTask.themeData
    m.homeView.themeData = theme
    m.calendarView.themeData = theme
    if theme <> invalid and theme.background_overlay <> invalid
        overlay = theme.background_overlay
        if overlay < 45 then overlay = 45
        alpha = Int(overlay * 255 / 100)
        if alpha < 0 then alpha = 0
        if alpha > 255 then alpha = 255
        m.scrim.color = "0x000000" + ByteToHex(alpha)
    end if
end sub

function ByteToHex(value as integer) as string
    digits = "0123456789ABCDEF"
    return Mid(digits, Int(value / 16) + 1, 1) + Mid(digits, (value MOD 16) + 1, 1)
end function

sub onConnectionStatus()
    status = m.haTask.connectionStatus
    m.homeView.connectionStatus = status
    m.setupView.pairingStatus = status
    if status = "connected"
        if m.setupView.visible then showConnectedDashboard()
        return
    end if
    if status = "auth_error"
        showSetup("This Roku's credential was revoked. Start pairing again.", m.haTask.lastConfig)
    else if status = "network_error"
        showSetup("Could not reach Home Assistant. Check the URL and your network.", m.haTask.lastConfig)
    else if status = "network_denied"
        showSetup("Home Assistant blocked pairing from this network. Check Family Dashboard network access.", m.haTask.lastConfig)
    else if status = "pairing_unavailable"
        showSetup("Update the Family Dashboard integration in Home Assistant, then try again.", m.haTask.lastConfig)
    else if status = "pairing_denied"
        showSetup("Pairing was denied. Select START PAIRING to try again.", m.haTask.lastConfig)
    else if status = "pairing_expired"
        showSetup("The pairing code expired. Select START PAIRING to get a new code.", m.haTask.lastConfig)
    end if
end sub
