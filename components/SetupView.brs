' SetupView uses native focusable Button controls. Selecting URL or token
' opens Roku's KeyboardDialog, which supports remote and mobile-app input.
sub init()
    m.urlButton = m.top.FindNode("urlButton")
    m.tokenButton = m.top.FindNode("tokenButton")
    m.connectButton = m.top.FindNode("connectButton")
    m.messageButton = m.top.FindNode("messageButton")

    m.url = "http://homeassistant.local:8123"
    m.token = ""
    m.editingField = ""

    m.urlButton.ObserveField("buttonSelected", "onUrlSelected")
    m.tokenButton.ObserveField("buttonSelected", "onTokenSelected")
    m.connectButton.ObserveField("buttonSelected", "onConnectSelected")
    renderValues()
    m.urlButton.SetFocus(true)
end sub

sub onPrefill()
    prefill = m.top.prefill
    if prefill = invalid then return
    if prefill.url <> invalid and prefill.url <> "" then m.url = prefill.url
    if prefill.token <> invalid then m.token = prefill.token
    renderValues()
end sub

sub onErrorMessage()
    if m.top.errorMessage <> ""
        m.messageButton.text = m.top.errorMessage
    end if
end sub

sub renderValues()
    m.urlButton.text = "HOME ASSISTANT URL:  " + m.url
    if m.token = ""
        m.tokenButton.text = "ACCESS TOKEN:  NOT ENTERED"
    else
        m.tokenButton.text = "ACCESS TOKEN:  SAVED (" + Len(m.token).ToStr() + " CHARACTERS)"
    end if
end sub

sub onUrlSelected()
    openKeyboard("url")
end sub

sub onTokenSelected()
    openKeyboard("token")
end sub

sub onConnectSelected()
    saveAndConnect()
end sub

sub openKeyboard(fieldName as string)
    m.editingField = fieldName
    dialog = CreateObject("roSGNode", "KeyboardDialog")
    if dialog = invalid
        m.messageButton.text = "This Roku could not open its keyboard"
        return
    end if

    if fieldName = "url"
        dialog.title = "Enter Home Assistant URL"
        dialog.text = m.url
    else
        dialog.title = "Enter Long-Lived Access Token"
        dialog.text = m.token
    end if
    dialog.buttons = ["SAVE", "CANCEL"]
    dialog.ObserveField("buttonSelected", "onKeyboardButton")
    m.keyboardDialog = dialog

    ' Attach first so the internal TextEditBox is fully created.
    scene = m.top.GetScene()
    scene.dialog = dialog
    if dialog.textEditBox <> invalid
        dialog.textEditBox.maxTextLength = 1024
        dialog.textEditBox.clearOnDownKey = false
        dialog.textEditBox.secureMode = (fieldName = "token")
    end if
    dialog.SetFocus(true)
end sub

sub onKeyboardButton()
    dialog = m.keyboardDialog
    if dialog = invalid then return
    if dialog.buttonSelected = 0
        value = dialog.text.Trim()
        if m.editingField = "url"
            m.url = value
        else
            m.token = value
        end if
        renderValues()
        m.messageButton.text = "Value saved - select CONNECT when ready"
    end if
    dialog.close = true
    m.keyboardDialog = invalid
    m.editingField = ""
    if m.urlButton <> invalid then m.urlButton.SetFocus(true)
end sub

sub saveAndConnect()
    url = m.url.Trim()
    token = m.token.Trim()
    if url = "" or token = ""
        m.messageButton.text = "URL AND ACCESS TOKEN ARE BOTH REQUIRED"
        return
    end if
    if Left(url, 7) <> "http://" and Left(url, 8) <> "https://"
        m.messageButton.text = "URL MUST START WITH http:// OR https://"
        return
    end if
    m.messageButton.text = "CONNECTING..."
    m.top.config = {
        url: url
        token: token
        mealEntity: "input_text.roku_dashboard_meal_plan"
        insideEntity: ""
        outsideEntity: ""
    }
    m.top.configSaved = true
end sub
