' MainScene: app coordinator.
' Loads saved HA config from the registry, routes between SetupView and
' HomeView, and relays Home Assistant data from HATask into the UI.
sub init()
    m.top.focusable = true
    m.setupView = m.top.FindNode("setupView")
    m.homeView = m.top.FindNode("homeView")
    m.weatherView = m.top.FindNode("weatherView")
    m.lightsView = m.top.FindNode("lightsView")
    m.scenesView = m.top.FindNode("scenesView")
    m.climateView = m.top.FindNode("climateView")
    m.views = {
        home: m.homeView
        weather: m.weatherView
        lights: m.lightsView
        scenes: m.scenesView
        climate: m.climateView
    }
    m.tabOrder = ["home", "weather", "lights", "scenes", "climate"]
    m.currentTab = "home"
    m.tabsData = {}
    m.commandSeq = 0
    m.homeView.ObserveField("tabRequest", "onHomeTabRequest")
    m.weatherView.ObserveField("tabRequest", "onWeatherTabRequest")
    m.lightsView.ObserveField("tabRequest", "onLightsTabRequest")
    m.scenesView.ObserveField("tabRequest", "onScenesTabRequest")
    m.climateView.ObserveField("tabRequest", "onClimateTabRequest")
    m.lightsView.ObserveField("commandRequest", "onLightsCommand")
    m.scenesView.ObserveField("commandRequest", "onScenesCommand")
    m.climateView.ObserveField("commandRequest", "onClimateCommand")
    ' Observe the submitted config itself. This avoids a separate Boolean
    ' signal that some Roku OS versions coalesce or fail to deliver.
    m.setupView.ObserveField("config", "onConfigSubmitted")
    m.haTask = invalid

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
    end if
end sub

sub showSetup(errorMessage as string, config as dynamic)
    m.homeView.visible = false
    m.weatherView.visible = false
    m.lightsView.visible = false
    m.scenesView.visible = false
    m.climateView.visible = false
    m.setupView.visible = true
    m.setupView.inputActive = true
    if config <> invalid
        m.setupView.prefill = config
    end if
    m.setupView.errorMessage = errorMessage
    m.setupView.SetFocus(true)
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
    print "MAIN: registry saved; opening dashboard"
    startDashboard(config)
end sub

sub startDashboard(config as object)
    print "MAIN: startDashboard"
    m.setupView.inputActive = false
    m.setupView.visible = false
    m.homeView.visible = true
    m.weatherView.visible = false
    m.lightsView.visible = false
    m.scenesView.visible = false
    m.climateView.visible = false
    m.currentTab = "home"
    m.homeView.url = config.url
    m.homeView.mealEntity = config.mealEntity
    m.top.SetFocus(true)

    if m.haTask <> invalid
        m.haTask.control = "STOP"
        m.top.RemoveChild(m.haTask)
    end if
    m.haTask = m.top.CreateChild("HATask")
    m.haTask.ObserveField("states", "onStates")
    m.haTask.ObserveField("resolvedEntities", "onResolvedEntities")
    m.haTask.ObserveField("calendarEvents", "onCalendarEvents")
    m.haTask.ObserveField("monthCalendar", "onMonthCalendar")
    m.haTask.ObserveField("weatherData", "onWeatherData")
    m.haTask.ObserveField("tabsData", "onTabsData")
    m.haTask.ObserveField("lightsData", "onLightsData")
    m.haTask.ObserveField("scenesData", "onScenesData")
    m.haTask.ObserveField("climatesData", "onClimatesData")
    m.haTask.ObserveField("commandResult", "onCommandResult")
    m.haTask.ObserveField("mealPlan", "onMealPlan")
    m.haTask.ObserveField("connectionStatus", "onConnectionStatus")
    m.haTask.url = config.url
    m.haTask.token = config.token
    m.haTask.mealEntity = config.mealEntity
    m.haTask.insideEntity = config.insideEntity
    m.haTask.outsideEntity = config.outsideEntity
    m.haTask.control = "RUN"
    print "MAIN: Home Assistant task started"
end sub

sub onStates()
    m.homeView.states = m.haTask.states
end sub

sub onResolvedEntities()
    m.homeView.resolvedEntities = m.haTask.resolvedEntities
end sub

sub onCalendarEvents()
    m.homeView.calendarEvents = m.haTask.calendarEvents
end sub

sub onMonthCalendar()
    m.homeView.monthCalendar = m.haTask.monthCalendar
end sub

sub onWeatherData()
    m.weatherView.weatherData = m.haTask.weatherData
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

sub onHomeTabRequest()
    navigateTab(m.homeView.tabRequest)
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

sub showWeatherTab()
    showTab("weather")
end sub

sub showHomeTab()
    showTab("home")
end sub

sub navigateTab(direction as string)
    currentIndex = 0
    for i = 0 to m.tabOrder.Count() - 1
        if m.tabOrder[i] = m.currentTab then currentIndex = i
    end for
    stepValue = 1
    if direction = "previous" then stepValue = -1
    for attempt = 1 to m.tabOrder.Count()
        currentIndex = (currentIndex + stepValue + m.tabOrder.Count()) MOD m.tabOrder.Count()
        candidate = m.tabOrder[currentIndex]
        if tabEnabled(candidate)
            showTab(candidate)
            return
        end if
    end for
end sub

function tabEnabled(name as string) as boolean
    if name = "home" then return true
    if m.tabsData = invalid then return true
    value = m.tabsData[name]
    if value = invalid then return true
    return value
end function

sub showTab(name as string)
    for each key in m.views
        m.views[key].visible = false
    end for
    view = m.views[name]
    view.visible = true
    m.top.SetFocus(true)
    m.currentTab = name
end sub

' MainScene owns focus on the dashboard and forwards keys explicitly. This
' avoids older Roku OS versions leaving focus in hidden setup controls.
function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    if m.setupView.visible then return false
    if key = "back" and m.currentTab = "home" then return false
    view = m.views[m.currentTab]
    if view = invalid then return false
    print "KEY: "; key; " -> "; m.currentTab
    view.keyInput = key
    return true
end function

sub sendCommand(command as object)
    m.commandSeq = m.commandSeq + 1
    command.request_id = m.commandSeq
    print "COMMAND UI: "; command.action; " -> "; command.entity_id; " #"; m.commandSeq
    m.haTask.command = command
end sub

sub onLightsCommand()
    sendCommand(m.lightsView.commandRequest)
end sub

sub onScenesCommand()
    sendCommand(m.scenesView.commandRequest)
end sub

sub onClimateCommand()
    sendCommand(m.climateView.commandRequest)
end sub

sub onCommandResult()
    result = m.haTask.commandResult
    m.lightsView.commandResult = result
    m.scenesView.commandResult = result
    m.climateView.commandResult = result
end sub

sub onMealPlan()
    m.homeView.mealPlan = m.haTask.mealPlan
end sub

sub onConnectionStatus()
    status = m.haTask.connectionStatus
    m.homeView.connectionStatus = status
    if status = "auth_error"
        showSetup("Pairing failed. Check the 8-character code in Home Assistant.", m.haTask.lastConfig)
    else if status = "network_error"
        showSetup("Could not reach Home Assistant. Check the URL and your network.", m.haTask.lastConfig)
    end if
end sub
