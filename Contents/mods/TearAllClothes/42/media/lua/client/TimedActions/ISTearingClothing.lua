require "TimedActions/ISBaseTimedAction"

ISTearingClothing = ISBaseTimedAction:derive("ISRipingClothes")

function ISTearingClothing:isValid()
    if isClient() and self.started then return true end
    if isClient() and self.item then
        return self.character:getInventory():containsID(self.item:getID())
    else
        return self.character:getInventory():contains(self.item)
    end
end

function ISTearingClothing:waitToStart()
    return false
end

function ISTearingClothing:update()
    self.item:setJobDelta(self:getJobDelta())

    if not self.sound and self:getJobDelta() > 0.7 and self.item then
        self.sound = self.character:playSound("ClothesRipping")
    end
    self.character:setMetabolicTarget(Metabolics.HeavyDomestic)
end

function ISTearingClothing:start()
    self.item:setJobDelta(0.0)
    self:setActionAnim("RipSheets")
    self.sound = self.character:getEmitter():playSound("ClothesRipping")
    self:setOverrideHandModels(nil, nil)
    if isClient() and self.item then
        self.item = self.character:getInventory():getItemById(self.item:getID())
    end
end

function ISTearingClothing:stop()
    self.item:setJobDelta(0.0)
    if self.sound and self.character:getEmitter():isPlaying(self.sound) then
        self.character:getEmitter():stopSound(self.sound)
    end
end

function ISTearingClothing:stopSound()
    if self.sound and self.character:getEmitter():isPlaying(self.sound) then
        self.character:stopOrTriggerSound(self.sound)
    end
end

function ISTearingClothing:perform()
    self:stopSound()

    local character = self.character
    local item = self.item
    item:setJobDelta(0.0)

    local materials = nil
    local nbrOfCoveredParts = nil
    if ClothingRecipesDefinitions[item:getType()] then
        local recipe = ClothingRecipesDefinitions[item:getType()]
        materials = luautils.split(recipe.materials, ":");
    elseif ClothingRecipesDefinitions["FabricType"][item:getFabricType()] then
        materials = {};
        materials[1] = ClothingRecipesDefinitions["FabricType"][item:getFabricType()].material;
        -- we change this so the number of holes etc impact the yield
        nbrOfCoveredParts = item:getNbrOfCoveredParts() - (item:getHolesNumber() + item:getPatchesNumber());
        if nbrOfCoveredParts == 0 then nbrOfCoveredParts = 1 end
        local minMaterial = 2;
        local maxMaterial = nbrOfCoveredParts;
        if nbrOfCoveredParts == 1 then
            minMaterial = 1;
        end

        local nbr = ZombRand(minMaterial, maxMaterial + 1);
        nbr = nbr + (character:getPerkLevel(Perks.Tailoring) / 2);
        if nbr > nbrOfCoveredParts then nbr = nbrOfCoveredParts end
        materials[2] = nbr;

        self.maxTime = nbrOfCoveredParts * 20;
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
    if (ZombRand(7) < character:getPerkLevel(Perks.Tailoring)) and receiveThread then
        local max = 4;
        if nbrOfCoveredParts then
            max = nbrOfCoveredParts;
            if max > 6 then
                max = 6;
            end
        end
        max = ZombRand(2, max);
        local thread = instanceItem("Base.Thread");
        for i = 1, 10 - max do
            thread:Use();
        end
        character:getInventory():AddItem(thread);
    end
    local xpAmount = SandboxVars.TearAllClothing.TailoringXP
    character:getXp():AddXP(Perks.Tailoring, xpAmount);

    if item:hasTag("Buckles") then
        character:getInventory():AddItems("Base.Buckle", 2)
    elseif item:hasTag("Buckle") then
        character:getInventory():AddItem("Base.Buckle")
    end

    if item:hasTag("Wire") then
        character:getInventory():AddItems("Base.Wire", 2)
    end

    self.character:getInventory():Remove(self.item)
    ISBaseTimedAction.perform(self)
end

function ISTearingClothing:new(character, item)
    local o = ISBaseTimedAction.new(self, character)
    o.stopOnWalk = true
    o.stopOnRun = true
    o.maxTime = 100
    o.item = item
    -- o.transactionId = 0

    if character:isTimedActionInstant() then
        o.maxTime = -1
    end
    if isClient() then
        o.maxTime = -1
    end
    return o
end
