' SetupView uses native focusable Button controls. Selecting URL or token
' opens Roku's KeyboardDialog, which supports remote and mobile-app input.
sub init()
    m.urlButton = m.top.FindNode("urlButton")
    m.tokenButton = m.top.FindNode("tokenButton")
    m.connectButton = m.top.FindNode("connectButton")
    m.messageButton = m.top.FindNode("messageButton")
    m.loginButtons = m.top.FindNode("loginButtons")
    m.tokenEditor = m.top.FindNode("tokenEditor")
    m.tokenInput = m.top.FindNode("tokenInput")
    m.saveTokenButton = m.top.FindNode("saveTokenButton")
    m.cancelTokenButton = m.top.FindNode("cancelTokenButton")
    m.tokenHelp = m.top.FindNode("tokenHelp")

    m.url = "http://homeassistant.local:8123"
    m.token = ""
    m.editingField = ""

    m.urlButton.ObserveField("buttonSelected", "onUrlSelected")
    m.tokenButton.ObserveField("buttonSelected", "onTokenSelected")
    m.connectButton.ObserveField("buttonSelected", "onConnectSelected")
    m.saveTokenButton.ObserveField("buttonSelected", "onSaveToken")
    m.cancelTokenButton.ObserveField("buttonSelected", "onCancelToken")
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
    openTokenEditor()
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

sub openTokenEditor()
    m.tokenEditing = true
    m.tokenEditor.visible = true
    m.tokenInput.text = m.token
    m.tokenInput.cursorPosition = Len(m.token)
    m.tokenInput.maxTextLength = 1024
    m.tokenInput.secureMode = true
    m.tokenInput.SetFocus(true)
end sub

sub onSaveToken()
    value = m.tokenInput.text.Trim()
    if value = ""
        m.tokenHelp.text = "TOKEN CANNOT BE EMPTY - PASTE IT ABOVE"
        m.tokenInput.SetFocus(true)
        return
    end if
    m.token = value
    closeTokenEditor()
    renderValues()
    m.messageButton.text = "Token saved - " + Len(m.token).ToStr() + " characters"
end sub

sub onCancelToken()
    closeTokenEditor()
end sub

sub closeTokenEditor()
    m.tokenEditing = false
    m.tokenEditor.visible = false
    m.tokenButton.SetFocus(true)
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
    print "SETUP: submitting Home Assistant config for "; url
    m.top.config = {
        url: url
        token: token
        mealEntity: "input_text.roku_dashboard_meal_plan"
        insideEntity: ""
        outsideEntity: ""
    }
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press or not m.tokenEditing then return false
    if key = "down" and m.tokenInput.IsInFocusChain()
        m.saveTokenButton.SetFocus(true)
        return true
    else if key = "up" and (m.saveTokenButton.IsInFocusChain() or m.cancelTokenButton.IsInFocusChain())
        m.tokenInput.SetFocus(true)
        return true
    else if key = "right" and m.saveTokenButton.IsInFocusChain()
        m.cancelTokenButton.SetFocus(true)
        return true
    else if key = "left" and m.cancelTokenButton.IsInFocusChain()
        m.saveTokenButton.SetFocus(true)
        return true
    else if key = "back"
        closeTokenEditor()
        return true
    end if
    return false
end function
