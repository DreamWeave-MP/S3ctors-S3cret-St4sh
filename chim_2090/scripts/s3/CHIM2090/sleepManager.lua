-- local async = require('openmw.async')
local core = require('openmw.core')
local nearby = require('openmw.nearby')
local types = require('openmw.types')
local ui = require('openmw.ui')

local I = require('openmw.interfaces')

local Debug = require('openmw.debug')

local s3lf = require('scripts.s3.lf')

local modInfo = require('scripts.s3.CHIM2090.modInfo')

local SleepManager = require('scripts.s3.CHIM2090.protectedTable')('SettingsGlobal' .. modInfo.name .. 'Sleep')
local RestMenu = require('scripts.s3.CHIM2090.ui.restMenu')

function SleepManager.test()
  Debug.reloadLua()
end

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

local didRest = false
local fromBed = false
local fromBedroll = false
local fromOwnedBed = false
local nearbyActorStats = {}
local oldWorldTime = core.getGameTime()
local restOrWait = false
local sleepMultiplier = 1.0
local sleepingOnGround = false

local sleepMenu = ui.create(RestMenu)

function SleepManager.makeSleepMenu(state)
  assert(state ~= nil
         , modInfo.logPrefix .. 'Must provide a state when calling toggle sleep menu!')

  local sleepProps = sleepMenu.layout.props
  if state == sleepProps.visible then return end

  sleepProps.visible = not sleepProps.visible

  if not state then
    sleepMenu:update()
    I.UI.setMode()
  end
end

I.UI.setPauseOnMode('Rest', false)
I.UI.registerWindow('WaitDialog', function() SleepManager.makeSleepMenu(true) end
                    , function() SleepManager.makeSleepMenu(false) end)

function SleepManager.getSleepMenu()
  return sleepMenu
end

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

    if sleepingOnGround and SleepManager.NoSleepOnGround then
      I.UI.setMode()
      return
    end

    if sleepingOnGround then
      sleepMultiplier = SleepManager.GroundSleepMult
    elseif fromBedroll then
      sleepMultiplier = SleepManager.BedrollSleepMult
    elseif fromBed then
      sleepMultiplier = SleepManager.BedSleepMult
    elseif fromOwnedBed then
      sleepMultiplier = SleepManager.OwnedSleepMult
    end

    local isOutside = s3lf.cell.isExterior or s3lf.cell:hasTag('QuasiExterior')

    if isOutside and not fromBedroll then
      if restOrWait then
        sleepMultiplier = sleepMultiplier * SleepManager.OutdoorSleepMult
      else
        sleepMultiplier = sleepMultiplier * SleepManager.OutdoorWaitMult
      end
    elseif not isOutside and not restOrWait then
      sleepMultiplier = sleepMultiplier * SleepManager.IndoorWaitMult
    end

    if SleepManager.PillowEnable and SleepManager.playerHasPillow() then
      sleepMultiplier = sleepMultiplier + SleepManager.PillowMult
    end

    RestMenu.updateSleepInfo {
      fromBedroll = fromBedroll
      , fromOwnedBed = fromOwnedBed
      , isOutside = isOutside
      , multiplier = sleepMultiplier
      , sleeping = restOrWait
      , sleepingOnGround = sleepingOnGround
    }

    RestMenu.updateHoursToHeal {
      needsToHeal = s3lf.health.current < s3lf.health.base,
      sleepMultiplier = sleepMultiplier,
      restOrWait = restOrWait,
    }

    sleepMenu:update()

    SleepManager.debugLog('rest menu opened, restOrWait:', tostring(restOrWait)
                            , 'fromBed:', tostring(fromBed)
                            , 'fromOwnedBed:', tostring(fromOwnedBed)
                            , 'fromBedroll:', tostring(fromBedroll)
                            , 'sleepingOnGround:', tostring(sleepingOnGround)
                            , 'sleepMultiplier:', sleepMultiplier)
    SleepManager.getLocalActorHealthTable()
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

  if didRest then
    if currentWorldTime - oldWorldTime > 3600 then
      local sleptHours = math.floor((currentWorldTime - oldWorldTime) / 3600)
      for _, actor in pairs(nearby.actors) do
        if actor.id ~= s3lf.id then
          actor:sendEvent('s3ChimDynamic_SleepActor', { time = sleptHours,
                                                        restOrWait = restOrWait,
                                                        oldHealth = nearbyActorStats[actor.id]})
        else
          actor:sendEvent('s3ChimDynamic_SleepPlayer', { time = sleptHours,
                                                         restOrWait = restOrWait,
                                                         oldHealth = nearbyActorStats[actor.id],
                                                         sleepMultiplier = sleepMultiplier })
        end
      end
    end
    didRest = false
  end

  oldWorldTime = core.getGameTime()
end

function SleepManager.getLocalActorHealthTable()
  nearbyActorStats = {}
  for _, actor in pairs(nearby.actors) do
    nearbyActorStats[actor.id] = s3lf.From(actor).health.current
    SleepManager.debugLog('Added actor', actor.id, 'to nearbyActorStats')
  end
end

function SleepManager.onUpdate(_dt)
  SleepManager.handleSleepFrame()
end

return {
  interfaceName = 's3ChimSleep',
  interface = {
    version = modInfo.version,
    Manager = SleepManager,
    Menu = sleepMenu,
  },
  eventHandlers = {
    s3Chim_objectActivated = SleepManager.receivedActivation,
    UiModeChanged = SleepManager.handleUiMode,
  },
  engineHandlers = {
    onUpdate = SleepManager.onUpdate,
  },
}
