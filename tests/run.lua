-- Nullgate's Poisons: tests for the poison data, picking, weapon states, warnings and crafting.
-- Run from the repository root:  lua tests/run.lua   (Lua 5.1 or newer)

local source = debug.getinfo(1, "S").source or ""
local script = source:match("^@(.*)$") or "tests/run.lua"
local scriptDir = script:match("^(.*)[/\\][^/\\]*$") or "."
local root = (scriptDir:match("^(.*)[/\\][^/\\]*$") or ".") .. "/NullgatesPoisons-Forever/"

local ns = { L = setmetatable({}, { __index = function(_, k) return k end }) }
local function Load(file) assert(loadfile(root .. file), "cannot load " .. file)("NullgatesPoisons-Forever", ns) end
Load("Data/Poisons.lua")
Load("Poisons.lua")
Load("Warn.lua")
local P, W = ns.Poisons, ns.Warn

local checks, failures = 0, 0
local function EQ(got, want, name)
    checks = checks + 1
    if got ~= want then
        failures = failures + 1
        print(string.format("FAIL %s: expected %s, got %s", name, tostring(want), tostring(got)))
    end
end

-- --- The data ---------------------------------------------------------------------
EQ(type(ns.POISON_DATA_BUILD), "string", "the data names its client build")
EQ(ns.POISON_TYPES[1], "instant", "Instant Poison comes first")
local enchants = {}
for _, kind in ipairs(ns.POISON_TYPES) do
    EQ(type(ns.POISON_NAMES[kind]), "string", kind .. " has a name")
    for i, p in ipairs(ns.POISONS[kind]) do
        EQ(p.item > 0 and p.enchant > 0 and #p.reagents > 0, true, kind .. " rank " .. i .. " is complete")
        EQ(enchants[p.enchant], nil, "enchant " .. p.enchant .. " belongs to one poison")
        enchants[p.enchant] = true
    end
end
EQ(#ns.POISONS.instant, 6, "six ranks of Instant Poison")

-- --- Picking ------------------------------------------------------------------------
local bags = {}
P.Count = function(id) return bags[id] or 0 end
EQ(P.Best("instant", 60), nil, "nothing carried: nothing to apply")
bags[6947], bags[6950], bags[8928] = 5, 10, 3 -- Instant I, III, VI
local best, n = P.Best("instant", 60)
EQ(best.item, 8928, "level 60: the highest rank carried (Instant VI)")
EQ(n, 3, "with its count")
EQ(P.Best("instant", 40).item, 6950, "level 40 can't use rank VI: Instant III")
EQ(P.Total("instant"), 18, "total Instant Poison carried")
local a = P.Attributes("off", best)
EQ(a.type1 == "item" and a.item1 == "item:8928" and a["target-slot1"] == 17, true, "off hand: item button aimed at slot 17")
EQ(P.Attributes("main", best)["target-slot1"], 16, "main hand: slot 16")
EQ(P.Attributes("main", nil).type1, nil, "nothing to apply: no action")

-- --- Weapon states --------------------------------------------------------------------
local kind = P.FromEnchant(ns.POISONS.deadly[5].enchant)
EQ(kind, "deadly", "an enchant ID maps back to its poison")
EQ(P.FromEnchant(12345678), nil, "an unknown enchant isn't a poison")
local s = P.State(true, 754000, 40, ns.POISONS.instant[6].enchant)
EQ(s.kind == "instant" and s.seconds == 754 and s.charges == 40, true, "a weapon state from GetWeaponEnchantInfo")
EQ(P.Level(P.State(false), 300, 10), "none", "no poison")
EQ(P.Level(s, 300, 10), "ok", "12 minutes and 40 charges: fine")
EQ(P.Level(P.State(true, 200000, 40, 1), 300, 10), "low", "under 5 minutes: low")
EQ(P.Level(P.State(true, 900000, 6, 1), 300, 10), "low", "under 10 charges: low")
EQ(P.Level(P.State(true, 900000, 0, 1), 300, 10), "ok", "no charge count: only time matters")
EQ(P.Level(P.State(true, 100000, 40, 1), 0, 10), "ok", "time warning off")
EQ(P.Short(754), "12m", "minutes")
EQ(P.Short(45), "45s", "seconds")

-- --- Warnings ---------------------------------------------------------------------------
EQ(W.ShouldWarn("ok", "low"), true, "warn when it starts running low")
EQ(W.ShouldWarn("low", "low"), false, "but only once")
EQ(W.ShouldWarn("ok", "none"), true, "warn when it runs out")
EQ(W.ShouldWarn("low", "none"), true, "and when low becomes none")
EQ(W.ShouldWarn("none", "ok"), false, "no warning when it's fixed")
EQ(W.ShouldWarn("none", "low"), false, "nor for a short poison just applied")

-- --- Crafting -----------------------------------------------------------------------------
local instantVI = ns.POISONS.instant[6] -- Dust of Deterioration x4, Crystal Vial x1
bags = { [8924] = 13, [8925] = 5 }
EQ(P.Craftable(instantVI), 3, "13 dust and 5 vials: 3 crafts (dust runs out first)")
bags = { [8924] = 13 }
EQ(P.Craftable(instantVI), 0, "no vials: none")
EQ(P.TopRank("instant", 45).item, ns.POISONS.instant[4].item, "the top rank at level 45 is Instant IV")

print(string.format("%d checks, %d failure(s)", checks, failures))
if failures > 0 then os.exit(1) end
