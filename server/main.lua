QBCore = exports['qb-core']:GetCoreObject()
local activeDeliveries = {}

local function checkPlayerExists(citizenid, callback)
    MySQL.scalar('SELECT COUNT(*) FROM neon_pizzajob WHERE citizenid = ?', {citizenid}, function(count)
        callback(count > 0)
    end)
end

local function insertPlayer(citizenid)
    MySQL.insert('INSERT INTO neon_pizzajob (citizenid, total_deliveries) VALUES (?, ?)', 
        {citizenid, 0}, function(insertId)
    end)
end

local function updateTotalDeliveries(citizenid)
    MySQL.update('UPDATE neon_pizzajob SET total_deliveries = total_deliveries + 1 WHERE citizenid = ?', {citizenid}, function(affectedRows)
    end)
end

RegisterNetEvent('neon_pizzajob:startDelivering')
AddEventHandler('neon_pizzajob:startDelivering', function()
    local src = source
    activeDeliveries[src] = true
end)

RegisterNetEvent('neon_pizzajob:stopDelivering')
AddEventHandler('neon_pizzajob:stopDelivering', function()
    local src = source
    activeDeliveries[src] = nil
end)

RegisterNetEvent('neon_pizzajob:completeDelivery')
AddEventHandler('neon_pizzajob:completeDelivery', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if Player and activeDeliveries[src] then
        local payAmount = math.random(Config.Pay.min, Config.Pay.max)
        Player.Functions.AddMoney("cash", payAmount, "Pizza Delivery")

        local citizenid = Player.PlayerData.citizenid
        checkPlayerExists(citizenid, function(exists)
            if exists then
                updateTotalDeliveries(citizenid)
            else
                insertPlayer(citizenid)
                updateTotalDeliveries(citizenid)
            end
        end)

        activeDeliveries[src] = true 
    else
        print("Failed payment attempt: player not actively delivering.")
    end
end)

RegisterNetEvent('neon_pizzajob:requestLeaderboard')
AddEventHandler('neon_pizzajob:requestLeaderboard', function()
    local src = source
    MySQL.query('SELECT citizenid, total_deliveries FROM neon_pizzajob ORDER BY total_deliveries DESC LIMIT 10', {}, function(results)
        local leaderboard = {}

        for _, row in ipairs(results) do
            local player = QBCore.Functions.GetPlayerByCitizenId(row.citizenid)
            local firstname, lastname

            if player then
                firstname = player.PlayerData.charinfo.firstname
                lastname = player.PlayerData.charinfo.lastname
            else
                firstname = "Unknown"
                lastname = ""
            end

            table.insert(leaderboard, {
                citizenid = row.citizenid,
                firstname = firstname,
                lastname = lastname,
                total_deliveries = row.total_deliveries
            })
        end

        TriggerClientEvent('neon_pizzajob:receiveLeaderboard', src, leaderboard)
    end)
end)