-- ESX Initialization
ESX = nil
local token = nil

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

        Citizen.Wait(250)
    end
end)

-- main script logic
if config.main.killsRanking then
    AddEventHandler('gameEventTriggered', function(name,args)

        if name ~= 'CEventNetworkEntityDamage' then return end;

        if args[6] == 1 then
            TriggerEvent('zykem_ranking:pedDieEvent', args[1],args[2], args[7], 'kill')
        end

    end)
end

local types = {"kill", "death"}
RegisterNetEvent('zykem_ranking:pedDieEvent')
AddEventHandler('zykem_ranking:pedDieEvent', function(victimPED, killerPED, weapon, stattype)
 
    if (not table.concat(types, ','):match(stattype)) then return end;
    if (token == nil) then return end;
    
    if (victimPED == PlayerPedId()) and config.main.deathsRanking then
        TriggerServerEvent('zykem-statEvent', token, 'death')
        return
    end

    local playerSVID = GetPlayerServerId(NetworkGetPlayerIndexFromPed(killerPED)) -- killer's server id
    
    if (playerSVID == 0) then return end; -- killer is not player

    local victimSVID = GetPlayerServerId(NetworkGetPlayerIndexFromPed(victimPED)) -- vitim's server id

    if (victimSVID == 0) then
        if not config.main.npcKills then return end;
    end
    
    TriggerServerEvent('zykem-statEvent', token, 'kill')

end)

-- server -> client tokenizer call
RegisterNetEvent('zykem_ranking:receiveToken')
AddEventHandler('zykem_ranking:receiveToken', function(tokenhuj)
    token = tokenhuj
end)

-- playtime logic
if (config.main.playTimeRanking) then

    local random_interval
    Citizen.CreateThread(function()
    
        while true do
    
            random_interval = math.random(1,4)
            Citizen.Wait(1000 * 60 * random_interval)
            TriggerServerEvent('zykem_ranking:updatePlaytime', random_interval, token)


        end
    
    end)

end

local elements, playtime, decimalhours
RegisterCommand('stats', function()

    ESX.UI.Menu.CloseAll()

    ESX.TriggerServerCallback('zykem_ranking:getStats', function(stats)
        
        playtime = json.decode(stats[1].playtime)
        decimalhours = string.format("%.2f", playtime.decimalhours)
        elements = {
            {label = locales[config.main.locale].esxmenu_kills .. ': ' .. stats[1].kills, value = ''},
            {label = locales[config.main.locale].esxmenu_deaths .. ': ' .. stats[1].deaths, value = ''},
            {label = locales[config.main.locale].esxmenu_playtime .. ': ' .. decimalhours, value = ''}
        }
        ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'actions_menu',
        {
            title    = locales[config.main.locale].esxmenu_title,
            align    = 'center',
            elements = elements
        }, function(data, menu)			

        end, function(data, menu)
            menu.close()
        end)
    
    end)
    
end)
