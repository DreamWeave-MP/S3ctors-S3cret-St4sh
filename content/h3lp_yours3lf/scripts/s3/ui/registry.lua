---@omw-context menu|player

local async = require 'openmw.async'
local constants = require 'scripts.s3.ui.constants'
local merge = require 'scripts.s3.ui.merge'
local mutation = require 'scripts.s3.ui.mutation'

local styleTargetMarker = {}
local styleTargetGroupMarker = {}
local emptyDeltas = {}

local function new(definitions)
  local adapters = {}
  local adapterNames = {}

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
    local stateTargetMarkers = {}
    local stateTargetOptions = {}
    for slotName, mapping in next, definition.slots do
      local slotMarkers = {}
      stateTargetMarkers[slotName] = slotMarkers
      for styleKind, optionKey in next, mapping do
        styledOptions[optionKey] = true
        if styleKind == 'props' or styleKind == 'external' then
          local previous = stateTargetOptions[optionKey]
          assert(
            previous == nil,
            ('H3 UI runtime style target %q is shared by %s.%s and %s.%s'):format(
              optionKey,
              previous and previous.slot or slotName,
              previous and previous.kind or styleKind,
              slotName,
              styleKind
            )
          )
          local marker = {
            slot = slotName,
            kind = styleKind,
            option = optionKey,
          }
          slotMarkers[styleKind] = marker
          stateTargetOptions[optionKey] = marker
        end
      end
    end
    definition._styledOptions = styledOptions
    definition._stateTargetMarkers = stateTargetMarkers
    adapters[name] = definition
    adapterNames[definition] = name
  end

  local registry = {}

  function registry.get(name)
    local adapter = adapters[name]
    if not adapter then error('Unknown H3 UI component: ' .. tostring(name)) end
    return adapter
  end

  function registry.has(name) return adapters[name] ~= nil end

  function registry.supportsRuntimeState(name) return registry.get(name).runtimeState == true end

  function registry.supportsSelection(name) return registry.get(name).selectable == true end

  function registry.publicComponents()
    local result = {}
    for name, adapter in next, adapters do
      if adapter.public then result[#result + 1] = name end
    end
    table.sort(result)
    return result
  end

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
      error(
        ('Unknown H3 UI style slot %q for component %q'):format(slotName, adapterNames[adapter])
      )
    end
    assert(merge.isPlainTable(style), 'H3 UI style slot must be a plain table')

    for styleKey, value in next, style do
      local optionKey = mapping[styleKey]
      if not optionKey then
        error(
          ('Unsupported H3 UI style key %q on %s.%s'):format(
            tostring(styleKey),
            adapterNames[adapter],
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

  local function markStyleTargets(options, adapter, stateStyles)
    for state, styles in next, stateStyles do
      if state ~= 'baseState' then
        for slotName, style in next, styles do
          local mapping = adapter.slots[slotName]
          if not mapping then
            error(
              ('Unknown H3 UI style slot %q for component %q'):format(
                slotName,
                adapterNames[adapter]
              )
            )
          end

          for styleKind in next, style do
            assert(
              styleKind == 'props' or styleKind == 'external',
              'H3 UI runtime state styles support props and external values only'
            )
            local optionKey = mapping[styleKind]
            if not optionKey then
              error(
                ('Unsupported H3 UI style key %q on %s.%s'):format(
                  tostring(styleKind),
                  adapterNames[adapter],
                  slotName
                )
              )
            end

            local styleOptions = options[optionKey]
            if styleOptions == nil then
              styleOptions = {}
              options[optionKey] = styleOptions
            end
            assert(
              merge.isPlainTable(styleOptions),
              'H3 UI runtime state target must be a plain table: ' .. optionKey
            )
            rawset(
              styleOptions,
              styleTargetMarker,
              adapter._stateTargetMarkers[slotName][styleKind]
            )
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
      local marker = rawget(value, styleTargetMarker)
      if not marker then return end
      rawset(value, styleTargetMarker, nil)

      local target = targets[marker]
      if target == nil then
        targets[marker] = value
      elseif rawget(target, styleTargetGroupMarker) then
        target[#target + 1] = value
      else
        targets[marker] = {
          [styleTargetGroupMarker] = true,
          target,
          value,
        }
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
    local protected

    local function add(source)
      if not source then return end
      for slotName, mapping in next, adapter.slots do
        for styleKind, optionKey in next, mapping do
          if styleKind == 'props' or styleKind == 'external' then
            local value = source[optionKey]
            if value ~= nil then
              protected = protected or {}
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
      protected = protected or {}
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

  local function appendStateDelta(deltas, target, key, value)
    if rawget(target, styleTargetGroupMarker) then
      for index = 1, #target do
        local offset = #deltas
        deltas[offset + 1] = target[index]
        deltas[offset + 2] = key
        deltas[offset + 3] = value
      end
      return #target
    end

    local offset = #deltas
    deltas[offset + 1] = target
    deltas[offset + 2] = key
    deltas[offset + 3] = value
    return 1
  end

  local function compileStateDeltas(adapter, targets, stateStyles, protected)
    local compiled = {}
    local count = 0

    for state, styles in next, stateStyles do
      if state ~= 'baseState' then
        local stateDeltas = {}

        for slotName, style in next, styles do
          local slotProtection = protected and protected[slotName]
          local markers = adapter._stateTargetMarkers[slotName]
          for styleKind, values in next, style do
            if styleKind == 'props' or styleKind == 'external' then
              local keys = slotProtection and slotProtection[styleKind]
              if keys ~= true then
                local target = targets[markers[styleKind]]
                if target then
                  for key, value in next, values do
                    if not (keys and keys[key]) then
                      count = count + appendStateDelta(stateDeltas, target, key, value)
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
    for index = 1, #active, 4 do
      local target = active[index]
      local key = active[index + 1]
      if active[index + 3] then
        target[key] = active[index + 2]
      else
        target[key] = nil
      end
    end

    local activeIndex = 1
    for index = 1, #deltas, 3 do
      local target = deltas[index]
      local key = deltas[index + 1]
      local value = target[key]
      active[activeIndex] = target
      active[activeIndex + 1] = key
      active[activeIndex + 2] = value
      active[activeIndex + 3] = value ~= nil
      if constants.isUnset(deltas[index + 2]) then
        target[key] = nil
      else
        target[key] = merge.copy(deltas[index + 2])
      end
      activeIndex = activeIndex + 4
    end

    for index = activeIndex, #active do
      active[index] = nil
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

  local function applyInvalidation(options, adapter, invalidate)
    if not invalidate or not adapter.invalidateOn then return end

    local callbacks = adapter.invalidateOn
    if type(callbacks) == 'string' then
      options[callbacks] = mutation.invalidateAfter(options[callbacks], invalidate)
      return
    end

    for index = 1, #callbacks do
      local name = callbacks[index]
      options[name] = mutation.invalidateAfter(options[name], invalidate)
    end
  end

  local runtimeStates = setmetatable({}, { __mode = 'k' })

  local function refreshRuntimeState(state)
    local nextState
    if state.pressed and state.compiled.pressed then
      nextState = 'pressed'
    elseif state.focused and state.compiled.hover then
      nextState = 'hover'
    else
      nextState = state.baseState
    end

    if state.currentState == nextState then return false end
    state.currentState = nextState
    applyStateDeltas(state.active, state.compiled[nextState] or emptyDeltas)
    return true
  end

  local function finishRuntimeStateEvent(state, previous, event, eventLayout)
    local changed = refreshRuntimeState(state)
    local result
    if previous then result = previous(event, eventLayout) end
    if changed and state.invalidate then state.invalidate() end
    return result
  end

  local function onFocusGain(event, eventLayout)
    local state = runtimeStates[eventLayout]
    if not state then return end
    state.focused = true
    return finishRuntimeStateEvent(state, state.focusGain, event, eventLayout)
  end

  local function onFocusLoss(event, eventLayout)
    local state = runtimeStates[eventLayout]
    if not state then return end
    state.focused = nil
    state.pressed = nil
    return finishRuntimeStateEvent(state, state.focusLoss, event, eventLayout)
  end

  local function onMousePress(event, eventLayout)
    local state = runtimeStates[eventLayout]
    if not state then return end
    if event and event.button == 1 then state.pressed = true end
    return finishRuntimeStateEvent(state, state.mousePress, event, eventLayout)
  end

  local function onMouseRelease(event, eventLayout)
    local state = runtimeStates[eventLayout]
    if not state then return end
    if event and event.button == 1 then state.pressed = nil end
    return finishRuntimeStateEvent(state, state.mouseRelease, event, eventLayout)
  end

  local stateHandlers = {
    focusGain = async:callback(onFocusGain),
    focusLoss = async:callback(onFocusLoss),
    mousePress = async:callback(onMousePress),
    mouseRelease = async:callback(onMouseRelease),
  }

  local function installStateHandler(state, events, name)
    state[name] = events[name]
    events[name] = stateHandlers[name]
  end

  function registry.build(name, args, themeStyles, inlineStyles, stateStyles, invalidate)
    local adapter = registry.get(name)
    local options = {}

    applyStyles(options, adapter, themeStyles)
    overlayArgs(options, adapter, args)
    applyStyles(options, adapter, inlineStyles)
    if stateStyles then markStyleTargets(options, adapter, stateStyles) end

    applyInvalidation(options, adapter, invalidate)

    local layout = adapter.builder(options)
    if stateStyles then
      local targets = collectStyleTargets(layout)
      local protected = protectedStyleKeys(adapter, args, inlineStyles)
      local compiled, deltaCount = compileStateDeltas(adapter, targets, stateStyles, protected)
      if deltaCount == 0 then return layout end

      local events = merge.shallowCopy(layout.events or {})
      layout.events = events
      local state = {
        active = {},
        baseState = stateStyles.baseState,
        compiled = compiled,
        invalidate = invalidate,
      }
      runtimeStates[layout] = state

      local hasHover = compiled.hover ~= nil
      local hasPressed = compiled.pressed ~= nil
      if hasHover then installStateHandler(state, events, 'focusGain') end
      if hasHover or hasPressed then installStateHandler(state, events, 'focusLoss') end
      if hasPressed then
        installStateHandler(state, events, 'mousePress')
        installStateHandler(state, events, 'mouseRelease')
      end

      refreshRuntimeState(state)
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

  return registry
end

return new
