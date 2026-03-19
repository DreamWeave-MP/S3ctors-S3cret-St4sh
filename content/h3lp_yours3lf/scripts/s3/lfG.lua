local S3S = require 'openmw.storage'.globalSection 'S3lfColdStorage'

S3S:set('IgnoredBaseKeys', {
  baseType = true,
  stats = true,
  type = true,
})

S3S:set('UncacheableKeys', {
  cell = true,
  count = true,
  enabled = true,
  id = true,
  owner = true,
  parentContainer = true,
  position = true,
  recordId = true,
  rotation = true,
  scale = true,
})
