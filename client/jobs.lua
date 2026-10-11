local resolved = {}
local meter
local mission

local function resolve(kind)
    if resolved[kind] ~= nil then return resolved[kind] or nil end
    local cfg = Config.Jobs[kind] or {}
    local choice = cfg.integration or 'auto'
    local found
    for _, entry in ipairs(Config.Integrations[kind] or {}) do
        if choice == 'auto' then
            if GetResourceState(entry.resource) == 'started' then
                found = entry
                break
            end
        elseif choice == entry.name then
            found = entry
            break
        end
    end
    resolved[kind] = found or false
    return found
end

local function findAction(kind, id)
    local integration = resolve(kind)
    if integration and integration.actions[id] then return integration.actions[id] end
    local fallback = Config.Integrations.fallback[kind]
    return fallback and fallback[id]
end

local function isActive(kind, id)
    if kind == 'taxi' and id == 'meter' then return meter ~= nil end
    if kind == 'taxi' and id == 'npc' then return mission ~= nil end
    return false
end

NS.Builders.job = function()
    local job = Bridge.GetJob()
    if not job then return nil, locale('job_none') end
    local kind, cfg = NS.JobKind(job.name)
    if not kind then return nil, locale('job_none') end
    if cfg.requireDuty and not job.onduty then return nil, locale('job_off_duty') end
    local list = {}
    for _, def in ipairs(cfg.actions) do
        local action = findAction(def.from or kind, def.id)
        if action then
            list[#list + 1] = {
                label = locale(def.label),
                icon = def.icon,
                color = cfg.color,
                active = isActive(def.from or kind, def.id),
                action = action
            }
        end
    end
    if #list == 0 then return nil, locale('job_none') end
    return list
end

function NS.Internal.checkStatus()
    local playerId, ped = NS.ClosestPlayer()
    if not playerId then return NS.Notify(locale('no_player_nearby'), 'error') end
    if IsPedDeadOrDying(ped, true) or GetEntityHealth(ped) <= 100 then
        return NS.Notify(locale('status_dead'), 'error')
    end
    local max = math.max(GetEntityMaxHealth(ped) - 100, 1)
    local health = math.floor((GetEntityHealth(ped) - 100) / max * 100)
    NS.Notify(locale('status_health', health, GetPedArmour(ped)), 'inform')
end

function NS.Internal.searchPlayer(target)
    if not target then return end
    if GetResourceState('ox_inventory') == 'started' then
        return exports.ox_inventory:openInventory('player', target)
    elseif GetResourceState('qs-inventory') == 'started' then
        return TriggerServerEvent('inventory:server:OpenInventory', 'otherplayer', target)
    elseif GetResourceState('qb-inventory') == 'started' or GetResourceState('ps-inventory') == 'started' then
        return TriggerServerEvent('inventory:server:OpenInventory', 'otherplayer', target)
    end
    NS.Notify(locale('unsupported'), 'error')
end

function NS.Internal.revokeLicense(target, licenseType)
    if not target then return end
    TriggerServerEvent('ns_radialmenu:server:revokeLicense', target, licenseType)
end

local function nearbyVehicleOutside()
    if cache.vehicle then
        NS.Notify(locale('mech_exit'), 'error')
        return
    end
    local vehicle = NS.ClosestVehicle(4.0)
    if not vehicle then
        NS.Notify(locale('no_vehicle_nearby'), 'error')
        return
    end
    return vehicle
end

function NS.Internal.mechRepair()
    local vehicle = nearbyVehicleOutside()
    if not vehicle then return end
    TaskTurnPedToFaceEntity(cache.ped, vehicle, 800)
    Wait(800)
    if NS.Control(vehicle) then SetVehicleDoorOpen(vehicle, 4, false, false) end
    local done = lib.progressCircle({
        duration = Config.Mechanic.repairTime,
        label = locale('repairing'),
        position = 'bottom',
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = 'mini@repair', clip = 'fixing_a_player', flag = 1 }
    })
    if NS.Control(vehicle) then
        if done then
            SetVehicleFixed(vehicle)
            SetVehicleDeformationFixed(vehicle)
            SetVehicleEngineHealth(vehicle, 1000.0)
            SetVehicleBodyHealth(vehicle, 1000.0)
            SetVehiclePetrolTankHealth(vehicle, 1000.0)
            SetVehicleUndriveable(vehicle, false)
            NS.Notify(locale('repaired'), 'success')
        end
        SetVehicleDoorShut(vehicle, 4, false)
    end
end

function NS.Internal.mechClean()
    local vehicle = nearbyVehicleOutside()
    if not vehicle then return end
    TaskTurnPedToFaceEntity(cache.ped, vehicle, 800)
    Wait(800)
    local done = lib.progressCircle({
        duration = Config.Mechanic.cleanTime,
        label = locale('cleaning'),
        position = 'bottom',
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { scenario = 'WORLD_HUMAN_MAID_CLEAN' }
    })
    ClearPedTasks(cache.ped)
    if done and NS.Control(vehicle) then
        SetVehicleDirtLevel(vehicle, 0.0)
        WashDecalsFromVehicle(vehicle, 1.0)
        NS.Notify(locale('cleaned'), 'success')
    end
end

local function fareText()
    local fare = Config.Taxi.baseFare + meter.distance / 1000.0 * Config.Taxi.perKm
    return ('%.2f'):format(fare), ('%.2f'):format(meter.distance / 1000.0)
end

function NS.Internal.taxiMeter()
    if meter then
        local fare = fareText()
        meter = nil
        lib.hideTextUI()
        return NS.Notify(locale('meter_off', fare), 'inform')
    end
    if not cache.vehicle then return NS.Notify(locale('taxi_need_vehicle'), 'error') end
    meter = { distance = 0.0, last = GetEntityCoords(cache.ped) }
    NS.Notify(locale('meter_on'), 'success')
    CreateThread(function()
        while meter do
            local position = GetEntityCoords(cache.ped)
            if cache.vehicle then
                meter.distance = meter.distance + #(position - meter.last)
            end
            meter.last = position
            local fare, km = fareText()
            lib.showTextUI(locale('meter_text', fare, km), { position = 'right-center', icon = 'taxi' })
            Wait(1000)
        end
    end)
end

local function endMission(ped, blip, cancelled)
    if blip and DoesBlipExist(blip) then RemoveBlip(blip) end
    if ped and DoesEntityExist(ped) then
        SetBlockingOfNonTemporaryEvents(ped, false)
        TaskWanderStandard(ped, 10.0, 10)
        SetPedAsNoLongerNeeded(ped)
    end
    if cancelled then
        TriggerServerEvent('ns_radialmenu:server:taxiCancel')
        NS.Notify(locale('taxi_cancel'), 'error')
    end
    mission = nil
end

function NS.Internal.taxiNpc()
    if mission then
        mission.cancel = true
        return
    end
    if not cache.vehicle or cache.seat ~= -1 then return NS.Notify(locale('taxi_need_vehicle'), 'error') end
    local data = lib.callback.await('ns_radialmenu:taxiStart', false)
    if not data then return NS.Notify(locale('taxi_active'), 'error') end
    mission = { cancel = false }
    local pickup = Config.Taxi.locations[data.pickup]
    local drop = Config.Taxi.locations[data.drop]
    CreateThread(function()
        local model = Config.Taxi.pedModels[math.random(#Config.Taxi.pedModels)]
        lib.requestModel(model)
        local found, groundZ = GetGroundZFor_3dCoord(pickup.x, pickup.y, pickup.z + 2.0, false)
        local ped = CreatePed(4, joaat(model), pickup.x, pickup.y, found and groundZ or pickup.z, math.random(0, 359) + 0.0, true, true)
        SetModelAsNoLongerNeeded(joaat(model))
        SetBlockingOfNonTemporaryEvents(ped, true)
        SetPedKeepTask(ped, true)
        TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_STAND_MOBILE', 0, true)
        local blip = AddBlipForCoord(pickup.x, pickup.y, pickup.z)
        SetBlipColour(blip, 5)
        SetBlipRoute(blip, true)
        SetBlipRouteColour(blip, 5)
        NS.Notify(locale('taxi_pickup'), 'inform')
        local stage = 1
        local vehicle
        while mission do
            if mission.cancel or not DoesEntityExist(ped) or IsEntityDead(ped) then
                endMission(ped, blip, true)
                break
            end
            local position = GetEntityCoords(cache.ped)
            if stage == 1 then
                vehicle = cache.vehicle
                if vehicle and #(position - pickup) < 12.0 and GetEntitySpeed(vehicle) < 1.5 then
                    local seat = IsVehicleSeatFree(vehicle, 2) and 2 or (IsVehicleSeatFree(vehicle, 1) and 1 or 0)
                    ClearPedTasks(ped)
                    TaskEnterVehicle(ped, vehicle, 15000, seat, 1.0, 1, 0)
                    stage = 2
                end
            elseif stage == 2 then
                if GetVehiclePedIsIn(ped, false) == vehicle then
                    RemoveBlip(blip)
                    blip = AddBlipForCoord(drop.x, drop.y, drop.z)
                    SetBlipColour(blip, 5)
                    SetBlipRoute(blip, true)
                    SetBlipRouteColour(blip, 5)
                    NS.Notify(locale('taxi_dropoff'), 'inform')
                    stage = 3
                elseif cache.vehicle ~= vehicle then
                    stage = 1
                end
            elseif stage == 3 then
                if cache.vehicle == vehicle and #(position - drop) < 12.0 and GetEntitySpeed(vehicle) < 1.5 then
                    TaskLeaveVehicle(ped, vehicle, 0)
                    Wait(1500)
                    local pay = lib.callback.await('ns_radialmenu:taxiFinish', false)
                    if pay then NS.Notify(locale('taxi_paid', pay), 'success') end
                    endMission(ped, blip, false)
                    break
                end
            end
            Wait(500)
        end
    end)
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if meter then lib.hideTextUI() end
end)
