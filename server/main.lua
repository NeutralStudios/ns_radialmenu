local carrying = {}
local carriedBy = {}
local trunks = {}
local taxiMissions = {}
local saveCooldown = {}

CreateThread(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `ns_radialmenu` (
            `identifier` VARCHAR(80) NOT NULL,
            `settings` LONGTEXT NOT NULL,
            `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`identifier`)
        )
    ]])
end)

local function notify(src, message, kind)
    TriggerClientEvent('ox_lib:notify', src, { description = message, type = kind or 'inform' })
end

local function valid(src)
    return src and GetPlayerName(src) ~= nil
end

local function distance(a, b)
    local pa, pb = GetPlayerPed(a), GetPlayerPed(b)
    if pa == 0 or pb == 0 then return math.huge end
    return #(GetEntityCoords(pa) - GetEntityCoords(pb))
end

local function distanceToEntity(src, entity)
    local ped = GetPlayerPed(src)
    if ped == 0 or not DoesEntityExist(entity) then return math.huge end
    return #(GetEntityCoords(ped) - GetEntityCoords(entity))
end

local function hasJobKind(src, kind)
    local job = Bridge.GetJob(src)
    local cfg = Config.Jobs[kind]
    if not cfg then return false end
    for _, name in ipairs(cfg.jobs) do
        if name == job then return true end
    end
    return false
end

lib.callback.register('ns_radialmenu:getSettings', function(src)
    local identifier = Bridge.GetIdentifier(src)
    if not identifier then return end
    local row = MySQL.scalar.await('SELECT `settings` FROM `ns_radialmenu` WHERE `identifier` = ?', { identifier })
    if not row then return end
    local ok, data = pcall(json.decode, row)
    if ok then return data end
end)

RegisterNetEvent('ns_radialmenu:server:saveSettings', function(data)
    local src = source
    local now = GetGameTimer()
    if saveCooldown[src] and now - saveCooldown[src] < 400 then return end
    saveCooldown[src] = now
    local identifier = Bridge.GetIdentifier(src)
    if not identifier then return end
    local settings = NS.SanitizeSettings(data)
    MySQL.insert('INSERT INTO `ns_radialmenu` (`identifier`, `settings`) VALUES (?, ?) ON DUPLICATE KEY UPDATE `settings` = VALUES(`settings`)', { identifier, json.encode(settings) })
end)

lib.callback.register('ns_radialmenu:getProfile', function(src)
    return { name = Bridge.GetName(src), id = src }
end)

lib.callback.register('ns_radialmenu:getWallet', function(src)
    return { cash = Bridge.GetMoney(src, 'cash'), bank = Bridge.GetMoney(src, 'bank') }
end)

RegisterNetEvent('ns_radialmenu:server:giveCash', function(target, amount)
    local src = source
    if not Config.Wallet.giveCash then return end
    target = tonumber(target)
    amount = math.floor(tonumber(amount) or 0)
    if not target or target == src or not valid(target) then return end
    if amount <= 0 or amount > Config.Wallet.maxGive then return end
    if distance(src, target) > Config.InteractDistance + 1.5 then return end
    if not Bridge.RemoveMoney(src, 'cash', amount) then
        return notify(src, locale('wal_failed'), 'error')
    end
    Bridge.AddMoney(target, 'cash', amount)
    notify(src, locale('wal_given', amount), 'success')
    notify(target, locale('wal_received', amount), 'success')
end)

RegisterNetEvent('ns_radialmenu:server:revokeLicense', function(target, licenseType)
    local src = source
    target = tonumber(target)
    if not target or not valid(target) or not hasJobKind(src, 'police') then return end
    if distance(src, target) > Config.InteractDistance + 1.5 then return end
    if type(licenseType) ~= 'string' then
        licenseType = (Bridge.Framework == 'esx') and 'drive' or 'driver'
    end
    if Bridge.RevokeLicense(target, licenseType) then
        notify(src, locale('license_revoked'), 'success')
        notify(target, locale('license_revoked_target'), 'error')
    else
        notify(src, locale('unsupported'), 'error')
    end
end)

local function releaseCarry(src, silent)
    local target = carrying[src]
    if not target then return end
    carrying[src] = nil
    carriedBy[target] = nil
    TriggerClientEvent('ns_radialmenu:client:releaseCarry', src)
    if valid(target) then
        TriggerClientEvent('ns_radialmenu:client:releaseCarry', target)
        if not silent then notify(target, locale('cit_released'), 'inform') end
    end
    return target
end

RegisterNetEvent('ns_radialmenu:server:kidnap', function(target)
    local src = source
    target = tonumber(target)
    if not target or target == src or not valid(target) then return end
    if carrying[src] or carriedBy[src] or carrying[target] or carriedBy[target] or trunks[target] or trunks[src] then return end
    if distance(src, target) > Config.Kidnap.distance + 1.0 then return end
    if Config.Kidnap.requireRestrained and not Bridge.IsRestrained(target) then
        return notify(src, locale('cit_not_restrained'), 'error')
    end
    carrying[src] = target
    carriedBy[target] = src
    TriggerClientEvent('ns_radialmenu:client:carrying', src, target)
    TriggerClientEvent('ns_radialmenu:client:carried', target, src)
    notify(target, locale('cit_kidnapped'), 'error')
end)

RegisterNetEvent('ns_radialmenu:server:release', function()
    releaseCarry(source)
end)

RegisterNetEvent('ns_radialmenu:server:putInTrunk', function(netId)
    local src = source
    local target = carrying[src]
    if not target or type(netId) ~= 'number' then return end
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not vehicle or vehicle == 0 or distanceToEntity(src, vehicle) > 7.0 then return end
    if Entity(vehicle).state.nsTrunk then
        return notify(src, locale('cit_trunk_occupied'), 'error')
    end
    releaseCarry(src, true)
    TriggerClientEvent('ns_radialmenu:client:forceTrunk', target, netId)
end)

RegisterNetEvent('ns_radialmenu:server:takeOutOfTrunk', function(netId)
    local src = source
    if type(netId) ~= 'number' then return end
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not vehicle or vehicle == 0 or distanceToEntity(src, vehicle) > 7.0 then return end
    for player, id in pairs(trunks) do
        if id == netId and player ~= src then
            TriggerClientEvent('ns_radialmenu:client:leaveTrunk', player)
        end
    end
end)

local function clearTrunk(src)
    local netId = trunks[src]
    if not netId then return end
    trunks[src] = nil
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) and Entity(vehicle).state.nsTrunk == src then
        Entity(vehicle).state:set('nsTrunk', nil, true)
    end
end

RegisterNetEvent('ns_radialmenu:server:trunkState', function(netId)
    local src = source
    clearTrunk(src)
    if type(netId) ~= 'number' then return end
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not vehicle or vehicle == 0 or distanceToEntity(src, vehicle) > 10.0 then return end
    local occupant = Entity(vehicle).state.nsTrunk
    if occupant and occupant ~= src and valid(occupant) then return end
    trunks[src] = netId
    Entity(vehicle).state:set('nsTrunk', src, true)
end)

lib.callback.register('ns_radialmenu:taxiStart', function(src)
    if not hasJobKind(src, 'taxi') or taxiMissions[src] then return end
    local count = #Config.Taxi.locations
    local pickup = math.random(count)
    local drop = math.random(count)
    while drop == pickup do drop = math.random(count) end
    taxiMissions[src] = { pickup = pickup, drop = drop, started = os.time() }
    return { pickup = pickup, drop = drop }
end)

lib.callback.register('ns_radialmenu:taxiFinish', function(src)
    local mission = taxiMissions[src]
    if not mission then return end
    taxiMissions[src] = nil
    if not hasJobKind(src, 'taxi') then return end
    if os.time() - mission.started < Config.Taxi.minMissionTime then return end
    local ped = GetPlayerPed(src)
    local drop = Config.Taxi.locations[mission.drop]
    if #(GetEntityCoords(ped) - drop) > 30.0 then return end
    local km = #(Config.Taxi.locations[mission.pickup] - drop) / 1000.0
    local pay = math.min(math.floor(Config.Taxi.baseFare + km * Config.Taxi.perKm), Config.Taxi.maxPayout)
    Bridge.AddMoney(src, Config.Taxi.payAccount, pay)
    return pay
end)

RegisterNetEvent('ns_radialmenu:server:taxiCancel', function()
    taxiMissions[source] = nil
end)

AddEventHandler('playerDropped', function()
    local src = source
    releaseCarry(src)
    local carrier = carriedBy[src]
    if carrier then releaseCarry(carrier, true) end
    clearTrunk(src)
    taxiMissions[src] = nil
    saveCooldown[src] = nil
end)
