---@omw-context local
local interfaces = require 'openmw.interfaces'

interfaces.Combat.applyArmor({
  damage = { health = 10 },
  strength = 1,
  windUp = 0,
  successful = true,
  sourceType = 'melee'
})
local _animationControllerVersion = interfaces.AnimationController.version
local _activationVersion = interfaces.Activation.version
