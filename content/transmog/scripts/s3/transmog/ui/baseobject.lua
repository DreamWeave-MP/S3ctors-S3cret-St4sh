local ui = require('openmw.ui')
local util = require('openmw.util')

local common = require('scripts.s3.transmog.ui.common')
local Object = require('scripts.s3.transmog.lib.object')

local BaseUIObject = {}

local ElementValidateString = "No content available, has this element been constructed?"

function BaseUIObject.new(props)
  local newUIObject = Object:new(BaseUIObject)

  for k, v in pairs(props) do
    newUIObject[k] = v
  end

  return newUIObject
end

-- Provides the enchantment frame for the item portrait, if the item is enchanted.
-- Just fills in a fake element otherwise.
-- @param enchant: The enchantment string of the item
function BaseUIObject.getEnchantmentFrame(enchantId)
  if not enchantId or enchantId == "" then
    return { props = { name = "Empty Enchantment Frame" }}
  end

  return {
    type = ui.TYPE.Image,
    props = {
      -- We really need to do something about this!
      -- The original enchantment frame is 1/4 the size of the icon
      -- So I sliced out the empty space and made it a 1/4 size image
      -- preferably we should find some way to use the original
      resource = ui.texture{ path = "textures\\mogenchant\\menu_icon_magic.dds" },
      relativeSize = util.vector2(1, 1),
    },
    external = {
      grow = 1,
      stretch = 1,
    },
  }
end

--- Checks if a layout is visible (and exists)
function BaseUIObject:isVisible()
  return self and self.props and self.props.visible
end

--- Finds the size of a layout, or that of its largest child
--- @param layout openmw_ui#Layout: The layout to find the size of
--- @return openmw_util#Vector2
function BaseUIObject:getSize()
  local currentSize = self.props.size

  if self.content then
    for _, child in ipairs(self.content) do
      if child.props and child.props.size then
        if not currentSize or child.props.size:length() > currentSize:length() then
          currentSize = child.props.size
          break
        end
      end
    end
  end

  return currentSize
end

--- Checks if a layout has a highlight
--- @param layout openmw_ui#Layout: The layout to check for a highlight
--- @return boolean
function BaseUIObject:hasHighlight()
  assert(self.content, ElementValidateString)
  for _, child in ipairs(self.content) do
    if child.props and child.props.name == "highlight" then
      return true
    end
  end
  return false
end

--- Removes a highlight from an arbitrary layout
--- Don't forget you need to actually update it after!
--- @param layout openmw_ui#Layout: The layout to remove the highlight from
function BaseUIObject:removeHighlight()
  assert(self.content, ElementValidateString)
  for index, child in ipairs(self.content) do
    if child.props and child.props.name == "highlight" then
      table.remove(self.content, index)
      break
    end
  end
end

--- Adds a highlight to an arbitrary layout
--- Don't forget you need to actually update it after!
--- @param layout openmw_ui#Layout: The layout to add the highlight to
--- @param size openmw_util#Vector2: The size of the highlight
function BaseUIObject:addHighlight(highlightArgs)
  assert(self.content, ElementValidateString)
  if self:hasHighlight() then return end
  highlightArgs = highlightArgs or {}

  local highlightTemplate = {
    type = ui.TYPE.Image,
    props = {
      name = "highlight",
      resource = ui.texture{ path = 'white' },
      color = highlightArgs.color or common.const.HIGHLIGHT_COLOR,
      relativeSize = highlightArgs.relativeSize or util.vector2(1, 1),
    },
  }

  self.content:insert(1, highlightTemplate)
end

function BaseUIObject:getElementByName(name)
  for _, child in ipairs(self.content or {}) do
    if child.props and child.props.name == name then
      return child
    end
    local found = self:getElementByName(child, name)
    if found then return found end
  end
end

function BaseUIObject:getUserData()
  assert(self.content, ElementValidateString)
  for _, content in ipairs(self.content) do
    if content.userData then
      return content.userData
    end
  end
end

return BaseUIObject
