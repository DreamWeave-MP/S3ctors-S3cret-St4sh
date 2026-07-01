---@omw-context local | player

local TaggerInterface = require 'Scripts.S3.ModTags.interface'
TaggerInterface.ingestTag = nil
TaggerInterface.removeTagFromMemory = nil
TaggerInterface._isLoadingComplete = nil
TaggerInterface.markLoadingComplete = nil
TaggerInterface.syncToStorage = nil

return {
	interfaceName = 'TaggerL',
	interface = TaggerInterface,
}
