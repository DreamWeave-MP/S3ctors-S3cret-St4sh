---@omw-context global

local markup = require 'openmw.markup'
local storage = require 'openmw.storage'
local vfs = require 'openmw.vfs'

local FlexTagInterface = require 'Scripts.S3.ModTags.interface'
local ingestTag = FlexTagInterface.ingestTag
local removeTagFromMemory = FlexTagInterface.removeTagFromMemory
local markLoadingComplete = FlexTagInterface.markLoadingComplete
local isLoadingComplete = FlexTagInterface._isLoadingComplete
local syncToStorage = FlexTagInterface.syncToStorage
FlexTagInterface.ingestTag = nil
FlexTagInterface.removeTagFromMemory = nil
FlexTagInterface.markLoadingComplete = nil
FlexTagInterface._isLoadingComplete = nil
FlexTagInterface.syncToStorage = nil

local TagSection = storage.globalSection 'FlexTagStorage'

---@diagnostic disable-next-line: param-type-mismatch
TagSection:setLifeTime(storage.LIFE_TIME.Temporary)

local CoCreate, CoResume, CoStatus, CoYield = coroutine.create, coroutine.resume, coroutine.status, coroutine.yield
local pairs, print, type = pairs, print, type

local LogPrefix = ' [ FLEXTAG ]:'
local function TagLog(...)
	print(LogPrefix, ...)
end

---Load a single YAML table's tags into the in-progress tables (memory-only).
---Yields between each top-level key so large tag groups don't hitch a frame.
---@param tagTable table<string, string[]>
---@param tagCount number number of keys in this table
local function loadTagTableWithYields(tagTable, tagCount)
	local i = 0

	for tagName, itemList in pairs(tagTable) do
		i = i + 1

		if type(tagName) ~= 'string' then
			TagLog(tagName, 'is not a valid tag name! Skipping . . .')
		elseif type(itemList) ~= 'table' then
			TagLog(tagName, 'has a non-table item list. Skipping . . .')
		else
			for j = 1, #itemList do
				if type(itemList[j]) == 'string' then
					ingestTag(itemList[j], tagName)
				else
					TagLog(tagName, 'has non-string entry, skipping:', itemList[j])
				end
			end
		end

		if i < tagCount then
			CoYield()
		end
	end
end

---@return thread
local function createTagLoaderCoroutine()
	return CoCreate(function()
		local fileList = {}
		for tagFile in vfs.pathsWithPrefix("ModTags/") do
			fileList[#fileList + 1] = tagFile
		end

		if #fileList == 0 then
			TagLog('No tag files found in ModTags/')
			markLoadingComplete()
			return
		end

		TagLog('Staggered loading of', #fileList, 'tag files . . .')

		for i = 1, #fileList do
			local tagFile = fileList[i]
			local tagTable = markup.loadYaml(tagFile)

			if tagTable then
				local keyCount = 0
				for _ in pairs(tagTable) do keyCount = keyCount + 1 end
				loadTagTableWithYields(tagTable, keyCount)
			else
				TagLog(tagFile, 'is not a valid YAML file! Skipping . . .')
			end

			if i < #fileList then
				CoYield()
			end
		end

		markLoadingComplete()
		TagLog('Tag loading complete.')
	end)
end

local loaderCo = createTagLoaderCoroutine()

local onUpdate
local function noop() end

local function resumeLoader()
	local ok, err = CoResume(loaderCo)

	if not ok then
		TagLog('Coroutine error:', err)
		markLoadingComplete()
	end

	if CoStatus(loaderCo) == 'dead' then onUpdate = noop end
end

onUpdate = resumeLoader

---@param eventData table<string, string[]>
local function onAddTags(eventData)
	for taggedObject, tagList in pairs(eventData) do
		for tagIdx = 1, #tagList do
			ingestTag(taggedObject, tagList[tagIdx])
		end
	end

	if isLoadingComplete() then
		syncToStorage()
	end
end

---@param eventData table<string, string[]>
local function onRemoveTags(eventData)
	for taggedObject, tagList in pairs(eventData) do
		for tagIdx = 1, #tagList do
			removeTagFromMemory(taggedObject, tagList[tagIdx])
		end
	end

	if isLoadingComplete() then
		syncToStorage()
	end
end

return {
	interfaceName = 'FlexTagG',
	interface = FlexTagInterface,
	engineHandlers = {
		onUpdate = function()
			onUpdate()
		end,
	},
	eventHandlers = {
		FlexTagAdd = onAddTags,
		FlexTagRemove = onRemoveTags,
	},
}
