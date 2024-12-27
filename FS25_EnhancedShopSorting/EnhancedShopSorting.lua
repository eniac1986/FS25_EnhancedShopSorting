--[[
SHORT DESCRIPTION OF WHAT YOUR MOD DOES GOES HERE

Author:     YOUR NAME/NICKNAME
Version:    1.0.0
Modified:   2024-12-27

Changelog:

]]

EnhancedShopSorting = Mod:init()

Log:info("This is a test") -- This will output one line in the log with a prefix of your mod's name (requires the LogHelper.lua to be referenced in modDesc.xml)
Log:debug("This only works in 'debug' mode") -- This will output one line in the log only if you have the DebugHelper.lua in your lib folder

SortOrder = {}
SortOrder.ASCENDING = 1
SortOrder.DESCENDING = 2

SortMethod = {}
SortMethod.PRICE = 1
SortMethod.NAME = 2
SortMethod.SPEED = 3
SortMethod.POWER = 4
SortMethod.CAPACITY = 5
SortMethod.WORKINGWIDTH = 6
SortMethod.WORKINGSPEED = 7
SortMethod.WEIGHT = 8

GroupMethod = {}
GroupMethod.NONE = 1
GroupMethod.MODS = 2


-- -- Event that is executed when your mod is loading (after the map has been loaded and before the game starts)
-- function EnhancedShopSorting:loadMap(filename)
-- end

-- -- Event that is executed when the player chooses to start the mission (after the map has been loaded and before the game starts)
-- function EnhancedShopSorting:startMission()
-- end

function EnhancedShopSorting:sortDisplayItems(items)
    Log:debug("EnhancedShopSorting.sortDisplayItems")
    Log:debug("SortOrder: %d, SortMethod: %d, GroupMethod: %d", self.sortOrder, self.sortMethod, self.groupMethod)

    local SORT_ORDER_ASC = true

    local function sortItems_sortOrder(sortValue)
        if SORT_ORDER_ASC then
            return sortValue
        else
            return not sortValue
        end
    end
    
    local function sortItems_byPrice(item1, item2)
        local item1 = item1.storeItem or item1
        local item2 = item2.storeItem or item2
        
        return sortItems_sortOrder(item1.price <  item2.price)
        
    end
    
    local function sortItems_byName(item1, item2)
        local item1 = item1.storeItem or item1
        local item2 = item2.storeItem or item2
        
        return sortItems_sortOrder(string.byte(item1.name) < string.byte( item2.name))
        
    end
    
    -- table.sort(g_shopMenu.currentDisplayItems, sortItems_byName)
    table.sort(items, sortItems_byName)
    -- g_shopMenu.pageShopItemDetails:setDisplayItems(g_shopMenu.currentDisplayItems)
    
    
end

function EnhancedShopSorting:updateDisplayItems()
    Log:debug("EnhancedShopSorting.updateDisplayItems")
    g_shopMenu.pageShopItemDetails:setDisplayItems(g_shopMenu.currentDisplayItems)
end

function EnhancedShopSorting:initMission()
    self.sortOrder = SortOrder.ASCENDING
    self.sortMethod = SortMethod.PRICE
    self.groupMethod = GroupMethod.MODS
end

function EnhancedShopSorting:getItemsByCategory(shopController, superFunc, ...)
    Log:debug("ShopController.getItemsByCategory")

    local items = superFunc(shopController, ...)

    local function sortItems_byPrice(item1, item2)
        local item1 = item1.storeItem or item1
        local item2 = item2.storeItem or item2
        
        return item1.price <  item2.price
        
    end

    table.sort(items, sortItems_byPrice)


    for i = 1, #items do
        Log:debug("#%d: %s [%d]: %d", i, items[i].storeItem.name, items[i].storeItem.id, items[i].orderValue)
    end

    return items
end

-- function EnhancedShopSorting:setDisplayItems(self, superFunc, items, ...)

--     return superFunc(self, items, ...)
-- end

ShopItemsFrame.setDisplayItems = Utils.overwrittenFunction(ShopItemsFrame.setDisplayItems, function(self, superFunc, items, ...)
    Log:debug("ShopItemsFrame.setDisplayItems")
    Log:var("items", items)
    if items and #items > 0 then 
        EnhancedShopSorting:sortDisplayItems(items)
    end
    -- EnhancedShopSorting:sortDisplayItems(items)
    return superFunc(self, items, ...)
end)

-- ShopController.getItemsByCategory = Utils.overwrittenFunction(ShopController.getItemsByCategory, function(self, superFunc, ...)
--     return EnhancedShopSorting:getItemsByCategory(self, superFunc, ...)
-- end)
