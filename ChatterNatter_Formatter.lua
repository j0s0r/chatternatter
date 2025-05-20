-- ChatterNatter_Formatter.lua
local addonName, addon = ...

-- Font path table MUST be loaded first and global to addon
-- ChatterNatter_Formatter.lua
addon.fontPathMap = {
    ["Friz Quadrata"] = "Fonts\\FRIZQT__.TTF",
    ["Arial Narrow"]  = "Fonts\\ARIALN.TTF",
    ["Roboto"]        = "Interface\\AddOns\\ChatterNatter\\fonts\\Roboto-Regular.ttf",
    ["Open Sans"]     = "Interface\\AddOns\\ChatterNatter\\fonts\\OpenSans-Regular.ttf",
    ["Montserrat"]    = "Interface\\AddOns\\ChatterNatter\\fonts\\Montserrat-Regular.ttf",
    ["Quazzi"]        = "Interface\\AddOns\\ChatterNatter\\fonts\\Quazii.ttf",
}

-- Tag and color mapping
addon.shortTags = {
    Guild="G", Party="P", Raid="R", Instance="I",
    Whisper="W", Officer="O", Say="S", Yell="Y",
    General="Gen", Trade="T", LocalDefense="LD", LookingForGroup="LFG",
    Battleground="BG", Custom="C", WorldDefense="WD", Recruitment="Rec",
}

addon.tagColors = {
    Guild="|cff40ff40", Party="|cffaaaaff", Raid="|cffff7f7f", Instance="|cffff7f7f",
    Whisper="|cffffaaff", Officer="|cffffff88", Say="|cffffffff", Yell="|cffff0000",
    Loot="|cffff4444", Currency="|cffffff00", Money="|cff00ff00",
    General="|cffffcc00", Trade="|cffffb000", LocalDefense="|cffffcc00",
    LookingForGroup="|cffffcc00", Battleground="|cffffcc00", Custom="|cffffcc00",
    WorldDefense="|cffffcc00", Recruitment="|cffffcc00",
}

addon.DEFAULTS = {
    font            = "Friz Quadrata",
    fontSize        = 14,
    fontStyle       = "NONE",
    showTimestamps  = true,
    timestampFormat = "[%H:%M]",
    tagStyle        = "Default", -- "Default" (Blizz), "Short", "Normal"
    opacity         = 30,
    inputBoxOnTop   = false,
}

function addon.StripColors(str)
    return str:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
end

function addon.SimplifyTag(tag)
    local cleanTag = addon.StripColors(tag)
    return cleanTag:match("^(%a+)") or cleanTag
end

-- Full channel tag replacement, never affects player names
-- Full channel tag replacement, never affects player names
function addon.ReplaceChannelTags(text)
    local s = ChatterNatter_Settings or addon.DEFAULTS
    if not s.tagStyle or s.tagStyle == "Default" then
        return text
    end
    
    -- This pattern only matches channel tags at the beginning of messages
    -- and avoids player links which contain |Hplayer: 
    return text:gsub("^(|cffffff00%[%d+%. .-%]|r%s)(%[)(%d*%.?%s*)([^%]]+)(%])", function(timestamp, left, num, tag, right)
        return timestamp .. left .. num .. tag .. right
    end):gsub("(%[)(%d*%.?%s*)([^%]]+)(%])", function(left, num, tag, right)
        -- Skip player links that have already been colored
        if tag:find("|Hplayer:") then
            return left .. num .. tag .. right
        end
        
        -- Don't replace already colorized tags that contain player info
        if tag:find("|c%x%x%x%x%x%x%x%x") and tag:find("|r") then
            return left .. num .. tag .. right
        end
        
        local tagKey = addon.SimplifyTag(tag)
        local color = addon.tagColors[tagKey] or "|cffffffff"
        
        if s.tagStyle == "Short" then
            local short = addon.shortTags[tagKey] or tagKey
            return color .. "[" .. short .. "]|r"
        elseif s.tagStyle == "Normal" then
            local cleanTag = addon.StripColors(tag)
            return color .. "[" .. cleanTag .. "]|r"
        end
        return left .. num .. tag .. right
    end)
end

-- Best-in-class class-coloring for player names
function addon.HighlightPlayerNames(text)
    -- Handles ALL player link formats in chat
    -- 1. Standard player links: |Hplayer:Name-Realm:GUID|h[Name]|h and |Hplayer:Name:GUID|hName|h
    text = text:gsub("(|Hplayer:([^:]+):([%d%-]+):([%d]+):.-|h)(.-)(|h)", function(link, nameRealm, _, guid, displayText, close)
        local name = nameRealm:match("^([^-]+)")
        local color = "80c0ff"
        local _, class
        if guid and guid ~= "" then _, class = GetPlayerInfoByGUID(guid) end
        if not class and name then _, class = UnitClass(name) end
        if class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class] then
            color = RAID_CLASS_COLORS[class].colorStr:sub(3)
        end
        return link .. "|cff" .. color .. displayText .. "|r" .. close
    end)
    -- 2. "Unlinked" player names - fallback for weird patterns, do NOT catch everything
    -- (Optional, can be commented out to avoid over-coloring.)
    -- text = text:gsub("(%[%w+%])", function(bracketed)
    --     return "|cff80c0ff"..bracketed.."|r"
    -- end)
    return text
end

function addon.FormatTimestamp()
    local s = ChatterNatter_Settings or addon.DEFAULTS
    return "|cffffff00" .. date(s.timestampFormat or "[%H:%M]") .. "|r "
end
