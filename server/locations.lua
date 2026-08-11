AddEventHandler("Proxy:Shared:RegisterReady", function()
	exports["pulsar_core"]:RegisterComponent("Locations", LOCATIONS)
end)

CreateThread(function()
	RegisterCallbacks()
	RegisterChatCommands()
	Startup()
	TriggerEvent("Locations:Server:Startup")
end)

function RegisterCallbacks()
	plsr.Callbacks:RegisterServerCallback("Locations:GetAll", function(source, data, cb)
		plsr.Locations:GetAll(data.type, cb)
	end)
end

function RegisterChatCommands()
	plsr.Chat:RegisterAdminCommand("location", function(source, args, rawCommand)
		local playerPed = GetPlayerPed(source)
		local coords = GetEntityCoords(playerPed)
		local heading = GetEntityHeading(playerPed)
		if args[1]:lower() == "add" and args[2] then
			plsr.Locations:Add(coords, heading, args[2], args[3])
		end
	end, {
		help = "Add Location",
		params = {
			{
				name = "Action",
				help = "Available: add",
			},
			{
				name = "Type",
				help = "Type of Location",
			},
			{
				name = "Name",
				help = "Name of Location",
			},
		},
	}, 3)
end

local _locationsTableReady = false
local function ensureLocationsTable(callback)
	if _locationsTableReady then
		if callback then
			callback()
		end
		return
	end
	plsr.Database:Query(
		"CREATE TABLE IF NOT EXISTS `locations` (`id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, `type` VARCHAR(191) NOT NULL, `data` JSON NOT NULL, INDEX `idx_type` (`type`))",
		nil,
		function()
			_locationsTableReady = true
			if callback then
				callback()
			end
		end
	)
end

LOCATIONS = {
	Add = function(self, coords, heading, type, name, cb)
		local doc = {
			Coords = vector4(coords.x, coords.y, coords.z, heading),
			Type = type,
			Name = name,
		}
		ensureLocationsTable(function()
			plsr.Database:Insert("INSERT INTO `locations` (`type`, `data`) VALUES (?, ?)", { type, json.encode(doc) }, function(success, newId)
				if not success then
					return
				end

				doc._id = newId
				TriggerEvent("Locations:Server:Added", type, doc)
				if cb ~= nil then
					cb(newId ~= nil)
				end
			end)
		end)
	end,
	GetAll = function(self, locType, cb)
		ensureLocationsTable(function()
			plsr.Database:Query("SELECT `id`, `data` FROM `locations` WHERE `type` = ?", { locType }, function(success, rows)
				if not success then
					cb({})
					return
				end
				local results = {}
				for k, row in ipairs(rows) do
					local ok, location = pcall(json.decode, row.data)
					if ok and type(location) == "table" then
						location._id = row.id
						location.Coords = vector4(location.Coords.x, location.Coords.y, location.Coords.z, location.Coords.w)
						table.insert(results, location)
					end
				end
				cb(results)
			end)
		end)
	end,
}
