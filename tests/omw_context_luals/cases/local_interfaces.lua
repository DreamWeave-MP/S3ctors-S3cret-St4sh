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
local _aiVersion = interfaces.AI.version
local _spellCastingVersion = interfaces.SpellCasting.version
local _activationVersion = interfaces.Activation.version
local _cameraVersion = interfaces.Camera.version
local _mwuiVersion = interfaces.MWUI.version
local _uiVersion = interfaces.UI.version
local _projectilesVersion = interfaces.Projectiles.version
