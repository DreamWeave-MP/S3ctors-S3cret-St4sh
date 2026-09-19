---@omw-context menu|player
---@module 'scripts.s3.ui.registry'

local async = require 'openmw.async'
local constants = require 'scripts.s3.ui.constants'
local merge = require 'scripts.s3.ui.merge'
local mutation = require 'scripts.s3.ui.mutation'

local styleTargetMarker = {}
local styleTargetGroupMarker = {}
local emptyDeltas = {}

---@param definitions H3UI.ComponentDefinitions
---@return H3UI.Registry
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
        if styleKind ~= 'retained' then styledOptions[optionKey] = true end
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
    definition._targetMarkers = stateTargetMarkers
    definition._stateTargetMarkers = stateTargetMarkers
    adapters[name] = definition
    adapterNames[definition] = name
  end

  local registry = {}
  local runtimeStates = setmetatable({}, { __mode = 'k' })
  local semanticTargets = setmetatable({}, { __mode = 'k' })
  local layoutAdapters = setmetatable({}, { __mode = 'k' })
  local layoutInvalidators = setmetatable({}, { __mode = 'k' })
  local selectionStates = setmetatable({}, { __mode = 'k' })

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

  local function markStyleTargets(options, adapter, stateStyles, selectionStyles)
    if stateStyles then
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

    local function markSelectionStyles(styles)
      if not styles then return end
      for slotName, style in next, styles do
        local mapping = adapter.slots[slotName]
        if not mapping then
          error(
            ('Unknown H3 UI style slot %q for component %q'):format(slotName, adapterNames[adapter])
          )
        end
        for styleKind in next, style do
          if styleKind == 'props' or styleKind == 'external' then
            local optionKey = mapping[styleKind]
            assert(
              optionKey,
              ('Unsupported H3 UI style key %q on %s.%s'):format(
                tostring(styleKind),
                adapterNames[adapter],
                slotName
              )
            )
            local styleOptions = options[optionKey]
            if styleOptions == nil then
              styleOptions = {}
              options[optionKey] = styleOptions
            end
            assert(merge.isPlainTable(styleOptions), 'H3 UI selection target must be a plain table')
            rawset(styleOptions, styleTargetMarker, adapter._targetMarkers[slotName][styleKind])
          end
        end
      end
    end
    if selectionStyles then
      markSelectionStyles(selectionStyles.base)
      markSelectionStyles(selectionStyles.selected)
    end

    for slotName, mapping in next, adapter.slots do
      local markers = adapter._targetMarkers[slotName]
      for styleKind in next, mapping do
        if styleKind == 'props' or styleKind == 'external' then
          local optionKey = mapping[styleKind]
          local styleOptions = options[optionKey]
          if
            styleOptions ~= nil
            or slotName == 'root' and styleKind == 'props'
            or mapping.retained == true and styleKind == 'props'
          then
            if styleOptions == nil then
              styleOptions = {}
              options[optionKey] = styleOptions
            end
            assert(
              merge.isPlainTable(styleOptions),
              'H3 UI semantic target must be a plain table: ' .. optionKey
            )
            rawset(styleOptions, styleTargetMarker, markers[styleKind])
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

      if layoutValue.template ~= nil then visit(layoutValue.template) end
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

    if inlineStyles then
      for slotName, style in next, inlineStyles do
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
    if not stateStyles then return emptyDeltas, 0 end

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
                      count = count + appendStateDelta(stateDeltas, target, key, merge.copy(value))
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

  local function compileStyleDeltas(adapter, targets, styles, protected)
    local deltas = {}

    for slotName, style in next, styles do
      local slotProtection = protected and protected[slotName]
      local markers = adapter._targetMarkers[slotName]
      for styleKind, values in next, style do
        if styleKind == 'props' or styleKind == 'external' then
          local keys = slotProtection and slotProtection[styleKind]
          if keys ~= true then
            local target = targets[markers[styleKind]]
            if target then
              for key, value in next, values do
                if not (keys and keys[key]) then
                  appendStateDelta(deltas, target, key, merge.copy(value))
                end
              end
            end
          end
        end
      end
    end

    return deltas
  end

  local function addSelectionValues(values, deltas)
    for index = 1, #deltas, 3 do
      local target = deltas[index]
      local key = deltas[index + 1]
      local targetValues = values[target]
      if targetValues == nil then
        targetValues = {}
        values[target] = targetValues
      end
      targetValues[key] = deltas[index + 2]
    end
  end

  local function appendSelectionDelta(deltas, target, key, value, present)
    local offset = #deltas
    deltas[offset + 1] = target
    deltas[offset + 2] = key
    deltas[offset + 3] = value
    deltas[offset + 4] = present
  end

  local function makeSelectionDeltas(baseValues, selectedValues)
    local baseDeltas = {}
    local selectedDeltas = {}
    local seen = {}

    local function addKeys(values)
      for target, targetValues in next, values do
        local targetKeys = seen[target]
        if targetKeys == nil then
          targetKeys = {}
          seen[target] = targetKeys
        end
        for key in next, targetValues do
          targetKeys[key] = true
        end
      end
    end
    addKeys(baseValues)
    addKeys(selectedValues)

    for target, targetKeys in next, seen do
      for key in next, targetKeys do
        local baseline = target[key]
        local baseValue = baseValues[target] and baseValues[target][key]
        local selectedValue = selectedValues[target] and selectedValues[target][key]
        if baseValue == nil then baseValue = baseline end
        if selectedValue == nil then selectedValue = baseline end
        appendSelectionDelta(
          baseDeltas,
          target,
          key,
          baseValue,
          baseValue ~= nil or baseline ~= nil
        )
        appendSelectionDelta(
          selectedDeltas,
          target,
          key,
          selectedValue,
          selectedValue ~= nil or baseline ~= nil
        )
      end
    end

    return baseDeltas, selectedDeltas
  end

  local function makeSelectionState(
    layout,
    adapter,
    targets,
    baseStyles,
    selectedStyles,
    protected,
    selected
  )
    local baseValues = {}
    local selectedValues = {}
    addSelectionValues(baseValues, compileStyleDeltas(adapter, targets, baseStyles, protected))
    addSelectionValues(
      selectedValues,
      compileStyleDeltas(adapter, targets, selectedStyles, protected)
    )

    local baseDeltas, selectedDeltas = makeSelectionDeltas(baseValues, selectedValues)
    if #baseDeltas == 0 then return end

    local state = {
      deltas = { base = baseDeltas, selected = selectedDeltas },
      selected = selected == true,
    }
    selectionStates[layout] = state
    return state
  end

  local function applySelectionState(state, selected)
    local deltas = state.deltas[selected and 'selected' or 'base']
    for index = 1, #deltas, 4 do
      local target = deltas[index]
      local key = deltas[index + 1]
      local value = deltas[index + 2]
      if not deltas[index + 3] or constants.isUnset(value) then
        target[key] = nil
      else
        target[key] = value
      end
    end
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
        target[key] = deltas[index + 2]
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

  function registry.build(
    name,
    args,
    themeStyles,
    inlineStyles,
    stateStyles,
    invalidate,
    selectionStyles,
    selected
  )
    local adapter = registry.get(name)
    local options = {}

    local constructionStyles = themeStyles
    if selectionStyles and adapter.selectable and selected then
      constructionStyles = selectionStyles.base
    end
    applyStyles(options, adapter, constructionStyles)
    overlayArgs(options, adapter, args)
    applyStyles(options, adapter, inlineStyles)
    markStyleTargets(options, adapter, stateStyles, selectionStyles)

    applyInvalidation(options, adapter, invalidate)

    local layout = adapter.builder(options)
    local targets = collectStyleTargets(layout)
    semanticTargets[layout] = targets
    layoutAdapters[layout] = adapter
    layoutInvalidators[layout] = invalidate

    if selectionStyles and adapter.selectable then
      local protected = protectedStyleKeys(adapter, args, inlineStyles)
      local selectionState = makeSelectionState(
        layout,
        adapter,
        targets,
        selectionStyles.base,
        selectionStyles.selected,
        protected,
        selected
      )
      if selectionState then
        local baseCompiled, baseCount =
          compileStateDeltas(adapter, targets, selectionStyles.baseRuntime, protected)
        local selectedCompiled, selectedCount =
          compileStateDeltas(adapter, targets, selectionStyles.selectedRuntime, protected)
        selectionState.runtimeCompiled = { base = baseCompiled, selected = selectedCompiled }
        selectionState.runtimeCounts = { base = baseCount, selected = selectedCount }
        if selected then applySelectionState(selectionState, true) end
      end
    end

    local selectionState = selectionStates[layout]
    local protected = protectedStyleKeys(adapter, args, inlineStyles)
    local compiled
    local deltaCount
    if selectionState then
      local variant = selected and 'selected' or 'base'
      compiled = selectionState.runtimeCompiled[variant]
      deltaCount = selectionState.runtimeCounts[variant]
    elseif stateStyles then
      compiled, deltaCount = compileStateDeltas(adapter, targets, stateStyles, protected)
    end
    if compiled and deltaCount > 0 then
      local events = merge.shallowCopy(layout.events or {})
      layout.events = events
      local state = {
        active = {},
        baseState = stateStyles.baseState,
        compiled = compiled,
        invalidate = invalidate,
        adapter = adapter,
        targets = targets,
        protected = protected,
      }
      runtimeStates[layout] = state
      if selectionState then selectionState.runtime = state end

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

  function registry.patch(layout, styles)
    local adapter = layoutAdapters[layout]
    assert(adapter, 'H3 UI patch target is not an H3 component layout')
    assert(merge.isPlainTable(styles), 'H3 UI patch styles must be a plain table')
    local targets = semanticTargets[layout] or {}

    for slotName, style in next, styles do
      local mapping = adapter.slots[slotName]
      assert(
        mapping,
        ('Unknown H3 UI patch slot %q for %s'):format(slotName, adapterNames[adapter])
      )
      assert(merge.isPlainTable(style), 'H3 UI patch slot must be a plain table')
      for styleKind, values in next, style do
        assert(
          styleKind == 'props' or styleKind == 'external',
          'H3 UI patch supports props and external values only'
        )
        local marker = adapter._targetMarkers[slotName][styleKind]
        local target = targets[marker]
        assert(target, ('H3 UI patch target is unavailable: %s.%s'):format(slotName, styleKind))
        assert(merge.isPlainTable(values), 'H3 UI patch values must be a plain table')
        local function patchTarget(targetValue)
          merge.mergeInto(targetValue, values)
          local selection = selectionStates[layout]
          local runtime = runtimeStates[layout]
          if selection then
            local deltas = selection.deltas[selection.selected and 'selected' or 'base']
            for key in next, values do
              local value = constants.isUnset(values[key]) and constants.UNSET or targetValue[key]
              local present = not constants.isUnset(values[key])
              for index = 1, #deltas, 4 do
                if deltas[index] == targetValue and deltas[index + 1] == key then
                  deltas[index + 3] = present
                  deltas[index + 2] = value
                  break
                end
              end
            end
          end
          if runtime then
            for key in next, values do
              local value = constants.isUnset(values[key]) and constants.UNSET or targetValue[key]
              local present = not constants.isUnset(values[key])
              for index = 1, #runtime.active, 4 do
                if runtime.active[index] == targetValue and runtime.active[index + 1] == key then
                  runtime.active[index + 3] = present
                  runtime.active[index + 2] = value
                  break
                end
              end
            end
          end
        end
        if rawget(target, styleTargetGroupMarker) then
          for index = 1, #target do
            patchTarget(target[index])
          end
        else
          patchTarget(target)
        end
      end
    end

    local invalidate = layoutInvalidators[layout]
    if invalidate then invalidate() end
  end

  function registry.setSelected(layout, selected)
    local adapter = layoutAdapters[layout]
    assert(adapter, 'H3 UI selection target is not an H3 component layout')
    assert(
      adapter.selectable == true,
      'H3 UI component is not selectable: ' .. adapterNames[adapter]
    )
    assert(type(selected) == 'boolean', 'H3 UI selected must be boolean')
    local state = selectionStates[layout]
    if not state or state.selected == selected then return false end
    local runtime = state.runtime
    if runtime then
      applyStateDeltas(runtime.active, emptyDeltas)
      runtime.compiled = state.runtimeCompiled[selected and 'selected' or 'base']
      runtime.currentState = nil
    end
    state.selected = selected
    applySelectionState(state, selected)
    if runtime then refreshRuntimeState(runtime) end
    local invalidate = layoutInvalidators[layout]
    if invalidate then invalidate() end
    return true
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
