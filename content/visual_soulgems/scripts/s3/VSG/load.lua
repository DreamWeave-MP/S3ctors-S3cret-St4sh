---@omw-context load

local content = require 'openmw.content'
local recordData = require 'scripts.s3.VSG.records'

local miscellaneousRecords = content.miscs.records

for i = 1, #recordData.records do
  local record = recordData.records[i]
  local template = miscellaneousRecords[record.sourceId]
  if not template then
    if record.required then error(string.format('Missing soul gem record: %s', record.sourceId)) end
  else
    for j = 1, #recordData.variants do
      local variant = recordData.variants[j]
      local recordId = recordData.replacementPrefix
        .. record.replacementName
        .. '_'
        .. variant.suffix

      miscellaneousRecords[recordId] = {
        template = template,
        model = variant.models[record.modelKey],
      }
    end
  end
end
