local DEFAULT_SETTINGS = {
    messages = {
        "Guild is recruiting! Looking for active players."
    },
    currentMsgIndex = 1,
    interval = 60,
    channel = "GFTest",
    enableAlliance = false,
    enableHorde = false
}

local DEFAULT_STATS = {
    sentMessages = 0
}

local PREFIX = "|cff00aeef[GFRecruit]|r "
local ADDON_PREFIX = "GFRecruit"

GFRecruitFrame = CreateFrame("Frame")
local recruitTicker = nil
local syncTicker = nil
local isInitialSyncPending = true

local registerSuccess = RegisterAddonMessagePrefix(ADDON_PREFIX)

local function GetCustomChannelId(targetName)
    if not targetName then return nil end
    targetName = string.lower(targetName)
    local i = 1
    while true do
        local channelName, header, _, channelNumber = GetChannelDisplayInfo(i)
        if not channelName then break end
        if not header and string.lower(channelName) == targetName then
            return channelNumber
        end
        i = i + 1
    end
    return nil
end

local function IsFactionEnabled()
    if not GF_Settings then return false end
    local playerFaction = UnitFactionGroup("player")
    
    if playerFaction == "Alliance" and GF_Settings.enableAlliance then
        return true
    elseif playerFaction == "Horde" and GF_Settings.enableHorde then
        return true
    end
    
    return false
end

function GFRecruit_SendAnnouncement()
    if not GF_Settings or not IsFactionEnabled() then 
        return 
    end

    local channelId = GetCustomChannelId(GF_Settings.channel)
    if channelId then
        local msgs = GF_Settings.messages
        if not msgs or #msgs == 0 then
            print(PREFIX .. "Error: No recruitment messages defined.")
            return
        end

        local idx = GF_Settings.currentMsgIndex or 1
        if idx > #msgs then idx = 1 end

        local msgToSend = msgs[idx]
        local currentTime = time()
        local playerName = UnitName("player")

        SendChatMessage(msgToSend, "CHANNEL", nil, channelId)
        
        -- Przejście do następnej wiadomości w kolejce
        GF_Settings.currentMsgIndex = (idx % #msgs) + 1

        GF_LastSendTime = currentTime
        GF_LastSender = playerName
        GF_Stats.sentMessages = (GF_Stats.sentMessages or 0) + 1
        
        local payload = tostring(currentTime) .. ":" .. tostring(playerName) .. ":" .. tostring(GF_Settings.currentMsgIndex)
        SendAddonMessage(ADDON_PREFIX, payload, "GUILD")

        print(PREFIX .. "Announcement [" .. idx .. "/" .. #msgs .. "] sent to channel: " .. GF_Settings.channel)
        
        if GFRecruitOptionsPanel and GFRecruitOptionsPanel:IsShown() and GFRecruitOptionsPanel.refresh then
            GFRecruitOptionsPanel.refresh()
        end
    else
        print(PREFIX .. "Error: Channel '" .. tostring(GF_Settings.channel) .. "' not found.")
    end
end

function GFRecruit_RestartTicker()
    if recruitTicker then
        recruitTicker:Cancel()
        recruitTicker = nil
    end

    if syncTicker then
        syncTicker:Cancel()
        syncTicker = nil
    end

    recruitTicker = C_Timer.NewTicker(30, function()
        if isInitialSyncPending then return end
        if GF_LastSendTime == nil or GF_Settings == nil then return end
        if not IsFactionEnabled() then return end

        local intervalInSeconds = (GF_Settings.interval or 60) * 60
        local currentTime = time()

        if (currentTime - GF_LastSendTime) >= intervalInSeconds then
            GFRecruit_SendAnnouncement()
        end
    end)

    syncTicker = C_Timer.NewTicker(300, function()
        if GF_LastSendTime and GF_LastSendTime > 0 and IsInGuild() then
            local playerName = UnitName("player")
            local payload = tostring(GF_LastSendTime) .. ":" .. tostring(GF_LastSender or playerName) .. ":" .. tostring(GF_Settings.currentMsgIndex or 1)
            SendAddonMessage(ADDON_PREFIX, payload, "GUILD")
        end
    end)
end

GFRecruitFrame:RegisterEvent("PLAYER_LOGIN")
GFRecruitFrame:RegisterEvent("CHAT_MSG_ADDON")

GFRecruitFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        if GF_LastSendTime == nil then GF_LastSendTime = 0 end
        if GF_LastSender == nil or GF_LastSender == "" then GF_LastSender = "N/A" end
        if GF_Settings == nil then GF_Settings = {} end
        if GF_Stats == nil then GF_Stats = {} end

        -- Migracja ze starego pola 'message' na tablicę 'messages'
        if GF_Settings.message and not GF_Settings.messages then
            GF_Settings.messages = { GF_Settings.message }
            GF_Settings.message = nil
        end

        for k, v in pairs(DEFAULT_SETTINGS) do
            if GF_Settings[k] == nil then GF_Settings[k] = v end
        end
        for k, v in pairs(DEFAULT_STATS) do
            if GF_Stats[k] == nil then GF_Stats[k] = v end
        end

        if GFRecruit_CreateOptionsPanel then
            GFRecruit_CreateOptionsPanel(DEFAULT_SETTINGS)
        end

        GFRecruit_RestartTicker()

        if IsInGuild() then
            SendAddonMessage(ADDON_PREFIX, "REQ_SYNC", "GUILD")
        end

        C_Timer.After(10, function()
            isInitialSyncPending = false
        end)

    elseif event == "CHAT_MSG_ADDON" then
        local prefix, message, channel, sender = ...
        
        if prefix ~= ADDON_PREFIX then return end

        local playerName = UnitName("player")
        
        local cleanSender = string.gsub(sender, "%-.*$", "")
        local cleanPlayer = string.gsub(playerName, "%-.*$", "")

        if string.lower(cleanSender) == string.lower(cleanPlayer) then 
            return 
        end

        if message == "REQ_SYNC" then
            if GF_LastSendTime and GF_LastSendTime > 0 and IsInGuild() then
                local payload = tostring(GF_LastSendTime) .. ":" .. tostring(GF_LastSender or playerName) .. ":" .. tostring(GF_Settings.currentMsgIndex or 1)
                SendAddonMessage(ADDON_PREFIX, payload, "GUILD")
            end
            return
        end

        local remoteTimeStr, senderFromPayload, nextIndexStr = string.match(message, "^(%d+):?([^:]*):?(%d*)$")
        local remoteTime = tonumber(remoteTimeStr)
        local remoteNextIndex = tonumber(nextIndexStr)
        
        local actualSender = (senderFromPayload and senderFromPayload ~= "") and senderFromPayload or cleanSender

        if remoteTime then
            if remoteTime > GF_LastSendTime then
                GF_LastSendTime = remoteTime
                GF_LastSender = actualSender
                if remoteNextIndex then
                    GF_Settings.currentMsgIndex = remoteNextIndex
                end
                
                if GFRecruitOptionsPanel and GFRecruitOptionsPanel:IsShown() and GFRecruitOptionsPanel.refresh then
                    GFRecruitOptionsPanel.refresh()
                end
            end
        end
    end
end)