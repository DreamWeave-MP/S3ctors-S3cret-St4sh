---@module 'doc.s3maphoreTypes'
---@omw-context player

local I = require 'openmw.interfaces'
local core = require 'openmw.core'
local gameSelf = require 'openmw.self'
local nearby = require 'openmw.nearby'
local types = require 'openmw.types'

local ActiveEffects, CreatureRecords, DynamicStats, GetGameTime, IsNPC, Level, NPCRecords =
  types.Actor.activeEffects,
  types.Creature.records,
  types.NPC.stats.dynamic,
  core.getGameTime,
  types.NPC.objectIsInstance,
  types.Actor.stats.level,
  types.NPC.records

local VAMPIRISM_EFFECT = core.magic.EFFECT_TYPE.Vampirism

local Error, Floor, Next, Pairs, StrFind, StrFormat, StrLower, Type, HUGE =
  error, math.floor, next, pairs, string.find, string.format, string.lower, type, math.huge

local Quests = gameSelf.type.quests(gameSelf)
local MyLevel = gameSelf.type.stats.level(gameSelf)
local NearbyActors = nearby.actors

local PlaylistState = require 'scripts.s3.music.playlistState'
local clear = require 'scripts.s3.clear'

---@class PlaylistRules helper functions for running playlist behaviors
local PlaylistRules = {}

local combatTargetCacheKey

--- Stores playlist rule lookups according to whatever is most relevant for that particular type,
--- allowing rules to only execute once per a given context.
--- This cache has the same lifetime as the game session itself, so long sessions with no reloads
--- could potentially see a relatively large cache build up over time.
---@type table<any, any>
local S3maphoreGlobalCache = {}

--- Returns the per-cell cache table, creating it if needed.
---@param cellName string
---@return table<any, any>
local function ensureCellCache(cellName)
  local cache = S3maphoreGlobalCache[cellName]
  if not cache then
    cache = {}
    S3maphoreGlobalCache[cellName] = cache
  end
  return cache
end

--- Table of IDs mapped to target levels
---@type table<string, openmw.types.LevelStat>
local combatTargetLevelCache = {}

--- Ensure the combat target cache table exists and return it, or nil if there is no cache key
---@return table<any, any>|nil
local function ensureCombatCache()
  local key = combatTargetCacheKey
  if not key then return end

  local cache = S3maphoreGlobalCache[key]
  if not cache then
    cache = {}
    S3maphoreGlobalCache[key] = cache
  end

  return cache
end

---@hidden
--- Clear target-specific caches, used either when they exit combat or are hit
---@param removedTargetId string
local function clearPerTargetCaches(removedTargetId)
  S3maphoreGlobalCache[removedTargetId] = nil
  combatTargetLevelCache[removedTargetId] = nil
end

---@hidden
local function clearGlobalCombatTargetCache()
  if not combatTargetCacheKey then return end
  S3maphoreGlobalCache[combatTargetCacheKey] = nil
end

---@hidden
--- When a target dies or is otherwised removed from the combat targets table, remove
--- references to the old cache and any userdata objects cached for memory saving purposes
---@param removedTargetId string
local function clearCombatCaches(removedTargetId)
  clearGlobalCombatTargetCache()
  clearPerTargetCaches(removedTargetId)
end

--- Returns whether the current cell name matches a pattern rule. Checks disallowed patterns first
---
--- Example usage:
---
--- playlistRules.cellNameMatch { allowed = { 'mages', 'south wall', }, disallowed = { 'fighters', } }
---@param patterns CellMatchPatterns
function PlaylistRules.cellNameMatch(patterns)
  local cellName = PlaylistState.cellName

  local cellCache = ensureCellCache(cellName)
  local old = cellCache[patterns]
  if old ~= nil then return old end

  local result, found = false, false

  local disallowed = patterns.disallowed or {}
  for i = 1, #disallowed do
    local pattern = disallowed[i]
    if StrFind(cellName, pattern, 1, true) then
      found = true
      break
    end
  end

  if not found then
    local allowed = patterns.allowed or {}
    for i = 1, #allowed do
      local pattern = allowed[i]
      if StrFind(cellName, pattern, 1, true) then
        result = true
        break
      end
    end
  end

  cellCache[patterns] = result

  return result
end

--- Returns whether or not the current cell exists in the cellNames map
---
--- Example usage:
---
--- playlistRules.cellNameExact { 'balmora, caius cosades\'s house' = true, 'balmora, guild of mages' = true, }
---@param cellNames IDPresenceMap
---@return boolean
function PlaylistRules.cellNameExact(cellNames) return cellNames[PlaylistState.cellName] end

--- Returns whether the player is currently in combat with any actor out of the input set
--- the playlistState provided to each `isValidCallback` includes a `combatTargets` field which is meant to be used as the first argument
---
--- Exmple usage:
---
--- playlistRules.combatTarget { 'caius cosades' = true, }
---@param validTargets IDPresenceMap
---@return boolean
function PlaylistRules.combatTargetExact(validTargets)
  if not PlaylistState.isInCombat then return false end

  local currentCombatTargetsCache = ensureCombatCache()

  if currentCombatTargetsCache then
    local old = currentCombatTargetsCache[validTargets]
    if old ~= nil then return old end
  end

  local result = false
  local combatTargets = PlaylistState.combatTargets
  for i = 1, #combatTargets do
    local actor = combatTargets[i]
    local actorName = StrLower(actor.type.records[actor.recordId].name)

    if validTargets[actorName] then
      result = true
      break
    end
  end

  currentCombatTargetsCache[validTargets] = result

  return result
end

local validCreatureTypes = {
  [0] = 'creatures',
  [1] = 'daedra',
  [2] = 'undead',
  [3] = 'humanoid',
}

--- Rule for checking whether combat targets match a specific type. This can be for NPCs, or specific subtypes of creatures, such as undead, or daedric.
--- Valid values are listed under the TargetType enum.
--- NOTE: These are hashsets and only `true` is a valid value.
--- Inputs must always be lowercased. Yes, really.
---
--- Example Usage:
---
--- playlistRules.combatTargetType { ['npc'] = true }
--- playlistRules.combatTargetType { ['undead'] = true }
---@param targetTypeRules CombatTargetTypeMatches
---@return boolean
function PlaylistRules.combatTargetType(targetTypeRules)
  if not PlaylistState.isInCombat then return false end

  local currentCombatTargetsCache = ensureCombatCache()

  if currentCombatTargetsCache then
    local old = currentCombatTargetsCache[targetTypeRules]
    if old ~= nil then return old end
  end

  local result = false
  local combatTargets = PlaylistState.combatTargets
  for i = 1, #combatTargets do
    local actor = combatTargets[i]

    if IsNPC(actor) then
      if targetTypeRules.npc then
        result = true
        break
      end
    else
      local creatureRecord = CreatureRecords[actor.recordId]
      ---@diagnostic disable-next-line: need-check-nil
      local creatureType = validCreatureTypes[creatureRecord.type]

      if targetTypeRules[creatureType] then
        result = true
        break
      end
    end
  end

  currentCombatTargetsCache[targetTypeRules] = result

  return result
end

--- Checks whether any combat target's classes matches one of a hashset
--- ALWAYS LOWERCASE YOUR INPUTS!
---
--- Example Usage:
---
--- playlistRules.combatTargetClasses { ['guard'] = true, ['acrobat'] = true }
---@param classes IDPresenceMap
---@return boolean
function PlaylistRules.combatTargetClass(classes)
  if not PlaylistState.isInCombat then return false end

  local currentCombatTargetsCache = ensureCombatCache()

  if currentCombatTargetsCache then
    local old = currentCombatTargetsCache[classes]
    if old ~= nil then return old end
  end

  local result = false
  local combatTargets = PlaylistState.combatTargets
  for i = 1, #combatTargets do
    local actor = combatTargets[i]

    if IsNPC(actor) then
      local targetRecord = actor.type.records[actor.recordId]

      if classes[targetRecord.class] then
        result = true
        break
      end
    end
  end

  currentCombatTargetsCache[classes] = result

  return result
end

--- Rule used to check if a nearby merchant does, or doesn't, offer a specific service.
--- Works on all nearby actors, and bails and returns true for the first actor whom matches all provided rules.
--- Works best in locations where a single merchant is present - for cells where multiple actors may potentially offer the same service, like The Abecette,
--- a cellNameMatch or cellNameExact rule may be more appropriate.
--- Only accepts a limited range of inputs as defined by the `ServicesOffered` type.
---
--- Example Usage:
---
--- local services = { ["Armor"] = true, ['Repair'] = true, }
--- playlistRules.localMerchantType(services)
---@param services ServicesOffered
---@return boolean
function PlaylistRules.localMerchantType(services)
  if PlaylistState.isInCombat then return false end

  local cellName = PlaylistState.cellName

  local cellCache = ensureCellCache(cellName)
  local old = cellCache[services]
  if old ~= nil then return old end

  local result = false

  for i = 1, #NearbyActors do
    local actor = NearbyActors[i]
    local targetRecord = (IsNPC(actor) and NPCRecords or CreatureRecords)[actor.recordId]

    ---@diagnostic disable-next-line: need-check-nil
    local targetServices = targetRecord.servicesOffered

    local matchedAll = true
    for serviceName, offered in Next, services do
      if targetServices[serviceName] ~= offered then
        matchedAll = false
        break
      end
    end

    if matchedAll then
      result = true
      break
    end
  end

  cellCache[services] = result

  return result
end

--- Rule for checking the rank of a target in the specified faction.
--- Like any rule utilizing a LevelDifferenceMap, either min or max are optional, but *one* of the two is required.
---
--- Example usage:
---
--- playlistRules.combatTargetFaction { hlaalu = { min = 1 } }
---@param factionRules NumericPresenceMap
function PlaylistRules.combatTargetFaction(factionRules)
  if not PlaylistState.isInCombat then return false end

  local currentCombatTargetsCache = ensureCombatCache()

  if currentCombatTargetsCache then
    local old = currentCombatTargetsCache[factionRules]
    if old ~= nil then return old end
  end

  local result, combatTargets = false, PlaylistState.combatTargets
  for i = 1, #combatTargets do
    local actor = combatTargets[i]
    local getFactionRank = actor.type.getFactionRank

    if getFactionRank then
      for factionName, rankRange in Next, factionRules do
        local targetFactionRank = getFactionRank(actor, factionName)

        if
          targetFactionRank <= (rankRange.max or HUGE)
          and targetFactionRank >= (rankRange.min or 1)
        then
          result = true
          break
        end
      end
    end

    if result then break end
  end

  currentCombatTargetsCache[factionRules] = result

  return result
end

--- Sets a relative or absolute limit on combat target levels for triggering combat music.
---
--- levelDifference rules may be relative or absolute, eg a multplier of the player's level or the actual difference in level.
--- They may have a minimum and maximum threshold, although either is optional.
--- Negative values indicate the player is stronger, whereas positive ones indicate the target is stronger.
---
--- Example usage:
---
--- This rule plays if the target's level is equal to or up to five levels bove the player's
--- playlistRules.combatTargetLevelDifference { absolute = { min = 0, max = 5 } }
---
--- This rule is valid if the target's level is within half or twice the player's level. EG if you're level 20, and the target is level 10, this rule matches.
--- playlistRules.combatTargetLevelDifference { relative = { min = 0.5, max = 2.0 } }
---@param levelRule LevelDifferenceMap
function PlaylistRules.combatTargetLevelDifference(levelRule)
  if not PlaylistState.isInCombat then return false end

  local currentCombatTargetsCache = ensureCombatCache()

  if currentCombatTargetsCache then
    local old = currentCombatTargetsCache[levelRule]
    if old ~= nil then return old end
  end

  local result = false
  local combatTargets = PlaylistState.combatTargets
  for i = 1, #combatTargets do
    local actor = combatTargets[i]
    local targetLevel = combatTargetLevelCache[actor.id]
    if not targetLevel then
      ---@diagnostic disable-next-line: cast-local-type
      targetLevel = Level(actor)
      combatTargetLevelCache[actor.id] = targetLevel
    end

    ---@cast targetLevel openmw.types.LevelStat

    local levelDifference, levelScale
    if levelRule.absolute then
      levelDifference = targetLevel.current - MyLevel.current
      levelScale = levelRule.absolute
    elseif levelRule.relative then
      levelDifference = targetLevel.current / MyLevel.current
      levelScale = levelRule.relative
    else
      Error(
        StrFormat(
          'Table %s for combatTargetLevelDifference rule does not contain either the relative OR absolute fields! You broke it!',
          levelRule
        )
      )
    end

    ---@diagnostic disable-next-line: need-check-nil
    if levelDifference <= levelScale.max and levelDifference >= levelScale.min then
      result = true
      break
    end
  end

  currentCombatTargetsCache[levelRule] = result

  return result
end

--- Rule for checking if the player is fighting vampires of any type, or clan.
--- To check specific vampire clans, use the faction rule.
---@return boolean
function PlaylistRules.fightingVampires()
  if not PlaylistState.isInCombat then return false end

  local currentCombatTargetsCache = ensureCombatCache()

  if currentCombatTargetsCache then
    local old = currentCombatTargetsCache.vampires
    if old ~= nil then return old end
  end

  local result = false
  local combatTargets = PlaylistState.combatTargets
  for i = 1, #combatTargets do
    local actor = combatTargets[i]
    local actorId = actor.id

    local actorStatCache = S3maphoreGlobalCache[actorId]
    if not actorStatCache then
      actorStatCache = {}
      S3maphoreGlobalCache[actorId] = actorStatCache
    end

    local activeEffects = actorStatCache.effects or ActiveEffects(actor)
    if not actorStatCache.effects then actorStatCache.effects = activeEffects end

    if activeEffects:getEffect(VAMPIRISM_EFFECT).magnitude > 0 then
      result = true
      break
    end
  end

  currentCombatTargetsCache.vampires = result

  return result
end

--- Checks whether or not an actor meets a specific threshold for any of the three dynamic stats - health, fatigue, or magicka.
--- Any combination of the three will work, and one may use a maximum and/or a minimum threshold
---
--- Example usage:
---
--- Rule is valid if an actor has MORE than 25% health
--- playlistRules.dynamicStatThreshold { health = { min = 0.25 } }
---
--- Rule is valid is an actor has LESS THAN 75% magicka.
--- playlistRules.dynamicStatThreshold { magicka = { max = 0.75 } }
---@param statThreshold StatThresholdMap decimal number encompassing how much health the target should have left in order for this playlist to be considered valid
---@return boolean
function PlaylistRules.dynamicStatThreshold(statThreshold)
  if not PlaylistState.isInCombat then return false end

  local currentCombatTargetsCache = ensureCombatCache()

  if currentCombatTargetsCache then
    local old = currentCombatTargetsCache[statThreshold]
    if old ~= nil then return old end
  end

  --- Iterate every actor
  --- Confirm all of them fall within the threshold
  --- if any one of them does not pass, then, bail on the whole thing
  local result = true
  local combatTargets = PlaylistState.combatTargets
  for i = 1, #combatTargets do
    local actor = combatTargets[i]
    local actorId = actor.id

    local actorStatCache = S3maphoreGlobalCache[actorId]
    if not actorStatCache then
      actorStatCache = {}
      S3maphoreGlobalCache[actorId] = actorStatCache
    end

    local passed = true
    for statName, range in Next, statThreshold do
      local stat = actorStatCache[statName] or DynamicStats[statName](actor)
      if not actorStatCache[statName] then actorStatCache[statName] = stat end

      local normalizedStat = stat.current / stat.base

      if normalizedStat < (range.min or 0.0) or normalizedStat > (range.max or HUGE) then
        passed = false
        break
      end
    end

    if not passed then
      result = false
      break
    end
  end

  currentCombatTargetsCache[statThreshold] = result

  return result
end

--- Finds any nearby combat target whose name matches any one string of a set
---
--- Example usage:
---
--- playlist.rules.combatTargetMatch { 'jedi', 'sith', }
---@param validTargetPatterns string[]
---@return boolean
function PlaylistRules.combatTargetMatch(validTargetPatterns)
  if not PlaylistState.isInCombat then return false end

  local currentCombatTargetsCache = ensureCombatCache()

  if currentCombatTargetsCache then
    local old = currentCombatTargetsCache[validTargetPatterns]
    if old ~= nil then return old end
  end

  local combatTargets = PlaylistState.combatTargets
  local result = false

  for i = 1, #combatTargets do
    local actor = combatTargets[i]
    local actorId = actor.recordId
    if not S3maphoreGlobalCache[actorId] then S3maphoreGlobalCache[actorId] = {} end

    local cachedResult = S3maphoreGlobalCache[actorId][validTargetPatterns]

    if cachedResult ~= nil then
      if cachedResult then
        result = true
        break
      end
    else
      local actorName = StrLower(actor.type.records[actorId].name)

      local actorResult = false
      for j = 1, #validTargetPatterns do
        local pattern = validTargetPatterns[j]
        if StrFind(actorName, pattern, 1, true) ~= nil then
          actorResult = true
          break
        end
      end

      S3maphoreGlobalCache[actorId][validTargetPatterns] = actorResult

      if actorResult then
        result = true
        break
      end
    end
  end

  currentCombatTargetsCache[validTargetPatterns] = result

  return result
end

--- Returns true if any current combat target has a recordId with any of the given FlexTags.
--- Iterates PlaylistState.combatTargets once, checking objectHasTag per target.
---
--- Example usage:
---
--- playlistRules.combatTargetTagged { 'npcassassin', 'npcbandit', 'npcfactioncamonnatong', }
---@param tagTable string[]
---@return boolean
function PlaylistRules.combatTargetTagged(tagTable)
  if not I.FlexTagL then
    print '[ S3MAPHORE ]: FlexTag not installed — combatTargetTagged returning false'
    return false
  end

  local currentCombatTargetsCache = ensureCombatCache()
  if currentCombatTargetsCache then
    local old = currentCombatTargetsCache[tagTable]
    if old ~= nil then return old end
  end

  local result = false
  local combatTargets = PlaylistState.combatTargets

  for i = 1, #combatTargets do
    local target = combatTargets[i]
    if I.FlexTagL.objectHasTag(target.recordId, tagTable) then
      result = true
      break
    end
  end

  if currentCombatTargetsCache then currentCombatTargetsCache[tagTable] = result end

  return result
end

--- Checks whether any object matching the given record IDs is present in the current cell.
--- Replaces former staticExact — same logic, broader scope (uses byRecord presence).
--- Example usage:
---
--- playlistRules.objectExact { 'furn_de_ex_bench_01' = true, 'ex_ashl_tent_01' = false, }
---@param staticRules IDPresenceMap
---@return boolean?
function PlaylistRules.objectExact(staticRules)
  local cellName = PlaylistState.cellName

  local cellCache = ensureCellCache(cellName)
  local old = cellCache[staticRules]
  if old ~= nil then return old end

  local byRecord = PlaylistState.objectsByRecord
  local result = false

  for recordId, ruleVal in Next, staticRules do
    if byRecord[recordId] then
      result = ruleVal
      break
    end
  end

  cellCache[staticRules] = result

  return result
end

--- REMOVED — Replaced by objectExact.
---@param staticRules IDPresenceMap
---@return boolean?
function PlaylistRules.staticExact(staticRules)
  print '[ S3MAPHORE ]: staticExact deprecated — replace with objectExact in your playlist'
  return PlaylistRules.objectExact(staticRules)
end

--- REMOVED — Replaced by tagger tag rules + music markers.
--- See souleInteriors.lua and souleCells.lua for former call sites.
---@param _patterns string[]
---@return boolean?
function PlaylistRules.staticMatch(_patterns)
  Error 'staticMatch has been removed. Use tagger tag rules + music markers instead.'
end

--- Returns whether or not a given cell contains statics matching the given content file array
--- Automatically lowercases all input content file names!
---
--- Example usage:
---
--- Playback.rules.staticContentFile { ['starwind enhanced.esm'] = true, }
---@param inputContentFiles  IDPresenceMap
---@return boolean
function PlaylistRules.staticContentFile(inputContentFiles)
  local contentFiles = PlaylistState.staticObjectContentFiles
  if not contentFiles[1] then return false end
  local cellName = PlaylistState.cellName

  local cellCache = ensureCellCache(cellName)
  local old = cellCache[inputContentFiles]
  if old ~= nil then return old end

  local result = false

  for i = 1, #contentFiles do
    local contentFile = contentFiles[i]
    if inputContentFiles[contentFile] ~= nil then
      result = true
      break
    end
  end

  cellCache[inputContentFiles] = result

  return result
end

--- True if the current cell has any of the given FlexTags.
--- Requires FlexTag installed with cell tags in ModTags YAML.
---
--- Example usage:
---
--- playlistRules.cellHasTag { 'ashlands', 'blight', }
---@param tagTable string[]
---@return boolean
function PlaylistRules.cellHasTag(tagTable)
  if not I.FlexTagL then
    print '[ S3MAPHORE ]: FlexTag not installed — cellHasTag returning false'
    return false
  end

  local cellName = PlaylistState.cellName
  local cellCache = ensureCellCache(cellName)
  local old = cellCache[tagTable]
  if old ~= nil then return old end

  local result = I.FlexTagL.objectHasTag(cellName, tagTable) or false

  cellCache[tagTable] = result

  return result
end

--- True if any object in the current cell has a recordId with any of the given FlexTags.
--- Iterates CellPresence.byRecord once, checking objectHasTag per recordId.
---
--- Example usage:
---
--- playlistRules.cellContainsTagged { 'WeaponDwemer', 'ArmorDwemer', }
---@param tagTable string[]
---@return boolean
function PlaylistRules.cellContainsTagged(tagTable)
  if not I.FlexTagL then
    print '[ S3MAPHORE ]: FlexTag not installed — cellContainsTagged returning false'
    return false
  end

  local cellName = PlaylistState.cellName
  local cellCache = ensureCellCache(cellName)
  local old = cellCache[tagTable]
  if old ~= nil then return old end

  local result = false
  local byRecord = PlaylistState.objectsByRecord

  for recordId in Pairs(byRecord) do
    if I.FlexTagL.objectHasTag(recordId, tagTable) then
      result = true
      break
    end
  end

  cellCache[tagTable] = result
  return result
end

--- True if any content file with objects in the current cell has any of the given FlexTags.
--- FlexTag can tag any string — content file names work the same as record IDs or cell names.
--- Iterates CellPresence.byContentFile keys once, checking objectHasTag per content file.
---
--- Example usage:
---
--- playlistRules.contentTag { 'starwind-core', 'tamriel-rebuilt', }
---@param tagTable string[]
---@return boolean
function PlaylistRules.contentTag(tagTable)
  if not I.FlexTagL then
    print '[ S3MAPHORE ]: FlexTag not installed — contentTag returning false'
    return false
  end

  local cellName = PlaylistState.cellName
  local cellCache = ensureCellCache(cellName)
  local old = cellCache[tagTable]
  if old ~= nil then return old end

  local result = false
  local byContentFile = PlaylistState.objectsByContentFile

  for contentFile in Pairs(byContentFile) do
    if I.FlexTagL.objectHasTag(contentFile, tagTable) then
      result = true
      break
    end
  end

  cellCache[tagTable] = result
  return result
end

--- Check if the count of objects of a given type in the current cell falls within a range.
--- Reads from CellPresence.byType. Omitting min or max skips that bound.
---
--- Example usage:
---
--- playlistRules.typeCount { type = 'Container', min = 3, max = 10 }
---@param typeRule { type: string, min?: number, max?: number }
---@return boolean
function PlaylistRules.typeCount(typeRule)
  local cellName = PlaylistState.cellName
  local cellCache = ensureCellCache(cellName)
  local old = cellCache[typeRule]
  if old ~= nil then return old end

  local count = PlaylistState.objectsByType[typeRule.type] or 0
  local min = typeRule.min or 0
  local max = typeRule.max or HUGE

  local result = count >= min and count <= max

  cellCache[typeRule] = result
  return result
end

--- Checks whether the current gameHour matches a certain time of day or not
--- Starts at the minHour, and ends at the maxHour.
--- The below example using 8 and 12, will start at 8 am and end at 12 PM.
---
--- Example usage:
---
--- playlistRules.timeOfDay(8, 12)
---@param minHour integer
---@param maxHour integer
---@return boolean
function PlaylistRules.timeOfDay(minHour, maxHour)
  local gameHour = Floor(GetGameTime() / 3600) % 24
  return gameHour < maxHour and gameHour >= minHour
end

--- Return whether the current region matches a set
---
--- Example usage:
---
--- playlistRules.region { 'azura\'s coast region' = true, 'sheogorad region' = true, }
---@param regionNames IDPresenceMap
---@return boolean
function PlaylistRules.region(regionNames)
  local currentRegion = PlaylistState.nearestRegion

  return currentRegion ~= nil and currentRegion ~= '' and regionNames[currentRegion] or false
end

--- Return whether the current weather matches a set
---
--- Example usage:
---
--- playlistRules.weatherType { 'rain' = true, 'overcast' = true, 'thunder' = true, }
---@param weatherNames IDPresenceMap
---@return boolean
function PlaylistRules.weatherType(weatherNames) return weatherNames[PlaylistState.weather] or false end

--- Returns whether the current exterior cell is on a particular node of the grid
---
--- Example usage:
---
--- playlistRules.exteriorGrid { { x = -2, y = -3 } }
---@param gridRules S3maphoreCellGrid[]
function PlaylistRules.exteriorGrid(gridRules)
  local currentGrid = PlaylistState.currentGrid
  if not currentGrid then return false end

  local exteriorGridCache = S3maphoreGlobalCache[PlaylistState.cellId]
  if exteriorGridCache ~= nil then return exteriorGridCache end

  local result = false
  for i = 1, #gridRules do
    local gridRule = gridRules[i]
    if gridRule.x == currentGrid.x and gridRule.y == currentGrid.y then
      result = true
      break
    end
  end

  S3maphoreGlobalCache[PlaylistState.cellId] = result

  return result
end

local S3maphoreJournalCache = {}

---@hidden
---Clear the journal cache when a player gets a journal update
local function clearJournalCache() clear(S3maphoreJournalCache) end

--- Playlist rule for checking a specific journal state
---
--- Example usage:
---
--- Playback.rules.journal { A1_V_VivecInformants = { min = 50, max = 55, }, }
---@param journalDataMap NumericPresenceMap
---@return boolean
function PlaylistRules.journal(journalDataMap)
  local cachedResult = S3maphoreJournalCache[journalDataMap]

  if cachedResult ~= nil then return cachedResult end

  local result = false

  for questName, questRange in Next, journalDataMap do
    local quest = Quests[questName]

    if quest then
      local questState = quest.stage

      if questState <= (questRange.max or HUGE) and questState >= questRange.min then
        result = true
        break
      end
    end
  end

  S3maphoreJournalCache[journalDataMap] = result

  return result
end

---@hidden
---@param key S3maphoreCacheKey?
local function setCombatTargetCacheKey(key)
  if key and Type(key) ~= 'string' then Error('Invalid cache key provided!', 2) end

  local prev = combatTargetCacheKey
  if prev and prev ~= key then S3maphoreGlobalCache[prev] = nil end

  combatTargetCacheKey = key
end

return {
  rules = PlaylistRules,
  clearJournalCache = clearJournalCache,
  clearGlobalCombatTargetCache = clearGlobalCombatTargetCache,
  setCombatTargetCacheKey = setCombatTargetCacheKey,
  clearCombatCaches = clearCombatCaches,
}
