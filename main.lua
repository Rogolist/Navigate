local api = require("api")
local UI = require("Navigate/ui")
local helpers = require("Navigate/util/helpers")

local NavigateAddon = {
    name = "Navigate",
    author = "Misosoup",
    version = "1.1.0",
    desc = "Share points."
}

local lastUpdate = 0

local settings = {}

local function OnUpdate(dt)
    lastUpdate = lastUpdate + dt
    -- 20 is ok
    if lastUpdate < 200 then return end
    lastUpdate = dt

    if UI.TrackingData ~= nil then UI.UpdateTrackingData() end
end

NavigateAddon.Init = function() end

local function Load()
    -- Init canvas
    NavigateAddon.CANVAS = api.Interface:CreateEmptyWindow("Navigate")
    NavigateAddon.CANVAS:Show(true)
    NavigateAddon.CANVAS:Clickable(false)

    -- UI things
    UI.Init(NavigateAddon.CANVAS)

    api.Log:Info("Loaded " .. NavigateAddon.name .. " v" ..
                     NavigateAddon.version .. " by " .. NavigateAddon.author)
    api.On("UPDATE", OnUpdate)

end

local function Unload()
    UI.UnLoad()
    if NavigateAddon.CANVAS ~= nil then
        NavigateAddon.CANVAS:Show(false)
        NavigateAddon.CANVAS = nil
    end
end

local function OnChatMessage(channelId, speakerId, _, speakerName, message)

    local sharedCode = string.find(message, '[Navigate:', 1, true)
    -- TODO check if sender not player
    local unitId = api.Unit:GetUnitId('player')
    if sharedCode ~= nil then
        -- if sharedCode ~= nil and unitId ~= speakerId then
        local trimmed = string.trim(message:match("%[Navigate:(.+)%]"))
        if trimmed then
            UI.CreateIncomingShareWindow(speakerName, trimmed)
        end
    end
end

NavigateAddon.OnLoad = Load
NavigateAddon.OnUnload = Unload
NavigateAddon.OnChatMessage = OnChatMessage
api.On("CHAT_MESSAGE", OnChatMessage)

return NavigateAddon
