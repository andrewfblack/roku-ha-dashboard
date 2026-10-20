' SetupView: compact first-run login screen.
' It uses Roku's native KeyboardDialog rather than bare TextEditBox nodes;
' this keeps the form readable in every display mode and makes long token
' entry/paste work reliably with the Roku mobile app.
sub init()
    m.urlValue = m.top.FindNode("urlValue")
    m.tokenValue = m.top.FindNode("tokenValue")
    m.errorLabel = m.top.FindNode("errorLabel")
    m.focusRings = [
        m.top.FindNode("urlFocus")
        m.top.FindNode("tokenFocus")
        m.top.FindNode("connectFocus")
    ]

    m.url = "http://homeassistant.local:8123"
    m.token = ""
    m.focusIndex = 0
    m.editingField = ""
    renderValues()
    renderFocus()
    m.top.SetFocus(true)
end sub

sub onPrefill()
    prefill = m.top.prefill
    if prefill = invalid then return
    if prefill.url <> invalid and prefill.url <> "" then m.url = prefill.url
    if prefill.token <> invalid then m.token = prefill.token
    renderValues()
end sub

sub onErrorMessage()
    m.errorLabel.text = m.top.errorMessage
end sub

sub renderValues()
    m.urlValue.text = m.url
    if m.token = ""
        m.tokenValue.text = "Select to enter token"
        m.tokenValue.color = "0x604F43FF"
    else
        ' Never show the credential on the TV after entry.
        m.tokenValue.text = "Token saved  -  " + Len(m.token).ToStr() + " characters"
        m.tokenValue.color = "0x25170FFF"
    end if
end sub

sub renderFocus()
    for i = 0 to m.focusRings.Count() - 1
        m.focusRings[i].visible = (i = m.focusIndex)
    end for
end sub

sub openKeyboard(fieldName as string)
    m.editingField = fieldName
    dialog = CreateObject("roSGNode", "KeyboardDialog")
    if fieldName = "url"
        dialog.title = "Home Assistant URL"
        dialog.text = m.url
    else
        dialog.title = "Long-Lived Access Token"
        dialog.text = m.token
    end if
    dialog.buttons = ["SAVE", "CANCEL"]
    dialog.optionsDialog = true
    if dialog.textEditBox <> invalid
        dialog.textEditBox.maxTextLength = 1024
        dialog.textEditBox.clearOnDownKey = false
        dialog.textEditBox.secureMode = (fieldName = "token")
    end if
    dialog.ObserveField("buttonSelected", "onKeyboardButton")
    m.keyboardDialog = dialog
    m.top.GetScene().dialog = dialog
end sub

sub onKeyboardButton()
    dialog = m.keyboardDialog
    if dialog = invalid then return
    if dialog.buttonSelected = 0
        value = dialog.text.Trim()
        if m.editingField = "url"
            m.url = value
        else if m.editingField = "token"
            m.token = value
        end if
        renderValues()
        m.errorLabel.text = ""
    end if
    dialog.close = true
    m.keyboardDialog = invalid
    m.editingField = ""
    m.top.SetFocus(true)
end sub

sub onSave()
    url = m.url.Trim()
    token = m.token.Trim()
    m.errorLabel.text = ""
    if url = "" or token = ""
        m.errorLabel.text = "Both the Home Assistant URL and access token are required."
        return
    end if
    if Left(url, 7) <> "http://" and Left(url, 8) <> "https://"
        m.errorLabel.text = "The URL must start with http:// or https://"
        return
    end if
    m.top.config = {
        url: url
        token: token
        mealEntity: "input_text.roku_dashboard_meal_plan"
        insideEntity: ""
        outsideEntity: ""
    }
    m.top.configSaved = true
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    if key = "down"
        if m.focusIndex < 2 then m.focusIndex = m.focusIndex + 1
        renderFocus()
        return true
    else if key = "up"
        if m.focusIndex > 0 then m.focusIndex = m.focusIndex - 1
        renderFocus()
        return true
    else if key = "OK"
        if m.focusIndex = 0
            openKeyboard("url")
        else if m.focusIndex = 1
            openKeyboard("token")
        else
            onSave()
        end if
        return true
    end if
    return false
end function
