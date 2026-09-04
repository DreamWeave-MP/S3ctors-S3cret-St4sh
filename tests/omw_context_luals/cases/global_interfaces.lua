---@omw-context global
local interfaces = require 'openmw.interfaces'

interfaces.Combat.adjustDamageForArmor(10)
local _activationVersion = interfaces.Activation.version
local _settingsVersion = interfaces.Settings.version
local _itemUsageVersion = interfaces.ItemUsage.version
local _crimesVersion = interfaces.Crimes.version
local _projectilesVersion = interfaces.Projectiles.version
local _spellCastingVersion = interfaces.SpellCasting.version
local _animationControllerVersion = interfaces.AnimationController.version
local _aiVersion = interfaces.AI.version
local _cameraVersion = interfaces.Camera.version
local _mwuiVersion = interfaces.MWUI.version
local _uiVersion = interfaces.UI.version
local _skillProgressionVersion = interfaces.SkillProgression.version
local _controlsVersion = interfaces.Controls.version
local _gamepadControlsVersion = interfaces.GamepadControls.version
local _directCameraVersion = require('openmw.interfaces').Camera.version
