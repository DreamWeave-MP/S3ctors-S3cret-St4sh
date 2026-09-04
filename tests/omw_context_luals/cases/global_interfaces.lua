---@omw-context global
local interfaces = require 'openmw.interfaces'

interfaces.Combat.adjustDamageForArmor(10)
local _activationVersion = interfaces.Activation.version
local _animationControllerVersion = interfaces.AnimationController.version
