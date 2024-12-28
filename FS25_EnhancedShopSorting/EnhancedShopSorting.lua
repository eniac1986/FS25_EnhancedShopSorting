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
-- Enum(SortOrder)

SortMethod = {}
SortMethod.PRICE = 1
SortMethod.NAME = 2
SortMethod.SPEED = 3
SortMethod.POWER = 4
SortMethod.WEIGHT = 5
-- SortMethod.CAPACITY = 6
-- SortMethod.WORKINGWIDTH = 7
-- SortMethod.WORKINGSPEED = 8
-- Enum(SortMethod)

GroupMethod = {}
GroupMethod.NONE = 1
GroupMethod.MODS = 2
-- Enum(GroupMethod)

function EnhancedShopSorting:sortDisplayItems(items)
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
    end

    local sortCallbacks = {}

    local function getItems(item1, item2)
        return item1.storeItem or item1, item2.storeItem or item2
    end

    local function defaultDelegate(item1, item2)
        local item1, item2 = getItems(item1, item2)
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
        return applySortOptions(speed1 < speed2)
    end

    sortCallbacks[SortMethod.POWER] = function(item1, item2)
        local item1, item2 = getItems(item1, item2)
        local speed1 = safeGetValue(item1, "specs.power")
        local speed2 = safeGetValue(item2, "specs.power")
        return applySortOptions(speed1 < speed2)
    end    

    sortCallbacks[SortMethod.WEIGHT] = function(item1, item2)
        local item1, item2 = getItems(item1, item2)
        local weight1 = safeGetValue(item1, "specs.weight.componentMass") + safeGetValue(item1, "specs.weight.wheelMassDefaultConfig")
        local weight2 = safeGetValue(item2, "specs.weight.componentMass") + safeGetValue(item2, "specs.weight.wheelMassDefaultConfig")
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
                
                return not item1.isMod and item2.isMod        
            end)
        else
            -- Log:debug("GroupMethod.NONE")
            table.sort(items, sortDelegate)
        end

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

    EnhancedShopSorting.enumToName = {}
    EnhancedShopSorting.enumToName[SortMethod] = "sortMethod"
    EnhancedShopSorting.enumToName[SortOrder] = "sortOrder"
    EnhancedShopSorting.enumToName[GroupMethod] = "groupMethod"
end

function EnhancedShopSorting:getItemsByCategory(shopController, superFunc, ...)
    -- Log:debug("ShopController.getItemsByCategory")

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

    local dialogTitle = g_i18n:getText("dialogTitle") or g_modManager.nameToMod[g_currentModName].title

    local function getOptionsTranslated(enum)
        local options = {}
        local enumName = self.enumToName[enum]
        for i = 1, EnumUtil.getNumEntries(enum) do
            local itemName = EnumUtil.getName(enum, i) or "UNKNOWN"
            local translationKey = string.format("enum_%s_%s", enumName, itemName:lower())
            -- Log:debug("enum: %s, index %d, itemName: %s, translationKey: %s", enumName, i, itemName, translationKey)
            -- Log:var("translationKey" , translationKey)
            options[i] = g_i18n:getText(translationKey)
        end
        return options
        
    end

    local function showOption(text, currentState, enum, callback)
        OptionDialog.createFromExistingGui({
            callbackFunc = callback,
            optionText = text,
            optionTitle = dialogTitle,
            options = getOptionsTranslated(enum),
        })
        OptionDialog.INSTANCE.optionElement:setState( currentState or 1)
    end

    showOption(g_i18n:getText("choose_sortMethod"), self.sortMethod, SortMethod, function(chosenMethod)
        Log:debug("callbackFunc state: %s", chosenMethod)
        
        if chosenMethod == 0 then
            return
        end

        self.sortMethod = chosenMethod

        -- Log:debug("self.sortMethod: %s", self.sortMethod)

        showOption(g_i18n:getText("choose_sortOrder"), self.sortOrder, SortOrder, function(chosenOrder)
            Log:debug("callbackFunc state: %s", chosenOrder)

            if chosenOrder == 0 then
                return
            end

            self.sortOrder = chosenOrder
    
            showOption(g_i18n:getText("choose_groupMethod"), self.groupMethod, GroupMethod, function(chosenGrouping)
                Log:debug("callbackFunc state: %s", chosenGrouping)

                if chosenGrouping == 0 then
                    return
                end

                self.groupMethod = chosenGrouping
                EnhancedShopSorting:updateDisplayItems()
            end)
        end)
    end)
end

function EnhancedShopSorting:mainKeyEvent()
    Log:debug("EnhancedShopSorting.keyDummy")
    if g_shopMenu.isOpen then
        self:showDialog()
    end
end

function EnhancedShopSorting:registerHotkeys()
    local triggerUp, triggerDown, triggerAlways, startActive, callbackState, disableConflictingBindings = false, true, false, true, nil, true
    local success, actionEventId, otherEvents = g_inputBinding:registerActionEvent(InputAction.SORT_SHOP, self, self.mainKeyEvent, triggerUp, triggerDown, triggerAlways, startActive, callbackState, disableConflictingBindings)

    if success then
        Log:debug("Registered main key for EnhancedShopSorting")
        g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_LOW)
    -- else
    --     Log:debug("Failed to register main key for EnhancedShopSorting")
    end    
    
end

ShopItemsFrame.setDisplayItems = Utils.overwrittenFunction(ShopItemsFrame.setDisplayItems, function(self, superFunc, items, ...)
    if items and #items > 0 then 
        EnhancedShopSorting:sortDisplayItems(items)
    end
    return superFunc(self, items, ...)
end)

TabbedMenuWithDetails.onOpen = Utils.overwrittenFunction(TabbedMenuWithDetails.onOpen, function(self, superFunc, ...)
    local returnValue superFunc(self, ...)

    if g_shopMenu.isOpen then
        EnhancedShopSorting:registerHotkeys()
    end
    
    return returnValue
end)

