require "TimedActions/ISBaseTimedAction"

ISReconditionShoes = ISBaseTimedAction:derive("ISReconditionShoes")

function ISReconditionShoes:new(character, item, needle, brush)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.item = item
    o.needle = needle
    o.brush = brush

    o.stopOnWalk = false
    o.stopOnRun = true
    o.maxTime = character:isTimedActionInstant() and 1 or 50
    return o
end