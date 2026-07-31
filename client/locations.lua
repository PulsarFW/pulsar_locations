local config = load(LoadResourceFile(GetCurrentResourceName(), "config/shared.lua"))()

AddEventHandler('Proxy:Shared:RegisterReady', function()
    exports['pulsar_core']:RegisterComponent('Locations', LOCATIONS)
end)

CreateThread(function()
    for k, v in ipairs(config.LogoutLocations) do
        plsr.Targeting.Zones:AddBox("logout-location-" .. k, "person-from-portal", v.center, v.length, v.width, {
            heading = v.heading,
            minZ = v.minZ,
            maxZ = v.maxZ,
        }, {
            {
                icon = "person-from-portal",
                text = "Logout",
                event = "Locations:Client:LogoutLocation",
            },
        }, 2.0, true)
    end
end)

LOCATIONS = {
    GetAll = function(self, type, cb)
        plsr.Callbacks:ServerCallback('Locations:GetAll', {
            type = type
        }, cb)
    end
}

AddEventHandler('Locations:Client:LogoutLocation', function()
    plsr.Characters:Logout()
end)

AddEventHandler("Characters:Client:Spawn", function()
	CreateThread(function()
		while plsr.State.flags.loggedIn do
			Wait(60000)

            if not plsr.State.flags.tpLocation then
                local coords = GetEntityCoords(PlayerPedId())
                if plsr.State.flags.loggedIn and coords and #(coords - vector3(0.0, 0.0, 0.0)) >= 10.0 then
                    TriggerServerEvent('Characters:Server:LastLocation', coords)
                end
            end
        end
	end)
end)
