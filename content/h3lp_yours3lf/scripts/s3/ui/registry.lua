---@omw-context menu|player

local constants = require 'scripts.s3.ui.constants'
local merge = require 'scripts.s3.ui.merge'

local function new(definitions)
  local adapters = {}

  for name, definition in next, definitions do
    assert(type(name) == 'string' and name ~= '', 'H3 UI component name must be a string')
    assert(type(definition) == 'table', 'H3 UI component adapter must be a table')
    assert(
      type(definition.builder) == 'function',
      'H3 UI component adapter requires builder: ' .. name
    )
    assert(
      type(definition.slots) == 'table' and definition.slots.root,
      'H3 UI component adapter requires root slot: ' .. name
    )
    local styledOptions = {}
    for _, mapping in next, definition.slots do
      for _, optionKey in next, mapping do
        styledOptions[optionKey] = true
      end
    end
    definition._styledOptions = styledOptions
    adapters[name] = definition
  end

  local registry = {}

  function registry.get(name)
    local adapter = adapters[name]
    if not adapter then error('Unknown H3 UI component: ' .. tostring(name)) end
    return adapter
  end

  function registry.has(name) return adapters[name] ~= nil end

  function registry.validateSlot(name, slot)
    local adapter = registry.get(name)
    if not adapter.slots[slot] then
      error(('Unknown H3 UI style slot %q for component %q'):format(tostring(slot), name))
    end
    return true
  end

  local function applySlot(options, adapter, slotName, style)
    local mapping = adapter.slots[slotName]
    if not mapping then
      error(('Unknown H3 UI style slot %q for component %q'):format(slotName, adapter.name))
    end
    assert(merge.isPlainTable(style), 'H3 UI style slot must be a plain table')

    for styleKey, value in next, style do
      local optionKey = mapping[styleKey]
      if not optionKey then
        error(
          ('Unsupported H3 UI style key %q on %s.%s'):format(
            tostring(styleKey),
            adapter.name,
            slotName
          )
        )
      end

      if constants.isUnset(value) then
        options[optionKey] = nil
      elseif merge.isPlainTable(value) then
        local current = options[optionKey]
        if not merge.isPlainTable(current) then
          current = {}
          options[optionKey] = current
        end
        merge.mergeInto(current, value)
      else
        options[optionKey] = value
      end
    end
  end

  local function applyStyles(options, adapter, styles)
    if not styles then return end
    for slotName, style in next, styles do
      applySlot(options, adapter, slotName, style)
    end
  end

  local function overlayArgs(options, adapter, args)
    if not args then return end
    for key, value in next, args do
      if adapter._styledOptions[key] and merge.isPlainTable(value) then
        local current = options[key]
        if not merge.isPlainTable(current) then
          current = {}
          options[key] = current
        end
        merge.mergeInto(current, value)
      else
        -- Behavioral data and child layouts remain opaque. In particular, do not deep-copy
        -- caller-owned raw child layouts merely because they pass through H3UI.
        options[key] = value
      end
    end
  end

  function registry.build(name, args, themeStyles, inlineStyles)
    local adapter = registry.get(name)
    local options = {}

    applyStyles(options, adapter, themeStyles)
    overlayArgs(options, adapter, args)
    applyStyles(options, adapter, inlineStyles)

    return adapter.builder(options)
  end

  function registry.slots(name)
    local adapter = registry.get(name)
    local result = {}
    for slot in next, adapter.slots do
      result[#result + 1] = slot
    end
    table.sort(result)
    return result
  end

  for name, adapter in next, adapters do
    adapter.name = name
  end

  return registry
end

return new
