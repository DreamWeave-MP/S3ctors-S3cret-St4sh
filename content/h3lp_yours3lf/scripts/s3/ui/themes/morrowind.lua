---@omw-context menu|player

local textRules = require 'scripts.s3.ui.themes.textRules'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local function rgb(red, green, blue) return util.color.rgb(red / 255, green / 255, blue / 255) end

---@type H3UI.ThemeSpec
return {
  name = 'Morrowind',
  tokens = {
    color = {
      text = rgb(202, 165, 96),
      textHover = rgb(223, 201, 159),
      textPressed = rgb(243, 237, 221),
      active = rgb(96, 112, 202),
      activeHover = rgb(159, 169, 223),
      activePressed = rgb(223, 226, 244),
      disabled = rgb(179, 168, 135),
      disabledHover = rgb(223, 201, 159),
      disabledPressed = rgb(243, 237, 221),
      link = rgb(112, 126, 207),
      linkHover = rgb(143, 155, 218),
      linkPressed = rgb(175, 184, 228),
      journalLink = rgb(37, 49, 112),
      journalLinkHover = rgb(58, 77, 175),
      journalLinkPressed = rgb(112, 126, 207),
      journalTopic = rgb(0, 0, 0),
      journalTopicHover = rgb(58, 77, 175),
      journalTopicPressed = rgb(112, 126, 207),
      answer = rgb(150, 50, 30),
      answerHover = rgb(223, 201, 159),
      answerPressed = rgb(243, 237, 221),
      header = rgb(223, 201, 159),
      notify = rgb(223, 201, 159),
      bigText = rgb(202, 165, 96),
      bigTextHover = rgb(223, 201, 159),
      bigTextPressed = rgb(243, 237, 221),
      bigLink = rgb(112, 126, 207),
      bigLinkHover = rgb(143, 155, 218),
      bigLinkPressed = rgb(175, 184, 228),
      bigAnswer = rgb(150, 50, 30),
      bigAnswerHover = rgb(223, 201, 159),
      bigAnswerPressed = rgb(243, 237, 22),
      bigHeader = rgb(223, 201, 159),
      bigNotify = rgb(223, 201, 159),
      background = rgb(0, 0, 0),
      focus = rgb(80, 80, 80),
      health = rgb(200, 60, 30),
      magic = rgb(53, 69, 159),
      fatigue = rgb(0, 150, 60),
      misc = rgb(0, 205, 205),
      weaponFill = rgb(200, 60, 30),
      magicFill = rgb(200, 60, 30),
      positive = rgb(223, 201, 159),
      negative = rgb(200, 60, 30),
      count = rgb(223, 201, 159),
      accent = rgb(223, 201, 159),
    },
    textSize = {
      normal = 16,
      header = 18,
    },
    transparency = {
      menu = 0.84,
    },
    spacing = {
      xs = 2,
      sm = 4,
      md = 2,
      lg = 4,
      xl = 6,
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
  rules = textRules(),
}
