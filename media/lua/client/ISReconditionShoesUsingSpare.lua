require "TimedActions/ISBaseTimedAction"

ISReconditionShoesUsingSpare = ISBaseTimedAction:derive("ISReconditionShoesUsingSpare")

function ISReconditionShoesUsingSpare:new(character, item, scissors, spareItem , materials)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.item = item
    o.scissors = scissors
    o.spareItem = spareItem
    o.materials = materials

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

    local materialUses = #self.materials
    local successChance = RealisticShoes.getSuccessChanceUsingSpare(self.item, self.character, self.spareItem)
    if ZombRandFloat(0, 1) < successChance then
        local potentialRepair = RealisticShoes.getPotentialRepairUsingSpare(self.item, self.character, self.spareItem)
        local conditionGain = math.ceil(potentialRepair * (self.item:getConditionMax() - self.item:getCondition()))
        local repairedTimes = RealisticShoes.getRepairedTimes(self.item)
        self.character:getXp():AddXP(Perks.Tailoring, 0.25 * 2 ^ (3 - repairedTimes))
        self.character:getXp():AddXP(Perks.Maintenance, conditionGain * 0.2 / (repairedTimes < 10 and (repairedTimes + 1) or 0))

        self.item:setCondition(self.item:getCondition() + conditionGain)
        self.item:setHaveBeenRepaird(self.item:getHaveBeenRepaired() + 1)

        self.character:getInventory():Remove(self.spareItem)
    else
        if ZombRandFloat(0, 1) < RealisticShoes.ChanceToDegradeOnFailure then
            self.item:setCondition(self.item:getCondition() - 1)
        end

        self.character:getEmitter():playSound("ReconditionShoesFailed")
        self.character:getXp():AddXP(Perks.Tailoring, 0.25 * math.max(0, 10 - repairedTimes) / 10)

        materialUses = math.ceil(materialUses / 2)
        while true do
            if ZombRand(2) == 0 then
                local condLoss = ZombRand(math.ceil(self.spareItem:getConditionMax() * 0.2)) + 1
                if self.spareItem:getCondition() > condLoss then
                    self.spareItem:setCondition(self.spareItem:getCondition() - condLoss)
                else
                    self.character:getInventory():Remove(self.spareItem)
                    break
                end
            else
                break
            end
        end
    end

    for _, material in ipairs(self.materials) do
        if materialUses > 0 then
            self.character:getInventory():Remove(material)
            materialUses = materialUses - 1
        end
    end
end

function ISReconditionShoesUsingSpare:update()
    self.item:setJobDelta(self:getJobDelta())
end

function ISReconditionShoesUsingSpare:isValid()
    local inv = self.character:getInventory()

    for _, material in ipairs(self.materials) do
        if not inv:contains(material) then return false end
    end

    return inv:contains(self.item) and inv:contains(self.spareItem) and inv:contains(self.scissors)
end