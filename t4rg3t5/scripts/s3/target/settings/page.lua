local input = require 'openmw.input'

local I = require 'openmw.interfaces'
local ModInfo = require 'scripts.s3.target.modInfo'

I.Settings.registerPage {
    key = ModInfo.name,
    l10n = ModInfo.l10nName,
    name = 'TargetLockPageName',
    description = 'TargetLockPageDescription',
}

input.registerAction {
    key = 'S3TargetLock',
    type = input.ACTION_TYPE.Boolean,
    l10n = ModInfo.l10nName,
    name = 'TargetLockActionName',
    description = 'TargetLockActionDesc',
    -- name = 'Target Lock Toggle',
    -- description = 'Manually engages target locking',
    defaultValue = false,
}
