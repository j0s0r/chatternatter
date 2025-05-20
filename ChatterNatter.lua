-- ChatterNatter.lua
local addonName, addon = ...

local DEFAULTS = addon.DEFAULTS

local function GetSettings()
    return ChatterNatter_Settings or DEFAULTS
end

-- Copy button with popup functionality
local function AddCopyButton(chatFrame)
    if chatFrame.copyButton then return end
    
    -- Create the copy button
    local button = CreateFrame("Button", nil, chatFrame)
    button:SetSize(20, 20)
    button:SetPoint("TOPRIGHT", chatFrame, "TOPRIGHT", 0, 0)
    button:SetNormalTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")
    button:SetPushedTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Down")
    button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    button:SetAlpha(0.3)
    
    -- Create popup frame (only once)
    if not _G["ChatterNatterCopyFrame"] then
        local copyFrame = CreateFrame("Frame", "ChatterNatterCopyFrame", UIParent, "BackdropTemplate")
        copyFrame:SetSize(500, 400)
        copyFrame:SetPoint("CENTER", UIParent, "CENTER")
        copyFrame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 }
        })
        copyFrame:SetBackdropColor(0, 0, 0, 1)
        copyFrame:EnableMouse(true)
        copyFrame:SetMovable(true)
        copyFrame:SetClampedToScreen(true)
        copyFrame:SetFrameStrata("DIALOG")
        copyFrame:Hide()
        
        -- Make the frame draggable
        copyFrame:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then
                self:StartMoving()
            end
        end)
        copyFrame:SetScript("OnMouseUp", function(self, button)
            self:StopMovingOrSizing()
        end)
        
        -- Add a title
        local title = copyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", 16, -16)
        title:SetText("ChatterNatter - Copy Chat")
        
        -- Add a close button
        local closeButton = CreateFrame("Button", nil, copyFrame, "UIPanelCloseButton")
        closeButton:SetPoint("TOPRIGHT", copyFrame, "TOPRIGHT", -4, -4)
        
        -- Add a scroll frame
        local scrollFrame = CreateFrame("ScrollFrame", nil, copyFrame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", 16, -40)
        scrollFrame:SetPoint("BOTTOMRIGHT", -36, 16)
        
        -- Add an edit box
        local editBox = CreateFrame("EditBox", nil, scrollFrame)
        editBox:SetMultiLine(true)
        editBox:SetFontObject(ChatFontNormal)
        editBox:SetWidth(scrollFrame:GetWidth())
        editBox:SetHeight(400)
        editBox:SetAutoFocus(false)
        editBox:SetScript("OnEscapePressed", function() copyFrame:Hide() end)
        scrollFrame:SetScrollChild(editBox)
        
        copyFrame.editBox = editBox
    end
    
    button:SetScript("OnClick", function(self)
        local copyFrame = _G["ChatterNatterCopyFrame"]
        local text = ""
        
        -- Collect all messages
        for i = 1, chatFrame:GetNumMessages() do
            text = text .. chatFrame:GetMessageInfo(i) .. "\n"
        end
        
        if text and text ~= "" then
            -- Show the popup and set the text
            copyFrame.editBox:SetText(text)
            copyFrame:Show()
            
            -- Focus the edit box for immediate copying
            copyFrame.editBox:SetFocus()
            copyFrame.editBox:HighlightText()
        end
    end)
    
    button:SetScript("OnEnter", function(self)
        self:SetAlpha(1)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText("Copy Chat", 1, 1, 1)
        GameTooltip:Show()
    end)
    
    button:SetScript("OnLeave", function(self)
        self:SetAlpha(0.3)
        GameTooltip:Hide()
    end)
    
    chatFrame.copyButton = button
end

local function AddTimestampHook(chatFrame)
    if chatFrame._chatterNatterTimestamped then return end
    chatFrame._chatterNatterTimestamped = true

    local origAddMessage = chatFrame.AddMessage
    chatFrame.AddMessage = function(self, text, ...)
        local s = GetSettings()
        if type(text) == "string" then
            -- 1. Color player names FIRST
            text = addon.HighlightPlayerNames(text)
            -- 2. Process channel tags SECOND
            text = addon.ReplaceChannelTags(text)
            -- 3. Add timestamps LAST
            if s.showTimestamps then
                local ts = addon.FormatTimestamp()
                if not text:find("^|cffffff00%[") then
                    text = ts .. text
                end
            end
        end
        return origAddMessage(self, text, ...)
    end
end

function addon:ApplyChatStyle()
    local s = GetSettings()
    local fontName = s.font or DEFAULTS.font
    local fontSize = tonumber(s.fontSize) or DEFAULTS.fontSize
    local fontStyle = s.fontStyle or ""
    if fontStyle == "NONE" then fontStyle = "" end
    local fontPath = addon.fontPathMap and addon.fontPathMap[fontName] or "Fonts\\FRIZQT__.TTF"

    -- Validate font path
    if not fontPath or fontPath == "" then
        print("ChatterNatter: Invalid font path for '" .. fontName .. "', falling back to default.")
        fontPath = "Fonts\\FRIZQT__.TTF"
    end

    -- Create the font object if it doesn't exist
    if not self.chatFont then
        self.chatFont = CreateFont("ChatterNatterChatFont")
    end

    -- Set the font properties on our font object
    self.chatFont:SetFont(fontPath, fontSize, fontStyle)
    
    -- Set default chat font size for all future frames
    CHAT_FONT_HEIGHTS = {
        [1] = fontSize,
        [2] = fontSize,
        [3] = fontSize,
        [4] = fontSize,
        [5] = fontSize,
        [6] = fontSize,
        [7] = fontSize,
        [8] = fontSize,
        [9] = fontSize,
        [10] = fontSize,
        [11] = fontSize,
        [12] = fontSize,
        [13] = fontSize,
        [14] = fontSize,
        [15] = fontSize,
        [16] = fontSize,
    }

    local opacity = tonumber(s.opacity or 30)
    local alpha = math.max(0, math.min(1, opacity / 100))

    addon.chatBG = addon.chatBG or {}

    -- Apply to all existing chat frames
    for i = 1, NUM_CHAT_WINDOWS do
        local frame = _G["ChatFrame" .. i]
        if frame then
            -- Apply our font to the frame
            frame:SetFontObject(self.chatFont)
            
            -- Force the font size directly as well
            frame:SetFont(fontPath, fontSize, fontStyle)
            
            -- Make sure the edit box uses the same font
            local editBox = _G["ChatFrame" .. i .. "EditBox"]
            if editBox then
                editBox:SetFontObject(self.chatFont)
            end
            
            -- Also update the message font size in another way
            FCF_SetChatWindowFontSize(nil, frame, fontSize)
            
            -- Set other chat frame properties
            frame:SetSpacing(2)
            frame:SetHyperlinksEnabled(true)

            local blizzBG = _G["ChatFrame" .. i .. "Background"]
            if blizzBG then
                blizzBG:Hide()
                blizzBG:SetAlpha(0)
            end

            if not addon.chatBG[i] then
                addon.chatBG[i] = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
                addon.chatBG[i]:SetPoint("TOPLEFT")
                addon.chatBG[i]:SetPoint("BOTTOMRIGHT")
            end

            addon.chatBG[i]:SetColorTexture(0, 0, 0, alpha)
            addon.chatBG[i]:Show()

            for _, suffix in ipairs({
                "TopTexture", "BottomTexture", "LeftTexture", "RightTexture",
                "TopLeftTexture", "TopRightTexture", "BottomLeftTexture", "BottomRightTexture"
            }) do
                local tex = _G["ChatFrame" .. i .. suffix]
                if tex then tex:Hide() end
            end
        end
    end
    
    -- Apply to temporary chat windows too
    for i = 1, #CHAT_FRAMES do
        local frame = _G[CHAT_FRAMES[i]]
        if frame and not frame:GetID() then  -- Temporary chat windows don't have an ID
            frame:SetFontObject(self.chatFont)
            frame:SetFont(fontPath, fontSize, fontStyle)
            FCF_SetChatWindowFontSize(nil, frame, fontSize)
        end
    end
end

function addon:EnableTabStyle()
    local s = GetSettings()
    local fontName = s.font or "Friz Quadrata"
    local fontSize = 12
    local fontPath = addon.fontPathMap and addon.fontPathMap[fontName] or "Fonts\\FRIZQT__.TTF"
    if not self.tabFont then
        self.tabFont = CreateFont("ChatterNatterTabFont")
    end
    local success = pcall(self.tabFont.SetFont, self.tabFont, fontPath, fontSize, "THICKOUTLINE")
    if not success then
        pcall(self.tabFont.SetFont, self.tabFont, "Fonts\\FRIZQT__.TTF", fontSize, "THICKOUTLINE")
    end

    for i = 1, NUM_CHAT_WINDOWS do
        local frame = _G["ChatFrame"..i]
        local tab = _G["ChatFrame"..i.."Tab"]
        local tabText = _G["ChatFrame"..i.."TabText"]

        if frame and tab and tabText then
            tab:SetHighlightTexture(nil)
            tab:SetNormalTexture(nil)
            tab:SetPushedTexture(nil)
            tab:SetDisabledTexture(nil)

            for j = 1, tab:GetNumRegions() do
                local region = select(j, tab:GetRegions())
                if region and region:GetObjectType() == "Texture" then
                    region:Hide()
                end
            end

            tab:ClearAllPoints()
            tab:SetPoint("BOTTOMLEFT", ChatFrame1, "TOPLEFT", 4, 0)
            tab:SetHeight(18)
            tab:SetFrameStrata("HIGH")
            tab:SetFrameLevel(5)
            tab:EnableMouse(true)

            tabText:SetFontObject(self.tabFont)
            tabText:SetShadowOffset(1, -1)
            tabText:SetDrawLayer("OVERLAY", 7)
            tabText:ClearAllPoints()
            tabText:SetPoint("CENTER")
            tabText:Show()

            tab:SetAlpha(0)
            tabText:SetAlpha(0)

            tab:HookScript("OnEnter", function()
                UIFrameFadeIn(tab, 0.25, 0, 1)
                UIFrameFadeIn(tabText, 0.25, 0, 1)
            end)
            tab:HookScript("OnLeave", function()
                tab:SetAlpha(0)
                tabText:SetAlpha(0)
            end)
        end
    end

    hooksecurefunc("FCF_SelectDockFrame", function()
        for j = 1, NUM_CHAT_WINDOWS do
            local t = _G["ChatFrame"..j.."Tab"]
            local tx = _G["ChatFrame"..j.."TabText"]
            if t then t:SetAlpha(0) end
            if tx then tx:SetAlpha(0) end
        end
    end)
end

function addon:HookTooltips()
    for i = 1, NUM_CHAT_WINDOWS do
        local frame = _G["ChatFrame"..i]
        if frame then
            frame:SetHyperlinksEnabled(true)
            frame:HookScript("OnHyperlinkEnter", function(self, link)
                GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
                GameTooltip:SetHyperlink(link)
                GameTooltip:Show()
            end)
            frame:HookScript("OnHyperlinkLeave", function()
                GameTooltip:Hide()
            end)
        end
    end
end

function addon:ApplyInputBoxPosition()
    local s = ChatterNatter_Settings or DEFAULTS
    for i = 1, NUM_CHAT_WINDOWS do
        local f = _G["ChatFrame"..i]
        local eb = _G["ChatFrame"..i.."EditBox"]
        if f and eb then
            eb:ClearAllPoints()
            if s.inputBoxOnTop then
                eb:SetPoint("BOTTOMLEFT", f, "TOPLEFT", 0, 4)
                eb:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", 0, 4)
            else
                eb:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 0, -4)
                eb:SetPoint("TOPRIGHT", f, "BOTTOMRIGHT", 0, -4)
            end
        end
    end
end

function addon:ApplyButtonPanelStyle()
    local s = ChatterNatter_Settings or DEFAULTS
    local style = s.buttonPanelStyle or "Default"
    
    -- Hide QuickJoinToastButton (social icon at top of chat)
    if QuickJoinToastButton then
        if style == "Default" then
            QuickJoinToastButton:Show()
        else
            QuickJoinToastButton:Hide()
        end
    end
    
    -- Find and hide any social notification frames
    if ChatFrame1 and ChatFrame1.tex and ChatFrame1.tex.remoteCircle then
        if style == "Default" then
            ChatFrame1.tex.remoteCircle:Show()
        else
            ChatFrame1.tex.remoteCircle:Hide()
        end
    end
    
    -- Handle any other social buttons that might be attached to the top of the chat frame
    local socialButtons = {
        "QuickJoinToastButton",
        "ChatFrameSocialButton",
        "ChatFrameChannelShortcutButton", 
        "ChatFrameSocialShortcutButton"
    }
    
    for _, buttonName in ipairs(socialButtons) do
        local button = _G[buttonName]
        if button then
            if style == "Default" then
                button:Show()
            else
                button:Hide()
            end
        end
    end
    
    for i = 1, NUM_CHAT_WINDOWS do
        local chatFrame = _G["ChatFrame" .. i]
        if chatFrame then
            -- Hide social icon specific to this chat frame
            for _, regionName in ipairs({"SocialRemoteCircle", "SocialIcon", "SocialButton"}) do
                local region = chatFrame[regionName]
                if region then
                    if style == "Default" then
                        region:Show()
                    else
                        region:Hide()
                    end
                end
            end
            
            -- Handle the main chat button panel (channel, voice, social, etc.)
            local buttonFrame = _G["ChatFrame" .. i .. "ButtonFrame"]
            if buttonFrame then
                if style == "Hidden" then
                    buttonFrame:Hide()
                elseif style == "Minimal" then
                    buttonFrame:Show()
                    
                    -- Hide most buttons but keep the main toggle
                    local buttons = {
                        "ChatFrameChannelButton",
                        "ChatFrameToggleVoiceDeafenButton",
                        "ChatFrameToggleVoiceMuteButton",
                        "ChatFrameMenuButton",
                        "ChatFrameVoicePromoButton",
                        "ChatFrameMixerOpenButton",
                        "ChatFrame" .. i .. "PriorityHeader"
                    }
                    
                    for _, buttonName in ipairs(buttons) do
                        local button = _G[buttonName]
                        if button then
                            button:Hide()
                        end
                    end
                    
                    -- Keep the main toggle button if it exists
                    local mainButton = _G["ChatFrame" .. i .. "ButtonFrameBottomButton"]
                    if mainButton then
                        mainButton:Show()
                    end
                else
                    -- Default: show everything
                    buttonFrame:Show()
                    
                    -- Ensure all buttons are shown
                    local buttons = {
                        "ChatFrameChannelButton",
                        "ChatFrameToggleVoiceDeafenButton",
                        "ChatFrameToggleVoiceMuteButton",
                        "ChatFrameMenuButton",
                        "ChatFrameVoicePromoButton", 
                        "ChatFrameMixerOpenButton",
                        "ChatFrame" .. i .. "PriorityHeader"
                    }
                    
                    for _, buttonName in ipairs(buttons) do
                        local button = _G[buttonName]
                        if button then
                            button:Show()
                        end
                    end
                    
                    local mainButton = _G["ChatFrame" .. i .. "ButtonFrameBottomButton"]
                    if mainButton then
                        mainButton:Show()
                    end
                end
            end
        end
    end
end

-- NEW: Event-based combat and loot message formatting
function addon:SetupChatMessageFilters()
    if self.messageFilterInitialized then return end
    
    local yellow = "|cffffff00"
    local green = "|cff00ff00"
    local red = "|cffff0000"
    local reset = "|r"
    
    -- Handles damage and healing
    local function CombatMessageFilter(self, event, msg, ...)
        -- Check if feature is disabled in settings
        local s = GetSettings()
        if s.disableCombatFormatting then return false end
        
        -- Basic direct damage: "Your Fireball hits Enemy for 1234"
        local spell, dmg = msg:match("Your ([^ ]+) hits.-for (%d+)")
        if spell and dmg then
            return true, yellow .. spell .. ": " .. dmg .. reset
        end
        
        -- Critical hits: "Your Fireball crits Enemy for 2468"
        local spellCrit, dmgCrit = msg:match("Your ([^ ]+) crits.-for (%d+)")
        if spellCrit and dmgCrit then
            return true, yellow .. spellCrit .. ": " .. dmgCrit .. reset .. " (Critical)"
        end
        
        -- Healing: "Your Rejuvenation heals You for 567"
        local spellHeal, heal = msg:match("Your ([^ ]+) heals.-for (%d+)")
        if spellHeal and heal then
            return true, green .. spellHeal .. ": " .. heal .. reset
        end
        
        return false
    end
    
    -- Handles loot messages
    local function LootMessageFilter(self, event, msg, ...)
        -- Check if feature is disabled in settings
        local s = GetSettings()
        if s.disableCombatFormatting then return false end
        
        -- "You receive loot: [Item Name]"
        local itemLink = msg:match("You receive loot: (.+)")
        if itemLink then
            return true, red .. "LOOT: " .. reset .. itemLink
        end
        
        return false
    end
    
    -- Add chat filters
    
    ChatFrame_AddMessageEventFilter("CHAT_MSG_LOOT", LootMessageFilter)
    
    self.messageFilterInitialized = true
end

function addon:RefreshAll()
    self:ApplyChatStyle()
    self:EnableTabStyle()
    self:HookTooltips()
    self:ApplyInputBoxPosition()
    self:ApplyButtonPanelStyle()
    self:SetupChatMessageFilters() -- Added the new function
    for i = 1, NUM_CHAT_WINDOWS do
        local f = _G["ChatFrame"..i]
        if f then 
            AddTimestampHook(f)
            AddCopyButton(f)
        end
    end
end

do
    local loader = CreateFrame("Frame")
    loader:RegisterEvent("ADDON_LOADED")
    loader:SetScript("OnEvent", function(_, event, arg1)
        if event == "ADDON_LOADED" and arg1 == addonName then
            if not ChatterNatter_Settings then
                ChatterNatter_Settings = {}
            end
            addon:RefreshAll()
        end
    end)
end