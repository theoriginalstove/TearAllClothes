require "ISUI/ISInventoryPaneContextMenu"

-- check to see
local function skipInventoryItem(playerObj, container, skipInventory)
    local playerInv = playerObj:getInventory()
    if (skipInventory) and (container == playerInv) then 
        print("Skipping inventory item")  -- for debugging
        return true
    end
    return false
end

local function getAllClothingItems(playerObj, skipInventory)
    local clothingItems = {}
    local containers = ISInventoryPaneContextMenu.getContainers(playerObj)
    for i = 0, containers:size()-1 do
        local container = containers:get(i)
        local containerItems = container:getItems()
        for j = 0, containerItems:size()-1 do
            local item = containerItems:get(j)
            if (instanceof(item, "Clothing") and item:getFabricType()) and
                not (playerObj:isEquipped(item) or item:isFavorite()) and
                not skipInventoryItem(playerObj, container, skipInventory) then
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

local function tearSelectedClothing(player, clothingItems)
    for _, clothingItem in ipairs(clothingItems) do
        local hasRequired = playerHasToolRequired(player, clothingItem)
        if (not (player:isEquipped(clothingItem) or clothingItem:isFavorite()) and hasRequired) then
            ISInventoryPaneContextMenu.transferIfNeeded(player, clothingItem)
            ISTimedActionQueue.add(ISTearingClothing:new(player, clothingItem))
        end
    end
end


local function tearClothing(player, skipInventoryItems)
    print("Skip inventory items: ", skipInventoryItems)
    local clothingItems = getAllClothingItems(player, skipInventoryItems)
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
        if ctxitem["items"] then
            if ctxitem.items[1]:getCategory() == "Clothing" and not ctxitem.equipped then
                table.insert(selectedClothingItems, ctxitem.items[1])
                clothingItemsTotal = clothingItemsTotal + 1
            end
        else 
            if ctxitem:getCategory() == "Clothing" and not playerObj:isEquipped(ctxitem) then
                print("Inventory Item was expanded")
                table.insert(selectedClothingItems, ctxitem)
                clothingItemsTotal = clothingItemsTotal + 1
            end
        end
    end

    if clothingItemsTotal >= 1 then
        local menuText = "Tear Clothing"
        local option = context:insertOptionAfter("Grab", getText("ContextMenu_TearClothingMenu"))
        option.iconTexture = getTexture("media/textures/Item_Jacket_HideDeer.png")

        local subMenu = context:getNew(context)
        context:addSubMenu(option, subMenu)
        local selectedOption = subMenu:addOption(getText("ContextMenu_TearClothingSelected"), playerObj, tearSelectedClothing,
            selectedClothingItems)
        selectedOption.iconTexture = getTexture("media/textures/target.png")
        local surroundingOption = subMenu:addOption(getText("ContextMenu_TearClothingSurrounding"), playerObj, tearClothing, true)
        surroundingOption.iconTexture = getTexture("media/textures/radar.png")
        local allOption = subMenu:addOption(getText("ContextMenu_TearClothingAll"), playerObj, tearClothing, false)
        allOption.iconTexture = getTexture("media/textures/globe.png")
    end
end


Events.OnFillInventoryObjectContextMenu.Add(createRipClothingMenu)
