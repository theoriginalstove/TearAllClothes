-- Code copied from server/recipecode.lua which was copied from TimedActions/ISRipClothing.lua
function Recipe.OnCreate.RipClothing(craftRecipeData, character)
    local items = craftRecipeData:getAllConsumedItems();
    -- 	local result = craftRecipeData:getAllCreatedItems():get(0);
    --     result:setName("I should not exist")
    --     -- TODO: fix removing items from player inventory not working
    --     result:Remove();
    -- --     character:removeFromHands(result)
    -- --     character:getInventory():Remove(result);
    -- --     sendRemoveItemFromContainer(character:getInventory(), result);

    local item = items:get(0) -- assumes any tool comes after this in recipes.txt

    -- either we come from clothingrecipesdefinitions or we simply check number of covered parts by the clothing and add
    local materials = nil
    local nbrOfCoveredParts = nil
    local maxTime = 0 -- TODO: possibly allow recipe to call Lua function to get maxTime for actions
    if ClothingRecipesDefinitions[item:getType()] then
        local recipe = ClothingRecipesDefinitions[item:getType()]
        materials = luautils.split(recipe.materials, ":");
        maxTime = tonumber(materials[2]) * 20;
    elseif ClothingRecipesDefinitions["FabricType"][item:getFabricType()] then
        materials = {};
        materials[1] = ClothingRecipesDefinitions["FabricType"][item:getFabricType()].material;
        -- we change this so the number of holes etc impact the yield
        nbrOfCoveredParts = item:getNbrOfCoveredParts() - (item:getHolesNumber() + item:getPatchesNumber());
        --         nbrOfCoveredParts = item:getNbrOfCoveredParts();
        --         character:Say("Parts 1 " .. tostring(nbrOfCoveredParts))
        if nbrOfCoveredParts == 0 then nbrOfCoveredParts = 1 end
        local minMaterial = 2;
        local maxMaterial = nbrOfCoveredParts;
        if nbrOfCoveredParts == 1 then
            minMaterial = 1;
        end

        local nbr = ZombRand(minMaterial, maxMaterial + 1);
        nbr = nbr + (character:getPerkLevel(Perks.Tailoring) / 2);
        if nbr > nbrOfCoveredParts then
            nbr = nbrOfCoveredParts;
        end
        materials[2] = nbr;
        --         character:Say("Parts 2 " .. tostring(nbr))

        maxTime = nbrOfCoveredParts * 20;
    else
        error "Recipe.OnCreate.RipClothing"
    end

    for i = 1, tonumber(materials[2]) do
        local item2;
        local dirty = false;
        if instanceof(item, "Clothing") then
            dirty = (ZombRand(100) <= item:getDirtyness() + item:getBloodlevel());
        end
        if not dirty then
            item2 = instanceItem(materials[1]);
        elseif getScriptManager():FindItem(materials[1] .. "Dirty") then
            item2 = instanceItem(materials[1] .. "Dirty");
        else
            item2 = instanceItem(materials[1])
        end
        character:getInventory():AddItem(item2);
    end

    -- add thread and xp back

    -- add thread sometimes, depending on tailoring level
        local receiveThread = SandboxVars.TearAllClothing.ReceiveThread
    if (ZombRand(9) < character:getPerkLevel(Perks.Tailoring)) then
        local max = 4;
        if nbrOfCoveredParts then
            max = nbrOfCoveredParts;
            if max > 6 then
                max = 6;
            end
        end
        max = ZombRand(4, max);
        local thread = instanceItem("Base.Thread");
        for i = 1, 10 - max do
            thread:Use();
        end
        if receiveThread then
            character:getInventory():AddItem(thread);
        end
    end
    local xpAmount = SandboxVars.TearAllClothing.TailoringXP
    character:getXp():AddXP(Perks.Tailoring, xpAmount);

    if item:hasTag("Buckles") then
        character:getInventory():AddItems("Base.Buckle", 2)
    elseif item:hasTag("Buckle") then
        character:getInventory():AddItem("Base.Buckle")
    end

    if item:hasTag("Wire") and (ZombRand(0, 10) < 5) then
        character:getInventory():AddItems("Base.Wire")
    end
end
