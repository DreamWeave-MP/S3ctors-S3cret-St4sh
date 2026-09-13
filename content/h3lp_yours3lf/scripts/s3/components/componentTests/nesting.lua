---@omw-context player

local I = require 'openmw.interfaces'

local box = require 'scripts.s3.components.box'
local collapsible = require 'scripts.s3.components.collapsible'
local column = require 'scripts.s3.components.column'
local row = require 'scripts.s3.components.row'
local selector = require 'scripts.s3.components.selector'
local tabs = require 'scripts.s3.components.tabs'
local text = require 'scripts.s3.components.text'
local toggle = require 'scripts.s3.components.toggle'

---@return openmw.ui.Layout
local function nesting()
  local status = text { text = 'nested state untouched' }

  return column {
    name = 'ct_demo_nesting',
    children = {
      text { text = 'Nested Flex/component composition' },
      status,
      box {
        children = {
          collapsible {
            title = 'Outer collapsible',
            expanded = true,
            onToggle = I.H3ComponentTest.refresh,
            children = {
              row {
                children = {
                  toggle {
                    label = 'Outer toggle',
                    onChange = function(value)
                      status.props.text = 'outer toggle = ' .. tostring(value)
                      I.H3ComponentTest.refresh()
                    end,
                  },
                  selector {
                    items = { 'North', 'East', 'South', 'West' },
                    onSelect = function(index)
                      status.props.text = 'direction = ' .. tostring(index)
                      I.H3ComponentTest.refresh()
                    end,
                  },
                },
              },
              collapsible {
                title = 'Inner collapsible',
                expanded = true,
                onToggle = I.H3ComponentTest.refresh,
                children = {
                  tabs {
                    items = { 'Nested A', 'Nested B', 'Nested C' },
                    selected = 2,
                    onSelect = function(index)
                      status.props.text = 'inner tab = ' .. tostring(index)
                      I.H3ComponentTest.refresh()
                    end,
                  },
                  box {
                    children = {
                      column {
                        children = {
                          text { text = 'Depth 1' },
                          box {
                            children = {
                              column {
                                children = {
                                  text { text = 'Depth 2' },
                                  box {
                                    children = {
                                      text { text = 'Depth 3' },
                                    },
                                  },
                                },
                              },
                            },
                          },
                        },
                      },
                    },
                  },
                },
              },
            },
          },
        },
      },
    },
  }
end

return nesting
