---@omw-context local

---Opt-in H3lp Yours3lf CUSTOM/local fixture probe.
---Attach manually to a non-static object while testing. It persists only small
---primitive counters and never stores object handles in save data.

local async = require 'openmw.async'
local core = require 'openmw.core'
local self = require 'openmw.self'

local trace = require 'scripts.s3.fixtures.trace'

local FIXTURE = 'h3_probe_local'
local CTX = 'local'
local VERSION = 1

local seq = 0
local updateSeen = false
local initCount = 0
local loadCount = 0
local saveCount = 0

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

local function deferredAck()
    emit('timer', 'unsavable')
    core.sendGlobalEvent('S3FixtureAck', { from = CTX, kind = 'timer', seq = seq })
end

return {
    engineHandlers = {
        onInit = function(initData)
            initCount = initCount + 1
            emit('onInit', 'enter', { initCount = initCount, hasInitData = initData ~= nil, recordId = self.object.recordId or 'nil' })
            async:newUnsavableSimulationTimer(0, deferredAck)
        end,

        onLoad = function(data)
            -- Save migration/default handling: schema v1 has only primitive counters;
            -- missing/older fields intentionally keep current defaults.
            loadCount = loadCount + 1
            if data then
                seq = tonumber(data.seq) or seq
                initCount = tonumber(data.initCount) or initCount
                saveCount = tonumber(data.saveCount) or saveCount
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
            }
        end,

        onUpdate = function()
            if updateSeen then
                return
            end
            updateSeen = true
            emit('onUpdate', 'first', { active = self.isActive(), recordId = self.object.recordId or 'nil' })
        end,
    },

    eventHandlers = {
        S3FixturePingLocal = function(payload)
            emit('S3FixturePingLocal', 'receive', { from = payload and payload.from or 'unknown' })
            core.sendGlobalEvent('S3FixtureAck', { from = CTX, kind = 'local-ping', seq = seq })
        end,
    },
}
