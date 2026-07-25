---@omw-context none

---@class T4RG3T5ModInfo
---@field name string name of the mod to use in logInfo
---@field l10nName string Name of the l10n context
---@field groupName string Name of the (player) settings group used by the mod
---@field description string
---@field version integer
---@field logPrefix string Mostly self explanatory, but generally should include a space for ease of use.
local ModInfo = {
  name = 'T4rg3t5',
  l10nName = 'S3Targets',
  groupName = 'SettingsPlayerT4rg3t5',
  description = 'T4rg3t5 is a lock-on mod with a focus on scalability via custom icons, usability, and performance.',
  version = 1,
  logPrefix = '[ T4rg3t5 ]: ',
}

return ModInfo
