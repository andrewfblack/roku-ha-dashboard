sub Main()
    screen = CreateObject("roSGScreen")
    port = CreateObject("roMessagePort")
    screen.SetMessagePort(port)
    scene = screen.CreateScene("MainScene")
    screen.Show()
    ' SceneGraph may ignore focus requests made while component init() is
    ' running. Signal the scene only after the screen is on the display.
    scene.dashboardReady = true

    ' Reset Roku's inactivity timer while this always-on dashboard is open.
    appManager = CreateObject("roAppManager")

    while true
        msg = Wait(30000, port)
        if msg = invalid
            if appManager <> invalid then appManager.UpdateLastKeyPressTime()
        else if Type(msg) = "roSGScreenEvent"
            if msg.IsScreenClosed() then return
        end if
    end while
end sub
