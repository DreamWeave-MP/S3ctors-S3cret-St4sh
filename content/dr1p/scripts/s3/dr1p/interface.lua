---@omw-context none

local Enum = require 'scripts.s3.dr1p.enum'

---@param runtime DR1PRuntime
---@return DR1PInterfaceDefinition
return function(runtime)
  return {
    interfaceName = 'DR1P',
    interface = {
      addRing = runtime.addRing,
      AuxSlot = Enum.AuxSlot,
      BodyType = Enum.BodyType,
      Finger = Enum.Finger,
      Hand = Enum.Hand,
      Skeleton = Enum.Skeleton,
      getSkeletonType = runtime.getSkeletonType,
      getSkeletonTypeName = runtime.getSkeletonTypeName,
    },
  }
end
