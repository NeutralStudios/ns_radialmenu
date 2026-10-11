local current

NS.Housing = {}

function NS.Housing.Property()
    if current then return current end
    local state = LocalPlayer.state
    local fromState = state.property_id or state.propertyId or state.currentProperty
    if fromState and fromState ~= '' then return fromState end
end

function NS.Housing.Inside()
    return NS.Housing.Property() ~= nil
end

local function setProperty(value)
    if value == nil or value == '' then
        current = nil
    else
        current = value
    end
end

local cfg = Config.Housing

if cfg and cfg.enabled then
    for _, name in ipairs(cfg.enterEvents or {}) do
        RegisterNetEvent(name, function(propertyId)
            setProperty(propertyId)
        end)
    end
    for _, name in ipairs(cfg.exitEvents or {}) do
        RegisterNetEvent(name, function()
            setProperty(nil)
        end)
    end
end

local function available()
    if not cfg or not cfg.enabled then return false end
    return GetResourceState(cfg.resource) == 'started'
end

NS.Housing.Available = available

NS.Builders.housing = function()
    if not available() then return nil, locale('unsupported') end
    local inside = NS.Housing.Inside()
    local list = {}
    for _, def in ipairs(cfg.actions or {}) do
        local action = def.action
        local usable = action and (action.event or action.command or action.resource or action.fn)
        local show = true
        if def.requireInside and not inside then show = false end
        if def.requireOutside and inside then show = false end
        if usable and show then
            list[#list + 1] = {
                label = locale(def.label),
                icon = def.icon,
                color = cfg.color,
                action = action
            }
        end
    end
    if #list == 0 then return nil, locale('nothing_available') end
    return list
end

function NS.Internal.housingLeave()
    local propertyId = NS.Housing.Property()
    if not propertyId then return NS.Notify(locale('house_outside'), 'error') end
    TriggerServerEvent(cfg.leaveEvent, propertyId)
    setProperty(nil)
end

AddEventHandler('onResourceStop', function(resource)
    if resource == cfg.resource then setProperty(nil) end
end)
