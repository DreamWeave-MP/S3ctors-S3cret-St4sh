---@omw-context menu

---Opt-in H3lp Yours3lf menu fixture probe.
---Creates one simple root only after explicit events and destroys it on hide/load.
---No storage, settings, object handles, callbacks, or UI elements are persisted.

local async = require 'openmw.async'
local core = require 'openmw.core'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local trace = require 'scripts.s3.fixtures.trace'

local FIXTURE = 'h3_probe_menu'
local CTX = 'menu'
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
            title = 'H3 Fixture Menu Probe',
            position = util.vector2(100, 100),
            size = util.vector2(340, 90),
        },
        content = ui.content {
            {
                type = ui.TYPE.Text,
                props = { text = 'H3 fixture menu UI gen ' .. tostring(gen) },
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

local function deferredTrace()
    emit('timer', 'unsavable')
end

return {
    engineHandlers = {
        onInit = function(initData)
            initCount = initCount + 1
            emit('onInit', 'enter', { initCount = initCount, hasInitData = initData ~= nil })
            async:newUnsavableSimulationTimer(0, deferredTrace)
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
        S3FixtureShowMenuUi = function(payload)
            showRoot(payload and payload.reason or 'event')
        end,

        S3FixtureHideMenuUi = function(payload)
            destroyRoot(payload and payload.reason or 'event')
        end,

        S3FixtureUiSnapshot = function()
            emit('uiSnapshot', 'summary', { open = isOpen(), generation = generation, lines = isOpen() and 1 or 0 })
        end,

        S3FixturePingMenu = function(payload)
            emit('S3FixturePingMenu', 'receive', { from = payload and payload.from or 'unknown' })
            if payload and payload.ackGlobal then
                core.sendGlobalEvent('S3FixtureAck', { from = CTX, kind = 'menu-ping', seq = seq })
            end
        end,
    },
}
