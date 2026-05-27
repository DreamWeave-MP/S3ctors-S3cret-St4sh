-- mwse.memory.writeNoOperation{address = 0x4BB666, length = 18}
package.path = package.path .. ";.\\Data Files\\?.lua;"

require("s3maphore.meta")
local mcm = require("s3maphore.mcm")

--- This path was changed in current builds, but also
--- The util module returns a local variable which should be bound to a variable in the scope in which it's require'd
--- There is no way this works like you're expecting it to
-- require("scripts.s3.music.util")

--- @param e loadedEventData
local function loadedCallback(e)
    if (tes3.player) then
        tes3.player.tempData["S3maphoreActivePlaylistSettings"] = tes3.player.tempData["S3maphoreActivePlaylistSettings"] or {}
        tes3.player.tempData["S3MusicPlaylistsTrackOrder"] = tes3.player.tempData["S3MusicPlaylistsTrackOrder"] or {}

        mcm.initGameSessionData()

        --- Register MWSE events
        local core = require("scripts.s3.music.core")
        event.register(tes3.event.journal, core.engineHandlers.onQuestUpdate)
        event.register(tes3.event.simulate, core.engineHandlers.onUpdate)
        event.register(tes3.event.saved, core.engineHandlers.onSave)
        event.register(tes3.event.loaded, core.engineHandlers.onLoad)

        event.register(tes3.event.damaged, core.eventHandlers.Died)

        event.register(tes3.event.key, core.mwse.keyCallback)
        event.register(tes3.event.combatStarted, core.mwse.combatStarted)
        event.register(tes3.event.combatStopped, core.mwse.combatStopped)

        local staticCollection = require("scripts.s3.music.staticCollection")
        event.register(tes3.event.weatherCycled, staticCollection.mwse.weatherChanged)
        event.register(tes3.event.cellChanged, staticCollection.mwse.cellChanged)

        --- Register S3maphore events

        event.register("S3maphoreToggleMusic", core.eventHandlers.S3maphoreToggleMusic)
        event.register("S3maphoreSkipTrack", core.eventHandlers.S3maphoreSkipTrack)
        event.register("S3maphoreSpecialTrack", core.eventHandlers.S3maphoreSpecialTrack)
        event.register("S3maphoreSetPlaylistActive", core.eventHandlers.S3maphoreSetPlaylistActive)
        event.register("S3maphoreMusicStopped", core.eventHandlers.S3maphoreMusicStopped)
        event.register("S3maphoreCombatTargetsUpdated", core.eventHandlers.S3maphoreCombatTargetsUpdated)
        event.register("S3maphoreCellChanged", core.eventHandlers.S3maphoreCellChanged)
        event.register("S3maphoreWeatherChanged", core.eventHandlers.S3maphoreWeatherChanged)
        event.register("S3maphoreClearTargetCache", core.eventHandlers.S3maphoreClearTargetCache)
    end
end
event.register(tes3.event.loaded, loadedCallback)