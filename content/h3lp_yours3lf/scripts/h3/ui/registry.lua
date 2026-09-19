---@omw-context menu|player
---@module 'scripts.h3.ui.registry'

local async = require 'openmw.async'
local constants = require 'scripts.h3.ui.constants'
local merge = require 'scripts.h3.ui.merge'
local mutation = require 'scripts.h3.ui.mutation'

local Assert, Error, Next, RawGet, RawSet, SetMetatable, StrFormat, TableSort, ToString, Type =
  assert, error, next, rawget, rawset, setmetatable, string.format, table.sort, tostring, type

local StyleTargetMarker, StyleTargetGroupMarker, EmptyDeltas = {}, {}, {}
local WeakKeys = { __mode = 'k' }

---@param definitions H3UI.ComponentDefinitions
---@return H3UI.Registry
local function new(definitions)
  local adapters, adapterNames = {}, {}

  for name, definition in Next, definitions do
    Assert(Type(name) == 'string' and name ~= '', 'H3 UI component name must be a string')

    Assert(Type(definition) == 'table', 'H3 UI component adapter must be a table')

    if Type(definition.builder) ~= 'function' then
      Error(StrFormat('H3 UI component adapter requires builder: %s', name))
    end

    if Type(definition.slots) ~= 'table' or not definition.slots.root then
      Error(StrFormat('H3 UI component adapter requires root slot: %s', name))
    end

    local styledOptions, targetMarkers, targetOptions = {}, {}, {}

    for slotName, mapping in Next, definition.slots do
      local slotMarkers = {}
      targetMarkers[slotName] = slotMarkers

      for styleKind, optionKey in Next, mapping do
        if styleKind ~= 'retained' then styledOptions[optionKey] = true end

        if styleKind == 'props' or styleKind == 'external' then
          local previous = targetOptions[optionKey]

          if previous then
            Error(
              StrFormat(
                'H3 UI runtime style target %q is shared by %s.%s and %s.%s',
                optionKey,
                previous.slot,
                previous.kind,
                slotName,
                styleKind
              )
            )
          end

          local marker = {
            kind = styleKind,
            option = optionKey,
            slot = slotName,
          }

          slotMarkers[styleKind] = marker
          targetOptions[optionKey] = marker
        end
      end
    end

    definition._styledOptions = styledOptions
    definition._targetMarkers = targetMarkers

    adapters[name] = definition
    adapterNames[definition] = name
  end

  local registry = {}
  local runtimeStates = SetMetatable({}, WeakKeys)
  local semanticTargets = SetMetatable({}, WeakKeys)
  local layoutAdapters = SetMetatable({}, WeakKeys)
  local layoutInvalidators = SetMetatable({}, WeakKeys)
  local selectionStates = SetMetatable({}, WeakKeys)

  ---@param name string
  ---@return H3UI.ComponentAdapter
  function registry.get(name)
    local adapter = adapters[name]
    if not adapter then Error(StrFormat('Unknown H3 UI component: %s', ToString(name))) end
    return adapter
  end

  ---@param name string
  ---@return boolean
  function registry.has(name) return adapters[name] ~= nil end

  ---@param name string
  ---@return boolean
  function registry.supportsRuntimeState(name) return registry.get(name).runtimeState == true end

  ---@param name string
  ---@return boolean
  function registry.supportsSelection(name) return registry.get(name).selectable == true end

  ---@return string[]
  function registry.publicComponents()
    local result = {}

    for name, adapter in Next, adapters do
      if adapter.isPublic then result[#result + 1] = name end
    end

    TableSort(result)

    return result
  end

  ---@param name string
  ---@param slot string
  ---@return boolean
  function registry.validateSlot(name, slot)
    local adapter = registry.get(name)

    if not adapter.slots[slot] then
      Error(StrFormat('Unknown H3 UI style slot %q for component %q', ToString(slot), name))
    end

    return true
  end

  ---@param options table
  ---@param adapter H3UI.ComponentAdapter
  ---@param slotName string
  ---@param style H3UI.Style
  ---@return nil
  local function applySlot(options, adapter, slotName, style)
    local mapping = adapter.slots[slotName]

    if not mapping then
      Error(
        StrFormat('Unknown H3 UI style slot %q for component %q', slotName, adapterNames[adapter])
      )
    end

    Assert(merge.isPlainTable(style), 'H3 UI style slot must be a plain table')

    for styleKey, value in Next, style do
      local optionKey = mapping[styleKey]
      if not optionKey then
        Error(
          StrFormat(
            'Unsupported H3 UI style key %q on %s.%s',
            ToString(styleKey),
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

  ---@param options table
  ---@param adapter H3UI.ComponentAdapter
  ---@param styles? H3UI.StyleMap
  ---@return nil
  local function applyStyles(options, adapter, styles)
    if not styles then return end

    for slotName, style in Next, styles do
      applySlot(options, adapter, slotName, style)
    end
  end

  ---@param options table
  ---@param adapter H3UI.ComponentAdapter
  ---@param slotName string
  ---@param styleKind 'props'|'external'
  ---@param context string
  ---@return table target
  ---@return H3UI.StyleTargetMarker marker
  local function ensureStyleTarget(options, adapter, slotName, styleKind, context)
    local mapping = adapter.slots[slotName]
    if not mapping then
      Error(
        StrFormat('Unknown H3 UI style slot %q for component %q', slotName, adapterNames[adapter])
      )
    end

    local optionKey = mapping[styleKind]
    if not optionKey then
      Error(
        StrFormat(
          'Unsupported H3 UI style key %q on %s.%s',
          ToString(styleKind),
          adapterNames[adapter],
          slotName
        )
      )
    end

    local target = options[optionKey]
    if not target then
      target = {}
      options[optionKey] = target
    end

    if not merge.isPlainTable(target) then
      Error(StrFormat('H3 UI %s target must be a plain table: %s', context, optionKey))
    end

    return target, adapter._targetMarkers[slotName][styleKind]
  end

  ---@param options table
  ---@param adapter H3UI.ComponentAdapter
  ---@param stateStyles? H3UI.RuntimeStyleSet
  ---@param selectionStyles? H3UI.SelectionStyles
  ---@return nil
  local function markStyleTargets(options, adapter, stateStyles, selectionStyles)
    for state, styles in Next, stateStyles or EmptyDeltas do
      if state ~= 'baseState' then
        for slotName, style in Next, styles do
          for styleKind in Next, style do
            Assert(
              styleKind == 'props' or styleKind == 'external',
              'H3 UI runtime state styles support props and external values only'
            )

            local target, marker =
              ensureStyleTarget(options, adapter, slotName, styleKind, 'runtime state')
            RawSet(target, StyleTargetMarker, marker)
          end
        end
      end
    end

    ---@param styles? H3UI.StyleMap
    ---@return nil
    local function markSelectionStyles(styles)
      if not styles then return end

      for slotName, style in Next, styles do
        for styleKind in Next, style do
          Assert(
            styleKind == 'props' or styleKind == 'external',
            'H3 UI selected styles support props and external values only'
          )

          local target, marker =
            ensureStyleTarget(options, adapter, slotName, styleKind, 'selection')
          RawSet(target, StyleTargetMarker, marker)
        end
      end
    end

    if selectionStyles then
      markSelectionStyles(selectionStyles.base)
      markSelectionStyles(selectionStyles.selected)
    end

    for slotName, mapping in Next, adapter.slots do
      for styleKind in Next, mapping do
        if styleKind == 'props' or styleKind == 'external' then
          local optionKey = mapping[styleKind]
          if
            options[optionKey] ~= nil
            or slotName == 'root' and styleKind == 'props'
            or mapping.retained == true and styleKind == 'props'
          then
            local target, marker =
              ensureStyleTarget(options, adapter, slotName, styleKind, 'semantic')
            RawSet(target, StyleTargetMarker, marker)
          end
        end
      end
    end
  end

  ---@param layout openmw.ui.Layout
  ---@return table<H3UI.StyleTargetMarker, table>
  local function collectStyleTargets(layout)
    local targets = {}
    local seen = {}

    ---@param value? table
    ---@return nil
    local function collect(value)
      if Type(value) ~= 'table' or seen[value] then return end

      seen[value] = true
      local marker = RawGet(value, StyleTargetMarker)
      if not marker then return end

      RawSet(value, StyleTargetMarker, nil)

      local target = targets[marker]
      if not target then
        targets[marker] = value
      elseif RawGet(target, StyleTargetGroupMarker) then
        target[#target + 1] = value
      else
        targets[marker] = {
          [StyleTargetGroupMarker] = true,
          target,
          value,
        }
      end
    end

    ---@param layoutValue? table
    ---@return nil
    local function visit(layoutValue)
      if Type(layoutValue) ~= 'table' then return end
      collect(layoutValue.props)
      collect(layoutValue.external)

      local content = layoutValue.content
      if content then
        for index = 1, #content do
          visit(content[index])
        end
      end

      if layoutValue.template then visit(layoutValue.template) end
    end

    visit(layout)

    return targets
  end

  ---@param adapter H3UI.ComponentAdapter
  ---@param args? table
  ---@param inlineStyles? H3UI.StyleMap
  ---@return H3UI.StyleProtection?
  local function protectedStyleKeys(adapter, args, inlineStyles)
    local protected

    ---@param source? table
    ---@return nil
    local function add(source)
      if not source then return end
      for slotName, mapping in Next, adapter.slots do
        for styleKind, optionKey in Next, mapping do
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
              if not keys then
                keys = merge.isPlainTable(value) and {} or true
                slot[styleKind] = keys
              end

              if keys ~= true then
                for key in Next, value do
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
      for slotName, style in Next, inlineStyles do
        protected = protected or {}

        local slot = protected[slotName]
        if not slot then
          slot = {}
          protected[slotName] = slot
        end

        for styleKind, values in Next, style do
          if styleKind == 'props' or styleKind == 'external' then
            local keys = slot[styleKind]

            if not keys then
              keys = {}
              slot[styleKind] = keys
            end

            if keys ~= true then
              for key in Next, values do
                keys[key] = true
              end
            end
          end
        end
      end
    end

    return protected
  end

  ---@param deltas H3UI.StateDeltaList
  ---@param target table
  ---@param key string
  ---@param value H3UI.LuaValue
  ---@return integer
  local function appendStateDelta(deltas, target, key, value)
    if RawGet(target, StyleTargetGroupMarker) then
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

  ---@param adapter H3UI.ComponentAdapter
  ---@param targets table<H3UI.StyleTargetMarker, table>
  ---@param stateStyles? H3UI.RuntimeStyleSet
  ---@param protected? H3UI.StyleProtection
  ---@return H3UI.CompiledRuntimeStyles compiled
  ---@return integer count
  local function compileStateDeltas(adapter, targets, stateStyles, protected)
    if not stateStyles then return EmptyDeltas, 0 end

    local compiled = {}
    local count = 0

    for state, styles in Next, stateStyles do
      if state ~= 'baseState' then
        local stateDeltas = {}

        for slotName, style in Next, styles do
          local slotProtection = protected and protected[slotName]
          local markers = adapter._targetMarkers[slotName]

          for styleKind, values in Next, style do
            if styleKind == 'props' or styleKind == 'external' then
              local keys = slotProtection and slotProtection[styleKind]

              if keys ~= true then
                local target = targets[markers[styleKind]]

                if target then
                  for key, value in Next, values do
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

  ---@param adapter H3UI.ComponentAdapter
  ---@param targets table<H3UI.StyleTargetMarker, table>
  ---@param styles H3UI.StyleMap
  ---@param protected? H3UI.StyleProtection
  ---@return H3UI.StateDeltaList
  local function compileStyleDeltas(adapter, targets, styles, protected)
    local deltas = {}

    for slotName, style in Next, styles do
      local slotProtection = protected and protected[slotName]
      local markers = adapter._targetMarkers[slotName]

      for styleKind, values in Next, style do
        if styleKind == 'props' or styleKind == 'external' then
          local keys = slotProtection and slotProtection[styleKind]

          if keys ~= true then
            local target = targets[markers[styleKind]]

            if target then
              for key, value in Next, values do
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

  ---@param values H3UI.SelectionValueMap
  ---@param deltas H3UI.StateDeltaList
  ---@return nil
  local function addSelectionValues(values, deltas)
    for index = 1, #deltas, 3 do
      local target = deltas[index]
      local key = deltas[index + 1]

      local targetValues = values[target]
      if not targetValues then
        targetValues = {}
        values[target] = targetValues
      end

      targetValues[key] = deltas[index + 2]
    end
  end

  ---@param deltas H3UI.SelectionDeltaList
  ---@param target table
  ---@param key string
  ---@param value H3UI.LuaValue
  ---@param present boolean
  ---@return nil
  local function appendSelectionDelta(deltas, target, key, value, present)
    local offset = #deltas
    deltas[offset + 1] = target
    deltas[offset + 2] = key
    deltas[offset + 3] = value
    deltas[offset + 4] = present
  end

  ---@param baseValues H3UI.SelectionValueMap
  ---@param selectedValues H3UI.SelectionValueMap
  ---@return H3UI.SelectionDeltaList baseDeltas
  ---@return H3UI.SelectionDeltaList selectedDeltas
  local function makeSelectionDeltas(baseValues, selectedValues)
    local baseDeltas = {}
    local selectedDeltas = {}
    local seen = {}

    ---@param values H3UI.SelectionValueMap
    ---@return nil
    local function addKeys(values)
      for target, targetValues in Next, values do
        local targetKeys = seen[target]

        if not targetKeys then
          targetKeys = {}
          seen[target] = targetKeys
        end

        for key in Next, targetValues do
          targetKeys[key] = true
        end
      end
    end

    addKeys(baseValues)
    addKeys(selectedValues)

    for target, targetKeys in Next, seen do
      for key in Next, targetKeys do
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

  ---@param layout openmw.ui.Layout
  ---@param adapter H3UI.ComponentAdapter
  ---@param targets table<H3UI.StyleTargetMarker, table>
  ---@param baseStyles H3UI.StyleMap
  ---@param selectedStyles H3UI.StyleMap
  ---@param protected? H3UI.StyleProtection
  ---@param selected boolean
  ---@return H3UI.SelectionState?
  local function makeSelectionState(
    layout,
    adapter,
    targets,
    baseStyles,
    selectedStyles,
    protected,
    selected
  )
    local baseValues, selectedValues = {}, {}

    addSelectionValues(baseValues, compileStyleDeltas(adapter, targets, baseStyles, protected))
    addSelectionValues(
      selectedValues,
      compileStyleDeltas(adapter, targets, selectedStyles, protected)
    )

    local baseDeltas, selectedDeltas = makeSelectionDeltas(baseValues, selectedValues)
    if not Next(baseDeltas) then return end

    local state = {
      deltas = { base = baseDeltas, selected = selectedDeltas },
      selected = selected == true,
    }

    selectionStates[layout] = state

    return state
  end

  ---@param state H3UI.SelectionState
  ---@param selected boolean
  ---@return nil
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

  ---@param active H3UI.SelectionDeltaList
  ---@param deltas H3UI.StateDeltaList
  ---@return nil
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

  ---@param options table
  ---@param adapter H3UI.ComponentAdapter
  ---@param args? table
  ---@return nil
  local function overlayArgs(options, adapter, args)
    if not args then return end

    for key, value in Next, args do
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

  ---@param options table
  ---@param adapter H3UI.ComponentAdapter
  ---@param invalidate? fun(): nil
  ---@return nil
  local function applyInvalidation(options, adapter, invalidate)
    if not invalidate then return end

    local callbacks = adapter.invalidateOn
    if not callbacks then return end
    if Type(callbacks) == 'string' then
      options[callbacks] = mutation.invalidateAfter(options[callbacks], invalidate)
      return
    end

    for index = 1, #callbacks do
      local name = callbacks[index] or Error('H3 UI invalidation callback name is missing')
      options[name] = mutation.invalidateAfter(options[name], invalidate)
    end
  end

  ---@param state H3UI.RuntimeState
  ---@return boolean
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
    applyStateDeltas(state.active, state.compiled[nextState] or EmptyDeltas)

    return true
  end

  ---@param state H3UI.RuntimeState
  ---@param previous? H3UI.RuntimeEventHandler
  ---@param event? openmw.ui.MouseEvent
  ---@param eventLayout openmw.ui.Layout
  ---@return boolean?
  local function finishRuntimeStateEvent(state, previous, event, eventLayout)
    local changed, result = refreshRuntimeState(state), nil

    if previous then result = previous(event, eventLayout) end
    if changed and state.invalidate then state.invalidate() end

    return result
  end

  ---@param event? openmw.ui.MouseEvent
  ---@param eventLayout openmw.ui.Layout
  ---@return boolean?
  local function onFocusGain(event, eventLayout)
    local state = runtimeStates[eventLayout]
    if not state then return end

    state.focused = true

    return finishRuntimeStateEvent(state, state.focusGain, event, eventLayout)
  end

  ---@param event? openmw.ui.MouseEvent
  ---@param eventLayout openmw.ui.Layout
  ---@return boolean?
  local function onFocusLoss(event, eventLayout)
    local state = runtimeStates[eventLayout]
    if not state then return end

    state.focused, state.pressed = nil, nil

    return finishRuntimeStateEvent(state, state.focusLoss, event, eventLayout)
  end

  ---@param event? openmw.ui.MouseEvent
  ---@param eventLayout openmw.ui.Layout
  ---@return boolean?
  local function onMousePress(event, eventLayout)
    local state = runtimeStates[eventLayout]
    if not state then return end

    if event and event.button == 1 then state.pressed = true end

    return finishRuntimeStateEvent(state, state.mousePress, event, eventLayout)
  end

  ---@param event? openmw.ui.MouseEvent
  ---@param eventLayout openmw.ui.Layout
  ---@return boolean?
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

  ---@param state H3UI.RuntimeState
  ---@param events table<string, H3UI.RuntimeEventHandler|openmw.async.Callback>
  ---@param name 'focusGain'|'focusLoss'|'mousePress'|'mouseRelease'
  ---@return nil
  local function installStateHandler(state, events, name)
    state[name] = events[name]
    events[name] = stateHandlers[name]
  end

  ---@param name string
  ---@param args table
  ---@param themeStyles H3UI.StyleMap
  ---@param inlineStyles? H3UI.StyleMap
  ---@param stateStyles? H3UI.RuntimeStyleSet
  ---@param invalidate? fun(): nil
  ---@param selectionStyles? H3UI.SelectionStyles
  ---@param selected? boolean
  ---@return openmw.ui.Layout
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

    local protected = protectedStyleKeys(adapter, args, inlineStyles)
    local selectionState
    if selectionStyles and adapter.selectable then
      selectionState = makeSelectionState(
        layout,
        adapter,
        targets,
        selectionStyles.base,
        selectionStyles.selected,
        protected,
        selected == true
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

    local compiled, deltaCount
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
        baseState = stateStyles and stateStyles.baseState,
        compiled = compiled,
        invalidate = invalidate,
        adapter = adapter,
        targets = targets,
        protected = protected,
      }

      runtimeStates[layout] = state
      if selectionState then selectionState.runtime = state end

      if compiled.hover then installStateHandler(state, events, 'focusGain') end
      if compiled.hover or compiled.pressed then installStateHandler(state, events, 'focusLoss') end

      if compiled.pressed then
        installStateHandler(state, events, 'mousePress')
        installStateHandler(state, events, 'mouseRelease')
      end

      refreshRuntimeState(state)
    end

    return layout
  end

  ---@param layout openmw.ui.Layout
  ---@param styles table<string, H3UI.Style>
  ---@return nil
  function registry.patch(layout, styles)
    local adapter = layoutAdapters[layout]

    Assert(adapter, 'H3 UI patch target is not an H3 component layout')
    Assert(merge.isPlainTable(styles), 'H3 UI patch styles must be a plain table')

    local targets = semanticTargets[layout] or {}

    for slotName, style in Next, styles do
      local mapping = adapter.slots[slotName]

      Assert(
        mapping,
        StrFormat('Unknown H3 UI patch slot %q for %s', slotName, adapterNames[adapter])
      )
      Assert(merge.isPlainTable(style), 'H3 UI patch slot must be a plain table')

      for styleKind, values in Next, style do
        Assert(
          styleKind == 'props' or styleKind == 'external',
          'H3 UI patch supports props and external values only'
        )

        local marker = adapter._targetMarkers[slotName][styleKind]
        local target = targets[marker]

        if not target then
          Error(StrFormat('H3 UI patch target is unavailable: %s.%s', slotName, styleKind))
        end
        Assert(merge.isPlainTable(values), 'H3 UI patch values must be a plain table')
        ---@param targetValue table
        ---@return nil
        local function patchTarget(targetValue)
          merge.mergeInto(targetValue, values)
          local runtime, selection = runtimeStates[layout], selectionStates[layout]

          if selection then
            local deltas = selection.deltas[selection.selected and 'selected' or 'base']

            for key in Next, values do
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
            for key in Next, values do
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

        if RawGet(target, StyleTargetGroupMarker) then
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

  ---@param layout openmw.ui.Layout
  ---@param selected boolean
  ---@return boolean
  function registry.setSelected(layout, selected)
    local adapter = layoutAdapters[layout]

    Assert(adapter, 'H3 UI selection target is not an H3 component layout')
    if adapter.selectable ~= true then
      Error(StrFormat('H3 UI component is not selectable: %s', adapterNames[adapter]))
    end
    Assert(Type(selected) == 'boolean', 'H3 UI selected must be boolean')

    local state = selectionStates[layout]
    if not state or state.selected == selected then return false end
    local runtime = state.runtime

    if runtime then
      applyStateDeltas(runtime.active, EmptyDeltas)
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

  ---@param name string
  ---@return string[]
  function registry.slots(name)
    local adapter = registry.get(name)

    local result = {}
    for slot in Next, adapter.slots do
      result[#result + 1] = slot
    end

    TableSort(result)

    return result
  end

  return registry
end

return new
