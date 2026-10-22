' Setup finds Home Assistant and starts device-initiated pairing. The code is
' generated for this Roku and approved from the Family Dashboard HA panel.
sub init()
    m.urlButton = m.top.FindNode("urlButton")
    m.discoverButton = m.top.FindNode("discoverButton")
    m.connectButton = m.top.FindNode("connectButton")
    m.messageButton = m.top.FindNode("messageButton")
    m.pairingLabel = m.top.FindNode("pairingLabel")
    m.instructionsLabel = m.top.FindNode("instructionsLabel")
    m.url = "http://homeassistant.local:8123"
    m.editingField = ""
    m.discoverySeq = 0
    m.urlButton.ObserveField("buttonSelected", "onUrlSelected")
    m.discoverButton.ObserveField("buttonSelected", "onDiscoverSelected")
    m.connectButton.ObserveField("buttonSelected", "onConnectSelected")
    renderValues()
    m.urlButton.SetFocus(true)
end sub

sub onPrefill()
    value = m.top.prefill
    if value = invalid then return
    if value.url <> invalid and value.url <> "" then m.url = value.url
    renderValues()
end sub

sub onErrorMessage()
    if m.top.errorMessage <> "" then m.messageButton.text = m.top.errorMessage
end sub

sub onInputActive()
    active = m.top.inputActive
    m.urlButton.focusable = active
    m.discoverButton.focusable = active
    m.connectButton.focusable = active
    if active
        m.urlButton.SetFocus(true)
    else
        ' Clear focus from the hidden setup button before MainScene takes it.
        m.urlButton.SetFocus(false)
        m.discoverButton.SetFocus(false)
        m.connectButton.SetFocus(false)
    end if
end sub

sub onFocusRequest()
    if m.top.inputActive then m.urlButton.SetFocus(true)
end sub

sub renderValues()
    m.urlButton.text = "HOME ASSISTANT URL:  " + m.url
end sub

sub onUrlSelected()
    openKeyboard("url")
end sub

sub onDiscoverSelected()
    m.messageButton.text = "SEARCHING YOUR LOCAL NETWORK..."
    m.discoverySeq = m.discoverySeq + 1
    m.top.discoveryRequest = m.discoverySeq
end sub

sub openKeyboard(fieldName as string)
    m.editingField = fieldName
    dialog = CreateObject("roSGNode", "KeyboardDialog")
    if dialog = invalid
        m.messageButton.text = "Unable to open Roku keyboard"
        return
    end if
    dialog.title = "Enter Home Assistant URL"
    dialog.text = m.url
    dialog.buttons = ["SAVE", "CANCEL"]
    dialog.ObserveField("buttonSelected", "onKeyboardButton")
    m.keyboardDialog = dialog
    m.top.GetScene().dialog = dialog
    dialog.SetFocus(true)
end sub

sub onKeyboardButton()
    dialog = m.keyboardDialog
    if dialog = invalid then return
    if dialog.buttonSelected = 0
        value = dialog.text.Trim()
        m.url = value
        renderValues()
        m.messageButton.text = "VALUE SAVED - SELECT START PAIRING"
    end if
    dialog.close = true
    m.keyboardDialog = invalid
    m.urlButton.SetFocus(true)
    m.top.restoreFocus = "setupKeyboardClosed"
end sub

sub onConnectSelected()
    url = m.url.Trim()
    if url = ""
        m.messageButton.text = "HOME ASSISTANT URL IS REQUIRED"
        return
    end if
    if Left(url, 7) <> "http://" and Left(url, 8) <> "https://"
        m.messageButton.text = "URL MUST START WITH http:// OR https://"
        return
    end if
    m.messageButton.text = "REQUESTING A PAIRING CODE..."
    m.pairingLabel.visible = false
    m.instructionsLabel.visible = false
    m.top.config = {
        url: url
        token: ""
        mealEntity: ""
        insideEntity: ""
        outsideEntity: ""
    }
end sub

sub onDiscoveryStatus()
    status = m.top.discoveryStatus
    if status = "searching"
        m.messageButton.text = "SEARCHING YOUR LOCAL NETWORK..."
    else if status = "not_found"
        m.messageButton.text = "NOT FOUND - ENTER THE HOME ASSISTANT URL MANUALLY"
    end if
end sub

sub onFoundUrl()
    if m.top.foundUrl = "" then return
    m.url = m.top.foundUrl
    renderValues()
    m.messageButton.text = "HOME ASSISTANT FOUND - SELECT START PAIRING"
    m.urlButton.SetFocus(true)
end sub

sub onPairingCode()
    code = m.top.pairingCode
    if code = ""
        m.pairingLabel.visible = false
        m.instructionsLabel.visible = false
        return
    end if
    m.pairingLabel.text = "PAIRING CODE:  " + code
    m.pairingLabel.visible = true
    m.instructionsLabel.text = "Open Family Dashboard in Home Assistant, select Pair a device, then approve this Roku."
    m.instructionsLabel.visible = true
    m.messageButton.text = "WAITING FOR APPROVAL..."
end sub

sub onPairingStatus()
    status = m.top.pairingStatus
    if status = "pairing_request"
        m.messageButton.text = "REQUESTING A PAIRING CODE..."
    else if status = "pairing_pending"
        m.messageButton.text = "WAITING FOR APPROVAL..."
    else if status = "pairing_denied"
        m.messageButton.text = "PAIRING WAS DENIED - SELECT START PAIRING TO RETRY"
    else if status = "pairing_expired"
        m.messageButton.text = "PAIRING CODE EXPIRED - SELECT START PAIRING TO RETRY"
    end if
end sub
