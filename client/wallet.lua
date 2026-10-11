local function format(amount)
    local formatted = tostring(math.floor(amount or 0))
    local k
    repeat
        formatted, k = formatted:gsub('^(-?%d+)(%d%d%d)', '%1,%2')
    until k == 0
    return formatted
end

local function showBalance(account)
    local data = lib.callback.await('ns_radialmenu:getWallet', false)
    if not data then return end
    if account == 'cash' then
        NS.Notify(locale('wal_cash_amount', format(data.cash)), 'inform')
    else
        NS.Notify(locale('wal_bank_amount', format(data.bank)), 'inform')
    end
end

local function giveCash()
    local playerId = NS.ClosestPlayer()
    if not playerId then return NS.Notify(locale('no_player_nearby'), 'error') end
    local input = lib.inputDialog(locale('wal_give_title'), {
        { type = 'number', label = locale('wal_amount'), required = true, min = 1, max = Config.Wallet.maxGive, icon = 'dollar-sign' }
    })
    if not input or not input[1] then return end
    local target = NS.ClosestPlayer()
    if target ~= playerId then return NS.Notify(locale('no_player_nearby'), 'error') end
    TriggerServerEvent('ns_radialmenu:server:giveCash', GetPlayerServerId(playerId), input[1])
end

NS.Builders.wallet = function()
    local list = {
        { label = locale('wal_cash'), icon = 'fa-solid fa-money-bill-wave', action = function() showBalance('cash') end },
        { label = locale('wal_bank'), icon = 'fa-solid fa-building-columns', action = function() showBalance('bank') end }
    }
    if Config.Wallet.giveCash and Bridge.Framework ~= 'standalone' then
        list[#list + 1] = { label = locale('wal_give'), icon = 'fa-solid fa-hand-holding-dollar', action = giveCash }
    end
    return list
end
