local saved = {}
local savedModel
local busy = false

local function gender()
    local model = GetEntityModel(cache.ped)
    if model ~= savedModel then
        saved = {}
        savedModel = model
    end
    if model == `mp_m_freemode_01` then return 'male' end
    if model == `mp_f_freemode_01` then return 'female' end
end

local function playAnim(anim)
    if not anim or cache.vehicle then return Wait(250) end
    lib.requestAnimDict(anim.dict)
    TaskPlayAnim(cache.ped, anim.dict, anim.clip, 3.0, 3.0, anim.time, 51, 0, false, false, false)
    Wait(anim.time)
    StopAnimTask(cache.ped, anim.dict, anim.clip, 1.0)
    RemoveAnimDict(anim.dict)
end

local function restore(slot)
    local data = saved[slot.id]
    if not data then return end
    local ped = cache.ped
    if slot.type == 'prop' then
        SetPedPropIndex(ped, slot.index, data.drawable, data.texture, true)
    else
        for _, comp in ipairs(data) do
            SetPedComponentVariation(ped, comp.index, comp.drawable, comp.texture, comp.palette)
        end
    end
    saved[slot.id] = nil
end

local function remove(slot, sex)
    local ped = cache.ped
    if slot.type == 'prop' then
        local drawable = GetPedPropIndex(ped, slot.index)
        if drawable == -1 then return false end
        saved[slot.id] = { drawable = drawable, texture = GetPedPropTextureIndex(ped, slot.index) }
        ClearPedProp(ped, slot.index)
        return true
    end
    local naked = slot.naked[sex]
    if GetPedDrawableVariation(ped, slot.index) == naked then return false end
    local data = {
        { index = slot.index, drawable = GetPedDrawableVariation(ped, slot.index), texture = GetPedTextureVariation(ped, slot.index), palette = GetPedPaletteVariation(ped, slot.index) }
    }
    for _, extra in ipairs(slot.extra or {}) do
        data[#data + 1] = { index = extra.index, drawable = GetPedDrawableVariation(ped, extra.index), texture = GetPedTextureVariation(ped, extra.index), palette = GetPedPaletteVariation(ped, extra.index) }
    end
    saved[slot.id] = data
    SetPedComponentVariation(ped, slot.index, naked, 0, 0)
    for _, extra in ipairs(slot.extra or {}) do
        SetPedComponentVariation(ped, extra.index, extra[sex], 0, 0)
    end
    return true
end

local function hasItem(slot, sex)
    local ped = cache.ped
    if slot.type == 'prop' then return GetPedPropIndex(ped, slot.index) ~= -1 end
    return GetPedDrawableVariation(ped, slot.index) ~= slot.naked[sex]
end

local function toggle(slot)
    if busy then return end
    local sex = gender()
    if not sex then return NS.Notify(locale('cl_unsupported'), 'error') end
    busy = true
    if saved[slot.id] then
        playAnim(slot.anim)
        restore(slot)
    elseif hasItem(slot, sex) then
        playAnim(slot.anim)
        remove(slot, sex)
    else
        NS.Notify(locale('cl_nothing'), 'error')
    end
    busy = false
end

local function resetAll()
    if busy then return end
    busy = true
    local any = false
    for _, slot in ipairs(Config.Clothing) do
        if saved[slot.id] then any = true break end
    end
    if any then
        playAnim({ dict = 'clothingtie', clip = 'try_tie_positive_a', time = 1500 })
        for i = #Config.Clothing, 1, -1 do restore(Config.Clothing[i]) end
    end
    busy = false
end

NS.Builders.clothes = function()
    local sex = gender()
    if not sex then return nil, locale('cl_unsupported') end
    local list = {}
    for _, slot in ipairs(Config.Clothing) do
        if saved[slot.id] or hasItem(slot, sex) then
            list[#list + 1] = {
                label = locale('cl_' .. slot.id),
                icon = slot.icon,
                active = saved[slot.id] ~= nil,
                keepOpen = true,
                action = function() toggle(slot) end
            }
        end
    end
    if next(saved) then
        list[#list + 1] = { label = locale('cl_reset'), icon = 'fa-solid fa-rotate-left', keepOpen = true, action = resetAll }
    end
    if #list == 0 then return nil, locale('cl_nothing') end
    return list
end

exports('ResetClothing', function() saved = {} end)
