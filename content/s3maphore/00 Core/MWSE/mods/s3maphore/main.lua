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

        local core = require("scripts.s3.music.core")
        local staticCollection = require("scripts.s3.music.staticCollection")
        local actor = require("scripts.omw.music.actor")

        --- Register MWSE events
        event.register(tes3.event.journal, core.engineHandlers.onQuestUpdate)
        event.register(tes3.event.simulate, core.engineHandlers.onUpdate)
        event.register(tes3.event.save, core.engineHandlers.onSave)
        event.register(tes3.event.loaded, core.engineHandlers.onLoad)

        event.register(tes3.event.damaged, core.eventHandlers.Died)

        event.register(tes3.event.key, core.mwse.keyCallback)

        event.register(tes3.event.simulate, staticCollection.mwse.onUpdate)
        event.register(tes3.event.cellChanged, staticCollection.mwse.cellChanged)

        event.register(tes3.event.referenceDeactivated, actor.engineHandlers.onInactive)

        event.register(tes3.event.damage, actor.mwse.onDamage)
        event.register(tes3.event.damaged, actor.mwse.onDeath)
        event.register(tes3.event.combatStarted, actor.mwse.combatStarted)
        event.register(tes3.event.combatStopped, actor.mwse.combatStopped)

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
        
        event.register("S3maphoreCombatStarted", core.mwse.combatStarted)
        event.register("S3maphoreCombatStopped", core.mwse.combatStopped)
    end
end
event.register(tes3.event.loaded, loadedCallback)