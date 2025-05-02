local api = require("api")
local defaultSettings = require("Navigate/util/default_settings")
local checkButton = require('Navigate/util/check_button')

local helpers = {}
LIST_COLUMN_HEIGHT = 35
local labelHeight = 20
local editWidth = 100

function helpers.getSettings()
    local settings = api.GetSettings("Navigate")
    -- loop for set default settings if not exists
    for k, v in pairs(defaultSettings) do
        if settings[k] == nil then settings[k] = v end
    end
    return settings
end

function helpers.createButton(id, parent, text, x, y)
    local button = api.Interface:CreateWidget('button', id, parent)
    button:SetExtent(55, 26)
    button:AddAnchor("TOPLEFT", x, y)
    button:SetText(text)
    api.Interface:ApplyButtonSkin(button, BUTTON_BASIC.DEFAULT)
    return button
end

function helpers.createLabel(id, parent, text, offsetX, offsetY, fontSize)
    local label = api.Interface:CreateWidget('label', id, parent)
    label:AddAnchor("TOPLEFT", offsetX, offsetY)
    label:SetExtent(255, labelHeight)
    label:SetText(text)
    label.style:SetColor(FONT_COLOR.TITLE[1], FONT_COLOR.TITLE[2],
                         FONT_COLOR.TITLE[3], 1)
    label.style:SetAlign(ALIGN.LEFT)
    label.style:SetFontSize(fontSize or 18)

    return label
end

function helpers.createCheckbox(id, parent, text, offsetX, offsetY)
    local checkBox = checkButton.CreateCheckButton(id, parent, text)
    checkBox:AddAnchor("TOPLEFT", offsetX, offsetY)
    checkBox:SetButtonStyle("default")
    return checkBox
end

function helpers.createEdit(id, parent, text, offsetX, offsetY)
    local field = W_CTRL.CreateEdit(id, parent)
    field:SetExtent(editWidth, labelHeight)
    field:AddAnchor("TOPLEFT", offsetX, offsetY)
    field:SetText(tostring(text))
    field.style:SetColor(0, 0, 0, 1)
    field.style:SetAlign(ALIGN.LEFT)
    -- field:SetDigit(true)
    field:SetInitVal(tostring(text))
    -- field:SetMaxTextLength(4)
    return field
end

function helpers.DefaultTooltipSetting(widget)
    ApplyTextColor(widget, FONT_COLOR.SOFT_BROWN)
    widget:SetInset(10, 10, 10, 10)
    widget:SetLineSpace(4)
    widget.style:SetSnap(true)
end
function helpers.createTooltip(id, parent, text, x, y)
    local tooltip = api.Interface:CreateWidget("gametooltip", id, parent)
    tooltip:AddAnchor("CENTER", x, y)
    tooltip:EnablePick(false)
    tooltip:Show(false)
    helpers.DefaultTooltipSetting(tooltip)
    tooltip:SetInset(7, 7, 7, 7)
    tooltip.bg = tooltip:CreateNinePartDrawable('ui/common_new/default.dds',
                                                "background")
    tooltip.bg:SetTextureInfo("tooltip")
    tooltip.bg:AddAnchor("TOPLEFT", tooltip, 0, 0)
    tooltip.bg:AddAnchor("BOTTOMRIGHT", tooltip, 0, 0)
    tooltip:SetInset(10, 10, 10, 10)
    tooltip:ClearLines()
    tooltip:AddLine(text, "", 0, "left", ALIGN.LEFT, 0)
    return tooltip
end

function helpers.DrawListCtrlUnderLine(listCtrl, offsetY, colorWhite, offsetX)
    if colorWhite == nil then colorWhite = false end
    local width = listCtrl:GetWidth()
    if offsetX == nil then offsetX = 0 end
    local underLine_1 = listCtrl:CreateImageDrawable(TEXTURE_PATH.TAB_LIST,
                                                     "artwork")
    underLine_1:SetCoords(0, 6, 256, 3)
    underLine_1:SetExtent(width / 2, 3)
    local underLine_2 = listCtrl:CreateImageDrawable(TEXTURE_PATH.TAB_LIST,
                                                     "artwork")
    underLine_2:SetCoords(256, 6, -256, 3)
    underLine_2:SetExtent(width / 2, 3)
    if not colorWhite then
        underLine_1:SetColor(FONT_COLOR.DEFAULT[1], FONT_COLOR.DEFAULT[2],
                             FONT_COLOR.DEFAULT[3], FONT_COLOR.DEFAULT[4])
        underLine_2:SetColor(FONT_COLOR.DEFAULT[1], FONT_COLOR.DEFAULT[2],
                             FONT_COLOR.DEFAULT[3], FONT_COLOR.DEFAULT[4])
    end
    if offsetY == nil then
        underLine_1:AddAnchor("TOPLEFT", listCtrl, offsetX,
                              LIST_COLUMN_HEIGHT - 2)
        underLine_2:AddAnchor("TOPRIGHT", listCtrl, -offsetX,
                              LIST_COLUMN_HEIGHT - 2)
    else
        underLine_1:AddAnchor("TOPLEFT", listCtrl, offsetX, offsetY)
        underLine_2:AddAnchor("TOPRIGHT", listCtrl, -offsetX, offsetY)
    end
end

function helpers.DrawListCtrlColumnSperatorLine(widget, totalCount, count,
                                                colorWhite)
    local inset = 3
    if colorWhite == nil then colorWhite = false end
    local divideLine
    if count < totalCount then
        divideLine = widget:CreateImageDrawable("ui/common/tab_list.dds",
                                                "overlay")
        if count % 3 == 1 then
            divideLine:SetExtent(24, 55)
            divideLine:SetCoords(182, 9, 24, 55)
            divideLine:AddAnchor("BOTTOMLEFT", widget, "BOTTOMRIGHT", 0, 33)
        elseif count % 3 == 2 then
            divideLine:SetExtent(25, 51)
            divideLine:SetCoords(206, 9, 25, 51)
            divideLine:AddAnchor("BOTTOMLEFT", widget, "BOTTOMRIGHT", 0, 22)
        else
            divideLine:SetExtent(25, 15)
            divideLine:SetCoords(231, 9, 25, 15)
            divideLine:AddAnchor("BOTTOMLEFT", widget, "BOTTOMRIGHT", 0, 0)
        end
        if not colorWhite then
            divideLine:SetColor(ConvertColor(114), ConvertColor(94),
                                ConvertColor(50), 1)
        end
    end
    return divideLine
end

function helpers.insertColumns(listCtrl, columns)

    for i = 1, #columns do
        -- columns[i].index = i
        listCtrl:InsertColumn(columns[i].text, columns[i].width, 1,
                              columns[i].setFunc, nil, nil, columns[i].func)

        local column = listCtrl.listCtrl.column[i]

        column:Enable(false)
        column.style:SetColor(FONT_COLOR.DEFAULT[1], FONT_COLOR.DEFAULT[2],
                              FONT_COLOR.DEFAULT[3], FONT_COLOR.DEFAULT[4])
        column.style:SetFontSize(FONT_SIZE.LARGE)

        helpers.DrawListCtrlColumnSperatorLine(column, #columns, i)

        function column.OnEnter(self)
            self.style:SetColor(FONT_COLOR.DEFAULT[1], FONT_COLOR.DEFAULT[2],
                                FONT_COLOR.DEFAULT[3], FONT_COLOR.DEFAULT[4])
        end
        column:SetHandler("OnEnter", column.OnEnter)

        function column.OnLeave(self)
            self.style:SetColor(FONT_COLOR.DEFAULT[1], FONT_COLOR.DEFAULT[2],
                                FONT_COLOR.DEFAULT[3], FONT_COLOR.DEFAULT[4])
        end
        column:SetHandler("OnLeave", column.OnLeave)
    end
end

helpers.BUTTON_ICON = {
    PORTAL_DELETE = {
        drawableType = "icon",
        path = "ui/button/icon_shape/wastebasket.dds"
    },
    PORTAL_RENAME = {
        drawableType = "icon",
        path = "ui/button/icon_shape/pencil.dds"
    },
    DEFAULT = {
        path = "ui/common/default.dds",
        fontColor = {
            normal = {0.407843, 0.266667, 0.0705882, 1},
            pushed = {0.407843, 0.266667, 0.0705882, 1},
            highlight = {0.603922, 0.376471, 0.0627451, 1},
            disabled = {0.360784, 0.360784, 0.360784, 1}
        },
        coords = {
            normal = {727, 247, 60, 25},
            disable = {788, 273, 60, 25},
            over = {727, 273, 60, 25},
            click = {788, 247, 60, 25}
        },
        fontInset = {top = 0, right = 11, left = 11, bottom = 0},
        width = 28,
        height = 28,
        autoResize = true,
        drawableType = "drawable",
        coordsKey = "btn"
    },
    MAIN_MENU_MAP = {
        drawableType = "drawable",
        path = TEXTURE_PATH.HUD,
        coords = {
            normal = {893, 231, 32, 32},
            over = {926, 231, 32, 32},
            click = {959, 231, 32, 32},
            disable = {992, 231, 32, 32}
        },
        width = 32,
        height = 32
    },
    MAIN_MENU_ADDITONAL = {
        drawableType = "drawable",
        path = TEXTURE_PATH.ADDITIONAL_MAIN_MENU,
        coordsKey = "house"
    },
    INGAMESHOP_COMMERCIAL_MAIL = {
        drawableType = "drawable",
        path = TEXTURE_PATH.INGAME_SHOP,
        coords = {
            normal = {787, 196, 46, 36},
            over = {833, 196, 46, 36},
            click = {879, 196, 46, 36},
            disable = {925, 196, 46, 36}
        },
        width = 46,
        height = 36
    }
}

function table.removekey(table, key)
    local element = table[key]
    table[key] = nil
    return element
end
-- trim string function 
function string.trim(s) return (s:gsub("^%s*(.-)%s*$", "%1")) end
function string.split(input, delimiter)
    local result = {}
    local pattern = string.format("([^%s]+)", delimiter)
    for word in string.gmatch(input, pattern) do
        table.insert(result, string.trim(word))
    end
    return result
end

function helpers.reverseTable(tab)
    for i = 1, math.floor(#tab / 2), 1 do
        tab[i], tab[#tab - i + 1] = tab[#tab - i + 1], tab[i]
    end
    return tab
end

function helpers.getShareLink(data)
    local data = string.format("[Navigate:%s,%s]", data.name,
                               helpers.sextantToString(data.sextant))
    return data
end

local coordCoef = 0.00097657363894522145695357130138029
function helpers.latitudeSextantToDegrees(direction, degrees, minutes, seconds)
    local yCoords = 0
    yCoords = seconds / 60
    yCoords = (yCoords + minutes) / 60
    yCoords = degrees + yCoords
    if direction == "S" then yCoords = yCoords * -1 end
    return (yCoords + 28) / coordCoef

end
function helpers.longitudeSextantToDegrees(direction, degrees, minutes, seconds)
    local xCoords = 0
    xCoords = seconds / 60
    xCoords = (xCoords + minutes) / 60
    xCoords = degrees + xCoords
    if direction == "W" then xCoords = xCoords * -1 end
    return (xCoords + 21) / coordCoef
end

function helpers.sextantToString(s)
    return table.concat({
        s.longitude, s.deg_long, s.min_long, s.sec_long, s.latitude, s.deg_lat,
        s.min_lat, s.sec_lat
    }, "|")
end

function helpers.sextantFromString(str)
    local parts = {}
    for part in string.gmatch(str, "([^|]+)") do table.insert(parts, part) end

    return {
        longitude = parts[1],
        deg_long = tonumber(parts[2]),
        min_long = tonumber(parts[3]),
        sec_long = tonumber(parts[4]),
        latitude = parts[5],
        deg_lat = tonumber(parts[6]),
        min_lat = tonumber(parts[7]),
        sec_lat = tonumber(parts[8])
    }
end

function helpers.calcDistanceBetweenSextants(sex1, sex2)
    local x1 = helpers.longitudeSextantToDegrees(sex1.longitude, sex1.deg_long,
                                                 sex1.min_long, sex1.sec_long)
    local y1 = helpers.latitudeSextantToDegrees(sex1.latitude, sex1.deg_lat,
                                                sex1.min_lat, sex1.sec_lat)

    local x2 = helpers.longitudeSextantToDegrees(sex2.longitude, sex2.deg_long,
                                                 sex2.min_long, sex2.sec_long)
    local y2 = helpers.latitudeSextantToDegrees(sex2.latitude, sex2.deg_lat,
                                                sex2.min_lat, sex2.sec_lat)

    -- Расчёт расстояния
    local dx = x2 - x1
    local dy = y2 - y1
    local distance = math.sqrt(dx * dx + dy * dy)
    return tonumber(string.format("%.1f", distance))
end

function helpers.getDate(timestamp)
    local settings = helpers.getSettings()
    local timestamp = timestamp or api.Time:GetLocalTime()
    local timezone_offset = settings.timezone_offset * 3600
    local localTimestamp = X2Util:StrNumericAdd(tostring(timestamp),
                                                tostring(timezone_offset))

    -- Количество секунд в сутках
    local secondsInADay = "86400"

    -- Вычисляем количество дней, прошедших с 1 января 1970
    local daysSinceEpoch = tonumber(X2Util:DivideNumberString(localTimestamp,
                                                              secondsInADay))
    -- Определяем год
    local year = 1970
    while daysSinceEpoch >= 365 do
        -- Проверяем високосный год
        local isLeapYear = (year % 4 == 0 and year % 100 ~= 0) or
                               (year % 400 == 0)
        local daysInYear = isLeapYear and 366 or 365

        -- Если дней хватает на целый год, вычитаем его
        if daysSinceEpoch >= daysInYear then
            daysSinceEpoch = tonumber(X2Util:StrNumericSub(tostring(
                                                               daysSinceEpoch),
                                                           tostring(daysInYear)))
            year = year + 1
        else
            break
        end
    end

    -- Определяем месяц и день
    local month = 1
    local daysInMonth = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}

    -- Учитываем високосные годы
    if (year % 4 == 0 and year % 100 ~= 0) or (year % 400 == 0) then
        daysInMonth[2] = 29
    end

    while daysSinceEpoch >= daysInMonth[month] do
        daysSinceEpoch = tonumber(X2Util:StrNumericSub(tostring(daysSinceEpoch),
                                                       tostring(
                                                           daysInMonth[month])))
        month = month + 1
    end

    local day = X2Util:StrNumericAdd(tostring(daysSinceEpoch), "1") -- Дни считаются с 0, поэтому +1

    -- Вычисляем часы, минуты, секунды
    local fullDaysInSeconds = X2Util:StrIntegerMul(
                                  X2Util:DivideNumberString(localTimestamp,
                                                            secondsInADay),
                                  secondsInADay)
    local remainingSeconds = X2Util:StrNumericSub(localTimestamp,
                                                  fullDaysInSeconds)

    local hours = X2Util:DivideNumberString(remainingSeconds, "3600")
    local hoursInSeconds = X2Util:StrIntegerMul(hours, "3600")

    local minutes = X2Util:DivideNumberString(
                        X2Util:StrNumericSub(remainingSeconds, hoursInSeconds),
                        "60")
    local minutesInSeconds = X2Util:StrIntegerMul(minutes, "60")

    local seconds = X2Util:StrNumericSub(
                        X2Util:StrNumericSub(remainingSeconds, hoursInSeconds),
                        minutesInSeconds)

    local weekday = (tonumber(daysSinceEpoch) + 4) % 7

    -- Посчитаем день в году
    local dayOfYear = 0
    for m = 1, month - 1 do dayOfYear = dayOfYear + daysInMonth[m] end
    dayOfYear = dayOfYear + tonumber(day)

    -- Определяем день недели 1 января
    local jan1Weekday = (weekday - (dayOfYear % 7) + 7) % 7 -- День недели 1 января

    -- ISO-нумерация недель (первая неделя начинается с понедельника)
    local weekNumber = math.floor((dayOfYear + jan1Weekday - 1) / 7) + 1

    return {
        year = year,
        month = month,
        day = tonumber(day),
        hours = tonumber(hours),
        minutes = tonumber(minutes),
        seconds = tonumber(seconds),
        weekday = weekday,
        weekNumber = weekNumber, -- Номер недели
        dayOfYear = dayOfYear
    }
end

function helpers.getAngleToTarget(curX, curY, targetX, targetY)
    return math.atan2(targetY - curY, targetX - curX)
end

function helpers.getAngleOfMovement(prevX, prevY, curX, curY)
    return math.atan2(curY - prevY, curX - prevX)
end

-- Функция для вычисления угла между двумя векторами
function helpers.calcAngleBetweenVectors(x1, y1, x2, y2)
    local dotProduct = x1 * x2 + y1 * y2 -- Скалярное произведение
    local len1 = math.sqrt(x1 * x1 + y1 * y1) -- Длина первого вектора
    local len2 = math.sqrt(x2 * x2 + y2 * y2) -- Длина второго вектора
    local cosTheta = dotProduct / (len1 * len2) -- Косинус угла
    local angle = math.acos(cosTheta) -- Угол между векторами
    return angle -- Возвращаем угол в радианах
end

function helpers.getRelativeDirection(prevPos, curPos, targetPos)
    -- Преобразуем позиции в координаты
    local curX = helpers.longitudeSextantToDegrees(curPos.longitude,
                                                   curPos.deg_long,
                                                   curPos.min_long,
                                                   curPos.sec_long)
    local curY = helpers.latitudeSextantToDegrees(curPos.latitude,
                                                  curPos.deg_lat,
                                                  curPos.min_lat, curPos.sec_lat)
    local targetX = helpers.longitudeSextantToDegrees(targetPos.longitude,
                                                      targetPos.deg_long,
                                                      targetPos.min_long,
                                                      targetPos.sec_long)
    local targetY = helpers.latitudeSextantToDegrees(targetPos.latitude,
                                                     targetPos.deg_lat,
                                                     targetPos.min_lat,
                                                     targetPos.sec_lat)

    local prevX = helpers.longitudeSextantToDegrees(prevPos.longitude,
                                                    prevPos.deg_long,
                                                    prevPos.min_long,
                                                    prevPos.sec_long)
    local prevY = helpers.latitudeSextantToDegrees(prevPos.latitude,
                                                   prevPos.deg_lat,
                                                   prevPos.min_lat,
                                                   prevPos.sec_lat)

    -- Векторы
    local dx1, dy1 = curX - prevX, curY - prevY -- движение игрока
    local dx2, dy2 = targetX - curX, targetY - curY -- к цели

    -- Угол между ними
    local angle = helpers.calcAngleBetweenVectors(dx1, dy1, dx2, dy2)

    -- Переводим угол в градусы
    local degrees = math.deg(angle)

    -- Нормализуем угол в диапазон [0, 360)
    degrees = (degrees + 360) % 360

    return degrees
end

function helpers.getArrowByAngle(angle)
    -- Нормализуем угол в диапазон [0, 360)
    angle = angle % 360

    -- Устанавливаем порог для минимального отклонения (например, 15 градусов)
    local threshold = 15 -- в градусах

    -- Проверяем, в какой четверти находится угол
    if angle >= 337.5 or angle < 22.5 then
        return "↑" -- Север
    elseif angle < 67.5 then
        if angle < threshold then
            return "→" -- Восток
        else
            return "↗" -- Северо-восток
        end
    elseif angle < 112.5 then
        return "→" -- Восток
    elseif angle < 157.5 then
        if angle < threshold then
            return "→" -- Восток
        else
            return "↘" -- Юго-восток
        end
    elseif angle < 202.5 then
        return "↓" -- Юг
    elseif angle < 247.5 then
        if angle < threshold then
            return "←" -- Запад
        else
            return "↙" -- Юго-запад
        end
    elseif angle < 292.5 then
        return "←" -- Запад
    else
        return "MOVE" -- Северо-запад
    end
end

return helpers
