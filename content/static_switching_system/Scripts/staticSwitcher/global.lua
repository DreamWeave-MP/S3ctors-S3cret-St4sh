---@omw-context global

local types = require 'openmw.types'
local util = require 'openmw.util'
local world = require 'openmw.world'

---@type StaticUtil
local staticUtil = require 'Scripts.staticSwitcher.util'

---@type SSSLogger
local logger = require 'Scripts.staticSwitcher.logger'

local ModuleToRemove

local ipairs, type = ipairs, type

local sendMenuEvent = types.Player.sendMenuEvent

local DeleteManager = require 'Scripts.staticSwitcher.deleteManager'

local StaticReplacements = require 'Scripts.staticSwitcher.staticReplacements'(DeleteManager)

local ModuleCatalog = require 'Scripts.staticSwitcher.moduleCatalog'(StaticReplacements)

StaticReplacements.setModuleResolver(ModuleCatalog.resolveModuleId)

local InstanceModifiers = require 'Scripts.staticSwitcher.instanceModifiers'(ModuleCatalog, DeleteManager)

local uninstallModule = require 'Scripts.staticSwitcher.globalSettings'(
	ModuleCatalog.staticModuleIds,
	DeleteManager,
	StaticReplacements.ReplacedObjectSet,
	StaticReplacements.uninstallModule
)

local settingsGroup = require('openmw.storage').globalSection 'SettingsStaticSwitcher'

---@type openmw.GObject[]
local ActiveObjectStack = {}

local NullFunction = require 'scripts.s3.nullFunction'
local UpdateFunction = NullFunction
local processActiveObject, processDeletions, processUninstall

local REPLACE_PER_BATCH = 4

processActiveObject = function()
	local numObjects = 0

	for _ = 1, REPLACE_PER_BATCH do
		numObjects = #ActiveObjectStack

		if numObjects == 0 then
			break
		end

		local object = ActiveObjectStack[numObjects]

		if object:isValid() and object.count >= 1 then
			local instanceModificationList = InstanceModifiers.getMatchingInstanceModules(object)

			--- I don't like this.
			--- Ideally we should have like, a special type that gets assigned to each module, or something
			--- a more bespoke way to describe what *type* of module it is
			if instanceModificationList then
				InstanceModifiers.tryModifyObject(object, instanceModificationList)
			else
				StaticReplacements.tryReplaceObject(object)
			end
		end

		ActiveObjectStack[numObjects] = nil
	end

	logger.debug('Batch processed, stack: %d remaining', #ActiveObjectStack)

	if not DeleteManager:queueIsEmpty() then
		UpdateFunction = processDeletions
	elseif numObjects <= 1 then
		UpdateFunction = NullFunction
	end
end

processUninstall = function()
	--- When a module is removed and all objects are removed
	--- kick every player from the game and force them to save
	logger.info('Uninstall complete for %s, forcing save and quit', ModuleToRemove)

	for _, player in ipairs(world.players) do
		sendMenuEvent(player, 'StaticSwitcherMenuRemoveModule', ModuleToRemove)
	end

	ModuleToRemove = nil
	UpdateFunction = NullFunction
end

processDeletions = function()
	DeleteManager:processDeleteQueue()

	local deletionsFinished = DeleteManager:queueIsEmpty()

	if next(ActiveObjectStack) ~= nil then
		UpdateFunction = processActiveObject
	elseif ModuleToRemove and deletionsFinished then
		UpdateFunction = processUninstall
	elseif deletionsFinished then
		UpdateFunction = NullFunction
	end

	logger.debug('Deletions: queue empty=%s, stack=%d', deletionsFinished, #ActiveObjectStack)
end

settingsGroup:subscribe(require('openmw.async'):callback(function(_, key)
	if key == 'StaticSwitcherDisableModule' and settingsGroup:get 'StaticSwitcherDisableModule' == true then
		local moduleToUninstall = settingsGroup:get 'StaticSwitcherModuleSelect'
		logger.info('Uninstall triggered via settings for: %s', moduleToUninstall)

		local removedModule = uninstallModule(moduleToUninstall)
		if not removedModule then
			return
		end

		ModuleToRemove = removedModule
		UpdateFunction = processDeletions
	end
end))

return {
	interface = {
		---@return boolean isGenerated, number refNum
		getRefNum = staticUtil.getRefNum,
		---@return table<string, SSSModule> moduleData Map of file names handling mesh replacements to the data contained therein
		composedReplacements = function()
			return util.makeReadOnly(StaticReplacements.ComposedReplacements)
		end,
		---@return SSSObjectModificationStore
		objectModificationStore = function()
			return util.makeReadOnly(ModuleCatalog.ObjectModificationStore)
		end,
		---@return SSSOverrideRecords
		overrideRecords = function()
			return util.makeReadOnly(StaticReplacements.OverrideRecords)
		end,
		---@return SSSReplacedObjectSet
		replacedObjectSet = function()
			return util.makeReadOnly(StaticReplacements.ReplacedObjectSet)
		end,
		---@param moduleName string
		uninstallModule = function(moduleName)
			local removedModule = uninstallModule(moduleName)
			if not removedModule then
				return
			end

			ModuleToRemove = removedModule
			UpdateFunction = processDeletions
		end,
		version = 3,
	},
	interfaceName = 'StaticSwitcher_G',
	engineHandlers = {
		onUpdate = function()
			UpdateFunction()
		end,
		---@param object openmw.GObject
		onObjectActive = function(object)
			if ModuleToRemove then
				return
			end

			local stackWasEmpty = not next(ActiveObjectStack)

			if stackWasEmpty then
				InstanceModifiers.clearPerCellTracking()
			end

			ActiveObjectStack[#ActiveObjectStack + 1] = object
			logger.debug('Object active: %s (%s) [stack=%d]', object.id, object.recordId or '?', #ActiveObjectStack)

			if UpdateFunction ~= processActiveObject then
				UpdateFunction = processActiveObject
			end
		end,
		---@return SSSSavedState
		onSave = function()
			logger.debug 'Saving SSS state'
			return {
				overrideRecords = StaticReplacements.OverrideRecords,
				objectDeleteQueue = DeleteManager.queue,
				instanceModifiers = InstanceModifiers.saveOnceCache(),
				replacementChains = StaticReplacements.saveReplacementChains(),
				replacedObjectSet = StaticReplacements.ReplacedObjectSet,
			}
		end,
		---@param data SSSSavedState?
		onLoad = function(data)
			if not data then
				logger.debug 'Loading SSS state: fresh save (no data)'
				DeleteManager.queue = {}
				InstanceModifiers.loadOnceCache()
				StaticReplacements.loadReplacementChains()
				return
			end

			logger.debug 'Loading SSS state from save data'
			staticUtil.deepCopy(StaticReplacements.OverrideRecords, data.overrideRecords)
			StaticReplacements.migrateOverrideRecords()
			DeleteManager.queue = {}
			if type(data.objectDeleteQueue) == 'table' then
				staticUtil.deepCopy(DeleteManager.queue, data.objectDeleteQueue)
			end
			InstanceModifiers.loadOnceCache(data.instanceModifiers)
			staticUtil.deepCopy(StaticReplacements.ReplacedObjectSet, data.replacedObjectSet)
			StaticReplacements.loadReplacementChains(data.replacementChains)

			if settingsGroup:get 'StaticSwitcherDisableModule' then
				logger.info 'Clearing stale disable-module flag after load'
				settingsGroup:set('StaticSwitcherDisableModule', false)
			end

			if not DeleteManager:queueIsEmpty() then
				UpdateFunction = processDeletions
			end
		end,
	},
}
