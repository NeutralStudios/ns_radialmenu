local trunk = { active = false, vehicle = nil, forced = false }
local carry = { target = nil, by = nil }
local trunkDict, trunkClip = 'fin_ext_p1-7', 'cs_devin_dual-7'

local function hasTrunk(vehicle)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return false end
    local class = GetVehicleClass(vehicle)
    for _, blocked in ipairs(Config.Trunk.blockedClasses) do
        if class == blocked then return false end
    end
    return GetEntityBoneIndexByName(vehicle, 'boot') ~= -1
end

local function netId(vehicle)
    if not NetworkGetEntityIsNetworked(vehicle) then return end
    return VehToNet(vehicle)
end

local function setLid(vehicle, open)
    if not DoesEntityExist(vehicle) then return end
    NS.Control(vehicle)
    if open then
        SetVehicleDoorOpen(vehicle, 5, false, false)
    else
        SetVehicleDoorShut(vehicle, 5, false)
    end
end

local leaveTrunk

local function trunkLoop()
    local canLeave = not trunk.forced or Config.Trunk.victimCanEscape
    lib.showTextUI(locale(canLeave and 'cit_trunk_help' or 'cit_trunk_help_locked'), { position = 'left-center', icon = 'car-rear' })
    while trunk.active do
        local vehicle = trunk.vehicle
        if not DoesEntityExist(vehicle) or IsEntityDead(cache.ped) then
            leaveTrunk()
            break
        end
        DisableAllControlActions(0)
        EnableControlAction(0, 0, true)
        EnableControlAction(0, 1, true)
        EnableControlAction(0, 2, true)
        EnableControlAction(0, 245, true)
        EnableControlAction(0, 249, true)
        if not IsEntityPlayingAnim(cache.ped, trunkDict, trunkClip, 3) then
            TaskPlayAnim(cache.ped, trunkDict, trunkClip, 8.0, -8.0, -1, 1, 0, false, false, false)
        end
        if canLeave then
            if IsDisabledControlJustReleased(0, 38) then
                leaveTrunk()
                break
            end
            if IsDisabledControlJustReleased(0, 47) then
                setLid(vehicle, GetVehicleDoorAngleRatio(vehicle, 5) <= 0.0)
            end
        end
        Wait(0)
    end
end

function NS.EnterTrunk(vehicle, forced)
    if trunk.active or not hasTrunk(vehicle) then
        return NS.Notify(locale('cit_no_trunk'), 'error')
    end
    local id = netId(vehicle)
    if not id then return NS.Notify(locale('cit_no_trunk'), 'error') end
    local occupant = Entity(vehicle).state.nsTrunk
    if occupant and occupant ~= cache.serverId then
        return NS.Notify(locale('cit_trunk_occupied'), 'error')
    end
    if not forced and GetVehicleDoorLockStatus(vehicle) >= 2 then
        return NS.Notify(locale('veh_locked'), 'error')
    end
    local ped = cache.ped
    setLid(vehicle, true)
    Wait(400)
    lib.requestAnimDict(trunkDict)
    local min = GetModelDimensions(GetEntityModel(vehicle))
    AttachEntityToEntity(ped, vehicle, 0, 0.0, min.y + Config.Trunk.offsetY, Config.Trunk.offsetZ, 0.0, 0.0, 0.0, false, false, false, false, 20, true)
    TaskPlayAnim(ped, trunkDict, trunkClip, 8.0, -8.0, -1, 1, 0, false, false, false)
    trunk.active, trunk.vehicle, trunk.forced = true, vehicle, forced and true or false
    TriggerServerEvent('ns_radialmenu:server:trunkState', id)
    SetTimeout(700, function()
        if trunk.active and trunk.vehicle == vehicle then setLid(vehicle, false) end
    end)
    CreateThread(trunkLoop)
end

leaveTrunk = function()
    if not trunk.active then return end
    local vehicle = trunk.vehicle
    local ped = cache.ped
    trunk.active = false
    trunk.vehicle = nil
    trunk.forced = false
    lib.hideTextUI()
    DetachEntity(ped, true, true)
    StopAnimTask(ped, trunkDict, trunkClip, 1.0)
    ClearPedTasks(ped)
    if DoesEntityExist(vehicle) then
        setLid(vehicle, true)
        local min = GetModelDimensions(GetEntityModel(vehicle))
        local position = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, min.y - 0.7, 0.0)
        SetEntityCoords(ped, position.x, position.y, position.z, false, false, false, false)
        SetEntityHeading(ped, GetEntityHeading(vehicle) + 180.0)
        SetTimeout(900, function() setLid(vehicle, false) end)
    end
    TriggerServerEvent('ns_radialmenu:server:trunkState', false)
end
NS.LeaveTrunk = leaveTrunk

local function carryLoop()
    local dict, clip = 'missfinale_c2mcs_1', 'fin_c2_mcs_1_camman'
    lib.requestAnimDict(dict)
    while carry.target do
        if not IsEntityPlayingAnim(cache.ped, dict, clip, 3) then
            TaskPlayAnim(cache.ped, dict, clip, 8.0, -8.0, -1, 49, 0, false, false, false)
        end
        DisableControlAction(0, 21, true)
        DisableControlAction(0, 22, true)
        DisableControlAction(0, 23, true)
        DisableControlAction(0, 24, true)
        DisableControlAction(0, 25, true)
        DisableControlAction(0, 44, true)
        DisableControlAction(0, 140, true)
        DisableControlAction(0, 141, true)
        DisableControlAction(0, 142, true)
        local targetPlayer = GetPlayerFromServerId(carry.target)
        if targetPlayer == -1 or IsEntityDead(cache.ped) then
            TriggerServerEvent('ns_radialmenu:server:release')
            break
        end
        Wait(0)
    end
    StopAnimTask(cache.ped, dict, clip, 1.0)
    RemoveAnimDict(dict)
end

local function carriedLoop()
    local dict, clip = 'nm', 'firemans_carry'
    lib.requestAnimDict(dict)
    while carry.by do
        local carrier = GetPlayerFromServerId(carry.by)
        local carrierPed = carrier ~= -1 and GetPlayerPed(carrier) or 0
        if carrierPed == 0 or not DoesEntityExist(carrierPed) then
            carry.by = nil
            break
        end
        if not IsEntityAttachedToEntity(cache.ped, carrierPed) then
            AttachEntityToEntity(cache.ped, carrierPed, 0, 0.27, 0.15, 0.63, 0.5, 0.5, 180.0, false, false, false, false, 2, false)
        end
        if not IsEntityPlayingAnim(cache.ped, dict, clip, 3) then
            TaskPlayAnim(cache.ped, dict, clip, 8.0, -8.0, -1, 33, 0, false, false, false)
        end
        DisableAllControlActions(0)
        EnableControlAction(0, 1, true)
        EnableControlAction(0, 2, true)
        EnableControlAction(0, 245, true)
        EnableControlAction(0, 249, true)
        Wait(0)
    end
    DetachEntity(cache.ped, true, false)
    StopAnimTask(cache.ped, dict, clip, 1.0)
    RemoveAnimDict(dict)
end

RegisterNetEvent('ns_radialmenu:client:carrying', function(target)
    carry.target = target
    CreateThread(carryLoop)
end)

RegisterNetEvent('ns_radialmenu:client:carried', function(by)
    if NS.IsOpen() then NS.Close() end
    carry.by = by
    CreateThread(carriedLoop)
end)

RegisterNetEvent('ns_radialmenu:client:releaseCarry', function()
    carry.target = nil
    carry.by = nil
end)

RegisterNetEvent('ns_radialmenu:client:forceTrunk', function(id)
    local timeout = GetGameTimer() + 3000
    while not NetworkDoesEntityExistWithNetworkId(id) and GetGameTimer() < timeout do Wait(50) end
    if not NetworkDoesEntityExistWithNetworkId(id) then return end
    local vehicle = NetToVeh(id)
    Wait(300)
    DetachEntity(cache.ped, true, false)
    NS.EnterTrunk(vehicle, true)
end)

RegisterNetEvent('ns_radialmenu:client:leaveTrunk', function()
    leaveTrunk()
end)

NS.Builders.citizen = function()
    local list = {}
    if trunk.active then
        if not trunk.forced or Config.Trunk.victimCanEscape then
            list[1] = { label = locale('cit_leave_trunk'), icon = 'fa-solid fa-person-walking-arrow-right', action = leaveTrunk }
        end
        return list
    end
    if carry.by then return nil end
    local vehicle = not cache.vehicle and NS.ClosestVehicle(3.5) or nil
    local validTrunk = vehicle and hasTrunk(vehicle) and netId(vehicle)
    if carry.target then
        if validTrunk then
            list[#list + 1] = {
                label = locale('cit_put_trunk'),
                icon = 'fa-solid fa-car-rear',
                action = function() TriggerServerEvent('ns_radialmenu:server:putInTrunk', validTrunk) end
            }
        end
        list[#list + 1] = {
            label = locale('cit_release'),
            icon = 'fa-solid fa-hand',
            action = function() TriggerServerEvent('ns_radialmenu:server:release') end
        }
        return list
    end
    if cache.vehicle then return nil, locale('nothing_available') end
    if validTrunk then
        if Entity(vehicle).state.nsTrunk then
            list[#list + 1] = {
                label = locale('cit_take_trunk'),
                icon = 'fa-solid fa-people-arrows',
                action = function() TriggerServerEvent('ns_radialmenu:server:takeOutOfTrunk', validTrunk) end
            }
        else
            list[#list + 1] = {
                label = locale('cit_hide_trunk'),
                icon = 'fa-solid fa-car-rear',
                action = function() NS.EnterTrunk(vehicle, false) end
            }
        end
    end
    local playerId = NS.ClosestPlayer(Config.Kidnap.distance)
    if playerId then
        list[#list + 1] = {
            label = locale('cit_kidnap'),
            icon = 'fa-solid fa-person-carry-box',
            action = function() TriggerServerEvent('ns_radialmenu:server:kidnap', GetPlayerServerId(playerId)) end
        }
    end
    if #list == 0 then return nil, locale('nothing_available') end
    return list
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if trunk.active then
        lib.hideTextUI()
        DetachEntity(cache.ped, true, true)
        ClearPedTasks(cache.ped)
    end
    if carry.by then DetachEntity(cache.ped, true, false) end
end)
