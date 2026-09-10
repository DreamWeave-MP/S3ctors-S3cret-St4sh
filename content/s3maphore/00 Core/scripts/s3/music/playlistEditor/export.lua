return function(context)
  local state, exportInput, button, rebuild =
    context.state, context.exportInput, context.button, context.rebuild

  local function layout()
    return {
      context.text 'Exported playlist Lua',
      exportInput(state.exportText or '', function(value) state.exportText = value or '' end),
      button('Close Export', function()
        state.exportText = nil
        rebuild()
      end),
    }
  end

  return { layout = layout }
end
