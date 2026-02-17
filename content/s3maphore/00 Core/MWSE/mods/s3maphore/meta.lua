---@param fun function
---@param data table | nil
function table:subscribe(fun, data)
    local mt =
    {
        __newindex = function (t, k, v)
            rawset(self, k, v)
            fun(data)
        end
    }

    setmetatable(self, mt)
end