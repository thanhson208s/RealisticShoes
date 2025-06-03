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
    o.maxTime = time
    return o
end

function ISCheckShoesSize:start()
end

function ISCheckShoesSize:stop()
end

function ISCheckShoesSize:perform()
end

function ISCheckShoesSize:update()
    self.item:setJobDelta(self:getJobDelta())
end

function ISCheckShoesSize:isValid()
    return self.character:getInventory():contains(self.item)
end