' MainScene: app coordinator.
' Loads saved HA config from the registry, routes between SetupView and
' HomeView, and relays Home Assistant data from HATask into the UI.
sub init()
    m.setupView = m.top.FindNode("setupView")
    m.homeView = m.top.FindNode("homeView")
    m.setupView.ObserveField("configSaved", "onConfigSaved")
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
    m.setupView.visible = true
    if config <> invalid
        m.setupView.prefill = config
    end if
    m.setupView.errorMessage = errorMessage
    m.setupView.SetFocus(true)
end sub

sub onConfigSaved()
    config = m.setupView.config
    section = CreateObject("roRegistrySection", "haDashboard")
    section.Write("url", config.url)
    section.Write("token", config.token)
    section.Write("mealEntity", config.mealEntity)
    section.Write("insideEntity", config.insideEntity)
    section.Write("outsideEntity", config.outsideEntity)
    section.Flush()
    startDashboard(config)
end sub

sub startDashboard(config as object)
    m.setupView.visible = false
    m.homeView.visible = true
    m.homeView.url = config.url
    m.homeView.mealEntity = config.mealEntity
    m.homeView.SetFocus(true)

    if m.haTask <> invalid
        m.haTask.control = "STOP"
        m.top.RemoveChild(m.haTask)
    end if
    m.haTask = m.top.CreateChild("HATask")
    m.haTask.ObserveField("states", "onStates")
    m.haTask.ObserveField("resolvedEntities", "onResolvedEntities")
    m.haTask.ObserveField("calendarEvents", "onCalendarEvents")
    m.haTask.ObserveField("mealPlan", "onMealPlan")
    m.haTask.ObserveField("connectionStatus", "onConnectionStatus")
    m.haTask.url = config.url
    m.haTask.token = config.token
    m.haTask.mealEntity = config.mealEntity
    m.haTask.insideEntity = config.insideEntity
    m.haTask.outsideEntity = config.outsideEntity
    m.haTask.control = "RUN"
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

sub onMealPlan()
    m.homeView.mealPlan = m.haTask.mealPlan
end sub

sub onConnectionStatus()
    status = m.haTask.connectionStatus
    m.homeView.connectionStatus = status
    if status = "auth_error"
        showSetup("Login failed. Check your URL and long-lived access token.", m.haTask.lastConfig)
    else if status = "network_error"
        showSetup("Could not reach Home Assistant. Check the URL and your network.", m.haTask.lastConfig)
    end if
end sub
