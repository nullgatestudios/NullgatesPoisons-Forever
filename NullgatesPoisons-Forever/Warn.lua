-- Nullgate's Poisons: expiry warnings. Each hand warns once when its poison is missing or running
-- low (chat line and/or sound; the glow is drawn by the buttons), and again only after it's fixed.
local _, ns = ...

local L = ns.L
local Warn = {}
ns.Warn = Warn

local last = {} -- [hand] = "none" | "low" | "ok"

-- Pure: whether to warn when a hand goes from `before` to `now`.
function Warn.ShouldWarn(before, now)
    return now ~= "ok" and before ~= now and not (before == "none" and now == "low")
end

function Warn.Hand(hand, level, state)
    local before = last[hand] or "ok"
    last[hand] = level
    if not Warn.ShouldWarn(before, level) then return end
    local settings = ns.db.warn
    local handName = hand == "main" and L["Main hand"] or L["Off hand"]
    if settings.chat then
        if level == "none" then
            ns.Print(string.format(L["%s has no poison."], handName))
        else
            ns.Print(string.format(L["%s poison is running low (%s left)."], handName, ns.Poisons.Short(state.seconds)))
        end
    end
    if settings.sound and PlaySound then PlaySound((SOUNDKIT and SOUNDKIT.RAID_WARNING) or 8959, "Master") end
end
