sub init()
    m.top.focusable = true
    m.status = m.top.FindNode("status")
    m.name = m.top.FindNode("weatherName")
    m.currentIcon = m.top.FindNode("currentIcon")
    m.temp = m.top.FindNode("currentTemp")
    m.condition = m.top.FindNode("currentCondition")
    m.humidity = m.top.FindNode("currentHumidity")
    m.wind = m.top.FindNode("currentWind")
    m.pressure = m.top.FindNode("currentPressure")
    m.visibility = m.top.FindNode("currentVisibility")
    m.forecastHeader = m.top.FindNode("forecastHeader")
    m.rows = []
    buildForecastRows()
end sub

sub buildForecastRows()
    group = m.top.FindNode("forecastRows")
    for i = 0 to 7
        col = i MOD 5
        cardRow = Int(i / 5)
        x = col * 218
        y = cardRow * 330
        bg = group.CreateChild("Rectangle")
        bg.width = 202
        bg.height = 310
        bg.translation = [x, y]
        if i MOD 2 = 0 then bg.color = "0x382A1CF2" else bg.color = "0x2A2017F2"

        period = group.CreateChild("Label")
        period.width = 182
        period.height = 48
        period.horizAlign = "center"
        period.translation = [x + 10, y + 14]
        condition = group.CreateChild("Label")
        condition.width = 182
        condition.height = 44
        condition.horizAlign = "center"
        condition.translation = [x + 10, y + 184]
        icon = group.CreateChild("Poster")
        icon.width = 112
        icon.height = 112
        icon.translation = [x + 45, y + 62]
        icon.loadDisplayMode = "scaleToFit"
        icon.uri = "pkg:/images/weather/forecast/unknown.png"
        temperature = group.CreateChild("Label")
        temperature.width = 182
        temperature.height = 48
        temperature.horizAlign = "left"
        temperature.font = "font:MediumSystemFont"
        temperature.translation = [x + 10, y + 228]
        rain = group.CreateChild("Label")
        rain.width = 182
        rain.height = 36
        rain.horizAlign = "center"
        rain.translation = [x + 10, y + 270]
        m.rows.Push({ period: period, icon: icon, condition: condition, temperature: temperature, rain: rain, bg: bg })
    end for
end sub

sub onWeatherData()
    data = m.top.weatherData
    if data = invalid then return
    if data.enabled = false
        m.status.text = "Weather tab disabled in Home Assistant"
        return
    end if
    if data.available = false
        m.status.text = "Weather entity unavailable"
        return
    end if

    m.status.text = "LIVE FROM HOME ASSISTANT"
    m.name.text = valueOr(data.name, "WEATHER")
    m.currentIcon.uri = currentWeatherIconUri(valueOr(data.condition, "unknown"))
    m.temp.text = temperatureText(data.temperature, valueOr(data.temperature_unit, ""))
    m.condition.text = humanCondition(valueOr(data.condition, "Unknown"))
    m.humidity.text = detailLine("Humidity", data.humidity, "%")
    m.wind.text = detailLine("Wind", data.wind_speed, "")
    m.pressure.text = detailLine("Pressure", data.pressure, "")
    m.visibility.text = detailLine("Visibility", data.visibility, "")
    m.forecastHeader.text = UCase(valueOr(data.forecast_type, "daily")) + " FORECAST"

    forecast = data.forecast
    if forecast = invalid then forecast = []
    for i = 0 to 7
        visible = i < forecast.Count()
        row = m.rows[i]
        row.bg.visible = visible
        row.period.visible = visible
        row.condition.visible = visible
        row.icon.visible = visible
        row.temperature.visible = visible
        row.rain.visible = visible
        if visible
            item = forecast[i]
            if item.label <> invalid and item.label <> ""
                row.period.text = item.label.ToStr()
            else
                row.period.text = forecastTime(valueOr(item.datetime, ""), data.forecast_type)
            end if
            row.condition.text = humanCondition(valueOr(item.condition, "Unknown"))
            row.icon.uri = forecastWeatherIconUri(valueOr(item.condition, "unknown"))
            high = temperatureText(item.temperature, "")
            low = ""
            if item.templow <> invalid then low = " / " + temperatureText(item.templow, "")
            row.temperature.text = high + low
            if item.precipitation_probability <> invalid
                row.rain.text = item.precipitation_probability.ToStr() + "% rain"
            else
                row.rain.text = ""
            end if
        end if
    end for
end sub

function valueOr(value as dynamic, fallback as string) as string
    if value = invalid then return fallback
    return value.ToStr()
end function

function temperatureText(value as dynamic, unit as string) as string
    if value = invalid then return "--"
    text = value.ToStr()
    if Right(text, 2) = ".0" then text = Left(text, Len(text) - 2)
    if Len(unit) > 0 and Left(unit, 1) = Chr(176)
        return text + unit
    end if
    return text + Chr(176) + unit
end function

function detailLine(label as string, value as dynamic, suffix as string) as string
    if value = invalid then return ""
    return label + ": " + value.ToStr() + suffix
end function

function forecastTime(value as string, forecastType as string) as string
    if Len(value) < 10 then return value
    result = Mid(value, 6, 2) + "/" + Mid(value, 9, 2)
    if forecastType = "hourly" and Len(value) >= 16
        result = result + " " + Mid(value, 12, 5)
    end if
    return result
end function

function humanCondition(value as string) as string
    text = value.Replace("-", " ").Replace("_", " ")
    if text = "partlycloudy" then return "Partly Cloudy"
    if text = "clear night" then return "Clear Night"
    if text = "" then return "Unknown"
    return UCase(Left(text, 1)) + LCase(Mid(text, 2))
end function

function weatherIconKey(condition as string) as string
    key = LCase(condition)
    supported = {
        "sunny": true
        "clear-night": true
        "cloudy": true
        "partlycloudy": true
        "rainy": true
        "pouring": true
        "lightning": true
        "lightning-rainy": true
        "snowy": true
        "snowy-rainy": true
        "fog": true
        "windy": true
        "windy-variant": true
        "hail": true
        "exceptional": true
    }
    if not supported.DoesExist(key) then key = "unknown"
    return key
end function

function currentWeatherIconUri(condition as string) as string
    return "pkg:/images/weather/current/" + weatherIconKey(condition) + ".png"
end function

function forecastWeatherIconUri(condition as string) as string
    return "pkg:/images/weather/forecast/" + weatherIconKey(condition) + ".png"
end function

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    m.top.activity = key
    if key = "left" or key = "back"
        m.top.tabRequest = "previous"
        return true
    else if key = "right"
        m.top.tabRequest = "next"
        return true
    end if
    return false
end function

sub onKeyInput()
    onKeyEvent(m.top.keyInput, true)
end sub
