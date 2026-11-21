-- Nullgate's Poisons: smoke test of the whole addon with stand-in game API.
-- Loads the files in .toc order, logs in as a level 60 rogue and drives the two buttons, the
-- right-click menu, combat, weapon states, warnings, settings and /npoison check.
-- Run from the repository root:  lua tests/smoke.lua

local source = debug.getinfo(1, "S").source or ""
local script = source:match("^@(.*)$") or "tests/smoke.lua"
local scriptDir = script:match("^(.*)[/\\][^/\\]*$") or "."
local repo = scriptDir:match("^(.*)[/\\][^/\\]*$") or "."
local folder = "NullgatesPoisons-Forever"
local root = repo .. "/" .. folder .. "/"

local checks, failures = 0, 0
local function OK(cond, name)
    checks = checks + 1
    if not cond then failures = failures + 1; io.write("FAIL " .. name .. "\n") end
end

-- --- Stand-in game API ----------------------------------------------------------
local frames, printed = {}, {}
local function NewFrame(kind, name, _, template)
    local f = { kind = kind, name = name, template = template, scripts = {}, attributes = {}, events = {}, shown = false }
    setmetatable(f, { __index = function(_, key) if type(key) == "string" and key:match("^%u") then return function() return nil end end end })
    function f:SetScript(k, fn) self.scripts[k] = fn end
    function f:GetScript(k) return self.scripts[k] end
    function f:HookScript(k, fn) local old = self.scripts[k]; self.scripts[k] = function(...) if old then old(...) end fn(...) end end
    function f:RegisterEvent(e) self.events[e] = true end
    function f:SetAttribute(k, v) self.attributes[k] = v end
    function f:GetAttribute(k) return self.attributes[k] end
    function f:Show() self.shown = true end
    function f:Hide() self.shown = false end
    function f:SetShown(v) self.shown = v and true or false end
    function f:IsShown() return self.shown end
    function f:SetText(t) self.text = t end
    function f:GetText() return self.text end
    function f:SetChecked(v) self.checked = v end
    function f:GetChecked() return self.checked end
    function f:CreateFontString() return NewFrame("FontString") end
    function f:CreateTexture() return NewFrame("Texture") end
    frames[#frames + 1] = f
    if name then _G[name] = f end
    return f
end
CreateFrame = NewFrame
SlashCmdList = {}
UIParent = NewFrame("Frame", "UIParent")
GameTooltip = NewFrame("GameTooltip", "GameTooltip")
UISpecialFrames = {}
print = function(text) printed[#printed + 1] = tostring(text) end
local function Printed(fragment)
    for _, line in ipairs(printed) do if line:find(fragment, 1, true) then return true end end
    return false
end

local inCombat = false
function UnitClass() return "ROGUE", "ROGUE" end
function UnitLevel() return 60 end
function InCombatLockdown() return inCombat end
function GetBuildInfo() return "1.60.1", "70532", "Nov 2026", 16001 end
function PlaySound() end
local tickers = 0
C_Timer = { After = function(_, fn) fn() end, NewTicker = function() tickers = tickers + 1 end }
local weapons = { [16] = 1001, [17] = 1002 }
function GetInventoryItemID(_, slot) return weapons[slot] end
local enchant = { false, 0, 0, nil, false, 0, 0, nil }
function GetWeaponEnchantInfo() return unpack(enchant) end
unpack = unpack or table.unpack
local bags = {}
C_Item = {
    GetItemCount = function(id) return bags[id] or 0 end,
    GetItemIconByID = function(id) return "icon" .. id end,
    GetItemInfo = function(id) return "Item" .. id end,
}

-- --- Load the files in .toc order -----------------------------------------------
local ns = {}
local toc = assert(io.open(root .. folder .. ".toc", "r")):read("*a")
for line in toc:gmatch("[^\r\n]+") do
    if not line:match("^##") and line:match("%.lua$") then
        assert(loadfile(root .. line:gsub("\\", "/")))(folder, ns)
    end
end
local core
for _, f in ipairs(frames) do if f.events.PLAYER_LOGIN then core = f end end
local function Fire(event, ...) core.scripts.OnEvent(core, event, ...) end
Fire("ADDON_LOADED", folder)
local db = NullgatesPoisonsDB
OK(db.choice.main == "instant" and db.choice.off == "deadly", "defaults: Instant on the main hand, Deadly on the off hand")
OK(SLASH_NULLGATESPOISONS1 == "/npoison" and SLASH_NULLGATESPOISONS2 == "/poisons", "slash commands /npoison and /poisons")
OK(_G["BINDING_NAME_CLICK NullgatesPoisonsMainHand:LeftButton"] ~= nil, "the main hand key binding has a name")

-- --- Login with no poisons --------------------------------------------------------
Fire("PLAYER_LOGIN")
local mh, oh = NullgatesPoisonsMainHand, NullgatesPoisonsOffHand
OK(mh and oh and mh.template == "SecureActionButtonTemplate", "two secure buttons")
OK(mh.attributes.type1 == nil, "no poisons carried: nothing to apply")
OK(tickers == 1, "a timer refreshes the time left")
OK(not Printed("has no poison"), "no warning when you carry no poison at all")

-- --- Poisons in the bags ---------------------------------------------------------------
bags[8928], bags[20844] = 10, 10 -- Instant VI, Deadly V
Fire("BAG_UPDATE_DELAYED")
OK(mh.attributes.type1 == "item" and mh.attributes.item1 == "item:8928" and mh.attributes["target-slot1"] == 16, "main hand applies Instant VI to slot 16")
OK(oh.attributes.item1 == "item:20844" and oh.attributes["target-slot1"] == 17, "off hand applies Deadly V to slot 17")
OK(mh.attributes.type == nil and mh.attributes.type2 == nil, "right-click has no secure action")
OK(Printed("Main hand has no poison."), "now it warns that the main hand has no poison")
OK(mh.glow.shown, "and the button glows")

-- --- Applying: the weapon state ------------------------------------------------------------
local instantEnchant, deadlyEnchant = ns.POISONS.instant[6].enchant, ns.POISONS.deadly[5].enchant
enchant = { true, 1800000, 60, instantEnchant, true, 1800000, 60, deadlyEnchant }
printed = {}
Fire("UNIT_INVENTORY_CHANGED", "player")
OK(mh.timer.text == "30m / 60", "the button shows time and charges")
OK(not mh.glow.shown and #printed == 0, "fine: no glow, no warning")
OK(mh.state.kind == "instant" and oh.state.kind == "deadly", "the addon knows which poison is on each weapon")

-- --- Running low ---------------------------------------------------------------------------
enchant = { true, 200000, 60, instantEnchant, true, 1800000, 8, deadlyEnchant }
ns.Buttons.UpdateStatus()
OK(Printed("Main hand poison is running low (3m left)."), "main hand under 5 minutes warns")
OK(Printed("Off hand poison is running low"), "off hand under 10 charges warns")
printed = {}
ns.Buttons.UpdateStatus()
OK(#printed == 0, "no repeat warnings")

-- --- Right-click menu --------------------------------------------------------------------
mh.scripts.OnClick(mh, "RightButton", false)
OK(NullgatesPoisonsMenu and NullgatesPoisonsMenu.shown, "right-click opens the poison menu")
local crippling
for _, e in ipairs(NullgatesPoisonsMenu.entries) do if e.kind == "crippling" then crippling = e end end
bags[3776] = 5 -- Crippling Poison II
crippling.scripts.OnClick(crippling)
OK(db.choice.main == "crippling" and mh.attributes.item1 == "item:3776", "choosing Crippling switches the main hand")
OK(not NullgatesPoisonsMenu.shown, "and closes the menu")

-- --- Combat: changes wait --------------------------------------------------------------------
inCombat = true
db.choice.main = "instant"
ns.Buttons.Update()
OK(mh.attributes.item1 == "item:3776" and mh.stale, "in combat the button keeps its poison and is marked")
inCombat = false
Fire("PLAYER_REGEN_ENABLED")
OK(mh.attributes.item1 == "item:8928" and not mh.stale, "after combat the change applies")

-- --- No off-hand weapon ------------------------------------------------------------------------
weapons[17] = nil
enchant = { true, 1800000, 60, instantEnchant, false, 0, 0, nil }
printed = {}
ns.Buttons.UpdateStatus()
OK(not Printed("Off hand has no poison"), "no off-hand weapon: no warning")

-- --- Settings and /npoison check ------------------------------------------------------------
SlashCmdList.NULLGATESPOISONS("")
OK(NullgatesPoisonsOptions and NullgatesPoisonsOptions.shown, "/npoison opens the settings")
SlashCmdList.NULLGATESPOISONS("check")
local log = table.concat(db.check or {}, "\n")
OK(log:find("GetWeaponEnchantInfo=yes", 1, true), "check reports which calls exist")
OK(log:find("-> main instant", 1, true), "check reads the poison on the main hand")
OK(NullgatesPoisonsCheck and NullgatesPoisonsCheck.shown, "the check window opens")

io.write(string.format("smoke: %d checks, %d failure(s)\n", checks, failures))
if failures > 0 then os.exit(1) end
