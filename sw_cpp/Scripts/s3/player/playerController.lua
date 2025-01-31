local ambient = require('openmw.ambient')
local core = require('openmw.core')
local self = require('openmw.self')
local ui = require('openmw.ui')

local ShowMessage = ui.showMessage
return {
  engineHandlers = {
    onTeleported = function()
      core.sendGlobalEvent('SW4_PlayerCellChanged', { player = self.object, prevCell = self.cell.name })
    end
  },
  eventHandlers = {
    SW4_AmbientEvent = function(ambientData)
      local soundFile = ambientData.soundFile
      local soundRecord = ambientData.soundRecord
      if soundFile then
        if ambient.isSoundFilePlaying(soundFile) then
          ambient.stopSoundFile(soundFile)
        end
        ambient.playSoundFile(soundFile, ambientData.options)
      elseif soundRecord then
        if ambient.isSoundPlaying(soundRecord) then
          ambient.stopSound(soundRecord)
        end
        ambient.playSound(soundRecord, ambientData.options)
      elseif not soundRecord and not soundFile then
        error("Invalid sound information provided to SW4_AmbientEvent!")
      end
    end,
    SW4_UIMessage = ShowMessage,
  }
}
