local PREFIX = "|cff00aeef[GFRecruit]|r "

function GFRecruit_CreateOptionsPanel(defaultSettings)
    local panel = CreateFrame("Frame", "GFRecruitOptionsPanel", InterfaceOptionsFramePanelContainer)
    panel.name = "GF Recruitment"

    -- Główny ScrollFrame obejmujący cały panel opcji
    local mainScroll = CreateFrame("ScrollFrame", "GFRecruitMainScrollFrame", panel, "UIPanelScrollFrameTemplate")
    mainScroll:SetAllPoints(panel)

    local scrollChild = CreateFrame("Frame", "GFRecruitMainScrollChild", mainScroll)
    scrollChild:SetSize(panel:GetWidth() > 0 and panel:GetWidth() or 580, 1)
    mainScroll:SetScrollChild(scrollChild)

    local title = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("GF Recruitment - Options")

    -- 1. Etykieta listy wiadomości
    local msgLabel = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    msgLabel:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -12)
    msgLabel:SetText("Announcement messages list:")

    -- Kontener na dynamiczne wiersze wiadomości
    local msgContainer = CreateFrame("Frame", nil, scrollChild)
    msgContainer:SetPoint("TOPLEFT", msgLabel, "BOTTOMLEFT", 0, -8)
    msgContainer:SetSize(360, 1)

    -- Przycisk dodawania nowej wiadomości
    local addBtn = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
    addBtn:SetSize(130, 22)
    addBtn:SetText("+ Add Message")

    -- 2. Channel name
    local chanLabel = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    chanLabel:SetPoint("TOPLEFT", addBtn, "BOTTOMLEFT", 0, -12)
    chanLabel:SetText("Channel name (e.g. GFTest or Global):")

    local chanBox = CreateFrame("EditBox", nil, scrollChild, "InputBoxTemplate")
    chanBox:SetPoint("TOPLEFT", chanLabel, "BOTTOMLEFT", 5, -4)
    chanBox:SetSize(150, 20)
    chanBox:SetAutoFocus(false)

    -- 3. Interval
    local intLabel = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    intLabel:SetPoint("TOPLEFT", chanBox, "BOTTOMLEFT", -5, -10)
    intLabel:SetText("Send interval (in minutes):")

    local intBox = CreateFrame("EditBox", nil, scrollChild, "InputBoxTemplate")
    intBox:SetPoint("TOPLEFT", intLabel, "BOTTOMLEFT", 5, -4)
    intBox:SetSize(60, 20)
    intBox:SetAutoFocus(false)
    intBox:SetNumeric(true)

    -- 4. Faction Checkboxes
    local allyCheck = CreateFrame("CheckButton", "GF_AllyCheck", scrollChild, "UICheckButtonTemplate")
    allyCheck:SetPoint("TOPLEFT", intBox, "BOTTOMLEFT", -5, -10)
    local allyText = _G[allyCheck:GetName() .. "Text"]
    allyText:SetText("Enable for Alliance characters")
    allyText:SetTextColor(0, 0.68, 1)

    local hordeCheck = CreateFrame("CheckButton", "GF_HordeCheck", scrollChild, "UICheckButtonTemplate")
    hordeCheck:SetPoint("TOPLEFT", allyCheck, "BOTTOMLEFT", 0, -2)
    local hordeText = _G[hordeCheck:GetName() .. "Text"]
    hordeText:SetText("Enable for Horde characters")
    hordeText:SetTextColor(1, 0.2, 0.2)

    -- Status & Stats Labels
    local statusLabel = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    statusLabel:SetPoint("TOPLEFT", hordeCheck, "BOTTOMLEFT", 0, -10)

    local nextMsgLabel = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    nextMsgLabel:SetPoint("TOPLEFT", statusLabel, "BOTTOMLEFT", 0, -4)

    local senderLabel = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    senderLabel:SetPoint("TOPLEFT", nextMsgLabel, "BOTTOMLEFT", 0, -4)

    local statsSentLabel = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    statsSentLabel:SetPoint("TOPLEFT", senderLabel, "BOTTOMLEFT", 0, -8)

    local msgEntries = {}

    local function RefreshMessageRows()
        for _, entry in ipairs(msgEntries) do
            entry.frame:Hide()
        end

        local msgs = GF_Settings.messages or defaultSettings.messages
        if #msgs == 0 then
            msgs = CopyTable(defaultSettings.messages)
            GF_Settings.messages = msgs
        end

        local totalHeight = 0
        for i, text in ipairs(msgs) do
            if not msgEntries[i] then
                local row = CreateFrame("Frame", nil, msgContainer)
                row:SetSize(330, 42)

                local numLabel = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
                numLabel:SetPoint("TOPLEFT", row, "TOPLEFT", 2, 0)

                local eBox = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
                eBox:SetPoint("TOPLEFT", numLabel, "BOTTOMLEFT", 5, -2)
                eBox:SetSize(280, 20)
                eBox:SetAutoFocus(false)

                local delBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
                delBtn:SetPoint("LEFT", eBox, "RIGHT", 5, 0)
                delBtn:SetSize(22, 20)
                delBtn:SetText("X")

                msgEntries[i] = { frame = row, numLabel = numLabel, editBox = eBox, delBtn = delBtn }
            end

            local entry = msgEntries[i]
            entry.frame:SetPoint("TOPLEFT", msgContainer, "TOPLEFT", 0, -totalHeight)
            entry.numLabel:SetText("Message #" .. i .. ":")
            entry.editBox:SetText(text)
            entry.editBox:SetCursorPosition(0)

            entry.delBtn:SetScript("OnClick", function()
                table.remove(GF_Settings.messages, i)
                RefreshMessageRows()
            end)

            entry.frame:Show()
            totalHeight = totalHeight + 45
        end

        msgContainer:SetHeight(math.max(totalHeight, 1))

        addBtn:ClearAllPoints()
        if totalHeight > 0 then
            addBtn:SetPoint("TOPLEFT", msgContainer, "BOTTOMLEFT", 0, -4)
        else
            addBtn:SetPoint("TOPLEFT", msgContainer, "TOPLEFT", 0, 0)
        end

        -- Przeliczanie wysokości całego kontenera, żeby aktywować/dezaktywować scrollbar
        local contentBottom = statsSentLabel:GetBottom()
        local scrollChildTop = scrollChild:GetTop()
        if contentBottom and scrollChildTop then
            local calculatedHeight = (scrollChildTop - contentBottom) + 60
            scrollChild:SetHeight(math.max(calculatedHeight, 500))
        else
            scrollChild:SetHeight(500 + totalHeight)
        end
    end

    addBtn:SetScript("OnClick", function()
        GF_Settings.messages = GF_Settings.messages or {}
        table.insert(GF_Settings.messages, "New recruitment message...")
        RefreshMessageRows()
    end)

    local function LoadValues()
        RefreshMessageRows()

        chanBox:SetText(GF_Settings.channel or defaultSettings.channel)
        chanBox:SetCursorPosition(0)

        intBox:SetText(tostring(GF_Settings.interval or defaultSettings.interval))
        intBox:SetCursorPosition(0)

        allyCheck:SetChecked(GF_Settings.enableAlliance ~= false)
        hordeCheck:SetChecked(GF_Settings.enableHorde ~= false)

        local currentIdx = GF_Settings.currentMsgIndex or 1
        local totalMsgs = #(GF_Settings.messages or {})
        if currentIdx > totalMsgs then currentIdx = 1 end

        nextMsgLabel:SetText("Next msg index: " .. currentIdx .. " / " .. totalMsgs)

        if GF_LastSendTime and GF_LastSendTime > 0 then
            local formattedTime = date("%Y-%m-%d %H:%M:%S", GF_LastSendTime)
            local diffSeconds = math.max(0, time() - GF_LastSendTime)
            local diffMinutes = math.floor(diffSeconds / 60)

            statusLabel:SetText("Last sent: " .. formattedTime .. " (" .. diffMinutes .. " min ago)")
            senderLabel:SetText("Sent by: " .. tostring(GF_LastSender or "N/A"))
        else
            statusLabel:SetText("Last sent: No data (not sent yet)")
            senderLabel:SetText("Sent by: N/A")
        end

        statsSentLabel:SetText("Total messages sent: " .. (GF_Stats and GF_Stats.sentMessages or 0))
    end

    local function SaveValues()
        local newMsgs = {}
        for i, entry in ipairs(msgEntries) do
            if entry.frame:IsShown() then
                local txt = string.gsub(entry.editBox:GetText(), "^%s*(.-)%s*$", "%1")
                if txt ~= "" then
                    table.insert(newMsgs, txt)
                end
            end
        end

        if #newMsgs == 0 then
            newMsgs = CopyTable(defaultSettings.messages)
        end

        GF_Settings.messages = newMsgs
        if (GF_Settings.currentMsgIndex or 1) > #newMsgs then
            GF_Settings.currentMsgIndex = 1
        end

        GF_Settings.channel = chanBox:GetText()
        GF_Settings.enableAlliance = allyCheck:GetChecked()
        GF_Settings.enableHorde = hordeCheck:GetChecked()

        local val = tonumber(intBox:GetText())
        if val and val > 0 then
            GF_Settings.interval = val
        end

        print(PREFIX .. "Settings saved successfully.")
        LoadValues()
    end

    -- Save Button
    local saveBtn = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
    saveBtn:SetPoint("TOPLEFT", statsSentLabel, "BOTTOMLEFT", 0, -12)
    saveBtn:SetSize(100, 22)
    saveBtn:SetText("Save")
    saveBtn:SetScript("OnClick", SaveValues)

    -- Send Now Button
    local sendBtn = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
    sendBtn:SetPoint("LEFT", saveBtn, "RIGHT", 10, 0)
    sendBtn:SetSize(100, 22)
    sendBtn:SetText("Send Now")
    sendBtn:SetScript("OnClick", function()
        SaveValues()
        if GFRecruit_SendAnnouncement then
            GFRecruit_SendAnnouncement()
        end
    end)

    -- Reset Counter Button
    local resetBtn = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
    resetBtn:SetPoint("LEFT", sendBtn, "RIGHT", 10, 0)
    resetBtn:SetSize(110, 22)
    resetBtn:SetText("Reset Counter")
    resetBtn:SetScript("OnClick", function()
        GF_Stats.sentMessages = 0
        LoadValues()
        print(PREFIX .. "Sent counter reset.")
    end)

    LoadValues()

    panel.refresh = LoadValues
    panel.okay = SaveValues
    panel.default = function()
        GF_Settings = CopyTable(defaultSettings)
        LoadValues()
    end

    InterfaceOptions_AddCategory(panel)
end

SLASH_GFRECRUIT1 = "/gfr"
SlashCmdList["GFRECRUIT"] = function()
    if not InterfaceOptionsFrame:IsShown() then
        InterfaceOptionsFrame:Show()
    end
    InterfaceOptionsFrame_OpenToCategory(GFRecruitOptionsPanel)
    InterfaceOptionsFrame_OpenToCategory(GFRecruitOptionsPanel)
end