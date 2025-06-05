require "TimedActions/ISBaseTimedAction"

ISCheckShoesSize = ISBaseTimedAction:derive("ISCheckShoesSize")

function ISCheckShoesSize:new(character, item, time)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.item = item

    o.stopOnWalk = false
    o.stopOnRun = true
    o.maxTime = character:isTimedActionInstant() and 1 or time
    return o
end

function ISCheckShoesSize:start()
    self.item:setJobType(getText("IGUI_JobType_CheckShoesSize"))
    self.item:setJobDelta(0.0)

    self:setActionAnim("Loot")
    self:setAnimVariable("LootPosition", "Low")
    self:setOverrideHandModels(nil, nil)
end

function ISCheckShoesSize:stop()
    ISBaseTimedAction.stop(self);
	self.item:setJobDelta(0.0);
end

function ISCheckShoesSize:perform()
    ISBaseTimedAction.perform(self);
    self.item:setJobDelta(0.0);

    local data = RealisticShoes.getOrCreateModData(self.item)
    local shoesSize = data.size
    local playerSize = RealisticShoes.getPlayerSize(self.character)
    local diff = shoesSize - playerSize

    if not data.reveal then
        data.reveal = true
        self.character:getXp():AddXP(Perks.Tailoring, 0.25)
    end

    self.character:Say(RealisticShoes.getDiffText(diff, shoesSize))
end

function ISCheckShoesSize:update()
    self.item:setJobDelta(self:getJobDelta())
end

function ISCheckShoesSize:isValid()
    return self.character:getInventory():contains(self.item)
end