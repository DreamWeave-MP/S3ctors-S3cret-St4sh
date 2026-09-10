local PlaylistConditions = require 'scripts.s3.music.playlistConditions'
local ConditionRegistry = PlaylistConditions.registry

local unpack = unpack

return function(context)
  local state, button, input, row, text, paged, rebuild =
    context.state,
    context.button,
    context.input,
    context.row,
    context.text,
    context.paged,
    context.rebuild
  local stateChoices = {
    movementMode = { 'standing', 'walking', 'running', 'sneaking', 'swimming', 'flying' },
    playlistTimeOfDay = { 'night', 'morning', 'afternoon', 'evening' },
  }

  local function replaceNode(root, path, replacement)
    if #path == 0 then return replacement end

    local parent = root
    for i = 1, #path - 1 do
      parent = parent.kind == 'not' and parent.child or parent.children[path[i]]
    end

    if parent.kind == 'not' then
      parent.child = replacement
    else
      parent.children[path[#path]] = replacement
    end

    return root
  end

  local function nodeAt(root, path)
    local node = root
    for i = 1, #path do
      node = node.kind == 'not' and node.child or node.children[path[i]]
    end
    return node
  end

  local function removeNode(root, path)
    if #path == 0 then return PlaylistConditions.all {} end

    local parent = nodeAt(root, { unpack(path, 1, #path - 1) })
    if parent.kind == 'and' or parent.kind == 'or' then
      table.remove(parent.children, path[#path])
      return root
    end

    return removeNode(root, { unpack(path, 1, #path - 1) })
  end

  local function setCondition(root) state.working.condition = PlaylistConditions.serialize(root) end

  local function splitList(value)
    local result = {}
    for item in (value or ''):gmatch '[^\r\n]+' do
      result[#result + 1] = item:gsub('^%s+', ''):gsub('%s+$', '')
    end
    return result
  end

  local function argumentText(value) return table.concat(value, '\n') end

  local function argumentLabel(kind, index)
    if kind == 'patterns' then
      return index == 1 and 'Allowed values (one per line)' or 'Disallowed values (one per line)'
    end
    if kind == 'hour' then return index == 1 and 'Start hour' or 'End hour' end
    if kind == 'nameSet' then return 'Values (one per line)' end
    if kind == 'lowerList' then return 'Patterns (one per line)' end
    return 'Values (one per line)'
  end

  local function operatorLabel(operator)
    local labels = {
      eq = 'Equals',
      ne = 'Does not equal',
      lt = 'Less than',
      le = 'At most',
      gt = 'Greater than',
      ge = 'At least',
    }
    return labels[operator]
  end

  local function defaultArgument(kind)
    if kind == 'patterns' then return { allowed = {}, disallowed = {} } end
    if kind == 'hour' then return 0 end
    return {}
  end

  local function defaultNode(spec)
    if spec.kind == 'state' then
      local value = spec.valueType == 'boolean' and false or spec.valueType == 'number' and 0 or ''
      return PlaylistConditions.state(spec.id, 'eq', value)
    end

    local args = {}
    for i = 1, #spec.arguments do
      args[i] = defaultArgument(spec.arguments[i])
    end

    return PlaylistConditions.rule(spec.id, unpack(args, 1, #args))
  end

  local function updateNode(path, update)
    local root = PlaylistConditions.deserialize(state.working.condition)
    local node = nodeAt(root, path)
    update(node)

    local ok, validated = pcall(PlaylistConditions.validate, root)
    if ok then setCondition(validated) end
  end

  local function addCondition(path)
    state.conditionPickerPath = path
    state.conditionPickerMode = 'add'
    rebuild()
  end

  local function replaceCondition(path)
    state.conditionPickerPath = path
    state.conditionPickerMode = 'replace'
    rebuild()
  end

  local function wrapNot(path)
    local root = PlaylistConditions.deserialize(state.working.condition)
    setCondition(replaceNode(root, path, PlaylistConditions.not_(nodeAt(root, path))))
    rebuild()
  end

  local function addRegistryNode(path, spec)
    local root = PlaylistConditions.deserialize(state.working.condition)
    local target = nodeAt(root, path)
    local node = defaultNode(spec)

    if state.conditionPickerMode == 'replace' then
      root = replaceNode(root, path, node)
    elseif target.kind == 'and' or target.kind == 'or' then
      target.children[#target.children + 1] = node
    else
      root = replaceNode(root, path, PlaylistConditions.all { target, node })
    end

    setCondition(root)
    state.conditionPickerPath, state.conditionPickerMode = nil, nil
    rebuild()
  end

  local function addNode(path, node)
    local root = PlaylistConditions.deserialize(state.working.condition)
    local target = nodeAt(root, path)

    if target.kind == 'and' or target.kind == 'or' then
      target.children[#target.children + 1] = node
    else
      root = replaceNode(root, path, PlaylistConditions.all { target, node })
    end

    setCondition(root)
    rebuild()
  end

  local function countConditionRows(node, rowCounts)
    local cachedCount = rowCounts[node]
    if cachedCount then return cachedCount end

    if node.kind == 'and' or node.kind == 'or' then
      local count = 2
      for i = 1, #node.children do
        count = count + countConditionRows(node.children[i], rowCounts)
      end
      rowCounts[node] = count
      return count
    end

    local count = node.kind == 'not' and 1 + countConditionRows(node.child, rowCounts) or 1
    rowCounts[node] = count
    return count
  end

  local function conditionNode(node, path, output, first, last, cursor, rowCounts)
    if node.kind == 'and' or node.kind == 'or' then
      cursor = cursor + 1
      if cursor >= first and cursor <= last then
        output[#output + 1] =
          text(string.rep('  ', #path) .. (node.kind == 'and' and 'Match ALL' or 'Match ANY'))
      end

      for i = 1, #node.children do
        local child = node.children[i]
        local childCount = rowCounts[child]
        if cursor + childCount >= first and cursor < last then
          local childPath = { unpack(path) }
          childPath[#childPath + 1] = i
          cursor = conditionNode(child, childPath, output, first, last, cursor, rowCounts)
        else
          cursor = cursor + childCount
        end
      end

      cursor = cursor + 1
      if cursor >= first and cursor <= last then
        local controls = {
          text(string.rep('  ', #path)),
          button('+ Condition', function() addCondition(path) end),
          button('+ ALL', function() addNode(path, PlaylistConditions.all {}) end),
          button('+ ANY', function() addNode(path, PlaylistConditions.any {}) end),
          button(
            '+ NOT',
            function()
              addNode(
                path,
                PlaylistConditions.not_(PlaylistConditions.state('cellIsExterior', 'eq', true))
              )
            end
          ),
        }
        if #path > 0 then
          controls[#controls + 1] = button('Remove Group', function()
            setCondition(removeNode(PlaylistConditions.deserialize(state.working.condition), path))
            rebuild()
          end)
        end
        output[#output + 1] = row(controls)
      end
      return cursor
    end

    if node.kind == 'not' then
      cursor = cursor + 1
      if cursor >= first and cursor <= last then
        output[#output + 1] = text(string.rep('  ', #path) .. 'NOT')
      end

      if cursor + rowCounts[node.child] >= first and cursor < last then
        local childPath = { unpack(path) }
        childPath[#childPath + 1] = 1
        cursor = conditionNode(node.child, childPath, output, first, last, cursor, rowCounts)
      else
        cursor = cursor + rowCounts[node.child]
      end
      return cursor
    end

    cursor = cursor + 1
    if cursor < first or cursor > last then return cursor end

    local spec = node.kind == 'rule' and ConditionRegistry.rules[node.id]
      or ConditionRegistry.states[node.id]
    local leaf = { text(string.rep('  ', #path) .. spec.label) }

    if node.kind == 'rule' then
      for i = 1, #spec.arguments do
        local kind = spec.arguments[i]

        if kind == 'patterns' then
          leaf[#leaf + 1] = text(argumentLabel(kind, i))
          leaf[#leaf + 1] = input(argumentText(node.args[i].allowed), function(value)
            updateNode(path, function(target) target.args[i].allowed = splitList(value) end)
          end)
          leaf[#leaf + 1] = text(argumentLabel(kind, i + 1))
          leaf[#leaf + 1] = input(argumentText(node.args[i].disallowed), function(value)
            updateNode(path, function(target) target.args[i].disallowed = splitList(value) end)
          end)
        elseif kind == 'hour' then
          leaf[#leaf + 1] = text(argumentLabel(kind, i))
          leaf[#leaf + 1] = input(tostring(node.args[i]), function(value)
            local number = tonumber(value)
            if number then updateNode(path, function(target) target.args[i] = number end) end
          end)
        else
          leaf[#leaf + 1] = text(argumentLabel(kind, i))
          leaf[#leaf + 1] = input(argumentText(node.args[i]), function(value)
            updateNode(path, function(target) target.args[i] = splitList(value) end)
          end)
        end
      end
    else
      local operators = spec.valueType == 'number' and { 'eq', 'ne', 'lt', 'le', 'gt', 'ge' }
        or { 'eq', 'ne' }
      leaf[#leaf + 1] = button('Comparison: ' .. operatorLabel(node.op), function()
        local nextOperator = 1
        for i = 1, #operators do
          if operators[i] == node.op then nextOperator = i % #operators + 1 end
        end
        updateNode(path, function(target) target.op = operators[nextOperator] end)
      end)

      local choices = stateChoices[node.id]
      if spec.valueType == 'boolean' then
        leaf[#leaf + 1] = button('Value: ' .. tostring(node.value), function()
          updateNode(path, function(target) target.value = not target.value end)
        end)
      elseif choices then
        leaf[#leaf + 1] = button('Value: ' .. tostring(node.value), function()
          local nextValue = 1
          for i = 1, #choices do
            if choices[i] == node.value then nextValue = i % #choices + 1 end
          end
          updateNode(path, function(target) target.value = choices[nextValue] end)
        end)
      else
        leaf[#leaf + 1] = input(tostring(node.value), function(value)
          local parsed = spec.valueType == 'number' and tonumber(value) or value
          if spec.valueType == 'number' and not parsed then return end
          updateNode(path, function(target) target.value = parsed end)
        end)
      end
    end

    leaf[#leaf + 1] = button('Replace', function() replaceCondition(path) end)
    leaf[#leaf + 1] = button('NOT', function() wrapNot(path) end)
    leaf[#leaf + 1] = button('Remove', function()
      setCondition(removeNode(PlaylistConditions.deserialize(state.working.condition), path))
      rebuild()
    end)
    output[#output + 1] = row(leaf)
    return cursor
  end

  local function pickerLayout()
    local output = {
      text 'Add condition',
      button('Cancel', function()
        state.conditionPickerPath = nil
        state.conditionPickerMode = nil
        state.pickerPage = 0
        rebuild()
      end),
    }
    local page = paged(#ConditionRegistry.ordered, state.pickerPage, function(first, last)
      local items = {}
      for i = first, last do
        local spec = ConditionRegistry.ordered[i]
        items[#items + 1] = button(
          spec.category .. ': ' .. spec.label,
          function() addRegistryNode(state.conditionPickerPath, spec) end
        )
      end
      return items
    end, function(value) state.pickerPage = value end)
    for i = 1, #page do
      output[#output + 1] = page[i]
    end
    return output
  end

  local function replaceCustomCondition()
    state.working.condition = PlaylistConditions.serialize(PlaylistConditions.all {})
    rebuild()
  end

  local function restoreSourceCondition()
    state.working.condition = nil
    rebuild()
  end

  local function layout()
    if state.conditionPickerPath then return pickerLayout() end

    if not state.working.condition then
      local output = {
        text 'This playlist uses a custom Lua condition.',
        text 'Replace it with a graphical condition to edit it here.',
      }

      if context.Catalog.source(state.selectedId) then
        output[#output + 1] = button('Replace Condition', replaceCustomCondition)
      end

      return output
    end

    local condition = PlaylistConditions.deserialize(state.working.condition)
    local rowCounts = {}
    local totalConditionRows = countConditionRows(condition, rowCounts)
    local page = paged(totalConditionRows, state.conditionPage, function(first, last)
      local output = {}
      conditionNode(condition, {}, output, first, last, 0, rowCounts)
      return output
    end, function(value) state.conditionPage = value end)
    if context.Catalog.source(state.selectedId) then
      page[#page + 1] = button('Restore source condition', restoreSourceCondition)
    end

    return page
  end

  return { layout = layout }
end
