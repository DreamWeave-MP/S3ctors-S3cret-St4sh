---@omw-context none
---@module 'scripts.h3.runtime'

local IsLuau = _VERSION == 'Luau'

---@type H3.UserdataTypeNames
local UserdataType = IsLuau
    and {
      Color = 'openmw.util.Color',
      Spell = 'openmw.core.Spell',
      Vector2 = 'openmw.util.Vector2',
      Vector3 = 'openmw.util.Vector3',
      Vector4 = 'openmw.util.Vector4',
    }
  or {
    Color = 'Misc::Color',
    Spell = 'ESM::Spell',
    Vector2 = 'osg::Vec2f',
    Vector3 = 'osg::Vec3f',
    Vector4 = 'osg::Vec4f',
  }

---@param value userdata|H3.EngineUserdata|openmw.core.Spell
---@return string?
local function userdataTypeName(value)
  ---@diagnostic disable-next-line: undefined-global
  if IsLuau then return typeof(value) end

  local typeInfo = value.__type
  return typeInfo and typeInfo.name
end

---@type H3.Runtime
local Runtime = {
  isLuaJIT = not IsLuau,
  isLuau = IsLuau,
  userdataType = UserdataType,
  userdataTypeName = userdataTypeName,
}

return Runtime
