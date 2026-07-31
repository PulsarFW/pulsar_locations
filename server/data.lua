local config = load(LoadResourceFile(GetCurrentResourceName(), "config/server.lua"))()

local _ran = false

-- Inserts any default that isn't already present (matched by Name) into `locations` directly -
-- no separate seed table/version bookkeeping, this resource owns one table now.
function Startup()
	if _ran then
		return
	end
	_ran = true

	LOCATIONS:GetAll("spawn", function(existing)
		local seen = {}
		for _, location in ipairs(existing or {}) do
			seen[location.Name] = true
		end

		for _, default in ipairs(config.DefaultLocations) do
			if not seen[default.Name] then
				LOCATIONS:Add(default.Coords, default.Coords.w, default.Type, default.Name)
			end
		end
	end)
end
