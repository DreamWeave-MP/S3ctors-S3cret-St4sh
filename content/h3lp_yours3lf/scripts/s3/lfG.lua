local S3S = require 'openmw.storage'.globalSection 'S3lfColdStorage'

---@alias KeyBehavior
---| 0 # Ignored
---| 1 # Uncacheable

---@class KeyBehaviors
local KeyBehavior = {
  baseType = 0,
  stats = 0,
  type = 0,
  cell = 1,
  count = 1,
  enabled = 1,
  id = 1,
  owner = 1,
  parentContainer = 1,
  position = 1,
  recordId = 1,
  rotation = 1,
  scale = 1,
}

S3S:set('KeyBehavior', KeyBehavior)
