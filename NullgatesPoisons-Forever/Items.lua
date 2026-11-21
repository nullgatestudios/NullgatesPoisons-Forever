-- Nullgate's Poisons: item names.
local _, ns = ...

local Items = {}
ns.Items = Items

function Items.Name(itemID)
    local info = (C_Item and C_Item.GetItemInfo) or GetItemInfo
    return info and (info(itemID)) or nil
end
