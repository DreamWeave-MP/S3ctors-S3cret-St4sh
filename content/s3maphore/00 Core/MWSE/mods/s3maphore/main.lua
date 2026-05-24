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
        tes3.player.tempData['S3maphoreActivePlaylistSettings'] = tes3.player.tempData['S3maphoreActivePlaylistSettings'] or {}
        tes3.player.tempData["S3MusicPlaylistsTrackOrder"] = tes3.player.tempData["S3MusicPlaylistsTrackOrder"] or {}

        mcm.initGameSessionData()
    end
end
event.register(tes3.event.loaded, loadedCallback)