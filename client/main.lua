local pedModel = Config.Ped.model
local deliveryVehicle = nil
local isDelivering = false
local currentDelivery = nil
local targetZoneId = nil
local currentDeliveryBlip = nil
local playerVehicles = {}

local function getRandomDeliveryLocation()
    local locations = Config.Deliveries.locations
    local randomIndex = math.random(1, #locations)
    return locations[randomIndex]
end

function startDelivering()
    local vehicleHash = GetHashKey(Config.Deliveries.vehicle)
    local uniquePlate = "PIZZA" .. tostring(math.random(100, 999))

    lib.notify({
        title = 'Delivery Started',
        description = 'You have started delivering pizzas. Get to your vehicle and follow the waypoint!',
        type = 'inform',
    })

    RequestModel(vehicleHash)
    while not HasModelLoaded(vehicleHash) do
        Wait(500)
    end

    local vehicle = CreateVehicle(vehicleHash, Config.Deliveries.spawnLocation.x, Config.Deliveries.spawnLocation.y, Config.Deliveries.spawnLocation.z, Config.Deliveries.spawnLocation.w, true, false)
    SetVehicleNumberPlateText(vehicle, uniquePlate)

    playerVehicles[PlayerPedId()] = vehicle
    TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)

    isDelivering = true
    TriggerServerEvent('neon_pizzajob:startDelivering')

    currentDelivery = getRandomDeliveryLocation()
    setDeliveryWaypoint(currentDelivery)
    createDeliveryBlip(currentDelivery)
end

function setDeliveryWaypoint(delivery)
    if delivery and delivery.location then
        local deliveryCoords = delivery.location
        SetNewWaypoint(deliveryCoords.x, deliveryCoords.y)
    end
end

function removePreviousMarkerAndTarget()
    if targetZoneId then
        exports.ox_target:removeZone(targetZoneId)
        targetZoneId = nil
    end

    if currentDeliveryBlip then
        RemoveBlip(currentDeliveryBlip)
        currentDeliveryBlip = nil
    end
end

function createDeliveryBlip(delivery)
    local deliveryCoords = delivery.location
    removePreviousMarkerAndTarget()

    currentDeliveryBlip = AddBlipForCoord(deliveryCoords.x, deliveryCoords.y, deliveryCoords.z)
    SetBlipSprite(currentDeliveryBlip, 1)
    SetBlipColour(currentDeliveryBlip, 5)
    SetBlipScale(currentDeliveryBlip, 0.8)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Delivery Location")
    EndTextCommandSetBlipName(currentDeliveryBlip)

    targetZoneId = exports.ox_target:addSphereZone({
        coords = deliveryCoords,
        radius = 1.5,
        options = {
            {
                label = "Deliver Pizza",
                icon = 'fa-solid fa-box',
                onSelect = function()
                    startDeliveryAnimation() 
                end
            }
        }
    })
end

function startDeliveryAnimation()
    if lib.progressCircle({
        duration = Config.DeliveryTime or 3000,
        position = 'bottom',
        label = 'Delivering Pizza',
        useWhileDead = false,
        canCancel = false,
        disable = {
            car = true,
            move = true,
            combat = true,
            mouse = false
        }
    }) then
        completeDelivery()
    end
end

function completeDelivery()
    TriggerServerEvent('neon_pizzajob:completeDelivery')

    lib.notify({
        title = 'Delivery Complete',
        description = 'Pizza delivered. Please move onto the next delivery.',
        type = 'success',
    })

    local newDelivery
    repeat
        newDelivery = getRandomDeliveryLocation()
    until newDelivery ~= currentDelivery

    currentDelivery = newDelivery
    setDeliveryWaypoint(currentDelivery)
    createDeliveryBlip(currentDelivery)
end

function stopDelivering()
    local playerVehicle = playerVehicles[PlayerPedId()]

    if playerVehicle and DoesEntityExist(playerVehicle) then
        DeleteVehicle(playerVehicle)
        playerVehicles[PlayerPedId()] = nil
    end

    lib.notify({
        title = 'Delivery Stopped',
        description = 'You have stopped delivering pizzas. The vehicle has been removed.',
        type = 'inform',
    })

    removePreviousMarkerAndTarget()
    SetWaypointOff()
    TriggerServerEvent('neon_pizzajob:stopDelivering')
    isDelivering = false
    currentDelivery = nil
end

local function viewLeaderboard()
    TriggerServerEvent('neon_pizzajob:requestLeaderboard')
end

local function displayLeaderboardMenu(leaderboardData)
    local leaderboardOptions = {}

    for i, playerData in ipairs(leaderboardData) do
        table.insert(leaderboardOptions, {
            title = string.format("Rank %d: %s %s", i, playerData.firstname, playerData.lastname),
            description = string.format("Total Deliveries: %d", playerData.total_deliveries),
            icon = 'fa-solid fa-user'
        })
    end

    lib.registerContext({
        id = 'leaderboard_menu',
        title = 'Top Pizza Deliverers',
        options = leaderboardOptions,
        onExit = function()
        end
    })

    lib.showContext('leaderboard_menu')
end

RegisterNetEvent('neon_pizzajob:receiveLeaderboard', function(leaderboardData)
    displayLeaderboardMenu(leaderboardData)
end)

local function openChefMenu()
    local options = {}

    if isDelivering then
        table.insert(options, {
            title = 'Stop Delivering',
            description = 'Stop delivering pizzas and return the vehicle.',
            icon = 'fa-solid fa-stop',
            iconColor = '#FF0000',
            onSelect = function()
                stopDelivering()
            end
        })
    else
        table.insert(options, {
            title = 'Start Deliveries',
            description = 'Start delivering pizzas around the city.',
            icon = 'fa-solid fa-play',
            iconColor = '#00FF00',
            onSelect = function()
                startDelivering()
            end
        })
    end

    table.insert(options, {
        title = 'View Leaderboard',
        description = 'See the top pizza deliverers!',
        icon = 'fa-solid fa-trophy',
        onSelect = function()
            viewLeaderboard()
        end
    })

    lib.registerContext({
        id = 'chef_menu',
        title = 'Pizza Deliveries',
        options = options
    })

    lib.showContext('chef_menu')
end

local function addTargetOptions(ped)
    if Config.Target == 'ox_target' then
        exports.ox_target:addLocalEntity(ped, {
            {
                label = Config.TargetSettings.label,
                distance = Config.TargetSettings.distance,
                size = Config.TargetSettings.size,
                icon = 'fa-solid fa-pizza-slice',
                canInteract = function()
                    local playerPed = PlayerPedId()
                    return not IsPedInAnyVehicle(playerPed, false) and not IsEntityDead(playerPed)
                end,
                onSelect = function()
                    openChefMenu()
                end
            }
        })
    end
end

local function spawnPed()
    local pedHash = GetHashKey(pedModel)

    Citizen.CreateThread(function()
        RequestModel(pedHash)
        local timeout = 5000
        while not HasModelLoaded(pedHash) and timeout > 0 do
            Wait(500)
            timeout = timeout - 500
        end

        if HasModelLoaded(pedHash) then
            local pedZ = Config.Ped.location.z - 1.0
            local ped = CreatePed(4, pedHash, Config.Ped.location.x, Config.Ped.location.y, pedZ, Config.Ped.location.w, false, true)
            SetEntityInvincible(ped, true)
            FreezeEntityPosition(ped, true)
            SetBlockingOfNonTemporaryEvents(ped, true)
            addTargetOptions(ped)
        end
    end)
end

local function createBlip()
    Citizen.CreateThread(function()
        local blip = AddBlipForCoord(Config.Ped.location.x, Config.Ped.location.y, Config.Ped.location.z)
        SetBlipSprite(blip, Config.Blip.sprite)
        SetBlipColour(blip, Config.Blip.color)
        SetBlipScale(blip, Config.Blip.size)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(Config.Blip.label)
        EndTextCommandSetBlipName(blip)
    end)
end

AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        spawnPed()
        createBlip()
    end
end)
