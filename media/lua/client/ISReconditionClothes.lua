require "TimedActions/ISBaseTimedAction"

ISReconditionClothes = ISBaseTimedAction:derive("ISReconditionClothes")

function ISReconditionClothes:new(character, item, needle, threads, strips, threadUses)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.item = item
    o.needle = needle
    o.threads = threads
    o.strips = strips
    o.threadUses = threadUses

    o.stopOnWalk = false
    o.stopOnRun = true
    o.maxTime = RealisticClothes.getReconditionDuration(item)
    return o
end

function ISReconditionClothes:start()
    self.item:setJobType(getText("IGUI_JobType_Recondition"))
    self.item:setJobDelta(0.0)
end

function ISReconditionClothes:stop()
    ISBaseTimedAction.stop(self);
    self.item:setJobDelta(0.0);
end

function ISReconditionClothes:perform()
    ISBaseTimedAction.perform(self);
    self.item:setJobDelta(0.0);

    local threadUses = self.threadUses
    local stripUses = #self.strips

    local successChance = RealisticClothes.getSuccessChanceForRecondition(self.item, self.character)
    if ZombRandFloat(0, 1) < successChance then
        local potentialRepair = RealisticClothes.getPotentialRepairForRecondition(self.item, self.character)
        local conditionGain = math.ceil(potentialRepair * (self.item:getConditionMax() - self.item:getCondition()))
        local repairedTimes = self.item:getHaveBeenRepaired() - 1
        self.character:getXp():AddXP(Perks.Tailoring, RealisticClothes.getTailoringXpForRecondition(self.item, true))
        self.character:getXp():AddXP(Perks.Maintenance, conditionGain * 0.5 / (repairedTimes < 10 and (repairedTimes + 1) or 0))

        self.item:setCondition(self.item:getCondition() + conditionGain)
        self.item:setHaveBeenRepaired(self.item:getHaveBeenRepaired() + 1)
    else
        if ZombRandFloat(0, 1) < RealisticClothes.ChanceToDegradeOnFailure then
            self.item:setCondition(self.item:getCondition() - 1)
        end
        
        self.character:getEmitter():playSound("ResizeFailed")
        self.character:getXp():AddXP(Perks.Tailoring, RealisticClothes.getTailoringXpForRecondition(self.item, false))

        threadUses = math.ceil(threadUses / 2)
        stripUses = math.ceil(stripUses / 2)
    end

    for _, thread in ipairs(self.threads) do
        while threadUses > 0 and thread:getRemainingUses() > 0 do
            thread:Use()
            threadUses = threadUses - 1
        end
    end
    for _, strip in ipairs(self.strips) do
        if stripUses > 0 then
            self.character:getInventory():Remove(strip)
            stripUses = stripUses - 1
        end
    end
end

function ISReconditionClothes:update()
    self.item:setJobDelta(self:getJobDelta())
end

function ISReconditionClothes:isValid()
    local inv = self.character:getInventory()

    for _, thread in ipairs(self.threads) do
        if not inv:contains(thread) then return false end
    end

    for _, strip in ipairs(self.strips) do
        if not inv:contains(strip) then return false end
    end

    return inv:contains(self.item) and inv:contains(self.needle)
end