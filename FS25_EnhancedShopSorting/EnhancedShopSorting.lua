--[[
SHORT DESCRIPTION OF WHAT YOUR MOD DOES GOES HERE

Author:     YOUR NAME/NICKNAME
Version:    1.0.0
Modified:   2024-12-28

Changelog:

]]

EnhancedShopSorting = Mod:init()

SortOrder = {}
SortOrder.ASCENDING = 1
SortOrder.DESCENDING = 2
Enum(SortOrder)

SortMethod = {}
SortMethod.PRICE = 1
SortMethod.NAME = 2
SortMethod.SPEED = 3
SortMethod.POWER = 4
SortMethod.WEIGHT = 5
-- SortMethod.CAPACITY = 6
-- SortMethod.WORKINGWIDTH = 7
-- SortMethod.WORKINGSPEED = 8
Enum(SortMethod)

GroupMethod = {}
GroupMethod.NONE = 1
GroupMethod.MODS = 2
Enum(GroupMethod)


-- -- Event that is executed when your mod is loading (after the map has been loaded and before the game starts)
-- function EnhancedShopSorting:loadMap(filename)
-- end

-- -- Event that is executed when the player chooses to start the mission (after the map has been loaded and before the game starts)
-- function EnhancedShopSorting:startMission()
-- end



function EnhancedShopSorting:sortDisplayItems(items)
    -- Log:debug("EnhancedShopSorting.sortDisplayItems")
    Log:debug("EnhancedShopSorting.sortDisplayItems> SortOrder: %d, SortMethod: %d, GroupMethod: %d", self.sortOrder, self.sortMethod, self.groupMethod)

    if items == nil then
        Log:debug("WARN: No items to sort")
        return
    end    
    
    local SORT_ORDER_ASC = (self.sortOrder == SortOrder.ASCENDING)

    

    local function applySortOptions(sortValue)
        if SORT_ORDER_ASC then
            return sortValue
        else
            return not sortValue
        end
    end

    local function safeGetValue(t, namedValues, default)
        default = default or 0

        local values = string.split(namedValues, ".")
    
        for i = 1, #values do
            local k = values[i]
            t = t[k]
    
            if t == nil then
                return default
            end
        end
    
        return t or default
        
        -- local specs = item1 and item1.specs
        -- if specs == nil then
        --     return 0
        -- end
        -- return specs[namedValue] or 0
    end

    local sortCallbacks = {}
    local isFirst = true

    local function getItems(item1, item2)
        return item1.storeItem or item1, item2.storeItem or item2
    end

    local function defaultDelegate(item1, item2)
        -- if isFirst then 
        --     isFirst = false
        --     Log:table("item1", item1, 1)
        -- end
        local item1, item2 = getItems(item1, item2)
        -- Log:debug("item1.price: %d, item2.price: %d", item1.price, item2.price)
        return  item1.price <  item2.price
    end

    sortCallbacks[SortMethod.PRICE] = function(item1, item2)
        local item1, item2 = getItems(item1, item2)
        return applySortOptions(defaultDelegate(item1, item2))
    end

    sortCallbacks[SortMethod.NAME] = function(item1, item2)
        local item1, item2 = getItems(item1, item2)
        return applySortOptions(item1.name < item2.name)
    end

    sortCallbacks[SortMethod.SPEED] = function(item1, item2)
        local item1, item2 = getItems(item1, item2)
        local speed1 = safeGetValue(item1, "specs.maxSpeed")
        local speed2 = safeGetValue(item2, "specs.maxSpeed")

        -- Log:debug("speed1: %d, speed2: %d", speed1, speed2)
        
        return applySortOptions(speed1 < speed2)
    end

    sortCallbacks[SortMethod.WEIGHT] = function(item1, item2)
        local item1, item2 = getItems(item1, item2)
        local weight1 = safeGetValue(item1, "specs.weight.componentMass") + safeGetValue(item1, "specs.weight.wheelMassDefaultConfig")
        local weight2 = safeGetValue(item2, "specs.weight.componentMass") + safeGetValue(item2, "specs.weight.wheelMassDefaultConfig")

        -- Log:debug("#%d: weight1: %d, weight2: %d", item1.id, weight1, weight2)
        
        return applySortOptions(weight1 < weight2)
    end

    -- table.sort(g_shopMenu.currentDisplayItems, sortItems_byName)
    local sortDelegate = sortCallbacks[self.sortMethod]

    if sortDelegate ~= nil then
        -- Primary sort based on method
        if self.groupMethod == GroupMethod.MODS then
            -- Log:debug("GroupMethod.MODS")
            table.sort(items, function(item1, item2)
                local item1, item2 = getItems(item1, item2)
                if item1.isMod == item2.isMod then
                    return sortDelegate(item1, item2)
                end
                
                -- Log:debug("Item 1 is mod: %s, Item 2 is mod: %s", tostring(item1.isMod), tostring(item2.isMod))
                -- return applySortOptions(not item1.isMod and item2.isMod)
                return not item1.isMod and item2.isMod
        
            end)
        else
            -- Log:debug("GroupMethod.NONE")
            table.sort(items, sortDelegate)
        end

        -- -- Secondary sort based on group method
        -- if self.groupMethod == GroupMethod.MODS then
        --     table.sort(items, function(item1, item2)
        --         local item1 = item1.storeItem or item1
        --         local item2 = item2.storeItem or item2
        --         return not item1.isMod and item2.isMod
        --     end)
        -- end
        
    else
        Log:warning("Sort method not implemented: %s [%d]", SortMethod.getName(self.sortMethod), self.sortMethod)
    end
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

    -- Log:var("g_shopMenu", g_shopMenu)

    -- g_shopMenu.onOpen = Utils.overwrittenFunction(g_shopMenu.onOpen, function(self, superFunc, ...)
    --     Log:debug("g_shopMenu.onOpen")
    --     return superFunc(self, ...)
    -- end)
    
    -- g_shopMenu.onClose = Utils.overwrittenFunction(g_shopMenu.onClose, function(self, superFunc, ...)
    --     Log:debug("g_shopMenu.onClose")
    --     return superFunc(self, ...)
    -- end)
    
    -- g_shopMenu.onClickItemCategory = Utils.overwrittenFunction(g_shopMenu.onClickItemCategory, function(self, superFunc, ...)
    --     Log:debug("g_shopMenu.onClickItemCategory")
    --     return superFunc(self, ...)
    -- end)
    
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


    -- for i = 1, #items do
    --     Log:debug("#%d: %s [%d]: %d", i, items[i].storeItem.name, items[i].storeItem.id, items[i].orderValue)
    -- end

    return items
end

function EnhancedShopSorting:showDialog()

    local dialogTitle = "Enhanced Shop Sort" --TODO: l10n

    local function getOptionsTranslated(enum)
        local options = {}
        for i = 1, EnumUtil.getNumEntries(enum) do
            options[i] = EnumUtil.getName(enum, i)
        end
        return options
        
    end

    local function showOption(text, currentState, enum, callback)
        OptionDialog.createFromExistingGui({
            callbackFunc = callback,
            optionText = text, --TODO: l10n
            optionTitle = dialogTitle,
            options = getOptionsTranslated(enum),
        })
        -- Log:var("currentState", currentState)
        OptionDialog.INSTANCE.optionElement:setState( currentState or 1)
    end

    showOption("Choose SORT METHOD:", self.sortMethod, SortMethod, function(chosenMethod)
        Log:debug("callbackFunc state: %s", chosenMethod)
        
        if chosenMethod == 0 then
            return
        end

        self.sortMethod = chosenMethod

        -- Log:debug("self.sortMethod: %s", self.sortMethod)

        showOption("Choose SORT ORDER:", self.sortOrder, SortOrder, function(chosenOrder)
            Log:debug("callbackFunc state: %s", chosenOrder)

            if chosenOrder == 0 then
                return
            end

            self.sortOrder = chosenOrder
    
            showOption("Should mod equipment be grouped after base game items?", self.groupMethod, GroupMethod, function(chosenGrouping)
                Log:debug("callbackFunc state: %s", chosenGrouping)

                if chosenGrouping == 0 then
                    return
                end

                self.groupMethod = chosenGrouping
                    -- EnhancedShopSorting:sortDisplayItems(g_shopMenu.currentDisplayItems)
                EnhancedShopSorting:updateDisplayItems()
            end)
        end)
    end)
end

-- function EnhancedShopSorting:showDialog2()

    
    

--     local function showOptionDialog(callback)
--         OptionDialog.createFromExistingGui({
--             callbackFunc = callback,
--             optionText = "Enhanced Shop Sort",
--             optionTitle = "Choose sort option to change:",
--             options = {
--                 "Sort Method [" .. EnumUtil.getName(SortMethod, self.sortMethod) .. "]",
--                 "Sort Order [" .. EnumUtil.getName(SortOrder, self.sortOrder) .. "]",
--                 "Grouping Method [" .. EnumUtil.getName(GroupMethod, self.groupMethod) .. "]",
--             }
--         })
        
--     end

--     local function dialogCallback(state)
--         Log:debug("callbackFunc state: %s", state)
--         if state == 0 then
--             g_shopMenu.pageShopItemDetails:setDisplayItems(g_shopMenu.currentDisplayItems)
--             return
--         elseif state == 1 then
--             EnhancedShopSorting.sortMethod = self.sortMethod + 1
--             if EnhancedShopSorting.sortMethod > 8 then
--                 EnhancedShopSorting.sortMethod = 1
--             end
--         elseif state == 2 then
--             EnhancedShopSorting.sortOrder = EnhancedShopSorting.sortOrder + 1
--             if EnhancedShopSorting.sortOrder > 2 then
--                 EnhancedShopSorting.sortOrder = 1
--             end
--         elseif state == 3 then
--             EnhancedShopSorting.groupMethod = EnhancedShopSorting.groupMethod + 1
--             if EnhancedShopSorting.groupMethod > 2 then
--                 EnhancedShopSorting.groupMethod = 1
--             end
--         end
--         -- showOptionDialog(dialogCallback)
        
--     end

--     -- if false then dialogCallback() end

--     showOptionDialog(dialogCallback)

-- end

function EnhancedShopSorting:mainKeyEvent()
    Log:debug("EnhancedShopSorting.keyDummy")
    if g_shopMenu.isOpen then
        self:showDialog()
    end
end

function EnhancedShopSorting:registerHotkeys()
    -- Log:debug("EnhancedShopSorting.registerHotkeys")
    local triggerUp, triggerDown, triggerAlways, startActive, callbackState, disableConflictingBindings = false, true, false, true, nil, true
    local success, actionEventId, otherEvents = g_inputBinding:registerActionEvent(InputAction.SORT_SHOP, self, self.mainKeyEvent, triggerUp, triggerDown, triggerAlways, startActive, callbackState, disableConflictingBindings)

    if success then
        Log:debug("Registered main key for EnhancedShopSorting")
        g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_LOW)
    -- else
    --     Log:debug("Failed to register main key for EnhancedShopSorting")
    --     Log:var("state", success)
    --     Log:var("actionId", actionEventId)
    end    
    
end

-- PlayerInputComponent.registerGlobalPlayerActionEvents = Utils.appendedFunction(PlayerInputComponent.registerGlobalPlayerActionEvents, function()
--     EnhancedShopSorting:mainKeyEvent()
-- end)

-- function EnhancedShopSorting:setDisplayItems(self, superFunc, items, ...)

--     return superFunc(self, items, ...)
-- end

ShopItemsFrame.setDisplayItems = Utils.overwrittenFunction(ShopItemsFrame.setDisplayItems, function(self, superFunc, items, ...)
    -- Log:debug("ShopItemsFrame.setDisplayItems")
    -- Log:var("items", items)
    if items and #items > 0 then 
        EnhancedShopSorting:sortDisplayItems(items)
    end
    -- EnhancedShopSorting:sortDisplayItems(items)
    return superFunc(self, items, ...)
end)

-- ShopController.getItemsByCategory = Utils.overwrittenFunction(ShopController.getItemsByCategory, function(self, superFunc, ...)
--     return EnhancedShopSorting:getItemsByCategory(self, superFunc, ...)
-- end)


-- ShopMenu.onOpen = Utils.overwrittenFunction(ShopMenu.onOpen, function(self, superFunc, ...)
--     Log:debug("ShopMenu.onOpen")
--     return superFunc(self, ...)
-- end)

-- ShopMenu.onClose = Utils.overwrittenFunction(ShopMenu.onClose, function(self, superFunc, ...)
--     Log:debug("ShopMenu.onClose")
--     return superFunc(self, ...)
-- end)

-- -- ShopMenu.onClickMenu = Utils.overwrittenFunction

-- ShopMenu.exitMenu = Utils.overwrittenFunction(ShopMenu.exitMenu, function(self, superFunc, ...)
--     Log:debug("ShopMenu.exitMenu")
--     return superFunc(self, ...)
-- end)

-- ShopMenu.onClickItemCategory = Utils.overwrittenFunction(ShopMenu.onClickItemCategory, function(self, superFunc, ...)
--     Log:debug("ShopMenu.onClickItemCategory")
--     return superFunc(self, ...)
-- end)

TabbedMenuWithDetails.onOpen = Utils.overwrittenFunction(TabbedMenuWithDetails.onOpen, function(self, superFunc, ...)
    -- Log:debug("TabbedMenuWithDetails.onOpen")
    
    local returnValue superFunc(self, ...)
    -- Log:var("g_shopMenu.isOpen", g_shopMenu.isOpen)
    if g_shopMenu.isOpen then
        EnhancedShopSorting:registerHotkeys()
    end
    
    return returnValue
end)

-- TabbedMenuWithDetails.onDetailOpened = Utils.overwrittenFunction(TabbedMenuWithDetails.onDetailOpened, function(self, superFunc, ...)
--     Log:debug("TabbedMenuWithDetails.onDetailOpened")
--     return superFunc(self, ...)
-- end)