local settings = NS.SanitizeSettings(Config.Defaults)
local isOpen = false
local settingsOpen = false
local stack = {}
local nodes = {}
local counter = 0
local external = {}
local externalCount = 0
local headshot
local saveTimer
local suppressPause = 0

local uiKeys = {
    'ui_settings', 'ui_radial_menu', 'ui_general', 'ui_customize', 'ui_theme', 'ui_blur', 'ui_behaviour', 'ui_hold', 'ui_press',
    'ui_sound', 'ui_colored', 'ui_light', 'ui_dark', 'ui_dynamic', 'ui_add', 'ui_revert', 'ui_preview', 'ui_max', 'ui_desc_theme',
    'ui_desc_blur', 'ui_desc_behaviour', 'ui_desc_sound', 'ui_desc_colored', 'ui_empty', 'ui_all_added', 'ui_close', 'ui_id', 'ui_full',
    'ui_subtitle', 'ui_tab_look', 'ui_tab_controls', 'ui_tab_layout', 'ui_open_mode', 'ui_hold_desc', 'ui_press_desc', 'ui_slots',
    'ui_slots_used', 'ui_available', 'ui_empty_slot', 'ui_move_up', 'ui_move_down', 'ui_remove', 'ui_preview_hint', 'ui_layout_desc'
}

local function uiLocale()
    local out = {}
    for i = 1, #uiKeys do out[uiKeys[i]] = locale(uiKeys[i]) end
    return out
end

function NS.GetSettings()
    return settings
end

function NS.Notify(message, kind)
    Bridge.Notify(message, kind)
end

function NS.IsOpen()
    return isOpen
end

function NS.ClosestPlayer(maxDistance)
    local playerId, playerPed = lib.getClosestPlayer(GetEntityCoords(cache.ped), maxDistance or Config.InteractDistance, false)
    return playerId, playerPed
end

function NS.ClosestVehicle(maxDistance, includeOwn)
    if includeOwn and cache.vehicle then return cache.vehicle end
    local vehicle = lib.getClosestVehicle(GetEntityCoords(cache.ped), maxDistance or Config.Vehicle.searchDistance, false)
    return vehicle
end

function NS.Control(entity)
    if not DoesEntityExist(entity) then return false end
    if NetworkHasControlOfEntity(entity) then return true end
    local timeout = GetGameTimer() + 2000
    while not NetworkHasControlOfEntity(entity) and GetGameTimer() < timeout do
        NetworkRequestControlOfEntity(entity)
        Wait(10)
    end
    return NetworkHasControlOfEntity(entity)
end

function NS.Run(action, context)
    if type(action) == 'function' then return action(context) end
    if type(action) ~= 'table' then return end
    local target
    if action.target then
        local playerId = NS.ClosestPlayer(action.distance)
        if not playerId then return NS.Notify(locale('no_player_nearby'), 'error') end
        target = action.localTarget and playerId or GetPlayerServerId(playerId)
    end
    local args, placed = {}, false
    for i, value in ipairs(action.args or {}) do
        if value == '$target' then
            args[i] = target
            placed = true
        elseif value == '$property' then
            args[i] = NS.Housing and NS.Housing.Property()
        else
            args[i] = value
        end
    end
    if target and not placed then table.insert(args, 1, target) end
    local kind = action.type
    if kind == 'client' then
        TriggerEvent(action.event, table.unpack(args))
    elseif kind == 'server' then
        TriggerServerEvent(action.event, table.unpack(args))
    elseif kind == 'command' then
        local command = action.command
        for i = 1, #args do command = command .. ' ' .. tostring(args[i]) end
        ExecuteCommand(command)
    elseif kind == 'export' then
        local ok, err = pcall(function()
            local resource = exports[action.resource]
            return resource[action.fn](resource, table.unpack(args))
        end)
        if not ok then
            lib.print.warn(('export %s:%s failed: %s'):format(action.resource, action.fn, err))
            NS.Notify(locale('unsupported'), 'error')
        end
    elseif kind == 'internal' then
        local fn = NS.Internal[action.fn]
        if fn then fn(table.unpack(args)) end
    end
end

local function itemVisible(item)
    if not item.hideWhenEmpty or not Config.HideEmptyItems then return true end
    local builder = item.submenu and NS.Builders[item.submenu]
    if not builder then return true end
    local ok, result = pcall(builder)
    return ok and type(result) == 'table' and #result > 0
end

local function rootItems()
    local list = {}
    for _, id in ipairs(settings.items) do
        local item = NS.ItemIndex[id]
        if item and itemVisible(item) then
            list[#list + 1] = {
                label = locale(item.label),
                icon = item.icon,
                color = item.color,
                builder = item.submenu and NS.Builders[item.submenu] or nil,
                action = item.action
            }
        end
    end
    local keys = {}
    for key in pairs(external) do keys[#keys + 1] = key end
    table.sort(keys, function(a, b) return external[a].order < external[b].order end)
    for _, key in ipairs(keys) do
        local option = external[key]
        if not option.canShow or option.canShow() then list[#list + 1] = option end
    end
    return list
end

local function serialize(list)
    nodes = {}
    local out = {}
    for i = 1, #list do
        counter = counter + 1
        local id = 'n' .. counter
        local item = list[i]
        nodes[id] = item
        out[i] = {
            id = id,
            label = item.label,
            icon = item.icon or 'fa-solid fa-circle',
            color = item.color,
            submenu = (item.builder or item.children) and true or false,
            active = item.active and true or false
        }
    end
    return out
end

local function resolveFrame(frame)
    if frame.builder then return frame.builder() end
    return frame.items
end

local invLock = nil

local function lockInventory()
    if invLock then return end
    local state = LocalPlayer.state
    invLock = { busy = state.invBusy, hotkeys = state.invHotkeys }
    state:set('invBusy', true, false)
    state:set('invHotkeys', false, false)
    if GetResourceState('qb-inventory') == 'started' or GetResourceState('ps-inventory') == 'started' then
        TriggerEvent('inventory:client:busy:status', true)
    end
end

local function unlockInventory()
    if not invLock then return end
    local state = LocalPlayer.state
    state:set('invBusy', invLock.busy == true, false)
    state:set('invHotkeys', invLock.hotkeys ~= false, false)
    if GetResourceState('qb-inventory') == 'started' or GetResourceState('ps-inventory') == 'started' then
        TriggerEvent('inventory:client:busy:status', false)
    end
    invLock = nil
end

local function closeMenu()
    if not isOpen then return end
    isOpen = false
    unlockInventory()
    stack = {}
    nodes = {}
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({ action = 'close' })
    if settings.blur then TriggerScreenblurFadeOut(200) end
    suppressPause = GetGameTimer() + 400
end
NS.Close = closeMenu

local function present()
    if not isOpen then return end
    local frame = stack[#stack]
    if not frame then return closeMenu() end
    local list, message = resolveFrame(frame)
    if not list or #list == 0 then
        if message then NS.Notify(message, 'error') end
        stack[#stack] = nil
        if #stack == 0 then return closeMenu() end
        return present()
    end
    local max = Config.MaxItems
    local shown = list
    if #list > max then
        local perPage = max - 1
        local pages = math.ceil(#list / perPage)
        frame.page = frame.page or 1
        if frame.page > pages then frame.page = 1 end
        shown = {}
        for i = (frame.page - 1) * perPage + 1, math.min(frame.page * perPage, #list) do
            shown[#shown + 1] = list[i]
        end
        shown[#shown + 1] = { label = locale('more', frame.page, pages), icon = 'fa-solid fa-ellipsis', page = true }
    end
    SendNUIMessage({
        action = 'setItems',
        items = serialize(shown),
        title = frame.title,
        depth = #stack
    })
end
NS.Refresh = present

local function controlLoop()
    while isOpen do
        DisableControlAction(0, 1, true)
        DisableControlAction(0, 2, true)
        DisableControlAction(0, 14, true)
        DisableControlAction(0, 15, true)
        DisableControlAction(0, 16, true)
        DisableControlAction(0, 17, true)
        DisableControlAction(0, 24, true)
        DisableControlAction(0, 25, true)
        DisableControlAction(0, 37, true)
        DisableControlAction(0, 68, true)
        DisableControlAction(0, 69, true)
        DisableControlAction(0, 70, true)
        DisableControlAction(0, 91, true)
        DisableControlAction(0, 92, true)
        DisableControlAction(0, 106, true)
        DisableControlAction(0, 114, true)
        DisableControlAction(0, 140, true)
        DisableControlAction(0, 141, true)
        DisableControlAction(0, 142, true)
        DisableControlAction(0, 177, true)
        DisableControlAction(0, 199, true)
        DisableControlAction(0, 200, true)
        DisableControlAction(0, 157, true)
        DisableControlAction(0, 158, true)
        DisableControlAction(0, 160, true)
        DisableControlAction(0, 164, true)
        DisableControlAction(0, 165, true)
        DisableControlAction(0, 257, true)
        DisableControlAction(0, 263, true)
        DisableControlAction(0, 264, true)
        DisableControlAction(0, 322, true)
        Wait(0)
    end
    while GetGameTimer() < suppressPause do
        DisableControlAction(0, 199, true)
        DisableControlAction(0, 200, true)
        DisableControlAction(0, 322, true)
        Wait(0)
    end
end

local function blocked(reason)
    if Config.Debug then print(('[ns_radialmenu] open blocked: %s'):format(reason)) end
    return false
end

local function canOpen()
    if isOpen then return blocked('already open') end
    if settingsOpen then return blocked('settings open') end
    if IsPauseMenuActive() then return blocked('pause menu') end
    if Config.Block.dead and Bridge.IsDead() then return blocked('player dead') end
    if Config.Block.restrained and Bridge.IsRestrained() then return blocked('player restrained') end
    if LocalPlayer.state.invOpen then return blocked('inventory open') end
    return true
end

local function openMenu()
    if not canOpen() then return end
    isOpen = true
    lockInventory()
    stack = { { builder = rootItems } }
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true)
    SendNUIMessage({
        action = 'open',
        settings = settings,
        hour = GetClockHours(),
        center = Config.CenterIcon
    })
    present()
    if settings.blur then TriggerScreenblurFadeIn(200) end
    CreateThread(controlLoop)
end
NS.Open = openMenu

local function select(id, release)
    local item = nodes[id]
    if not item then return end
    if item.page then
        if release then return closeMenu() end
        local frame = stack[#stack]
        frame.page = (frame.page or 1) + 1
        return present()
    end
    if item.builder or item.children then
        if release then return closeMenu() end
        local list, message
        if item.builder then list, message = item.builder() else list = item.children end
        if not list or #list == 0 then
            return NS.Notify(message or locale('nothing_available'), 'error')
        end
        stack[#stack + 1] = { title = item.label, builder = item.builder, items = item.children }
        return present()
    end
    if not item.action then return end
    local keepOpen = item.keepOpen and not release
    if not keepOpen then closeMenu() end
    CreateThread(function()
        NS.Run(item.action, item)
        if keepOpen and isOpen then
            Wait(120)
            present()
        end
    end)
end

local function back()
    if #stack > 1 then
        stack[#stack] = nil
        present()
    else
        closeMenu()
    end
end

local function queueSave()
    if saveTimer then saveTimer = GetGameTimer() + 600 return end
    saveTimer = GetGameTimer() + 600
    CreateThread(function()
        while GetGameTimer() < saveTimer do Wait(100) end
        saveTimer = nil
        TriggerServerEvent('ns_radialmenu:server:saveSettings', settings)
    end)
end

local function releaseHeadshot()
    if headshot then
        UnregisterPedheadshot(headshot)
        headshot = nil
    end
end

local function getHeadshot()
    releaseHeadshot()
    local handle = RegisterPedheadshot(cache.ped)
    local timeout = GetGameTimer() + 2500
    while GetGameTimer() < timeout and not (IsPedheadshotReady(handle) and IsPedheadshotValid(handle)) do
        Wait(50)
    end
    if IsPedheadshotReady(handle) and IsPedheadshotValid(handle) then
        headshot = handle
        local txd = GetPedheadshotTxdString(handle)
        return ('https://nui-img/%s/%s'):format(txd, txd)
    end
    UnregisterPedheadshot(handle)
end

local function poolForUi()
    local pool = {}
    for i, item in ipairs(Config.Items) do
        pool[i] = { id = item.id, label = locale(item.label), icon = item.icon, color = item.color }
    end
    return pool
end

local settingsBlur = false

function NS.Internal.openSettings()
    if settingsOpen then return end
    if isOpen then closeMenu() end
    settingsOpen = true
    local profile = lib.callback.await('ns_radialmenu:getProfile', false) or {}
    profile.avatar = getHeadshot()
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
    settingsBlur = settings.blur and true or false
    if settingsBlur then TriggerScreenblurFadeIn(200) end
    SendNUIMessage({
        action = 'openSettings',
        settings = settings,
        defaults = NS.SanitizeSettings(Config.Defaults),
        pool = poolForUi(),
        max = Config.MaxItems,
        server = Config.ServerName,
        profile = profile,
        hour = GetClockHours(),
        center = Config.CenterIcon,
        locale = uiLocale()
    })
end

local function closeSettings()
    if not settingsOpen then return end
    settingsOpen = false
    SetNuiFocus(false, false)
    if settingsBlur then TriggerScreenblurFadeOut(200) end
    settingsBlur = false
    SendNUIMessage({ action = 'closeSettings' })
    releaseHeadshot()
    suppressPause = GetGameTimer() + 400
    CreateThread(controlLoop)
end

RegisterNUICallback('select', function(data, cb)
    cb(1)
    select(data.id, data.release)
end)

RegisterNUICallback('back', function(_, cb)
    cb(1)
    back()
end)

RegisterNUICallback('close', function(_, cb)
    cb(1)
    closeMenu()
end)

RegisterNUICallback('saveSettings', function(data, cb)
    cb(1)
    settings = NS.SanitizeSettings(data)
    queueSave()
end)

RegisterNUICallback('previewBlur', function(data, cb)
    cb(1)
    if not settingsOpen then return end
    local on = data and data.on == true
    if on == settingsBlur then return end
    settingsBlur = on
    if on then TriggerScreenblurFadeIn(200) else TriggerScreenblurFadeOut(200) end
end)

RegisterNUICallback('closeSettings', function(_, cb)
    cb(1)
    closeSettings()
end)

RegisterNUICallback('ready', function(_, cb)
    cb({ locale = uiLocale() })
end)

local pending = false
local releasedEarly = false

local function boundKey(command)
    return GetControlInstructionalButton(0, joaat(command) | 0x80000000, true)
end

local function hotbarWillToggle()
    if GetResourceState('ox_inventory') ~= 'started' then return false end
    local mine = boundKey('+nsradial')
    local theirs = boundKey('+hotbar')
    if Config.Debug then print(('[ns_radialmenu] key %s / ox hotbar %s'):format(mine, theirs)) end
    if not mine or mine == '' or mine ~= theirs then return false end
    if LocalPlayer.state.invHotkeys == false or IsNuiFocused() then return false end
    if lib.progressActive() then return false end
    return true
end

local function keyPressed()
    if pending then return end
    if Config.Debug then print(('[ns_radialmenu] key pressed (%s)'):format(settings.behaviour)) end
    local undoHotbar = hotbarWillToggle()
    pending = true
    releasedEarly = false
    CreateThread(function()
        Wait(0)
        if undoHotbar then
            ExecuteCommand('+hotbar')
            ExecuteCommand('-hotbar')
        end
        pending = false
        if settings.behaviour == 'press' and isOpen then
            return closeMenu()
        end
        openMenu()
        if releasedEarly and settings.behaviour == 'hold' and isOpen then
            SendNUIMessage({ action = 'release' })
        end
    end)
end

local function keyReleased()
    if pending then
        releasedEarly = true
        return
    end
    if settings.behaviour == 'hold' and isOpen then
        SendNUIMessage({ action = 'release' })
    end
end

RegisterCommand('+nsradial', keyPressed, false)
RegisterCommand('-nsradial', keyReleased, false)
RegisterKeyMapping('+nsradial', locale('keybind_desc'), 'keyboard', Config.Keybind)

if Config.OpenCommand and Config.OpenCommand ~= '' then
    RegisterCommand(Config.OpenCommand, function()
        if isOpen then return closeMenu() end
        local behaviour = settings.behaviour
        settings.behaviour = 'press'
        openMenu()
        settings.behaviour = behaviour
    end, false)
end

RegisterCommand(Config.SettingsCommand, function()
    NS.Internal.openSettings()
end, false)

function NS.Internal.openPhone()
    if GetResourceState('lb-phone') == 'started' then
        return exports['lb-phone']:ToggleOpen(true)
    elseif GetResourceState('npwd') == 'started' then
        return exports.npwd:setPhoneVisible(true)
    elseif GetResourceState('qs-smartphone') == 'started' or GetResourceState('qs-smartphone-pro') == 'started' then
        return TriggerEvent('phone:client:OpenPhone')
    end
    ExecuteCommand(Config.Phone.command)
end

function NS.Internal.openInventory()
    if GetResourceState('ox_inventory') == 'started' then
        return exports.ox_inventory:openInventory()
    end
    ExecuteCommand(Config.Inventory.command)
end

function NS.Internal.openEmotes()
    ExecuteCommand(Config.Emotes.command)
end

local function loadSettings()
    local data = lib.callback.await('ns_radialmenu:getSettings', false)
    settings = NS.SanitizeSettings(data or Config.Defaults)
end

Bridge.OnLoaded(function()
    loadSettings()
end)

CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do Wait(500) end
    Wait(1000)
    loadSettings()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    unlockInventory()
    if isOpen or settingsOpen then
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
        TriggerScreenblurFadeOut(0)
    end
    releaseHeadshot()
end)

local function convertOption(option)
    local node = {
        label = option.label or option.title or '?',
        icon = option.icon and (option.icon:find('fa%-') and option.icon or ('fa-solid fa-' .. option.icon)) or 'fa-solid fa-circle',
        color = option.color,
        keepOpen = option.keepOpen or option.shouldClose == false,
        canShow = option.canShow
    }
    if option.items then
        node.children = {}
        for i, child in ipairs(option.items) do node.children[i] = convertOption(child) end
    elseif option.onSelect then
        node.action = option.onSelect
    elseif option.action then
        node.action = option.action
    elseif option.type == 'command' then
        node.action = { type = 'command', command = option.command or option.event }
    elseif option.event then
        node.action = { type = option.type == 'server' and 'server' or 'client', event = option.event, args = option.args }
    end
    return node
end

exports('AddOption', function(option, id)
    externalCount = externalCount + 1
    id = id or option.id or ('ext_' .. externalCount)
    local node = convertOption(option)
    node.order = external[id] and external[id].order or externalCount
    external[id] = node
    if isOpen and #stack == 1 then present() end
    return id
end)

exports('RemoveOption', function(id)
    external[id] = nil
    if isOpen and #stack == 1 then present() end
end)

exports('Open', openMenu)
exports('Close', closeMenu)
exports('IsOpen', function() return isOpen end)
exports('OpenSettings', function() NS.Internal.openSettings() end)
