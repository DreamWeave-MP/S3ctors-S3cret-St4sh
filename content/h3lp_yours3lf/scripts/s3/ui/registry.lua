---@omw-context menu|player

local async = require 'openmw.async'
local constants = require 'scripts.s3.ui.constants'
local merge = require 'scripts.s3.ui.merge'

local styleTargetMarker = {}

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

  function registry.supportsRuntimeState(name) return registry.get(name).runtimeState == true end

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

  local function markStyleTargets(options, adapter, styles)
    for slotName, mapping in next, adapter.slots do
      local kinds = styles[slotName]
      if kinds then
        for styleKind, optionKey in next, mapping do
          if kinds[styleKind] then
            local styleOptions = options[optionKey]
            if styleOptions == nil then
              styleOptions = {}
              options[optionKey] = styleOptions
            end
            if merge.isPlainTable(styleOptions) then
              local marks = rawget(styleOptions, styleTargetMarker)
              if not marks then
                marks = {}
                rawset(styleOptions, styleTargetMarker, marks)
              end
              local slotMarks = marks[slotName]
              if not slotMarks then
                slotMarks = {}
                marks[slotName] = slotMarks
              end
              slotMarks[styleKind] = true
            end
          end
        end
      end
    end
  end

  local function collectStyleTargets(layout)
    local targets = {}
    local seen = {}

    local function collect(value)
      if type(value) ~= 'table' or seen[value] then return end
      seen[value] = true
      local marks = rawget(value, styleTargetMarker)
      if marks then
        rawset(value, styleTargetMarker, nil)
        for slotName, slotMarks in next, marks do
          local slotTargets = targets[slotName] or {}
          targets[slotName] = slotTargets
          for styleKind in next, slotMarks do
            slotTargets[#slotTargets + 1] = {
              kind = styleKind,
              value = value,
            }
          end
        end
      end
    end

    local function visit(layoutValue)
      if type(layoutValue) ~= 'table' then return end
      collect(layoutValue.props)
      collect(layoutValue.external)

      local content = layoutValue.content
      if content ~= nil then
        for index = 1, #content do
          visit(content[index])
        end
      end
    end

    visit(layout)
    return targets
  end

  local function protectedStyleKeys(adapter, args, inlineStyles)
    local protected = {}

    local function add(source)
      if not source then return end
      for slotName, mapping in next, adapter.slots do
        for styleKind, optionKey in next, mapping do
          if styleKind == 'props' or styleKind == 'external' then
            local value = source[optionKey]
            if value ~= nil then
              local slot = protected[slotName]
              if not slot then
                slot = {}
                protected[slotName] = slot
              end
              local keys = slot[styleKind]
              if keys == nil then
                keys = merge.isPlainTable(value) and {} or true
                slot[styleKind] = keys
              end
              if keys ~= true then
                for key in next, value do
                  keys[key] = true
                end
              end
            end
          end
        end
      end
    end

    add(args)

    for slotName, style in next, inlineStyles or {} do
      local slot = protected[slotName]
      if not slot then
        slot = {}
        protected[slotName] = slot
      end
      for styleKind, values in next, style do
        if styleKind == 'props' or styleKind == 'external' then
          local keys = slot[styleKind]
          if keys == nil then
            keys = {}
            slot[styleKind] = keys
          end
          if keys ~= true then
            for key in next, values do
              keys[key] = true
            end
          end
        end
      end
    end

    return protected
  end

  local function compileStateDeltas(targets, stateStyles, protected)
    local compiled = {}
    local count = 0

    for state, styles in next, stateStyles do
      if state ~= 'baseState' then
        local stateDeltas = {}

        for slotName, style in next, styles do
          local slotTargets = targets[slotName]
          if slotTargets then
            local slotProtection = protected[slotName]
            for styleKind, values in next, style do
              if styleKind == 'props' or styleKind == 'external' then
                local keys = slotProtection and slotProtection[styleKind]
                if keys ~= true then
                  for key, value in next, values do
                    if not (keys and keys[key]) then
                      for targetIndex = 1, #slotTargets do
                        local target = slotTargets[targetIndex]
                        if target.kind == styleKind then
                          stateDeltas[#stateDeltas + 1] = {
                            key = key,
                            target = target,
                            value = value,
                          }
                          count = count + 1
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end

        if #stateDeltas > 0 then compiled[state] = stateDeltas end
      end
    end

    return compiled, count
  end

  local function applyStateDeltas(active, deltas)
    for index = 1, #active do
      local entry = active[index]
      if entry.hadValue then
        entry.target.value[entry.key] = entry.previous
      else
        entry.target.value[entry.key] = nil
      end
      active[index] = nil
    end

    for index = 1, #deltas do
      local entry = deltas[index]
      local value = entry.target.value[entry.key]
      entry.previous = value
      entry.hadValue = value ~= nil
      if constants.isUnset(entry.value) then
        entry.target.value[entry.key] = nil
      else
        entry.target.value[entry.key] = merge.copy(entry.value)
      end
      active[index] = entry
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

  function registry.build(name, args, themeStyles, inlineStyles, stateStyles, invalidate)
    local adapter = registry.get(name)
    local options = {}

    applyStyles(options, adapter, themeStyles)
    overlayArgs(options, adapter, args)
    applyStyles(options, adapter, inlineStyles)
    if stateStyles then
      local activeSlots = {}
      for state, styles in next, stateStyles do
        if state ~= 'baseState' then
          applyStyles({}, adapter, styles)
          for slotName, style in next, styles do
            local kinds = activeSlots[slotName] or {}
            activeSlots[slotName] = kinds
            for styleKind in next, style do
              assert(
                styleKind == 'props' or styleKind == 'external',
                'H3 UI runtime state styles support props and external values only'
              )
              kinds[styleKind] = true
            end
          end
        end
      end
      markStyleTargets(options, adapter, activeSlots)
    end

    local layout = adapter.builder(options)
    if stateStyles then
      local targets = collectStyleTargets(layout)
      local protected = protectedStyleKeys(adapter, args, inlineStyles)
      local compiled, deltaCount = compileStateDeltas(targets, stateStyles, protected)
      if deltaCount == 0 then return layout end

      local events = merge.shallowCopy(layout.events or {})
      layout.events = events
      local baseState = stateStyles.baseState
      local active = {}
      local emptyDeltas = {}
      local currentState
      local focused = false
      local pressed = false

      local function nextState()
        if pressed and compiled.pressed then return 'pressed' end
        if focused and compiled.hover then return 'hover' end
        return baseState
      end

      local function refreshState()
        local state = nextState()
        if currentState == state then return false end
        currentState = state
        applyStateDeltas(active, compiled[state] or emptyDeltas)
        return true
      end

      local function addStateHandler(name, transition)
        local previous = events[name]
        events[name] = async:callback(function(event, eventLayout)
          transition(event)
          local changed = refreshState()
          local result
          if previous then result = previous(event, eventLayout) end
          if changed and invalidate then invalidate() end
          return result
        end)
      end

      addStateHandler('focusGain', function() focused = true end)
      addStateHandler('focusLoss', function()
        focused = false
        pressed = false
      end)
      addStateHandler('mousePress', function(event)
        if event and event.button == 1 then pressed = true end
      end)
      addStateHandler('mouseRelease', function(event)
        if event and event.button == 1 then pressed = false end
      end)

      refreshState()
      return layout
    end

    return layout
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
