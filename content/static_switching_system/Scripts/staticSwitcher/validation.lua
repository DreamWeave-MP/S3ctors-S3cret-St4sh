---@omw-context global

local KNOWN_KEYS = {
	log_name = true,
	replace_names = true,
	exterior_cells = true,
	replace_regions = true,
	ignore_records = true,
	replace_meshes = true,
	instances = true,
}

---@param modulePath string
---@param moduleData table
local function validateModule(modulePath, moduleData)
	for key in pairs(moduleData) do
		if not KNOWN_KEYS[key] then
			print(('SSS Warning: unknown top-level key "%s" in %s'):format(key, modulePath))
		end
	end

	if not moduleData.replace_meshes and not moduleData.instances then
		print(('SSS Warning: no replace_meshes or instances in %s'):format(modulePath))
	end

	if moduleData.replace_meshes and moduleData.instances then
		print(
			('SSS Warning: both replace_meshes and instances in %s; they are mutually exclusive'):format(
				modulePath
			)
		)
	end
end

return { validate = validateModule }
