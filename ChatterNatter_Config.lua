-- ChatterNatter_Config.lua
local addonName, addon = ...
local DEFAULTS = addon.DEFAULTS

-- Create config panel as a standalone frame
local panel = CreateFrame("Frame", "ChatterNatterConfigPanel", UIParent, "BackdropTemplate")
panel.name = "ChatterNatter"
panel:SetSize(650, 720)  -- Adjusted width back to 650 since we're narrowing the dropdown
panel:SetPoint("CENTER")
panel:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})
panel:SetBackdropColor(0, 0, 0, 1)
panel:EnableMouse(true)
panel:SetMovable(true)
panel:SetClampedToScreen(true)
panel:SetFrameStrata("DIALOG")
panel:Hide()

-- Make the frame draggable
panel:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
        self:StartMoving()
    end
end)
panel:SetScript("OnMouseUp", function(self, button)
    self:StopMovingOrSizing()
end)

-- Add a close button
local closeButton = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -4, -4)

local header = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
header:SetPoint("TOP", 0, -30)  -- Moved down slightly for better top spacing
header:SetText("ChatterNatter Settings")

local scrollFrame = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 20, -80)  -- Adjusted for better top margin
scrollFrame:SetPoint("BOTTOMRIGHT", -40, 20)
local content = CreateFrame("Frame", nil, scrollFrame)
scrollFrame:SetScrollChild(content)
content:SetSize(580, 1200)  -- Increased height to fit larger font section

-- FONT SECTION
local fontSection = CreateFrame("Frame", nil, content, "InsetFrameTemplate3")
fontSection:SetPoint("TOPLEFT", 10, -20)
fontSection:SetPoint("TOPRIGHT", -10, -20)
fontSection:SetHeight(200)  -- Kept height large for layout
local fontLabel = fontSection:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
fontLabel:SetPoint("TOPLEFT", 20, -15)
fontLabel:SetText("Font")
local fontDropdown = CreateFrame("Frame", "CN_FontDropdown", fontSection, "UIDropDownMenuTemplate")
fontDropdown:SetPoint("TOPLEFT", fontLabel, "BOTTOMLEFT", -15, -25)  -- Increased vertical spacing
fontDropdown:SetWidth(150)  -- Narrowed the font dropdown
UIDropDownMenu_SetWidth(fontDropdown, 150)
UIDropDownMenu_SetText(fontDropdown, ChatterNatter_Settings and ChatterNatter_Settings.font or DEFAULTS.font)
UIDropDownMenu_Initialize(fontDropdown, function(self, level, menuList)
    local settings = ChatterNatter_Settings or DEFAULTS
    local currentFont = settings.font or DEFAULTS.font
    local isValidFont = addon.fontPathMap[currentFont]

    -- Reset to default if the current font is invalid
    if not isValidFont then
        print("ChatterNatter: Selected font '" .. currentFont .. "' is invalid. Resetting to default.")
        ChatterNatter_Settings.font = DEFAULTS.font
        currentFont = DEFAULTS.font
    end

    for fontName, path in pairs(addon.fontPathMap) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = fontName
        info.value = fontName
        info.checked = currentFont == fontName
        info.func = function()
            ChatterNatter_Settings.font = fontName
            UIDropDownMenu_SetText(fontDropdown, fontName)
            addon:RefreshAll()
        end
        UIDropDownMenu_AddButton(info)
    end
    UIDropDownMenu_SetText(fontDropdown, currentFont)
end)

-- Font style dropdown
local styleLabel = fontSection:CreateFontString(nil, "ARTWORK", "GameFontNormal")
styleLabel:SetPoint("LEFT", fontDropdown, "RIGHT", 30, 2)  -- Reduced horizontal spacing to fit within UI
styleLabel:SetText("Font Style")
local styleDropdown = CreateFrame("Frame", "CN_FontStyleDropdown", fontSection, "UIDropDownMenuTemplate")
styleDropdown:SetPoint("LEFT", styleLabel, "RIGHT", 10, 0)
styleDropdown:SetWidth(150)  -- Narrowed to fit within UI
UIDropDownMenu_SetWidth(styleDropdown, 150)
local fontStyles = {"NONE", "OUTLINE", "THICKOUTLINE", "MONOCHROME", "MONOCHROMEOUTLINE", "THICKOUTLINEMONOCHROME"}
UIDropDownMenu_SetText(styleDropdown, ChatterNatter_Settings and ChatterNatter_Settings.fontStyle or "NONE")
UIDropDownMenu_Initialize(styleDropdown, function(self, level, menuList)
    for _, fontStyle in ipairs(fontStyles) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = fontStyle
        info.value = fontStyle
        info.checked = ChatterNatter_Settings and ChatterNatter_Settings.fontStyle == fontStyle
        info.func = function()
            ChatterNatter_Settings.fontStyle = fontStyle
            UIDropDownMenu_SetText(styleDropdown, fontStyle)
            addon:RefreshAll()
        end
        UIDropDownMenu_AddButton(info)
    end
end)

-- Font size slider
local sizeLabel = fontSection:CreateFontString(nil, "ARTWORK", "GameFontNormal")
sizeLabel:SetPoint("TOPLEFT", fontDropdown, "BOTTOMLEFT", 15, -40)  -- Kept spacing for larger section
sizeLabel:SetText("Font")
local sizeSlider = CreateFrame("Slider", "CN_FontSizeSlider", fontSection, "OptionsSliderTemplate")
sizeSlider:SetOrientation("HORIZONTAL")
sizeSlider:SetMinMaxValues(8, 30)  -- Kept range as per image (8 to 30)
sizeSlider:SetValueStep(1)
sizeSlider:SetWidth(350)  -- Kept slider width as per previous layout
sizeSlider:SetPoint("TOPLEFT", sizeLabel, "BOTTOMLEFT", 0, -20)  -- Adjusted for larger section
sizeSlider:SetObeyStepOnDrag(true)
sizeSlider:SetValue(ChatterNatter_Settings and ChatterNatter_Settings.fontSize or DEFAULTS.fontSize)
sizeSlider:SetScript("OnValueChanged", function(self, value)
    ChatterNatter_Settings.fontSize = math.floor(value + 0.5)
    _G[self:GetName() .. "Text"]:SetText(ChatterNatter_Settings.fontSize)
    addon:RefreshAll()
end)
_G[sizeSlider:GetName() .. "Low"]:SetText("8")
_G[sizeSlider:GetName() .. "High"]:SetText("30")
_G[sizeSlider:GetName() .. "Text"]:SetText(ChatterNatter_Settings and ChatterNatter_Settings.fontSize or DEFAULTS.fontSize)

-- TAG STYLE SECTION
local tagSection = CreateFrame("Frame", nil, content, "InsetFrameTemplate3")
tagSection:SetPoint("TOPLEFT", fontSection, "BOTTOMLEFT", 0, -40)  -- Increased gap between sections
tagSection:SetPoint("TOPRIGHT", fontSection, "BOTTOMRIGHT", 0, -40)
tagSection:SetHeight(80)
local tagLabel = tagSection:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
tagLabel:SetPoint("TOPLEFT", 20, -15)
tagLabel:SetText("Channel Tag Style")
local tagDropdown = CreateFrame("Frame", "CN_TagStyleDropdown", tagSection, "UIDropDownMenuTemplate")
tagDropdown:SetPoint("TOPLEFT", tagLabel, "BOTTOMLEFT", -15, -15)  -- Adjusted spacing
tagDropdown:SetWidth(200)
UIDropDownMenu_SetWidth(tagDropdown, 200)
local tagStyles = {
    { text = "Default (Blizzard)", value = "Default" },
    { text = "Short (Abbreviated)", value = "Short" },
    { text = "Normal (Full Tag)", value = "Normal" },
}
UIDropDownMenu_SetText(tagDropdown, ChatterNatter_Settings and ChatterNatter_Settings.tagStyle or DEFAULTS.tagStyle)
UIDropDownMenu_Initialize(tagDropdown, function(self, level, menuList)
    for _, opt in ipairs(tagStyles) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = opt.text
        info.value = opt.value
        info.checked = ChatterNatter_Settings and ChatterNatter_Settings.tagStyle == opt.value
        info.func = function()
            ChatterNatter_Settings.tagStyle = opt.value
            UIDropDownMenu_SetText(tagDropdown, opt.text)
            addon:RefreshAll()
        end
        UIDropDownMenu_AddButton(info)
    end
end)

-- TIMESTAMP SECTION
local timeSection = CreateFrame("Frame", nil, content, "InsetFrameTemplate3")
timeSection:SetPoint("TOPLEFT", tagSection, "BOTTOMLEFT", 0, -40)  -- Increased gap
timeSection:SetPoint("TOPRIGHT", tagSection, "BOTTOMRIGHT", 0, -40)
timeSection:SetHeight(80)
local timeLabel = timeSection:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
timeLabel:SetPoint("TOPLEFT", 20, -15)
timeLabel:SetText("Timestamps")

local tsCheckbox = CreateFrame("CheckButton", "CN_TimestampCheckbox", timeSection, "ChatConfigCheckButtonTemplate")
tsCheckbox:SetPoint("TOPLEFT", timeLabel, "BOTTOMLEFT", 0, -15)  -- Adjusted spacing
tsCheckbox.Text:SetText("Show Timestamps")
tsCheckbox:SetChecked(ChatterNatter_Settings and ChatterNatter_Settings.showTimestamps or DEFAULTS.showTimestamps)
tsCheckbox:SetScript("OnClick", function(self)
    ChatterNatter_Settings.showTimestamps = self:GetChecked()
    addon:RefreshAll()
end)

local tsLabel = timeSection:CreateFontString(nil, "ARTWORK", "GameFontNormal")
tsLabel:SetPoint("LEFT", tsCheckbox, "RIGHT", 40, 0)
tsLabel:SetText("Format:")
local tsDropdown = CreateFrame("Frame", "CN_TimestampFormatDropdown", timeSection, "UIDropDownMenuTemplate")
tsDropdown:SetPoint("LEFT", tsLabel, "RIGHT", 5, -2)
tsDropdown:SetWidth(200)
UIDropDownMenu_SetWidth(tsDropdown, 200)
local timeFormats = {
    { text = "24-hour (HH:MM)", value = "[%H:%M]" },
    { text = "24-hour + Sec (HH:MM:SS)", value = "[%H:%M:%S]" },
    { text = "12-hour (hh:mm AM/PM)", value = "[%I:%M %p]" },
    { text = "12-hour + Sec (hh:mm:ss AM/PM)", value = "[%I:%M:%S %p]" },
}
UIDropDownMenu_SetText(tsDropdown, ChatterNatter_Settings and ChatterNatter_Settings.timestampFormat or DEFAULTS.timestampFormat)
UIDropDownMenu_Initialize(tsDropdown, function(self, level, menuList)
    for _, opt in ipairs(timeFormats) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = opt.text
        info.value = opt.value
        info.checked = ChatterNatter_Settings and ChatterNatter_Settings.timestampFormat == opt.value
        info.func = function()
            ChatterNatter_Settings.timestampFormat = opt.value
            UIDropDownMenu_SetText(tsDropdown, opt.text)
            addon:RefreshAll()
        end
        UIDropDownMenu_AddButton(info)
    end
end)

-- OPACITY SECTION
local opacitySection = CreateFrame("Frame", nil, content, "InsetFrameTemplate3")
opacitySection:SetPoint("TOPLEFT", timeSection, "BOTTOMLEFT", 0, -40)  -- Increased gap
opacitySection:SetPoint("TOPRIGHT", timeSection, "BOTTOMRIGHT", 0, -40)
opacitySection:SetHeight(80)
local opacityLabel = opacitySection:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
opacityLabel:SetPoint("TOPLEFT", 20, -15)
opacityLabel:SetText("Background Opacity")

local opacitySlider = CreateFrame("Slider", "CN_OpacitySlider", opacitySection, "OptionsSliderTemplate")
opacitySlider:SetOrientation("HORIZONTAL")
opacitySlider:SetMinMaxValues(0, 100)
opacitySlider:SetValueStep(1)
opacitySlider:SetWidth(350)
opacitySlider:SetPoint("TOPLEFT", opacityLabel, "BOTTOMLEFT", 20, -15)  -- Adjusted spacing
opacitySlider:SetObeyStepOnDrag(true)
opacitySlider:SetValue(ChatterNatter_Settings and ChatterNatter_Settings.opacity or DEFAULTS.opacity)
opacitySlider:SetScript("OnValueChanged", function(self, value)
    ChatterNatter_Settings.opacity = math.floor(value + 0.5)
    _G[self:GetName() .. "Text"]:SetText(ChatterNatter_Settings.opacity .. "%")
    addon:RefreshAll()
end)
_G[opacitySlider:GetName() .. "Low"]:SetText("0%")
_G[opacitySlider:GetName() .. "High"]:SetText("100%")
_G[opacitySlider:GetName() .. "Text"]:SetText((ChatterNatter_Settings and ChatterNatter_Settings.opacity or DEFAULTS.opacity) .. "%")

-- INPUT BOX POSITION
local inputBoxSection = CreateFrame("Frame", nil, content, "InsetFrameTemplate3")
inputBoxSection:SetPoint("TOPLEFT", opacitySection, "BOTTOMLEFT", 0, -40)  -- Increased gap
inputBoxSection:SetPoint("TOPRIGHT", opacitySection, "BOTTOMRIGHT", 0, -40)
inputBoxSection:SetHeight(80)
local inputLabel = inputBoxSection:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
inputLabel:SetPoint("TOPLEFT", 20, -15)
inputLabel:SetText("Chat Input Box")

local inputBoxCheckbox = CreateFrame("CheckButton", "CN_InputBoxCheckbox", inputBoxSection, "ChatConfigCheckButtonTemplate")
inputBoxCheckbox:SetPoint("TOPLEFT", inputLabel, "BOTTOMLEFT", 0, -15)  -- Adjusted spacing
inputBoxCheckbox.Text:SetText("Move Chat Input Box to Top")
inputBoxCheckbox:SetChecked(ChatterNatter_Settings and ChatterNatter_Settings.inputBoxOnTop or DEFAULTS.inputBoxOnTop)
inputBoxCheckbox:SetScript("OnClick", function(self)
    ChatterNatter_Settings.inputBoxOnTop = self:GetChecked()
    addon:ApplyInputBoxPosition()
end)

-- CHAT BUTTON PANEL
local buttonPanelSection = CreateFrame("Frame", nil, content, "InsetFrameTemplate3")
buttonPanelSection:SetPoint("TOPLEFT", inputBoxSection, "BOTTOMLEFT", 0, -40)  -- Increased gap
buttonPanelSection:SetPoint("TOPRIGHT", inputBoxSection, "BOTTOMRIGHT", 0, -40)
buttonPanelSection:SetHeight(80)
local buttonPanelLabel = buttonPanelSection:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
buttonPanelLabel:SetPoint("TOPLEFT", 20, -15)
buttonPanelLabel:SetText("Chat Button Panel")

local buttonPanelDropdown = CreateFrame("Frame", "CN_ButtonPanelDropdown", buttonPanelSection, "UIDropDownMenuTemplate")
buttonPanelDropdown:SetPoint("TOPLEFT", buttonPanelLabel, "BOTTOMLEFT", -15, -15)  -- Adjusted spacing
buttonPanelDropdown:SetWidth(200)
UIDropDownMenu_SetWidth(buttonPanelDropdown, 200)
local buttonPanelOptions = {
    { text = "Default (Show All)", value = "Default" },
    { text = "Minimal (Hide Most)", value = "Minimal" },
    { text = "Hidden (Hide All)", value = "Hidden" },
}
UIDropDownMenu_SetText(buttonPanelDropdown, ChatterNatter_Settings and ChatterNatter_Settings.buttonPanelStyle or "Default")
UIDropDownMenu_Initialize(buttonPanelDropdown, function(self, level, menuList)
    for _, opt in ipairs(buttonPanelOptions) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = opt.text
        info.value = opt.value
        info.checked = ChatterNatter_Settings and ChatterNatter_Settings.buttonPanelStyle == opt.value
        info.func = function()
            ChatterNatter_Settings.buttonPanelStyle = opt.value
            UIDropDownMenu_SetText(buttonPanelDropdown, opt.text)
            addon:ApplyButtonPanelStyle()
        end
        UIDropDownMenu_AddButton(info)
    end
end)


-- Add reload command
SLASH_RELOAD1 = "/rl";
SlashCmdList["RELOAD"] = function(msg, editBox)
    ReloadUI();
end

-- Add settings access command
SLASH_CHATTERNATTER1 = "/chatternatter";
SLASH_CHATTERNATTER2 = "/cn";
SlashCmdList["CHATTERNATTER"] = function(msg, editBox)
    panel:Show();
end

-- Create a settings button on the chat frame
local function CreateSettingsButton()
    local button = CreateFrame("Button", "ChatterNatterSettingsButton", ChatFrame1)
    button:SetSize(16, 16)
    button:SetPoint("TOPRIGHT", ChatFrame1, "TOPRIGHT", -25, 0)
    button:SetNormalTexture("Interface\\Buttons\\UI-OptionsButton")
    button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    button:SetAlpha(0.3)
    
    button:SetScript("OnClick", function()
        panel:Show()
    end)
    
    button:SetScript("OnEnter", function(self)
        self:SetAlpha(1)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText("ChatterNatter Settings", 1, 1, 1)
        GameTooltip:Show()
    end)
    
    button:SetScript("OnLeave", function(self)
        self:SetAlpha(0.3)
        GameTooltip:Hide()
    end)
end

-- Initialize settings button
CreateSettingsButton()
print("ChatterNatter: Type /cn to open settings")