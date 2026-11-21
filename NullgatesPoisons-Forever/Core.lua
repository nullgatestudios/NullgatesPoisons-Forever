-- Nullgate's Poisons: saved data, events, the out-of-combat queue and slash commands.
local addonName, ns = ...

local L = ns.L

ns.DEFAULTS = {
    locked = false,
    vertical = false,
    scale = 1,
    choice = { main = "instant", off = "deadly" },
    warn = { minutes = 5, charges = 10, chat = true, sound = false, glow = true },
    showCraftable = false,
    language = "auto",
}

local function Merge(target, defaults)
    for key, value in pairs(defaults) do
        if type(value) == "table" then
            if type(target[key]) ~= "table" then target[key] = {} end
            Merge(target[key], value)
        elseif target[key] == nil then
            target[key] = value
        end
    end
end

function ns.Print(text)
    print("|cff00c0ffPoisons:|r " .. tostring(text))
end

function ns.IsRogue()
    local _, class = UnitClass("player")
    return class == "ROGUE"
end

local pending = {}
function ns.WhenSafe(key, fn)
    if InCombatLockdown() then
        pending[key] = fn
        return false
    end
    pending[key] = nil
    fn()
    return true
end

BINDING_HEADER_NULLGATESPOISONS = "Nullgate's Poisons"
local function NameBindings()
    _G["BINDING_NAME_CLICK NullgatesPoisonsMainHand:LeftButton"] = L["Apply poison to your main hand"]
    _G["BINDING_NAME_CLICK NullgatesPoisonsOffHand:LeftButton"] = L["Apply poison to your off hand"]
end

local events = CreateFrame("Frame")
local active = false

local function OnEvent(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == addonName then
            if type(NullgatesPoisonsDB) ~= "table" then NullgatesPoisonsDB = {} end
            Merge(NullgatesPoisonsDB, ns.DEFAULTS)
            ns.db = NullgatesPoisonsDB
            for hand, kind in pairs(ns.db.choice) do
                if not ns.POISONS[kind] then ns.db.choice[hand] = ns.DEFAULTS.choice[hand] end
            end
            ns.SetLanguage(ns.db.language)
            NameBindings()
        end
        if arg1 == addonName or arg1 == "NullgatesAddonConfig-Forever" then ns.Options.RegisterHub() end
    elseif event == "PLAYER_LOGIN" then
        active = ns.IsRogue()
        if active then
            ns.Buttons.Create()
            -- Time left counts down without events, so refresh the status every few seconds.
            C_Timer.NewTicker(5, ns.Buttons.UpdateStatus)
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        for key, fn in pairs(pending) do
            pending[key] = nil
            fn()
        end
    elseif not active then
        return
    elseif event == "UNIT_INVENTORY_CHANGED" then
        if arg1 == "player" then ns.Buttons.UpdateStatus() end
    else -- bags changed, level-up
        ns.Buttons.Update()
    end
end

events:SetScript("OnEvent", OnEvent)
for _, event in ipairs({ "ADDON_LOADED", "PLAYER_LOGIN", "PLAYER_REGEN_ENABLED", "BAG_UPDATE_DELAYED",
    "PLAYER_LEVEL_UP", "UNIT_INVENTORY_CHANGED" }) do
    events:RegisterEvent(event)
end

local function Help()
    ns.Print(L["commands:"])
    print("  /npoison - " .. L["open the settings"])
    print("  /npoison lock | unlock - " .. L["lock or unlock the bar"])
    print("  /npoison reset - " .. L["reset the bar's position"])
    print("  /npoison check - " .. L["test what the addon needs in this client (results are saved)"])
end

SLASH_NULLGATESPOISONS1 = "/npoison"
SLASH_NULLGATESPOISONS2 = "/poisons"
SlashCmdList["NULLGATESPOISONS"] = function(msg)
    local command = string.lower((msg or ""):match("^%s*(%S*)") or "")
    if command == "check" then
        ns.Check.Run()
    elseif command == "help" then
        Help()
    elseif not active then
        ns.Print(L["This addon is for rogues; only /npoison check works on other classes."])
    elseif command == "" or command == "options" or command == "config" then
        ns.Options.Open()
    elseif command == "lock" or command == "unlock" then
        ns.db.locked = command == "lock"
        ns.Buttons.Layout()
    elseif command == "reset" then
        ns.Buttons.ResetPosition()
    else
        Help()
    end
end
