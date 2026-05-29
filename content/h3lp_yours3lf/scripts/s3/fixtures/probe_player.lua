---@omw-context player

---Opt-in H3lp Yours3lf player fixture probe.
---Creates UI only after explicit `S3FixtureShowUi` events and destroys owned UI on
---hide/load/recreate. Inventory probing is read-only; mutation requests are traced
---as blocked unless a future test harness deliberately implements them.

local async = require 'openmw.async'
local core = require 'openmw.core'
local self = require 'openmw.self'
local types = require 'openmw.types'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local trace = require 'scripts.s3.fixtures.trace'

local FIXTURE = 'h3_probe_player'
local CTX = 'player'
local VERSION = 1

local seq = 0
local generation = 0
local updateSeen = false
local initCount = 0
local loadCount = 0
local saveCount = 0
local root = nil

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

local function isOpen()
    return root ~= nil and root.layout ~= nil
end

local function destroyRoot(reason)
    generation = generation + 1
    if isOpen() then
        root:destroy()
        root = nil
        emit('ui', 'destroy', { reason = reason or 'unknown', generation = generation })
        return true
    end
    root = nil
    emit('ui', 'destroy-skip', { reason = reason or 'unknown', generation = generation })
    return false
end

local function makeLayout(gen)
    return {
        type = ui.TYPE.Window,
        layer = 'Windows',
        props = {
            title = 'H3 Fixture Player Probe',
            position = util.vector2(80, 80),
            size = util.vector2(360, 90),
        },
        content = ui.content {
            {
                type = ui.TYPE.Text,
                props = { text = 'H3 fixture player UI gen ' .. tostring(gen) },
            },
        },
        events = {
            mouseClick = async:callback(function()
                if gen == generation then
                    emit('ui', 'callback', { generation = gen })
                end
            end),
        },
    }
end

local function showRoot(reason)
    if isOpen() then
        destroyRoot('recreate')
    end
    generation = generation + 1
    local gen = generation
    root = ui.create(makeLayout(gen))
    emit('ui', 'create', { reason = reason or 'event', generation = gen })
end

local function inventorySnapshot(payload)
    if payload and payload.confirm == 'S3FIXTURE_MUTATE' then
        emit('inventory', 'mutation-blocked', { recordId = payload.recordId or 'nil', count = payload.count or 0 })
        return
    end

    local inventory = types.Actor.inventory(self.object)
    local total = 0
    local gold = 0
    for _, item in pairs(inventory) do
        total = total + 1
        if item.recordId == 'gold_001' then
            gold = gold + (item.count or 1)
        end
    end
    emit('inventory', 'read', { entries = total, gold = gold })
end

local function deferredAck()
    emit('timer', 'unsavable')
    core.sendGlobalEvent('S3FixtureAck', { from = CTX, kind = 'timer', seq = seq })
end

return {
    engineHandlers = {
        onInit = function(initData)
            initCount = initCount + 1
            emit('onInit', 'enter', { initCount = initCount, hasInitData = initData ~= nil })
            async:newUnsavableSimulationTimer(0, deferredAck)
        end,

        onLoad = function(data)
            -- Save migration/default handling: schema v1 has only primitive counters;
            -- missing/older fields intentionally keep current defaults.
            destroyRoot('onLoad')
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
            emit('onUpdate', 'first', { sim = core.getSimulationTime() })
        end,
    },

    eventHandlers = {
        S3FixtureRequest = function(payload)
            emit('S3FixtureRequest', 'receive', { from = payload and payload.from or 'unknown', kind = payload and payload.kind or 'nil' })
            core.sendGlobalEvent('S3FixtureAck', { from = CTX, kind = 'request', seq = seq })
        end,

        S3FixtureShowUi = function(payload)
            showRoot(payload and payload.reason or 'event')
        end,

        S3FixtureHideUi = function(payload)
            destroyRoot(payload and payload.reason or 'event')
        end,

        S3FixtureInventory = function(payload)
            inventorySnapshot(payload)
        end,

        S3FixtureUiSnapshot = function()
            emit('uiSnapshot', 'summary', { open = isOpen(), generation = generation, lines = isOpen() and 1 or 0 })
        end,
    },
}
