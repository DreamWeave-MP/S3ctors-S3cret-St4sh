local core = require('openmw.core')
local nearby = require('openmw.nearby')
local self = require('openmw.self')
local time = require('openmw_aux.time')
local types = require('openmw.types')
local ui = require('openmw.ui')
local util = require('openmw.util')

local I = require('openmw.interfaces')

local ASSASSIN_ID_PREFIX = 'affass_'
-- Minutes
local ASSASSIN_SPAWN_DELAY = 60
local ASSASSIN_INTERACT_DIST = 96

local Quests = self.type.quests(self)
local fargothQuest = Quests['af_fargothsayshello']
local fargSpawnCoroutine
local fargCatchCoroutine
local fargothStopFn
local fargCaught = false
local fargSelected = false

local function huntedByFargoth()
  return fargothQuest.stage >= 90 and fargothQuest.stage < 100
end

local debug = false
local function doLog(...)
  if not debug then return end
  print("[ AFFASSASSINS ]: ", ...)
end

local function colorFromGMST(gmst)
  local colorString = core.getGMST(gmst)
  local numberTable = {}
  for numberString in colorString:gmatch("([^,]+)") do
    if #numberTable == 3 then break end
    local number = tonumber(numberString:match("^%s*(.-)%s*$"))
    if number then
      table.insert(numberTable, number / 255)
    end
  end

  if #numberTable < 3 then error('Invalid color GMST name: ' .. gmst) end

  return util.color.rgb(table.unpack(numberTable))
end

local function fargothSpawnIter(selected)
  local i = 1
  while i <= #nearby.actors do

    if fargothQuest.stage >= 100 or selected then break end

    local actor = nearby.actors[i]
    actor:sendEvent('S3_AffAss_FargothMinionSpawn', self.object)
    doLog("Sending", actor.recordId, "Fargoth minion clone event")
    i = i + 1
    coroutine.yield()
  end
  coroutine.yield()
end

local function fargothCaughtIter(caught)
  local i = 1
  while i <= #nearby.actors do
    local actor = nearby.actors[i]

    if fargothQuest.stage >= 100 or caught then break end

    if not fargCaught
      and huntedByFargoth()
      and not types.Player.objectIsInstance(actor)
      and string.find(actor.recordId, ASSASSIN_ID_PREFIX) then

      local distance = (self.position - actor.position):length()

      if distance < ASSASSIN_INTERACT_DIST then
        self:sendEvent('S3_AffAss_CaughtMenu')
        actor:sendEvent('StartAIPackage', { type='Combat', target= self.object })
        fargCaught = true
      end

    end

    i = i + 1
    coroutine.yield()
  end
  coroutine.yield()
end

local function findPotentialFargoth()
  fargCaught = false
  fargSelected = false

  if fargothQuest.stage < 90 then
    doLog("AFFargoth not progressed enough for assassin spawns")
    return
  elseif fargothQuest.stage >= 100 then
    fargothStopFn()
    fargothStopFn = nil
    return
  end

  if fargSpawnCoroutine and coroutine.status(fargSpawnCoroutine) ~= 'dead' then return end

  fargSpawnCoroutine = coroutine.create(fargothSpawnIter)
end

fargothStopFn = time.runRepeatedly(findPotentialFargoth, ASSASSIN_SPAWN_DELAY * time.minute, { type = time.GameTime })

local caughtMenu
return {
  engineHandlers = {
    onUpdate = function()
      -- Resume coroutine for determining fargoth spawn candidates
      if not fargSelected and fargSpawnCoroutine and coroutine.status(fargSpawnCoroutine) ~= 'dead' then
        coroutine.resume(fargSpawnCoroutine, fargSelected)
      end

      -- If the catcher isn't initialized, start it here
      if not fargCatchCoroutine or coroutine.status(fargCatchCoroutine) == 'dead' then
        fargCatchCoroutine = coroutine.create(fargothCaughtIter)
      -- Otherwise resume the catcher coroutine
      elseif not fargCaught and fargCatchCoroutine and coroutine.status(fargCatchCoroutine) ~= 'dead' then
        coroutine.resume(fargCatchCoroutine)
      end
    end,
    onKeyPress = function()
      if not caughtMenu then return end
      caughtMenu:destroy()
      caughtMenu = nil
      core.sendGlobalEvent('Unpause')
    end,
  },
  eventHandlers = {
    S3_AffAss_FargothSelected = function(selectedActor)
      fargSelected = true
      doLog(selectedActor.recordId, " was selected as a fargoth minion")
      fargSpawnCoroutine = nil
    end,
    S3_AffAss_CaughtMenu = function()
      if caughtMenu then doLog('caught menu already opened!') return end

      core.sendGlobalEvent('Pause')

      caughtMenu = ui.create {
      template = I.MWUI.templates.boxTransparentThick,
      layer = 'HUD',
      props = {
        relativePosition = util.vector2(.5, .5),
        anchor = util.vector2(.5, .5),
        relativeSize = util.vector2(.5, .5)
      },
      content = ui.content {
        {
          type = ui.TYPE.Text,
          props = {
            relativePosition = util.vector2(.25, .5),
            text = 'FARGOTH SAYS HELLO.\nPRESS ANY KEY TO DIE.',
            textColor = colorFromGMST('fontcolor_color_header'),
            relativeSize = util.vector2(1, 1),
            multiline = true,
            textShadow = true,
            textShadowColor = colorFromGMST('fontcolor_color_normal_pressed'),
            textSize = 64,
          },
        },
      }
    }

    end,
  },
}
