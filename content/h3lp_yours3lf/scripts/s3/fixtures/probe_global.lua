---@omw-context global

---Opt-in H3lp Yours3lf global fixture probe.
---Not referenced by normal H3 manifests/plugins; attach only from the example
---`h3-fixtures.omwscripts` while testing OpenMW-Lua lifecycle/event behavior.
---Persists only small primitive counters and schema version.

local async = require 'openmw.async'
local core = require 'openmw.core'
local world = require 'openmw.world'

local trace = require 'scripts.s3.fixtures.trace'

local FIXTURE = 'h3_probe_global'
local CTX = 'global'
local VERSION = 1

local seq = 0
local updateSeen = false
local initCount = 0
local loadCount = 0
local saveCount = 0
local ackCount = 0

local function emit(event, phase, fields)
    seq = seq + 1
    fields = fields or {}
    fields.fixture = FIXTURE
    fields.ctx = CTX
    fields.seq = seq
    fields.event = event
    fields.phase = phase
    trace.emit(fields)
end

emit('module', 'eval')

local function firstTimer()
    emit('timer', 'unsavable')
end

local function sendPlayerRequest(payload)
    local player = world.players and world.players[1]
    if player then
        player:sendEvent('S3FixtureRequest', payload)
        return true
    end
    return false
end

local function sendPlayerShowUi(payload)
    local player = world.players and world.players[1]
    if player then
        player:sendEvent('S3FixtureShowUi', payload)
        return true
    end
    return false
end

local function sendPlayerHideUi(payload)
    local player = world.players and world.players[1]
    if player then
        player:sendEvent('S3FixtureHideUi', payload)
        return true
    end
    return false
end

return {
    engineHandlers = {
        onInit = function(initData)
            initCount = initCount + 1
            emit('onInit', 'enter', { initCount = initCount, hasInitData = initData ~= nil })
            async:newUnsavableSimulationTimer(0, firstTimer)
            sendPlayerRequest({ from = CTX, kind = 'init-ack', seq = seq })
        end,

        onLoad = function(data)
            -- Save migration/default handling: schema v1 has only primitive counters;
            -- missing/older fields intentionally keep current defaults.
            loadCount = loadCount + 1
            if data then
                seq = tonumber(data.seq) or seq
                initCount = tonumber(data.initCount) or initCount
                saveCount = tonumber(data.saveCount) or saveCount
                ackCount = tonumber(data.ackCount) or ackCount
            end
            emit('onLoad', 'enter', { hasData = data ~= nil, loadCount = loadCount, version = data and data.version or 0 })
        end,

        onSave = function()
            saveCount = saveCount + 1
            emit('onSave', 'enter', { saveCount = saveCount })
            return {
                version = VERSION,
                seq = seq,
                initCount = initCount,
                loadCount = loadCount,
                saveCount = saveCount,
                ackCount = ackCount,
            }
        end,

        onUpdate = function()
            if updateSeen then
                return
            end
            updateSeen = true
            emit('onUpdate', 'first', { sim = core.getSimulationTime() })
        end,
    },

    eventHandlers = {
        S3FixtureAck = function(payload)
            ackCount = ackCount + 1
            emit('S3FixtureAck', 'receive', { ackCount = ackCount, from = payload and payload.from or 'unknown', kind = payload and payload.kind or 'nil' })
        end,

        S3FixturePingGlobal = function(payload)
            emit('S3FixturePingGlobal', 'receive', { from = payload and payload.from or 'unknown' })
            sendPlayerRequest({ from = CTX, kind = 'global-ping', seq = seq })
        end,

        S3FixtureShowUi = function(payload)
            emit('S3FixtureShowUi', 'relay', { target = payload and payload.target or 'player' })
            sendPlayerShowUi({ from = CTX, target = payload and payload.target or 'player' })
        end,

        S3FixtureHideUi = function(payload)
            emit('S3FixtureHideUi', 'relay', { target = payload and payload.target or 'player' })
            sendPlayerHideUi({ from = CTX, target = payload and payload.target or 'player' })
        end,
    },
}
