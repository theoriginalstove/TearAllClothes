require "ISUI/ISInventoryPaneContextMenu"


local function getSurroundingClothingItems(playerObj)
    local clothingItems = {}
    local containers = ISInventoryPaneContextMenu.getContainers(playerObj)
    for i = 0, containers:size()-1 do
        local container = containers:get(i)
        local containerItems = container:getItems()
        for j = 0, containerItems:size()-1 do
            local item = containerItems:get(j)
            if (instanceof(item, "Clothing") and item:getFabricType()) and not (playerObj:isEquipped(item) or item:isFavorite()) then
                table.insert(clothingItems, item)
            end
        end
    end
    return clothingItems
end

local function hasScissors(item)
    return not item:isBroken() and item:hasTag("Scissors")
end

local function hasKnife(item)
    return not item:isBroken() and item:hasTag("SharpKnife")
end

local function playerHasToolRequired(player, clothingItem)
    local hasRequiredTool = false
    local fabricType = clothingItem:getFabricType()
    if fabricType == "Cotton" then return true end

    local tool = player:getInventory():getFirstEvalRecurse(hasScissors) or
    player:getInventory():getFirstEvalRecurse(hasKnife)
    if tool ~= nil and fabricType ~= "Cotton" then
        return true
    end
end

local function ripSelectedClothing(player, clothingItems)
    for _, clothingItem in ipairs(clothingItems) do
        local hasRequired = playerHasToolRequired(player, clothingItem)
        if (not (player:isEquipped(clothingItem) or clothingItem:isFavorite()) and hasRequired) then
            ISInventoryPaneContextMenu.transferIfNeeded(player, clothingItem)
            ISTimedActionQueue.add(ISTearingClothing:new(player, clothingItem))
        end
    end
end


local function ripNearbyClothing(player)
    local clothingItems = getSurroundingClothingItems(player)
    for _, clothingItem in ipairs(clothingItems) do
        local hasRequired = playerHasToolRequired(player, clothingItem)
        if (not (player:isEquipped(clothingItem) or clothingItem:isFavorite()) and hasRequired) then
            ISInventoryPaneContextMenu.transferIfNeeded(player, clothingItem)
            ISTimedActionQueue.add(ISTearingClothing:new(player, clothingItem))
        end
    end
end

local function createRipClothingMenu(player, context, items)
    local playerObj = getSpecificPlayer(player)

    local selectedClothingItems = {}
    local clothingItemsTotal = 0
    -- the items are either a InventoryItem[] or ContextMenuItemStack[]
    for _, ctxitem in ipairs(items) do
        if ctxitem.items[1]:getCategory() == "Clothing" and not ctxitem.equipped then
            table.insert(selectedClothingItems, ctxitem.items[1])
            clothingItemsTotal = clothingItemsTotal + 1
        end
    end

    if clothingItemsTotal >= 1 then
        local menuText = "Tear Clothing"
        local option = context:insertOptionAfter("Grab", menuText)
        option.iconTexture = getTexture("media/textures/Item_Jacket_HideDeer.png")

        local subMenu = context:getNew(context)
        context:addSubMenu(option, subMenu)
        local selectedOption = subMenu:addOption("Tear Selected Clothing", playerObj, ripSelectedClothing,
            selectedClothingItems)
        local allOption = subMenu:addOption("Tear All Nearby Clothing", playerObj, ripNearbyClothing)
    end
end


Events.OnFillInventoryObjectContextMenu.Add(createRipClothingMenu)
