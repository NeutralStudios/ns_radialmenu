local doors = {
    { index = 0, label = 'veh_door_fl', icon = 'fa-solid fa-door-open' },
    { index = 1, label = 'veh_door_fr', icon = 'fa-solid fa-door-open' },
    { index = 2, label = 'veh_door_rl', icon = 'fa-solid fa-door-closed' },
    { index = 3, label = 'veh_door_rr', icon = 'fa-solid fa-door-closed' },
    { index = 4, label = 'veh_hood', icon = 'fa-solid fa-car-burst' },
    { index = 5, label = 'veh_trunk', icon = 'fa-solid fa-box' }
}

local function getVehicle()
    if cache.vehicle then return cache.vehicle, true end
    local vehicle = NS.ClosestVehicle(Config.Vehicle.searchDistance)
    if vehicle and vehicle ~= 0 then return vehicle, false end
end

local function isDoorOpen(vehicle, index)
    return GetVehicleDoorAngleRatio(vehicle, index) > 0.0
end

local function canUseDoors(vehicle)
    if not DoesEntityExist(vehicle) then return false end
    if not cache.vehicle and GetVehicleDoorLockStatus(vehicle) >= 2 then
        NS.Notify(locale('veh_locked'), 'error')
        return false
    end
    if not NS.Control(vehicle) then
        NS.Notify(locale('veh_no_control'), 'error')
        return false
    end
    return true
end

local function toggleDoor(vehicle, index)
    if not canUseDoors(vehicle) then return end
    if isDoorOpen(vehicle, index) then
        SetVehicleDoorShut(vehicle, index, false)
    else
        SetVehicleDoorOpen(vehicle, index, false, false)
    end
end

local function doorItems()
    local vehicle = getVehicle()
    if not vehicle then return nil, locale('no_vehicle_nearby') end
    local list = {}
    for _, door in ipairs(doors) do
        if GetIsDoorValid(vehicle, door.index) then
            list[#list + 1] = {
                label = locale(door.label),
                icon = door.icon,
                active = isDoorOpen(vehicle, door.index),
                keepOpen = true,
                action = function() toggleDoor(vehicle, door.index) end
            }
        end
    end
    if #list > 1 then
        list[#list + 1] = {
            label = locale('veh_all_doors'),
            icon = 'fa-solid fa-car-side',
            keepOpen = true,
            action = function()
                if not canUseDoors(vehicle) then return end
                local anyOpen = false
                for _, door in ipairs(doors) do
                    if GetIsDoorValid(vehicle, door.index) and isDoorOpen(vehicle, door.index) then
                        anyOpen = true
                        break
                    end
                end
                for _, door in ipairs(doors) do
                    if GetIsDoorValid(vehicle, door.index) then
                        if anyOpen then
                            SetVehicleDoorShut(vehicle, door.index, false)
                        else
                            SetVehicleDoorOpen(vehicle, door.index, false, false)
                        end
                    end
                end
            end
        }
    end
    return list
end

local function switchSeat(vehicle, seat)
    if not cache.vehicle or cache.vehicle ~= vehicle then return end
    if GetEntitySpeed(vehicle) * 3.6 > Config.Vehicle.seatChangeMaxSpeed then
        return NS.Notify(locale('veh_too_fast'), 'error')
    end
    if not IsVehicleSeatFree(vehicle, seat) then
        return NS.Notify(locale('veh_seat_taken'), 'error')
    end
    SetPedIntoVehicle(cache.ped, vehicle, seat)
end

local function seatItems()
    local vehicle = cache.vehicle
    if not vehicle then return nil, locale('no_vehicle_nearby') end
    local seats = GetVehicleModelNumberOfSeats(GetEntityModel(vehicle))
    local list = {}
    for seat = -1, seats - 2 do
        local label
        if seat == -1 then
            label = locale('veh_seat_driver')
        elseif seat == 0 then
            label = locale('veh_seat_passenger')
        else
            label = locale('veh_seat_n', seat + 2)
        end
        list[#list + 1] = {
            label = label,
            icon = seat == -1 and 'fa-solid fa-user-tie' or 'fa-solid fa-user',
            active = GetPedInVehicleSeat(vehicle, seat) == cache.ped,
            keepOpen = true,
            action = function() switchSeat(vehicle, seat) end
        }
    end
    return list
end

local function hasExtras(vehicle)
    for i = 0, 20 do
        if DoesExtraExist(vehicle, i) then return true end
    end
    return false
end

local function extraItems()
    local vehicle = cache.vehicle
    if not vehicle then return nil, locale('no_vehicle_nearby') end
    local list = {}
    for i = 0, 20 do
        if DoesExtraExist(vehicle, i) then
            list[#list + 1] = {
                label = locale('veh_extra_n', i),
                icon = 'fa-solid fa-puzzle-piece',
                active = IsVehicleExtraTurnedOn(vehicle, i),
                keepOpen = true,
                action = function()
                    if Config.Vehicle.extrasRequireStopped and GetEntitySpeed(vehicle) > 1.0 then
                        return NS.Notify(locale('veh_must_stop'), 'error')
                    end
                    local body, engine, tank = GetVehicleBodyHealth(vehicle), GetVehicleEngineHealth(vehicle), GetVehiclePetrolTankHealth(vehicle)
                    SetVehicleAutoRepairDisabled(vehicle, true)
                    SetVehicleExtra(vehicle, i, IsVehicleExtraTurnedOn(vehicle, i))
                    SetVehicleBodyHealth(vehicle, body)
                    SetVehicleEngineHealth(vehicle, engine)
                    SetVehiclePetrolTankHealth(vehicle, tank)
                end
            }
        end
    end
    return list
end

local function isFlipped(vehicle)
    return IsEntityUpsidedown(vehicle) or math.abs(GetEntityRoll(vehicle)) > 60.0
end

local function flipVehicle(vehicle)
    if not DoesEntityExist(vehicle) then return end
    TaskTurnPedToFaceEntity(cache.ped, vehicle, 800)
    Wait(800)
    local done = lib.progressCircle({
        duration = Config.Vehicle.flipDuration,
        label = locale('veh_flipping'),
        position = 'bottom',
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = 'missfinale_c2ig_11', clip = 'pushcar_offcliff_m', flag = 1 }
    })
    if not done then return end
    if not NS.Control(vehicle) then return NS.Notify(locale('veh_no_control'), 'error') end
    SetEntityRotation(vehicle, 0.0, 0.0, GetEntityHeading(vehicle), 2, true)
    SetVehicleOnGroundProperly(vehicle)
end

local function toggleEngine(vehicle)
    SetVehicleEngineOn(vehicle, not GetIsVehicleEngineRunning(vehicle), false, true)
end

NS.Builders.vehicle = function()
    local vehicle, inside = getVehicle()
    if not vehicle then return nil, locale('no_vehicle_nearby') end
    local list = {}
    if not inside and isFlipped(vehicle) then
        list[#list + 1] = {
            label = locale('veh_flip'),
            icon = 'fa-solid fa-rotate',
            action = function() flipVehicle(vehicle) end
        }
        return list
    end
    list[#list + 1] = { label = locale('veh_doors'), icon = 'fa-solid fa-door-open', builder = doorItems }
    if inside then
        list[#list + 1] = { label = locale('veh_seats'), icon = 'fa-solid fa-chair', builder = seatItems }
        if hasExtras(vehicle) then
            list[#list + 1] = { label = locale('veh_extras'), icon = 'fa-solid fa-puzzle-piece', builder = extraItems }
        end
        if GetPedInVehicleSeat(vehicle, -1) == cache.ped then
            list[#list + 1] = {
                label = locale('veh_engine'),
                icon = 'fa-solid fa-power-off',
                active = GetIsVehicleEngineRunning(vehicle),
                keepOpen = true,
                action = function() toggleEngine(vehicle) end
            }
        end
    end
    return list
end
