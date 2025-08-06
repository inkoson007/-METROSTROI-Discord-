--> Developer By INK <--------------------------------------------------------------------------------

-- Конфигурация --------------------------------------------------------------------------------
local PROXY_URL = "http://ВАШ_ДОМЕН/webhook_proxy.php"
local LOGGING_ENABLED = true
local DEFAULT_AVATAR = "https://ВАШ_URL"
local BOT_AVATAR = "https://ВАШ_URL"

local function LogMessage(msg)
    if LOGGING_ENABLED then
        print("[ДЦХ System] " .. msg)
    end
end
---------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function SafeGetNick(ply)
    if IsValid(ply) and ply:IsPlayer() then
        local success, result = pcall(function() return ply:Nick() end)
        if success then return result end
    end
    return "Неизвестный"
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function GetPlayerAvatar(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return DEFAULT_AVATAR end
    local steamid64 = ply:SteamID64()
    if not steamid64 then return DEFAULT_AVATAR end
    return "https://avatars.akamai.steamstatic.com/" .. string.sub(steamid64, -2) .. "/" .. steamid64 .. "_full.jpg"
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function SendToDiscord(embed, ply)
    if IsValid(ply) and ply:IsPlayer() then
        embed.thumbnail = { url = GetPlayerAvatar(ply) }
    end

    local payload = {
        embeds = {embed},
        username = "ДЦХ Монитор",
        avatar_url = BOT_AVATAR
    }

    local jsonPayload = util.TableToJSON(payload)
    if not jsonPayload then
        LogMessage("Ошибка: не удалось преобразовать таблицу в JSON")
        return
    end

    HTTP({
        url = PROXY_URL,
        method = "POST",
        headers = {
            ["Content-Type"] = "application/json"
        },
        body = jsonPayload,
        success = function(code, body, headers)
            if code ~= 204 and code ~= 200 then
                LogMessage("Ошибка отправки через прокси: Код "..code..". Ответ: "..tostring(body))
            else
                LogMessage("Уведомление успешно отправлено через прокси")
            end
        end,
        failed = function(err)
            LogMessage("Ошибка HTTP запроса к прокси: " .. tostring(err))
        end
    })
end
--------------------------------------------------------------------------------
-- Хук: Игрок заступил на пост ДЦХ --------------------------------------------------------------------------------
hook.Add("MDispatcher.TookPost", "DiscordNotify_TookPost", function(nick, ply)
    nick = nick or SafeGetNick(ply)
    local embed = {
        title = "🚔 Назначение на пост ДЦХ",
        description = "**" .. nick .. "** заступил на пост диспетчера",
        color = 0x3498db,
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        footer = { text = "ДЦХ Система | " .. os.date("%d.%m.%Y %H:%M") }
    }
    SendToDiscord(embed, ply)
    LogMessage(nick .. " заступил на пост ДЦХ")
end)
--------------------------------------------------------------------------------
-- Хук: Игрок покинул пост ДЦХ --------------------------------------------------------------------------------
hook.Add("MDispatcher.FreedPost", "DiscordNotify_FreedPost", function(nick, ply)
    nick = nick or SafeGetNick(ply)
    local embed = {
        title = "🚔 Освобождение поста ДЦХ",
        description = "**" .. nick .. "** покинул пост диспетчера",
        color = 0xe74c3c,
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        footer = { text = "ДЦХ Система | " .. os.date("%d.%m.%Y %H:%M") }
    }
    SendToDiscord(embed, ply)
    LogMessage(nick .. " покинул пост ДЦХ")
end)
--------------------------------------------------------------------------------
-- Хук: Изменение интервала --------------------------------------------------------------------------------
hook.Add("MDispatcher.SetInt", "DiscordNotify_SetInt", function(nick, interval, ply)
    nick = nick or SafeGetNick(ply)
    local embed = {
        title = "⏱ Изменение интервала",
        description = "**" .. nick .. "** установил интервал: **" .. interval .. "**",
        color = 0xf1c40f,
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        footer = { text = "ДЦХ Система | " .. os.date("%d.%m.%Y %H:%M") }
    }
    SendToDiscord(embed, ply)
    LogMessage(nick .. " изменил интервал на " .. interval)
end)
--------------------------------------------------------------------------------
-- Хук: Назначение ДСЦП --------------------------------------------------------------------------------
hook.Add("MDispatcher.DSCPSet", "DiscordNotify_DSCPSet", function(message, ply)
    local embed = {
        title = "🚦 Назначение ДСЦП",
        description = message,
        color = 0x2ecc71,
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        footer = { text = "ДЦХ Система | " .. os.date("%d.%m.%Y %H:%M") }
    }
    SendToDiscord(embed, ply)
    LogMessage("Назначен ДСЦП: " .. message)
end)
--------------------------------------------------------------------------------
-- Хук: Снятие ДСЦП --------------------------------------------------------------------------------
hook.Add("MDispatcher.DSCPUnset", "DiscordNotify_DSCPUnset", function(message, ply)
    local embed = {
        title = "🚦 Снятие ДСЦП",
        description = message,
        color = 0xe74c3c,
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        footer = { text = "ДЦХ Система | " .. os.date("%d.%m.%Y %H:%M") }
    }
    SendToDiscord(embed, ply)
    LogMessage("Снят ДСЦП: " .. message)
end)
--------------------------------------------------------------------------------
LogMessage("[✅] -> Система Discord уведомлений для ДЦХ/ДСЦП загружена V1.3 <-")