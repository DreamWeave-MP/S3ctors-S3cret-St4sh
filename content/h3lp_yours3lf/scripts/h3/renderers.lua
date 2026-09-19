---@omw-context menu
---@module 'scripts.h3.renderers'

local I = require 'openmw.interfaces'
local async = require 'openmw.async'
local core = require 'openmw.core'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

require 'scripts.h3.ui'
local appearance = require 'scripts.h3.ui.appearance'
local selector = require 'scripts.h3.components.selector'

local StrFormat, TableInsert, TableRemove, Type = string.format, table.insert, table.remove, type

local ColorRGB, L10nFactory, RegisterRenderer, ScreenSize, Templates, UiAlignment, UiContent, UiCreate, UiTexture, UiType, UtilClamp, UtilVector2 =
  util.color.rgb,
  core.l10n,
  I.Settings.registerRenderer,
  ui.screenSize,
  I.MWUI.templates,
  ui.ALIGNMENT,
  ui.content,
  ui.create,
  ui.texture,
  ui.TYPE,
  util.clamp,
  util.vector2

local MarkTexture, WhiteTexture =
  UiTexture { path = 'textures/menu_map_smark.dds' }, UiTexture { path = 'white' }

local ScreenPositionLayer = 'Modal'

local Center = UtilVector2(0.5, 0.5)

local L10n = L10nFactory 'H3'

---@type H3UI.ScreenPositionPopup?
local screenPositionPopup
local screenPositionGeneration = 0

---@param value? openmw.util.Vector2
---@return openmw.util.Vector2
local function normalizedScreenPosition(value)
  if not value then return Center end
  return UtilVector2(UtilClamp(value.x, 0, 1), UtilClamp(value.y, 0, 1))
end

---@param a? openmw.util.Vector2
---@param b? openmw.util.Vector2
---@return boolean?
local function sameScreenPosition(a, b) return a and b and a.x == b.x and a.y == b.y end

---@return nil
local function destroyScreenPositionPopup()
  local popup = screenPositionPopup

  if not popup then return end

  popup.alive = false
  screenPositionPopup = nil

  if popup.element and popup.element.layout then popup.element:destroy() end
end

---@param popup? H3UI.ScreenPositionPopup
---@param generation integer
---@return openmw.ui.Layout|false|nil
local function isScreenPositionPopupAlive(popup, generation)
  return popup
    and popup.alive
    and screenPositionPopup == popup
    and popup.generation == generation
    and popup.element
    and popup.element.layout
end

---@return H3UI.TokenValue color
---@return H3UI.TokenValue alpha
local function menuBackgroundStyle()
  local theme = appearance.activeTheme()
  return theme.token 'color.background', theme.token 'transparency.menu'
end

---@param argument? H3UI.ScreenPositionArgument
---@return string?
local function screenPositionTitle(argument)
  if Type(argument) ~= 'table' then return end
  if Type(argument.title) == 'string' then return argument.title end

  if Type(argument.l10n) == 'string' and Type(argument.name) == 'string' then
    return L10nFactory(argument.l10n)(argument.name)
  end
end

RegisterRenderer('ScreenPosition',
  ---@param value? openmw.util.Vector2
  ---@param set fun(value: openmw.util.Vector2)
  ---@param argument? H3UI.ScreenPositionArgument
  ---@return openmw.ui.Layout
  function(value, set, argument)
  local buttonSize = UtilVector2(20, 20)
  local previewSize = UtilVector2(50, 50)
  local titleText = screenPositionTitle(argument)
  local panelRelativeSize = UtilVector2(0.18, titleText and 0.24 or 0.21)
  local titleRelativePosition = UtilVector2(0.5, 0.09)
  local titleRelativeSize = UtilVector2(0.9, 0.1)
  local pickerRelativePosition = UtilVector2(0.5, titleText and 0.48 or 0.42)
  local pickerRelativeSize = UtilVector2(0.82, titleText and 0.56 or 0.68)
  local markerRelativeSize = UtilVector2(0.08, 0.11)
  local buttonRelativeSize = UtilVector2(0.3, 0.12)
  local applyButtonRelativePosition = UtilVector2(0.33, 0.88)
  local cancelButtonRelativePosition = UtilVector2(0.67, 0.88)
  local currentValue = normalizedScreenPosition(value)
  local previewBackgroundColor, previewBackgroundAlpha = menuBackgroundStyle()

  ---@param position openmw.util.Vector2
  ---@param props? table
  ---@return openmw.ui.Layout
  local function marker(position, props)
    props = props or { size = buttonSize }
    props.anchor = position
    props.relativePosition = position

    return {
      template = Templates.borders,
      props = props,
      content = UiContent {
        {
          type = UiType.Image,
          props = {
            resource = MarkTexture,
            relativeSize = UtilVector2(1, 1),
            color = ColorRGB(202 / 255, 165 / 255, 96 / 255),
          },
        },
      },
    }
  end

  ---@return nil
  local function openPopup()
    destroyScreenPositionPopup()
    screenPositionGeneration = screenPositionGeneration + 1

    local original = normalizedScreenPosition(value)
    local draft, dragging, writtenValue = original, false, nil

    local popup = {
      alive = true,
      generation = screenPositionGeneration,
      element = nil,
    }

    local screenSize = ScreenSize()
    local panelSize =
      UtilVector2(screenSize.x * panelRelativeSize.x, screenSize.y * panelRelativeSize.y)
    local pickerSize =
      UtilVector2(panelSize.x * pickerRelativeSize.x, panelSize.y * pickerRelativeSize.y)

    local generation = popup.generation
    local markerLayout = marker(draft, { relativeSize = markerRelativeSize })
    local backgroundColor, backgroundAlpha = menuBackgroundStyle()
    local panelContent = UiContent {}

    ---@return nil
    local function updateMarker()
      markerLayout.props.anchor = draft
      markerLayout.props.relativePosition = draft

      if isScreenPositionPopupAlive(popup, generation) then popup.element:update() end
    end

    ---@param offset openmw.util.Vector2
    ---@return nil
    local function offsetToDraft(offset)
      draft = UtilVector2(
        UtilClamp(offset.x / pickerSize.x, 0, 1),
        UtilClamp(offset.y / pickerSize.y, 0, 1)
      )

      updateMarker()
    end

    ---@param offset openmw.util.Vector2
    ---@return boolean
    local function offsetInsidePicker(offset)
      return offset.x >= 0
        and offset.y >= 0
        and offset.x <= pickerSize.x
        and offset.y <= pickerSize.y
    end

    ---@return nil
    local function closePopup()
      if isScreenPositionPopupAlive(popup, generation) then destroyScreenPositionPopup() end
    end

    ---@param label string
    ---@param callback fun(): nil
    ---@param props table
    ---@return openmw.ui.Layout
    local function button(label, callback, props)
      return {
        props = props,

        content = UiContent {
          {
            type = UiType.Image,
            props = {
              resource = WhiteTexture,
              relativeSize = UtilVector2(1, 1),
              color = backgroundColor,
              alpha = backgroundAlpha,
            },
          },

          {
            template = Templates.borders,
            props = {
              relativeSize = UtilVector2(1, 1),
            },
          },

          {
            template = Templates.textNormal,
            props = {
              text = label,
              textAlignH = UiAlignment.Center,
              textAlignV = UiAlignment.Center,
              autoSize = false,
              relativeSize = UtilVector2(1, 1),
            },
          },
        },

        events = {
          mouseClick = async:callback(
            ---@return nil
            function()
            if isScreenPositionPopupAlive(popup, generation) then callback() end
          end),
        },
      }
    end

    panelContent:add {
      type = UiType.Image,
      props = {
        resource = WhiteTexture,
        relativeSize = UtilVector2(1, 1),
        color = backgroundColor,
        alpha = backgroundAlpha,
      },
    }

    panelContent:add {
      template = Templates.borders,
      props = {
        relativeSize = UtilVector2(1, 1),
      },
    }

    if titleText then
      panelContent:add {
        template = Templates.textHeader,
        props = {
          anchor = Center,
          relativePosition = titleRelativePosition,
          relativeSize = titleRelativeSize,
          text = titleText,
          textAlignH = UiAlignment.Center,
          textAlignV = UiAlignment.Center,
          autoSize = false,
        },
      }
    end

    panelContent:add {
      props = {
        anchor = Center,
        relativePosition = pickerRelativePosition,
        relativeSize = pickerRelativeSize,
      },

      content = UiContent {
        {
          type = UiType.Image,
          props = {
            resource = WhiteTexture,
            relativeSize = UtilVector2(1, 1),
            color = backgroundColor,
            alpha = backgroundAlpha,
          },
        },

        {
          template = Templates.borders,
          props = {
            relativeSize = UtilVector2(1, 1),
          },
        },

        markerLayout,
      },

      events = {
        mousePress = async:callback(
          ---@param event? openmw.ui.MouseEvent
          ---@return nil
          function(event)
          if
            not isScreenPositionPopupAlive(popup, generation)
            or not event
            or event.button ~= 1
          then
            return
          end

          dragging = true
          offsetToDraft(event.offset)
        end),

        mouseMove = async:callback(
          ---@param event? openmw.ui.MouseEvent
          ---@return nil
          function(event)
          if not isScreenPositionPopupAlive(popup, generation) or not dragging or not event then
            return
          end

          offsetToDraft(event.offset)
        end),

        mouseRelease = async:callback(
          ---@param event? openmw.ui.MouseEvent
          ---@return nil
          function(event)
          if
            not isScreenPositionPopupAlive(popup, generation)
            or not dragging
            or not event
            or event.button ~= 1
          then
            return
          end

          dragging = false
          if offsetInsidePicker(event.offset) then offsetToDraft(event.offset) end

          writtenValue = draft
          set(draft)
        end),

        focusLoss = async:callback(
          ---@return nil
          function() dragging = false end),
      },
    }

    panelContent:add {
      props = {
        anchor = Center,
        relativePosition = applyButtonRelativePosition,
        relativeSize = buttonRelativeSize,
      },

      content = UiContent {
        button(L10n 'button_apply', closePopup, {
          relativeSize = UtilVector2(1, 1),
        }),
      },
    }

    panelContent:add {
      props = {
        anchor = Center,
        relativePosition = cancelButtonRelativePosition,
        relativeSize = buttonRelativeSize,
      },

      content = UiContent {
        button(L10n 'button_cancel',
          ---@return nil
          function()
          if writtenValue and not sameScreenPosition(writtenValue, original) then set(original) end
          closePopup()
        end, {
          relativeSize = UtilVector2(1, 1),
        }),
      },
    }

    --- `type` is not actually mandatory
    ---@diagnostic disable-next-line: missing-fields
    popup.element = UiCreate {
      layer = ScreenPositionLayer,
      props = {
        relativeSize = UtilVector2(1, 1),
      },

      content = UiContent {
        {
          type = UiType.Image,
          props = {
            resource = WhiteTexture,
            relativeSize = UtilVector2(1, 1),
            color = ColorRGB(0, 0, 0),
            alpha = 0.45,
          },
        },

        {
          props = {
            anchor = Center,
            relativePosition = Center,
            relativeSize = panelRelativeSize,
          },
          content = panelContent,
        },
      },
    }

    screenPositionPopup = popup
  end

  return {
    props = {
      size = previewSize + buttonSize,
    },

    content = UiContent {
      {
        type = UiType.Image,
        props = {
          resource = WhiteTexture,
          relativeSize = UtilVector2(1, 1),
          color = previewBackgroundColor,
          alpha = previewBackgroundAlpha,
        },
      },

      {
        template = Templates.borders,
        props = {
          relativeSize = UtilVector2(1, 1),
        },
      },

      marker(currentValue, { size = buttonSize }),
    },

    events = {
      mouseClick = async:callback(openPopup),
    },
  }
end)

RegisterRenderer('List',
  ---@param input string[]
  ---@param set fun(value: string[])
  ---@return openmw.ui.Layout
  function(input, set)
  local value = {}
  for i = 1, #input do
    TableInsert(value, input[i])
  end

  local header = {
    type = UiType.Flex,
    props = {
      horizontal = true,
    },

    content = UiContent {},
    external = {
      stretch = 1,
    },
  }

  local inputText = ''

  header.content:add {
    template = Templates.box,
    content = UiContent {
      {
        template = Templates.textEditLine,
        events = {
          textChanged = async:callback(
            ---@param text string
            ---@return nil
            function(text) inputText = text end),
        },
      },
    },
  }

  header.content:add {
    template = Templates.padding,
    external = {
      grow = 1,
    },
  }

  header.content:add {
    template = Templates.box,

    content = UiContent {
      {
        template = Templates.textNormal,
        props = {
          text = L10n 'button_add',
        },

        events = {
          mouseClick = async:callback(
            ---@return nil
            function()
            TableInsert(value, inputText)
            set(value)
          end),
        },
      },
    },
  }

  local body = {
    type = UiType.Flex,
    content = UiContent {},
  }
  ---@param text string
  ---@return string?
  local function remove(text)
    for i = 1, #value do
      local v = value[i]
      if v == text then return TableRemove(value, i) end
    end
  end

  for i = 1, #value do
    local text = value[i]
    body.content:add {
      template = Templates.padding,
    }

    body.content:add {
      type = UiType.Flex,
      props = {
        horizontal = true,
      },

      content = UiContent {
        {
          template = Templates.textNormal,
          props = { text = text },
        },

        {
          template = Templates.padding,
        },

        {
          template = Templates.box,
          content = UiContent {
            {
              template = Templates.textNormal,
              props = { text = L10n 'button_remove' },
              events = {
                mouseClick = async:callback(
                  ---@return nil
                  function()
                  remove(text)
                  set(value)
                end),
              },
            },
          },
        },
      },
    }
  end

  return {
    type = UiType.Flex,
    content = UiContent {
      header,
      body,
    },
  }
end)

---@param items H3UI.StringSelectorItem[]
---@param id string
---@return integer
local function themeIndex(items, id)
  for index = 1, #items do
    if items[index].value == id then return index end
  end

  return 1
end

RegisterRenderer('H3UITheme',
  ---@param _ H3UI.SettingValue
  ---@param set fun(value: string)
  ---@return openmw.ui.Layout
  function(_, set)
  local items, entries = {}, appearance.themeEntries()

  for index = 1, #entries do
    local entry = entries[index]
    items[#items + 1] = { label = entry.name, value = entry.id }
  end

  items[#items + 1] = {
    label = L10n 'H3UIThemeCustom',
    value = appearance.customThemeId,
  }

  local selected = appearance.currentThemeId()

  return selector {
    items = items,
    selected = themeIndex(items, selected),
    ---@param _ integer
    ---@param item H3UI.StringSelectorItem
    ---@return nil
    onSelect = function(_, item) appearance.selectTheme(item.value, set) end,
  }
end)

RegisterRenderer('H3UIChromeSource',
  ---@param value? string
  ---@param set fun(value: string): nil
  ---@return openmw.ui.Layout
  function(value, set)
  local items = {
    { label = L10n 'H3UIChromeSourceAuto', value = 'auto' },
    { label = L10n 'H3UIChromeSourceTheme', value = 'theme' },
    { label = L10n 'H3UIChromeSourceH3UI', value = 'h3ui' },
  }

  local selected = appearance.normalizeChromeSource(value) or appearance.defaultChromeSource

  return selector {
    items = items,
    selected = themeIndex(items, selected),
    ---@param _ integer
    ---@param item H3UI.StringSelectorItem
    ---@return nil
    onSelect = function(_, item) set(item.value) end,
  }
end)

RegisterRenderer('H3UIMaterialFamily',
  ---@param value? string
  ---@param set fun(value: string)
  ---@return openmw.ui.Layout
  function(value, set)
  local items, families = {}, appearance.materialFamilies()

  for index = 1, #families do
    local family = families[index]
    items[#items + 1] = {
      label = L10n(StrFormat('H3UIChromeMaterialFamily_%s', family)),
      value = family,
    }
  end

  local selected = appearance.normalizeMaterialFamily(value) or appearance.defaultMaterialFamily

  return selector {
    items = items,
    selected = themeIndex(items, selected),
    ---@param _ integer
    ---@param item H3UI.StringSelectorItem
    ---@return nil
    onSelect = function(_, item) appearance.selectMaterialFamily(item.value, set) end,
  }
end)

RegisterRenderer('H3UIMaterial',
  ---@param _ H3UI.SettingValue
  ---@param set fun(value: string)
  ---@return openmw.ui.Layout
  function(_, set)
  local items, stems = {}, appearance.materialStems(appearance.chromeMaterialFamily())

  for index = 1, #stems do
    local stem = stems[index]
    items[#items + 1] = {
      label = L10n(StrFormat('H3UIChromeMaterial_%s', stem)),
      value = stem,
    }
  end

  local selected = appearance.chromeMaterial()

  return selector {
    items = items,
    selected = themeIndex(items, selected),
    ---@param _ integer
    ---@param item H3UI.StringSelectorItem
    ---@return nil
    onSelect = function(_, item) set(item.value) end,
  }
end)

RegisterRenderer('H3UIColor',
  ---@param value? string
  ---@param set fun(value: string)
  ---@param argument H3UI.ColorRendererArgument
  ---@return openmw.ui.Layout
  function(value, set, argument)
  local hex = appearance.normalizeHex(value) or '000000'
  local swatch = {
    type = UiType.Image,
    props = {
      resource = WhiteTexture,
      size = UtilVector2(32, 20),
      color = appearance.color(hex),
    },
  }

  return {
    type = UiType.Flex,
    props = { horizontal = true },
    content = UiContent {
      swatch,
      {
        template = Templates.box,
        external = { stretch = 1 },
        content = UiContent {
          {
            template = Templates.textEditLine,
            props = { text = hex },
            events = {
              textChanged = async:callback(
                ---@param text string
                ---@return nil
                function(text)
                local nextHex = appearance.normalizeHex(text)
                if not nextHex then return end
                swatch.props.color = appearance.color(nextHex)
                appearance.setColor(argument.key, nextHex, set)
              end),
            },
          },
        },
      },
    },
  }
end)

RegisterRenderer('H3UIReset',
  ---@param _ H3UI.SettingValue
  ---@param set fun(value: boolean)
  ---@return openmw.ui.Layout
  function(_, set)
  return {
    template = Templates.box,
    content = UiContent {
      {
        template = Templates.textNormal,
        props = { text = L10n 'H3UIResetName' },
        events = {
          mouseClick = async:callback(
            ---@return nil
            function()
            appearance.reset()
            set(false)
          end),
        },
      },
    },
  }
end)

---@type { engineHandlers: table }
return {}
