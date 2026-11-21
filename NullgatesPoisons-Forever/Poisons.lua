-- Nullgate's Poisons: which poison to apply, what's on each weapon, when to warn and what can be
-- crafted. No game calls except through Poisons.Count, which the tests replace.
local _, ns = ...

local Poisons = {}
ns.Poisons = Poisons

Poisons.SLOTS = { main = 16, off = 17 }

function Poisons.Count(itemID)
    local count = (C_Item and C_Item.GetItemCount) or GetItemCount
    return (count and count(itemID)) or 0
end

-- The best poison of a type you carry and can use at your level: the rank entry and its count, or nil.
function Poisons.Best(kind, level)
    local best, count
    for _, p in ipairs(ns.POISONS[kind] or {}) do
        if p.level <= level then
            local n = Poisons.Count(p.item)
            if n > 0 then best, count = p, n end
        end
    end
    return best, count
end

-- How many applications of a type you carry in total.
function Poisons.Total(kind)
    local total = 0
    for _, p in ipairs(ns.POISONS[kind] or {}) do total = total + Poisons.Count(p.item) end
    return total
end

-- The secure attributes for applying a poison to a hand. Left-click only (the 1 suffix), so
-- right-click is free for choosing the poison.
function Poisons.Attributes(hand, poison)
    if not poison then return { type1 = nil, item1 = nil, ["target-slot1"] = nil } end
    return { type1 = "item", item1 = "item:" .. poison.item, ["target-slot1"] = Poisons.SLOTS[hand] }
end

-- The poison type and rank for a weapon enchant ID, or nil (not a known poison).
local byEnchant
function Poisons.FromEnchant(enchantID)
    if not byEnchant then
        byEnchant = {}
        for _, kind in ipairs(ns.POISON_TYPES) do
            for _, p in ipairs(ns.POISONS[kind]) do byEnchant[p.enchant] = { kind = kind, poison = p } end
        end
    end
    local hit = enchantID and byEnchant[enchantID]
    if hit then return hit.kind, hit.poison end
end

-- One hand from GetWeaponEnchantInfo: { has =, kind =, seconds =, charges = }.
function Poisons.State(has, expirationMs, charges, enchantID)
    if not has then return { has = false, seconds = 0, charges = 0 } end
    return { has = true, kind = Poisons.FromEnchant(enchantID), seconds = math.floor((expirationMs or 0) / 1000),
             charges = charges or 0 }
end

-- "none" (no poison), "low" (under the time or charge limit) or "ok". Charges of 0 mean the
-- poison has no charge count, so only time matters.
function Poisons.Level(state, minSeconds, minCharges)
    if not state.has then return "none" end
    if minSeconds > 0 and state.seconds < minSeconds then return "low" end
    if minCharges > 0 and state.charges > 0 and state.charges < minCharges then return "low" end
    return "ok"
end

-- How many applications you could craft of a rank from the reagents you carry.
function Poisons.Craftable(poison)
    if not poison or #poison.reagents == 0 then return 0 end
    local crafts
    for _, r in ipairs(poison.reagents) do
        local n = math.floor(Poisons.Count(r[1]) / r[2])
        crafts = crafts and math.min(crafts, n) or n
    end
    return (crafts or 0) * (poison.makes or 1)
end

-- The highest rank of a type usable at a level (for the crafting count), carried or not.
function Poisons.TopRank(kind, level)
    local top
    for _, p in ipairs(ns.POISONS[kind] or {}) do
        if p.level <= level then top = p end
    end
    return top
end

-- 754 -> "12m", 45 -> "45s".
function Poisons.Short(seconds)
    if seconds >= 60 then return math.floor(seconds / 60) .. "m" end
    return seconds .. "s"
end
