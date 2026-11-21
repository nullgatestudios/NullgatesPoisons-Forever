-- Nullgate's Poisons: /npoison check, the in-game self test (phase 0 of PLAN.md).
-- Every result goes to chat and to NullgatesPoisonsDB.check, so the log can be copied from
-- WTF\Account\<account>\<realm>\<character>\SavedVariables\NullgatesPoisons-Forever.lua.
--
--   1. Which calls exist, what GetWeaponEnchantInfo returns and which poison the addon reads from it.
--   2. Every poison carried and the one each button would apply.
--   3. While the window is open: applying a poison with a button is reported (what changed on the weapon).
local _, ns = ...

local Check = {}
ns.Check = Check

local LOG_LIMIT = 400
local panel, before

local function Log(text)
    local db = ns.db
    if db then
        db.check = db.check or {}
        if #db.check >= LOG_LIMIT then table.remove(db.check, 1) end
        db.check[#db.check + 1] = text
    end
    print("|cff00c0ffNullgate's Poisons check:|r " .. text)
end
Check.Log = Log

local function Exists(path)
    local value = _G
    for part in path:gmatch("[^.]+") do
        if type(value) ~= "table" then return false end
        value = value[part]
    end
    return type(value) == "function"
end

local function EnchantLine()
    local r = { GetWeaponEnchantInfo() }
    local parts = {}
    for i = 1, 8 do parts[i] = tostring(r[i]) end
    local mainKind = ns.Poisons.FromEnchant(r[4])
    local offKind = ns.Poisons.FromEnchant(r[8])
    return table.concat(parts, ", ") .. string.format(" -> main %s, off %s", tostring(mainKind), tostring(offKind))
end

local function StaticChecks()
    local _, class = UnitClass("player")
    Log(string.format("client %s, build %s, interface %s; class %s, level %s; data build %s",
        tostring(GetBuildInfo and select(1, GetBuildInfo())), tostring(GetBuildInfo and select(2, GetBuildInfo())),
        tostring(GetBuildInfo and select(4, GetBuildInfo())), tostring(class), tostring(UnitLevel("player")),
        tostring(ns.POISON_DATA_BUILD)))
    local calls = {}
    for _, name in ipairs({ "GetWeaponEnchantInfo", "C_Item.GetItemCount", "GetInventoryItemID", "C_Timer.NewTicker" }) do
        calls[#calls + 1] = name .. "=" .. (Exists(name) and "yes" or "no")
    end
    Log("calls: " .. table.concat(calls, " "))
    Log("GetWeaponEnchantInfo: " .. EnchantLine())
    local carried = {}
    for _, kind in ipairs(ns.POISON_TYPES) do
        for _, p in ipairs(ns.POISONS[kind]) do
            local n = ns.Poisons.Count(p.item)
            if n > 0 then carried[#carried + 1] = string.format("%s x%d (item %d, enchant %d)", ns.Items.Name(p.item) or p.item, n, p.item, p.enchant) end
        end
    end
    Log("carried: " .. (#carried > 0 and table.concat(carried, "; ") or "no poisons"))
    for hand, slot in pairs(ns.Poisons.SLOTS) do
        local button = ns.Buttons.buttons[hand]
        Log(string.format("%s (slot %d): weapon %s, choice %s, button applies %s", hand, slot,
            tostring(GetInventoryItemID("player", slot)), tostring(ns.db.choice[hand]),
            tostring(button and button.poison and button.poison.item)))
    end
end

local function BuildPanel()
    panel = CreateFrame("Frame", "NullgatesPoisonsCheck", UIParent, "BasicFrameTemplateWithInset")
    panel:SetSize(300, 110)
    panel:SetPoint("CENTER")
    panel:SetFrameStrata("DIALOG")
    panel:SetToplevel(true)
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", panel.StartMoving)
    panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
    local title = "Poisons check"
    if type(panel.SetTitle) == "function" then panel:SetTitle(title)
    elseif type(panel.TitleText) == "table" then panel.TitleText:SetText(title) end
    local note = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    note:SetPoint("TOP", panel, "TOP", 0, -36)
    note:SetWidth(270)
    note:SetText("Click the Main Hand and Off Hand buttons while this window is open; what changed on each weapon goes to chat. Results are saved.")
end

local watcher = CreateFrame("Frame")
watcher:RegisterEvent("UNIT_INVENTORY_CHANGED")
watcher:RegisterEvent("ADDON_ACTION_BLOCKED")
watcher:RegisterEvent("ADDON_ACTION_FORBIDDEN")
watcher:RegisterEvent("UI_ERROR_MESSAGE")
watcher:SetScript("OnEvent", function(_, event, a, b)
    if not (panel and panel:IsShown()) then return end
    if event == "UNIT_INVENTORY_CHANGED" then
        if a ~= "player" then return end
        local now = EnchantLine()
        if now ~= before then Log("weapon enchants now: " .. now) end
        before = now
    elseif event == "UI_ERROR_MESSAGE" then
        Log("game error: " .. tostring(b or a))
    else
        Log(event .. ": " .. tostring(a) .. " tried " .. tostring(b))
    end
end)

function Check.Run()
    if ns.db then ns.db.check = {} end
    StaticChecks()
    before = EnchantLine()
    if not panel then BuildPanel() end
    panel:Show()
end
