local core = require('openmw.core')
local nearby = require('openmw.nearby')
local types = require('openmw.types')
local I = require('openmw.interfaces')

local s3lf = require('scripts.s3.lf')

local modInfo = require('scripts.s3.CHIM2090.modInfo')

local SleepManager = require('scripts.s3.CHIM2090.protectedTable')('SettingsGlobal' .. modInfo.name .. 'Sleep')

I.Settings.registerPage {
  key = modInfo.name,
  l10n = modInfo.l10nName,
  name = "CHIM 2090",
  description = "Manages actor fatigue, carry weight, hit chance, and strength in combat."
}

print(string.format("%s loaded version %s. Thank you for playing %s! <3",
                    modInfo.logPrefix,
                    modInfo.version,
                    modInfo.name))

local currentCell = nil
local didRest = false
local fromBed = false
local fromBedroll = false
local fromOwnedBed = false
local nearbyActorStats = {}
local oldWorldTime = core.getGameTime()
local restOrWait = false
local sleepMultiplier = 1.0
local sleepingOnGround = false

function SleepManager.playerHasPillow()
  local misc = s3lf.inventory():getAll(types.Miscellaneous)
  for _, item in pairs(misc) do
    if string.find(item.recordId, 'pillow') ~= nil then
      return true
    end
  end
  return false
end

function SleepManager.receivedActivation(data)
  if I.UI.getMode() == 'Rest' then
    fromBed = true
    fromOwnedBed = data.owner == s3lf.recordId
    fromBedroll = string.find(data.origin, 'bedroll') ~= nil
  end
end

function SleepManager.handleUiMode(data)
  if data.newMode == 'Rest' then
    sleepMultiplier = 1.0
    restOrWait = fromBed or not s3lf.cell:hasTag('NoSleep')

    sleepingOnGround = restOrWait and not fromBed

    if sleepingOnGround then
      sleepMultiplier = SleepManager.GroundSleepMult
    elseif fromBedroll then
      sleepMultiplier = SleepManager.BedrollSleepMult
    elseif fromBed then
      sleepMultiplier = SleepManager.BedSleepMult
    elseif fromOwnedBed then
      sleepMultiplier = SleepManager.OwnedSleepMult
    end

    if s3lf.cell.isExterior or s3lf.cell:hasTag('QuasiExterior') then
      if restOrWait and fromBed then
        sleepMultiplier = sleepMultiplier * SleepManager.OutdoorSleepMult
      else
        sleepMultiplier = sleepMultiplier * SleepManager.OutdoorWaitMult
      end
    elseif not restOrWait then
      sleepMultiplier = sleepMultiplier * SleepManager.IndoorWaitMult
    end

    if SleepManager.PillowEnable and SleepManager.playerHasPillow() then
      sleepMultiplier = sleepMultiplier + SleepManager.PillowMult
    end

    SleepManager.debugLog('rest menu opened, restOrWait:', tostring(restOrWait)
                            , 'fromBed:', tostring(fromBed)
                            , 'fromOwnedBed:', tostring(fromOwnedBed)
                            , 'fromBedroll:', tostring(fromBedroll)
                            , 'sleepingOnGround:', tostring(sleepingOnGround)
                            , 'sleepMultiplier:', sleepMultiplier)
  elseif data.oldMode == 'Rest' then
    fromOwnedBed = false
    fromBed = false
    fromBedroll = false
    didRest = true
  elseif data.newMode ~= 'Rest' then
    didRest = false
  end
end

function SleepManager.handleSleepFrame()
  if core.isWorldPaused() then return end
  local currentWorldTime = core.getGameTime()

  if currentWorldTime - oldWorldTime > 3600 then
    if didRest then
      local sleptHours = math.floor((currentWorldTime - oldWorldTime) / 3600)
      for _, actor in pairs(nearby.actors) do
        if actor.id ~= s3lf.id then
          actor:sendEvent('s3ChimFatigue_SleepActor', { time = sleptHours,
                                                        actorStats = nearbyActorStats[actor.id]})
        else
          actor:sendEvent('s3ChimFatigue_SleepPlayer', { time = sleptHours,
                                                         actorStats = nearbyActorStats[actor.id],
                                                         sleepMultiplier = sleepMultiplier })
        end
      end
    end
    currentCell = nil
    didRest = false
  end

  oldWorldTime = core.getGameTime()
end

function SleepManager.handleCellChanged()
  if currentCell ~= s3lf.cell then
    nearbyActorStats = {}
    for _, actor in pairs(nearby.actors) do
      local s3lfActor = s3lf.From(actor)
      nearbyActorStats[actor.id] = {
        health = s3lfActor.health.current,
        magicka = s3lfActor.magicka.current,
      }
      SleepManager.debugLog('Added actor', actor.id, 'to nearbyActorStats')
    end
    currentCell = s3lf.cell
  end
end

function SleepManager.onUpdate(_dt)
  SleepManager.handleCellChanged()
  SleepManager.handleSleepFrame()
end

return {
  interfaceName = 's3ChimSleep',
  interface = {
    version = modInfo.version,
    Manager = SleepManager,
  },
  eventHandlers = {
    s3Chim_objectActivated = SleepManager.receivedActivation,
    UiModeChanged = SleepManager.handleUiMode,
  },
  engineHandlers = {
    onUpdate = SleepManager.onUpdate,
  },
}
