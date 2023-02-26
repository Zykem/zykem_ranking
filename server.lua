
ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

local playersReceived = {}

AddEventHandler('playerDropped', function()

    for i=1,#playersReceived do

        if GetPlayerName(source) == playersReceived[i].name then
            print('tokenizer # nulled ' .. playersReceived[i].name .. ' token table! [leave-event]')
            playersReceived[i] = nil
            return
        end

    end

end)

function getDcId(source)
    
    for k,v in pairs(GetPlayerIdentifiers(source)) do
        if (string.match(v, "^discord:")) then
            return v;
        end
    end
    return locales[config.main.locale].nodiscord;

end

function getCharName(identifier)

    local name = MySQL.query.await('SELECT firstname,lastname FROM users WHERE identifier = ?', {identifier})
    return name;

end

AddEventHandler('esx:playerLoaded', function(source)

    local player = ESX.GetPlayerFromId(source)
    local identifier = player.getIdentifier()
    local identifiers = {
        playerId = identifier,
        name = GetPlayerName(source),
        charname = getCharName(identifier),
        discord = getDcId(source)
    }
    local isInRanking = MySQL.query.await('SELECT * FROM rankings WHERE JSON_EXTRACT(identifier, "$.playerId") = ?', {identifier})

    if (isInRanking[1] == nil) then insertNewPlayer(identifiers) end;

    -- new token gneeration
    local generatedToken = config.main.token_prefixes[math.floor(math.random(1, #config.main.token_prefixes))] .. math.random(11111,99999)
    local tableOfData = {

        name = GetPlayerName(source),
        token = generatedToken

    }
    playersReceived[#playersReceived + 1] = tableOfData

    -- Server -> Client Token Receiver
    TriggerClientEvent('zykem_ranking:receiveToken', source, generatedToken)
    print('# Assigned ' .. generatedToken .. ' to player ' .. source)

end)

function insertNewPlayer(identifiers)
    MySQL.query('INSERT INTO rankings (identifier,playtime) VALUES (?,?)', {json.encode(identifiers), json.encode({hours = 0.00})})
end

function generateNew(playername)

    -- cleanup old token
    for i=1,#playersReceived do
        if (playername == playersReceived[i].name) then
            playersReceived[i] = nil
        end
    end

    -- new token generation
    local gentoken = config.main.token_prefixes[math.floor(math.random(1, #config.main.token_prefixes))] .. math.random(11111,99999)
    local tokenizerTable = {

        name = playername,
        token = gentoken

    }
    -- sending new generated token
    playersReceived[#playersReceived + 1] = tokenizerTable
    TriggerClientEvent('zykem_ranking:receiveToken', source, gentoken)

end

local stattypes = {"kill", "death"}
RegisterServerEvent('zykem-statEvent')
AddEventHandler('zykem-statEvent', function(sectoken, stattype)
    -- guard clause
    if (not table.concat(stattypes, ','):match(stattype)) then return end;  

    -- tokenizer check
    for i = 1, #playersReceived do
        if GetPlayerName(source) == playersReceived[i].name then
            if sectoken ~= playersReceived[i].token then DropPlayer(source, '💌: hakerom mowimy nie') return end; -- ban/kick/log 
        end
    end

    player = ESX.GetPlayerFromId(source)
    pIdentifier = player.getIdentifier()

    if (stattype == 'kill') then

        MySQL.Async.execute('UPDATE rankings SET kills = kills + 1 WHERE JSON_EXTRACT(identifier, "$.playerId") = ?', {pIdentifier}, function(result)
            -- kill stat incremented event | maybe discord log?
        end)

    elseif (stattype == 'death') then

        MySQL.Async.execute('UPDATE rankings SET deaths = deaths + 1 WHERE JSON_EXTRACT(identifier, "$.playerId") = ?', {pIdentifier}, function(result)
            -- death stat incremented event | maybe discord log?
        end)

    end
    
    -- generate new security token for player after everything's done
    generateNew(GetPlayerName(source))
end)

MySQL.ready(function()

    

end)

local stats_temp = {
    kills = {},
    deaths = {},
    playtime = {}
}
local money, identifiers, decimalhours_formatted
function sendStat(stat, sus)

    if not table.concat({"playtime", "kills", "deaths", "money"}, ','):match(stat) then return end;

    local embed = {
        {
            ["color"] = 65351,

            ["author"] = {
                ["name"] = "",
            },
            ["thumbnail"] = {
                ["url"] = svcfg.webhooks.serverLogo
            },
            ["description"] = "",
            ["footer"] = {
                ["text"] = "Ranking System"
            },
        }
    }
    if (stat == 'money') then
        embed[1]["author"]["name"] = locales[config.main.locale].embed_title_money
        for i = 1, #sus do
            
            identifiers = MySQL.query.await('SELECT identifier FROM rankings WHERE JSON_EXTRACT(identifier, "$.playerId") = ?', {sus[i].identifier})
            identifiers = json.decode(identifiers[1].identifier)
            money = json.decode(sus[i].accounts)
            embed[1]["description"] = embed[1]["description"] .. '\n**' .. i .. '.** ' .. identifiers.charname[1].firstname .. ' ' .. identifiers.charname[1].lastname .. " **#** <@" .. identifiers.discord .. '> - ' .. locales[config.main.locale].amount .. ' **' .. money.bank .. '**'

        end
    elseif (stat == 'playtime') then
        embed[1]["author"]["name"] = locales[config.main.locale].embed_title_playtime
        for i = 1, #sus do

            identifiers = json.decode(sus[i].identifier)
            playtime = json.decode(sus[i].playtime)
            playtime.decimalhours = string.format("%.2f", playtime.decimalhours)
            embed[1]["description"] = embed[1]["description"] .. '\n**' .. i .. '.** ' .. identifiers.charname[1].firstname .. ' ' .. identifiers.charname[1].lastname .. " **#** <@" .. identifiers.discord .. '> - ' .. locales[config.main.locale].amount .. ' **' .. playtime.decimalhours .. '**'

        end
    else
        embed[1]["author"]["name"] = string.format(locales[config.main.locale].embed_title_killsdeaths, stat)
        for i = 1, #sus do

            identifiers = json.decode(sus[i].identifier)
            embed[1]["description"] = embed[1]["description"] .. '\n**' .. i .. '.** ' .. identifiers.charname[1].firstname .. ' ' .. identifiers.charname[1].lastname .. " **#** <@" .. identifiers.discord .. '> - ' .. locales[config.main.locale].amount .. ' **' .. sus[i][stat] .. '**'

        end
    end
    PerformHttpRequest(svcfg.webhooks[stat], function(err, text, headers) end, 'POST', json.encode({embeds = {embed[1]}}), { ['Content-Type'] = 'application/json' })

end

-- playtime count
local timeToAdd, oldtime, formattedTime, newHours, newMinutes, decimalHours, player, pIdentifier
RegisterNetEvent('zykem_ranking:updatePlaytime')
AddEventHandler('zykem_ranking:updatePlaytime', function(random_interval, token)
    
    player = ESX.GetPlayerFromId(source)
    pIdentifier = player.getIdentifier()
    
    oldtime = MySQL.query.await('SELECT playtime FROM rankings WHERE JSON_EXTRACT(identifier, "$.playerId") = ?', {pIdentifier})
    formattedTime = json.decode(oldtime[1].playtime)

    newHours = random_interval / 60 + formattedTime.hours
    newMinutes = random_interval + formattedTime.minutes
    decimalHours = formattedTime.hours + random_interval / 60

    timeToAdd = {
        decimalhours = decimalHours,
        hours = newHours,
        minutes = newMinutes
    }

    MySQL.Async.execute('UPDATE rankings SET playtime = ? WHERE JSON_EXTRACT(identifier, "$.playerId") = ?', {json.encode(timeToAdd), pIdentifier}, function(result)
       -- updated playtime, do whatever you want here

    end)

end)

local kills_await, deaths_await, playtime_await, money_await
Citizen.CreateThread(function()

    while true do

        kills_await = MySQL.query.await('SELECT identifier,kills FROM rankings ORDER BY kills DESC LIMIT 25');
        deaths_await = MySQL.query.await('SELECT identifier,deaths FROM rankings ORDER BY deaths DESC LIMIT 25');
        playtime_await = MySQL.query.await('SELECT identifier,playtime FROM rankings ORDER BY CAST(JSON_EXTRACT(playtime, "$.decimalhours") AS DECIMAL(10,2)) DESC LIMIT 25')
        money_await = MySQL.query.await('SELECT identifier,accounts FROM users ORDER BY JSON_EXTRACT(accounts, "$.bank") DESC LIMIT 25')

        sendStat('kills', kills_await)
        sendStat('deaths', deaths_await)
        sendStat('playtime', playtime_await)
        sendStat('money', money_await)

        Citizen.Wait(1000 * 60 * 10)
    end

end)

RegisterCommand('sendstats', function(source)

    if source ~= 0 then return end;
    kills_await = MySQL.query.await('SELECT identifier,kills FROM rankings ORDER BY kills DESC LIMIT 25');
        deaths_await = MySQL.query.await('SELECT identifier,deaths FROM rankings ORDER BY deaths DESC LIMIT 25');
        playtime_await = MySQL.query.await('SELECT identifier,playtime FROM rankings ORDER BY CAST(JSON_EXTRACT(playtime, "$.decimalhours") AS DECIMAL(10,2)) DESC LIMIT 25')
        money_await = MySQL.query.await('SELECT identifier,accounts FROM users ORDER BY JSON_EXTRACT(accounts, "$.bank") DESC LIMIT 25')

        sendStat('kills', kills_await)
        sendStat('deaths', deaths_await)
        sendStat('playtime', playtime_await)
        sendStat('money', money_await)

end)

ESX.RegisterServerCallback('zykem_ranking:getStats', function(source,cb)

    local player = ESX.GetPlayerFromId(source)
    local pIdentifier = player.getIdentifier()
    local stats = MySQL.query.await('SELECT kills,deaths,playtime FROM rankings WHERE JSON_EXTRACT(identifier, "$.playerId") = ?', {pIdentifier})

    cb(stats);

end)