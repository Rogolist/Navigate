local api = require("api")
local helpers = require('Navigate/util/helpers')

local UI = {}
local settings = {}

local CANVAS, markButtonWnd, markButton, listButton, listWnd
local dataFileName = 'Navigate/data/items.lua'

UI.Init = function(cnv)
    CANVAS = cnv
    settings = helpers.getSettings()
    UI.CreateMainWindow()
    UI.CreateTrackWindow();
    UI.CreateList()
    UI.CreateShareWindow()
    UI.CreateNewPointWindow()
end

UI.CreateNewPointWindow = function()
    listWnd.newPointWnd = api.Interface:CreateWindow("newPointWnd", 'New point')
    listWnd.newPointWnd:AddAnchor("CENTER", "UIParent", 0, -150)
    listWnd.newPointWnd:SetExtent(300, 150)
    listWnd.newPointWnd:Show(false)

    -- label
    local label = helpers.createLabel('label', listWnd.newPointWnd,
                                      'Create new point on your current XY coordinates',
                                      0, 0)
    label.style:SetAlign(ALIGN.CENTER)
    label.style:SetFontSize(FONT_SIZE.MIDDLE)
    ApplyTextColor(label, FONT_COLOR.DEFAULT)
    label:RemoveAllAnchors()
    label:AddAnchor("CENTER", listWnd.newPointWnd, 0, -30)
    label:SetExtent(200, 30)

    -- name edit
    local nameField = helpers.createEdit('nameField', listWnd.newPointWnd,
                                         'Name', 0, 0)
    nameField.style:SetAlign(ALIGN.LEFT)
    ApplyTextColor(nameField, FONT_COLOR.DEFAULT)
    nameField:RemoveAllAnchors()
    nameField:AddAnchor("CENTER", label, 0, 30)
    nameField:SetExtent(200, 30)
    nameField:SetText('My awesome point')
    listWnd.newPointNameField = nameField

    -- save btn
    local saveButton = helpers.createButton('saveButton', listWnd.newPointWnd,
                                            'Save', 0, 0)
    saveButton:RemoveAllAnchors()
    saveButton:AddAnchor("CENTER", nameField, 0, 40)
    saveButton.style:SetAlign(ALIGN.CENTER)
    ApplyTextColor(saveButton, FONT_COLOR.DEFAULT)

    saveButton.OnClick = function() UI.SaveNewPoint() end
    saveButton:SetHandler('OnClick', saveButton.OnClick)
end

UI.CreateIncomingShareWindow = function(senderName, trimmed)

    local shareWnd = api.Interface:CreateWindow("shareWnd", 'New point')
    shareWnd:AddAnchor("CENTER", "UIParent", 0, -150)
    shareWnd:SetExtent(300, 160)
    shareWnd:Show(true)
    table.insert(listWnd.incomingShares, shareWnd)

    local unparse = string.split(trimmed, ',')
    local pointName = unparse[1]

    local sextant = helpers.sextantFromString(unparse[2])

    -- label with description
    local label = helpers.createLabel('shareLabel', shareWnd, 'Share a point',
                                      0, 0)
    label:RemoveAllAnchors()
    label:AddAnchor("CENTER", shareWnd, 0, -20)
    label.style:SetFontSize(FONT_SIZE.MIDDLE)
    label.style:SetAlign(ALIGN.CENTER)
    ApplyTextColor(label, FONT_COLOR.DEFAULT)
    label:SetText(senderName .. ' shared a point:')

    -- name label
    local name = helpers.createEdit('nameLabel', shareWnd, 'Name', 0, 0)
    name:RemoveAllAnchors()
    name:AddAnchor("CENTER", label, 0, 25)
    name.style:SetFontSize(FONT_SIZE.MIDDLE)
    -- name.style:SetAlign(ALIGN.CENTER)
    ApplyTextColor(name, FONT_COLOR.DEFAULT)
    name:SetText(pointName)
    name:SetEnable(false)
    name:SetReadOnly(true)
    name:SetExtent(270, 30)

    -- import button
    local importButton = helpers.createButton('importButton', shareWnd,
                                              'Import', 0, 0)
    importButton:RemoveAllAnchors()
    importButton:AddAnchor("BOTTOM", shareWnd, -45, -5)
    importButton.style:SetAlign(ALIGN.CENTER)
    ApplyTextColor(importButton, FONT_COLOR.DEFAULT)
    importButton:SetHandler("OnClick", function(self)
        UI.ImportPoint(pointName, sextant)
        shareWnd:Show(false)
    end)

    -- map button
    local mapButton = helpers.createButton('mapButton', shareWnd, 'Map', 0, 0)
    mapButton:RemoveAllAnchors()
    mapButton:AddAnchor("RIGHT", importButton, 90, 0)
    mapButton.style:SetAlign(ALIGN.CENTER)
    ApplyTextColor(mapButton, FONT_COLOR.DEFAULT)
    mapButton:SetHandler("OnClick", function(self)
        local xMap = helpers.longitudeSextantToDegrees(sextant.longitude,
                                                       sextant.deg_long,
                                                       sextant.min_long,
                                                       sextant.sec_long)
        local yMap = helpers.latitudeSextantToDegrees(sextant.latitude,
                                                      sextant.deg_lat,
                                                      sextant.min_lat,
                                                      sextant.sec_lat)

        api.Map:ToggleMapWithPortal(323, xMap, yMap, 100)

    end)

end

UI.CreateShareWindow = function()
    listWnd.shareWnd = api.Interface:CreateWindow("listWnd", 'Share a point')
    listWnd.shareWnd:AddAnchor("CENTER", "UIParent", 0, -150)
    listWnd.shareWnd:SetExtent(300, 150)

    local shareEdit =
        helpers.createEdit('shareEdit', listWnd.shareWnd, '', 0, 0)
    shareEdit:RemoveAllAnchors()
    shareEdit:AddAnchor("CENTER", listWnd.shareWnd, 0, 0)
    shareEdit.style:SetAlign(ALIGN.LEFT)
    ApplyTextColor(shareEdit, FONT_COLOR.DEFAULT)
    shareEdit:SetExtent(200, 30)
    listWnd.shareEdit = shareEdit
end

UI.UpdateWindowCoords = function(x, y)
    settings.MainWindowX = x
    settings.MainWindowY = y
    api.SaveSettings()
end

UI.UpdateTrackWindowCoords = function(x, y)
    settings.TrackWindowX = x
    settings.TrackWindowY = y
    api.SaveSettings()
end

UI.listControls = {}

UI.ListRowRenderFunc = function(frame, rowIndex, colIndex, subItem)

    -- check if listcontrols exist
    if UI.listControls[rowIndex] == nil then UI.listControls[rowIndex] = {} end

    -- name column
    if colIndex == 1 then
        local name = helpers.createEdit('nameEdit', subItem, '', 0, 0)
        name:RemoveAllAnchors()
        name:AddAnchor("CENTER", subItem, 0, 0)
        name.style:SetAlign(ALIGN.LEFT)
        ApplyTextColor(name, FONT_COLOR.DEFAULT)
        UI.listControls[rowIndex].name = name
    end
    -- actions column
    if colIndex == 2 then
        local coords = helpers.createEdit('coordsEdit', subItem, '', 0, 0)
        coords:RemoveAllAnchors()
        coords:AddAnchor("CENTER", subItem, 0, 0)
        coords.style:SetAlign(ALIGN.LEFT)
        ApplyTextColor(coords, FONT_COLOR.DEFAULT)
        UI.listControls[rowIndex].coords = coords
        UI.listControls[rowIndex].coords:Show(false)

        -- track button
        local trackButton = helpers.createButton('trackButton', subItem, '', 0,
                                                 0)
        api.Interface:ApplyButtonSkin(trackButton, BUTTON_CONTENTS.MAP_ENEMY_BTN)
        trackButton:RemoveAllAnchors()
        trackButton:AddAnchor("CENTER", subItem, -20, 0)
        trackButton.style:SetAlign(ALIGN.CENTER)
        ApplyTextColor(trackButton, FONT_COLOR.DEFAULT)
        trackButton:SetExtent(30, 30)
        local trackTooltip = helpers.createTooltip('trackTooltip', trackButton,
                                                   '', 0, -20)
        trackTooltip:SetInset(2, 2, 2, 2)
        function trackButton.OnEnter(self)
            trackTooltip:Show(true)
            trackTooltip:AddLine('Track', "", 0, "left", ALIGN.LEFT, 0)
        end
        trackButton:SetHandler("OnEnter", trackButton.OnEnter)
        function trackButton.OnLeave(self) trackTooltip:Show(false) end
        trackButton:SetHandler("OnLeave", trackButton.OnLeave)
        UI.listControls[rowIndex].trackButton = trackButton
        -- /track button

        -- share button
        local shareButton = helpers.createButton('shareButton', subItem, '', 0,
                                                 0)
        api.Interface:ApplyButtonSkin(shareButton, BUTTON_CONTENTS.REPORT)
        shareButton:RemoveAllAnchors()
        shareButton:AddAnchor("CENTER", trackButton, 30, 0)
        shareButton.style:SetAlign(ALIGN.CENTER)
        ApplyTextColor(shareButton, FONT_COLOR.DEFAULT)
        shareButton:SetExtent(30, 30)

        local shareTooltip = helpers.createTooltip('shareTooltip', shareButton,
                                                   '', 0, -20)
        shareTooltip:SetInset(2, 2, 2, 2)
        function shareButton.OnEnter(self)
            shareTooltip:Show(true)
            shareTooltip:AddLine('Share', "", 0, "left", ALIGN.LEFT, 0)
        end
        shareButton:SetHandler("OnEnter", shareButton.OnEnter)
        function shareButton.OnLeave(self) shareTooltip:Show(false) end
        shareButton:SetHandler("OnLeave", shareButton.OnLeave)
        UI.listControls[rowIndex].shareButton = shareButton
        -- /share button
    end
    -- distance column
    if colIndex == 3 then
        local distance = helpers.createLabel('distanceLabel', subItem, '', 0, 0)
        distance:RemoveAllAnchors()
        distance:AddAnchor("CENTER", subItem, 0, 0)
        distance.style:SetAlign(ALIGN.CENTER)
        distance.style:SetFontSize(FONT_SIZE.MIDDLE)
        ApplyTextColor(distance, FONT_COLOR.DEFAULT)
        UI.listControls[rowIndex].distance = distance
    end
    -- status column
    if colIndex == 4 then
        local status = helpers.createLabel('statusLabel', subItem, '', 0, 0)
        status:RemoveAllAnchors()
        status:AddAnchor("CENTER", subItem, 0, 0)
        status.style:SetAlign(ALIGN.CENTER)
        status.style:SetFontSize(FONT_SIZE.MIDDLE)
        ApplyTextColor(status, FONT_COLOR.DEFAULT)
        UI.listControls[rowIndex].status = status
    end
    -- map column
    if colIndex == 5 then
        local map = helpers.createButton('mapButton', subItem, '', 0, 0)
        api.Interface:ApplyButtonSkin(map, BUTTON_CONTENTS.MAP_OPEN)
        map:RemoveAllAnchors()
        map:AddAnchor("CENTER", subItem, 0, 0)
        map.style:SetAlign(ALIGN.CENTER)
        ApplyTextColor(map, FONT_COLOR.DEFAULT)
        UI.listControls[rowIndex].map = map
    end
    -- options column
    if colIndex == 6 then
        -- update button
        local updateButton = helpers.createButton('updateButton', subItem, '',
                                                  0, 0)
        api.Interface:ApplyButtonSkin(updateButton, BUTTON_CONTENTS.MAP_LINE_BTN)
        updateButton:RemoveAllAnchors()
        updateButton:AddAnchor("CENTER", subItem, -20, 0)
        updateButton.style:SetAlign(ALIGN.CENTER)
        ApplyTextColor(updateButton, FONT_COLOR.DEFAULT)
        updateButton:SetExtent(30, 30)
        local updTooltip = helpers.createTooltip('updateTooltip', updateButton,
                                                 '', 0, -20)
        updTooltip:SetInset(2, 2, 2, 2)
        function updateButton.OnEnter(self)
            updTooltip:Show(true)
            updTooltip:AddLine('Update/Save', "", 0, "left", ALIGN.LEFT, 0)
        end
        updateButton:SetHandler("OnEnter", updateButton.OnEnter)
        function updateButton.OnLeave(self) updTooltip:Show(false) end
        updateButton:SetHandler("OnLeave", updateButton.OnLeave)
        UI.listControls[rowIndex].updateButton = updateButton
        -- /update button

        -- delete button
        local deleteButton = helpers.createButton('deleteButton', subItem, '',
                                                  0, 0)
        api.Interface:ApplyButtonSkin(deleteButton,
                                      BUTTON_CONTENTS.SKILL_ABILITY_DELETE)
        deleteButton:RemoveAllAnchors()
        deleteButton:AddAnchor("CENTER", updateButton, 30, 0)
        deleteButton.style:SetAlign(ALIGN.CENTER)
        ApplyTextColor(deleteButton, FONT_COLOR.DEFAULT)
        deleteButton:SetExtent(30, 30)
        local deleteTooltip = helpers.createTooltip('deleteTooltip',
                                                    deleteButton, '', 0, -20)
        deleteTooltip:SetInset(2, 2, 2, 2)
        function deleteButton.OnEnter(self)
            deleteTooltip:Show(true)
            deleteTooltip:AddLine('Delete', "", 0, "left", ALIGN.LEFT, 0)
        end
        deleteButton:SetHandler("OnEnter", deleteButton.OnEnter)
        function deleteButton.OnLeave(self) deleteTooltip:Show(false) end
        deleteButton:SetHandler("OnLeave", deleteButton.OnLeave)
        UI.listControls[rowIndex].deleteButton = deleteButton
        -- /delete button
    end

end

UI.ListRowSetFunc = function(subItem, data, setValue)
    if setValue then
        -- Data Assignments
        local index = data.index

        UI.listControls[index].name:SetText(data.name)

        local coords = helpers.sextantToString(data.sextant)
        UI.listControls[index].coords:SetText(coords)
        UI.listControls[index].coords:SetEnable(false)
        UI.listControls[index].coords:SetReadOnly(true)
        UI.listControls[index].distance:SetText(data.distance)
        UI.listControls[index].status:SetText(data.status)

        local updateButton = UI.listControls[index].updateButton
        function updateButton.OnClick(self)
            UI.SaveButtonClicked(data.realIndex, data.index)
        end
        updateButton:SetHandler("OnClick", updateButton.OnClick)

        local shareButton = UI.listControls[index].shareButton
        function shareButton.OnClick(self)
            UI.ShareButtonClicked(data.realIndex)
        end
        shareButton:SetHandler("OnClick", shareButton.OnClick)

        local deleteButton = UI.listControls[index].deleteButton
        function deleteButton.OnClick(self)
            UI.DeleteListItem(data.realIndex, data.index)
        end
        deleteButton:SetHandler("OnClick", deleteButton.OnClick)

        local mapButton = UI.listControls[index].map
        function mapButton.OnClick(self)
            UI.MapButtonClicked(data.realIndex)
        end
        mapButton:SetHandler("OnClick", mapButton.OnClick)

        local trackButton = UI.listControls[index].trackButton
        function trackButton.OnClick(self)
            UI.TrackButtonClicked(data.realIndex)
        end
        trackButton:SetHandler('OnClick', trackButton.OnClick)

        -- date tooltip
        local dateTooltip = helpers.createTooltip('dateTooltip', subItem, '', 0,
                                                  0)
        dateTooltip:RemoveAllAnchors()
        dateTooltip:AddAnchor('CENTER', subItem, 20, -30)
        UI.listControls[index].dateTooltip = dateTooltip

        function subItem.OnEnter(self)
            local date = helpers.getDate(data.timestamp)
            dateTooltip:ClearLines()
            dateTooltip:AddLine(string.format(
                                    'Created at: %02d.%02d.%d %02d:%02d',
                                    date.day, date.month, date.year, date.hours,
                                    date.minutes), "", 0, "left", ALIGN.LEFT, 0)
            dateTooltip:Show(true)
        end
        subItem:SetHandler("OnEnter", subItem.OnEnter)
        function subItem.OnLeave(self) dateTooltip:Show(false) end
        subItem:SetHandler("OnLeave", subItem.OnLeave)

    end
end

local pageSize = 8
UI.listItems = {}
UI.unsavedItems = {}
UI.fillListWithData = function(listCtrl, pageIndex)
    local startingIndex = 1
    if pageIndex > 1 then startingIndex = ((pageIndex - 1) * pageSize) + 1 end

    listCtrl:ResetScroll(0)
    listCtrl:DeleteAllDatas()

    local indexCount = 1
    local endingIndex = startingIndex + pageSize
    UI.listItems = {}

    local savedItems = UI.GetSavedItems()
    savedItems = helpers.reverseTable(savedItems)

    local curCoords = api.Map.GetPlayerSextants();

    for i = 1, #savedItems do
        local curElem = savedItems[i]

        -- calc distance between points
        local distance = helpers.calcDistanceBetweenSextants(curCoords,
                                                             curElem.sextant)

        local itemData = {
            name = curElem.name,
            sextant = curElem.sextant,
            realIndex = #savedItems + 1 - i,
            distance = distance .. ' m',
            timestamp = curElem.timestamp,
            status = 'Saved',
            -- Required fields 
            isViewData = true,
            isAbstention = false
        }
        table.insert(UI.listItems, itemData)
        if i >= startingIndex and i < endingIndex then
            itemData.index = indexCount
            listCtrl:InsertData(i, 1, itemData)
            indexCount = indexCount + 1
        end

    end

end

-- CLICKS EVENTS
UI.DeleteListItem = function(realIndex, index)
    local cur = UI.listItems[#UI.listItems + 1 - realIndex]

    local savedData = UI.GetSavedItems()

    if savedData[realIndex] ~= nil then
        table.remove(savedData, realIndex)
        UI.SaveItems(savedData)

        -- reloading list
        local curPage = UI.listCtrl.pageControl:GetCurrentPageIndex()

        UI.fillListWithData(UI.listCtrl, 1)

        if UI.listItems ~= nil then
            UI.maxPage = math.ceil(#UI.listItems / pageSize)
        else
            UI.maxPage = 1
        end

        if curPage > UI.maxPage then curPage = curPage - 1 end

        UI.listCtrl.pageControl.maxPage = UI.maxPage or 1

        UI.listCtrl.pageControl:SetCurrentPage(curPage, true)

    end
end

UI.ShareButtonClicked = function(realIndex)
    local cur = UI.listItems[#UI.listItems + 1 - realIndex]
    local data = {name = cur.name, sextant = cur.sextant}
    listWnd.shareEdit:SetText(helpers.getShareLink(data))
    listWnd.shareWnd:Show(true)
end

UI.GetSavedItems = function(reverse)
    if reverse == nil then reverse = false end
    local savedData = api.File:Read(dataFileName)
    return savedData or {}
end

UI.SaveItems = function(items) api.File:Write(dataFileName, items) end

UI.SaveButtonClicked = function(realIndex, index)
    local cur = UI.listItems[#UI.listItems + 1 - realIndex]

    local data = {name = cur.name, sextant = cur.sextant}

    -- check for values changes
    local name = UI.listControls[index].name:GetText()
    data.name = name
    data.sextant = helpers.sextantFromString(
                       UI.listControls[index].coords:GetText())

    local savedData = UI.GetSavedItems()

    local existingData = savedData[realIndex]

    if existingData then
        for i = 1, #savedData do
            if i == realIndex then savedData[i] = data end
        end
    else
        table.insert(savedData, data)
    end
    UI.SaveItems(savedData)
    local curPage = UI.listCtrl.pageControl:GetCurrentPageIndex()
    UI.fillListWithData(UI.listCtrl, curPage)
    api.Log:Info('Saved point with name "' .. data.name .. '"')
end

UI.ImportPoint = function(pointName, sextant)
    local data = {
        name = pointName,
        sextant = sextant,
        timestamp = api.Time:GetLocalTime()
    }
    local savedData = UI.GetSavedItems()
    table.insert(savedData, data)
    UI.SaveItems(savedData)
    api.Log:Info('Saved point with name "' .. data.name .. '"')

    -- reloading list
    UI.fillListWithData(UI.listCtrl, 1)

    if UI.listItems ~= nil then
        UI.maxPage = math.ceil(#UI.listItems / pageSize)
    else
        UI.maxPage = 1
    end

    UI.listCtrl.pageControl.maxPage = UI.maxPage or 1

    UI.listCtrl.pageControl:SetCurrentPage(1, true)

end

UI.MapButtonClicked = function(realIndex)
    local cur = UI.listItems[#UI.listItems + 1 - realIndex]
    local data = {name = cur.name, sextant = cur.sextant}

    local xMap = helpers.longitudeSextantToDegrees(data.sextant.longitude,
                                                   data.sextant.deg_long,
                                                   data.sextant.min_long,
                                                   data.sextant.sec_long)
    local yMap = helpers.latitudeSextantToDegrees(data.sextant.latitude,
                                                  data.sextant.deg_lat,
                                                  data.sextant.min_lat,
                                                  data.sextant.sec_lat)

    api.Map:ToggleMapWithPortal(323, xMap, yMap, 100)
end

-- REAL TIME TRACKING
UI.TrackingData = nil
UI.TrackButtonClicked = function(realIndex)
    local cur = UI.listItems[#UI.listItems + 1 - realIndex]
    UI.TrackingData = {name = cur.name, sextant = cur.sextant, cur.timestamp}
    UI.trackWindow:Show(true)
end
UI.prevPlayerPos = nil
UI.UpdateTrackingData = function()
    local curCoords = api.Map.GetPlayerSextants();
    local distance = helpers.calcDistanceBetweenSextants(curCoords,
                                                         UI.TrackingData.sextant)

    -- стрелка
    local arrow = ''
    if UI.prevPlayerPos then
        local angle = helpers.getRelativeDirection(UI.prevPlayerPos, curCoords,
                                                   UI.TrackingData.sextant)
        arrow = helpers.getArrowByAngle(angle)
    end

    -- сохранить текущие координаты для следующего обновления
    UI.prevPlayerPos = curCoords

    UI.trackWindow.markNameLabel:SetText(UI.TrackingData.name)
    UI.trackWindow.distanceLabel:SetText(
        string.format("%s %.1f m", arrow, distance))

    -- UI.trackWindow.distanceLabel:SetEffectRotate(40, 0, 0)
    UI.trackWindow.distanceLabel:SetMoveEffectType(1, "circle", 0, 0, 0.3, 0.2)
    UI.trackWindow.distanceLabel:SetMoveEffectCircle(1, 0, -40)
    UI.trackWindow.distanceLabel.style:SetFontSize(60)

end

UI.SaveNewPoint = function()
    local sextant = api.Map:GetPlayerSextants()
    local name = listWnd.newPointNameField:GetText()
    UI.ImportPoint(name, sextant)
    listWnd.newPointWnd:Show(false)
    listWnd.newPointNameField:SetText('My awesome point')
end

-- /CLICKS EVENTS

UI.listCtrl = nil
UI.CreateList = function()
    listWnd = api.Interface:CreateWindow("listWnd", 'Saved points')
    listWnd:AddAnchor("CENTER", 'UIParent', 0, 0)
    listWnd.bg = listWnd:CreateNinePartDrawable(TEXTURE_PATH.HUD, "background")
    listWnd.bg:SetTextureInfo("bg_quest")
    listWnd.bg:SetColor(0, 0, 0, 0.5)
    listWnd.bg:AddAnchor("TOPLEFT", listWnd, 0, 0)
    listWnd.bg:AddAnchor("BOTTOMRIGHT", listWnd, 0, 0)
    listWnd:SetExtent(800, 500)
    listWnd.incomingShares = {}

    UI.listCtrl = W_CTRL.CreatePageScrollListCtrl("listCtrl", listWnd)
    UI.listCtrl:RemoveAllAnchors()

    local wndWidth = listWnd:GetWidth()
    local wndHeight = listWnd:GetHeight()

    UI.listCtrl:SetExtent(wndWidth, 400)
    UI.listCtrl:AddAnchor("TOP", listWnd, -5, 40)
    UI.listCtrl.scroll:Show(false)

    local columnsCount = 6
    helpers.insertColumns(UI.listCtrl, {
        {
            width = wndWidth / columnsCount,
            text = "Name",
            setFunc = UI.ListRowSetFunc,
            func = UI.ListRowRenderFunc
        }, {
            width = wndWidth / columnsCount,
            text = "Actions",
            setFunc = UI.ListRowSetFunc,
            func = UI.ListRowRenderFunc
        }, {
            width = wndWidth / columnsCount,
            text = "Distance",
            setFunc = UI.ListRowSetFunc,
            func = UI.ListRowRenderFunc
        }, {
            width = wndWidth / columnsCount,
            text = "Status",
            setFunc = UI.ListRowSetFunc,
            func = UI.ListRowRenderFunc
        }, {
            width = wndWidth / columnsCount,
            text = "Map",
            setFunc = UI.ListRowSetFunc,
            func = UI.ListRowRenderFunc
        }, {
            width = wndWidth / columnsCount,
            text = "Options",
            setFunc = UI.ListRowSetFunc,
            func = UI.ListRowRenderFunc
        }
    })

    UI.listCtrl:InsertRows(pageSize, false)
    UI.listCtrl.listCtrl:DisuseSorting()
    helpers.DrawListCtrlUnderLine(UI.listCtrl)
    UI.listCtrl.listCtrl:UseOverClickTexture()

    UI.fillListWithData(UI.listCtrl, 1)

    if UI.listItems ~= nil then
        UI.maxPage = math.ceil(#UI.listItems / pageSize)
    else
        UI.maxPage = 1
    end

    UI.listCtrl.pageControl.maxPage = UI.maxPage or 1

    UI.listCtrl.pageControl:SetCurrentPage(1, true)
    function UI.listCtrl:OnPageChangedProc(pageIndex)
        UI.fillListWithData(UI.listCtrl, pageIndex)
    end
end
UI.ShowList = function()
    if listWnd ~= nil then
        UI.fillListWithData(UI.listCtrl, 1)
        listWnd:Show(true)
    end

end

-- Create the main button
UI.CreateMainWindow = function()
    markButtonWnd = api.Interface:CreateEmptyWindow("markButtonWnd")

    markButtonWnd:AddAnchor("TOPLEFT", "UIParent", settings.MainWindowX,
                            settings.MainWindowY)
    markButtonWnd.bg = markButtonWnd:CreateNinePartDrawable(TEXTURE_PATH.HUD,
                                                            "background")
    markButtonWnd.bg:SetTextureInfo("bg_quest")
    markButtonWnd.bg:SetColor(0, 0, 0, 0.5)
    markButtonWnd.bg:AddAnchor("TOPLEFT", markButtonWnd, 0, 0)
    markButtonWnd.bg:AddAnchor("BOTTOMRIGHT", markButtonWnd, 0, 0)
    markButtonWnd:SetExtent(100, 80)
    markButtonWnd:Show(true)

    -- drag events for main window
    function markButtonWnd:OnDragStart(arg)
        markButtonWnd:StartMoving()
        api.Cursor:ClearCursor()
        api.Cursor:SetCursorImage(CURSOR_PATH.MOVE, 0, 0)
    end
    function markButtonWnd:OnDragStop()
        markButtonWnd:StopMovingOrSizing()
        local x, y = markButtonWnd:GetEffectiveOffset()
        api.Cursor:ClearCursor()
        UI.UpdateWindowCoords(x, y)
    end

    markButtonWnd:SetHandler("OnDragStart", markButtonWnd.OnDragStart)
    markButtonWnd:SetHandler("OnDragStop", markButtonWnd.OnDragStop)

    if markButtonWnd.RegisterForDrag ~= nil then
        markButtonWnd:RegisterForDrag("LeftButton")
    end
    if markButtonWnd.EnableDrag ~= nil then markButtonWnd:EnableDrag(true) end
    -- /drag events for main window

    markButton = helpers.createButton("markButton", markButtonWnd, "Point", 20,
                                      10)
    markButton:SetExtent(55, 26)
    function markButton:OnClick() listWnd.newPointWnd:Show(true) end
    markButton:SetHandler('OnClick', markButton.OnClick)

    listButton = helpers.createButton("listButton", markButtonWnd, "List", 20,
                                      40)
    listButton:SetExtent(55, 26)
    function listButton:OnClick() UI.ShowList() end
    listButton:SetHandler('OnClick', listButton.OnClick)

end

-- Create track window
UI.CreateTrackWindow = function()
    UI.trackWindow = api.Interface:CreateEmptyWindow("trackWindow")
    UI.trackWindow:AddAnchor("TOPLEFT", "UIParent", settings.TrackWindowX,
                             settings.TrackWindowY)
    UI.trackWindow.bg = UI.trackWindow:CreateNinePartDrawable(TEXTURE_PATH.HUD,
                                                              "background")
    UI.trackWindow.bg:SetTextureInfo("bg_quest")
    UI.trackWindow.bg:SetColor(0, 0, 0, 0.5)
    UI.trackWindow.bg:AddAnchor("TOPLEFT", UI.trackWindow, 0, 0)
    UI.trackWindow.bg:AddAnchor("BOTTOMRIGHT", UI.trackWindow, 0, 0)
    UI.trackWindow:SetExtent(150, 150)
    UI.trackWindow:Show(false)

    -- drag events for track window
    function UI.trackWindow:OnDragStart(arg)
        UI.trackWindow:StartMoving()
        api.Cursor:ClearCursor()
        api.Cursor:SetCursorImage(CURSOR_PATH.MOVE, 0, 0)
    end
    function UI.trackWindow:OnDragStop()
        UI.trackWindow:StopMovingOrSizing()
        local x, y = UI.trackWindow:GetEffectiveOffset()
        api.Cursor:ClearCursor()
        UI.UpdateTrackWindowCoords(x, y)
    end

    UI.trackWindow:SetHandler("OnDragStart", UI.trackWindow.OnDragStart)
    UI.trackWindow:SetHandler("OnDragStop", UI.trackWindow.OnDragStop)

    if UI.trackWindow.RegisterForDrag ~= nil then
        UI.trackWindow:RegisterForDrag("LeftButton")
    end
    if UI.trackWindow.EnableDrag ~= nil then UI.trackWindow:EnableDrag(true) end
    -- /drag events for track window

    -- close button
    UI.trackWindow.closeBtn = UI.trackWindow:CreateChildWidget("button",
                                                               "closeBtn", 0,
                                                               true)
    UI.trackWindow.closeBtn:AddAnchor("TOPRIGHT", UI.trackWindow, -10, 5)
    api.Interface:ApplyButtonSkin(UI.trackWindow.closeBtn,
                                  BUTTON_BASIC.WINDOW_SMALL_CLOSE)
    UI.trackWindow.closeBtn:Show(true)
    UI.trackWindow.OnClose = nil

    function UI.trackWindow.OnClose(button, clicktype)
        UI.trackWindow:Show(false)
        UI.TrackingData = nil
    end

    UI.trackWindow.closeBtn:SetHandler("OnClick", UI.trackWindow.OnClose)

    -- labels
    local trackingLabel = helpers.createLabel('trackingLabel', UI.trackWindow,
                                              'Tracking:', 0, 0)
    trackingLabel:RemoveAllAnchors()
    trackingLabel:AddAnchor('TOPLEFT', UI.trackWindow, 20, 30)
    ApplyTextColor(trackingLabel, FONT_COLOR.WHITE)

    -- mark name label
    local markNameLabel = helpers.createLabel('markNameLabel', UI.trackWindow,
                                              'undefined point', 0, 0)
    markNameLabel:RemoveAllAnchors()
    markNameLabel:AddAnchor('CENTER', trackingLabel, 0, 20)
    ApplyTextColor(markNameLabel, FONT_COLOR.WHITE)
    UI.trackWindow.markNameLabel = markNameLabel

    -- distance label
    local distanceLabel = helpers.createLabel('distanceLabel', UI.trackWindow,
                                              '100.3 m', 0, 0)
    distanceLabel:RemoveAllAnchors()
    distanceLabel:AddAnchor('CENTER', markNameLabel, 0, 40)
    ApplyTextColor(distanceLabel, FONT_COLOR.WHITE)
    UI.trackWindow.distanceLabel = distanceLabel

end

UI.UnLoad = function()
    if markButtonWnd ~= nil then
        markButtonWnd:Show(false)
        markButtonWnd = nil
    end
    if UI.trackWindow ~= nil then
        UI.trackWindow:Show(false)
        UI.trackWindow = nil
    end
    if listWnd ~= nil then
        listWnd:ReleaseHandler("OnEvent")
        if listWnd.shareWnd ~= nil then
            listWnd.shareWnd:Show(false)
            listWnd.shareWnd = nil
        end
        if listWnd.newPointWnd ~= nil then
            listWnd.newPointWnd:Show(false)
            listWnd.newPointWnd = nil
        end
        if listWnd.incomingShares ~= nil then
            for i = 1, #listWnd.incomingShares do
                listWnd.incomingShares[i]:Show(false)
                listWnd.incomingShares[i] = nil
            end
        end
        listWnd:Show(false)
        listWnd = nil
    end
end

return UI
