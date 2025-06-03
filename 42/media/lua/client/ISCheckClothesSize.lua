require "TimedActions/ISBaseTimedAction"

ISCheckClothesSize = ISBaseTimedAction:derive("ISCheckClothesSize")

function ISCheckClothesSize:new(character, item, time)
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

function ISCheckClothesSize:start()
    self.item:setJobType(getText("IGUI_JobType_CheckSize"))
    self.item:setJobDelta(0.0)

    self:setActionAnim("Loot")
    self:setAnimVariable("LootPosition", "");
    self:setOverrideHandModels(nil, nil)

    self.sound = self.character:getEmitter():playSound("CheckSize")
end

function ISCheckClothesSize:stop()
    if self.sound and self.character:getEmitter():isPlaying(self.sound) then
        self.character:stopOrTriggerSound(self.sound)
    end

    ISBaseTimedAction.stop(self);
	self.item:setJobDelta(0.0);
end

function ISCheckClothesSize:perform()
    if self.sound and self.character:getEmitter():isPlaying(self.sound) then
        self.character:stopOrTriggerSound(self.sound)
    end

    ISBaseTimedAction.perform(self);
    self.item:setJobDelta(0.0);

    local data = RealisticClothes.getOrCreateModData(self.item)
    local playerSize = RealisticClothes.getPlayerSize(self.character)
    local clothesSize = RealisticClothes.getClothesSizeFromName(data.size)
    local diff = RealisticClothes.getSizeDiff(clothesSize, playerSize)
    local level = self.character:getPerkLevel(Perks.Tailoring)

    local text, gainExp
    if data.reveal or not RealisticClothes.NeedTailoringLevel or level >= RealisticClothes.getRequiredLevelToCheck(self.item) then
        text = RealisticClothes.getTextFromSizeDiff(diff, clothesSize)
        gainExp = not data.reveal
        data.reveal = true

        -- redraw inventory to separate clothes with different sizes
        self.character:getInventory():setDrawDirty(true)
    else
        text = RealisticClothes.getHintFromSizeDiff(diff)
        gainExp = false
        data.hint = true
    end

    self.character:Say(text)
    if gainExp and level < 5 then
        self.character:getXp():AddXP(Perks.Tailoring, (0.5 - level * 0.1) * RealisticClothes.TailoringXpMultiplier)
    end
end

function ISCheckClothesSize:update()
    self.item:setJobDelta(self:getJobDelta())
end

function ISCheckClothesSize:isValid()
    return self.character:getInventory():contains(self.item)
end