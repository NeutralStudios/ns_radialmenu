lib.locale()

NS = {}
NS.Builders = {}
NS.Internal = {}
NS.ItemIndex = {}

for i = 1, #Config.Items do
    NS.ItemIndex[Config.Items[i].id] = Config.Items[i]
end

local function bool(value, default)
    if type(value) == 'boolean' then return value end
    return default
end

function NS.SanitizeSettings(data)
    local defaults = Config.Defaults
    data = type(data) == 'table' and data or {}
    local out = {}
    out.theme = (data.theme == 'light' or data.theme == 'dark' or data.theme == 'dynamic') and data.theme or defaults.theme
    out.blur = bool(data.blur, defaults.blur)
    out.behaviour = (data.behaviour == 'hold' or data.behaviour == 'press') and data.behaviour or defaults.behaviour
    out.sound = bool(data.sound, defaults.sound)
    out.colored = bool(data.colored, defaults.colored)
    out.items = {}
    local source = type(data.items) == 'table' and data.items or defaults.items
    local seen = {}
    for _, id in ipairs(source) do
        if type(id) == 'string' and NS.ItemIndex[id] and not seen[id] and #out.items < Config.MaxItems then
            seen[id] = true
            out.items[#out.items + 1] = id
        end
    end
    return out
end

function NS.JobKind(jobName)
    for kind, cfg in pairs(Config.Jobs) do
        for _, name in ipairs(cfg.jobs) do
            if name == jobName then return kind, cfg end
        end
    end
end
