---@module 'doc.playlistEnv'
---@module 'doc.s3maphoreTypes'

local OuterRimCells = {
  ['the outer rim'] = true,
  ['the outer rim, freighter'] = true,
}

---@type S3maphorePlaylist[]
return {
  {
    id = 'Rickoff/The Outer Rim',
    priority = 490,
    randomize = true,
    isValidCallback = function() return Playback.rules.cellNameExact(OuterRimCells) end,
  },
  {
    id = 'Rickoff/Club Arkngthand',
    priority = 489,
    randomize = true,

    isValidCallback = function() return Playback.state.cellId == 'nar shaddaa, club arkngthand' end,
  },
}
