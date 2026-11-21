-- Nullgate's Poisons: the bar with the Main Hand and Off Hand buttons. Left-click applies the chosen
-- poison (a secure item button aimed at the weapon slot); right-click opens a menu to choose the
-- poison type. What a button applies can only change out of combat.
local _, ns = ...

local L = ns.L
local Buttons = {}
ns.Buttons = Buttons

local SIZE, GAP = 40, 4
local HANDS = { "main", "off" }
local EMPTY_ICON = "Interface\\Icons\\INV_Misc_Bag_10"
local bar, menu
local buttons = {}
Buttons.buttons = buttons

local function ItemIcon(itemID)
    local icon = (C_Item and C_Item.GetItemIconByID) or GetItemIcon
    return icon and icon(itemID) or nil
end

-- Translated type names; a type added by a later client patch falls back to its English name.
local TYPE_NAMES
function Buttons.TypeName(kind)
    TYPE_NAMES = TYPE_NAMES or {
        instant = L["Instant Poison"], deadly = L["Deadly Poison"], crippling = L["Crippling Poison"],
        mindnumbing = L["Mind-numbing Poison"], wound = L["Wound Poison"], numbing = L["Numbing Poison"],
        atrophic = L["Atrophic Poison"], sebacious = L["Sebacious Poison"], occult = L["Occult Poison"],
    }
    return TYPE_NAMES[kind] or ns.POISON_NAMES[kind] or kind
end

local function HasWeapon(hand)
    return GetInventoryItemID("player", ns.Poisons.SLOTS[hand]) ~= nil
end

local function ShowTooltip(button)
    local hand = button.hand
    local kind = ns.db.choice[hand]
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    GameTooltip:AddLine(hand == "main" and L["Main hand"] or L["Off hand"], 1, 0.82, 0)
    if not HasWeapon(hand) then
        GameTooltip:AddLine(L["No weapon in this hand."], 1, 0.3, 0.3, true)
    else
        local state = button.state
        if state and state.has then
            local name = state.kind and Buttons.TypeName(state.kind) or L["Unknown enchant"]
            local text = string.format(L["On the weapon: %s, %s left"], name, ns.Poisons.Short(state.seconds))
            if state.charges > 0 then text = text .. string.format(L[", %d charges"], state.charges) end
            GameTooltip:AddLine(text, 1, 1, 1, true)
        else
            GameTooltip:AddLine(L["No poison on this weapon."], 1, 0.5, 0.3, true)
        end
        if button.poison then
            GameTooltip:AddLine(string.format(L["Left-click: apply %s (%d in your bags)."], ns.Items.Name(button.poison.item)
                or Buttons.TypeName(kind), ns.Poisons.Total(kind)), 0.8, 0.8, 0.8, true)
        else
            GameTooltip:AddLine(string.format(L["You carry no %s you can use."], Buttons.TypeName(kind)), 1, 0.3, 0.3, true)
        end
        if ns.db.showCraftable then
            local top = ns.Poisons.TopRank(kind, UnitLevel("player"))
            if top then
                GameTooltip:AddLine(string.format(L["You could craft %d more from your reagents."], ns.Poisons.Craftable(top)), 0.6, 0.8, 1, true)
            end
        end
    end
    GameTooltip:AddLine(L["Right-click: choose the poison."], 0.6, 0.6, 0.6)
    if button.stale then GameTooltip:AddLine(L["In combat: updates when combat ends."], 1, 0.3, 0.3, true) end
    GameTooltip:Show()
end

-- The right-click menu: one entry per poison type.
local function ShowMenu(button)
    if not menu then
        menu = CreateFrame("Frame", "NullgatesPoisonsMenu", UIParent, "BackdropTemplate")
        menu:SetFrameStrata("DIALOG")
        menu:SetToplevel(true)
        menu:SetClampedToScreen(true)
        menu:EnableMouse(true)
        if menu.SetBackdrop then
            menu:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true, tileSize = 16, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 } })
            menu:SetBackdropColor(0.05, 0.06, 0.08, 0.95)
        end
        menu.entries = {}
        for i, kind in ipairs(ns.POISON_TYPES) do
            local entry = CreateFrame("Button", nil, menu)
            entry:SetSize(190, 20)
            entry:SetPoint("TOPLEFT", menu, "TOPLEFT", 8, -8 - (i - 1) * 20)
            entry.text = entry:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
            entry.text:SetPoint("LEFT", entry, "LEFT", 4, 0)
            local hl = entry:CreateTexture(nil, "HIGHLIGHT")
            hl:SetAllPoints(entry)
            hl:SetColorTexture(1, 1, 1, 0.15)
            entry.kind = kind
            entry:SetScript("OnClick", function(self)
                ns.db.choice[menu.hand] = self.kind
                menu:Hide()
                Buttons.Update()
            end)
            menu.entries[i] = entry
        end
        menu:SetSize(206, 16 + #ns.POISON_TYPES * 20)
        if UISpecialFrames then table.insert(UISpecialFrames, "NullgatesPoisonsMenu") end
    end
    menu.hand = button.hand
    for _, entry in ipairs(menu.entries) do
        local total = ns.Poisons.Total(entry.kind)
        local mark = ns.db.choice[button.hand] == entry.kind and "|cffffd100> |r" or "   "
        entry.text:SetText(mark .. Buttons.TypeName(entry.kind) .. (total > 0 and (" |cff9d9d9d(" .. total .. ")|r") or ""))
    end
    menu:ClearAllPoints()
    menu:SetPoint("BOTTOMLEFT", button, "TOPLEFT", 0, 4)
    menu:Show()
end
Buttons.ShowMenu = ShowMenu

local function NewButton(hand)
    local button = CreateFrame("Button", hand == "main" and "NullgatesPoisonsMainHand" or "NullgatesPoisonsOffHand", bar,
        "SecureActionButtonTemplate")
    button.hand = hand
    button:SetSize(SIZE, SIZE)
    button:RegisterForClicks("AnyUp", "AnyDown")
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetAllPoints(button)
    button.glow = button:CreateTexture(nil, "OVERLAY")
    button.glow:SetPoint("TOPLEFT", -4, 4)
    button.glow:SetPoint("BOTTOMRIGHT", 4, -4)
    button.glow:SetColorTexture(0.4, 1, 0.2, 0.35)
    button.glow:Hide()
    button.count = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    button.count:SetPoint("BOTTOMRIGHT", -2, 2)
    button.timer = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    button.timer:SetPoint("TOP", button, "BOTTOM", 0, -2)
    button.label = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    button.label:SetPoint("TOPLEFT", 2, -2)
    button.label:SetText(hand == "main" and "MH" or "OH")
    button.staleMark = button:CreateFontString(nil, "OVERLAY", "GameFontRedSmall")
    button.staleMark:SetPoint("TOPRIGHT", -2, -2)
    button.staleMark:SetText("*")
    button.staleMark:Hide()
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(button)
    highlight:SetColorTexture(1, 1, 1, 0.15)
    button:SetScript("OnEnter", ShowTooltip)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    button:HookScript("OnClick", function(self, mouse, down)
        if mouse == "RightButton" and not down then ShowMenu(self) end
    end)
    button:RegisterForDrag("LeftButton")
    button:SetScript("OnDragStart", function() bar:GetScript("OnDragStart")(bar) end)
    button:SetScript("OnDragStop", function() bar:GetScript("OnDragStop")(bar) end)
    buttons[hand] = button
    return button
end

local function SavePosition()
    local point, _, relativePoint, x, y = bar:GetPoint()
    ns.db.point = { point = point, relativePoint = relativePoint, x = x, y = y }
end

local function RestorePosition()
    bar:ClearAllPoints()
    local p = ns.db.point
    if p and p.point then
        bar:SetPoint(p.point, UIParent, p.relativePoint or p.point, p.x or 0, p.y or 0)
    else
        bar:SetPoint("CENTER", UIParent, "CENTER", 0, -220)
    end
end

function Buttons.Create()
    if bar then return end
    bar = CreateFrame("Frame", "NullgatesPoisonsBar", UIParent)
    bar:SetMovable(true)
    bar:SetClampedToScreen(true)
    bar:EnableMouse(true)
    bar:RegisterForDrag("LeftButton")
    bar:SetScript("OnDragStart", function(self)
        if not ns.db.locked and not InCombatLockdown() then self:StartMoving() end
    end)
    bar:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SavePosition()
    end)
    bar.background = bar:CreateTexture(nil, "BACKGROUND")
    bar.background:SetAllPoints(bar)
    bar.background:SetColorTexture(0.08, 0.1, 0.13, 0.75)
    for _, hand in ipairs(HANDS) do NewButton(hand) end
    RestorePosition()
    Buttons.Layout()
    Buttons.Update()
end

function Buttons.Layout()
    if not bar then return end
    ns.WhenSafe("layout", function()
        for i, hand in ipairs(HANDS) do
            local button = buttons[hand]
            button:ClearAllPoints()
            local offset = GAP + (i - 1) * (SIZE + GAP + (ns.db.vertical and 14 or 0))
            if ns.db.vertical then
                button:SetPoint("TOP", bar, "TOP", 0, -offset)
            else
                button:SetPoint("LEFT", bar, "LEFT", offset, 4)
            end
        end
        if ns.db.vertical then
            bar:SetSize(SIZE + 2 * GAP, GAP + #HANDS * (SIZE + GAP + 14))
        else
            bar:SetSize(GAP + #HANDS * (SIZE + GAP), SIZE + 2 * GAP + 14)
        end
        bar:SetScale(ns.db.scale or 1)
        bar.background:SetShown(not ns.db.locked)
        bar:Show()
    end)
    Buttons.UpdateStatus()
end

-- Picks the poison each button applies, out of combat.
function Buttons.Update()
    if not bar then return end
    local applied = ns.WhenSafe("poisons", function()
        local level = UnitLevel("player")
        for _, hand in ipairs(HANDS) do
            local button = buttons[hand]
            local poison = ns.Poisons.Best(ns.db.choice[hand], level)
            button.poison = poison
            for key, value in pairs(ns.Poisons.Attributes(hand, poison)) do button:SetAttribute(key, value) end
            button.icon:SetTexture((poison and ItemIcon(poison.item)) or EMPTY_ICON)
            button.icon:SetDesaturated(poison == nil)
            button.stale = false
            button.staleMark:Hide()
        end
    end)
    if not applied then
        for _, hand in ipairs(HANDS) do
            buttons[hand].stale = true
            buttons[hand].staleMark:Show()
        end
    end
    Buttons.UpdateStatus()
end

-- Time, charges, counts and warnings; none of this is protected.
function Buttons.UpdateStatus()
    if not bar then return end
    local hasMain, mainExp, mainCharges, mainEnchant, hasOff, offExp, offCharges, offEnchant = GetWeaponEnchantInfo()
    local states = {
        main = ns.Poisons.State(hasMain, mainExp, mainCharges, mainEnchant),
        off = ns.Poisons.State(hasOff, offExp, offCharges, offEnchant),
    }
    for _, hand in ipairs(HANDS) do
        local button, state = buttons[hand], states[hand]
        button.state = state
        button.count:SetText(button.poison and ns.Poisons.Total(ns.db.choice[hand]) or "")
        if state.has then
            local text = ns.Poisons.Short(state.seconds)
            if state.charges > 0 then text = text .. " / " .. state.charges end
            button.timer:SetText(text)
        else
            button.timer:SetText(HasWeapon(hand) and "|cffff6040" .. L["none"] .. "|r" or "")
        end
        -- Only warn about a hand you can do something about: a weapon, and the chosen poison carried
        -- (or a poison already on it).
        local watched = HasWeapon(hand) and (button.poison ~= nil or state.has)
        local level = watched and ns.Poisons.Level(state, (ns.db.warn.minutes or 0) * 60, ns.db.warn.charges or 0) or "ok"
        button.glow:SetShown(level ~= "ok" and ns.db.warn.glow)
        ns.Warn.Hand(hand, level, state)
    end
end

function Buttons.ResetPosition()
    if not bar then return end
    ns.db.point = nil
    ns.WhenSafe("position", RestorePosition)
end
