' SetupView: first-run configuration.
' Collects the HA URL, long-lived access token and optional entity ids,
' then hands the config back to MainScene for validation + registry save.
sub init()
    m.urlBox = m.top.FindNode("urlBox")
    m.tokenBox = m.top.FindNode("tokenBox")
    m.mealBox = m.top.FindNode("mealBox")
    m.insideBox = m.top.FindNode("insideBox")
    m.outsideBox = m.top.FindNode("outsideBox")
    m.saveButton = m.top.FindNode("saveButton")
    m.errorLabel = m.top.FindNode("errorLabel")
    m.top.FindNode("subtitleLabel").text = "Enter your Home Assistant URL and a long-lived access token." + Chr(10) + "Create one in Home Assistant: Profile -> Security -> Long-Lived Access Tokens."

    m.fields = [m.urlBox, m.tokenBox, m.mealBox, m.insideBox, m.outsideBox, m.saveButton]
    m.focusIndex = 0

    m.urlBox.text = "http://homeassistant.local:8123"
    m.mealBox.text = "sensor.meal_plan"
    m.tokenBox.text = ""
    m.insideBox.text = ""
    m.outsideBox.text = ""

    m.saveButton.ObserveField("buttonSelected", "onSave")

    m.urlBox.SetFocus(true)
end sub

sub onPrefill()
    prefill = m.top.prefill
    if prefill = invalid then return
    if prefill.url <> invalid and prefill.url <> "" then m.urlBox.text = prefill.url
    if prefill.token <> invalid then m.tokenBox.text = prefill.token
    if prefill.mealEntity <> invalid then m.mealBox.text = prefill.mealEntity
    if prefill.insideEntity <> invalid then m.insideBox.text = prefill.insideEntity
    if prefill.outsideEntity <> invalid then m.outsideBox.text = prefill.outsideEntity
end sub

sub onErrorMessage()
    m.errorLabel.text = m.top.errorMessage
end sub

sub onSave()
    url = m.urlBox.text.Trim()
    token = m.tokenBox.text.Trim()
    m.errorLabel.text = ""
    if url = "" or token = ""
        m.errorLabel.text = "URL and access token are required."
        return
    end if
    if Left(url, 7) <> "http://" and Left(url, 8) <> "https://"
        m.errorLabel.text = "URL must start with http:// or https://"
        return
    end if
    m.top.config = {
        url: url
        token: token
        mealEntity: m.mealBox.text.Trim()
        insideEntity: m.insideBox.text.Trim()
        outsideEntity: m.outsideBox.text.Trim()
    }
    m.top.configSaved = true
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    if key = "down"
        if m.focusIndex < m.fields.Count() - 1
            m.focusIndex = m.focusIndex + 1
            m.fields[m.focusIndex].SetFocus(true)
            return true
        end if
    else if key = "up"
        if m.focusIndex > 0
            m.focusIndex = m.focusIndex - 1
            m.fields[m.focusIndex].SetFocus(true)
            return true
        end if
    else if key = "OK"
        ' Track which row the user is on; the TextEditBox opens its own keyboard.
        for i = 0 to m.fields.Count() - 1
            if m.fields[i].IsInFocusChain()
                m.focusIndex = i
                exit for
            end if
        end for
    end if
    return false
end function
