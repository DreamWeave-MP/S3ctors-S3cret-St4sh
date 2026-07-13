---@omw-context player

local ui = require 'openmw.ui'

---@enum DisplayTier
local DisplayTier = {
  Small = 'small',
  Standard = 'standard',
  High = 'high',
  Ultra = 'ultra',
}

---@param y integer
---@return DisplayTier
local function fromHeight(y)
  if y <= 720 then
    return DisplayTier.Small
  elseif y <= 1080 then
    return DisplayTier.Standard
  elseif y <= 2160 then
    return DisplayTier.High
  else
    return DisplayTier.Ultra
  end
end

local currentTier = fromHeight(ui.screenSize().y)

---@return DisplayTier
local function getTier() return currentTier end

---@param y integer
local function refreshDisplayTier(y) currentTier = fromHeight(y) end

return {
  DisplayTier = DisplayTier,
  getTier = getTier,
  refreshDisplayTier = refreshDisplayTier,
}
