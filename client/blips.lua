local smart = false
local blips = {}
local lastRefresh

local function clearBlips()
    for i = 1, #blips do
        if DoesBlipExist(blips[i]) then RemoveBlip(blips[i]) end
    end
    blips = {}
end

local function nearest(category, position)
    local best, bestDistance
    for _, coords in ipairs(category.coords) do
        local dist = #(position - coords)
        if not bestDistance or dist < bestDistance then
            best, bestDistance = coords, dist
        end
    end
    return best, bestDistance
end

local function refreshBlips()
    clearBlips()
    local position = GetEntityCoords(cache.ped)
    lastRefresh = position
    for _, category in ipairs(Config.Blips.categories) do
        local sorted = {}
        for _, coords in ipairs(category.coords) do
            sorted[#sorted + 1] = { coords = coords, dist = #(position - coords) }
        end
        table.sort(sorted, function(a, b) return a.dist < b.dist end)
        for i = 1, math.min(Config.Blips.nearest, #sorted) do
            local c = sorted[i].coords
            local blip = AddBlipForCoord(c.x, c.y, c.z)
            SetBlipSprite(blip, category.sprite)
            SetBlipColour(blip, category.colour)
            SetBlipScale(blip, 0.7)
            SetBlipAsShortRange(blip, true)
            SetBlipCategory(blip, 10)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(locale(category.label))
            EndTextCommandSetBlipName(blip)
            blips[#blips + 1] = blip
        end
    end
end

local function toggleSmart()
    smart = not smart
    if not smart then
        clearBlips()
        return NS.Notify(locale('blip_smart_off'), 'inform')
    end
    NS.Notify(locale('blip_smart_on'), 'success')
    refreshBlips()
    CreateThread(function()
        while smart do
            local position = GetEntityCoords(cache.ped)
            if not lastRefresh or #(position - lastRefresh) > Config.Blips.refreshDistance then
                refreshBlips()
            end
            Wait(3000)
        end
    end)
end

local function setWaypoint(category)
    local coords, dist = nearest(category, GetEntityCoords(cache.ped))
    if not coords then return end
    SetNewWaypoint(coords.x, coords.y)
    NS.Notify(locale('blip_waypoint', locale(category.label), math.floor(dist)), 'success')
end

NS.Builders.blips = function()
    local list = {
        {
            label = locale(smart and 'blip_smart_on' or 'blip_smart_off'),
            icon = 'fa-solid fa-location-crosshairs',
            active = smart,
            keepOpen = true,
            action = toggleSmart
        }
    }
    if IsWaypointActive() then
        list[#list + 1] = {
            label = locale('blip_clear'),
            icon = 'fa-solid fa-location-pin-lock',
            action = function()
                SetWaypointOff()
                NS.Notify(locale('blip_cleared'), 'inform')
            end
        }
    end
    for _, category in ipairs(Config.Blips.categories) do
        list[#list + 1] = {
            label = locale(category.label),
            icon = category.icon,
            color = category.color,
            action = function() setWaypoint(category) end
        }
    end
    return list
end

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then clearBlips() end
end)
