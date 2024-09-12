local async = require('openmw.async')
local calendar = require('openmw_aux.calendar')
local core = require('openmw.core')
local nearby = require('openmw.nearby')
local types = require('openmw.types')
local ui = require('openmw.ui')
local util = require('openmw.util')

local I = require('openmw.interfaces')
local templates = I.MWUI.templates
local constants = require('scripts.omw.mwui.constants')

local Debug = require('openmw.debug')

local s3lf = require('scripts.s3.lf')

local modInfo = require('scripts.s3.CHIM2090.modInfo')

local SleepManager = require('scripts.s3.CHIM2090.protectedTable')('SettingsGlobal' .. modInfo.name .. 'Sleep')

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

local DateString = '%H:%M, Day %d of %b, %Y BBY'
local RestString = 'Sleeping'
local WaitString = 'You cannot sleep here. You\'ll need to find a bed.'

local didRest = false
local fromBed = false
local fromBedroll = false
local fromOwnedBed = false
local nearbyActorStats = {}
local oldWorldTime = core.getGameTime()
local restOrWait = false
local sleepMultiplier = 1.0
local sleepingOnGround = false

local common = {}

--- Just a simple text box, this is used in multiple places
--- @param text string: The text to display
--- @return ui.TYPE.Text
function common.TextBox(text, useWidget)
  local textBox = {
    type = ui.TYPE.Text,
    props = {
      text = text,
      textColor = constants.normalColor,
      textSize = constants.textHeaderSize,
      textAlignH = ui.ALIGNMENT.Center,
      textAlignV = ui.ALIGNMENT.Center,
      autoSize = false,
    }
  }

  local widget = {
    template = templates.padding,
    content = ui.content{ textBox },
    props = {},
  }

  return useWidget and widget or textBox
end

--- Takes text as input and gives back a laid-out button /w border
--- @param text string: The text to display on the button
--- @return ui.TYPE.Container
function common.createButton(text)
return {
  template = templates.bordersThick,
  -- template = templates.boxTransparentThick,
  content = ui.content {common.TextBox(text, true)},
  props = {},
  events = {},
}
end

--- Generates an image element
--- could be used for testing or actual elements
--- Stretch and grow are set to 1 by default, so fills empty space in a flex
--- @param path string: The path to the image, possibly an item record
--- @param relativeSize util.vector2: The size of the image
--- @param color util.color: The color of the image
common.templateImage = function(color, path, relativeSize)
  local image = {
    type = ui.TYPE.Image,
    external = {
      stretch = 1,
      grow = 1,
    },
    props = {
      relativeSize = relativeSize or util.vector2(1, 1),
      resource = ui.texture { path = path or "white" },
    },
  }
  if color then
    image.props.color = color
  end
  return image
end

local doDrag = false
local lastMousePos = nil
local sleepMenu = nil
function SleepManager.makeSleepMenu()
  if not I.UI.getMode() then
    I.UI.setMode('Dialogue', { windows = {} })
  else
    I.UI.setMode()
  end

  if sleepMenu then
    sleepMenu.layout.props.visible = not sleepMenu.layout.props.visible
    sleepMenu:update()
    return
  end

  local minorSize = util.vector2(1, .125)
  local majorSize = util.vector2(1, .35)

  local dateHeader = common.TextBox(calendar.formatGameTime(DateString))
  dateHeader.props.relativeSize = minorSize
  dateHeader.name = 'dateHeader'

  local sleepInfoString = restOrWait and RestString or WaitString

  local sleepInfoBox = common.TextBox(sleepInfoString)
  sleepInfoBox.props.relativeSize = minorSize
  sleepInfoBox.name = 'sleepInfoBox'

  local totalHoursToHeal = common.TextBox('You will need to sleep for X hours to recover from your wounds.')
  totalHoursToHeal.props.multiline = true
  totalHoursToHeal.props.wordWrap = true
  totalHoursToHeal.props.relativeSize = util.vector2(.75, .2)
  totalHoursToHeal.name = 'totalHoursToHeal'

  local background = common.templateImage(util.color.rgb(0 / 255, 0 / 255, 0 / 255))
  background.props.alpha = .75

  local leftArrow = {
    type = ui.TYPE.Image,
    name = 'decreaseSleepArrow',
    props = {
      resource = ui.texture { path = 'textures/menu_scroll_left.dds' },
      size = util.vector2(32, 32)
    },
  }

  local rightArrow = {
    type = ui.TYPE.Image,
    name = 'increaseSleepArrow',
    props = {
      resource = ui.texture { path = 'textures/menu_scroll_right.dds' },
      size = util.vector2(32, 32)
    },
  }

  local leftArrowContainer = {
    type = ui.TYPE.Flex,
    name = 'decreaseArrowContainer',
    props = {
      autoSize = false,
      relativeSize = util.vector2(0, 1),
      align = ui.ALIGNMENT.Center,
      arrange = ui.ALIGNMENT.End,
    },
    external = { grow = 1, },
    content = ui.content {
      leftArrow,
    },
  }

  local rightArrowContainer = {
    type = ui.TYPE.Flex,
    name = 'increaseArrowContainer',
    props = {
      autoSize = false,
      relativeSize = util.vector2(0, 1),
      align = ui.ALIGNMENT.Center,
      arrange = ui.ALIGNMENT.Start,
    },
    external = { grow = 1, },
    content = ui.content {
      rightArrow,
    },
  }

  local sleepTimeContainer = {
    type = ui.TYPE.Flex,
    props = {
      relativeSize = util.vector2(0.2, 1),
      align = ui.ALIGNMENT.Center,
      arrange = ui.ALIGNMENT.Center,
    },
    content = ui.content {
      {
        type = ui.TYPE.Text,
        name = 'sleepTimeSelection',
        props = {
          text = '24',
          textAlignH = ui.ALIGNMENT.Center,
          textAlignV = ui.ALIGNMENT.Center,
          textColor = constants.normalColor,
          textSize = 48,
        },
      }
    },
  }

  local middleBox = {
    type = ui.TYPE.Flex,
    name = 'timeSelectBody',
    props = {
      arrange = ui.ALIGNMENT.Center,
      horizontal = true,
      autoSize = false,
      relativeSize = majorSize,
    },
    content = ui.content {
      leftArrowContainer,
      sleepTimeContainer,
      rightArrowContainer,
    }
  }

  local cancelButton = {
    template = templates.bordersThick,
    type = ui.TYPE.Text,
    props = {
      relativeSize = util.vector2(0.25, 1),
      textColor = constants.normalColor,
      textSize = constants.textHeaderSize,
      textAlignH = ui.ALIGNMENT.Center,
      textAlignV = ui.ALIGNMENT.Center,
      text = 'Cancel',
      autoSize = false,
    },
  }

  local waitButton = {
    template = templates.bordersThick,
    type = ui.TYPE.Text,
    props = {
      relativeSize = util.vector2(0.25, 1),
      textColor = constants.normalColor,
      textSize = constants.textHeaderSize,
      textAlignH = ui.ALIGNMENT.Center,
      textAlignV = ui.ALIGNMENT.Center,
      text = 'Wait',
      autoSize = false,
    },
  }

  local untilHealedButton = {
    template = templates.bordersThick,
    type = ui.TYPE.Text,
    props = {
      relativeSize = util.vector2(0.25, 1),
      textColor = constants.normalColor,
      textSize = constants.textHeaderSize,
      textAlignH = ui.ALIGNMENT.Center,
      textAlignV = ui.ALIGNMENT.Center,
      text = 'Until Healed',
      autoSize = false,
    },
  }

  local buttonRowContainer = {
    type = ui.TYPE.Flex,
    name = 'selectionButtonRow',
    props = {
      relativeSize = minorSize,
      horizontal = true,
      align = ui.ALIGNMENT.Center,
      arrange = ui.ALIGNMENT.Center,
      autoSize = false,
    },
    external = { grow = 1, stretch = 1 },
    content = ui.content {
      cancelButton,
      { external = { grow = 1, stretch = 1 } },
      untilHealedButton,
      { external = { grow = 1, stretch = 1 } },
      waitButton,
    }
  }

  local widgetBody = {
    type = ui.TYPE.Flex,
    name = 'widgetBody',
    props = {
      arrange = ui.ALIGNMENT.Center,
      relativeSize = util.vector2(1, 1),
      autoSize = false,
    },
    content = ui.content {
      dateHeader,
      { external = { grow = 1 } },
      sleepInfoBox,
      middleBox,
      totalHoursToHeal,
      buttonRowContainer,
    }
  }

  local targetWidgetProps = {
    anchor = util.vector2(.5, .5),
    position = util.vector2(0, 0),
    relativePosition = util.vector2(.5, .5),
    relativeSize = util.vector2(.25, .25),
    visible = true,
  }

  local newMenu = {
    layer = 'Windows',
    type = ui.TYPE.Window,
    name = 'widgetRoot',
    template = I.MWUI.templates.bordersThick,
    events = {
      mousePress = async:callback(function(coord)
          lastMousePos = coord.position
          doDrag = true
      end),
      mouseRelease = async:callback(function() doDrag = false end),
      mouseMove = async:callback(function(coord, layout)
          if not doDrag then return end
          local p = layout.props
          p.position = p.position - (lastMousePos - coord.position)
          sleepMenu:update()
          lastMousePos = coord.position
      end),
    },
    props = targetWidgetProps,
    content = ui.content {
      background,
      widgetBody,
    },
  }

  sleepMenu = ui.create(newMenu)
end
SleepManager.makeSleepMenu()

-- I.UI.registerWindow('WaitDialog', SleepManager.makeSleepMenu, SleepManager.makeSleepMenu)

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

    -- if sleepingOnGround and self.NoSleepOnGround then
      -- I.UI.setMode()
      -- return
    -- end

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
  },
  eventHandlers = {
    s3Chim_objectActivated = SleepManager.receivedActivation,
    UiModeChanged = SleepManager.handleUiMode,
  },
  engineHandlers = {
    onUpdate = SleepManager.onUpdate,
  },
}
