---@omw-context menu|player

local ui = require 'openmw.ui'
local util = require 'openmw.util'

local function rgb(red, green, blue) return util.color.rgb(red / 255, green / 255, blue / 255) end

local normal = rgb(34, 175, 251)
local normalHover = rgb(36, 222, 249)

---@type H3UI.ThemeSpec
return {
  name = 'Starwind',
  tokens = {
    color = {
      text = normal,
      textHover = normalHover,
      textPressed = normal,
      active = normal,
      activeHover = normalHover,
      activePressed = normal,
      disabled = rgb(77, 156, 221),
      disabledHover = rgb(74, 190, 223),
      disabledPressed = rgb(77, 156, 221),
      link = rgb(84, 245, 234),
      linkHover = rgb(114, 254, 254),
      linkPressed = rgb(84, 245, 234),
      journalLink = rgb(84, 245, 234),
      journalLinkHover = rgb(114, 254, 254),
      journalLinkPressed = rgb(84, 245, 234),
      journalTopic = rgb(77, 156, 221),
      journalTopicHover = rgb(74, 190, 223),
      journalTopicPressed = rgb(77, 156, 221),
      answer = rgb(96, 112, 202),
      answerHover = rgb(159, 169, 223),
      answerPressed = rgb(223, 226, 244),
      header = rgb(128, 255, 245),
      notify = rgb(128, 255, 245),
      bigText = normal,
      bigTextHover = normalHover,
      bigTextPressed = normal,
      bigLink = rgb(84, 245, 234),
      bigLinkHover = rgb(114, 254, 254),
      bigLinkPressed = rgb(84, 245, 234),
      bigAnswer = rgb(96, 112, 202),
      bigAnswerHover = rgb(159, 169, 223),
      bigAnswerPressed = rgb(223, 226, 244),
      bigHeader = rgb(128, 255, 245),
      bigNotify = rgb(128, 255, 245),
      background = rgb(13, 0, 33),
      focus = rgb(66, 72, 94),
      health = rgb(172, 57, 57),
      magic = rgb(77, 160, 52),
      fatigue = rgb(255, 216, 23),
      misc = rgb(34, 175, 251),
      weaponFill = rgb(182, 72, 31),
      magicFill = rgb(182, 72, 31),
      positive = rgb(128, 255, 245),
      negative = rgb(172, 57, 57),
      count = normal,
      accent = normal,
    },
    textSize = {
      normal = 16,
      header = 18,
    },
    spacing = {
      padding = 2,
    },
    border = {
      normal = 2,
      thick = 4,
    },
    texture = {
      white = ui.texture { path = 'white' },
    },
  },
}
