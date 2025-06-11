require "TimedActions/ISBaseTimedAction"

ISReconditionShoesUsingSpare = ISBaseTimedAction:derive("ISReconditionShoesUsingSpare")

function ISReconditionShoesUsingSpare:new(character, item, spareItem, scissors)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.item = item
    o.spareItem = spareItem
    o.scissors = scissors

    o.stopOnWalk = false
    o.stopOnRun = true
    o.maxTime = character:isTimedActionInstant() and 1 or 50
    return o
end

function ISReconditionShoesUsingSpare:start()
    self.item:setJobType(getText("IGUI_JobType_ReconditionShoes"))
    self.item:setJobDelta(0.0)
end

function ISReconditionShoesUsingSpare:stop()
    ISBaseTimedAction.stop(self);
    self.item:setJobDelta(0.0);
end

function ISReconditionShoesUsingSpare:perform()
    ISBaseTimedAction.perform(self);
    self.item:setJobDelta(0.0);

    local successChance = RealisticShoes.getSuccessChanceForRecondition(self.item, self.character)
    if ZombRandFloat(0, 1) < successChance then
        local potentialRepair = RealisticShoes.getPotentialRepairForRecondition(self.item, self.character)
        local conditionGain = math.ceil(potentialRepair * (self.item:getConditionMax() - self.item:getCondition()))

        self.item:setCondition(self.item:getCondition() + conditionGain)
        self.item:setHaveBeenRepaird(self.item:getHaveBeenRepaired() + 1)

        self.character:getInventory():Remove(self.spareItem)
    else
        if ZombRandFloat(0, 1) < RealisticShoes.ChanceToDegradeOnFailure then
            self.item:setCondition(self.item:getCondition() - 1)
        end
    end
end

function ISReconditionShoesUsingSpare:update()
    self.item:setJobDelta(self:getJobDelta())
end

function ISReconditionShoesUsingSpare:isValid()
    local inv = self.character:getInventory()

    return inv:contains(self.item) and inv:contains(self.spareItem) and inv:contains(self.scissors)
end