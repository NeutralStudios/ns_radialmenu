Bridge = {}

local framework = Config.Framework
if framework == 'auto' then
    if GetResourceState('qbx_core') == 'started' then
        framework = 'qbx'
    elseif GetResourceState('qb-core') == 'started' then
        framework = 'qb'
    elseif GetResourceState('es_extended') == 'started' then
        framework = 'esx'
    else
        framework = 'standalone'
    end
end
Bridge.Framework = framework

local QBCore, ESX
if framework == 'qb' then
    QBCore = exports['qb-core']:GetCoreObject()
elseif framework == 'esx' then
    ESX = exports.es_extended:getSharedObject()
end

local function playerData()
    if framework == 'qbx' then
        return exports.qbx_core:GetPlayerData()
    elseif framework == 'qb' then
        return QBCore.Functions.GetPlayerData()
    elseif framework == 'esx' then
        return ESX.GetPlayerData()
    end
end

function Bridge.GetJob()
    local data = playerData()
    if framework == 'qbx' or framework == 'qb' then
        if not data or not data.job then return end
        local grade = type(data.job.grade) == 'table' and data.job.grade.level or data.job.grade
        return { name = data.job.name, grade = grade or 0, onduty = data.job.onduty ~= false }
    elseif framework == 'esx' then
        if not data or not data.job then return end
        local onduty = data.job.onDuty
        if onduty == nil then onduty = true end
        return { name = data.job.name, grade = data.job.grade or 0, onduty = onduty }
    end
    local state = LocalPlayer.state
    return { name = state.job or 'unemployed', grade = state.jobGrade or 0, onduty = state.duty ~= false }
end

function Bridge.IsDead()
    local state = LocalPlayer.state
    if state.isDead or state.dead or state.down then return true end
    if framework == 'qbx' or framework == 'qb' then
        local data = playerData()
        if data and data.metadata and (data.metadata.isdead or data.metadata.inlaststand) then return true end
    end
    return IsEntityDead(cache.ped)
end

function Bridge.IsRestrained()
    local state = LocalPlayer.state
    if state.handcuffed or state.isCuffed or state.cuffed or state.restrained or state.ziptied then return true end
    if framework == 'qbx' or framework == 'qb' then
        local data = playerData()
        if data and data.metadata and data.metadata.ishandcuffed then return true end
    end
    return false
end

function Bridge.IsLoaded()
    if framework == 'qbx' then
        return LocalPlayer.state.isLoggedIn == true
    elseif framework == 'qb' then
        return LocalPlayer.state.isLoggedIn == true
    elseif framework == 'esx' then
        return ESX.IsPlayerLoaded()
    end
    return NetworkIsPlayerActive(PlayerId())
end

function Bridge.Notify(message, kind)
    lib.notify({ description = message, type = kind or 'inform' })
end

function Bridge.OnLoaded(cb)
    if framework == 'qbx' or framework == 'qb' then
        RegisterNetEvent('QBCore:Client:OnPlayerLoaded', cb)
    elseif framework == 'esx' then
        RegisterNetEvent('esx:playerLoaded', function() SetTimeout(500, cb) end)
    else
        AddEventHandler('playerSpawned', cb)
    end
end
