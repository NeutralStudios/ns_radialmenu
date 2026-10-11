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

local function getPlayer(src)
    if framework == 'qbx' then
        return exports.qbx_core:GetPlayer(src)
    elseif framework == 'qb' then
        return QBCore.Functions.GetPlayer(src)
    elseif framework == 'esx' then
        return ESX.GetPlayerFromId(src)
    end
end

function Bridge.GetIdentifier(src)
    local player = getPlayer(src)
    if framework == 'qbx' or framework == 'qb' then
        return player and player.PlayerData.citizenid
    elseif framework == 'esx' then
        return player and player.identifier
    end
    return GetPlayerIdentifierByType(src, 'license')
end

function Bridge.GetName(src)
    local player = getPlayer(src)
    if (framework == 'qbx' or framework == 'qb') and player then
        local info = player.PlayerData.charinfo
        if info then return ('%s %s'):format(info.firstname, info.lastname) end
    elseif framework == 'esx' and player then
        return player.getName()
    end
    return GetPlayerName(src)
end

function Bridge.GetJob(src)
    local player = getPlayer(src)
    if (framework == 'qbx' or framework == 'qb') and player then
        return player.PlayerData.job.name, player.PlayerData.job.onduty ~= false
    elseif framework == 'esx' and player then
        return player.job.name, true
    end
    return Player(src).state.job or 'unemployed', true
end

function Bridge.GetMoney(src, account)
    local player = getPlayer(src)
    if not player then return 0 end
    if framework == 'qbx' or framework == 'qb' then
        return player.PlayerData.money[account] or 0
    elseif framework == 'esx' then
        if account == 'cash' then return player.getMoney() end
        local acc = player.getAccount(account)
        return acc and acc.money or 0
    end
    return 0
end

function Bridge.RemoveMoney(src, account, amount)
    local player = getPlayer(src)
    if not player then return false end
    if Bridge.GetMoney(src, account) < amount then return false end
    if framework == 'qbx' or framework == 'qb' then
        return player.Functions.RemoveMoney(account, amount, 'ns-radialmenu') ~= false
    elseif framework == 'esx' then
        if account == 'cash' then player.removeMoney(amount) else player.removeAccountMoney(account, amount) end
        return true
    end
    return false
end

function Bridge.AddMoney(src, account, amount)
    local player = getPlayer(src)
    if not player then return false end
    if framework == 'qbx' or framework == 'qb' then
        return player.Functions.AddMoney(account, amount, 'ns-radialmenu') ~= false
    elseif framework == 'esx' then
        if account == 'cash' then player.addMoney(amount) else player.addAccountMoney(account, amount) end
        return true
    end
    return false
end

function Bridge.IsRestrained(src)
    local state = Player(src).state
    if state.handcuffed or state.isCuffed or state.cuffed or state.restrained or state.ziptied or state.isDead or state.dead then return true end
    if state.cuffs and type(state.cuffs) == 'table' and state.cuffs.flags and state.cuffs.flags ~= 0 then return true end
    if framework == 'qbx' or framework == 'qb' then
        local player = getPlayer(src)
        local meta = player and player.PlayerData.metadata
        if meta and (meta.ishandcuffed or meta.isdead or meta.inlaststand) then return true end
    end
    local ped = GetPlayerPed(src)
    return ped ~= 0 and GetEntityHealth(ped) <= 0
end

function Bridge.RevokeLicense(target, licenseType)
    if framework == 'qbx' or framework == 'qb' then
        local player = getPlayer(target)
        if not player then return false end
        local licences = player.PlayerData.metadata.licences or {}
        licences[licenseType or 'driver'] = false
        player.Functions.SetMetaData('licences', licences)
        return true
    elseif framework == 'esx' then
        if GetResourceState('esx_license') ~= 'started' then return false end
        TriggerEvent('esx_license:removeLicense', target, licenseType or 'drive')
        return true
    end
    return false
end
