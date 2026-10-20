sub init()
    m.top.focusable = true
    m.status = m.top.FindNode("status")
    m.name = m.top.FindNode("weatherName")
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
        bg = group.CreateChild("Rectangle")
        bg.width = 1020
        bg.height = 72
        bg.translation = [0, i * 82]
        if i MOD 2 = 0 then bg.color = "0x382A1CDD" else bg.color = "0x2A2017DD"

        period = group.CreateChild("Label")
        period.width = 180
        period.height = 60
        period.translation = [20, i * 82 + 8]
        condition = group.CreateChild("Label")
        condition.width = 330
        condition.height = 60
        condition.translation = [210, i * 82 + 8]
        temperature = group.CreateChild("Label")
        temperature.width = 230
        temperature.height = 60
        temperature.translation = [550, i * 82 + 8]
        rain = group.CreateChild("Label")
        rain.width = 210
        rain.height = 60
        rain.horizAlign = "right"
        rain.translation = [790, i * 82 + 8]
        m.rows.Push({ period: period, condition: condition, temperature: temperature, rain: rain, bg: bg })
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
        row.temperature.visible = visible
        row.rain.visible = visible
        if visible
            item = forecast[i]
            row.period.text = forecastTime(valueOr(item.datetime, ""), data.forecast_type)
            row.condition.text = humanCondition(valueOr(item.condition, "Unknown"))
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

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    if key = "left" or key = "back"
        m.top.tabRequest = "previous"
        return true
    else if key = "right"
        m.top.tabRequest = "next"
        return true
    end if
    return false
end function
