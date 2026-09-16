---@module 'scripts.s3.ui.themes.chromeAssets'
---@omw-context menu|player

local util = require 'openmw.util'

local function vector2(x, y) return util.vector2(x, y) end

local function region(path, x, y, width, height, thickness, center, tintable)
  return {
    path = path,
    offset = vector2(x, y),
    size = vector2(width, height),
    thickness = thickness,
    center = center,
    tintable = tintable,
  }
end

local function frame(path, tintable, pinSize)
  return {
    thin = region(path, 0, 0, 516, 516, 2, false, tintable),
    thick = region(path, 520, 0, 520, 520, 4, false, tintable),
    button = region(path, 0, 520, 136, 24, 4, false, tintable),
    caption = region(path, 140, 520, 260, 20, 2, true, tintable),
    pinUp = region(
      path,
      402,
      520,
      pinSize == 15 and 19 or 20,
      pinSize == 15 and 19 or 20,
      2,
      true,
      tintable
    ),
    pinDown = region(
      path,
      424,
      520,
      pinSize == 15 and 19 or 20,
      pinSize == 15 and 19 or 20,
      2,
      true,
      tintable
    ),
  }
end

local function scroll(path, size)
  return {
    up = region(path, 0, 552, size, size),
    down = region(path, 34, 552, size, size),
    left = region(path, 68, 552, size, size),
    right = region(path, 102, 552, size, size),
  }
end

local h3uiPath = 'textures/h3ui/h3ui_chrome.dds'
local morrowindPath = 'textures/h3ui/morrowind_chrome.dds'

return {
  h3ui = {
    frame = frame(h3uiPath, true, 15),
    scroll = scroll(h3uiPath, 8),
  },
  morrowind = {
    frame = frame(morrowindPath, true, 16),
    scroll = scroll(morrowindPath, 16),
  },
  starwind = {
    frame = frame(morrowindPath, true, 16),
    scroll = scroll(morrowindPath, 16),
  },
}
