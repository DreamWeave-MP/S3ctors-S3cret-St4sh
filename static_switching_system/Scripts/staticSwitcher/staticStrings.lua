--- Static strings reused across the SSS framework
---@class SSSStaticStrings
SSSStaticStrings = {
    PREFIX_FRAME = '[ %s ]:',
    LOG_PREFIX = 'StaticSwitchingSystem',
    LOG_FORMAT_STR = '%s %s',
    GET_REFNUM_STR = '%s %s has refNum %d',
    MISSING_MESH_ERROR =
    [[Requested model %s to replace %s on object %s, but the mesh was not found. The module: %s was not properly installed!]],
    GeneratedObjectStr = 'Object %s is generated and cannot be modified on a per-instance basis!',
    InvalidModuleNameStr = 'Invalid module name provided: %s. Either it does not exist, or has not replaced anything.',
    NotARefNumStr = 'Refnum: %s was not a number!',
    ReplacingObjectsStr = 'Replacing Objects in cell: %s',
    ReplacingIndividualObjectStr = 'Replacing object %s with model %s provided by module %s',
    InvalidTypeStr = 'Invalid type was provided: %s',
}

return SSSStaticStrings
