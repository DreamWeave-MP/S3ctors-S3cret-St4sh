return function(context)
  local state, Catalog = context.state, context.Catalog
  local button, input, row, text, rebuild =
    context.button, context.input, context.row, context.text, context.rebuild
  local interruptLabels = { [0] = 'Me', [1] = 'Other', [2] = 'Never', [3] = 'Override' }

  local function layout()
    local properties = state.working.properties
    local output = {
      text 'Properties',
      text('ID: ' .. state.selectedId),
      text 'Activation is runtime-only.',
    }
    local source = Catalog.source(state.selectedId)

    local function numberProperty(key, label)
      output[#output + 1] = row {
        text(label .. ': '),
        input(tostring(properties[key] or ''), function(value)
          local number = tonumber(value)
          if not number or number ~= number or math.abs(number) == math.huge then return end
          if key == 'priority' and number > 1000 then return end
          if
            key == 'priority'
            and source
            and Catalog.category(number) ~= Catalog.category(source.playlist.priority)
          then
            return
          end
          if key == 'interruptMode' and (number < 0 or number > 3 or number % 1 ~= 0) then
            return
          end
          if key == 'fadeOut' and number < 0 then return end
          properties[key] = number
        end),
      }
    end

    numberProperty('priority', 'Priority')
    if source then
      output[#output + 1] = text('Category: ' .. Catalog.category(source.playlist.priority))
    end

    output[#output + 1] = button(
      'Interrupt: ' .. (interruptLabels[properties.interruptMode] or 'Invalid'),
      function()
        properties.interruptMode = ((properties.interruptMode or 0) + 1) % 4
        rebuild()
      end
    )
    numberProperty('fadeOut', 'Fade out seconds')

    local booleanProperties = {
      { key = 'randomize', label = 'Randomize track order' },
      { key = 'cycleTracks', label = 'Cycle tracks' },
      { key = 'playOneTrack', label = 'Play one track' },
      { key = 'deactivateAfterEnd', label = 'Deactivate after track ends' },
    }
    for i = 1, #booleanProperties do
      local property = booleanProperties[i]
      output[#output + 1] = button(
        property.label .. ': ' .. tostring(properties[property.key]),
        function()
          properties[property.key] = not properties[property.key]
          rebuild()
        end
      )
    end

    return output
  end

  return { layout = layout }
end
