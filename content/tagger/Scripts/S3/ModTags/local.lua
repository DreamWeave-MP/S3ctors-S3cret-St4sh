---@omw-context local | player

local FlexTagInterface = require 'Scripts.S3.ModTags.interface'
FlexTagInterface.ingestTag = nil
FlexTagInterface.removeTagFromMemory = nil
FlexTagInterface._isLoadingComplete = nil
FlexTagInterface.markLoadingComplete = nil
FlexTagInterface.syncToStorage = nil

return {
	interfaceName = 'FlexTagL',
	interface = FlexTagInterface,
}
